class pe_seq_item extends uvm_sequence_item;
    rand bit rst_assert;
    rand byte w_val;
    rand byte a_val[];
    rand int  psum_val[];
    
    int dut_psum; // Holds DUT output for scoreboard

    `uvm_object_utils_begin(pe_seq_item)
        `uvm_field_int(rst_assert, UVM_ALL_ON)
        `uvm_field_int(w_val, UVM_ALL_ON)
        `uvm_field_array_int(a_val, UVM_ALL_ON)
        `uvm_field_array_int(psum_val, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "pe_seq_item");
        super.new(name);
        rst_assert = 0;
    endfunction

    // Mentor: Professionally enforce dynamic array sizes directly in the item
    constraint size_c {
        psum_val.size() == a_val.size();
    }
endclass
