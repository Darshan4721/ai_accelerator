`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.svh"
import axis_tx_pkg::*;

module tb_axis_tx_top;

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
    axis_tx_if vif(aclk, aresetn);

    axis_tx dut (
        .aclk(aclk),
        .aresetn(aresetn),
        
        .array_o_valid(vif.array_o_valid),
        .array_o_psum(vif.array_o_psum),
        
        .m_axis_tdata(vif.m_axis_tdata),
        .m_axis_tvalid(vif.m_axis_tvalid),
        .m_axis_tready(vif.m_axis_tready),
        .m_axis_tlast(vif.m_axis_tlast)
    );

    // --------------------------------------------------------
    // Pass Virtual Interface to UVM Config DB
    // --------------------------------------------------------
    initial begin
        uvm_config_db#(virtual axis_tx_if)::set(null, "uvm_test_top.env.sys_tx_agt.*", "vif", vif);
        uvm_config_db#(virtual axis_tx_if)::set(null, "uvm_test_top.env.axi_rx_agt.*", "vif", vif);
        run_test(); // Test name is passed via +UVM_TESTNAME=...
    end

endmodule
