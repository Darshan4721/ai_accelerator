`ifndef AXIS_TX_VSEQ_SV
`define AXIS_TX_VSEQ_SV

class axis_tx_base_vseq extends uvm_sequence;
    `uvm_object_utils(axis_tx_base_vseq)
    `uvm_declare_p_sequencer(axis_tx_vsequencer)

    function new(string name = "axis_tx_base_vseq");
        super.new(name);
    endfunction
endclass

// -------------------------------------------------------------------------
// TC1: Clean Stream
// -------------------------------------------------------------------------
class tc1_clean_stream_vseq extends axis_tx_base_vseq;
    `uvm_object_utils(tc1_clean_stream_vseq)

    function new(string name="tc1_clean_stream_vseq"); super.new(name); endfunction

    virtual task body();
        sys_tx_seq_item sys_item;
        axi_rx_seq_item axi_item;

        fork
            begin // AXI: Permanent ready
                repeat(20) begin
                    axi_item = axi_rx_seq_item::type_id::create("axi_item");
                    start_item(axi_item, -1, p_sequencer.p_axi_rx_seqr);
                    axi_item.tready_delay = 0;
                    finish_item(axi_item);
                end
            end
            begin // Systolic: 16 clean rows
                for (int i=0; i<16; i++) begin
                    sys_item = sys_tx_seq_item::type_id::create("sys_item");
                    start_item(sys_item, -1, p_sequencer.p_sys_tx_seqr);
                    sys_item.psum_row = {480'h0, 32'(i)};
                    sys_item.delay_cycles = 0;
                    finish_item(sys_item);
                end
            end
        join
    endtask
endclass

// -------------------------------------------------------------------------
// TC2: Reset Polarity Translation (To be handled mostly in top env/test)
// -------------------------------------------------------------------------
// -------------------------------------------------------------------------
// TC3: DMA Backpressure (SVA Stability)
// -------------------------------------------------------------------------
class tc3_dma_backpressure_vseq extends axis_tx_base_vseq;
    `uvm_object_utils(tc3_dma_backpressure_vseq)

    function new(string name="tc3_dma_backpressure_vseq"); super.new(name); endfunction

    virtual task body();
        sys_tx_seq_item sys_item;
        axi_rx_seq_item axi_item;

        fork
            begin // AXI: Random stalls inside {1, 5}
                repeat(16) begin
                    axi_item = axi_rx_seq_item::type_id::create("axi_item");
                    start_item(axi_item, -1, p_sequencer.p_axi_rx_seqr);
                    assert(axi_item.randomize() with { tready_delay inside {[1:5]}; });
                    finish_item(axi_item);
                end
            end
            begin // Systolic: Send rows
                for (int i=0; i<16; i++) begin
                    sys_item = sys_tx_seq_item::type_id::create("sys_item");
                    start_item(sys_item, -1, p_sequencer.p_sys_tx_seqr);
                    assert(sys_item.randomize() with { delay_cycles == 0; });
                    finish_item(sys_item);
                end
            end
        join
    endtask
endclass

// -------------------------------------------------------------------------
// TC4: Unstoppable Drain (FIFO Stress)
// -------------------------------------------------------------------------
class tc4_unstoppable_drain_vseq extends axis_tx_base_vseq;
    `uvm_object_utils(tc4_unstoppable_drain_vseq)

    function new(string name="tc4_unstoppable_drain_vseq"); super.new(name); endfunction

    virtual task body();
        sys_tx_seq_item sys_item;
        axi_rx_seq_item axi_item;

        fork
            begin // AXI: Force stall for 20 cycles, then accept 16
                axi_item = axi_rx_seq_item::type_id::create("axi_item");
                start_item(axi_item, -1, p_sequencer.p_axi_rx_seqr);
                axi_item.tready_delay = 20;
                finish_item(axi_item);
                
                repeat(16) begin
                    axi_item = axi_rx_seq_item::type_id::create("axi_item");
                    start_item(axi_item, -1, p_sequencer.p_axi_rx_seqr);
                    axi_item.tready_delay = 0;
                    finish_item(axi_item);
                end
            end
            begin // Systolic: Blast 16 rows
                for (int i=0; i<16; i++) begin
                    sys_item = sys_tx_seq_item::type_id::create("sys_item");
                    start_item(sys_item, -1, p_sequencer.p_sys_tx_seqr);
                    sys_item.psum_row = $urandom();
                    sys_item.delay_cycles = 0;
                    finish_item(sys_item);
                end
            end
        join
    endtask
endclass

// -------------------------------------------------------------------------
// TC5: Disconnected Valid
// -------------------------------------------------------------------------
class tc5_disconnected_valid_vseq extends axis_tx_base_vseq;
    `uvm_object_utils(tc5_disconnected_valid_vseq)

    function new(string name="tc5_disconnected_valid_vseq"); super.new(name); endfunction

    virtual task body();
        sys_tx_seq_item sys_item;
        axi_rx_seq_item axi_item;

        fork
            begin // AXI: Permanent Stall
                axi_item = axi_rx_seq_item::type_id::create("axi_item");
                start_item(axi_item, -1, p_sequencer.p_axi_rx_seqr);
                axi_item.tready_delay = 50;
                finish_item(axi_item);
            end
            begin // Systolic: 1 row
                sys_item = sys_tx_seq_item::type_id::create("sys_item");
                start_item(sys_item, -1, p_sequencer.p_sys_tx_seqr);
                sys_item.delay_cycles = 0;
                finish_item(sys_item);
            end
        join_any
    endtask
endclass

// -------------------------------------------------------------------------
// TC6: TLAST Wrap Boundary
// -------------------------------------------------------------------------
class tc6_tlast_wrap_boundary_vseq extends axis_tx_base_vseq;
    `uvm_object_utils(tc6_tlast_wrap_boundary_vseq)

    function new(string name="tc6_tlast_wrap_boundary_vseq"); super.new(name); endfunction

    virtual task body();
        sys_tx_seq_item sys_item;
        axi_rx_seq_item axi_item;

        fork
            begin // AXI: Random stalls
                repeat(32) begin
                    axi_item = axi_rx_seq_item::type_id::create("axi_item");
                    start_item(axi_item, -1, p_sequencer.p_axi_rx_seqr);
                    assert(axi_item.randomize());
                    finish_item(axi_item);
                end
            end
            begin // Systolic: exactly 32 rows
                for (int i=0; i<32; i++) begin
                    sys_item = sys_tx_seq_item::type_id::create("sys_item");
                    start_item(sys_item, -1, p_sequencer.p_sys_tx_seqr);
                    sys_item.delay_cycles = 0;
                    finish_item(sys_item);
                end
            end
        join
    endtask
endclass

// -------------------------------------------------------------------------
// TC7: Extreme Bounds
// -------------------------------------------------------------------------
class tc7_extreme_bounds_vseq extends axis_tx_base_vseq;
    `uvm_object_utils(tc7_extreme_bounds_vseq)

    function new(string name="tc7_extreme_bounds_vseq"); super.new(name); endfunction

    virtual task body();
        sys_tx_seq_item sys_item;
        axi_rx_seq_item axi_item;
        logic [31:0] max_int = 32'h7FFFFFFF;
        logic [31:0] min_int = 32'h80000000;

        fork
            begin // AXI: 0 delay
                repeat(16) begin
                    axi_item = axi_rx_seq_item::type_id::create("axi_item");
                    start_item(axi_item, -1, p_sequencer.p_axi_rx_seqr);
                    axi_item.tready_delay = 0;
                    finish_item(axi_item);
                end
            end
            begin // Systolic: Extreme rows
                for (int i=0; i<16; i++) begin
                    sys_item = sys_tx_seq_item::type_id::create("sys_item");
                    start_item(sys_item, -1, p_sequencer.p_sys_tx_seqr);
                    sys_item.psum_row = (i%2 == 0) ? {16{max_int}} : {16{min_int}};
                    sys_item.delay_cycles = 0;
                    finish_item(sys_item);
                end
            end
        join
    endtask
endclass

// -------------------------------------------------------------------------
// TC8: 1000-Cycle Hammer
// -------------------------------------------------------------------------
class tc8_1000_cycle_hammer_vseq extends axis_tx_base_vseq;
    `uvm_object_utils(tc8_1000_cycle_hammer_vseq)

    function new(string name="tc8_1000_cycle_hammer_vseq"); super.new(name); endfunction

    virtual task body();
        sys_tx_seq_item sys_item;
        axi_rx_seq_item axi_item;

        fork
            begin // AXI: 50x16 = 800 handshakes
                repeat(800) begin
                    axi_item = axi_rx_seq_item::type_id::create("axi_item");
                    start_item(axi_item, -1, p_sequencer.p_axi_rx_seqr);
                    assert(axi_item.randomize());
                    finish_item(axi_item);
                end
            end
            begin // Systolic: 800 rows with unconstrained delay
                for (int i=0; i<800; i++) begin
                    sys_item = sys_tx_seq_item::type_id::create("sys_item");
                    start_item(sys_item, -1, p_sequencer.p_sys_tx_seqr);
                    assert(sys_item.randomize());
                    finish_item(sys_item);
                end
            end
        join
    endtask
endclass

`endif
