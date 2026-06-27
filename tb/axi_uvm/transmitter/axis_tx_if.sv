`ifndef AXIS_TX_IF_SV
`define AXIS_TX_IF_SV

interface axis_tx_if (
    input logic aclk,
    input logic aresetn
);

    // --------------------------------------------------------
    // 1. SysTx Interface (Array to DUT)
    // --------------------------------------------------------
    logic         array_o_valid;
    logic [511:0] array_o_psum;

    // --------------------------------------------------------
    // 2. AxiRx Interface (DUT to DMA)
    // --------------------------------------------------------
    logic [511:0] m_axis_tdata;
    logic         m_axis_tvalid;
    logic         m_axis_tready;
    logic         m_axis_tlast;

    // --------------------------------------------------------
    // 3. Embedded Functional Coverage Hooks (SVA)
    // --------------------------------------------------------
`ifndef SYNTHESIS
    property p_axi_tx_tdata_stable_if;
        @(posedge aclk) disable iff (!aresetn)
        (m_axis_tvalid && !m_axis_tready) |=> ($stable(m_axis_tdata) && m_axis_tvalid);
    endproperty

    assert property (p_axi_tx_tdata_stable_if) 
        else $error("AXI TX Violation: tdata changed while stalled! (Caught by Interface SVA)");
        
    cover property (p_axi_tx_tdata_stable_if);
`endif

endinterface

`endif
