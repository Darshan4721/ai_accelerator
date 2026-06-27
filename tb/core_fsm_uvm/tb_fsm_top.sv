`timescale 1ns/1ps

`include "uvm_macros.svh"
import uvm_pkg::*;
import fsm_ctrl_pkg::*;

module tb_fsm_top;

    logic clk;
    logic rst;

    // Clock Generation
    initial begin
        clk = 0;
        forever #1.25 clk = ~clk; // 400MHz clock
    end

    // Reset Generation (Synchronous Active-High)
    initial begin
        rst = 1;
        #40;
        @(posedge clk);
        rst = 0;
    end

    // Interface
    fsm_ctrl_if vif(clk, rst);

    // DUT
    core_fsm_ctrl dut (
        .clk(clk),
        .rst(rst),
        .start_compute(vif.start_compute),
        .mac_done(vif.mac_done),
        .sram_re(vif.sram_re),
        .sram_r_addr(vif.sram_r_addr),
        .sram_r_data(vif.sram_r_data),
        .array_load_weight_valid(vif.array_load_weight_valid),
        .array_compute_valid(vif.array_compute_valid),
        .array_w_in(vif.array_w_in),
        .array_a_in(vif.array_a_in),
        .array_weight_locked(vif.array_weight_locked)
    );

    // Continuous assignment to expose internal state to interface for SVA monitoring
    assign vif.current_state = dut.current_state;
    assign vif.drain_cnt     = dut.drain_cnt;

    initial begin
        uvm_config_db#(virtual fsm_ctrl_if)::set(null, "*", "vif", vif);
        run_test();
    end

endmodule
