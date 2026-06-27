`ifndef AXI_LITE_SQR_SV
`define AXI_LITE_SQR_SV

class axi_lite_sqr extends uvm_sequencer #(axi_lite_item);
    `uvm_component_utils(axi_lite_sqr)
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
endclass

`endif
