`ifndef HOST_CTRL_SEQ_ITEM_SV
`define HOST_CTRL_SEQ_ITEM_SV

class host_ctrl_seq_item extends uvm_sequence_item;
    
    // Variables
    rand int delay_before_start;

    constraint delay_c {
        delay_before_start >= 0;
        delay_before_start <= 50;
    }

    `uvm_object_utils_begin(host_ctrl_seq_item)
        `uvm_field_int(delay_before_start, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "host_ctrl_seq_item");
        super.new(name);
    endfunction
endclass

`endif
