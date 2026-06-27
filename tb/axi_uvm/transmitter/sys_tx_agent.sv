`ifndef SYS_TX_AGENT_SV
`define SYS_TX_AGENT_SV

// -------------------------------------------------------------------------
// SEQUENCER
// -------------------------------------------------------------------------
class sys_tx_sequencer extends uvm_sequencer #(sys_tx_seq_item);
    `uvm_component_utils(sys_tx_sequencer)

    function new(string name = "sys_tx_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass

// -------------------------------------------------------------------------
// DRIVER
// -------------------------------------------------------------------------
class sys_tx_driver extends uvm_driver #(sys_tx_seq_item);
    `uvm_component_utils(sys_tx_driver)

    virtual axis_tx_if vif;

    function new(string name = "sys_tx_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axis_tx_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "virtual interface must be set for: vif")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        // Initialize
        vif.array_o_valid <= 1'b0;
        vif.array_o_psum  <= 512'h0;

        forever begin
            seq_item_port.get_next_item(req);

            // Wait for specified delay cycles before asserting valid
            repeat(req.delay_cycles) @(posedge vif.aclk);

            // Drive data
            vif.array_o_valid <= 1'b1;
            vif.array_o_psum  <= req.psum_row;
            
            @(posedge vif.aclk);
            vif.array_o_valid <= 1'b0;

            seq_item_port.item_done();
        end
    endtask
endclass

// -------------------------------------------------------------------------
// MONITOR
// -------------------------------------------------------------------------
class sys_tx_monitor extends uvm_monitor;
    `uvm_component_utils(sys_tx_monitor)

    virtual axis_tx_if vif;
    uvm_analysis_port #(sys_tx_seq_item) ap;

    function new(string name = "sys_tx_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axis_tx_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "virtual interface must be set for: vif")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        sys_tx_seq_item item;
        forever begin
            @(posedge vif.aclk);
            // We only sample when array_o_valid is HIGH
            // Note: Since we sample on posedge, we see the values just before the edge.
            // But we can also sample just after. For simplicity, we just check if it's 1.
            if (vif.array_o_valid === 1'b1) begin
                item = sys_tx_seq_item::type_id::create("item");
                item.psum_row = vif.array_o_psum;
                ap.write(item);
            end
        end
    endtask
endclass

// -------------------------------------------------------------------------
// AGENT
// -------------------------------------------------------------------------
class sys_tx_agent extends uvm_agent;
    `uvm_component_utils(sys_tx_agent)

    sys_tx_sequencer sequencer;
    sys_tx_driver    driver;
    sys_tx_monitor   monitor;

    function new(string name = "sys_tx_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor = sys_tx_monitor::type_id::create("monitor", this);
        if (get_is_active() == UVM_ACTIVE) begin
            sequencer = sys_tx_sequencer::type_id::create("sequencer", this);
            driver    = sys_tx_driver::type_id::create("driver", this);
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
