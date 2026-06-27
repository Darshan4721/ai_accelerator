`ifndef TOP_VSEQUENCER_SV
`define TOP_VSEQUENCER_SV

class top_vsequencer extends uvm_sequencer;
    `uvm_component_utils(top_vsequencer)
    
    axi_lite_sqr  axi_lite_sqr_h;
    axis_rx_sqr   axis_rx_sqr_h;
    axis_tx_sqr   axis_tx_sqr_h;
    bist_sqr      bist_sqr_h;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass

`endif
