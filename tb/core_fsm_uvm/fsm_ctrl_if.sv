`ifndef FSM_CTRL_IF_SV
`define FSM_CTRL_IF_SV

interface fsm_ctrl_if (
    input logic clk,
    input logic rst
);

    // --------------------------------------------------------
    // Host Control Plane
    // --------------------------------------------------------
    logic start_compute;
    logic mac_done;

    // --------------------------------------------------------
    // SRAM Interface
    // --------------------------------------------------------
    logic         sram_re;
    logic [7:0]   sram_r_addr;
    logic [127:0] sram_r_data;

    // --------------------------------------------------------
    // Systolic Array Interface
    // --------------------------------------------------------
    logic         array_load_weight_valid;
    logic         array_compute_valid;
    logic [127:0] array_w_in;
    logic [127:0] array_a_in;
    logic         array_weight_locked;

    // --------------------------------------------------------
    // Internal Taps for SVA (Connected in top level)
    // --------------------------------------------------------
    logic [1:0] current_state;
    logic [5:0] drain_cnt;
    
    // States for reference in SVA
    localparam S_IDLE         = 2'b00;
    localparam S_LOAD_WEIGHTS = 2'b01;
    localparam S_COMPUTE      = 2'b10;
    localparam S_DRAIN        = 2'b11;

    // --------------------------------------------------------
    // SystemVerilog Assertions (SVA)
    // --------------------------------------------------------
`ifndef SYNTHESIS

    // 1. Ensure SRAM read enable is strictly LOW during DRAIN to save power
    property p_sram_re_low_during_drain;
        @(posedge clk) disable iff (rst)
        (current_state == S_DRAIN) |-> (sram_re == 1'b0);
    endproperty
    assert property (p_sram_re_low_during_drain) else $error("FSM SVA: sram_re asserted during S_DRAIN!");
    cover property (p_sram_re_low_during_drain);

    // 2. Ensure 48-cycle exact latency constraint
    property p_mac_done_48_cycles;
        @(posedge clk) disable iff (rst)
        (current_state == S_DRAIN && drain_cnt == 48) |=> (mac_done == 1'b1);
    endproperty
    assert property (p_mac_done_48_cycles) else $error("FSM SVA: mac_done did not assert exactly at 48 cycles!");
    cover property (p_mac_done_48_cycles);

    // 3. Rule A: 1-Cycle Pipeline Delay for SRAM Read Latency
    property p_load_valid_latency;
        @(posedge clk) disable iff (rst)
        // If we requested an address < 16, exactly one cycle later, array_load_weight_valid MUST be 1
        (sram_re && sram_r_addr < 16) |=> (array_load_weight_valid == 1'b1);
    endproperty
    assert property (p_load_valid_latency) else $fatal(1, "FSM SVA: array_load_weight_valid violated 1-cycle latency rule!");

    property p_compute_valid_latency;
        @(posedge clk) disable iff (rst)
        // If we requested an address >= 16, exactly one cycle later, array_compute_valid MUST be 1
        (sram_re && sram_r_addr >= 16) |=> (array_compute_valid == 1'b1);
    endproperty
    assert property (p_compute_valid_latency) else $fatal(1, "FSM SVA: array_compute_valid violated 1-cycle latency rule!");

`endif

endinterface

`endif
