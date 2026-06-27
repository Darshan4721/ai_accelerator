class systolic_test extends uvm_test;
    `uvm_component_utils(systolic_test)
    systolic_env env;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = systolic_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        uvm_sequence_base seq;
        string seq_name = "stress_1000_seq"; // Default sequence
        
        phase.raise_objection(this);
        
        // Allow command line override: +SEQ_NAME=smoke_seq
        $value$plusargs("SEQ_NAME=%s", seq_name);
        
        begin
            uvm_object obj = uvm_factory::get().create_object_by_name(seq_name);
            if (obj == null || !$cast(seq, obj)) begin
                `uvm_error("TEST", $sformatf("Failed to create sequence: %s", seq_name))
                seq = stress_1000_seq::type_id::create("stress_1000_seq");
            end
        end
        
        `uvm_info("TEST", $sformatf("Starting sequence: %s", seq.get_name()), UVM_NONE)
        seq.start(env.agent.seqr);
        
        // Wait for pipeline to flush
        #2000ns;
        phase.drop_objection(this);
    endtask
endclass
