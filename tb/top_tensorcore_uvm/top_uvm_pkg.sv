`ifndef TOP_UVM_PKG_SV
`define TOP_UVM_PKG_SV

package top_uvm_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"
    
    // Agents
    `include "agents/axi_lite_agent/axi_lite_item.sv"
    `include "agents/axi_lite_agent/axi_lite_sqr.sv"
    `include "agents/axi_lite_agent/axi_lite_driver.sv"
    `include "agents/axi_lite_agent/axi_lite_monitor.sv"
    `include "agents/axi_lite_agent/axi_lite_agent.sv"
    
    `include "agents/axis_rx_agent/axis_rx_item.sv"
    `include "agents/axis_rx_agent/axis_rx_sqr.sv"
    `include "agents/axis_rx_agent/axis_rx_driver.sv"
    `include "agents/axis_rx_agent/axis_rx_monitor.sv"
    `include "agents/axis_rx_agent/axis_rx_agent.sv"
    
    `include "agents/axis_tx_agent/axis_tx_item.sv"
    `include "agents/axis_tx_agent/axis_tx_sqr.sv"
    `include "agents/axis_tx_agent/axis_tx_driver.sv"
    `include "agents/axis_tx_agent/axis_tx_monitor.sv"
    `include "agents/axis_tx_agent/axis_tx_agent.sv"
    
    `include "agents/bist_agent/bist_item.sv"
    `include "agents/bist_agent/bist_sqr.sv"
    `include "agents/bist_agent/bist_driver.sv"
    `include "agents/bist_agent/bist_monitor.sv"
    `include "agents/bist_agent/bist_agent.sv"
    
    // Environment
    `include "env/top_vsequencer.sv"
    `include "env/top_scoreboard.sv"
    `include "env/top_coverage.sv"
    `include "env/top_env.sv"
    
    // Sequences
    `include "sequences/top_vseq_base.sv"
    `include "sequences/vseq_axi_lite_tests.sv"
    `include "sequences/vseq_fsm_tests.sv"
    `include "sequences/vseq_rx_tests.sv"
    `include "sequences/vseq_tx_tests.sv"
    `include "sequences/vseq_sram_tests.sv"
    `include "sequences/vseq_array_tests.sv"
    `include "sequences/vseq_bist_tests.sv"
    `include "sequences/vseq_top_specialized.sv"
    
    // Tests
    `include "tests/top_test_base.sv"
    `include "tests/top_tests_all.sv"
endpackage

`endif