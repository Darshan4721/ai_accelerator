`ifndef AXIS_RX_MONITOR_SV
`define AXIS_RX_MONITOR_SV

class axis_rx_monitor extends uvm_monitor;
    `uvm_component_utils(axis_rx_monitor)
    
    virtual system_top_if vif;
    uvm_analysis_port #(axis_rx_item) ap;
    
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
        axis_rx_item item;
        
        forever begin
            @(vif.cb_mon);
            if (vif.cb_mon.s_axis_tvalid && vif.cb_mon.s_axis_tready) begin
                item = axis_rx_item::type_id::create("item");
                item.tdata = vif.cb_mon.s_axis_tdata;
                item.tlast = vif.cb_mon.s_axis_tlast;
                ap.write(item);
            end
        end
    endtask
endclass

`endif
