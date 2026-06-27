`ifndef AXIS_RX_PKG_SV
`define AXIS_RX_PKG_SV

// Senior Engineer Request #1: Timescale BEFORE package declaration
`timescale 1ns/1ps

package axis_rx_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "axi_dma_seq_item.sv"
    `include "sram_out_seq_item.sv"
    
    `include "axi_dma_agent.sv"
    `include "sram_out_agent.sv"
    
    `include "axis_rx_scoreboard.sv"
    `include "axis_rx_vsequencer.sv"
    
    `include "axis_rx_env.sv"
    
    `include "axis_rx_vseq.sv"
    `include "axis_rx_test.sv"

endpackage

`endif
