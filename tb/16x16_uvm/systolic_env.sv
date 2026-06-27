class systolic_env extends uvm_env;
    `uvm_component_utils(systolic_env)
    systolic_agent agent;
    systolic_scoreboard scb;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent = systolic_agent::type_id::create("agent", this);
        scb = systolic_scoreboard::type_id::create("scb", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.mon.ap_in.connect(scb.fifo_in.analysis_export);
        agent.mon.ap_out.connect(scb.fifo_out.analysis_export);
    endfunction
endclass
