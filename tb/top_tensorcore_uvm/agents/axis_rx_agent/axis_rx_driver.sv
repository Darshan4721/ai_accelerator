`ifndef AXIS_RX_DRIVER_SV
`define AXIS_RX_DRIVER_SV

class axis_rx_driver extends uvm_driver #(axis_rx_item);
    `uvm_component_utils(axis_rx_driver)
    
    virtual system_top_if vif;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual system_top_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
    endfunction
    
    task run_phase(uvm_phase phase);
        vif.cb_drv.s_axis_tdata <= 0;
        vif.cb_drv.s_axis_tvalid <= 0;
        vif.cb_drv.s_axis_tlast <= 0;
        
        forever begin
            seq_item_port.get_next_item(req);
            
            if (req.delay > 0) begin
                vif.cb_drv.s_axis_tvalid <= 1'b0;
                repeat(req.delay) @(vif.cb_drv);
            end
            
            vif.cb_drv.s_axis_tdata <= req.tdata;
            vif.cb_drv.s_axis_tlast <= req.tlast;
            vif.cb_drv.s_axis_tvalid <= 1'b1;
            
            @(vif.cb_drv);
            while (vif.cb_drv.s_axis_tready !== 1'b1) begin
                @(vif.cb_drv);
            end
            
            // To ensure tvalid drops if there are no more items, we can use a non-blocking check
            // However, typical pipelined drivers just let the next get_next_item drop it if delayed.
            // A simple approach is to deassert it if the queue is empty.
            if (seq_item_port.has_do_available() == 0) begin
                vif.cb_drv.s_axis_tvalid <= 1'b0;
            end
            
            seq_item_port.item_done();
        end
    endtask
endclass

`endif
