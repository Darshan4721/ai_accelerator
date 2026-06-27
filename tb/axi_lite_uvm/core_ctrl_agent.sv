`ifndef CORE_CTRL_AGENT_SV
`define CORE_CTRL_AGENT_SV

class core_ctrl_sequencer extends uvm_sequencer #(core_ctrl_seq_item);
    `uvm_component_utils(core_ctrl_sequencer)
    function new(string name="core_ctrl_sequencer", uvm_component parent=null);
        super.new(name, parent);
    endfunction
endclass

class core_ctrl_agent extends uvm_agent;
    `uvm_component_utils(core_ctrl_agent)

    core_ctrl_sequencer sequencer;
    core_ctrl_driver    driver;
    core_ctrl_monitor   monitor;

    function new(string name = "core_ctrl_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor = core_ctrl_monitor::type_id::create("monitor", this);
        if (get_is_active() == UVM_ACTIVE) begin
            sequencer = core_ctrl_sequencer::type_id::create("sequencer", this);
            driver    = core_ctrl_driver::type_id::create("driver", this);
        end
    endfunction

    virtual function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if (get_is_active() == UVM_ACTIVE) begin
            driver.seq_item_port.connect(sequencer.seq_item_export);
        end
    endfunction
endclass

`endif
