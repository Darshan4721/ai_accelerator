`ifndef AXI_LITE_ENV_SV
`define AXI_LITE_ENV_SV

class axi_lite_env extends uvm_env;
    `uvm_component_utils(axi_lite_env)

    axi_master_agent axi_agt;
    core_ctrl_agent  core_agt;

    axi_lite_scoreboard scb;
    axi_lite_coverage   cov;
    axi_lite_vsequencer vsqr;

    function new(string name = "axi_lite_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        axi_agt  = axi_master_agent::type_id::create("axi_agt", this);
        core_agt = core_ctrl_agent::type_id::create("core_agt", this);
        
        scb  = axi_lite_scoreboard::type_id::create("scb", this);
        cov  = axi_lite_coverage::type_id::create("cov", this);
        vsqr = axi_lite_vsequencer::type_id::create("vsqr", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        // Connect monitors to scoreboard
        axi_agt.monitor.ap.connect(scb.axi_export);
        core_agt.monitor.ap.connect(scb.core_export);
        
        // Connect coverage
        axi_agt.monitor.ap.connect(cov.analysis_export);

        // Connect vsequencer
        vsqr.p_axi_seqr  = axi_agt.sequencer;
        vsqr.p_core_seqr = core_agt.sequencer;
        
        // Update scoreboard logic with vif to accurately check mac_done
        // The scoreboard needs to know physical mac_done for checking
        // Since we didn't pass vif to scb, let's just do it directly here via config DB or simple logic
        // We will just let the testbench pass it
    endfunction
endclass

`endif
