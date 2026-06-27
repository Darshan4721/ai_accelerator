`ifndef CORE_CTRL_SEQ_ITEM_SV
`define CORE_CTRL_SEQ_ITEM_SV

class core_ctrl_seq_item extends uvm_sequence_item;
    
    // Simulate the time the FSM takes to run its matrix math
    rand int mac_done_delay;

    constraint delay_c {
        // Normally it's 48 cycles as per specs, but we randomize to test polling
        mac_done_delay >= 10;
        mac_done_delay <= 100;
    }

    `uvm_object_utils_begin(core_ctrl_seq_item)
        `uvm_field_int(mac_done_delay, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "core_ctrl_seq_item");
        super.new(name);
    endfunction
endclass

`endif
