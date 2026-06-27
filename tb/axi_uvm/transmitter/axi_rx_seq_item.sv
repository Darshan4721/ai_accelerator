`ifndef AXI_RX_SEQ_ITEM_SV
`define AXI_RX_SEQ_ITEM_SV

class axi_rx_seq_item extends uvm_sequence_item;
    
    // Meta-Data for driving tready stalls
    rand int tready_delay;

    constraint delay_c {
        tready_delay >= 0;
        tready_delay <= 15;
    }

    `uvm_object_utils_begin(axi_rx_seq_item)
        `uvm_field_int(tready_delay, UVM_ALL_ON | UVM_DEC)
    `uvm_object_utils_end

    function new(string name = "axi_rx_seq_item");
        super.new(name);
    endfunction

endclass

`endif
