class pe_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(pe_scoreboard)
    uvm_analysis_imp #(pe_seq_item, pe_scoreboard) ap_imp;

    function new(string name, uvm_component parent); super.new(name, parent); endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap_imp = new("ap_imp", this);
    endfunction

    function void write(pe_seq_item item);
        int expected_psum = ($signed(item.w_val) * $signed(item.a_val[0])) + item.psum_val[0];
        
        if(expected_psum == item.dut_psum) begin
            `uvm_info("SCBD_PASS", $sformatf("W:%0d A:%0d PIn:%0d | POut:%0d matches", 
                      item.w_val, item.a_val[0], item.psum_val[0], expected_psum), UVM_MEDIUM)
        end else begin
            `uvm_error("SCBD_FAIL", $sformatf("W:%0d A:%0d PIn:%0d | Expected:%0d Got:%0d", 
                       item.w_val, item.a_val[0], item.psum_val[0], expected_psum, item.dut_psum))
        end
    endfunction
endclass
