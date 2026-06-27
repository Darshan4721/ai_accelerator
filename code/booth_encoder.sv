// Radix-4 Booth Encoder (Flattened Ports for Tool Compatibility)
module booth_encoder (
    input  logic [7:0] multiplier,
    output logic [11:0] sel_flat, // 4 * 3-bit signals
    output logic [3:0]  neg       
);
    logic [2:0] sel [0:3];
    logic [8:0] m_ext;
    assign m_ext = {multiplier, 1'b0};

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : gen_booth
            logic [2:0] window;
            assign window = m_ext[2*i+2 : 2*i];
            always_comb begin
                case (window)
                    3'b000, 3'b111: begin sel[i] = 3'b000; neg[i] = 1'b0; end
                    3'b001, 3'b010: begin sel[i] = 3'b001; neg[i] = 1'b0; end
                    3'b011:         begin sel[i] = 3'b010; neg[i] = 1'b0; end
                    3'b100:         begin sel[i] = 3'b010; neg[i] = 1'b1; end
                    3'b101, 3'b110: begin sel[i] = 3'b001; neg[i] = 1'b1; end
                    default:        begin sel[i] = 3'b000; neg[i] = 1'b0; end
                endcase
            end
            assign sel_flat[i*3 +: 3] = sel[i];
        end
    endgenerate
endmodule
