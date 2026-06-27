`ifndef HOST_CTRL_AGENT_SV
`define HOST_CTRL_AGENT_SV

// -------------------------------------------------------------------------
// SEQUENCER
// -------------------------------------------------------------------------
class host_ctrl_sequencer extends uvm_sequencer #(host_ctrl_seq_item);
    `uvm_component_utils(host_ctrl_sequencer)

    function new(string name = "host_ctrl_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass

// -------------------------------------------------------------------------
// DRIVER
// -------------------------------------------------------------------------
class host_ctrl_driver extends uvm_driver #(host_ctrl_seq_item);
    `uvm_component_utils(host_ctrl_driver)

    virtual fsm_ctrl_if vif;

    function new(string name = "host_ctrl_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual fsm_ctrl_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "virtual interface must be set for: vif")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        vif.start_compute <= 1'b0;

        forever begin
            seq_item_port.get_next_item(req);

            if (req.delay_before_start > 0) begin
                repeat(req.delay_before_start) @(posedge vif.clk);
            end

            // Drive start_compute pulse
            vif.start_compute <= 1'b1;
            @(posedge vif.clk);
            vif.start_compute <= 1'b0;

            seq_item_port.item_done();
        end
    endtask
endclass

// -------------------------------------------------------------------------
// MONITOR
// -------------------------------------------------------------------------
class host_ctrl_monitor extends uvm_monitor;
    `uvm_component_utils(host_ctrl_monitor)

    virtual fsm_ctrl_if vif;
    uvm_analysis_port #(host_ctrl_seq_item) ap;

    function new(string name = "host_ctrl_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual fsm_ctrl_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "virtual interface must be set for: vif")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        host_ctrl_seq_item item;
        
        forever begin
            @(posedge vif.clk);
            if (vif.mac_done === 1'b1 || vif.start_compute === 1'b1) begin
                item = host_ctrl_seq_item::type_id::create("item");
                // Just pass an item to indicate an event (start or done)
                ap.write(item);
            end
        end
    endtask
endclass

// -------------------------------------------------------------------------
// AGENT
// -------------------------------------------------------------------------
class host_ctrl_agent extends uvm_agent;
    `uvm_component_utils(host_ctrl_agent)

    host_ctrl_sequencer sequencer;
    host_ctrl_driver    driver;
    host_ctrl_monitor   monitor;

    function new(string name = "host_ctrl_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor = host_ctrl_monitor::type_id::create("monitor", this);
        if (get_is_active() == UVM_ACTIVE) begin
            sequencer = host_ctrl_sequencer::type_id::create("sequencer", this);
            driver    = host_ctrl_driver::type_id::create("driver", this);
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
