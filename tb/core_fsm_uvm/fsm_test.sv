`ifndef FSM_TEST_SV
`define FSM_TEST_SV

class fsm_base_test extends uvm_test;
    `uvm_component_utils(fsm_base_test)

    fsm_env env;

    function new(string name = "fsm_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = fsm_env::type_id::create("env", this);
    endfunction
endclass

class tc1_test extends fsm_base_test;
    `uvm_component_utils(tc1_test)
    function new(string name="tc1_test", uvm_component parent=null); super.new(name,parent); endfunction

    virtual task run_phase(uvm_phase phase);
        tc1_golden_smoke_vseq vseq;
        phase.raise_objection(this);
        #50ns; // Wait for reset to clear perfectly!
        `uvm_info("TEST", "Running TC1...", UVM_LOW)
        vseq = tc1_golden_smoke_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        #100ns;
        phase.drop_objection(this);
    endtask
endclass

class tc4_test extends fsm_base_test;
    `uvm_component_utils(tc4_test)
    function new(string name="tc4_test", uvm_component parent=null); super.new(name,parent); endfunction

    virtual task run_phase(uvm_phase phase);
        tc4_delayed_weight_lock_vseq vseq;
        phase.raise_objection(this);
        #50ns;
        `uvm_info("TEST", "Running TC4...", UVM_LOW)
        vseq = tc4_delayed_weight_lock_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        #100ns;
        phase.drop_objection(this);
    endtask
endclass

class tc5_test extends fsm_base_test;
    `uvm_component_utils(tc5_test)
    function new(string name="tc5_test", uvm_component parent=null); super.new(name,parent); endfunction

    virtual task run_phase(uvm_phase phase);
        tc5_back_to_back_vseq vseq;
        phase.raise_objection(this);
        #50ns;
        `uvm_info("TEST", "Running TC5...", UVM_LOW)
        vseq = tc5_back_to_back_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        #100ns;
        phase.drop_objection(this);
    endtask
endclass

class tc6_test extends fsm_base_test;
    `uvm_component_utils(tc6_test)
    function new(string name="tc6_test", uvm_component parent=null); super.new(name,parent); endfunction

    virtual task run_phase(uvm_phase phase);
        tc6_1000_cycle_hammer_vseq vseq;
        phase.raise_objection(this);
        #50ns;
        `uvm_info("TEST", "Running TC6...", UVM_LOW)
        vseq = tc6_1000_cycle_hammer_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        #100ns;
        phase.drop_objection(this);
    endtask
endclass

`endif
