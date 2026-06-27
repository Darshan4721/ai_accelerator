`ifndef ARRAY_FEEDBACK_AGENT_SV
`define ARRAY_FEEDBACK_AGENT_SV

// -------------------------------------------------------------------------
// SEQUENCER
// -------------------------------------------------------------------------
class array_feedback_sequencer extends uvm_sequencer #(array_feedback_seq_item);
    `uvm_component_utils(array_feedback_sequencer)

    function new(string name = "array_feedback_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass

// -------------------------------------------------------------------------
// DRIVER
// -------------------------------------------------------------------------
class array_feedback_driver extends uvm_driver #(array_feedback_seq_item);
    `uvm_component_utils(array_feedback_driver)

    virtual fsm_ctrl_if vif;

    function new(string name = "array_feedback_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual fsm_ctrl_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "virtual interface must be set for: vif")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        vif.array_weight_locked <= 1'b0;

        forever begin
            seq_item_port.get_next_item(req);

            // Wait until we see 16 valid load signals
            begin
                int load_cnt = 0;
                while(load_cnt < 16) begin
                    @(posedge vif.clk);
                    if (vif.array_load_weight_valid) begin
                        load_cnt++;
                    end
                end
            end

            // Now wait the randomized delay before locking
            if (req.weight_lock_delay > 0) begin
                repeat(req.weight_lock_delay) @(posedge vif.clk);
            end

            // Assert lock
            vif.array_weight_locked <= 1'b1;
            
            // Wait until compute finishes (mac_done) to clear it
            do begin
                @(posedge vif.clk);
            end while (vif.mac_done !== 1'b1);
            
            // Clear lock
            vif.array_weight_locked <= 1'b0;

            seq_item_port.item_done();
        end
    endtask
endclass

// -------------------------------------------------------------------------
// MONITOR
// -------------------------------------------------------------------------
class array_feedback_monitor extends uvm_monitor;
    `uvm_component_utils(array_feedback_monitor)

    virtual fsm_ctrl_if vif;
    uvm_analysis_port #(array_feedback_seq_item) ap;

    function new(string name = "array_feedback_monitor", uvm_component parent = null);
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
        array_feedback_seq_item item;
        
        forever begin
            @(posedge vif.clk);
            // We passively monitor the valids and the data going into the array
            if (vif.array_load_weight_valid || vif.array_compute_valid) begin
                item = array_feedback_seq_item::type_id::create("item");
                // The item will just be an indicator that we received valid data
                ap.write(item);
            end
        end
    endtask
endclass

// -------------------------------------------------------------------------
// AGENT
// -------------------------------------------------------------------------
class array_feedback_agent extends uvm_agent;
    `uvm_component_utils(array_feedback_agent)

    array_feedback_sequencer sequencer;
    array_feedback_driver    driver;
    array_feedback_monitor   monitor;

    function new(string name = "array_feedback_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor = array_feedback_monitor::type_id::create("monitor", this);
        if (get_is_active() == UVM_ACTIVE) begin
            sequencer = array_feedback_sequencer::type_id::create("sequencer", this);
            driver    = array_feedback_driver::type_id::create("driver", this);
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
