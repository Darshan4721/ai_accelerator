`ifndef AXI_LITE_IF_SV
`define AXI_LITE_IF_SV

interface axi_lite_if (
    input logic clk,
    input logic rst
);

    // --------------------------------------------------------
    // Custom Accelerator Control Plane
    // --------------------------------------------------------
    logic start_compute;
    logic mac_done;

    // --------------------------------------------------------
    // AXI4-Lite Slave Interface
    // --------------------------------------------------------
    // Write Address Channel
    logic [31:0] s_axi_awaddr;
    logic        s_axi_awvalid;
    logic        s_axi_awready;

    // Write Data Channel
    logic [31:0] s_axi_wdata;
    logic        s_axi_wvalid;
    logic        s_axi_wready;

    // Write Response Channel
    logic [1:0]  s_axi_bresp;
    logic        s_axi_bvalid;
    logic        s_axi_bready;

    // Read Address Channel
    logic [31:0] s_axi_araddr;
    logic        s_axi_arvalid;
    logic        s_axi_arready;

    // Read Data Channel
    logic [31:0] s_axi_rdata;
    logic [1:0]  s_axi_rresp;
    logic        s_axi_rvalid;
    logic        s_axi_rready;


    // --------------------------------------------------------
    // SystemVerilog Assertions (SVA)
    // --------------------------------------------------------
`ifndef SYNTHESIS
    // 1. BVALID must NEVER drop if BREADY was low
    property no_bvalid_loop;
        @(posedge clk) disable iff (rst)
        (s_axi_bvalid && !s_axi_bready) |=> s_axi_bvalid;
    endproperty
    assert property(no_bvalid_loop) else $fatal(1, "STA VIOLATION: BVALID dropped before BREADY!");

    // 2. RVALID must NEVER drop if RREADY was low
    property no_rvalid_loop;
        @(posedge clk) disable iff (rst)
        (s_axi_rvalid && !s_axi_rready) |=> s_axi_rvalid;
    endproperty
    assert property(no_rvalid_loop) else $fatal(1, "STA VIOLATION: RVALID dropped before RREADY!");

    // 3. start_compute must be exactly 1 cycle wide
    property start_compute_pulse_width;
        @(posedge clk) disable iff (rst)
        start_compute |=> !start_compute;
    endproperty
    assert property(start_compute_pulse_width) else $fatal(1, "PROTOCOL VIOLATION: start_compute was HIGH for >1 cycle!");
`endif

endinterface

`endif
