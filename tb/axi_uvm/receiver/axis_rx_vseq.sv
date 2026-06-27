`ifndef AXIS_RX_VSEQ_SV
`define AXIS_RX_VSEQ_SV

class axis_rx_base_vseq extends uvm_sequence;
    `uvm_object_utils(axis_rx_base_vseq)
    `uvm_declare_p_sequencer(axis_rx_vsequencer)

    function new(string name = "axis_rx_base_vseq");
        super.new(name);
    endfunction
endclass

// -------------------------------------------------------------------------
// TC1: Golden Smoke Test (Clean Egress to SRAM)
// -------------------------------------------------------------------------
class tc1_golden_smoke_vseq extends axis_rx_base_vseq;
    `uvm_object_utils(tc1_golden_smoke_vseq)

    function new(string name="tc1_golden_smoke_vseq"); super.new(name); endfunction

    virtual task body();
        axi_dma_seq_item axi_item;
        sram_out_seq_item sram_item;

        fork
            begin // SRAM: Permanent ready (no stall delay)
                repeat(20) begin
                    uvm_object tmp;
                    tmp = sram_out_seq_item::type_id::create("sram_item");
                    if (!$cast(sram_item, tmp)) `uvm_fatal("CASTFAIL", "Failed to cast sram_item")
                    start_item(sram_item, -1, p_sequencer.p_sram_out_seqr);
                    sram_item.stall_delay = 0;
                    finish_item(sram_item);
                end
            end
            begin // AXI: 16 clean rows
                for (int i=0; i<16; i++) begin
                    uvm_object tmp;
                    tmp = axi_dma_seq_item::type_id::create("axi_item");
                    if (!$cast(axi_item, tmp)) `uvm_fatal("CASTFAIL", "Failed to cast axi_item")
                    start_item(axi_item, -1, p_sequencer.p_axi_dma_seqr);
                    axi_item.tdata = {96'h0, 32'(i)};
                    axi_item.tlast = (i == 15) ? 1'b1 : 1'b0;
                    axi_item.valid_delay = 0;
                    finish_item(axi_item);
                end
            end
        join
    endtask
endclass

// -------------------------------------------------------------------------
// TC3: SRAM Backpressure (Skid Buffer Stress)
// -------------------------------------------------------------------------
class tc3_sram_backpressure_vseq extends axis_rx_base_vseq;
    `uvm_object_utils(tc3_sram_backpressure_vseq)

    function new(string name="tc3_sram_backpressure_vseq"); super.new(name); endfunction

    virtual task body();
        axi_dma_seq_item axi_item;
        sram_out_seq_item sram_item;

        fork
            begin // SRAM: Random pauses
                repeat(16) begin
                    uvm_object tmp;
                    tmp = sram_out_seq_item::type_id::create("sram_item");
                    if (!$cast(sram_item, tmp)) `uvm_fatal("CASTFAIL", "Failed to cast sram_item")
                    start_item(sram_item, -1, p_sequencer.p_sram_out_seqr);
                    assert(sram_item.randomize() with { stall_delay inside {[1:5]}; });
                    finish_item(sram_item);
                end
            end
            begin // AXI: Continuous stream
                for (int i=0; i<16; i++) begin
                    uvm_object tmp;
                    tmp = axi_dma_seq_item::type_id::create("axi_item");
                    if (!$cast(axi_item, tmp)) `uvm_fatal("CASTFAIL", "Failed to cast axi_item")
                    start_item(axi_item, -1, p_sequencer.p_axi_dma_seqr);
                    assert(axi_item.randomize() with { valid_delay == 0; });
                    axi_item.tlast = (i == 15) ? 1'b1 : 1'b0;
                    finish_item(axi_item);
                end
            end
        join
    endtask
endclass

// -------------------------------------------------------------------------
// TC5: Premature TLAST Injection
// -------------------------------------------------------------------------
class tc5_premature_tlast_vseq extends axis_rx_base_vseq;
    `uvm_object_utils(tc5_premature_tlast_vseq)

    function new(string name="tc5_premature_tlast_vseq"); super.new(name); endfunction

    virtual task body();
        axi_dma_seq_item axi_item;
        sram_out_seq_item sram_item;

        fork
            begin // SRAM: Permanent ready
                repeat(20) begin
                    uvm_object tmp;
                    tmp = sram_out_seq_item::type_id::create("sram_item");
                    if (!$cast(sram_item, tmp)) `uvm_fatal("CASTFAIL", "Failed to cast")
                    start_item(sram_item, -1, p_sequencer.p_sram_out_seqr);
                    sram_item.stall_delay = 0;
                    finish_item(sram_item);
                end
            end
            begin // AXI: tlast on 5th row
                for (int i=0; i<5; i++) begin
                    uvm_object tmp;
                    tmp = axi_dma_seq_item::type_id::create("axi_item");
                    if (!$cast(axi_item, tmp)) `uvm_fatal("CASTFAIL", "Failed to cast")
                    start_item(axi_item, -1, p_sequencer.p_axi_dma_seqr);
                    assert(axi_item.randomize() with { valid_delay == 0; });
                    axi_item.tlast = (i == 4) ? 1'b1 : 1'b0;
                    finish_item(axi_item);
                end
            end
        join
    endtask
endclass

// -------------------------------------------------------------------------
// TC6: Back to Back Matrices
// -------------------------------------------------------------------------
class tc6_back_to_back_vseq extends axis_rx_base_vseq;
    `uvm_object_utils(tc6_back_to_back_vseq)

    function new(string name="tc6_back_to_back_vseq"); super.new(name); endfunction

    virtual task body();
        axi_dma_seq_item axi_item;
        sram_out_seq_item sram_item;

        fork
            begin // SRAM: Permanent ready
                repeat(35) begin
                    uvm_object tmp;
                    tmp = sram_out_seq_item::type_id::create("sram_item");
                    if (!$cast(sram_item, tmp)) `uvm_fatal("CASTFAIL", "Failed to cast")
                    start_item(sram_item, -1, p_sequencer.p_sram_out_seqr);
                    sram_item.stall_delay = 0;
                    finish_item(sram_item);
                end
            end
            begin // AXI: 32 rows continuous
                for (int i=0; i<32; i++) begin
                    uvm_object tmp;
                    tmp = axi_dma_seq_item::type_id::create("axi_item");
                    if (!$cast(axi_item, tmp)) `uvm_fatal("CASTFAIL", "Failed to cast")
                    start_item(axi_item, -1, p_sequencer.p_axi_dma_seqr);
                    assert(axi_item.randomize() with { valid_delay == 0; });
                    axi_item.tlast = (i == 15 || i == 31) ? 1'b1 : 1'b0;
                    finish_item(axi_item);
                end
            end
        join
    endtask
endclass

// -------------------------------------------------------------------------
// TC7: Extreme Bounds Data Integrity
// -------------------------------------------------------------------------
class tc7_extreme_bounds_vseq extends axis_rx_base_vseq;
    `uvm_object_utils(tc7_extreme_bounds_vseq)

    function new(string name="tc7_extreme_bounds_vseq"); super.new(name); endfunction

    virtual task body();
        axi_dma_seq_item axi_item;
        sram_out_seq_item sram_item;

        fork
            begin // SRAM: No delay
                repeat(16) begin
                    uvm_object tmp;
                    tmp = sram_out_seq_item::type_id::create("sram_item");
                    if (!$cast(sram_item, tmp)) `uvm_fatal("CASTFAIL", "Failed to cast")
                    start_item(sram_item, -1, p_sequencer.p_sram_out_seqr);
                    sram_item.stall_delay = 0;
                    finish_item(sram_item);
                end
            end
            begin // AXI: Max and Min values (+127 / -128)
                for (int i=0; i<16; i++) begin
                    uvm_object tmp;
                    tmp = axi_dma_seq_item::type_id::create("axi_item");
                    if (!$cast(axi_item, tmp)) `uvm_fatal("CASTFAIL", "Failed to cast")
                    start_item(axi_item, -1, p_sequencer.p_axi_dma_seqr);
                    axi_item.tdata = (i%2 == 0) ? {16{8'h7F}} : {16{8'h80}};
                    axi_item.tlast = (i == 15) ? 1'b1 : 1'b0;
                    axi_item.valid_delay = 0;
                    finish_item(axi_item);
                end
            end
        join
    endtask
endclass

// -------------------------------------------------------------------------
// TC8: 1000-Cycle Hammer
// -------------------------------------------------------------------------
class tc8_1000_cycle_hammer_vseq extends axis_rx_base_vseq;
    `uvm_object_utils(tc8_1000_cycle_hammer_vseq)

    function new(string name="tc8_1000_cycle_hammer_vseq"); super.new(name); endfunction

    virtual task body();
        axi_dma_seq_item axi_item;
        sram_out_seq_item sram_item;

        fork
            begin // SRAM: Random Delays (50 matrices * 16 rows = 800)
                repeat(800) begin
                    uvm_object tmp;
                    tmp = sram_out_seq_item::type_id::create("sram_item");
                    if (!$cast(sram_item, tmp)) `uvm_fatal("CASTFAIL", "Failed to cast")
                    start_item(sram_item, -1, p_sequencer.p_sram_out_seqr);
                    assert(sram_item.randomize());
                    finish_item(sram_item);
                end
            end
            begin // AXI: Random Valid Delays
                for (int i=0; i<800; i++) begin
                    uvm_object tmp;
                    tmp = axi_dma_seq_item::type_id::create("axi_item");
                    if (!$cast(axi_item, tmp)) `uvm_fatal("CASTFAIL", "Failed to cast")
                    start_item(axi_item, -1, p_sequencer.p_axi_dma_seqr);
                    assert(axi_item.randomize());
                    axi_item.tlast = ((i+1)%16 == 0) ? 1'b1 : 1'b0;
                    finish_item(axi_item);
                end
            end
        join
    endtask
endclass

`endif
