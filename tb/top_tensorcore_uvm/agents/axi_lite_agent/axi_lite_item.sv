`ifndef AXI_LITE_ITEM_SV
`define AXI_LITE_ITEM_SV

class axi_lite_item extends uvm_sequence_item;
    rand bit [31:0] addr;
    rand bit [31:0] data;
    rand bit        is_write;
    
    // Response fields
    bit [1:0]       bresp;
    bit [1:0]       rresp;
    
    `uvm_object_utils_begin(axi_lite_item)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(data, UVM_ALL_ON)
        `uvm_field_int(is_write, UVM_ALL_ON)
        `uvm_field_int(bresp, UVM_ALL_ON)
        `uvm_field_int(rresp, UVM_ALL_ON)
    `uvm_object_utils_end
    
    function new(string name = "axi_lite_item");
        super.new(name);
    endfunction
endclass

`endif
