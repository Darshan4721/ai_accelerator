// Wallace Tree (Flattened Ports and Improved Sign Extension)
module wallace_tree (
    input  logic [63:0] pp_flat,
    input  logic [3:0]  neg, 
    output logic [31:0] sum_vec,
    output logic [31:0] carry_vec
);
    logic [15:0] pp [0:3];
    generate
        for (genvar g = 0; g < 4; g++) assign pp[g] = pp_flat[g*16 +: 16];
    endgenerate

    // Alignment and Correct Sign Extension to 32 bits
    logic [31:0] v0, v1, v2, v3;
    assign v0 = {{16{pp[0][15]}}, pp[0]};
    assign v1 = {{14{pp[1][15]}}, pp[1], 2'b00};
    assign v2 = {{12{pp[2][15]}}, pp[2], 4'b0000};
    assign v3 = {{10{pp[3][15]}}, pp[3], 6'b000000};

    // Booth 2's Complement Correction Vector
    logic [31:0] v_corr;
    assign v_corr = {25'b0, neg[3], 1'b0, neg[2], 1'b0, neg[1], 1'b0, neg[0]}; 

    // CSA Tree
    logic [31:0] s1, c1, s2, c2;
    
    // Layer 1: v0, v1, v2 -> s1, c1
    generate
        for (genvar i = 0; i < 32; i++) begin : csa1
            assign s1[i] = v0[i] ^ v1[i] ^ v2[i];
            if (i == 0) assign c1[i] = 1'b0;
            else        assign c1[i] = (v0[i-1] & v1[i-1]) | (v0[i-1] & v2[i-1]) | (v1[i-1] & v2[i-1]);
        end
    endgenerate

    // Layer 2: s1, c1, v3 -> s2, c2
    generate
        for (genvar i = 0; i < 32; i++) begin : csa2
            assign s2[i] = s1[i] ^ c1[i] ^ v3[i];
            if (i == 0) assign c2[i] = 1'b0;
            else        assign c2[i] = (s1[i-1] & c1[i-1]) | (s1[i-1] & v3[i-1]) | (c1[i-1] & v3[i-1]);
        end
    endgenerate

    // Layer 3: s2, c2, v_corr -> sum_vec, carry_vec
    generate
        for (genvar i = 0; i < 32; i++) begin : csa3
            assign sum_vec[i] = s2[i] ^ c2[i] ^ v_corr[i];
            if (i == 0) assign carry_vec[i] = 1'b0;
            else        assign carry_vec[i] = (s2[i-1] & c2[i-1]) | (s2[i-1] & v_corr[i-1]) | (c2[i-1] & v_corr[i-1]);
        end
    endgenerate
endmodule
