`ifndef FSM_VSEQUENCER_SV
`define FSM_VSEQUENCER_SV

class fsm_vsequencer extends uvm_sequencer;
    `uvm_component_utils(fsm_vsequencer)

    host_ctrl_sequencer      p_host_seqr;
    array_feedback_sequencer p_array_seqr;
    sram_dummy_sequencer     p_sram_seqr;

    function new(string name = "fsm_vsequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass

`endif
