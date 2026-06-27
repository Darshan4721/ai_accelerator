`ifndef FSM_VSEQ_SV
`define FSM_VSEQ_SV

class fsm_base_vseq extends uvm_sequence;
    `uvm_object_utils(fsm_base_vseq)
    `uvm_declare_p_sequencer(fsm_vsequencer)

    function new(string name = "fsm_base_vseq");
        super.new(name);
    endfunction
endclass

// -------------------------------------------------------------------------
// TC1: Golden Smoke Test (The Perfect Matrix)
// -------------------------------------------------------------------------
class tc1_golden_smoke_vseq extends fsm_base_vseq;
    `uvm_object_utils(tc1_golden_smoke_vseq)

    function new(string name="tc1_golden_smoke_vseq"); super.new(name); endfunction

    virtual task body();
        host_ctrl_seq_item host_item;
        array_feedback_seq_item array_item;

        fork
            begin
                // Start compute after 5 cycles
                uvm_object tmp;
                tmp = host_ctrl_seq_item::type_id::create("host_item");
                if (!$cast(host_item, tmp)) `uvm_fatal("CAST", "Cast failed")
                start_item(host_item, -1, p_sequencer.p_host_seqr);
                host_item.delay_before_start = 5;
                finish_item(host_item);
            end
            begin
                // Array locks weights immediately (0 delay)
                uvm_object tmp;
                tmp = array_feedback_seq_item::type_id::create("array_item");
                if (!$cast(array_item, tmp)) `uvm_fatal("CAST", "Cast failed")
                start_item(array_item, -1, p_sequencer.p_array_seqr);
                array_item.weight_lock_delay = 0;
                finish_item(array_item);
            end
        join
    endtask
endclass

// -------------------------------------------------------------------------
// TC3: Synchronous Active-High Reset Interruption
// -------------------------------------------------------------------------
// This sequence will intentionally not finish normally since it triggers a hard reset.
// We handle the reset in the top testbench by forcing vif.rst.

// -------------------------------------------------------------------------
// TC4: Delayed Weight Lock (The Stall Test)
// -------------------------------------------------------------------------
class tc4_delayed_weight_lock_vseq extends fsm_base_vseq;
    `uvm_object_utils(tc4_delayed_weight_lock_vseq)

    function new(string name="tc4_delayed_weight_lock_vseq"); super.new(name); endfunction

    virtual task body();
        host_ctrl_seq_item host_item;
        array_feedback_seq_item array_item;

        fork
            begin
                uvm_object tmp;
                tmp = host_ctrl_seq_item::type_id::create("host_item");
                $cast(host_item, tmp);
                start_item(host_item, -1, p_sequencer.p_host_seqr);
                host_item.delay_before_start = 2;
                finish_item(host_item);
            end
            begin
                // Array takes 10 cycles to lock
                uvm_object tmp;
                tmp = array_feedback_seq_item::type_id::create("array_item");
                $cast(array_item, tmp);
                start_item(array_item, -1, p_sequencer.p_array_seqr);
                array_item.weight_lock_delay = 10;
                finish_item(array_item);
            end
        join
    endtask
endclass

// -------------------------------------------------------------------------
// TC5: Back-to-Back Compute (Zero-Idle Transition)
// -------------------------------------------------------------------------
class tc5_back_to_back_vseq extends fsm_base_vseq;
    `uvm_object_utils(tc5_back_to_back_vseq)

    function new(string name="tc5_back_to_back_vseq"); super.new(name); endfunction

    virtual task body();
        host_ctrl_seq_item host_item;
        array_feedback_seq_item array_item;

        for (int i=0; i<3; i++) begin
            fork
                begin
                    uvm_object tmp;
                    tmp = host_ctrl_seq_item::type_id::create("host_item");
                    $cast(host_item, tmp);
                    start_item(host_item, -1, p_sequencer.p_host_seqr);
                    host_item.delay_before_start = (i == 0) ? 5 : 0; // Back to back!
                    finish_item(host_item);
                end
                begin
                    uvm_object tmp;
                    tmp = array_feedback_seq_item::type_id::create("array_item");
                    $cast(array_item, tmp);
                    start_item(array_item, -1, p_sequencer.p_array_seqr);
                    array_item.weight_lock_delay = 0;
                    finish_item(array_item);
                end
            join
        end
    endtask
endclass

// -------------------------------------------------------------------------
// TC6: 1000-Cycle Hammer
// -------------------------------------------------------------------------
class tc6_1000_cycle_hammer_vseq extends fsm_base_vseq;
    `uvm_object_utils(tc6_1000_cycle_hammer_vseq)

    function new(string name="tc6_1000_cycle_hammer_vseq"); super.new(name); endfunction

    virtual task body();
        host_ctrl_seq_item host_item;
        array_feedback_seq_item array_item;

        for (int i=0; i<25; i++) begin
            fork
                begin
                    uvm_object tmp;
                    tmp = host_ctrl_seq_item::type_id::create("host_item");
                    $cast(host_item, tmp);
                    start_item(host_item, -1, p_sequencer.p_host_seqr);
                    assert(host_item.randomize());
                    finish_item(host_item);
                end
                begin
                    uvm_object tmp;
                    tmp = array_feedback_seq_item::type_id::create("array_item");
                    $cast(array_item, tmp);
                    start_item(array_item, -1, p_sequencer.p_array_seqr);
                    assert(array_item.randomize());
                    finish_item(array_item);
                end
            join
        end
    endtask
endclass

`endif
