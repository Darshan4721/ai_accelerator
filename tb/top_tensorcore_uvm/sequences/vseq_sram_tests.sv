`ifndef VSEQ_SRAM_TESTS_SV
`define VSEQ_SRAM_TESTS_SV

// TC21: SRAM Ping-Pong Conflict Prevention
class tc21_sram_ping_pong_conflict_vseq extends top_vseq_base;
    `uvm_object_utils(tc21_sram_ping_pong_conflict_vseq)
    function new(string name="tc21_sram_ping_pong_conflict_vseq"); super.new(name); endfunction
    task body();
        send_matrix(16); send_matrix(16);
        trigger_compute();
        // FSM should block RX if ping-pong full
        send_matrix(16); send_matrix(16);
        wait_for_mac_done();
        `uvm_info("TC21", "SRAM Ping-Pong Conflict Prevention complete.", UVM_LOW)
    endtask
endclass

// TC22: SRAM Asymmetric Write/Read Bandwidth
class tc22_sram_asymmetric_bw_vseq extends top_vseq_base;
    `uvm_object_utils(tc22_sram_asymmetric_bw_vseq)
    function new(string name="tc22_sram_asymmetric_bw_vseq"); super.new(name); endfunction
    task body();
        axis_rx_item rx_item;
        for (int i=0; i<32; i++) begin
            `uvm_do_on_with(rx_item, p_sequencer.axis_rx_sqr_h, {
                tlast == (i == 15 || i == 31);
                delay == 15;
            })
        end
        trigger_compute();
        wait_for_mac_done();
        `uvm_info("TC22", "SRAM Asymmetric Bandwidth complete.", UVM_LOW)
    endtask
endclass

// TC23: Out-of-Bounds Address Forcing
class tc23_oob_addr_forcing_vseq extends top_vseq_base;
    `uvm_object_utils(tc23_oob_addr_forcing_vseq)
    function new(string name="tc23_oob_addr_forcing_vseq"); super.new(name); endfunction
    task body();
        send_matrix(40); // 40 > 32
        trigger_compute();
        wait_for_mac_done();
        `uvm_info("TC23", "Out-of-Bounds Address Forcing complete.", UVM_LOW)
    endtask
endclass

// TC24: Sustained Multi-Matrix Overwrite
class tc24_multi_matrix_overwrite_vseq extends top_vseq_base;
    `uvm_object_utils(tc24_multi_matrix_overwrite_vseq)
    function new(string name="tc24_multi_matrix_overwrite_vseq"); super.new(name); endfunction
    task body();
        send_matrix(16); send_matrix(16);
        send_matrix(16); send_matrix(16);
        send_matrix(16); send_matrix(16);
        trigger_compute();
        wait_for_mac_done();
        `uvm_info("TC24", "Sustained Multi-Matrix Overwrite complete.", UVM_LOW)
    endtask
endclass

// TC25: Dual-Port Coherency Verification
class tc25_dual_port_coherency_vseq extends top_vseq_base;
    `uvm_object_utils(tc25_dual_port_coherency_vseq)
    function new(string name="tc25_dual_port_coherency_vseq"); super.new(name); endfunction
    task body();
        send_matrix(16); send_matrix(16);
        trigger_compute();
        #10ns;
        // Concurrent write to opposite bank
        send_matrix(16); send_matrix(16);
        wait_for_mac_done();
        `uvm_info("TC25", "Dual-Port Coherency Verification complete.", UVM_LOW)
    endtask
endclass

`endif
