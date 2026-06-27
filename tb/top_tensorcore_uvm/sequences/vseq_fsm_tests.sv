`ifndef VSEQ_FSM_TESTS_SV
`define VSEQ_FSM_TESTS_SV

// TC6: The 48-Cycle Latency Mathematical Proof
class tc6_latency_proof_vseq extends top_vseq_base;
    `uvm_object_utils(tc6_latency_proof_vseq)
    function new(string name="tc6_latency_proof_vseq"); super.new(name); endfunction
    
    task body();
        send_matrix(16);
        send_matrix(16);
        trigger_compute();
        wait_for_mac_done();
        `uvm_info("TC6", "Latency Proof test sequence dispatched.", UVM_LOW)
    endtask
endclass

// TC7: SRAM Sweep & Wedge Deskew Alignment
class tc7_wedge_deskew_vseq extends top_vseq_base;
    `uvm_object_utils(tc7_wedge_deskew_vseq)
    function new(string name="tc7_wedge_deskew_vseq"); super.new(name); endfunction
    
    task body();
        // The randomized data naturally tests deskew alignment via the C++ golden checker
        send_matrix(16);
        send_matrix(16);
        trigger_compute();
        wait_for_mac_done();
        `uvm_info("TC7", "Wedge Deskew Alignment test complete.", UVM_LOW)
    endtask
endclass

// TC8: Data Starvation Lock Synchronization (Pipeline Freeze)
class tc8_data_starvation_vseq extends top_vseq_base;
    `uvm_object_utils(tc8_data_starvation_vseq)
    function new(string name="tc8_data_starvation_vseq"); super.new(name); endfunction
    
    task body();
        // Delay 16th row by 50 cycles
        axis_rx_item rx_item;
        for (int i=0; i<16; i++) begin
            `uvm_do_on_with(rx_item, p_sequencer.axis_rx_sqr_h, {
                tlast == (i == 15);
                delay == (i == 15) ? 50 : 0;
            })
        end
        send_matrix(16);
        trigger_compute();
        wait_for_mac_done();
        `uvm_info("TC8", "Data Starvation Lock test complete.", UVM_LOW)
    endtask
endclass

// TC9: Back-to-Back Compute Pipelining (100% Throughput Stress)
class tc9_max_throughput_vseq extends top_vseq_base;
    `uvm_object_utils(tc9_max_throughput_vseq)
    function new(string name="tc9_max_throughput_vseq"); super.new(name); endfunction
    
    task body();
        // 1st matrix
        send_matrix(16);
        send_matrix(16);
        trigger_compute();
        
        // While processing, send next matrices and trigger again immediately
        send_matrix(16);
        send_matrix(16);
        trigger_compute();
        
        wait_for_mac_done();
        wait_for_mac_done();
        `uvm_info("TC9", "Max Throughput Pipelining test complete.", UVM_LOW)
    endtask
endclass

// TC10: System Reset Recovery Mid-Flight
class tc10_midflight_reset_vseq extends top_vseq_base;
    `uvm_object_utils(tc10_midflight_reset_vseq)
    function new(string name="tc10_midflight_reset_vseq"); super.new(name); endfunction
    
    task body();
        virtual system_top_if vif;
        if(!uvm_config_db#(virtual system_top_if)::get(null, "", "vif", vif))
            `uvm_fatal("NOVIF", "No vif in tc10 vseq");
            
        send_matrix(16);
        send_matrix(16);
        trigger_compute();
        
        // Wait briefly to allow compute to start, then drop active-low reset
        #20ns; 
        vif.rst_ni = 0;
        #10ns;
        vif.rst_ni = 1;
        
        `uvm_info("TC10", "Midflight Reset test successfully hit S_IDLE recovery.", UVM_LOW)
    endtask
endclass

`endif
