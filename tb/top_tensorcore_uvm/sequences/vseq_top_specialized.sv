`ifndef VSEQ_TOP_SPECIALIZED_SV
`define VSEQ_TOP_SPECIALIZED_SV

// TC36: BIST -> Compute -> BIST State Recovery
class tc36_bist_compute_bist_vseq extends top_vseq_base;
    `uvm_object_utils(tc36_bist_compute_bist_vseq)
    function new(string name="tc36_bist_compute_bist_vseq"); super.new(name); endfunction
    task body();
        bist_item b_item;
        `uvm_do_on_with(b_item, p_sequencer.bist_sqr_h, { bist_start == 1; })
        
        send_matrix(16); send_matrix(16);
        trigger_compute();
        wait_for_mac_done();
        
        `uvm_do_on_with(b_item, p_sequencer.bist_sqr_h, { bist_start == 1; })
        `uvm_info("TC36", "BIST-Compute-BIST Recovery complete.", UVM_LOW)
    endtask
endclass

// TC37: Asynchronous Traffic Jam
class tc37_async_traffic_jam_vseq extends top_vseq_base;
    `uvm_object_utils(tc37_async_traffic_jam_vseq)
    function new(string name="tc37_async_traffic_jam_vseq"); super.new(name); endfunction
    task body();
        fork
            begin
                axis_rx_item rx_item;
                for(int i=0; i<32; i++) `uvm_do_on_with(rx_item, p_sequencer.axis_rx_sqr_h, { tlast == (i==15||i==31); delay inside {[0:15]}; })
            end
            begin
                axis_tx_item tx_item;
                repeat(16) `uvm_do_on_with(tx_item, p_sequencer.axis_tx_sqr_h, { ready_delay inside {[0:15]}; })
            end
            begin
                axi_lite_item ctrl_item;
                repeat(30) `uvm_do_on_with(ctrl_item, p_sequencer.axi_lite_sqr_h, { addr == 32'h04; is_write == 0; })
            end
        join
        trigger_compute();
        wait_for_mac_done();
        `uvm_info("TC37", "Async Traffic Jam complete.", UVM_LOW)
    endtask
endclass

// TC38: Pipelined Start Compute Overlap
class tc38_compute_overlap_vseq extends top_vseq_base;
    `uvm_object_utils(tc38_compute_overlap_vseq)
    function new(string name="tc38_compute_overlap_vseq"); super.new(name); endfunction
    task body();
        send_matrix(16); send_matrix(16);
        trigger_compute();
        trigger_compute(); // Immediate re-trigger
        wait_for_mac_done();
        `uvm_info("TC38", "Compute Overlap test complete.", UVM_LOW)
    endtask
endclass

// TC39: Power-Virus Toggling
class tc39_power_virus_vseq extends top_vseq_base;
    `uvm_object_utils(tc39_power_virus_vseq)
    function new(string name="tc39_power_virus_vseq"); super.new(name); endfunction
    task body();
        axis_rx_item rx_item;
        for (int i=0; i<32; i++) begin
            `uvm_do_on_with(rx_item, p_sequencer.axis_rx_sqr_h, {
                tlast == (i == 15 || i == 31);
                tdata == (i % 2 == 0) ? 128'hFFFFFFFF_FFFFFFFF_FFFFFFFF_FFFFFFFF : 128'h00000000_00000000_00000000_00000000;
            })
        end
        trigger_compute();
        wait_for_mac_done();
        `uvm_info("TC39", "Power-Virus Toggling complete.", UVM_LOW)
    endtask
endclass

// TC40: Full System Hang Recovery
class tc40_hang_recovery_vseq extends top_vseq_base;
    `uvm_object_utils(tc40_hang_recovery_vseq)
    function new(string name="tc40_hang_recovery_vseq"); super.new(name); endfunction
    task body();
        trigger_compute(); // Start math with empty SRAM!
        #100ns;
        // Inject data late to recover
        send_matrix(16); send_matrix(16);
        trigger_compute();
        wait_for_mac_done();
        `uvm_info("TC40", "Hang Recovery complete.", UVM_LOW)
    endtask
endclass

// TC41: Illegal Protocol Sequences
class tc41_illegal_protocol_vseq extends top_vseq_base;
    `uvm_object_utils(tc41_illegal_protocol_vseq)
    function new(string name="tc41_illegal_protocol_vseq"); super.new(name); endfunction
    task body();
        axi_lite_item ctrl_item;
        repeat(5) `uvm_do_on_with(ctrl_item, p_sequencer.axi_lite_sqr_h, { addr == 0; data == 1; is_write == 1; })
        send_matrix(16); send_matrix(16);
        wait_for_mac_done();
        `uvm_info("TC41", "Illegal Protocol complete.", UVM_LOW)
    endtask
endclass

// TC42: Ultimate UVM Golden Sign-off
class tc42_ultimate_signoff_vseq extends top_vseq_base;
    `uvm_object_utils(tc42_ultimate_signoff_vseq)
    function new(string name="tc42_ultimate_signoff_vseq"); super.new(name); endfunction
    task body();
        repeat(10) begin
            `uvm_info("TC42", "Initiating parallel DMA and CPU polling...", UVM_LOW)
            
            // FIRE BOTH THREADS SIMULTANEOUSLY
            fork
                begin
                    // THREAD 1: The DMA Firehose (Data Plane)
                    // Blast the 16 rows of Weights, then 16 rows of Activations
                    send_matrix(16); 
                    send_matrix(16); 
                end
                begin
                    // THREAD 2: The Host CPU (Control Plane)
                    // Starts polling register 0x04 IMMEDIATELY while the DMA is streaming.
                    // As soon as the DMA finishes above, this will detect the pulse and trigger the array.
                    trigger_compute();
                end
            join
            
            // Wait for the hardware to finish the math
            wait_for_mac_done();
        end
        `uvm_info("TC42", "Ultimate Sign-off complete.", UVM_LOW)
    endtask
endclass

`endif
