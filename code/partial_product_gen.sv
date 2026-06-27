// Partial Product Generator (Flattened Ports for Tool Compatibility)
module partial_product_gen (
    input  logic [7:0]  multiplicand,
    input  logic [11:0] sel_flat,
    input  logic [3:0]  neg,
    output logic [63:0] pp_flat // 4 * 16-bit products
);
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : gen_pp
            logic [2:0]  sel;
            logic [15:0] base_pp;
            logic [15:0] final_pp;
            
            assign sel = sel_flat[i*3 +: 3];
            
            always_comb begin
                case (sel)
                    3'b001:  base_pp = {{8{multiplicand[7]}}, multiplicand};
                    3'b010:  base_pp = {{7{multiplicand[7]}}, multiplicand, 1'b0};
                    default: base_pp = 16'b0;
                endcase
                final_pp = neg[i] ? ~base_pp : base_pp;
            end
            assign pp_flat[i*16 +: 16] = final_pp;
        end
    endgenerate
endmodule
