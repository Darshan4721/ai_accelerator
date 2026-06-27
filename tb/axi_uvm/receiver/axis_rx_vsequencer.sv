`ifndef AXIS_RX_VSEQUENCER_SV
`define AXIS_RX_VSEQUENCER_SV

class axis_rx_vsequencer extends uvm_sequencer;
    `uvm_component_utils(axis_rx_vsequencer)

    axi_dma_sequencer  p_axi_dma_seqr;
    sram_out_sequencer p_sram_out_seqr;

    function new(string name = "axis_rx_vsequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass

`endif
