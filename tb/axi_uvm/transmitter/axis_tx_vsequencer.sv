`ifndef AXIS_TX_VSEQUENCER_SV
`define AXIS_TX_VSEQUENCER_SV

class axis_tx_vsequencer extends uvm_sequencer;
    `uvm_component_utils(axis_tx_vsequencer)

    sys_tx_sequencer p_sys_tx_seqr;
    axi_rx_sequencer p_axi_rx_seqr;

    function new(string name = "axis_tx_vsequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction

endclass

`endif
