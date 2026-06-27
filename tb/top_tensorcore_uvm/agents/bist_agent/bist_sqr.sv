`ifndef BIST_SQR_SV
`define BIST_SQR_SV

class bist_sqr extends uvm_sequencer #(bist_item);
    `uvm_component_utils(bist_sqr)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass

`endif
