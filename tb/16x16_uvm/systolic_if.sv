interface systolic_if(input logic clk);
    logic        rst;
    logic        i_load_weight_valid;
    logic        i_compute_valid;
    logic [7:0]  i_w [0:15];
    logic [7:0]  i_a [0:15];
    logic        o_weight_locked;
    logic        o_valid;
    logic [31:0] o_psum [0:15];
endinterface
