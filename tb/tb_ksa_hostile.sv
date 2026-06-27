// Hostile Testbench for the 32-bit Kogge-Stone Adder
// Refactored to meet the 5-Scenario Rigorous Requirement
import uvm_report_pkg::*;

module tb_ksa_hostile;
    logic [31:0] a, b;
    logic cin;
    logic [31:0] sum;
    logic cout;

    // Instantiate KSA
    ksa_32bit dut (.*);

    // Scenario 1: Basic Addition & Random Stimulus
    task automatic run_random_test();
        bit error = 0;
        $display("[TEST CASE 1] Running 10,000 Random Stimulus Pairs...");
        repeat (10000) begin
            a = $urandom();
            b = $urandom();
            cin = $urandom_range(0,1);
            #1;
            if ({cout, sum} !== (a + b + cin)) begin
                error = 1;
            end
        end
        print_test_box("RANDOM STIMULUS TEST", error);
    endtask

    // Scenario 2: Standard Corner Cases (Zeros and Ones)
    task automatic run_corner_cases();
        bit error = 0;
        $display("[TEST CASE 2] Checking All-Ones and All-Zeros...");
        a = 32'hFFFFFFFF; b = 32'hFFFFFFFF; cin = 1; #1;
        if ({cout, sum} !== 33'h1FFFFFFFF) error = 1;
        a = 0; b = 0; cin = 0; #1;
        if ({cout, sum} !== 0) error = 1;
        print_test_box("BASIC CORNER TEST", error);
    endtask

    // Scenario 3: Walking Bit (Carry Propagation)
    task automatic run_walking_bit_test();
        bit error = 0;
        $display("[TEST CASE 3] Walking 1 through all 32 bits...");
        for (int i=0; i<32; i++) begin
            a = (1 << i);
            b = 32'hFFFFFFFF ^ a; // Every bit 1 except target
            cin = 1; #1;
            if (cout !== 1 || sum !== 0) error = 1;
        end
        print_test_box("WALKING BIT CARRY TEST", error);
    endtask

    // Scenario 4: Signed Arithmetic Boundaries
    task automatic run_signed_boundary_test();
        bit error = 0;
        $display("[TEST CASE 4] Checking Signed Max/Min Boundaries...");
        // Max Positive + 1 (Overflow into sign bit)
        a = 32'h7FFFFFFF; b = 32'h1; cin = 0; #1;
        if (sum !== 32'h80000000) error = 1;
        // Min Negative + (-1)
        a = 32'h80000000; b = 32'hFFFFFFFF; cin = 0; #1;
        if (sum !== 32'h7FFFFFFF || cout !== 1) error = 1;
        print_test_box("SIGNED BOUNDARY TEST", error);
    endtask

    // Scenario 5: Checkerboard Inversion
    task automatic run_checkerboard_test();
        bit error = 0;
        $display("[TEST CASE 5] Checkerboard AAAA + 5555...");
        a = 32'hAAAAAAAA; b = 32'h55555555; cin = 0; #1;
        if (sum !== 32'hFFFFFFFF || cout !== 0) error = 1;
        a = 32'hAAAAAAAA; b = 32'h55555555; cin = 1; #1;
        if (sum !== 32'h00000000 || cout !== 1) error = 1;
        print_test_box("CHECKERBOARD TEST", error);
    endtask

    initial begin
        print_banner("KSA-32BIT ADDER RIGOROUS VERIFICATION");
        reset_counters();
        
        run_random_test();
        run_corner_cases();
        run_walking_bit_test();
        run_signed_boundary_test();
        run_checkerboard_test();

        print_final_report();
        $finish;
    end
endmodule
