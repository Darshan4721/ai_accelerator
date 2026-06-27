`ifndef SYS_TX_SEQ_ITEM_SV
`define SYS_TX_SEQ_ITEM_SV

class sys_tx_seq_item extends uvm_sequence_item;
    
    // Physical Data
    rand logic [511:0] psum_row;
    
    // Meta-Data for driving
    rand int delay_cycles;

    constraint delay_c {
        delay_cycles >= 0;
        delay_cycles <= 15;
    }

    `uvm_object_utils_begin(sys_tx_seq_item)
        `uvm_field_int(psum_row, UVM_ALL_ON)
        `uvm_field_int(delay_cycles, UVM_ALL_ON | UVM_DEC)
    `uvm_object_utils_end

    function new(string name = "sys_tx_seq_item");
        super.new(name);
    endfunction

endclass

`endif
