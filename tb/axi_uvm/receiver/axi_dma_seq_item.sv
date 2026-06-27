`ifndef AXI_DMA_SEQ_ITEM_SV
`define AXI_DMA_SEQ_ITEM_SV

class axi_dma_seq_item extends uvm_sequence_item;
    
    // Physical Data
    rand logic [127:0] tdata;
    rand logic         tlast;
    
    // Meta-Data for driving
    rand int valid_delay;

    constraint delay_c {
        valid_delay >= 0;
        valid_delay <= 10;
    }

    `uvm_object_utils_begin(axi_dma_seq_item)
        `uvm_field_int(tdata, UVM_ALL_ON)
        `uvm_field_int(tlast, UVM_ALL_ON | UVM_BIN)
        `uvm_field_int(valid_delay, UVM_ALL_ON | UVM_DEC)
    `uvm_object_utils_end

    function new(string name = "axi_dma_seq_item");
        super.new(name);
    endfunction

endclass

`endif
