`ifndef VSEQ_RX_TESTS_SV
`define VSEQ_RX_TESTS_SV

// TC11: Burst Packing Validation (Zero-delay back-to-back)
class tc11_burst_packing_vseq extends top_vseq_base;
    `uvm_object_utils(tc11_burst_packing_vseq)
    function new(string name="tc11_burst_packing_vseq"); super.new(name); endfunction
    task body();
        send_matrix(16, 0);
        send_matrix(16, 0);
        trigger_compute();
        wait_for_mac_done();
        `uvm_info("TC11", "Burst Packing Validation complete.", UVM_LOW)
    endtask
endclass

// TC12: RX TREADY Backpressure Tolerance
class tc12_rx_tready_tolerance_vseq extends top_vseq_base;
    `uvm_object_utils(tc12_rx_tready_tolerance_vseq)
    function new(string name="tc12_rx_tready_tolerance_vseq"); super.new(name); endfunction
    task body();
        fork
            begin
                repeat(3) begin
                    send_matrix(16, 0);
                    send_matrix(16, 0);
                end
            end
            begin
                repeat(3) begin
                    trigger_compute();
                    wait_for_mac_done();
                end
            end
        join
        `uvm_info("TC12", "RX TREADY Backpressure Tolerance complete.", UVM_LOW)
    endtask
endclass

// TC13: Non-Contiguous TVALID Drops
class tc13_non_contiguous_tvalid_vseq extends top_vseq_base;
    `uvm_object_utils(tc13_non_contiguous_tvalid_vseq)
    function new(string name="tc13_non_contiguous_tvalid_vseq"); super.new(name); endfunction
    task body();
        axis_rx_item rx_item;
        for (int i=0; i<32; i++) begin
            `uvm_do_on_with(rx_item, p_sequencer.axis_rx_sqr_h, {
                tlast == (i == 15 || i == 31);
                delay inside {[1:20]};
            })
        end
        trigger_compute();
        wait_for_mac_done();
        `uvm_info("TC13", "Non-Contiguous TVALID Drops complete.", UVM_LOW)
    endtask
endclass

// TC14: TLAST Frame Misalignment
class tc14_tlast_misalignment_vseq extends top_vseq_base;
    `uvm_object_utils(tc14_tlast_misalignment_vseq)
    function new(string name="tc14_tlast_misalignment_vseq"); super.new(name); endfunction
    task body();
        axis_rx_item rx_item;
        // Drop tlast early (at row 8) to intentionally foul the pointer
        for (int i=0; i<16; i++) begin
            `uvm_do_on_with(rx_item, p_sequencer.axis_rx_sqr_h, {
                tlast == (i == 8);
                delay == 0;
            })
        end
        `uvm_info("TC14", "TLAST Frame Misalignment complete.", UVM_LOW)
    endtask
endclass

// TC15: Extreme INT8 Boundary Stress
class tc15_extreme_int8_bounds_vseq extends top_vseq_base;
    `uvm_object_utils(tc15_extreme_int8_bounds_vseq)
    function new(string name="tc15_extreme_int8_bounds_vseq"); super.new(name); endfunction
    task body();
        axis_rx_item rx_item;
        for (int i=0; i<32; i++) begin
            `uvm_do_on_with(rx_item, p_sequencer.axis_rx_sqr_h, {
                tlast == (i == 15 || i == 31);
                delay == 0;
                tdata inside {128'h7F7F7F7F_7F7F7F7F_7F7F7F7F_7F7F7F7F, 128'h80808080_80808080_80808080_80808080};
            })
        end
        trigger_compute();
        wait_for_mac_done();
        `uvm_info("TC15", "Extreme INT8 Boundary Stress complete.", UVM_LOW)
    endtask
endclass

`endif
