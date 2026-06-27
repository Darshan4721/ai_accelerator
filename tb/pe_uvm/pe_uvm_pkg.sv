`timescale 1ns/1ps
package pe_uvm_pkg;
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    `include "pe_seq_item.sv"
    `include "pe_sequences.sv"
    `include "pe_driver.sv"
    `include "pe_monitor.sv"
    `include "pe_scoreboard.sv"
    `include "pe_agent.sv"
    `include "pe_env.sv"
    `include "pe_test.sv"

endpackage
