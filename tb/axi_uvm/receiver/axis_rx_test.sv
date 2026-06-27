`ifndef AXIS_RX_TEST_SV
`define AXIS_RX_TEST_SV

// -------------------------------------------------------------------------
// BASE TEST
// -------------------------------------------------------------------------
class axis_rx_base_test extends uvm_test;
    `uvm_component_utils(axis_rx_base_test)

    axis_rx_env env;

    function new(string name = "axis_rx_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = axis_rx_env::type_id::create("env", this);
    endfunction

    virtual function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction
endclass

// -------------------------------------------------------------------------
// TC1 Test
// -------------------------------------------------------------------------
class tc1_test extends axis_rx_base_test;
    `uvm_component_utils(tc1_test)
    function new(string name="tc1_test", uvm_component parent=null); super.new(name, parent); endfunction

    virtual task run_phase(uvm_phase phase);
        tc1_golden_smoke_vseq vseq;
        uvm_object tmp;
        
        tmp = tc1_golden_smoke_vseq::type_id::create("vseq");
        if (!$cast(vseq, tmp)) `uvm_fatal("CASTFAIL", "Failed to cast vseq")
        
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
class tc3_test extends axis_rx_base_test;
    `uvm_component_utils(tc3_test)
    function new(string name="tc3_test", uvm_component parent=null); super.new(name, parent); endfunction

    virtual task run_phase(uvm_phase phase);
        tc3_sram_backpressure_vseq vseq;
        uvm_object tmp;
        
        tmp = tc3_sram_backpressure_vseq::type_id::create("vseq");
        if (!$cast(vseq, tmp)) `uvm_fatal("CASTFAIL", "Failed to cast vseq")
        
        phase.raise_objection(this);
        #50ns; // Wait for reset to clear
        `uvm_info("TEST", "Running TC3...", UVM_LOW)
        vseq.start(env.vsqr);
        #100ns;
        phase.drop_objection(this);
    endtask
endclass

// -------------------------------------------------------------------------
// TC6 Test
// -------------------------------------------------------------------------
class tc6_test extends axis_rx_base_test;
    `uvm_component_utils(tc6_test)
    function new(string name="tc6_test", uvm_component parent=null); super.new(name, parent); endfunction

    virtual task run_phase(uvm_phase phase);
        tc6_back_to_back_vseq vseq;
        uvm_object tmp;
        
        tmp = tc6_back_to_back_vseq::type_id::create("vseq");
        if (!$cast(vseq, tmp)) `uvm_fatal("CASTFAIL", "Failed to cast vseq")
        
        phase.raise_objection(this);
        #50ns; // Wait for reset to clear
        `uvm_info("TEST", "Running TC6...", UVM_LOW)
        vseq.start(env.vsqr);
        #100ns;
        phase.drop_objection(this);
    endtask
endclass

// -------------------------------------------------------------------------
// TC8 Test (Hammer)
// -------------------------------------------------------------------------
class tc8_test extends axis_rx_base_test;
    `uvm_component_utils(tc8_test)
    function new(string name="tc8_test", uvm_component parent=null); super.new(name, parent); endfunction

    virtual task run_phase(uvm_phase phase);
        tc8_1000_cycle_hammer_vseq vseq;
        uvm_object tmp;
        
        tmp = tc8_1000_cycle_hammer_vseq::type_id::create("vseq");
        if (!$cast(vseq, tmp)) `uvm_fatal("CASTFAIL", "Failed to cast vseq")
        
        phase.raise_objection(this);
        #50ns; // Wait for reset to clear
        `uvm_info("TEST", "Running TC8...", UVM_LOW)
        vseq.start(env.vsqr);
        #1000ns;
        phase.drop_objection(this);
    endtask
endclass

`endif
