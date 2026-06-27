`ifndef AXIS_RX_ITEM_SV
`define AXIS_RX_ITEM_SV

class axis_rx_item extends uvm_sequence_item;
    rand bit [127:0] tdata;
    rand bit         tlast;
    
    // Configurable delays for backpressure/stalls
    rand int         delay; 
    
    `uvm_object_utils_begin(axis_rx_item)
        `uvm_field_int(tdata, UVM_ALL_ON)
        `uvm_field_int(tlast, UVM_ALL_ON)
        `uvm_field_int(delay, UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_object_utils_end
    
    // Reasonable delay constraint
    constraint c_delay { delay dist { 0 := 80, [1:5] := 15, [6:20] := 5 }; }
    
    function new(string name = "axis_rx_item");
        super.new(name);
    endfunction
endclass

`endif
