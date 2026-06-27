`ifndef FSM_COVERAGE_SV
`define FSM_COVERAGE_SV

class fsm_coverage extends uvm_subscriber #(sram_dummy_seq_item);
    `uvm_component_utils(fsm_coverage)

    virtual fsm_ctrl_if vif;

    covergroup fsm_cg;
        option.per_instance = 1;
        
        // State transition coverage
        cp_state_transitions: coverpoint vif.current_state {
            bins idle_to_load = (0 => 1);
            bins load_to_compute = (1 => 2);
            bins compute_to_drain = (2 => 3);
            bins drain_to_idle = (3 => 0);
        }
    endgroup

    function new(string name = "fsm_coverage", uvm_component parent = null);
        super.new(name, parent);
        fsm_cg = new();
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual fsm_ctrl_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "virtual interface must be set for: vif")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            @(posedge vif.clk);
            fsm_cg.sample();
        end
    endtask
    
    // We must implement write() since we extend uvm_subscriber, but we do passive sampling above
    virtual function void write(sram_dummy_seq_item t);
    endfunction

endclass

`endif
