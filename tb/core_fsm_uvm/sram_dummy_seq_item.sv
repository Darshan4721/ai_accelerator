`ifndef SRAM_DUMMY_SEQ_ITEM_SV
`define SRAM_DUMMY_SEQ_ITEM_SV

class sram_dummy_seq_item extends uvm_sequence_item;
    
    // Variables
    rand logic [127:0] dummy_r_data;
    
    // For monitoring
    logic         sram_re;
    logic [7:0]   sram_r_addr;

    `uvm_object_utils_begin(sram_dummy_seq_item)
        `uvm_field_int(dummy_r_data, UVM_ALL_ON)
        `uvm_field_int(sram_re, UVM_ALL_ON)
        `uvm_field_int(sram_r_addr, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "sram_dummy_seq_item");
        super.new(name);
    endfunction
endclass

`endif
