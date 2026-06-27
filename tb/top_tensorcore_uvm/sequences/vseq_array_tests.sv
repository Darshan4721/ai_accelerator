`ifndef VSEQ_ARRAY_TESTS_SV
`define VSEQ_ARRAY_TESTS_SV

// TC26: Sparse Matrix Multiplication
class tc26_sparse_matrix_vseq extends top_vseq_base;
    `uvm_object_utils(tc26_sparse_matrix_vseq)
    function new(string name="tc26_sparse_matrix_vseq"); super.new(name); endfunction
    task body();
        axis_rx_item rx_item;
        for (int i=0; i<32; i++) begin
            `uvm_do_on_with(rx_item, p_sequencer.axis_rx_sqr_h, {
                tlast == (i == 15 || i == 31);
                tdata dist { 128'h0 := 90, 128'h01010101_01010101_01010101_01010101 := 10 };
            })
        end
        trigger_compute();
        wait_for_mac_done();
        `uvm_info("TC26", "Sparse Matrix Multiplication test complete.", UVM_LOW)
    endtask
endclass

// TC27: Dense All-Ones Multiplication
class tc27_dense_all_ones_vseq extends top_vseq_base;
    `uvm_object_utils(tc27_dense_all_ones_vseq)
    function new(string name="tc27_dense_all_ones_vseq"); super.new(name); endfunction
    task body();
        axis_rx_item rx_item;
        for (int i=0; i<32; i++) begin
            `uvm_do_on_with(rx_item, p_sequencer.axis_rx_sqr_h, {
                tlast == (i == 15 || i == 31);
                tdata == 128'h01010101_01010101_01010101_01010101;
            })
        end
        trigger_compute();
        wait_for_mac_done();
        `uvm_info("TC27", "Dense All-Ones test complete.", UVM_LOW)
    endtask
endclass

// TC28: Checkerboard Pattern Injection
class tc28_checkerboard_vseq extends top_vseq_base;
    `uvm_object_utils(tc28_checkerboard_vseq)
    function new(string name="tc28_checkerboard_vseq"); super.new(name); endfunction
    task body();
        axis_rx_item rx_item;
        for (int i=0; i<32; i++) begin
            `uvm_do_on_with(rx_item, p_sequencer.axis_rx_sqr_h, {
                tlast == (i == 15 || i == 31);
                tdata == (i % 2 == 0) ? 128'h55555555_55555555_55555555_55555555 : 128'hAAAAAAAA_AAAAAAAA_AAAAAAAA_AAAAAAAA;
            })
        end
        trigger_compute();
        wait_for_mac_done();
        `uvm_info("TC28", "Checkerboard Pattern Injection complete.", UVM_LOW)
    endtask
endclass

// TC29: Overflow Bound Accumulation
class tc29_overflow_bound_vseq extends top_vseq_base;
    `uvm_object_utils(tc29_overflow_bound_vseq)
    function new(string name="tc29_overflow_bound_vseq"); super.new(name); endfunction
    task body();
        axis_rx_item rx_item;
        for (int i=0; i<32; i++) begin
            `uvm_do_on_with(rx_item, p_sequencer.axis_rx_sqr_h, {
                tlast == (i == 15 || i == 31);
                tdata == 128'h7F7F7F7F_7F7F7F7F_7F7F7F7F_7F7F7F7F; // Max positive
            })
        end
        trigger_compute();
        wait_for_mac_done();
        `uvm_info("TC29", "Overflow Bound Accumulation complete.", UVM_LOW)
    endtask
endclass

// TC30: Zero-Weight Starvation
class tc30_zero_weight_vseq extends top_vseq_base;
    `uvm_object_utils(tc30_zero_weight_vseq)
    function new(string name="tc30_zero_weight_vseq"); super.new(name); endfunction
    task body();
        axis_rx_item rx_item;
        for (int i=0; i<32; i++) begin
            `uvm_do_on_with(rx_item, p_sequencer.axis_rx_sqr_h, {
                tlast == (i == 15 || i == 31);
                tdata == (i < 16) ? 128'h0 : 128'h7F7F7F7F_7F7F7F7F_7F7F7F7F_7F7F7F7F;
            })
        end
        trigger_compute();
        wait_for_mac_done();
        `uvm_info("TC30", "Zero-Weight Starvation complete.", UVM_LOW)
    endtask
endclass

`endif
