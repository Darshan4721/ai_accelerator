`ifndef AXI_RX_AGENT_SV
`define AXI_RX_AGENT_SV

// -------------------------------------------------------------------------
// AXI TRANSACTION ITEM FOR MONITOR (We need one for Scoreboard)
// -------------------------------------------------------------------------
class axi_rx_mon_item extends uvm_sequence_item;
    logic [511:0] tdata;
    logic         tlast;

    `uvm_object_utils_begin(axi_rx_mon_item)
        `uvm_field_int(tdata, UVM_ALL_ON)
        `uvm_field_int(tlast, UVM_ALL_ON | UVM_BIN)
    `uvm_object_utils_end

    function new(string name = "axi_rx_mon_item");
        super.new(name);
    endfunction
endclass

// -------------------------------------------------------------------------
// SEQUENCER
// -------------------------------------------------------------------------
class axi_rx_sequencer extends uvm_sequencer #(axi_rx_seq_item);
    `uvm_component_utils(axi_rx_sequencer)

    function new(string name = "axi_rx_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass

// -------------------------------------------------------------------------
// DRIVER
// -------------------------------------------------------------------------
class axi_rx_driver extends uvm_driver #(axi_rx_seq_item);
    `uvm_component_utils(axi_rx_driver)

    virtual axis_tx_if vif;

    function new(string name = "axi_rx_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axis_tx_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "virtual interface must be set for: vif")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        // Default to ready
        vif.m_axis_tready <= 1'b1;

        forever begin
            seq_item_port.get_next_item(req);

            if (req.tready_delay > 0) begin
                vif.m_axis_tready <= 1'b0;
                repeat(req.tready_delay) @(posedge vif.aclk);
            end

            vif.m_axis_tready <= 1'b1;
            
            // Hold it high for at least 1 cycle to allow transfers
            @(posedge vif.aclk);

            seq_item_port.item_done();
        end
    endtask
endclass

// -------------------------------------------------------------------------
// MONITOR
// -------------------------------------------------------------------------
class axi_rx_monitor extends uvm_monitor;
    `uvm_component_utils(axi_rx_monitor)

    virtual axis_tx_if vif;
    uvm_analysis_port #(axi_rx_mon_item) ap;

    function new(string name = "axi_rx_monitor", uvm_component parent = null);
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
        axi_rx_mon_item item;
        forever begin
            @(posedge vif.aclk);
            // Sample a successful handshake
            if (vif.m_axis_tvalid === 1'b1 && vif.m_axis_tready === 1'b1) begin
                item = axi_rx_mon_item::type_id::create("item");
                item.tdata = vif.m_axis_tdata;
                item.tlast = vif.m_axis_tlast;
                ap.write(item);
            end
        end
    endtask
endclass

// -------------------------------------------------------------------------
// AGENT
// -------------------------------------------------------------------------
class axi_rx_agent extends uvm_agent;
    `uvm_component_utils(axi_rx_agent)

    axi_rx_sequencer sequencer;
    axi_rx_driver    driver;
    axi_rx_monitor   monitor;

    function new(string name = "axi_rx_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor = axi_rx_monitor::type_id::create("monitor", this);
        if (get_is_active() == UVM_ACTIVE) begin
            sequencer = axi_rx_sequencer::type_id::create("sequencer", this);
            driver    = axi_rx_driver::type_id::create("driver", this);
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
