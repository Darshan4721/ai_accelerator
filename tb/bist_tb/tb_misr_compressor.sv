`timescale 1ns/1ps

module tb_misr_compressor();
    
    logic         clk;
    logic         rst_n;
    logic         en;
    logic [511:0] data_in;
    logic [511:0] signature;

    // Instantiate the 512-bit MISR Compressor design
    misr_compressor dut (
        .clk(clk),
        .rst_n(rst_n),
        .en(en),
        .data_in(data_in),
        .signature(signature)
    );

    int count = 0;
    int error_count = 0;
    
    // We use a flat history array instead of an associative array because
    // Cadence irun 15.20 has a hashing collision bug for associative array keys > 256 bits.
    logic [511:0] history [0:4095];
    
    logic [511:0] golden_signature;
    parameter num_of_random_stream = 10000;
    int mismatch = 0;
    int matched = 0;

    always #5 clk = ~clk; 

    // Golden model 
    function automatic [511:0] golden (
      input logic rst_n, enable,
      input [511:0] state,
      input [511:0] d
    );
        logic [511:0] next;
        
        if (!rst_n) next = 512'h0;
        else begin
            if (enable) begin
                // Polynomial matching RTL:
                // misr_reg <= {misr_reg[510:0], 1'b0} ^ data_in ^ (misr_reg[511] ? 512'h1000...0087 : 512'h0);
                next = {state[510:0], 1'b0} ^ d ^ (state[511] ? 512'h10000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000087 : 512'h0);
            end else begin
                next = state;
            end
        end
        return next;
    endfunction

    // --------------------------------------------------------
    // Apply Reset
    // --------------------------------------------------------
    task automatic apply_reset ();
        rst_n = 1;
        en = 0;
        data_in = 0;
        repeat (2) @(negedge clk);
        rst_n = 0;
        repeat (2) @(negedge clk);
        rst_n = 1;
        repeat (2) @(negedge clk);
    endtask 

    // --------------------------------------------------------
    // TEST 1: check_poly (Unique Stream Test)
    // --------------------------------------------------------
    task automatic check_poly ();
        $display("===========================================");
        $display("Running check_poly (Unique Stream Test)");
        apply_reset();
        
        @(negedge clk);
        en = 1;
        data_in = 512'h1; // Seed the MISR
        // Clear history
        for (int i=0; i<4096; i++) history[i] = 0;
        count = 0;
        error_count = 0;

        repeat (4095) begin
            bit repeated = 0;
            @(posedge clk); #1; // Wait for update
            
            // Check against all previously generated signatures manually
            for (int i=0; i<count; i++) begin
                if (history[i] === signature) begin
                    repeated = 1;
                    break;
                end
            end

            if (repeated) begin
                error_count++;
            end else begin
                history[count] = signature;
                count++;
            end
            
            @(negedge clk);
            data_in = 0; // Feed 0s for all subsequent cycles to let the polynomial run freely
        end
        
        $display("===========================================");
        $display("It generated %0d signatures without repeating", count);
        $display("It generated %0d signatures with repeating", error_count);
        if (error_count == 0) $display("TEST STATUS ==> PASS <==");
        else $display("TEST STATUS ==> FAIL <==");
        $display("===========================================");
    endtask

    // --------------------------------------------------------
    // TEST 2: Reset Test
    // --------------------------------------------------------
    task automatic reset_test ();
        $display("===========================================");
        $display("Running reset test");
        en = 1;
        data_in = {4{$urandom, $urandom, $urandom, $urandom}}; // Random 512-bit
        
        // Push some data
        repeat(5) @(negedge clk);
        
        // Apply reset
        apply_reset();
        
        @(posedge clk); #1;
        if (signature === 512'h0) begin
            $display("TEST STATUS ==> PASS <==");
            $display("signature out has successfully reset to 0");
        end else begin
            $error("TEST STATUS ==> FAIL <==");
            $error("signature has not reset to seed : expected = 0  got = %0h", signature);
        end
        $display("===========================================");
    endtask 

    // --------------------------------------------------------
    // TEST 3: Enable Pushing Test
    // --------------------------------------------------------
    task automatic test_enable();
        $display("===========================================");
        $display("Running test_enable");
        apply_reset();
        
        @(negedge clk);
        en = 0;
        
        repeat (200) @ (negedge clk) begin
            data_in = {4{$urandom, $urandom, $urandom, $urandom}}; // Noise
        end
        
        @(posedge clk); #1;
        if(signature !== 512'h0) begin 
            $error("TEST STATUS ==> FAIL <==");
            $error("MISR is running even when enable is 0 ");
        end else begin
            $display("TEST STATUS ==> PASS <==");
            $display("MISR is not running when enable is 0");
        end
        $display("===========================================");
    endtask 

    // --------------------------------------------------------
    // TEST 4: random_stream
    // --------------------------------------------------------
    task automatic random_stream();
        $display("===========================================");
        $display("Running random_stream (%0d cycles)", num_of_random_stream);
        apply_reset();
        
        @(negedge clk);
        en = 1;
        golden_signature = 512'h0;
        mismatch = 0;
        matched = 0;

        repeat (num_of_random_stream) begin
            @(negedge clk);
            data_in = {4{$urandom, $urandom, $urandom, $urandom}};
            golden_signature = golden(rst_n, en, golden_signature, data_in);

            @(posedge clk); #1;
            
            if (signature !== golden_signature) begin
                $error("signature : %0h != golden_signature : %0h", signature, golden_signature);
                mismatch++;
            end else begin
                matched++;
            end
        end 

        $display("===========================================");
        $display("Number of mismatches = %0d", mismatch);
        $display("Number of matches = %0d", matched);
        if (matched != num_of_random_stream) begin
            $display("TEST STATUS ==> FAIL <==");
        end else begin
            $display("TEST STATUS ==> PASS <==");
        end
        $display("===========================================");
    endtask 

    // --------------------------------------------------------
    // TEST 5: Linearity / Superposition
    // --------------------------------------------------------
    task automatic test_linearity();
        logic [511:0] seq_X [0:49];
        logic [511:0] seq_Y [0:49];
        logic [511:0] Sx, Sy, Sz, S0;
        int i;

        $display("===========================================");
        $display("Running Linearity / Superposition Test");

        // 1. Generate two random sequences of data
        for (i=0; i<50; i++) begin
            seq_X[i] = {4{$urandom, $urandom, $urandom, $urandom}};
            seq_Y[i] = {4{$urandom, $urandom, $urandom, $urandom}};
        end

        // 2. Run Sequence X
        apply_reset();
        @(negedge clk); en = 1;
        for (i=0; i<50; i++) begin
            @(negedge clk); data_in = seq_X[i];
        end
        @(posedge clk); #1; Sx = signature;

        // 3. Run Sequence Y
        apply_reset();
        @(negedge clk); en = 1;
        for (i=0; i<50; i++) begin
            @(negedge clk); data_in = seq_Y[i];
        end
        @(posedge clk); #1; Sy = signature;

        // 4. Run Sequence Z (X XOR Y)
        apply_reset();
        @(negedge clk); en = 1;
        for (i=0; i<50; i++) begin
            @(negedge clk); data_in = seq_X[i] ^ seq_Y[i];
        end
        @(posedge clk); #1; Sz = signature;

        // 5. Run Sequence 0 (Pure Zero Input)
        apply_reset();
        @(negedge clk); en = 1;
        for (i=0; i<50; i++) begin
            @(negedge clk); data_in = 0;
        end
        @(posedge clk); #1; S0 = signature;

        // 6. Verify the Superposition Math
        if ((Sx ^ Sy) === (Sz ^ S0)) begin
            $display("TEST STATUS ==> PASS <==");
            $display("Math proved: (Sx ^ Sy) == (Sz ^ S0)");
        end else begin
            $display("TEST STATUS ==> FAIL <==");
            $display("Math broken: %h != %h", (Sx ^ Sy), (Sz ^ S0));
        end
        $display("===========================================");
    endtask

    // --------------------------------------------------------
    // MAIN EXECUTION
    // --------------------------------------------------------
    initial begin
        clk = 0; 

        $display();
        $display("STARTING 512-BIT MISR COMPRESSOR VERIFICATION");
        $display();
        
        reset_test();
        check_poly();
        test_enable();
        random_stream();
        test_linearity();
      
        $display();
        $display(" ALL TESTS HAVE COMPLETED ");
        $display();

        $finish;
    end
endmodule
