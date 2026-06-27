`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.svh"
import axis_rx_pkg::*;

module tb_axis_rx_top;

    logic aclk;
    logic aresetn;

    // --------------------------------------------------------
    // Clock Generation (400 MHz -> 2.5ns period)
    // --------------------------------------------------------
    initial begin
        aclk = 0;
        forever #1.25 aclk = ~aclk;
    end

    // --------------------------------------------------------
    // Reset Generation
    // --------------------------------------------------------
    initial begin
        aresetn = 0;
        #20;
        aresetn = 1;
    end

    // --------------------------------------------------------
    // Interface & DUT Instantiation
    // --------------------------------------------------------
    axis_rx_if vif(aclk, aresetn);

    axis_rx dut (
        .aclk(aclk),
        .aresetn(aresetn),
        
        .s_axis_tdata(vif.s_axis_tdata),
        .s_axis_tvalid(vif.s_axis_tvalid),
        .s_axis_tready(vif.s_axis_tready),
        .s_axis_tlast(vif.s_axis_tlast),
        
        .sram_we(vif.sram_we),
        .sram_w_addr(vif.sram_w_addr),
        .sram_w_data(vif.sram_w_data),
        
        .rx_matrix_done(vif.rx_matrix_done)
    );

    // --------------------------------------------------------
    // Pass Virtual Interface to UVM Config DB
    // --------------------------------------------------------
    initial begin
        uvm_config_db#(virtual axis_rx_if)::set(null, "uvm_test_top.env.axi_agt.*", "vif", vif);
        uvm_config_db#(virtual axis_rx_if)::set(null, "uvm_test_top.env.sram_agt.*", "vif", vif);
        run_test(); // Test name is passed via +UVM_TESTNAME=...
    end

endmodule
