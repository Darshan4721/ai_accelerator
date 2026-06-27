`ifndef SRAM_OUT_AGENT_SV
`define SRAM_OUT_AGENT_SV

// -------------------------------------------------------------------------
// SRAM OUT TRANSACTION ITEM FOR MONITOR
// -------------------------------------------------------------------------
class sram_out_mon_item extends uvm_sequence_item;
    logic         we;
    logic [7:0]   addr;
    logic [127:0] data;
    logic         matrix_done;

    `uvm_object_utils_begin(sram_out_mon_item)
        `uvm_field_int(we, UVM_ALL_ON | UVM_BIN)
        `uvm_field_int(addr, UVM_ALL_ON | UVM_DEC)
        `uvm_field_int(data, UVM_ALL_ON)
        `uvm_field_int(matrix_done, UVM_ALL_ON | UVM_BIN)
    `uvm_object_utils_end

    function new(string name = "sram_out_mon_item");
        super.new(name);
    endfunction
endclass

// -------------------------------------------------------------------------
// SEQUENCER
// -------------------------------------------------------------------------
class sram_out_sequencer extends uvm_sequencer #(sram_out_seq_item);
    `uvm_component_utils(sram_out_sequencer)

    function new(string name = "sram_out_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass

// -------------------------------------------------------------------------
// DRIVER
// -------------------------------------------------------------------------
class sram_out_driver extends uvm_driver #(sram_out_seq_item);
    `uvm_component_utils(sram_out_driver)

    virtual axis_rx_if vif;

    function new(string name = "sram_out_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axis_rx_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "virtual interface must be set for: vif")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        // Default to SRAM ready
        vif.tb_sram_ready <= 1'b1;

        forever begin
            seq_item_port.get_next_item(req);

            if (req.stall_delay > 0) begin
                vif.tb_sram_ready <= 1'b0;
                repeat(req.stall_delay) @(posedge vif.aclk);
            end

            vif.tb_sram_ready <= 1'b1;
            @(posedge vif.aclk);

            seq_item_port.item_done();
        end
    endtask
endclass

// -------------------------------------------------------------------------
// MONITOR
// -------------------------------------------------------------------------
class sram_out_monitor extends uvm_monitor;
    `uvm_component_utils(sram_out_monitor)

    virtual axis_rx_if vif;
    uvm_analysis_port #(sram_out_mon_item) ap;

    function new(string name = "sram_out_monitor", uvm_component parent = null);
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
        sram_out_mon_item item;
        forever begin
            @(posedge vif.aclk);
            // We sample if there is a write OR if rx_matrix_done pulses
            if (vif.sram_we === 1'b1 || vif.rx_matrix_done === 1'b1) begin
                item = sram_out_mon_item::type_id::create("item");
                item.we = vif.sram_we;
                item.addr = vif.sram_w_addr;
                item.data = vif.sram_w_data;
                item.matrix_done = vif.rx_matrix_done;
                ap.write(item);
            end
        end
    endtask
endclass

// -------------------------------------------------------------------------
// AGENT
// -------------------------------------------------------------------------
class sram_out_agent extends uvm_agent;
    `uvm_component_utils(sram_out_agent)

    sram_out_sequencer sequencer;
    sram_out_driver    driver;
    sram_out_monitor   monitor;

    function new(string name = "sram_out_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        monitor = sram_out_monitor::type_id::create("monitor", this);
        if (get_is_active() == UVM_ACTIVE) begin
            sequencer = sram_out_sequencer::type_id::create("sequencer", this);
            driver    = sram_out_driver::type_id::create("driver", this);
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
