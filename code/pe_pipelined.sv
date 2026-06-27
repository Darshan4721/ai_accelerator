// Processing Element (PE) - Bulletproof ASIC Version
// Implementation: Daisy-Chain Weights + Control Wavefront
// Latency: a_out (1-cycle), psum_out (2-cycle)
`timescale 1ns/1ps

module pe_pipelined (
    input  logic        clk,
    input  logic        rst, // Synchronous active-high reset

    // Control Inputs (From Top/Left Neighbor)
    input  logic        req_load_weight_in,
    input  logic        req_work_in,

    // Control Outputs (To Bottom/Right Neighbor)
    output logic        req_load_weight_out,
    output logic        req_work_out,
    output logic        ack_weight_locked,

    // Data Inputs
    input  logic [7:0]  w_in,
    input  logic [7:0]  a_in,
    input  logic [31:0] psum_in,

    // Data Outputs
    output logic [7:0]  w_out,
    output logic [7:0]  a_out,
    output logic [31:0] psum_out
);

    // --- PHASE 1: Weight Loading (Self-Routing Daisy-Chain) ---
    logic [7:0] w_reg;
    logic [7:0] w_pass_reg;
    logic       load_out_reg;
    logic       weight_locked_reg;

    // Edge Detector for Compute Phase
    logic prev_req_work;
    always_ff @(posedge clk) begin
        if (rst) prev_req_work <= 1'b0;
        else     prev_req_work <= req_work_in;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            w_reg             <= 8'h0;
            w_pass_reg        <= 8'h0;
            load_out_reg      <= 1'b0;
            weight_locked_reg <= 1'b0; // Starts strictly UNLOCKED
        end else if (prev_req_work == 1'b1 && req_work_in == 1'b0) begin
            // AUTO-UNLOCK: The Compute phase just finished. 
            // Flush the lock so the PE accepts new weights on the next load cycle.
            weight_locked_reg <= 1'b0;
            load_out_reg      <= 1'b0;
        end else begin
            if (req_load_weight_in) begin
                if (!weight_locked_reg) begin
                    // I am empty: Lock this weight!
                    w_reg <= w_in; 
                    weight_locked_reg <= 1'b1;
                    load_out_reg <= 1'b0; // Do NOT pass request down yet
                end else begin
                    // I am full: Route this weight to my neighbor!
                    w_pass_reg <= w_in;
                    load_out_reg <= 1'b1;
                end
            end else begin
                // No incoming valid weight
                load_out_reg <= 1'b0;
            end
        end
    end

    assign w_out = w_pass_reg; 
    assign req_load_weight_out = load_out_reg;
    assign ack_weight_locked = weight_locked_reg; // Safe, sticky flag

    // --- PHASE 2: Compute Wavefront (2-Stage Math) ---

    // STAGE 1: Multiplier Sampling & Pass-right
    logic [7:0]  act_reg_s1;
    logic        work_reg_s1;
    logic [31:0] mult_sum_s1;
    logic [31:0] mult_carry_s1;

    // Combinational Multiplier
    logic [11:0] booth_sel;
    logic [3:0]  booth_neg;
    logic [63:0] pp_flat;
    logic [31:0] m_sum_comb, m_carry_comb;

    booth_encoder b_enc (.multiplier(w_reg), .sel_flat(booth_sel), .neg(booth_neg));
    partial_product_gen pp_gen (.multiplicand(a_in), .sel_flat(booth_sel), .neg(booth_neg), .pp_flat(pp_flat));
    wallace_tree w_tree (.pp_flat(pp_flat), .neg(booth_neg), .sum_vec(m_sum_comb), .carry_vec(m_carry_comb));

    always_ff @(posedge clk) begin
        if (rst) begin
            act_reg_s1    <= 8'h0;
            work_reg_s1   <= 1'b0;
            mult_sum_s1   <= 32'h0;
            mult_carry_s1 <= 32'h0;
        end else begin
            // We drive the multiplier combinationally from a_in to save 1 cycle
            if (req_work_in) begin
                act_reg_s1    <= a_in;
                mult_sum_s1   <= m_sum_comb;
                mult_carry_s1 <= m_carry_comb;
            end
            work_reg_s1 <= req_work_in;
        end
    end

    // STAGE 2: Accumulation & Output Latch
    logic [31:0] acc_reg_s2;
    logic [31:0] f_sum, f_carry, next_psum;

    // 3:2 Compressor for fusion (mult_reg + psum_in)
    generate
        for (genvar i = 0; i < 32; i++) begin : fusion
            assign f_sum[i] = mult_sum_s1[i] ^ mult_carry_s1[i] ^ psum_in[i];
            if (i == 0) assign f_carry[i] = 1'b0;
            else        assign f_carry[i] = (mult_sum_s1[i-1] & mult_carry_s1[i-1]) | 
                                            (mult_sum_s1[i-1] & psum_in[i-1]) | 
                                            (mult_carry_s1[i-1] & psum_in[i-1]);
        end
    endgenerate

    ksa_32bit ksa_inst (.a(f_sum), .b(f_carry), .cin(1'b0), .sum(next_psum), .cout());

    always_ff @(posedge clk) begin
        if (rst) begin
            acc_reg_s2 <= 32'h0;
        end else if (work_reg_s1) begin
            acc_reg_s2 <= next_psum;
        end
    end

    // Final Assignments
    assign a_out        = act_reg_s1;  // 1-cycle latency
    assign req_work_out = work_reg_s1; // 1-cycle latency
    assign psum_out     = acc_reg_s2;  // 2-cycle latency

endmodule
