`ifndef AXIS_TX_SQR_SV
`define AXIS_TX_SQR_SV

class axis_tx_sqr extends uvm_sequencer #(axis_tx_item);
    `uvm_component_utils(axis_tx_sqr)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass

`endif
