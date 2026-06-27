`ifndef VSEQ_AXI_LITE_TESTS_SV
`define VSEQ_AXI_LITE_TESTS_SV

// TC1: Firmware Hardware-in-the-Loop Handshake (Standard Wakeup)
class tc1_hw_in_the_loop_vseq extends top_vseq_base;
    `uvm_object_utils(tc1_hw_in_the_loop_vseq)
    function new(string name="tc1_hw_in_the_loop_vseq"); super.new(name); endfunction
    
    task body();
        send_matrix(16); // Weights
        send_matrix(16); // Activations
        trigger_compute();
        wait_for_mac_done();
        `uvm_info("TC1", "Hardware-in-the-Loop Handshake complete.", UVM_LOW)
    endtask
endclass

// TC2: Control Plane vs. Data Plane Cross-Talk Rejection
class tc2_crosstalk_rejection_vseq extends top_vseq_base;
    `uvm_object_utils(tc2_crosstalk_rejection_vseq)
    function new(string name="tc2_crosstalk_rejection_vseq"); super.new(name); endfunction
    
    task body();
        send_matrix(16);
        send_matrix(16);
        trigger_compute();
        // Continuously poll 0x04 every cycle during heavy math
        wait_for_mac_done();
        `uvm_info("TC2", "Cross-Talk Rejection polling complete.", UVM_LOW)
    endtask
endclass

// TC3: Invalid Address Isolation (CPU Anti-Lockup)
class tc3_invalid_addr_vseq extends top_vseq_base;
    `uvm_object_utils(tc3_invalid_addr_vseq)
    function new(string name="tc3_invalid_addr_vseq"); super.new(name); endfunction
    
    task body();
        fork
            begin
                send_matrix(16);
                send_matrix(16);
                trigger_compute();
                wait_for_mac_done();
            end
            begin
                axi_lite_item bad_item;
                repeat(20) begin
                    `uvm_do_on_with(bad_item, p_sequencer.axi_lite_sqr_h, {
                        addr inside {32'h08, 32'h0C, 32'hFF};
                        is_write == 1;
                    })
                end
            end
        join
        `uvm_info("TC3", "Invalid Address Isolation test complete.", UVM_LOW)
    endtask
endclass

// TC4: Asynchronous Spin-Polling Synchronization
class tc4_spin_poll_sync_vseq extends top_vseq_base;
    `uvm_object_utils(tc4_spin_poll_sync_vseq)
    function new(string name="tc4_spin_poll_sync_vseq"); super.new(name); endfunction
    
    task body();
        send_matrix(16);
        send_matrix(16);
        trigger_compute();
        wait_for_mac_done(); // Tight loop read of 0x04
        `uvm_info("TC4", "Spin-Polling Synchronization test complete.", UVM_LOW)
    endtask
endclass

// TC5: BIST Override Collision Protection
class tc5_bist_override_vseq extends top_vseq_base;
    `uvm_object_utils(tc5_bist_override_vseq)
    function new(string name="tc5_bist_override_vseq"); super.new(name); endfunction
    
    task body();
        bist_item b_item;
        axi_lite_item c_item;
        
        // Assert BIST start
        `uvm_do_on_with(b_item, p_sequencer.bist_sqr_h, { bist_start == 1; })
        
        // Concurrently attempt to trigger via AXI-Lite
        `uvm_do_on_with(c_item, p_sequencer.axi_lite_sqr_h, { addr == 0; data == 1; is_write == 1; })
        
        // Deassert BIST start
        `uvm_do_on_with(b_item, p_sequencer.bist_sqr_h, { bist_start == 0; })
        
        `uvm_info("TC5", "BIST Override Collision test complete.", UVM_LOW)
    endtask
endclass

`endif
