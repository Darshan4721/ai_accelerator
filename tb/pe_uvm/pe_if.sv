interface pe_if (input logic clk);
    logic        rst;
    logic        req_load_weight_in;
    logic        req_work_in;
    logic        req_load_weight_out;
    logic        req_work_out;
    logic        ack_weight_locked;
    logic [7:0]  w_in;
    logic [7:0]  a_in;
    logic [31:0] psum_in;
    logic [7:0]  w_out;
    logic [7:0]  a_out;
    logic [31:0] psum_out;
endinterface
