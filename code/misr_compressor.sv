// 512-bit Multiple Input Signature Register (MISR)
// Compresses 16 parallel 32-bit partial sum outputs into a single signature
module misr_compressor (
    input  logic         clk,
    input  logic         rst,
    input  logic         en,
    input  logic [511:0] data_in, // 16 * 32-bit outputs
    output logic [511:0] signature
);

    logic [511:0] misr_reg;

    // Polynomial for 512-bit MISR (Standard CRC-512 style feedback)
    always_ff @(posedge clk ) begin
        if (rst) begin
            misr_reg <= 512'h0;
        end else if (en) begin
            // Shift and XOR incoming data with current signature
            // This compresses the spatial data (parallel inputs) and temporal data (over cycles)
            misr_reg <= {misr_reg[510:0], 1'b0} ^ data_in ^ (misr_reg[511] ? 512'h10000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000087 : 512'h0);
        end
    end

    assign signature = misr_reg;

endmodule

