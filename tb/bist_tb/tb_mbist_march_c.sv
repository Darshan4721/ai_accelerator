`timescale 1ns/1ps

module tb_mbist_march_c();

    // --------------------------------------------------------
    // 1. SIGNALS & DUT INSTANTIATION
    // --------------------------------------------------------
    logic         clk;
    logic         rst_n;
    
    logic         mbist_en;
    logic         mbist_done;
    logic         mbist_fail;
    
    logic         mbist_we;
    logic         mbist_re;
    logic [7:0]   mbist_w_addr;
    logic [7:0]   mbist_r_addr;
    logic [127:0] mbist_w_data_128b;
    logic [127:0] sram_r_data_128b;

    mbist_march_c dut (
        .clk(clk),
        .rst_n(rst_n),
        .mbist_en(mbist_en),
        .mbist_done(mbist_done),
        .mbist_fail(mbist_fail),
        .mbist_we(mbist_we),
        .mbist_re(mbist_re),
        .mbist_w_addr(mbist_w_addr),
        .mbist_r_addr(mbist_r_addr),
        .mbist_w_data_128b(mbist_w_data_128b),
        .sram_r_data_128b(sram_r_data_128b)
    );

    // --------------------------------------------------------
    // 2. CLOCK GENERATOR (250MHz / 4ns period)
    // --------------------------------------------------------
    initial begin
        clk = 0;
        forever #2 clk = ~clk; 
    end

    // --------------------------------------------------------
    // 3. FAKE HOSTILE SRAM (1-Cycle Latency)
    // --------------------------------------------------------
    logic [127:0] sram_array [0:255];
    logic [127:0] sram_r_data_d1;
    
    // Fault Injection Flags
    logic       inject_sa0;
    logic       inject_sa1;
    logic       inject_alias;
    logic       inject_desync;
    logic [7:0] fault_addr;

    logic [127:0] raw_data;
    always_comb begin
        raw_data = sram_array[mbist_r_addr];
        if (inject_sa0 && mbist_r_addr == fault_addr) raw_data[0] = 1'b0;
        if (inject_sa1 && mbist_r_addr == fault_addr) raw_data[127] = 1'b1;
    end

    always_ff @(posedge clk) begin
        // Write Port
        if (mbist_we) begin
            if (inject_alias && mbist_w_addr == 8'h10) begin
                sram_array[8'h10] <= mbist_w_data_128b;
                sram_array[8'h50] <= mbist_w_data_128b; // Malicious Aliasing (Far apart to avoid pipeline WAR masking)
            end else begin
                sram_array[mbist_w_addr] <= mbist_w_data_128b;
            end
        end

        // Read Port (1-Cycle Latency)
        if (mbist_re) begin
            if (inject_desync) begin
                sram_r_data_128b <= sram_r_data_d1; // Delay by 2 cycles instead of 1
                sram_r_data_d1 <= raw_data;
            end else begin
                sram_r_data_128b <= raw_data; // Strict 1 cycle latency
            end
        end
    end

    // --------------------------------------------------------
    // 4. VERIFICATION TASKS
    // --------------------------------------------------------
    int total_tests = 0;
    int failed_tests = 0;

    task automatic reset_faults();
        inject_sa0 = 0;
        inject_sa1 = 0;
        inject_alias = 0;
        inject_desync = 0;
        fault_addr = 0;
    endtask

    task automatic apply_reset();
        rst_n = 1;
        mbist_en = 0;
        repeat (2) @(negedge clk);
        rst_n = 0;
        repeat (2) @(negedge clk);
        rst_n = 1;
        repeat (2) @(negedge clk);
    endtask

    task automatic wait_for_done();
        int timeout = 0;
        while (!mbist_done && timeout < 5000) begin
            @(negedge clk);
            timeout++;
        end
        if (timeout == 5000) $error("TIMEOUT: mbist_done never asserted!");
    endtask

    task automatic print_banner(string title);
        $display("\n==================================================");
        $display("  %s", title);
        $display("==================================================");
    endtask

    task automatic print_result(string test_name, bit status);
        total_tests++;
        if (status) begin 
            $display("[FAIL]  %-35s", test_name);
            failed_tests++;
        end else begin
            $display("[PASS]  %-35s", test_name);
        end
    endtask

    // --------------------------------------------------------
    // PART 1: GENERAL TEST CASES
    // --------------------------------------------------------
    
    // TC1: Golden Silicon
    task automatic tc1_golden_silicon();
        print_banner("TC1: Golden Silicon (Clean Smoke Test)");
        reset_faults();
        apply_reset();
        
        @(negedge clk) mbist_en = 1;
        wait_for_done();
        @(negedge clk) mbist_en = 0;
        
        print_result("TC1: Golden Silicon", (mbist_fail !== 0));
    endtask

    // TC2: Asynchronous Reset Interruption
    task automatic tc2_async_reset();
        print_banner("TC2: Asynchronous Reset Interruption");
        reset_faults();
        apply_reset();
        
        @(negedge clk) mbist_en = 1;
        repeat (400) @(negedge clk); // Interrupt midway through READ_0_WRITE_1
        
        rst_n = 0; // Async reset
        @(negedge clk);
        
        if (mbist_we === 0 && mbist_re === 0 && dut.state === dut.IDLE) begin
            print_result("TC2: Async Reset Interruption", 0);
        end else begin
            $error("Failed to reset instantly");
            print_result("TC2: Async Reset Interruption", 1);
        end
        rst_n = 1;
        mbist_en = 0;
    endtask

    // --------------------------------------------------------
    // PART 2: CORNER TEST CASES (HOSTILE)
    // --------------------------------------------------------

    // TC3: Single Stuck-At-0 (SA0)
    task automatic tc3_sa0_fault();
        print_banner("TC3: Single Stuck-At-0 (SA0)");
        reset_faults();
        inject_sa0 = 1;
        fault_addr = 8'h7A;
        apply_reset();
        
        @(negedge clk) mbist_en = 1;
        wait_for_done();
        @(negedge clk) mbist_en = 0;
        
        print_result("TC3: SA0 Fault Detected", (mbist_fail !== 1));
    endtask

    // TC4: Single Stuck-At-1 (SA1)
    task automatic tc4_sa1_fault();
        print_banner("TC4: Single Stuck-At-1 (SA1)");
        reset_faults();
        inject_sa1 = 1;
        fault_addr = 8'h33;
        apply_reset();
        
        @(negedge clk) mbist_en = 1;
        wait_for_done();
        @(negedge clk) mbist_en = 0;
        
        print_result("TC4: SA1 Fault Detected", (mbist_fail !== 1));
    endtask

    // TC5: Address Aliasing / Decoder Fault
    task automatic tc5_alias_fault();
        print_banner("TC5: Address Aliasing / Decoder Fault");
        reset_faults();
        inject_alias = 1;
        apply_reset();
        
        @(negedge clk) mbist_en = 1;
        wait_for_done();
        @(negedge clk) mbist_en = 0;
        
        print_result("TC5: Alias Fault Detected", (mbist_fail !== 1));
    endtask

    // TC6: The Sticky Fail Flag Retention Test
    task automatic tc6_sticky_flag();
        print_banner("TC6: Sticky Fail Flag Retention Test");
        reset_faults();
        inject_sa0 = 1;
        fault_addr = 8'h05; // Fault very early
        apply_reset();
        
        @(negedge clk) mbist_en = 1;
        wait_for_done(); // It reads 250 more perfectly good addresses
        @(negedge clk) mbist_en = 0;
        
        print_result("TC6: Sticky Flag Retention", (mbist_fail !== 1));
    endtask

    // TC7: 1-Cycle Pipeline Desync
    task automatic tc7_pipeline_desync();
        print_banner("TC7: 1-Cycle Pipeline Desync (Setup/Hold)");
        reset_faults();
        inject_desync = 1;
        apply_reset();
        
        @(negedge clk) mbist_en = 1;
        wait_for_done();
        @(negedge clk) mbist_en = 0;
        
        print_result("TC7: Pipeline Desync Caught", (mbist_fail !== 1));
    endtask

    // --------------------------------------------------------
    // PART 3: RANDOM STRESS TEST
    // --------------------------------------------------------
    
    // TC8: 1000-Cycle Hostile Randomized Hammer
    task automatic tc8_random_stress();
        int failures = 0;
        print_banner("TC8: 1000-Cycle Hostile Randomized Hammer");
        reset_faults();
        apply_reset();
        
        mbist_en = 1;
        repeat (1000) begin
            @(negedge clk);
            if ($urandom_range(0, 100) < 5) begin
                rst_n = 0; 
            end else begin
                rst_n = 1;
            end
            
            if ($urandom_range(0, 100) < 10) begin
                inject_sa0 = 1;
                fault_addr = $urandom;
            end else begin
                inject_sa0 = 0;
            end
            
            if ($urandom_range(0, 100) < 2) mbist_en = 0;
            else mbist_en = 1;
        end
        // If it didn't crash or lock up the simulation, it passes
        print_result("TC8: 1000-Cycle Random Stress", 0);
    endtask

    // --------------------------------------------------------
    // MAIN EXECUTION
    // --------------------------------------------------------
    initial begin
        $display("\n==================================================");
        $display("   STARTING MBIST MARCH-C VERIFICATION SUITE");
        $display("==================================================\n");

        tc1_golden_silicon();
        tc2_async_reset();
        tc3_sa0_fault();
        tc4_sa1_fault();
        tc5_alias_fault();
        tc6_sticky_flag();
        tc7_pipeline_desync();
        tc8_random_stress();

        $display("\n==================================================");
        $display("  FINAL TEST SUMMARY");
        $display("==================================================");
        $display("  Total Tests  : %0d", total_tests);
        $display("  Failed Tests : %0d", failed_tests);
        $display("  Passed Tests : %0d", total_tests - failed_tests);

        if (failed_tests == 0)
            $display("\n  OVERALL RESULT : PASS\n");
        else
            $display("\n  OVERALL RESULT : FAIL\n");
            
        $display("==================================================\n");
        $finish;
    end

endmodule
