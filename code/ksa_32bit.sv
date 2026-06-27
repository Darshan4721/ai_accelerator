// High-performance 32-bit Kogge-Stone Adder
// Adapted for use in the TensorCore_Lite PE
module ksa_32bit (
    input  logic [31:0] a,
    input  logic [31:0] b,
    input  logic cin,
    output logic [31:0] sum,
    output logic cout
);
    localparam width = 32;
    localparam final_stage = 5; // $clog2(32)

    logic [width - 1:0] propagate [final_stage:0];
    logic [width - 1:0] gen       [final_stage:0];

    // Pre-processing stage
    assign propagate[0] = a ^ b;
    assign gen[0][0] = (a[0] & b[0]) | (propagate[0][0] & cin);
    assign gen[0][width-1:1] = a[width-1:1] & b[width-1:1];

    // Kogge-Stone Parallel Prefix Network
    genvar i, j;
    generate
        for (i = 1; i <= final_stage; i = i + 1) begin : stage_loop
            localparam int jump = 1 << (i - 1);
            for (j = 0; j < width; j = j + 1) begin : calc_loop
                if (j >= jump) begin
                    assign gen[i][j] = gen[i-1][j] | (propagate[i-1][j] & gen[i-1][j-jump]);
                    assign propagate[i][j] = propagate[i-1][j] & propagate[i-1][j-jump];
                end else begin
                    assign gen[i][j] = gen[i-1][j];
                    assign propagate[i][j] = propagate[i-1][j];
                end
            end
        end
    endgenerate

    // Post-processing stage
    assign sum[0] = propagate[0][0] ^ cin;
    assign sum[width-1:1] = propagate[0][width-1:1] ^ gen[final_stage][width-2:0];
    assign cout = gen[final_stage][width-1];

endmodule
