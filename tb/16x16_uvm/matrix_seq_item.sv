class matrix_seq_item extends uvm_sequence_item;
    `uvm_object_utils(matrix_seq_item)
    
    rand byte w_mat[16][16];
    rand byte a_mat[16][16];
    rand bit  load_weights;
    
    int dut_psum[16][16];
    
    constraint c_load {
        load_weights dist { 1 := 10, 0 := 90 }; // 10% chance to load new weights, 90% to reuse
    }
    
    function new(string name = "matrix_seq_item");
        super.new(name);
    endfunction
endclass
