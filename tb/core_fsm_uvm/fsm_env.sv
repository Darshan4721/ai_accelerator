`ifndef FSM_ENV_SV
`define FSM_ENV_SV

class fsm_env extends uvm_env;
    `uvm_component_utils(fsm_env)

    host_ctrl_agent      host_agt;
    array_feedback_agent array_agt;
    sram_dummy_agent     sram_agt;

    fsm_scoreboard       scb;
    fsm_coverage         cov;
    fsm_vsequencer       vsqr;

    function new(string name = "fsm_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        host_agt  = host_ctrl_agent::type_id::create("host_agt", this);
        array_agt = array_feedback_agent::type_id::create("array_agt", this);
        sram_agt  = sram_dummy_agent::type_id::create("sram_agt", this);
        
        scb  = fsm_scoreboard::type_id::create("scb", this);
        cov  = fsm_coverage::type_id::create("cov", this);
        vsqr = fsm_vsequencer::type_id::create("vsqr", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        // Connect monitors to scoreboard
        host_agt.monitor.ap.connect(scb.host_export);
        array_agt.monitor.ap.connect(scb.array_export);
        sram_agt.monitor.ap.connect(scb.sram_export);

        // Connect vsequencer
        vsqr.p_host_seqr  = host_agt.sequencer;
        vsqr.p_array_seqr = array_agt.sequencer;
        vsqr.p_sram_seqr  = sram_agt.sequencer;
    endfunction
endclass

`endif
