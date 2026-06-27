`ifndef ARRAY_FEEDBACK_SEQ_ITEM_SV
`define ARRAY_FEEDBACK_SEQ_ITEM_SV

class array_feedback_seq_item extends uvm_sequence_item;
    
    // Variables
    rand int weight_lock_delay;

    constraint delay_c {
        weight_lock_delay >= 0;
        weight_lock_delay <= 20;
    }

    `uvm_object_utils_begin(array_feedback_seq_item)
        `uvm_field_int(weight_lock_delay, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "array_feedback_seq_item");
        super.new(name);
    endfunction
endclass

`endif
