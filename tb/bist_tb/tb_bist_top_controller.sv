`timescale 1ns/1ps

module tb_bist_top_controller();

    // --------------------------------------------------------
    // 1. SIGNALS & DUT INSTANTIATION
    // --------------------------------------------------------
    logic         clk;
    logic         rst_n;
    
    logic         bist_start;
    logic         bist_done;
    logic         bist_fail;
    logic [511:0] expected_misr_sig;
    
    logic         mbist_we;
    logic         mbist_re;
    logic [7:0]   mbist_w_addr;
    logic [7:0]   mbist_r_addr;
    logic [127:0] mbist_w_data_128b;
    logic [127:0] sram_r_data_128b;
    
    logic [127:0] lfsr_prpg_out;
    logic [511:0] array_results_in;

    bist_top_controller #(
        .LBIST_CYCLES(20) // Small number to verify TC7 cycle bounding
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .bist_start(bist_start),
        .bist_done(bist_done),
        .bist_fail(bist_fail),
        .expected_misr_sig(expected_misr_sig),
        .mbist_we(mbist_we),
        .mbist_re(mbist_re),
        .mbist_w_addr(mbist_w_addr),
        .mbist_r_addr(mbist_r_addr),
        .mbist_w_data_128b(mbist_w_data_128b),
        .sram_r_data_128b(sram_r_data_128b),
        .lfsr_prpg_out(lfsr_prpg_out),
        .array_results_in(array_results_in)
    );

    // --------------------------------------------------------
    // 2. CLOCK GENERATOR
    // --------------------------------------------------------
    initial begin
        clk = 0;
        forever #2 clk = ~clk; 
    end

    // --------------------------------------------------------
    // 3. VERIFICATION TASKS & MOCK INJECTORS
    // --------------------------------------------------------
    int total_tests = 0;
    int failed_tests = 0;

    task automatic apply_reset();
        rst_n = 1;
        bist_start = 0;
        expected_misr_sig = 512'hABCD;
        
        // Flush any active forces
        release dut.u_mbist.mbist_done;
        release dut.u_mbist.mbist_fail;
        release dut.u_misr.misr_reg;
        
        // Ensure submodules are deeply reset
        force dut.u_mbist.mbist_done = 0;
        force dut.u_mbist.mbist_fail = 0;
        
        repeat (2) @(negedge clk);
        rst_n = 0;
        repeat (2) @(negedge clk);
        rst_n = 1;
        repeat (2) @(negedge clk);
    endtask

    task automatic run_mbist_phase(bit fail_flag);
        // Wait for FSM to enter S_RUN_MBIST (3'd1)
        wait(dut.state == 3'd1);
        repeat ($urandom_range(5, 15)) @(negedge clk); // Random mock completion delay
        
        if (fail_flag) force dut.u_mbist.mbist_fail = 1'b1;
        else           force dut.u_mbist.mbist_fail = 1'b0;
        
        force dut.u_mbist.mbist_done = 1;
        
        @(negedge clk); // Allow FSM to see the done flag and transition
        
        force dut.u_mbist.mbist_done = 0;
        force dut.u_mbist.mbist_fail = 0; // Return to 0. The FSM must successfully latch the fail.
    endtask

    task automatic run_lbist_phase(bit match);
        // Wait for FSM to enter S_RUN_LBIST (3'd2)
        wait(dut.state == 3'd2);
        
        if (match) force dut.u_misr.misr_reg = expected_misr_sig;
        else       force dut.u_misr.misr_reg = ~expected_misr_sig;
        
        // Wait for FSM to reach S_DONE (3'd4)
        wait(dut.state == 3'd4);
        release dut.u_misr.misr_reg;
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
    task automatic tc1_clean_run();
        print_banner("TC1: Golden Silicon (Clean Smoke Test)");
        apply_reset();
        
        @(negedge clk) bist_start = 1;
        @(negedge clk) bist_start = 0;
        
        fork
            run_mbist_phase(0); // Pass
            run_lbist_phase(1); // Match
        join
        
        wait(bist_done == 1);
        @(negedge clk);
        print_result("TC1: Golden Silicon", (bist_done !== 1 || bist_fail !== 0));
    endtask

    // TC2: Asynchronous Reset Interruption
    task automatic tc2_async_reset();
        print_banner("TC2: Asynchronous Reset Interruption");
        apply_reset();
        
        @(negedge clk) bist_start = 1;
        @(negedge clk) bist_start = 0;
        
        // Finish MBIST phase normally
        run_mbist_phase(0);
        
        // Wait until we are in the middle of the LBIST phase
        wait(dut.state == 3'd2);
        repeat(5) @(negedge clk); 
        
        rst_n = 0; // Async reset mid-operation!
        @(negedge clk);
        
        // Check if everything dropped to 0 instantly
        if (dut.mbist_en == 0 && dut.lfsr_en == 0 && dut.misr_en == 0 && dut.lbist_counter == 0 && dut.state == 3'd0) begin
            print_result("TC2: Async Reset Interruption", 0);
        end else begin
            $error("Failed to instantly reset hardware and registers.");
            print_result("TC2: Async Reset Interruption", 1);
        end
        rst_n = 1;
    endtask

    // --------------------------------------------------------
    // PART 2: CORNER TEST CASES (FAULT INJECTION)
    // --------------------------------------------------------

    // TC3: Isolated Memory Failure
    task automatic tc3_memory_fail();
        print_banner("TC3: Isolated Memory Failure (MBIST Catch)");
        apply_reset();
        
        @(negedge clk) bist_start = 1;
        @(negedge clk) bist_start = 0;
        
        fork
            run_mbist_phase(1); // Force MBIST Fault!
            run_lbist_phase(1); // Logic passes perfectly
        join
        
        wait(bist_done == 1);
        @(negedge clk);
        print_result("TC3: Isolated Memory Failure", (bist_fail !== 1 || bist_done !== 1));
    endtask

    // TC4: Isolated Logic Failure
    task automatic tc4_logic_fail();
        print_banner("TC4: Isolated Logic Failure (MISR Mismatch)");
        apply_reset();
        
        @(negedge clk) bist_start = 1;
        @(negedge clk) bist_start = 0;
        
        fork
            run_mbist_phase(0); // Memory passes perfectly
            run_lbist_phase(0); // Force MISR Mismatch!
        join
        
        wait(bist_done == 1);
        @(negedge clk);
        print_result("TC4: Isolated Logic Failure", (bist_fail !== 1 || bist_done !== 1));
    endtask

    // TC5: Catastrophic Double Failure
    task automatic tc5_double_fail();
        print_banner("TC5: Catastrophic Double Failure");
        apply_reset();
        
        @(negedge clk) bist_start = 1;
        @(negedge clk) bist_start = 0;
        
        fork
            run_mbist_phase(1); // Fail!
            run_lbist_phase(0); // Fail!
        join
        
        wait(bist_done == 1);
        @(negedge clk);
        print_result("TC5: Catastrophic Double Failure", (bist_fail !== 1 || bist_done !== 1));
    endtask

    // TC6: Premature / Glitchy bist_start
    task automatic tc6_glitchy_start();
        print_banner("TC6: Premature / Glitchy bist_start Injection");
        apply_reset();
        
        @(negedge clk) bist_start = 1;
        @(negedge clk) bist_start = 0;
        
        fork
            run_mbist_phase(0);
            begin
                wait(dut.state == 3'd2);
                repeat(5) @(negedge clk);
                // Inject an illegal glitchy start while running
                bist_start = 1;
                @(negedge clk) bist_start = 0;
            end
            run_lbist_phase(1);
        join
        
        wait(bist_done == 1);
        @(negedge clk);
        print_result("TC6: Glitchy bist_start Handled", (bist_done !== 1 || bist_fail !== 0));
    endtask

    // TC7: LBIST Cycle Boundary Check
    task automatic tc7_cycle_boundary();
        int cycles_counted = 0;
        print_banner("TC7: LBIST Cycle Boundary Check");
        apply_reset();
        
        @(negedge clk) bist_start = 1;
        @(negedge clk) bist_start = 0;
        
        fork
            run_mbist_phase(0);
            run_lbist_phase(1);
            begin
                wait(dut.state == 3'd2);
                wait(dut.lfsr_en == 1); // Wait for the enable to physically assert
                while (dut.lfsr_en && dut.misr_en) begin
                    @(negedge clk);
                    cycles_counted++;
                end
            end
        join
        
        if (cycles_counted == 20) print_result("TC7: LBIST Cycle Boundary Check", 0);
        else begin
            $error("Counter ran for %0d cycles instead of exactly 20!", cycles_counted);
            print_result("TC7: LBIST Cycle Boundary Check", 1);
        end
    endtask

    // --------------------------------------------------------
    // PART 3: RANDOM STRESS TEST
    // --------------------------------------------------------

    // TC8: 1000-Cycle Randomized FSM Hammer
    task automatic tc8_random_stress();
        bit expected_fail;
        bit memory_fail;
        bit logic_match;
        
        print_banner("TC8: 1000-Cycle Randomized FSM Hammer");
        
        for (int i=0; i<50; i++) begin
            apply_reset();
            memory_fail = $urandom_range(0,1);
            logic_match = $urandom_range(0,1);
            
            // Expected logical OR outcome
            expected_fail = memory_fail | !logic_match;
            
            @(negedge clk) bist_start = 1;
            @(negedge clk) bist_start = 0;
            
            fork
                run_mbist_phase(memory_fail);
                run_lbist_phase(logic_match);
            join
            
            wait(bist_done == 1);
            @(negedge clk);
            
            if (bist_fail !== expected_fail || bist_done !== 1) begin
                $error("Failed Random Run %0d. Expected Fail=%0b, Actual=%0b", i, expected_fail, bist_fail);
                print_result("TC8: 1000-Cycle Random Stress", 1);
                return;
            end
        end
        print_result("TC8: 1000-Cycle Random Stress", 0);
    endtask

    // --------------------------------------------------------
    // MAIN EXECUTION
    // --------------------------------------------------------
    initial begin
        $display("\n==================================================");
        $display("   STARTING BIST TOP CONTROLLER VERIFICATION");
        $display("==================================================\n");

        tc1_clean_run();
        tc2_async_reset();
        tc3_memory_fail();
        tc4_logic_fail();
        tc5_double_fail();
        tc6_glitchy_start();
        tc7_cycle_boundary();
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
