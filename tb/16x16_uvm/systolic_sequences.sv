class smoke_seq extends uvm_sequence #(matrix_seq_item);
    `uvm_object_utils(smoke_seq)
    function new(string name="smoke_seq"); super.new(name); endfunction
    task body();
        matrix_seq_item req = matrix_seq_item::type_id::create("req");
        start_item(req);
        if (!req.randomize() with {
            load_weights == 1;
            foreach(w_mat[i, j]) {
                if (i == j) w_mat[i][j] == 1;
                else w_mat[i][j] == 0;
            }
        }) `uvm_error("SEQ", "Randomize failed")
        finish_item(req);
    endtask
endclass

class max_bounds_seq extends uvm_sequence #(matrix_seq_item);
    `uvm_object_utils(max_bounds_seq)
    function new(string name="max_bounds_seq"); super.new(name); endfunction
    task body();
        matrix_seq_item req = matrix_seq_item::type_id::create("req");
        start_item(req);
        if (!req.randomize() with {
            load_weights == 1;
            foreach(w_mat[i, j]) w_mat[i][j] inside {8'h7F, 8'h80};
            foreach(a_mat[i, j]) a_mat[i][j] inside {8'h7F, 8'h80};
        }) `uvm_error("SEQ", "Randomize failed")
        finish_item(req);
    endtask
endclass

class stress_1000_seq extends uvm_sequence #(matrix_seq_item);
    `uvm_object_utils(stress_1000_seq)
    function new(string name="stress_1000_seq"); super.new(name); endfunction
    task body();
        // 1000 cycles / 16 cycles per matrix = approx 65 matrices. We do 70.
        for(int i=0; i<70; i++) begin
            matrix_seq_item req = matrix_seq_item::type_id::create("req");
            start_item(req);
            if (!req.randomize() with {
                if (i == 0) load_weights == 1;
                else load_weights == 0;
            }) `uvm_error("SEQ", "Randomize failed")
            finish_item(req);
        end
    endtask
endclass
