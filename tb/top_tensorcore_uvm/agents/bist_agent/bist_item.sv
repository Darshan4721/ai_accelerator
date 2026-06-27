`ifndef BIST_ITEM_SV
`define BIST_ITEM_SV

class bist_item extends uvm_sequence_item;
    rand bit         bist_start;
    rand bit [511:0] expected_sig;
    
    // Monitored responses
    bit              bist_done;
    bit              bist_fail;
    
    `uvm_object_utils_begin(bist_item)
        `uvm_field_int(bist_start, UVM_ALL_ON)
        `uvm_field_int(expected_sig, UVM_ALL_ON)
        `uvm_field_int(bist_done, UVM_ALL_ON)
        `uvm_field_int(bist_fail, UVM_ALL_ON)
    `uvm_object_utils_end
    
    function new(string name = "bist_item");
        super.new(name);
    endfunction
endclass

`endif
