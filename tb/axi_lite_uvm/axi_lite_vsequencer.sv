`ifndef AXI_LITE_VSEQUENCER_SV
`define AXI_LITE_VSEQUENCER_SV

class axi_lite_vsequencer extends uvm_sequencer;
    `uvm_component_utils(axi_lite_vsequencer)

    axi_master_sequencer p_axi_seqr;
    core_ctrl_sequencer  p_core_seqr;

    function new(string name = "axi_lite_vsequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass

`endif
