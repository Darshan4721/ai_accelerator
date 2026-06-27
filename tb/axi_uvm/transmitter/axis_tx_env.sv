`ifndef AXIS_TX_ENV_SV
`define AXIS_TX_ENV_SV

class axis_tx_env extends uvm_env;
    `uvm_component_utils(axis_tx_env)

    sys_tx_agent       sys_tx_agt;
    axi_rx_agent       axi_rx_agt;
    axis_tx_vsequencer vsqr;
    axis_tx_scoreboard scb;

    function new(string name = "axis_tx_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        sys_tx_agt = sys_tx_agent::type_id::create("sys_tx_agt", this);
        axi_rx_agt = axi_rx_agent::type_id::create("axi_rx_agt", this);
        vsqr       = axis_tx_vsequencer::type_id::create("vsqr", this);
        scb        = axis_tx_scoreboard::type_id::create("scb", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // Connect Virtual Sequencer to physical sequencers
        vsqr.p_sys_tx_seqr = sys_tx_agt.sequencer;
        vsqr.p_axi_rx_seqr = axi_rx_agt.sequencer;

        // Connect monitors to Scoreboard
        sys_tx_agt.monitor.ap.connect(scb.sys_tx_export);
        axi_rx_agt.monitor.ap.connect(scb.axi_rx_export);
    endfunction

endclass

`endif
