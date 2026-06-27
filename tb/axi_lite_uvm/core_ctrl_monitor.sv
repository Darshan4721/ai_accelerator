`ifndef CORE_CTRL_MONITOR_SV
`define CORE_CTRL_MONITOR_SV

class core_ctrl_monitor extends uvm_monitor;
    `uvm_component_utils(core_ctrl_monitor)

    virtual axi_lite_if vif;
    uvm_analysis_port #(core_ctrl_seq_item) ap;

    function new(string name = "core_ctrl_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_lite_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "virtual interface must be set for: vif")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        core_ctrl_seq_item item;
        
        forever begin
            @(posedge vif.clk);
            if (vif.start_compute === 1'b1) begin
                item = core_ctrl_seq_item::type_id::create("item");
                // The item just indicates a pulse occurred
                ap.write(item);
            end
        end
    endtask
endclass

`endif
