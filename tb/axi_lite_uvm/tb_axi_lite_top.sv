`timescale 1ns/1ps

`include "uvm_macros.svh"
import uvm_pkg::*;
import axi_lite_uvm_pkg::*;

module tb_axi_lite_top;

    logic clk;
    logic rst;

    // Clock Generation (250MHz)
    initial begin
        clk = 0;
        forever #2.0 clk = ~clk; 
    end

    // Reset Generation (Synchronous Active-High)
    initial begin
        rst = 1;
        #40;
        @(posedge clk);
        rst = 0;
    end

    // Interface
    axi_lite_if vif(clk, rst);

    // DUT
    axi_lite_config dut (
        .clk(clk),
        .rst(rst),
        .start_compute(vif.start_compute),
        .mac_done(vif.mac_done),
        .s_axi_awaddr(vif.s_axi_awaddr),
        .s_axi_awvalid(vif.s_axi_awvalid),
        .s_axi_awready(vif.s_axi_awready),
        .s_axi_wdata(vif.s_axi_wdata),
        .s_axi_wvalid(vif.s_axi_wvalid),
        .s_axi_wready(vif.s_axi_wready),
        .s_axi_bresp(vif.s_axi_bresp),
        .s_axi_bvalid(vif.s_axi_bvalid),
        .s_axi_bready(vif.s_axi_bready),
        .s_axi_araddr(vif.s_axi_araddr),
        .s_axi_arvalid(vif.s_axi_arvalid),
        .s_axi_arready(vif.s_axi_arready),
        .s_axi_rdata(vif.s_axi_rdata),
        .s_axi_rresp(vif.s_axi_rresp),
        .s_axi_rvalid(vif.s_axi_rvalid),
        .s_axi_rready(vif.s_axi_rready)
    );

    initial begin
        uvm_config_db#(virtual axi_lite_if)::set(null, "*", "vif", vif);
        run_test();
    end

endmodule
