`ifndef AXIS_RX_SQR_SV
`define AXIS_RX_SQR_SV

class axis_rx_sqr extends uvm_sequencer #(axis_rx_item);
    `uvm_component_utils(axis_rx_sqr)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass

`endif
