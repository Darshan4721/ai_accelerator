`ifndef AXIS_RX_IF_SV
`define AXIS_RX_IF_SV

interface axis_rx_if (
    input logic aclk,
    input logic aresetn
);

    // --------------------------------------------------------
    // 1. AXI-Stream Slave Interface (DMA to DUT)
    // --------------------------------------------------------
    logic [127:0] s_axis_tdata;
    logic         s_axis_tvalid;
    logic         s_axis_tready;
    logic         s_axis_tlast;

    // --------------------------------------------------------
    // 2. SRAM Interface (DUT to Memory)
    // --------------------------------------------------------
    logic         sram_we;
    logic [7:0]   sram_w_addr;
    logic [127:0] sram_w_data;

    // --------------------------------------------------------
    // 3. Controller Interface
    // --------------------------------------------------------
    logic         rx_matrix_done;

    // --------------------------------------------------------
    // 4. Testbench Internal Signals
    // --------------------------------------------------------
    logic         tb_sram_ready; // Used by SRAM Agent to pause the Skid Buffer

    // --------------------------------------------------------
    // 5. Embedded Functional Coverage Hooks (SVA)
    // --------------------------------------------------------
`ifndef SYNTHESIS
    property p_axi_tdata_stable_if;
        @(posedge aclk) disable iff (!aresetn)
        (s_axis_tvalid && !s_axis_tready) |=> ($stable(s_axis_tdata) && s_axis_tvalid);
    endproperty

    assert property (p_axi_tdata_stable_if) 
        else $error("AXI RX Violation: tdata changed while stalled! (Caught by Interface SVA)");
        
    cover property (p_axi_tdata_stable_if);
`endif

endinterface

`endif
