`ifndef BIST_MONITOR_SV
`define BIST_MONITOR_SV

class bist_monitor extends uvm_monitor;
    `uvm_component_utils(bist_monitor)
    
    virtual system_top_if vif;
    uvm_analysis_port #(bist_item) ap;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual system_top_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
    endfunction
    
    task run_phase(uvm_phase phase);
        bist_item item;
        logic prev_bist_done = 0;
        
        forever begin
            @(vif.cb_mon);
            // We capture a transaction when bist_done transitions high
            if (vif.cb_mon.bist_done_o === 1'b1 && prev_bist_done === 1'b0) begin
                item = bist_item::type_id::create("item");
                item.bist_done = 1'b1;
                item.bist_fail = vif.cb_mon.bist_fail_o;
                ap.write(item);
            end
            prev_bist_done = vif.cb_mon.bist_done_o;
        end
    endtask
endclass

`endif
