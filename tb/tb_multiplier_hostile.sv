// Hostile Testbench for Multiplier Leaf Nodes
// Updated for 5-Scenario Rigorous Requirement and Flattened Ports
import uvm_report_pkg::*;

module tb_multiplier_hostile;
    logic [7:0]  multiplier, multiplicand;
    logic [11:0] sel_flat;
    logic [3:0]  neg;
    logic [63:0] pp_flat;
    logic [31:0] sum_vec, carry_vec;
    logic [31:0] final_result;

    // Instantiate Modules (Using flattened ports as per MECHANICAL rules)
    booth_encoder dut_enc (
        .multiplier(multiplier),
        .sel_flat(sel_flat),
        .neg(neg)
    );
    
    partial_product_gen dut_pp (
        .multiplicand(multiplicand),
        .sel_flat(sel_flat),
        .neg(neg),
        .pp_flat(pp_flat)
    );
    
    wallace_tree dut_wallace (
        .pp_flat(pp_flat),
        .neg(neg),
        .sum_vec(sum_vec),
        .carry_vec(carry_vec)
    );

    assign final_result = sum_vec + carry_vec;

    // Scenario 1: Zero & Identity Properties
    task automatic test_identity();
        bit error = 0;
        $display("[TEST CASE 1] Checking Zero and Identity (1*X, 0*X)...");
        multiplicand = 55; multiplier = 1; #1;
        if ($signed(final_result[15:0]) !== 55) error = 1;
        multiplicand = 55; multiplier = 0; #1;
        if ($signed(final_result[15:0]) !== 0) error = 1;
        multiplicand = 0;  multiplier = -128; #1;
        if ($signed(final_result[15:0]) !== 0) error = 1;
        print_test_box("IDENTITY TEST", error);
    endtask

    // Scenario 2: Powers of Two (Shifts)
    task automatic test_powers_of_two();
        bit error = 0;
        $display("[TEST CASE 2] Checking Powers of Two (Shifts)...");
        for (int i=0; i<7; i++) begin
            multiplicand = 3; multiplier = (1 << i); #1;
            if ($signed(final_result[15:0]) !== (3 << i)) error = 1;
        end
        print_test_box("POWERS OF TWO TEST", error);
    endtask

    // Scenario 3: Signed Extremes
    task automatic test_signed_extremes();
        bit error = 0;
        $display("[TEST CASE 3] Checking Signed Extremes (-128 * X)...");
        multiplicand = -128; multiplier = -128; #1;
        if ($signed(final_result[15:0]) !== 16384) error = 1;
        multiplicand = -128; multiplier = 127; #1;
        if ($signed(final_result[15:0]) !== -16256) error = 1;
        print_test_box("SIGNED EXTREMES TEST", error);
    endtask

    // Scenario 4: Signed Negative One
    task automatic test_neg_one();
        bit error = 0;
        $display("[TEST CASE 4] Checking Multiplications by -1...");
        multiplicand = 100; multiplier = -1; #1;
        if ($signed(final_result[15:0]) !== -100) error = 1;
        multiplicand = -50; multiplier = -1; #1;
        if ($signed(final_result[15:0]) !== 50) error = 1;
        print_test_box("NEG-ONE TEST", error);
    endtask

    // Scenario 5: Exhaustive Sweep
    task automatic run_exhaustive_test();
        bit error = 0;
        $display("[TEST CASE 5] Running 65,536 exhaustive combinations...");
        for (int i = -128; i < 128; i++) begin
            for (int j = -128; j < 128; j++) begin
                multiplicand = i[7:0];
                multiplier   = j[7:0];
                #1;
                if ($signed(final_result[15:0]) !== ($signed(multiplicand) * $signed(multiplier))) begin
                    error = 1;
                end
            end
        end
        print_test_box("EXHAUSTIVE MULTIPLIER TEST", error);
    endtask

    initial begin
        print_banner("BOOTH-WALLACE MULTIPLIER RIGOROUS VERIFICATION");
        reset_counters();
        
        test_identity();
        test_powers_of_two();
        test_signed_extremes();
        test_neg_one();
        run_exhaustive_test();

        print_final_report();
        $finish;
    end

endmodule
