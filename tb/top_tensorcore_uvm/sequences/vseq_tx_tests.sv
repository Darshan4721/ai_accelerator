`ifndef VSEQ_TX_TESTS_SV
`define VSEQ_TX_TESTS_SV

// TC16: 512-bit Data Drain Integrity
class tc16_tx_drain_integrity_vseq extends top_vseq_base;
    `uvm_object_utils(tc16_tx_drain_integrity_vseq)
    function new(string name="tc16_tx_drain_integrity_vseq"); super.new(name); endfunction
    task body();
        send_matrix(16);
        send_matrix(16);
        trigger_compute();
        wait_for_mac_done();
        `uvm_info("TC16", "Data Drain Integrity test complete.", UVM_LOW)
    endtask
endclass

// TC17: TX TREADY Backpressure Lock (100 cycle stall)
class tc17_tx_backpressure_lock_vseq extends top_vseq_base;
    `uvm_object_utils(tc17_tx_backpressure_lock_vseq)
    function new(string name="tc17_tx_backpressure_lock_vseq"); super.new(name); endfunction
    task body();
        axis_tx_item tx_item;
        send_matrix(16);
        send_matrix(16);
        trigger_compute();
        `uvm_do_on_with(tx_item, p_sequencer.axis_tx_sqr_h, { ready_delay == 100; })
        wait_for_mac_done();
        `uvm_info("TC17", "TX TREADY Backpressure Lock test complete.", UVM_LOW)
    endtask
endclass

// TC18: Mid-Drain TREADY Interruption
class tc18_mid_drain_interruption_vseq extends top_vseq_base;
    `uvm_object_utils(tc18_mid_drain_interruption_vseq)
    function new(string name="tc18_mid_drain_interruption_vseq"); super.new(name); endfunction
    task body();
        axis_tx_item tx_item;
        send_matrix(16);
        send_matrix(16);
        trigger_compute();
        #80ns; // Wait mid-drain
        `uvm_do_on_with(tx_item, p_sequencer.axis_tx_sqr_h, { ready_delay == 10; })
        wait_for_mac_done();
        `uvm_info("TC18", "Mid-Drain Interruption test complete.", UVM_LOW)
    endtask
endclass

// TC19: End-of-Frame TLAST Generation Validation
class tc19_eof_tlast_validation_vseq extends top_vseq_base;
    `uvm_object_utils(tc19_eof_tlast_validation_vseq)
    function new(string name="tc19_eof_tlast_validation_vseq"); super.new(name); endfunction
    task body();
        send_matrix(16);
        send_matrix(16);
        trigger_compute();
        wait_for_mac_done();
        `uvm_info("TC19", "End-of-Frame TLAST Generation Validation complete.", UVM_LOW)
    endtask
endclass

// TC20: Staggered TREADY Polling
class tc20_staggered_tready_polling_vseq extends top_vseq_base;
    `uvm_object_utils(tc20_staggered_tready_polling_vseq)
    function new(string name="tc20_staggered_tready_polling_vseq"); super.new(name); endfunction
    task body();
        axis_tx_item tx_item;
        send_matrix(16);
        send_matrix(16);
        trigger_compute();
        repeat(16) begin
            `uvm_do_on_with(tx_item, p_sequencer.axis_tx_sqr_h, { ready_delay inside {[1:3]}; })
        end
        wait_for_mac_done();
        `uvm_info("TC20", "Staggered TREADY Polling test complete.", UVM_LOW)
    endtask
endclass

`endif
