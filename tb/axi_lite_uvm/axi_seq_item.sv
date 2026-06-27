`ifndef AXI_SEQ_ITEM_SV
`define AXI_SEQ_ITEM_SV

class axi_seq_item extends uvm_sequence_item;
    
    rand bit [31:0] addr;
    rand bit [31:0] data;
    rand bit        is_write;
    
    // Test pipeline stalls by dropping BREADY/RREADY randomly
    rand int        backpressure_delay;

    constraint delay_c {
        backpressure_delay >= 0;
        backpressure_delay <= 20;
        
        // 80% of the time, no backpressure for fast processing
        backpressure_delay dist { 0 := 80, [1:20] := 20 };
    }

    `uvm_object_utils_begin(axi_seq_item)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(data, UVM_ALL_ON)
        `uvm_field_int(is_write, UVM_ALL_ON)
        `uvm_field_int(backpressure_delay, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "axi_seq_item");
        super.new(name);
    endfunction
endclass

`endif
