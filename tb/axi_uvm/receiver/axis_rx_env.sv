`ifndef AXIS_RX_ENV_SV
`define AXIS_RX_ENV_SV

class axis_rx_env extends uvm_env;
    `uvm_component_utils(axis_rx_env)

    axi_dma_agent      axi_agt;
    sram_out_agent     sram_agt;
    axis_rx_vsequencer vsqr;
    axis_rx_scoreboard scb;

    function new(string name = "axis_rx_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        axi_agt  = axi_dma_agent::type_id::create("axi_agt", this);
        sram_agt = sram_out_agent::type_id::create("sram_agt", this);
        vsqr     = axis_rx_vsequencer::type_id::create("vsqr", this);
        scb      = axis_rx_scoreboard::type_id::create("scb", this);
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        
        // Connect Virtual Sequencer handles
        vsqr.p_axi_dma_seqr  = axi_agt.sequencer;
        vsqr.p_sram_out_seqr = sram_agt.sequencer;

        // Connect monitors to Scoreboard
        axi_agt.monitor.ap.connect(scb.axi_export);
        sram_agt.monitor.ap.connect(scb.sram_export);
    endfunction

endclass

`endif
