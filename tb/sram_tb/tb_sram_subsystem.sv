`timescale 1ns/1ps

module tb_sram_subsystem;

    // --------------------------------------------------------
    // 1. SIGNALS & DUT INSTANTIATION
    // --------------------------------------------------------
    logic         clk;
    logic         rst_n;
    logic         en;
    logic         we;
    logic         re;
    logic [7:0]   w_base_addr;
    logic [7:0]   r_base_addr;
    logic [127:0] w_data_128b;
    logic [127:0] r_data_flat_128b;

    sram_subsystem_16bank dut (
        .clk              (clk),
        .rst_n            (rst_n),
        .en               (en),
        .we               (we),
        .re               (re),
        .w_base_addr      (w_base_addr),
        .r_base_addr      (r_base_addr),
        .w_data_128b      (w_data_128b),
        .r_data_flat_128b (r_data_flat_128b)
    );

    // --------------------------------------------------------
    // 2. CLOCK GENERATOR (250MHz / 4ns period)
    // --------------------------------------------------------
    initial begin
        clk = 0;
        forever #2 clk = ~clk; 
    end

    // --------------------------------------------------------
    // 3. AUTOMATIC SHADOW MEMORY (The Golden Model)
    // --------------------------------------------------------
    logic [7:0] shadow_mem [0:15][int];

    // Passive Monitor: Perfectly tracks hardware state exactly on the clock edge
    always @(posedge clk) begin
        if (we && en) begin
            for (int i = 0; i < 16; i++) begin
                shadow_mem[i][w_base_addr] = w_data_128b[i*8 +: 8];
            end
        end
    end

    // --------------------------------------------------------
    // 4. SYNCHRONIZED CHECKER TASK
    // --------------------------------------------------------
    int total_checks = 0;
    int passed = 0;
    int failed = 0;

    task check_read(input logic [7:0] expected_base_addr);
        @(posedge clk); 
        #1; // Wait 1ns for RTL non-blocking (<=) assignments to settle!
        
        for (int i = 0; i < 16; i++) begin
            logic [7:0] expected_val;
            logic [7:0] got_val;
            
            got_val = r_data_flat_128b[i*8 +: 8];
            
            if (shadow_mem[i].exists(expected_base_addr))
                expected_val = shadow_mem[i][expected_base_addr];
            else
                expected_val = 8'h00; // Assume 0 if uninitialized

            if (got_val !== expected_val) begin
                $error("[SCB_FAIL] Mismatch in Bank %0d Addr %0h: Expected %0h, Got %0h", 
                        i, expected_base_addr, expected_val, got_val);
                failed++;
            end
        end
        passed++;
        total_checks++;
    endtask

    // --------------------------------------------------------
    // 5. DIRECTED TEST SEQUENCES
    // --------------------------------------------------------
    initial begin
        // Reset inputs
        rst_n = 0; en = 0; we = 0; re = 0; w_base_addr = 0; r_base_addr = 0; w_data_128b = 0;
        for (int i=0; i<16; i++) shadow_mem[i].delete();
        
        // Wait for system to stabilize
        repeat(5) @(posedge clk);
        @(negedge clk); rst_n = 1;
        @(negedge clk); en = 1;

        // =======================================================
        $display("\n====== RUNNING TC1: SEQUENTIAL SWEEP (SMOKE) ======");
        for (int addr = 0; addr < 256; addr++) begin
            @(negedge clk);
            we = 1; w_base_addr = addr; 
            for (int i = 0; i < 16; i++) w_data_128b[i*8 +: 8] = addr + i;
        end
        @(negedge clk); we = 0;
        for (int addr = 0; addr < 256; addr++) begin
            @(negedge clk);
            re = 1; r_base_addr = addr;
            check_read(addr);
        end
        @(negedge clk); re = 0;

        // =======================================================
        $display("\n====== RUNNING TC2: INTERLEAVED PING-PONG ======");
        @(negedge clk); 
        we = 1; w_base_addr = 0; 
        for (int i = 0; i < 16; i++) w_data_128b[i*8 +: 8] = 8'hA0 + i;
        
        for (int addr = 1; addr < 16; addr++) begin
            @(negedge clk);
            we = 1; w_base_addr = addr; 
            for (int i = 0; i < 16; i++) w_data_128b[i*8 +: 8] = addr * 2 + i;
            re = 1; r_base_addr = addr - 1;
            check_read(addr - 1);
        end
        @(negedge clk); we = 0; re = 0;

        // =======================================================
        $display("\n====== RUNNING TC3: RAW HAZARD (WRITE-FIRST BYPASS) ======");
        @(negedge clk);
        we = 1; re = 1; w_base_addr = 8'h55; r_base_addr = 8'h55; 
        for (int i = 0; i < 16; i++) w_data_128b[i*8 +: 8] = 8'hBB;
        check_read(8'h55);
        @(negedge clk); we = 0; re = 0;

        // =======================================================
        $display("\n====== RUNNING TC4: ADDRESS WRAPAROUND ======");
        @(negedge clk); we = 1; w_base_addr = 8'hFF; for (int i = 0; i < 16; i++) w_data_128b[i*8 +: 8] = 8'h11;
        @(negedge clk); we = 1; w_base_addr = 8'h00; for (int i = 0; i < 16; i++) w_data_128b[i*8 +: 8] = 8'h22;
        @(negedge clk); we = 0; re = 1; r_base_addr = 8'hFF; check_read(8'hFF);
        @(negedge clk);         re = 1; r_base_addr = 8'h00; check_read(8'h00);
        @(negedge clk); re = 0;

        // =======================================================
        $display("\n====== RUNNING TC5: WRITE-DISABLE NOISE IMMUNITY ======");
        @(negedge clk); we = 1; w_base_addr = 8'h10; for (int i = 0; i < 16; i++) w_data_128b[i*8 +: 8] = 8'hEE;
        for (int i = 0; i < 10; i++) begin
            @(negedge clk);
            we = 0; w_base_addr = $urandom; 
            for (int k = 0; k < 16; k++) w_data_128b[k*8 +: 8] = $urandom;
        end
        @(negedge clk); re = 1; r_base_addr = 8'h10; check_read(8'h10);
        @(negedge clk); re = 0;

        // =======================================================
        $display("\n====== RUNNING TC6: CHECKERBOARD CROSSTALK ======");
        for (int addr = 0; addr < 256; addr++) begin
            @(negedge clk);
            we = 1; w_base_addr = addr; 
            for (int i = 0; i < 16; i++) w_data_128b[i*8 +: 8] = (addr % 2 == 0) ? 8'hAA : 8'h55;
        end
        @(negedge clk); we = 0;
        for (int addr = 0; addr < 256; addr++) begin
            @(negedge clk); re = 1; r_base_addr = addr; check_read(addr);
        end
        @(negedge clk); re = 0;

        // =======================================================
        $display("\n====== RUNNING TC7: EXTREME BOUNDS (+127, -128, 0) ======");
        @(negedge clk); we = 1; w_base_addr = 8'h20; for (int i = 0; i < 16; i++) w_data_128b[i*8 +: 8] = 8'h7F;
        @(negedge clk); we = 1; w_base_addr = 8'h30; for (int i = 0; i < 16; i++) w_data_128b[i*8 +: 8] = 8'h80;
        @(negedge clk); we = 1; w_base_addr = 8'h40; for (int i = 0; i < 16; i++) w_data_128b[i*8 +: 8] = 8'h00;
        @(negedge clk); we = 0;
        @(negedge clk); re = 1; r_base_addr = 8'h20; check_read(8'h20);
        @(negedge clk); re = 1; r_base_addr = 8'h30; check_read(8'h30);
        @(negedge clk); re = 1; r_base_addr = 8'h40; check_read(8'h40);
        @(negedge clk); re = 0;

        // =======================================================
        $display("\n====== RUNNING TC8: MARCH-C LITE ======");
        // Step 1: Write 0s
        for (int addr = 0; addr < 256; addr++) begin
            @(negedge clk); we = 1; re = 0; w_base_addr = addr; for (int i = 0; i < 16; i++) w_data_128b[i*8 +: 8] = 8'h00;
        end
        // Step 2: Ascending (Read 0, Write 1s)
        for (int addr = 0; addr < 256; addr++) begin
            @(negedge clk); we = 0; re = 1; r_base_addr = addr; check_read(addr);
            @(negedge clk); we = 1; re = 0; w_base_addr = addr; for (int i = 0; i < 16; i++) w_data_128b[i*8 +: 8] = 8'hFF;
        end
        // Step 3: Descending (Read 1s, Write 0s)
        for (int addr = 255; addr >= 0; addr--) begin
            @(negedge clk); we = 0; re = 1; r_base_addr = addr; check_read(addr);
            @(negedge clk); we = 1; re = 0; w_base_addr = addr; for (int i = 0; i < 16; i++) w_data_128b[i*8 +: 8] = 8'h00;
        end
        @(negedge clk); we = 0; re = 0;

        // =======================================================
        $display("\n====== RUNNING TC9: CHIP SELECT DE-ASSERTION ======");
        @(negedge clk);
        en = 0; we = 1; re = 1; w_base_addr = 8'h45; r_base_addr = 8'h45;
        for (int i = 0; i < 16; i++) w_data_128b[i*8 +: 8] = 8'hDE;
        @(negedge clk);
        we = 0; re = 0; en = 1;
        @(negedge clk);
        re = 1; r_base_addr = 8'h45; check_read(8'h45); // Should read 0s because write was gated!
        @(negedge clk);
        re = 0;

        // =======================================================
        $display("\n====== RUNNING TC10: 1000-CYCLE RANDOM STRESS ======");
        for (int j = 0; j < 1000; j++) begin
            @(negedge clk);
            we = $urandom_range(0, 1);
            re = $urandom_range(0, 1);
            w_base_addr = $urandom;
            r_base_addr = $urandom;
            for (int i = 0; i < 16; i++) w_data_128b[i*8 +: 8] = $urandom;

            if (re && en) begin
                check_read(r_base_addr);
            end
        end
        @(negedge clk); we = 0; re = 0;

        // --------------------------------------------------------
        // 6. FINAL SIMULATION SUMMARY
        // --------------------------------------------------------
        $display("\n========================================");
        $display("Total Subsystem Read Checks : %0d", total_checks);
        $display("Passed                      : %0d", passed);
        $display("Failed                      : %0d", failed);
        if (failed == 0)
            $display("TEST STATUS                 : PASS");
        else
            $display("TEST STATUS                 : FAIL");
        $display("========================================\n");

        $finish;
    end

endmodule
