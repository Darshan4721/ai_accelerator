`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.svh"
import pe_uvm_pkg::*;

module tb_pe_uvm_top;
    logic clk;
    logic rst;

    pe_if vif (clk);

    pe_pipelined dut (
        .clk(clk),
        .rst(vif.rst),
        .req_load_weight_in(vif.req_load_weight_in),
        .req_work_in(vif.req_work_in),
        .req_load_weight_out(vif.req_load_weight_out),
        .req_work_out(vif.req_work_out),
        .ack_weight_locked(vif.ack_weight_locked),
        .w_in(vif.w_in),
        .a_in(vif.a_in),
        .psum_in(vif.psum_in),
        .w_out(vif.w_out),
        .a_out(vif.a_out),
        .psum_out(vif.psum_out)
    );

    initial begin
        clk = 0;
        forever #1.25 clk = ~clk;
    end

    initial begin
        vif.rst = 1;
        #10 vif.rst = 0;
    end

    initial begin
        uvm_config_db#(virtual pe_if)::set(null, "*", "vif", vif);
        run_test("pe_test");
    end
endmodule
