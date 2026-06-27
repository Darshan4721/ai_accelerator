`ifndef AXIS_TX_PKG_SV
`define AXIS_TX_PKG_SV

`timescale 1ns/1ps

package axis_tx_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "sys_tx_seq_item.sv"
    `include "axi_rx_seq_item.sv"
    
    `include "sys_tx_agent.sv"
    `include "axi_rx_agent.sv"
    
    `include "axis_tx_scoreboard.sv"
    `include "axis_tx_vsequencer.sv"
    
    `include "axis_tx_env.sv"
    
    `include "axis_tx_vseq.sv"
    `include "axis_tx_test.sv"

endpackage

`endif
