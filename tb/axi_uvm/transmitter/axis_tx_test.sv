`ifndef AXIS_TX_TEST_SV
`define AXIS_TX_TEST_SV

// -------------------------------------------------------------------------
// BASE TEST
// -------------------------------------------------------------------------
class axis_tx_base_test extends uvm_test;
    `uvm_component_utils(axis_tx_base_test)

    axis_tx_env env;

    function new(string name = "axis_tx_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = axis_tx_env::type_id::create("env", this);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction
endclass

// -------------------------------------------------------------------------
// TC1 Test
// -------------------------------------------------------------------------
class tc1_test extends axis_tx_base_test;
    `uvm_component_utils(tc1_test)
    function new(string name="tc1_test", uvm_component parent=null); super.new(name, parent); endfunction

    virtual task run_phase(uvm_phase phase);
        tc1_clean_stream_vseq vseq = tc1_clean_stream_vseq::type_id::create("vseq");
        phase.raise_objection(this);
        #50ns; // Wait for reset to clear
        `uvm_info("TEST", "Running TC1...", UVM_LOW)
        vseq.start(env.vsqr);
        #100ns;
        phase.drop_objection(this);
    endtask
endclass

// -------------------------------------------------------------------------
// TC3 Test
// -------------------------------------------------------------------------
class tc3_test extends axis_tx_base_test;
    `uvm_component_utils(tc3_test)
    function new(string name="tc3_test", uvm_component parent=null); super.new(name, parent); endfunction

    virtual task run_phase(uvm_phase phase);
        tc3_dma_backpressure_vseq vseq = tc3_dma_backpressure_vseq::type_id::create("vseq");
        phase.raise_objection(this);
        #50ns; // Wait for reset to clear
        `uvm_info("TEST", "Running TC3...", UVM_LOW)
        vseq.start(env.vsqr);
        #100ns;
        phase.drop_objection(this);
    endtask
endclass

// -------------------------------------------------------------------------
// TC4 Test
// -------------------------------------------------------------------------
class tc4_test extends axis_tx_base_test;
    `uvm_component_utils(tc4_test)
    function new(string name="tc4_test", uvm_component parent=null); super.new(name, parent); endfunction

    virtual task run_phase(uvm_phase phase);
        tc4_unstoppable_drain_vseq vseq = tc4_unstoppable_drain_vseq::type_id::create("vseq");
        phase.raise_objection(this);
        #50ns; // Wait for reset to clear
        `uvm_info("TEST", "Running TC4...", UVM_LOW)
        vseq.start(env.vsqr);
        #100ns;
        phase.drop_objection(this);
    endtask
endclass

// -------------------------------------------------------------------------
// TC8 Test (Hammer)
// -------------------------------------------------------------------------
class tc8_test extends axis_tx_base_test;
    `uvm_component_utils(tc8_test)
    function new(string name="tc8_test", uvm_component parent=null); super.new(name, parent); endfunction

    virtual task run_phase(uvm_phase phase);
        tc8_1000_cycle_hammer_vseq vseq = tc8_1000_cycle_hammer_vseq::type_id::create("vseq");
        phase.raise_objection(this);
        #50ns; // Wait for reset to clear
        `uvm_info("TEST", "Running TC8...", UVM_LOW)
        vseq.start(env.vsqr);
        #1000ns;
        phase.drop_objection(this);
    endtask
endclass

`endif
