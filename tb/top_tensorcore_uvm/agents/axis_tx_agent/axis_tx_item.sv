`ifndef AXIS_TX_ITEM_SV
`define AXIS_TX_ITEM_SV

class axis_tx_item extends uvm_sequence_item;
    // Data captured from the DUT
    bit [511:0] tdata;
    bit         tlast;
    
    // Control from the sequence to inject stalls (tready drops)
    rand int    ready_delay;
    
    `uvm_object_utils_begin(axis_tx_item)
        `uvm_field_int(tdata, UVM_ALL_ON)
        `uvm_field_int(tlast, UVM_ALL_ON)
        `uvm_field_int(ready_delay, UVM_ALL_ON | UVM_NOCOMPARE)
    `uvm_object_utils_end
    
    constraint c_delay { ready_delay dist { 0 := 80, [1:30] := 20 }; }
    
    function new(string name = "axis_tx_item");
        super.new(name);
    endfunction
endclass

`endif
