class pe_test extends uvm_test;
    `uvm_component_utils(pe_test)
    pe_env env;
    function new(string name, uvm_component parent); super.new(name, parent); endfunction
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = pe_env::type_id::create("env", this);
    endfunction
    task run_phase(uvm_phase phase);
        phase.raise_objection(this);
        
        // Wait for initial hardware reset from tb_pe_uvm_top to complete
        #20;
        
        `uvm_info("TEST", "Running Throughput Sequence", UVM_LOW)
        create_and_start("throughput_seq");
        `uvm_info("TEST", "Running Stationary Sequence", UVM_LOW)
        create_and_start("stationary_seq");
        `uvm_info("TEST", "Running Bubble Sequence", UVM_LOW)
        create_and_start("bubble_seq");
        `uvm_info("TEST", "Running Booth Precision Sequence", UVM_LOW)
        create_and_start("booth_precision_seq");
        `uvm_info("TEST", "Running Bypass Sequence", UVM_LOW)
        create_and_start("bypass_seq");
        `uvm_info("TEST", "Running Accumulate Sequence", UVM_LOW)
        create_and_start("accum_seq");
        `uvm_info("TEST", "Running Identity Sequence", UVM_LOW)
        create_and_start("identity_seq");
        `uvm_info("TEST", "Running Bounds Sequence", UVM_LOW)
        create_and_start("bounds_seq");
        `uvm_info("TEST", "Running Wrap Sequence", UVM_LOW)
        create_and_start("wrap_seq");
        `uvm_info("TEST", "Running Toggle Sequence", UVM_LOW)
        create_and_start("toggle_seq");
        `uvm_info("TEST", "Running Reset Recovery Sequence", UVM_LOW)
        create_and_start("reset_recovery_seq");

        #200;
        phase.drop_objection(this);
    endtask
    
    task create_and_start(string seq_name);
        uvm_object obj = uvm_factory::get().create_object_by_name(seq_name);
        uvm_sequence_base seq;
        if (obj == null) begin
            `uvm_fatal("TEST", $sformatf("Could not create object for sequence: %s", seq_name))
        end
        if (!$cast(seq, obj)) begin
            `uvm_fatal("TEST", $sformatf("Failed to cast sequence: %s", seq_name))
        end
        seq.start(env.agent.seqr);
    endtask
endclass
