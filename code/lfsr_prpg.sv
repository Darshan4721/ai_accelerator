// 128-bit Pseudo-Random Pattern Generator (PRPG) using a Galois LFSR
// Polynomial: x^128 + x^126 + x^101 + x^99 + 1 (Primitive)
module lfsr_prpg (
    input  logic         clk,
    input  logic         rst_n,
    input  logic         en,
    input  logic [127:0] seed,
    output logic [127:0] prpg_out
);

    logic [127:0] lfsr_reg;
    // Primitive Taps for 128-bit: 128, 126, 101, 99
    localparam logic [127:0] POLYNOMIAL = 128'h80000000_00000000_00000020_00000005; 

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr_reg <= (seed == 128'h0) ? 128'hACE1_BEEF_CAFE_BABE_DEAD_BEEF_CAFE_BABE : seed;
        end else if (en) begin
            if (lfsr_reg[0]) begin
                lfsr_reg <= (lfsr_reg >> 1) ^ POLYNOMIAL;
            end else begin
                lfsr_reg <= (lfsr_reg >> 1);
            end
        end
    end

    assign prpg_out = lfsr_reg;

endmodule
