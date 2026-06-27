`ifndef AXI_LITE_VSEQ_SV
`define AXI_LITE_VSEQ_SV

class axi_lite_base_vseq extends uvm_sequence;
    `uvm_object_utils(axi_lite_base_vseq)
    `uvm_declare_p_sequencer(axi_lite_vsequencer)

    function new(string name = "axi_lite_base_vseq");
        super.new(name);
    endfunction
endclass

// TC1: Smoke Sequence
class tc1_smoke_vseq extends axi_lite_base_vseq;
    `uvm_object_utils(tc1_smoke_vseq)
    function new(string name="tc1_smoke_vseq"); super.new(name); endfunction

    virtual task body();
        axi_seq_item axi_req;
        core_ctrl_seq_item core_req;

        fork
            begin
                // Host CPU writes 0x00000001 to 0x00
                axi_req = axi_seq_item::type_id::create("axi_req");
                start_item(axi_req, -1, p_sequencer.p_axi_seqr);
                axi_req.addr = 32'h00;
                axi_req.data = 32'h0000_0001;
                axi_req.is_write = 1;
                axi_req.backpressure_delay = 0;
                finish_item(axi_req);

                // Then reads 0x04
                #100ns;
                axi_req = axi_seq_item::type_id::create("axi_req_read");
                start_item(axi_req, -1, p_sequencer.p_axi_seqr);
                axi_req.addr = 32'h04;
                axi_req.is_write = 0;
                axi_req.backpressure_delay = 0;
                finish_item(axi_req);
            end
            begin
                core_req = core_ctrl_seq_item::type_id::create("core_req");
                start_item(core_req, -1, p_sequencer.p_core_seqr);
                core_req.mac_done_delay = 20;
                finish_item(core_req);
            end
        join
    endtask
endclass

// TC2: Invalid Address Rejection (Anti-Lockup)
class tc2_invalid_addr_vseq extends axi_lite_base_vseq;
    `uvm_object_utils(tc2_invalid_addr_vseq)
    function new(string name="tc2_invalid_addr_vseq"); super.new(name); endfunction

    virtual task body();
        axi_seq_item axi_req;
        
        // Write to 0x08
        axi_req = axi_seq_item::type_id::create("axi_req");
        start_item(axi_req, -1, p_sequencer.p_axi_seqr);
        axi_req.addr = 32'h08;
        axi_req.data = 32'hFFFF_FFFF;
        axi_req.is_write = 1;
        axi_req.backpressure_delay = 0;
        finish_item(axi_req);

        #50ns;
        // Read from 0x0C
        axi_req = axi_seq_item::type_id::create("axi_req_read");
        start_item(axi_req, -1, p_sequencer.p_axi_seqr);
        axi_req.addr = 32'h0C;
        axi_req.is_write = 0;
        axi_req.backpressure_delay = 0;
        finish_item(axi_req);
    endtask
endclass

// TC3: Simultaneous R/W Deadlock Check
class tc3_simultaneous_rw_vseq extends axi_lite_base_vseq;
    `uvm_object_utils(tc3_simultaneous_rw_vseq)
    function new(string name="tc3_simultaneous_rw_vseq"); super.new(name); endfunction

    virtual task body();
        fork
            begin
                axi_seq_item axi_w = axi_seq_item::type_id::create("axi_w");
                start_item(axi_w, -1, p_sequencer.p_axi_seqr);
                axi_w.addr = 32'h00;
                axi_w.data = 32'h0000_0001;
                axi_w.is_write = 1;
                axi_w.backpressure_delay = 0;
                finish_item(axi_w);
            end
            begin
                axi_seq_item axi_r = axi_seq_item::type_id::create("axi_r");
                start_item(axi_r, -1, p_sequencer.p_axi_seqr);
                axi_r.addr = 32'h04;
                axi_r.is_write = 0;
                axi_r.backpressure_delay = 0;
                finish_item(axi_r);
            end
            begin
                core_ctrl_seq_item core_req = core_ctrl_seq_item::type_id::create("core_req");
                start_item(core_req, -1, p_sequencer.p_core_seqr);
                core_req.mac_done_delay = 10;
                finish_item(core_req);
            end
        join
    endtask
endclass

// TC4: Valid/Ready Handshake Drops (Backpressure)
class tc4_backpressure_vseq extends axi_lite_base_vseq;
    `uvm_object_utils(tc4_backpressure_vseq)
    function new(string name="tc4_backpressure_vseq"); super.new(name); endfunction

    virtual task body();
        axi_seq_item axi_req;
        
        // Write with 15 cycle BREADY stall
        axi_req = axi_seq_item::type_id::create("axi_req");
        start_item(axi_req, -1, p_sequencer.p_axi_seqr);
        axi_req.addr = 32'h00;
        axi_req.data = 32'h0000_0001;
        axi_req.is_write = 1;
        axi_req.backpressure_delay = 15;
        finish_item(axi_req);

        #50ns;
        // Read with 20 cycle RREADY stall
        axi_req = axi_seq_item::type_id::create("axi_req_read");
        start_item(axi_req, -1, p_sequencer.p_axi_seqr);
        axi_req.addr = 32'h04;
        axi_req.is_write = 0;
        axi_req.backpressure_delay = 20;
        finish_item(axi_req);
    endtask
endclass

// TC5: The Glitch-Free Trigger Check
class tc5_glitch_free_vseq extends axi_lite_base_vseq;
    `uvm_object_utils(tc5_glitch_free_vseq)
    function new(string name="tc5_glitch_free_vseq"); super.new(name); endfunction

    virtual task body();
        axi_seq_item axi_req;
        // Write to 0x00 but delay BREADY by 10 cycles. 
        // The SVA in interface checks that start_compute is exactly 1-cycle wide!
        axi_req = axi_seq_item::type_id::create("axi_req");
        start_item(axi_req, -1, p_sequencer.p_axi_seqr);
        axi_req.addr = 32'h00;
        axi_req.data = 32'h0000_0001;
        axi_req.is_write = 1;
        axi_req.backpressure_delay = 10;
        finish_item(axi_req);
    endtask
endclass

// TC6: 1000-Cycle Hammer
class tc6_1000_hammer_vseq extends axi_lite_base_vseq;
    `uvm_object_utils(tc6_1000_hammer_vseq)
    function new(string name="tc6_1000_hammer_vseq"); super.new(name); endfunction

    virtual task body();
        fork
            begin
                for (int i=0; i<100; i++) begin
                    axi_seq_item axi_req = axi_seq_item::type_id::create("axi_req");
                    start_item(axi_req, -1, p_sequencer.p_axi_seqr);
                    assert(axi_req.randomize());
                    // 20% of time unmapped addresses
                    if (i % 5 == 0) axi_req.addr = 32'h08; 
                    else axi_req.addr = (i%2==0) ? 32'h00 : 32'h04;
                    finish_item(axi_req);
                end
            end
            begin
                for (int j=0; j<50; j++) begin
                    core_ctrl_seq_item core_req = core_ctrl_seq_item::type_id::create("core_req");
                    start_item(core_req, -1, p_sequencer.p_core_seqr);
                    assert(core_req.randomize());
                    finish_item(core_req);
                end
            end
        join
    endtask
endclass

`endif
