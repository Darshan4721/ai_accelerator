`timescale 1ns/1ps
package axi_lite_uvm_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "axi_seq_item.sv"
    `include "core_ctrl_seq_item.sv"

    `include "axi_master_driver.sv"
    `include "axi_master_monitor.sv"
    `include "axi_master_agent.sv"

    `include "core_ctrl_driver.sv"
    `include "core_ctrl_monitor.sv"
    `include "core_ctrl_agent.sv"

    `include "axi_lite_scoreboard.sv"
    `include "axi_lite_coverage.sv"
    `include "axi_lite_vsequencer.sv"
    `include "axi_lite_env.sv"

    `include "axi_lite_vseq.sv"
    `include "axi_lite_test.sv"

endpackage
