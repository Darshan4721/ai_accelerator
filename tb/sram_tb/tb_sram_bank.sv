`timescale 1ns/1ps

module tb_sram_bank;

    // --------------------------------------------------------
    // 1. SIGNALS & DUT INSTANTIATION
    // --------------------------------------------------------
    logic       clk;
    logic       we;
    logic       re;
    logic [7:0] w_addr;
    logic [7:0] r_addr;
    logic [7:0] w_data;
    logic [7:0] r_data;

    sram_bank_256x8 dut (
        .clk    (clk),
        .we     (we),
        .re     (re),
        .w_addr (w_addr),
        .r_addr (r_addr),
        .w_data (w_data),
        .r_data (r_data)
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
    logic [7:0] shadow_mem [int]; // Associative array for clean tracking

    // Passive Monitor: Perfectly tracks hardware state exactly on the clock edge
    always @(posedge clk) begin
        if (we) begin
            shadow_mem[w_addr] = w_data;
        end
    end

    // --------------------------------------------------------
    // 4. SYNCHRONIZED CHECKER TASK
    // --------------------------------------------------------
    int total_checks = 0;
    int passed = 0;
    int failed = 0;

    task check_read(input logic [7:0] addr);
        // Treat uninitialized memory reads gracefully 
        logic [7:0] expected_data;
        
        @(posedge clk); 
        #1; // Wait 1ns for RTL non-blocking (<=) assignments to settle!
        
        if (shadow_mem.exists(addr))
            expected_data = shadow_mem[addr];
        else
            expected_data = 8'h00; // Assume 0 if uninitialized

        if (r_data !== expected_data) begin
            $error("[SCB_FAIL] Mismatch at Addr %0h: Expected %0h, Got %0h", addr, expected_data, r_data);
            failed++;
        end else begin
            passed++;
        end
        total_checks++;
    endtask

    // --------------------------------------------------------
    // 5. DIRECTED TEST SEQUENCES
    // --------------------------------------------------------
    initial begin
        // Reset inputs
        we = 0; re = 0; w_addr = 0; r_addr = 0; w_data = 0;
        shadow_mem.delete();
        
        // Wait for system to stabilize
        repeat(5) @(posedge clk);

        // =======================================================
        $display("\n====== RUNNING TC1: SEQUENTIAL SWEEP (SMOKE) ======");
        for (int i = 0; i < 256; i++) begin
            @(negedge clk);
            we = 1; w_addr = i; w_data = i; // Write unique data to every address
        end
        @(negedge clk); we = 0;
        for (int i = 0; i < 256; i++) begin
            @(negedge clk);
            re = 1; r_addr = i;
            check_read(i);
        end
        @(negedge clk); re = 0;

        // =======================================================
        $display("\n====== RUNNING TC2: INTERLEAVED PING-PONG ======");
        @(negedge clk); we = 1; w_addr = 0; w_data = 8'hA0; // Setup element 0
        for (int i = 1; i < 16; i++) begin
            @(negedge clk);
            we = 1; w_addr = i; w_data = i * 2; // Write to Address N
            re = 1; r_addr = i - 1;             // Read from Address N-1 simultaneously
            check_read(i - 1);
        end
        @(negedge clk); we = 0; re = 0;

        // =======================================================
        $display("\n====== RUNNING TC3: RAW HAZARD (WRITE-FIRST BYPASS) ======");
        @(negedge clk);
        we = 1; re = 1; w_addr = 8'h55; r_addr = 8'h55; w_data = 8'hBB;
        check_read(8'h55); // The bypass logic should forward 8'hBB immediately
        @(negedge clk); we = 0; re = 0;

        // =======================================================
        $display("\n====== RUNNING TC4: ADDRESS WRAPAROUND ======");
        @(negedge clk); we = 1; w_addr = 8'hFF; w_data = 8'h11;
        @(negedge clk); we = 1; w_addr = 8'h00; w_data = 8'h22;
        @(negedge clk); we = 0; re = 1; r_addr = 8'hFF; check_read(8'hFF);
        @(negedge clk);         re = 1; r_addr = 8'h00; check_read(8'h00);
        @(negedge clk); re = 0;

        // =======================================================
        $display("\n====== RUNNING TC5: WRITE-DISABLE NOISE IMMUNITY ======");
        @(negedge clk); we = 1; w_addr = 8'h10; w_data = 8'hEE;
        for (int i = 0; i < 10; i++) begin
            @(negedge clk);
            we = 0; w_addr = $urandom; w_data = $urandom; // Blast the bus with noise
        end
        @(negedge clk); re = 1; r_addr = 8'h10; check_read(8'h10); // Guarantee 0xEE survived
        @(negedge clk); re = 0;

        // =======================================================
        $display("\n====== RUNNING TC6: CHECKERBOARD CROSSTALK ======");
        for (int i = 0; i < 256; i++) begin
            @(negedge clk);
            we = 1; w_addr = i; w_data = (i % 2 == 0) ? 8'hAA : 8'h55;
        end
        @(negedge clk); we = 0;
        for (int i = 0; i < 256; i++) begin
            @(negedge clk); re = 1; r_addr = i; check_read(i);
        end
        @(negedge clk); re = 0;

        // =======================================================
        $display("\n====== RUNNING TC7: EXTREME BOUNDS (+127, -128, 0) ======");
        @(negedge clk); we = 1; w_addr = 8'h20; w_data = 8'h7F;
        @(negedge clk); we = 1; w_addr = 8'h30; w_data = 8'h80;
        @(negedge clk); we = 1; w_addr = 8'h40; w_data = 8'h00;
        @(negedge clk); we = 0;
        @(negedge clk); re = 1; r_addr = 8'h20; check_read(8'h20);
        @(negedge clk); re = 1; r_addr = 8'h30; check_read(8'h30);
        @(negedge clk); re = 1; r_addr = 8'h40; check_read(8'h40);
        @(negedge clk); re = 0;

        // =======================================================
        $display("\n====== RUNNING TC8: READ-DISABLE RETENTION ======");
        @(negedge clk); we = 1; w_addr = 8'h60; w_data = 8'hCC;
        @(negedge clk); we = 0; re = 1; r_addr = 8'h60; check_read(8'h60);
        @(negedge clk); re = 0; r_addr = 8'h00; 
        
        // Wait 1 clock cycle to ensure the output register held the last value
        @(posedge clk); #1;
        if (r_data !== 8'hCC) begin
             $error("[SCB_FAIL] Read-Disable Floating Bus! Expected 8'hCC, Got %0h", r_data);
             failed++;
        end else passed++;
        total_checks++;

        // =======================================================
        $display("\n====== RUNNING TC9: MARCH-C LITE ======");
        // Step 1: Write 0s
        for (int i = 0; i < 256; i++) begin
            @(negedge clk); we = 1; re = 0; w_addr = i; w_data = 8'h00;
        end
        // Step 2: Ascending (Read 0, Write 1s)
        for (int i = 0; i < 256; i++) begin
            @(negedge clk); we = 0; re = 1; r_addr = i; check_read(i);
            @(negedge clk); we = 1; re = 0; w_addr = i; w_data = 8'hFF;
        end
        // Step 3: Descending (Read 1s, Write 0s)
        for (int i = 255; i >= 0; i--) begin
            @(negedge clk); we = 0; re = 1; r_addr = i; check_read(i);
            @(negedge clk); we = 1; re = 0; w_addr = i; w_data = 8'h00;
        end
        @(negedge clk); we = 0; re = 0;

        // =======================================================
        $display("\n====== RUNNING TC10: 1000-CYCLE RANDOM STRESS ======");
        for (int i = 0; i < 1000; i++) begin
            @(negedge clk);
            we = $urandom_range(0, 1);
            re = $urandom_range(0, 1);
            w_addr = $urandom;
            r_addr = $urandom;
            w_data = $urandom;

            // Only invoke the checker if we are actually requesting a read this cycle
            if (re) begin
                check_read(r_addr);
            end
        end
        @(negedge clk); we = 0; re = 0;

        // --------------------------------------------------------
        // 6. FINAL SIMULATION SUMMARY
        // --------------------------------------------------------
        $display("\n========================================");
        $display("Total Read Checks : %0d", total_checks);
        $display("Passed            : %0d", passed);
        $display("Failed            : %0d", failed);
        if (failed == 0)
            $display("TEST STATUS       : PASS");
        else
            $display("TEST STATUS       : FAIL");
        $display("========================================\n");

        $finish;
    end

endmodule
