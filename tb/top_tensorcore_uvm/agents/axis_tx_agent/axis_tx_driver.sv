`ifndef AXIS_TX_DRIVER_SV
`define AXIS_TX_DRIVER_SV

class axis_tx_driver extends uvm_driver #(axis_tx_item);
    `uvm_component_utils(axis_tx_driver)
    
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
        vif.cb_drv.m_axis_tready <= 1'b1; // Default to always ready
        
        forever begin
            seq_item_port.get_next_item(req);
            
            // If the sequence requested a stall, drop tready
            if (req.ready_delay > 0) begin
                vif.cb_drv.m_axis_tready <= 1'b0;
                repeat(req.ready_delay) @(vif.cb_drv);
            end
            
            // Assert ready and wait at least one cycle
            vif.cb_drv.m_axis_tready <= 1'b1;
            @(vif.cb_drv);
            
            seq_item_port.item_done();
        end
    endtask
endclass

`endif
