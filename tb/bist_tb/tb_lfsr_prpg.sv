`timescale 1ns/1ps

module tb_lfsr_prpg();
  
  logic         clk;
  logic         rst_n;
  logic         en;
  logic [127:0] seed;
  logic [127:0] prpg_out;

  // Instantiate the 128-bit LFSR PRPG design
  lfsr_prpg dut (
    .clk(clk),
    .rst_n(rst_n),
    .en(en),
    .seed(seed),
    .prpg_out(prpg_out)
  );

  always #5 clk = ~clk;

  logic [127:0] expected;
  // Golden Model state (module level to persist correctly between test phases)
  logic [127:0] lfsr_model;

  // Polynomial for 128-bit LFSR
  localparam logic [127:0] POLYNOMIAL = 128'h80000000_00000000_00000020_00000005;

  // Associative array to track visited values
  bit visited [logic[127:0]];

  // Golden Model
  function automatic [127:0] lfsr_golden (
      input enable, rst_n,
      input [127:0] current_seed
    );

    if (!rst_n) begin
      lfsr_model = (current_seed == 128'h0) ? 128'hACE1_BEEF_CAFE_BABE_DEAD_BEEF_CAFE_BABE : current_seed;
    end
    else begin
      if (enable) begin
        if (lfsr_model[0]) begin
            lfsr_model = (lfsr_model >> 1) ^ POLYNOMIAL;
        end else begin
            lfsr_model = (lfsr_model >> 1);
        end
      end
    end
    return lfsr_model;
  endfunction

  // Apply Reset
  task automatic apply_rst ();
    print_banner("APPLY RESET");
    rst_n = 1;
    en = 0;
    seed = 128'hDEADBEEF;
    repeat (2) @(negedge clk);
    rst_n = 0;
    repeat (2) @(negedge clk);
    rst_n = 1;
    repeat(20) @(negedge clk);
    
    // Call golden model to sync state
    expected = lfsr_golden(en, 0, seed);
    expected = lfsr_golden(en, 1, seed);
  endtask

    // UNIQUE TEST (Checking first 1000 cycles for uniqueness)
  task automatic unique_test ();
    bit flag_check = 1'b0;
    print_banner("UNIQUE TEST (1000 Cycles)");
    visited.delete();
    
    repeat (1000) @(negedge clk) begin
      en = 1;
      expected = lfsr_golden(1'b1, 1'b1, seed);

      @(posedge clk); #1; // Wait for DUT to sample and update

      if (expected !== prpg_out) begin 
        $error ("NUMBER MISMATCHED      expected = %0h      got = %0h   ", expected, prpg_out);
        flag_check = 1'b1;
      end

      if (visited.exists(prpg_out)) begin
        $error ("NUMBER REPEATED      expected = %0h      got = %0h  ", expected, prpg_out);
        flag_check = 1'b1;
      end
      visited[prpg_out] = 1;
    end

    print_result("UNIQUE TEST", flag_check);
  endtask

  // RANDOM TEST (1000 cycles)
  task automatic run ();
    bit flag_check = 1'b0;
    print_banner("1000 RANDOM TEST");
    
    repeat (1000) @(negedge clk) begin
      en = $urandom_range (0, 1);
      
      expected = lfsr_golden(en, 1'b1, seed);

      @(posedge clk); #1;

      if (expected !== prpg_out) begin
        $error("NUMBER MISMATCH IN RANDOM 1000 CYCLES   expected = %0h   got = %0h ", expected, prpg_out);
        flag_check = 1'b1;
      end
    end
    
    print_result("1000 RANDOM TEST", flag_check);
  endtask

  // Helper tasks for reporting
  task automatic print_banner(string title);
    $display("\n==================================================");
    $display("  %s", title);
    $display("==================================================\n");
  endtask

  int total_tests_number;
  int failed_tests_number; 

  initial begin
    total_tests_number = 0;
    failed_tests_number = 0;
  end

  task automatic print_result(string test_name, bit status);
    total_tests_number = total_tests_number + 1;
    if (status) begin 
      $display("[FAIL]  %-25s", test_name);
      failed_tests_number = failed_tests_number + 1;
    end
    else
      $display("[PASS]  %-25s", test_name);
  endtask

  task automatic print_report ();
    print_banner("FINAL TEST SUMMARY");
    $display("Total Tests  : %0d", total_tests_number);
    $display("Failed Tests : %0d", failed_tests_number);
    $display("Passed Tests : %0d", total_tests_number - failed_tests_number);

    if (failed_tests_number == 0)
      $display("\nOVERALL RESULT : PASS\n");
    else
      $display("\nOVERALL RESULT : FAIL\n");
  endtask

  initial begin
    clk = 0;
    
    $display();
    $display("STARTING 128-BIT LFSR PRPG VERIFICATION");
    $display();
    
    apply_rst();
    unique_test();
    
    apply_rst();
    run();
    
    print_report();

    $display(" ALL TESTS HAVE COMPLETED ");
    #100 $finish;
  end

endmodule
