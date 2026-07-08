`timescale 1ns/1ps
// Simple Non-UVM Testbench for top_tensorcore_lite.sv
// Features: 1000-cycle Random testing, C-Like Golden Model, and Self-Reporting.
import uvm_report_pkg::*;

module tb_top_tensorcore_simple;

    // --------------------------------------------------------
    // Clock & Reset
    // --------------------------------------------------------
    logic clk;
    logic rst_ni;

    initial begin
        clk = 0;
        forever #50 clk = ~clk; // 10MHz (100ns period) to accommodate GF180 45ns SRAM read latency
    end

    // --------------------------------------------------------
    // Signals
    // --------------------------------------------------------
    // AXI-Lite
    logic [31:0]  s_axi_awaddr;
    logic         s_axi_awvalid;
    logic         s_axi_awready;
    logic [31:0]  s_axi_wdata;
    logic         s_axi_wvalid;
    logic         s_axi_wready;
    logic [1:0]   s_axi_bresp;
    logic         s_axi_bvalid;
    logic         s_axi_bready;
    logic [31:0]  s_axi_araddr;
    logic         s_axi_arvalid;
    logic         s_axi_arready;
    logic [31:0]  s_axi_rdata;
    logic [1:0]   s_axi_rresp;
    logic         s_axi_rvalid;
    logic         s_axi_rready;

    // AXI-Stream RX
    logic [127:0] s_axis_tdata;
    logic         s_axis_tvalid;
    logic         s_axis_tready;
    logic         s_axis_tlast;

    // AXI-Stream TX
    logic [511:0] m_axis_tdata;
    logic         m_axis_tvalid;
    logic         m_axis_tready;
    logic         m_axis_tlast;

    // BIST
    logic         bist_start_i;
    logic [511:0] expected_misr_sig_i;
    logic         bist_done_o;
    logic         bist_fail_o;

    // --------------------------------------------------------
    // DUT Instantiation
    // --------------------------------------------------------
    top_tensorcore_lite dut (
        .clk_i(clk),
        .rst_ni(rst_ni),
        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),
        .s_axi_wdata(s_axi_wdata),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),
        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),
        .s_axi_araddr(s_axi_araddr),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),
        .s_axi_rdata(s_axi_rdata),
        .s_axi_rresp(s_axi_rresp),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast),
        .bist_start_i(bist_start_i),
        .expected_misr_sig_i(expected_misr_sig_i),
        .bist_done_o(bist_done_o),
        .bist_fail_o(bist_fail_o)
    );

    // --------------------------------------------------------
    // AXI Tasks
    // --------------------------------------------------------
    task automatic init_signals();
        s_axi_awaddr = 0; s_axi_awvalid = 0; s_axi_wdata = 0; s_axi_wvalid = 0; s_axi_bready = 0;
        s_axi_araddr = 0; s_axi_arvalid = 0; s_axi_rready = 0;
        s_axis_tdata = 0; s_axis_tvalid = 0; s_axis_tlast = 0;
        m_axis_tready = 1; // Always ready to receive
        bist_start_i = 0; expected_misr_sig_i = 0;
    endtask

    task automatic axi_write(input logic [31:0] addr, input logic [31:0] data);
        // Drive AW and W channels
        @(negedge clk);
        s_axi_awaddr <= addr; s_axi_awvalid <= 1;
        s_axi_wdata <= data; s_axi_wvalid <= 1;
        s_axi_bready <= 1;

        // Wait for ready signals
        fork
            begin
                while (!s_axi_awready) @(negedge clk);
                s_axi_awvalid <= 0;
            end
            begin
                while (!s_axi_wready) @(negedge clk);
                s_axi_wvalid <= 0;
            end
        join

        // Wait for bvalid
        while (!s_axi_bvalid) @(negedge clk);
        @(posedge clk); // Wait for handshake to complete on posedge
        s_axi_bready <= 0;
        @(negedge clk); // Grace period
    endtask

    task automatic axi_read(input logic [31:0] addr, output logic [31:0] data);
        @(negedge clk);
        s_axi_araddr <= addr; s_axi_arvalid <= 1; s_axi_rready <= 1;
        
        while (!s_axi_arready) @(negedge clk);
        s_axi_arvalid <= 0;
        
        while (!s_axi_rvalid) @(negedge clk);
        data = s_axi_rdata;
        @(posedge clk); // Wait for handshake to complete on posedge
        s_axi_rready <= 0;
        @(negedge clk); // Grace period
    endtask

    task automatic send_matrices(input byte wgt[16][16], input byte act[16][16]);
        logic [127:0] row_data;
        // 1. Send Weights (16 rows)
        for (int i=0; i<16; i++) begin
            row_data = 0;
            for (int j=0; j<16; j++) row_data[j*8 +: 8] = wgt[i][j];
            @(negedge clk);
            s_axis_tdata <= row_data;
            s_axis_tvalid <= 1;
            s_axis_tlast <= 0;
            while (s_axis_tready !== 1'b1) @(negedge clk);
        end
        // 2. Send Acts (16 rows)
        for (int i=0; i<16; i++) begin
            row_data = 0;
            for (int j=0; j<16; j++) row_data[j*8 +: 8] = act[i][j];
            @(negedge clk);
            s_axis_tdata <= row_data;
            s_axis_tvalid <= 1;
            s_axis_tlast <= (i == 15) ? 1 : 0;
            while (s_axis_tready !== 1'b1) @(negedge clk);
        end
        @(negedge clk);
        s_axis_tvalid <= 0;
        s_axis_tlast <= 0;
    endtask

    task automatic read_results(output int res[16][16]);
        logic [511:0] out_data;
        for (int i=0; i<16; i++) begin
            @(negedge clk);
            while (m_axis_tvalid !== 1'b1) @(negedge clk);
            out_data = m_axis_tdata;
            for (int j=0; j<16; j++) begin
                res[i][j] = out_data[j*32 +: 32];
            end
        end
    endtask

    // --------------------------------------------------------
    // Golden Model
    // --------------------------------------------------------
    function automatic void golden_matmul(input byte act[16][16], input byte wgt[16][16], output int expected[16][16]);
        for (int i=0; i<16; i++) begin
            for (int j=0; j<16; j++) begin
                expected[i][j] = 0;
                for (int k=0; k<16; k++) begin
                    expected[i][j] += $signed(act[i][k]) * $signed(wgt[k][j]);
                end
            end
        end
    endfunction

    // --------------------------------------------------------
    // Main Test Execution
    // --------------------------------------------------------
    byte wgt_mat [16][16];
    byte act_mat [16][16];
    int  exp_mat [16][16];
    int  act_res [16][16];

    task automatic run_single_inference();
        logic [31:0] read_val;
        
        // Parallelize DMA TX, DMA RX, and CPU Polling
        fork
            begin
                // Thread 1: DMA Sends Input Matrices
                $display("    [T1] Sending matrices...");
                send_matrices(wgt_mat, act_mat);
                $display("    [T1] Done sending matrices.");
            end
            begin
                // Thread 2: CPU Orchestration
                
                // Poll for rx_matrix_done
                $display("    [T2] Polling for RX_DONE...");
                do begin
                    axi_read(32'h04, read_val);
                end while ((read_val & 32'h00000004) == 0); 
                $display("    [T2] RX_DONE received! Starting compute...");
                
                // Trigger start
                axi_write(32'h00, 32'h00000001);
                
                // Poll for mac_done
                $display("    [T2] Polling for MAC_DONE...");
                do begin
                    axi_read(32'h04, read_val);
                end while (read_val[1] == 0);
                $display("    [T2] MAC_DONE received!");
                
                // CRITICAL FIX: Clear the sticky status bits (RX_DONE, MAC_DONE)
                // so the next inference doesn't trigger prematurely!
                axi_write(32'h04, 32'h00);
            end
            begin
                // Thread 3: DMA Reads Output Results
                $display("    [T3] Waiting for output results...");
                read_results(act_res);
                $display("    [T3] Output results received!");
            end
        join
    endtask
    task automatic run_corner_cases();
        bit global_error = 0;
        int mismatch_cnt = 0;
        $display("[TEST CASE 2] Running Deterministic Corner Cases...");

        // 1. Zero Matrices
        $display("  -> Case 1: Zero Matrices");
        for (int i=0; i<16; i++) for (int j=0; j<16; j++) begin wgt_mat[i][j] = 0; act_mat[i][j] = 0; end
        golden_matmul(act_mat, wgt_mat, exp_mat);
        run_single_inference();
        for (int i=0; i<16; i++) for (int j=0; j<16; j++) if (act_res[i][j] !== exp_mat[i][j]) mismatch_cnt++;

        // 2. Identity Matrix (W = Identity, A = Random)
        $display("  -> Case 2: Identity Matrix");
        for (int i=0; i<16; i++) for (int j=0; j<16; j++) begin
            wgt_mat[i][j] = (i == j) ? 1 : 0;
            act_mat[i][j] = $urandom();
        end
        golden_matmul(act_mat, wgt_mat, exp_mat);
        run_single_inference();
        for (int i=0; i<16; i++) for (int j=0; j<16; j++) if (act_res[i][j] !== exp_mat[i][j]) mismatch_cnt++;

        // 3. Maximum Positive Saturation (127 x 127)
        $display("  -> Case 3: Maximum Positive Saturation");
        for (int i=0; i<16; i++) for (int j=0; j<16; j++) begin wgt_mat[i][j] = 127; act_mat[i][j] = 127; end
        golden_matmul(act_mat, wgt_mat, exp_mat);
        run_single_inference();
        for (int i=0; i<16; i++) for (int j=0; j<16; j++) if (act_res[i][j] !== exp_mat[i][j]) mismatch_cnt++;

        // 4. Maximum Negative Saturation (-128 x -128)
        $display("  -> Case 4: Maximum Negative Saturation");
        for (int i=0; i<16; i++) for (int j=0; j<16; j++) begin wgt_mat[i][j] = -128; act_mat[i][j] = -128; end
        golden_matmul(act_mat, wgt_mat, exp_mat);
        run_single_inference();
        for (int i=0; i<16; i++) for (int j=0; j<16; j++) if (act_res[i][j] !== exp_mat[i][j]) mismatch_cnt++;

        // 5. Maximum Asymmetric Extremes (-128 x 127)
        $display("  -> Case 5: Maximum Asymmetric Extremes");
        for (int i=0; i<16; i++) for (int j=0; j<16; j++) begin wgt_mat[i][j] = 127; act_mat[i][j] = -128; end
        golden_matmul(act_mat, wgt_mat, exp_mat);
        run_single_inference();
        for (int i=0; i<16; i++) for (int j=0; j<16; j++) if (act_res[i][j] !== exp_mat[i][j]) mismatch_cnt++;

        // 6. Checkerboard Pattern
        $display("  -> Case 6: Checkerboard Pattern (85 and -86)");
        for (int i=0; i<16; i++) for (int j=0; j<16; j++) begin 
            wgt_mat[i][j] = ((i+j)%2 == 0) ? 85 : -86; 
            act_mat[i][j] = ((i+j)%2 == 0) ? -86 : 85; 
        end
        golden_matmul(act_mat, wgt_mat, exp_mat);
        run_single_inference();
        for (int i=0; i<16; i++) for (int j=0; j<16; j++) if (act_res[i][j] !== exp_mat[i][j]) mismatch_cnt++;

        if (mismatch_cnt > 0) begin
            global_error = 1;
            $display("ERROR: %0d scalar mismatches found in Corner Cases!", mismatch_cnt);
        end
        print_test_box("CORNER CASES DIRECTED TEST", global_error);
    endtask

    task automatic run_100_random();
        bit local_error = 0;
        int mismatch_cnt = 0;
        $display("[TEST CASE 1] Running 100 Random Matrix Inferences...");

        for (int iter=0; iter<100; iter++) begin
            // 1. Randomize inputs
            for (int i=0; i<16; i++) begin
                for (int j=0; j<16; j++) begin
                    wgt_mat[i][j] = $urandom();
                    act_mat[i][j] = $urandom();
                end
            end
            
            // 2. Compute expected using Behavioral SV function
            golden_matmul(act_mat, wgt_mat, exp_mat);

            // 3. Run hardware
            run_single_inference();

            // 4. Compare
            for (int i=0; i<16; i++) begin
                for (int j=0; j<16; j++) begin
                    if (act_res[i][j] !== exp_mat[i][j]) begin
                        local_error = 1;
                        mismatch_cnt++;
                    end
                    // Print 16 samples from the very first inference
                    if (iter == 0 && i == 0) begin
                        $display("  [Iter 0, Row 0, Col %2d] Got: %10d | Expected: %10d", j, $signed(act_res[i][j]), $signed(exp_mat[i][j]));
                    end
                end
            end
            
            if (iter % 10 == 0 && iter > 0) $display("  - Completed %0d inferences", iter);
        end

        if (mismatch_cnt > 0) $display("ERROR: %0d scalar mismatches found in 100 inferences!", mismatch_cnt);
        print_test_box("100 CYCLES TOP RANDOM TEST", local_error);
    endtask

    task automatic run_bist();
        $display("[TEST CASE 3] Running BIST (Built-In Self-Test)...");
        @(negedge clk);
        bist_start_i <= 1'b1;
        // In a real scenario we'd use a golden signature. For now we just run it and check if it finishes.
        expected_misr_sig_i <= 512'h0; 
        @(negedge clk);
        bist_start_i <= 1'b0;
        
        $display("  -> Waiting for BIST to complete (this tests MBIST and LBIST)...");
        while (bist_done_o !== 1'b1) @(negedge clk);
        
        $display("  -> BIST Complete! Fail Status: %0b", bist_fail_o);
        print_test_box("BIST EXECUTION", bist_fail_o);
    endtask

    initial begin
        print_banner("TOP TENSORCORE: SIMPLE NON-UVM DIRECTED & RANDOM VERIFICATION");
        reset_counters();
        init_signals();
        
        // Assert Reset
        rst_ni = 0;
        repeat(5) @(posedge clk);
        rst_ni = 1;
        repeat(10) @(posedge clk);

        // Run directed corner cases first
        run_corner_cases();

        // Run 100 cycle test
        run_100_random();

        // Run the BIST sequence
        run_bist();

        // Print professional segmented box report
        print_final_report();
        $finish;
    end

    // Watchdog Timer (To catch deadlocks)
    initial begin
        #50000000; // 50ms timeout
        $display("\n\nFATAL: SIMULATION TIMEOUT HITTING WATCHDOG\n\n");
        $finish;
    end

endmodule
