`ifndef SRAM_DUMMY_AGENT_SV
`define SRAM_DUMMY_AGENT_SV

// -------------------------------------------------------------------------
// SEQUENCER
// -------------------------------------------------------------------------
class sram_dummy_sequencer extends uvm_sequencer #(sram_dummy_seq_item);
    `uvm_component_utils(sram_dummy_sequencer)

    function new(string name = "sram_dummy_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass

// -------------------------------------------------------------------------
// DRIVER
// -------------------------------------------------------------------------
class sram_dummy_driver extends uvm_driver #(sram_dummy_seq_item);
    `uvm_component_utils(sram_dummy_driver)

    virtual fsm_ctrl_if vif;

    function new(string name = "sram_dummy_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual fsm_ctrl_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "virtual interface must be set for: vif")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        vif.sram_r_data <= 128'h0;

        forever begin
            seq_item_port.get_next_item(req);

            // Wait until we see a read enable
            do begin
                @(posedge vif.clk);
            end while (vif.sram_re !== 1'b1);
            
            // The FSM has a 1-cycle pipeline delay for the SRAM read.
            // When sram_re is high, we delay 1 cycle and then output dummy data.
            // Actually, if we see sram_re high on clock edge N, the data must be on the bus for clock edge N+1.
            // We sample sram_re on posedge, so the data is driven immediately after the edge and will be sampled on the next posedge.
            vif.sram_r_data <= req.dummy_r_data;
            
            seq_item_port.item_done();
        end
    endtask
endclass

// -------------------------------------------------------------------------
// MONITOR
// -------------------------------------------------------------------------
class sram_dummy_monitor extends uvm_monitor;
    `uvm_component_utils(sram_dummy_monitor)

    virtual fsm_ctrl_if vif;
    uvm_analysis_port #(sram_dummy_seq_item) ap;

    function new(string name = "sram_dummy_monitor", uvm_component parent = null);
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
        sram_dummy_seq_item item;
        
        forever begin
            @(posedge vif.clk);
            if (vif.sram_re === 1'b1) begin
                item = sram_dummy_seq_item::type_id::create("item");
                item.sram_re = vif.sram_re;
                item.sram_r_addr = vif.sram_r_addr;
                // Broadcast exactly what the FSM requested
                ap.write(item);
            end
        end
    endtask
endclass

// -------------------------------------------------------------------------
// AGENT
// -------------------------------------------------------------------------
class sram_dummy_agent extends uvm_agent;
    `uvm_component_utils(sram_dummy_agent)

    sram_dummy_sequencer sequencer;
    sram_dummy_driver    driver;
    sram_dummy_monitor   monitor;

    function new(string name = "sram_dummy_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor = sram_dummy_monitor::type_id::create("monitor", this);
        if (get_is_active() == UVM_ACTIVE) begin
            sequencer = sram_dummy_sequencer::type_id::create("sequencer", this);
            driver    = sram_dummy_driver::type_id::create("driver", this);
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
