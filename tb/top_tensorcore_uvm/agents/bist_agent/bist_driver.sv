`ifndef BIST_DRIVER_SV
`define BIST_DRIVER_SV

class bist_driver extends uvm_driver #(bist_item);
    `uvm_component_utils(bist_driver)
    
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
        vif.cb_drv.bist_start_i <= 1'b0;
        vif.cb_drv.expected_misr_sig_i <= 0;
        
        forever begin
            seq_item_port.get_next_item(req);
            
            vif.cb_drv.bist_start_i <= req.bist_start;
            vif.cb_drv.expected_misr_sig_i <= req.expected_sig;
            
            @(vif.cb_drv);
            
            seq_item_port.item_done();
        end
    endtask
endclass

`endif
