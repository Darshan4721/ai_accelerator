`ifndef TOP_ENV_SV
`define TOP_ENV_SV

class top_env extends uvm_env;
    `uvm_component_utils(top_env)
    
    axi_lite_agent axi_lite_agent_h;
    axis_rx_agent  axis_rx_agent_h;
    axis_tx_agent  axis_tx_agent_h;
    bist_agent     bist_agent_h;
    
    top_vsequencer vsqr;
    top_scoreboard scb;
    top_coverage   cov;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        axi_lite_agent_h = axi_lite_agent::type_id::create("axi_lite_agent_h", this);
        axis_rx_agent_h  = axis_rx_agent::type_id::create("axis_rx_agent_h", this);
        axis_tx_agent_h  = axis_tx_agent::type_id::create("axis_tx_agent_h", this);
        bist_agent_h     = bist_agent::type_id::create("bist_agent_h", this);
        
        vsqr = top_vsequencer::type_id::create("vsqr", this);
        scb  = top_scoreboard::type_id::create("scb", this);
        cov  = top_coverage::type_id::create("cov", this);
    endfunction
    
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // Connect sub-sequencers to virtual sequencer
        vsqr.axi_lite_sqr_h = axi_lite_agent_h.sqr;
        vsqr.axis_rx_sqr_h  = axis_rx_agent_h.sqr;
        vsqr.axis_tx_sqr_h  = axis_tx_agent_h.sqr;
        vsqr.bist_sqr_h     = bist_agent_h.sqr;
        
        // Connect monitors to scoreboard
        axis_rx_agent_h.mon.ap.connect(scb.rx_export);
        axis_tx_agent_h.mon.ap.connect(scb.tx_export);
        
        // Connect RX monitor to coverage collector
        axis_rx_agent_h.mon.ap.connect(cov.analysis_export);
    endfunction
endclass

`endif
