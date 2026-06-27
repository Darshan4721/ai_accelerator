`ifndef AXIS_RX_AGENT_SV
`define AXIS_RX_AGENT_SV

class axis_rx_agent extends uvm_agent;
    `uvm_component_utils(axis_rx_agent)
    
    axis_rx_sqr     sqr;
    axis_rx_driver  drv;
    axis_rx_monitor mon;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        mon = axis_rx_monitor::type_id::create("mon", this);
        if(get_is_active() == UVM_ACTIVE) begin
            sqr = axis_rx_sqr::type_id::create("sqr", this);
            drv = axis_rx_driver::type_id::create("drv", this);
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
