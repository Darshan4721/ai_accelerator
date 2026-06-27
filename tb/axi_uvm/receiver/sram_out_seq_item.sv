`ifndef SRAM_OUT_SEQ_ITEM_SV
`define SRAM_OUT_SEQ_ITEM_SV

class sram_out_seq_item extends uvm_sequence_item;
    
    // Meta-Data for driving SRAM stalls
    rand int stall_delay;

    constraint delay_c {
        stall_delay >= 0;
        stall_delay <= 10;
    }

    `uvm_object_utils_begin(sram_out_seq_item)
        `uvm_field_int(stall_delay, UVM_ALL_ON | UVM_DEC)
    `uvm_object_utils_end

    function new(string name = "sram_out_seq_item");
        super.new(name);
    endfunction

endclass

`endif
