`timescale 1ns/1ps

module tb_sys_uvm_top;
    import uvm_pkg::*;
    import sys_uvm_pkg::*;

    logic clk;
    
    systolic_if vif(clk);

    systolic_array_16x16 dut (
        .clk(vif.clk),
        .rst(vif.rst),
        .i_load_weight_valid(vif.i_load_weight_valid),
        .i_compute_valid(vif.i_compute_valid),
        .i_w(vif.i_w),
        .i_a(vif.i_a),
        .o_weight_locked(vif.o_weight_locked),
        .o_valid(vif.o_valid),
        .o_psum(vif.o_psum)
    );

    initial begin
        clk = 0;
        forever #1.25 clk = ~clk; // 400 MHz
    end

    initial begin
        vif.rst = 1;
        #10;
        vif.rst = 0;
    end

    initial begin
        uvm_config_db#(virtual systolic_if)::set(null, "uvm_test_top.env.agent.*", "vif", vif);
        run_test("systolic_test");
    end

    // Dump waves
    initial begin
        $dumpfile("sys_dump.vcd");
        $dumpvars(0, tb_sys_uvm_top);
    end
endmodule
