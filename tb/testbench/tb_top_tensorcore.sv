`timescale 1ns/1ps

import uvm_pkg::*;
`include "uvm_macros.svh"
import top_uvm_pkg::*;

module tb_top_tensorcore;
    
    logic clk_i;
    
    // Interface instantiation
    system_top_if vif(clk_i);
    
    // DUT Instantiation
    top_tensorcore_lite DUT (
        .clk_i(clk_i),
        .rst_ni(vif.rst_ni),
        
        .s_axi_awaddr  (vif.s_axi_awaddr),
        .s_axi_awvalid (vif.s_axi_awvalid),
        .s_axi_awready (vif.s_axi_awready),
        .s_axi_wdata   (vif.s_axi_wdata),
        .s_axi_wvalid  (vif.s_axi_wvalid),
        .s_axi_wready  (vif.s_axi_wready),
        .s_axi_bresp   (vif.s_axi_bresp),
        .s_axi_bvalid  (vif.s_axi_bvalid),
        .s_axi_bready  (vif.s_axi_bready),
        .s_axi_araddr  (vif.s_axi_araddr),
        .s_axi_arvalid (vif.s_axi_arvalid),
        .s_axi_arready (vif.s_axi_arready),
        .s_axi_rdata   (vif.s_axi_rdata),
        .s_axi_rresp   (vif.s_axi_rresp),
        .s_axi_rvalid  (vif.s_axi_rvalid),
        .s_axi_rready  (vif.s_axi_rready),
        
        .s_axis_tdata  (vif.s_axis_tdata),
        .s_axis_tvalid (vif.s_axis_tvalid),
        .s_axis_tready (vif.s_axis_tready),
        .s_axis_tlast  (vif.s_axis_tlast),
        
        .m_axis_tdata  (vif.m_axis_tdata),
        .m_axis_tvalid (vif.m_axis_tvalid),
        .m_axis_tready (vif.m_axis_tready),
        .m_axis_tlast  (vif.m_axis_tlast),
        
        .bist_start_i  (vif.bist_start_i),
        .expected_misr_sig_i (vif.expected_misr_sig_i),
        .bist_done_o   (vif.bist_done_o),
        .bist_fail_o   (vif.bist_fail_o)
    );
    
    // Clock Generation (350MHz = 2.857ns period)
    initial begin
        clk_i = 0;
        forever #(2.857 / 2) clk_i = ~clk_i;
    end
    
    // Top level initialization and UVM boot
    initial begin
        uvm_config_db#(virtual system_top_if)::set(null, "*", "vif", vif);
        run_test();
    end
    
    // Reset generation
    initial begin
        vif.bist_start_i = 0;
        vif.expected_misr_sig_i = 0;
        vif.rst_ni = 0;
        #10ns;
        vif.rst_ni = 1;
    end
    
    // Waveform dumping (Cadence)
    initial begin
        $shm_open("waves.shm");
        $shm_probe("AS");
    end

endmodule