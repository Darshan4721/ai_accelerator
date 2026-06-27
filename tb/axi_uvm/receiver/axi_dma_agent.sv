`ifndef AXI_DMA_AGENT_SV
`define AXI_DMA_AGENT_SV

// -------------------------------------------------------------------------
// SEQUENCER
// -------------------------------------------------------------------------
class axi_dma_sequencer extends uvm_sequencer #(axi_dma_seq_item);
    `uvm_component_utils(axi_dma_sequencer)

    function new(string name = "axi_dma_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass

// -------------------------------------------------------------------------
// DRIVER
// -------------------------------------------------------------------------
class axi_dma_driver extends uvm_driver #(axi_dma_seq_item);
    `uvm_component_utils(axi_dma_driver)

    virtual axis_rx_if vif;

    function new(string name = "axi_dma_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axis_rx_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "virtual interface must be set for: vif")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        // Initialize
        vif.s_axis_tvalid <= 1'b0;
        vif.s_axis_tdata  <= 128'h0;
        vif.s_axis_tlast  <= 1'b0;

        forever begin
            seq_item_port.try_next_item(req);
            if (req == null) begin
                vif.s_axis_tvalid <= 1'b0;
                seq_item_port.get_next_item(req);
            end

            // Wait for specified valid delays
            if (req.valid_delay > 0) begin
                vif.s_axis_tvalid <= 1'b0;
                repeat(req.valid_delay) @(posedge vif.aclk);
            end

            // Drive data
            vif.s_axis_tvalid <= 1'b1;
            vif.s_axis_tdata  <= req.tdata;
            vif.s_axis_tlast  <= req.tlast;

            // Wait for handshake
            do begin
                @(posedge vif.aclk);
            end while (vif.s_axis_tready !== 1'b1);
            
            // Note: We don't drop tvalid immediately to 0 here unless delay tells us to, 
            // but we must let the next loop iteration handle it to support back-to-back streaming.

            seq_item_port.item_done();
        end
    endtask
endclass

// -------------------------------------------------------------------------
// MONITOR
// -------------------------------------------------------------------------
class axi_dma_monitor extends uvm_monitor;
    `uvm_component_utils(axi_dma_monitor)

    virtual axis_rx_if vif;
    uvm_analysis_port #(axi_dma_seq_item) ap;

    function new(string name = "axi_dma_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axis_rx_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "virtual interface must be set for: vif")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        axi_dma_seq_item item;
        forever begin
            @(posedge vif.aclk);
            if (vif.s_axis_tvalid === 1'b1 && vif.s_axis_tready === 1'b1) begin
                item = axi_dma_seq_item::type_id::create("item");
                item.tdata = vif.s_axis_tdata;
                item.tlast = vif.s_axis_tlast;
                ap.write(item);
            end
        end
    endtask
endclass

// -------------------------------------------------------------------------
// AGENT
// -------------------------------------------------------------------------
class axi_dma_agent extends uvm_agent;
    `uvm_component_utils(axi_dma_agent)

    axi_dma_sequencer sequencer;
    axi_dma_driver    driver;
    axi_dma_monitor   monitor;

    function new(string name = "axi_dma_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor = axi_dma_monitor::type_id::create("monitor", this);
        if (get_is_active() == UVM_ACTIVE) begin
            sequencer = axi_dma_sequencer::type_id::create("sequencer", this);
            driver    = axi_dma_driver::type_id::create("driver", this);
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
