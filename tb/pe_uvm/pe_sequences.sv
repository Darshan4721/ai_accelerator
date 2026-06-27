// 1, 3. Throughput Sequence
class throughput_seq extends uvm_sequence #(pe_seq_item);
    `uvm_object_utils(throughput_seq)
    function new(string name="throughput_seq"); super.new(name); endfunction
    task body();
        pe_seq_item item = pe_seq_item::type_id::create("item");
        start_item(item);
        void'(item.randomize() with { w_val == 5; a_val.size() == 50; });
        finish_item(item);
    endtask
endclass

// 2. Stationary Sequence
class stationary_seq extends uvm_sequence #(pe_seq_item);
    `uvm_object_utils(stationary_seq)
    function new(string name="stationary_seq"); super.new(name); endfunction
    task body();
        pe_seq_item item = pe_seq_item::type_id::create("item");
        start_item(item);
        void'(item.randomize() with { w_val == 42; a_val.size() == 20; });
        finish_item(item);
    endtask
endclass

// 4. Bubble Sequence
class bubble_seq extends uvm_sequence #(pe_seq_item);
    `uvm_object_utils(bubble_seq)
    function new(string name="bubble_seq"); super.new(name); endfunction
    task body();
        pe_seq_item item = pe_seq_item::type_id::create("item");
        start_item(item);
        void'(item.randomize() with { a_val.size() == 30; });
        finish_item(item);
    endtask
endclass

// 5, 10. Booth Precision Sequence
class booth_precision_seq extends uvm_sequence #(pe_seq_item);
    `uvm_object_utils(booth_precision_seq)
    function new(string name="booth_precision_seq"); super.new(name); endfunction
    task body();
        pe_seq_item item = pe_seq_item::type_id::create("item");
        start_item(item);
        void'(item.randomize() with { w_val == -10; a_val.size() == 10; });
        finish_item(item);
    endtask
endclass

// 6. Bypass Sequence
class bypass_seq extends uvm_sequence #(pe_seq_item);
    `uvm_object_utils(bypass_seq)
    function new(string name="bypass_seq"); super.new(name); endfunction
    task body();
        pe_seq_item item = pe_seq_item::type_id::create("item");
        start_item(item);
        void'(item.randomize() with { a_val.size() == 10; foreach(a_val[i]) a_val[i] == 0; });
        finish_item(item);
    endtask
endclass

// 7. Accumulate Sequence
class accum_seq extends uvm_sequence #(pe_seq_item);
    `uvm_object_utils(accum_seq)
    function new(string name="accum_seq"); super.new(name); endfunction
    task body();
        pe_seq_item item = pe_seq_item::type_id::create("item");
        start_item(item);
        void'(item.randomize() with { w_val == 0; a_val.size() == 10; });
        finish_item(item);
    endtask
endclass

// 8. Identity Sequence
class identity_seq extends uvm_sequence #(pe_seq_item);
    `uvm_object_utils(identity_seq)
    function new(string name="identity_seq"); super.new(name); endfunction
    task body();
        pe_seq_item item = pe_seq_item::type_id::create("item");
        start_item(item);
        void'(item.randomize() with { w_val == 1; a_val.size() == 10; });
        finish_item(item);
    endtask
endclass

// 9, 11, 12. Bounds Sequence
class bounds_seq extends uvm_sequence #(pe_seq_item);
    `uvm_object_utils(bounds_seq)
    function new(string name="bounds_seq"); super.new(name); endfunction
    task body();
        pe_seq_item item;
        item = pe_seq_item::type_id::create("item");
        start_item(item);
        void'(item.randomize() with { w_val == -128; a_val.size() == 5; foreach(a_val[i]) a_val[i] == -128; });
        finish_item(item);

        item = pe_seq_item::type_id::create("item");
        start_item(item);
        void'(item.randomize() with { w_val == 127; a_val.size() == 5; foreach(a_val[i]) a_val[i] == 127; });
        finish_item(item);

        item = pe_seq_item::type_id::create("item");
        start_item(item);
        void'(item.randomize() with { w_val == -1; a_val.size() == 5; });
        finish_item(item);
    endtask
endclass

// 13, 14. Wrap Sequence
class wrap_seq extends uvm_sequence #(pe_seq_item);
    `uvm_object_utils(wrap_seq)
    function new(string name="wrap_seq"); super.new(name); endfunction
    task body();
        pe_seq_item item;
        item = pe_seq_item::type_id::create("item");
        start_item(item);
        void'(item.randomize() with { 
            w_val == 100; a_val.size() == 5; 
            foreach(a_val[i]) a_val[i] == 100;
            foreach(psum_val[i]) psum_val[i] == 32'h7FFFFFFF - 1000;
        });
        finish_item(item);

        item = pe_seq_item::type_id::create("item");
        start_item(item);
        void'(item.randomize() with { 
            w_val == -100; a_val.size() == 5; 
            foreach(a_val[i]) a_val[i] == 100;
            foreach(psum_val[i]) psum_val[i] == 32'h80000000 + 1000;
        });
        finish_item(item);
    endtask
endclass

// 15. Toggle Sequence
class toggle_seq extends uvm_sequence #(pe_seq_item);
    `uvm_object_utils(toggle_seq)
    function new(string name="toggle_seq"); super.new(name); endfunction
    task body();
        pe_seq_item item = pe_seq_item::type_id::create("item");
        start_item(item);
        void'(item.randomize() with { w_val == 8'hAA; a_val.size() == 10; });
        foreach(item.a_val[i]) begin 
            item.a_val[i] = (i%2==0) ? 8'hAA : 8'h55; 
            item.psum_val[i] = (i%2==0) ? 32'hAAAAAAAA : 32'h55555555;
        end
        finish_item(item);
    endtask
endclass

// 16, 17. Reset Recovery Sequence
class reset_recovery_seq extends uvm_sequence #(pe_seq_item);
    `uvm_object_utils(reset_recovery_seq)
    function new(string name="reset_recovery_seq"); super.new(name); endfunction
    task body();
        pe_seq_item item;
        
        item = pe_seq_item::type_id::create("item");
        start_item(item);
        item.rst_assert = 1;
        finish_item(item);

        item = pe_seq_item::type_id::create("item");
        start_item(item);
        void'(item.randomize() with { w_val == 10; a_val.size() == 5; });
        finish_item(item);
    endtask
endclass
