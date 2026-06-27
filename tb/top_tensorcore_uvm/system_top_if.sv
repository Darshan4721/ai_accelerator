`timescale 1ns/1ps

interface system_top_if(input logic clk_i);
    logic rst_ni;
    // --------------------------------------------------------
    // 1. AXI4-Lite Configuration Interface
    // --------------------------------------------------------
    logic [31:0]  s_axi_awaddr;
    logic         s_axi_awvalid;
    logic         s_axi_awready;
    logic [31:0]  s_axi_wdata;
    logic         s_axi_wvalid;
    logic         s_axi_wready;
    logic [1:0]   s_axi_bresp;
    logic         s_axi_bvalid;
    logic         s_axi_bready;
    logic [31:0]  s_axi_araddr;
    logic         s_axi_arvalid;
    logic         s_axi_arready;
    logic [31:0]  s_axi_rdata;
    logic [1:0]   s_axi_rresp;
    logic         s_axi_rvalid;
    logic         s_axi_rready;

    // --------------------------------------------------------
    // 2. AXI-Stream RX (Incoming)
    // --------------------------------------------------------
    logic [127:0] s_axis_tdata;
    logic         s_axis_tvalid;
    logic         s_axis_tready;
    logic         s_axis_tlast;

    // --------------------------------------------------------
    // 3. AXI-Stream TX (Outgoing)
    // --------------------------------------------------------
    logic [511:0] m_axis_tdata;
    logic         m_axis_tvalid;
    logic         m_axis_tready;
    logic         m_axis_tlast;

    // --------------------------------------------------------
    // 4. DFT / BIST External Pins
    // --------------------------------------------------------
    logic         bist_start_i;
    logic [511:0] expected_misr_sig_i;
    logic         bist_done_o;
    logic         bist_fail_o;

    // ========================================================
    // CLOCKING BLOCKS (Strict setup/hold tracking for 350MHz)
    // ========================================================
    clocking cb_drv @(posedge clk_i);
        default input #1ns output #1ns;
        // AXI-Lite
        output s_axi_awaddr, s_axi_awvalid, s_axi_wdata, s_axi_wvalid, s_axi_bready;
        output s_axi_araddr, s_axi_arvalid, s_axi_rready;
        input  s_axi_awready, s_axi_wready, s_axi_bvalid, s_axi_bresp;
        input  s_axi_arready, s_axi_rvalid, s_axi_rdata, s_axi_rresp;
        
        // AXIS-RX
        output s_axis_tdata, s_axis_tvalid, s_axis_tlast;
        input  s_axis_tready;

        // AXIS-TX
        output m_axis_tready;
        input  m_axis_tdata, m_axis_tvalid, m_axis_tlast;

        // BIST
        output bist_start_i, expected_misr_sig_i;
        input  bist_done_o, bist_fail_o;
    endclocking

    clocking cb_mon @(posedge clk_i);
        default input #1ns output #1ns;
        // AXI-Lite
        input s_axi_awaddr, s_axi_awvalid, s_axi_awready;
        input s_axi_wdata, s_axi_wvalid, s_axi_wready;
        input s_axi_bresp, s_axi_bvalid, s_axi_bready;
        input s_axi_araddr, s_axi_arvalid, s_axi_arready;
        input s_axi_rdata, s_axi_rresp, s_axi_rvalid, s_axi_rready;
        
        // AXIS-RX
        input s_axis_tdata, s_axis_tvalid, s_axis_tready, s_axis_tlast;

        // AXIS-TX
        input m_axis_tdata, m_axis_tvalid, m_axis_tready, m_axis_tlast;

        // BIST
        input bist_start_i, expected_misr_sig_i, bist_done_o, bist_fail_o;
    endclocking

    // ========================================================
    // SYSTEMVERILOG ASSERTIONS (SVAs) - Protocol Checkers
    // ========================================================
    
    // Property: AXI-Stream RX stability. If tvalid is high and tready is low, tdata must be stable.
    property p_axis_rx_stable;
        @(posedge clk_i) disable iff (!rst_ni)
        (s_axis_tvalid && !s_axis_tready) |=> (s_axis_tdata == $past(s_axis_tdata)) && s_axis_tvalid;
    endproperty
    assert property(p_axis_rx_stable) else $error("SVA Failure: s_axis_tdata changed while tvalid was HIGH and tready was LOW!");

    // Property: AXI-Stream TX stability.
    property p_axis_tx_stable;
        @(posedge clk_i) disable iff (!rst_ni)
        (m_axis_tvalid && !m_axis_tready) |=> (m_axis_tdata == $past(m_axis_tdata)) && m_axis_tvalid;
    endproperty
    assert property(p_axis_tx_stable) else $error("SVA Failure: m_axis_tdata changed while tvalid was HIGH and tready was LOW!");

    // Property: AXI-Lite AW channel stability.
    property p_axi_aw_stable;
        @(posedge clk_i) disable iff (!rst_ni)
        (s_axi_awvalid && !s_axi_awready) |=> (s_axi_awaddr == $past(s_axi_awaddr)) && s_axi_awvalid;
    endproperty
    assert property(p_axi_aw_stable) else $error("SVA Failure: AXI-Lite AW channel unstable.");

    // Property: AXI-Lite W channel stability.
    property p_axi_w_stable;
        @(posedge clk_i) disable iff (!rst_ni)
        (s_axi_wvalid && !s_axi_wready) |=> (s_axi_wdata == $past(s_axi_wdata)) && s_axi_wvalid;
    endproperty
    assert property(p_axi_w_stable) else $error("SVA Failure: AXI-Lite W channel unstable.");

endinterface