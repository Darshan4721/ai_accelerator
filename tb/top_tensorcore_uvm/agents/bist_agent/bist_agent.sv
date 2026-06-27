`ifndef BIST_AGENT_SV
`define BIST_AGENT_SV

class bist_agent extends uvm_agent;
    `uvm_component_utils(bist_agent)
    
    bist_sqr     sqr;
    bist_driver  drv;
    bist_monitor mon;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        mon = bist_monitor::type_id::create("mon", this);
        if(get_is_active() == UVM_ACTIVE) begin
            sqr = bist_sqr::type_id::create("sqr", this);
            drv = bist_driver::type_id::create("drv", this);
        end
    endfunction
    
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        if(get_is_active() == UVM_ACTIVE) begin
            drv.seq_item_port.connect(sqr.seq_item_export);
        end
    endfunction
endclass

`endif
