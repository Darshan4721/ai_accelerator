`ifndef FSM_SCOREBOARD_SV
`define FSM_SCOREBOARD_SV

`uvm_analysis_imp_decl(_host)
`uvm_analysis_imp_decl(_array)
`uvm_analysis_imp_decl(_sram)

class fsm_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(fsm_scoreboard)

    uvm_analysis_imp_host  #(host_ctrl_seq_item, fsm_scoreboard) host_export;
    uvm_analysis_imp_array #(array_feedback_seq_item, fsm_scoreboard) array_export;
    uvm_analysis_imp_sram  #(sram_dummy_seq_item, fsm_scoreboard) sram_export;

    // Golden state tracking
    int expected_addr;
    bit sweeping_weights;
    bit sweeping_activations;

    function new(string name = "fsm_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        host_export  = new("host_export", this);
        array_export = new("array_export", this);
        sram_export  = new("sram_export", this);
        
        expected_addr = 0;
        sweeping_weights = 0;
        sweeping_activations = 0;
    endfunction

    virtual function void write_host(host_ctrl_seq_item item);
        // The host monitor sends an item when start_compute pulses or mac_done pulses
        // We could verify timing here if needed
        `uvm_info("SCB_HOST", "Received Host Control Event.", UVM_HIGH)
    endfunction

    virtual function void write_array(array_feedback_seq_item item);
        // Array monitor sends item on load or compute valid
        `uvm_info("SCB_ARRAY", "Received Array Feedback Event.", UVM_HIGH)
    endfunction

    virtual function void write_sram(sram_dummy_seq_item item);
        // SRAM monitor sends item when sram_re == 1
        if (item.sram_re) begin
            if (item.sram_r_addr != expected_addr) begin
                `uvm_error("SCB_FAIL", $sformatf("Address mismatch! Expected: %0d, Actual: %0d", expected_addr, item.sram_r_addr))
            end else begin
                `uvm_info("SCB_PASS", $sformatf("SRAM Address %0d requested perfectly.", item.sram_r_addr), UVM_HIGH)
            end
            
            if (expected_addr == 15) begin
                // Weight sweep done. The FSM should pause and wait for weight lock, then start at 16.
                expected_addr = 16;
            end else if (expected_addr == 31) begin
                // Activation sweep done.
                expected_addr = 0;
            end else begin
                expected_addr++;
            end
        end
    endfunction

endclass

`endif
