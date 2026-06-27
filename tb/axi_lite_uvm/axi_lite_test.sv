`ifndef AXI_LITE_TEST_SV
`define AXI_LITE_TEST_SV

class axi_lite_base_test extends uvm_test;
    `uvm_component_utils(axi_lite_base_test)

    axi_lite_env env;

    function new(string name = "axi_lite_base_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = axi_lite_env::type_id::create("env", this);
    endfunction
endclass

class tc1_test extends axi_lite_base_test;
    `uvm_component_utils(tc1_test)
    function new(string name="tc1_test", uvm_component parent=null); super.new(name,parent); endfunction

    virtual task run_phase(uvm_phase phase);
        tc1_smoke_vseq vseq;
        phase.raise_objection(this);
        #50ns; // Wait for reset to clear perfectly!
        `uvm_info("TEST", "Running TC1...", UVM_LOW)
        vseq = tc1_smoke_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        #100ns;
        phase.drop_objection(this);
    endtask
endclass

class tc2_test extends axi_lite_base_test;
    `uvm_component_utils(tc2_test)
    function new(string name="tc2_test", uvm_component parent=null); super.new(name,parent); endfunction

    virtual task run_phase(uvm_phase phase);
        tc2_invalid_addr_vseq vseq;
        phase.raise_objection(this);
        #50ns;
        `uvm_info("TEST", "Running TC2 (Invalid Address Anti-Lockup)...", UVM_LOW)
        vseq = tc2_invalid_addr_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        #100ns;
        phase.drop_objection(this);
    endtask
endclass

class tc3_test extends axi_lite_base_test;
    `uvm_component_utils(tc3_test)
    function new(string name="tc3_test", uvm_component parent=null); super.new(name,parent); endfunction

    virtual task run_phase(uvm_phase phase);
        tc3_simultaneous_rw_vseq vseq;
        phase.raise_objection(this);
        #50ns;
        `uvm_info("TEST", "Running TC3...", UVM_LOW)
        vseq = tc3_simultaneous_rw_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        #100ns;
        phase.drop_objection(this);
    endtask
endclass

class tc4_test extends axi_lite_base_test;
    `uvm_component_utils(tc4_test)
    function new(string name="tc4_test", uvm_component parent=null); super.new(name,parent); endfunction

    virtual task run_phase(uvm_phase phase);
        tc4_backpressure_vseq vseq;
        phase.raise_objection(this);
        #50ns;
        `uvm_info("TEST", "Running TC4 (Backpressure Valid/Ready Drops)...", UVM_LOW)
        vseq = tc4_backpressure_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        #100ns;
        phase.drop_objection(this);
    endtask
endclass

class tc5_test extends axi_lite_base_test;
    `uvm_component_utils(tc5_test)
    function new(string name="tc5_test", uvm_component parent=null); super.new(name,parent); endfunction

    virtual task run_phase(uvm_phase phase);
        tc5_glitch_free_vseq vseq;
        phase.raise_objection(this);
        #50ns;
        `uvm_info("TEST", "Running TC5 (Glitch-Free 1-Cycle Trigger)...", UVM_LOW)
        vseq = tc5_glitch_free_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        #100ns;
        phase.drop_objection(this);
    endtask
endclass

class tc6_test extends axi_lite_base_test;
    `uvm_component_utils(tc6_test)
    function new(string name="tc6_test", uvm_component parent=null); super.new(name,parent); endfunction

    virtual task run_phase(uvm_phase phase);
        tc6_1000_hammer_vseq vseq;
        phase.raise_objection(this);
        #50ns;
        `uvm_info("TEST", "Running TC6...", UVM_LOW)
        vseq = tc6_1000_hammer_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        #100ns;
        phase.drop_objection(this);
    endtask
endclass

class tc_all_test extends axi_lite_base_test;
    `uvm_component_utils(tc_all_test)
    function new(string name="tc_all_test", uvm_component parent=null); super.new(name,parent); endfunction

    virtual task run_phase(uvm_phase phase);
        tc1_smoke_vseq vseq1;
        tc2_invalid_addr_vseq vseq2;
        tc3_simultaneous_rw_vseq vseq3;
        tc4_backpressure_vseq vseq4;
        tc5_glitch_free_vseq vseq5;
        tc6_1000_hammer_vseq vseq6;

        phase.raise_objection(this);
        #50ns;
        
        `uvm_info("TEST", "========== RUNNING TC1 (SMOKE) ==========", UVM_LOW)
        vseq1 = tc1_smoke_vseq::type_id::create("vseq1");
        vseq1.start(env.vsqr);
        #100ns;

        `uvm_info("TEST", "========== RUNNING TC2 (INVALID ADDR) ==========", UVM_LOW)
        vseq2 = tc2_invalid_addr_vseq::type_id::create("vseq2");
        vseq2.start(env.vsqr);
        #100ns;

        `uvm_info("TEST", "========== RUNNING TC3 (SIMULTANEOUS R/W) ==========", UVM_LOW)
        vseq3 = tc3_simultaneous_rw_vseq::type_id::create("vseq3");
        vseq3.start(env.vsqr);
        #100ns;

        `uvm_info("TEST", "========== RUNNING TC4 (BACKPRESSURE) ==========", UVM_LOW)
        vseq4 = tc4_backpressure_vseq::type_id::create("vseq4");
        vseq4.start(env.vsqr);
        #100ns;

        `uvm_info("TEST", "========== RUNNING TC5 (GLITCH FREE) ==========", UVM_LOW)
        vseq5 = tc5_glitch_free_vseq::type_id::create("vseq5");
        vseq5.start(env.vsqr);
        #100ns;

        `uvm_info("TEST", "========== RUNNING TC6 (1000-CYCLE HAMMER) ==========", UVM_LOW)
        vseq6 = tc6_1000_hammer_vseq::type_id::create("vseq6");
        vseq6.start(env.vsqr);
        #100ns;

        `uvm_info("TEST", "========== ALL TESTS COMPLETED SUCCESSFULLY ==========", UVM_LOW)
        phase.drop_objection(this);
    endtask
endclass

`endif
