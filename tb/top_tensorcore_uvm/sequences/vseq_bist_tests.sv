`ifndef VSEQ_BIST_TESTS_SV
`define VSEQ_BIST_TESTS_SV

// TC31: Standard BIST Execution & MISR Verification
class tc31_bist_standard_vseq extends top_vseq_base;
    `uvm_object_utils(tc31_bist_standard_vseq)
    function new(string name="tc31_bist_standard_vseq"); super.new(name); endfunction
    task body();
        bist_item b_item;
        `uvm_do_on_with(b_item, p_sequencer.bist_sqr_h, { 
            bist_start == 1; 
            expected_sig == {16{32'hDEADBEEF}};
        })
        `uvm_info("TC31", "Standard BIST Execution complete.", UVM_LOW)
    endtask
endclass

// TC32: BIST Signature Failure Detection
class tc32_bist_failure_vseq extends top_vseq_base;
    `uvm_object_utils(tc32_bist_failure_vseq)
    function new(string name="tc32_bist_failure_vseq"); super.new(name); endfunction
    task body();
        bist_item b_item;
        `uvm_do_on_with(b_item, p_sequencer.bist_sqr_h, { 
            bist_start == 1; 
            expected_sig == 512'hBAD_C0DE; 
        })
        `uvm_info("TC32", "BIST Signature Failure test complete.", UVM_LOW)
    endtask
endclass

// TC33: AXI-Lite Status Polling During BIST
class tc33_bist_axi_polling_vseq extends top_vseq_base;
    `uvm_object_utils(tc33_bist_axi_polling_vseq)
    function new(string name="tc33_bist_axi_polling_vseq"); super.new(name); endfunction
    task body();
        fork
            begin
                bist_item b_item;
                `uvm_do_on_with(b_item, p_sequencer.bist_sqr_h, { bist_start == 1; })
            end
            begin
                axi_lite_item ctrl_item;
                repeat(50) begin
                    `uvm_do_on_with(ctrl_item, p_sequencer.axi_lite_sqr_h, {
                        addr == 32'h08; 
                        is_write == 0;
                    })
                end
            end
        join
        `uvm_info("TC33", "AXI Polling During BIST complete.", UVM_LOW)
    endtask
endclass

// TC34: BIST Abort/Interrupt Tolerance
class tc34_bist_abort_vseq extends top_vseq_base;
    `uvm_object_utils(tc34_bist_abort_vseq)
    function new(string name="tc34_bist_abort_vseq"); super.new(name); endfunction
    task body();
        fork
            begin
                bist_item b_item;
                `uvm_do_on_with(b_item, p_sequencer.bist_sqr_h, { bist_start == 1; })
            end
            begin
                virtual system_top_if vif;
                if(uvm_config_db#(virtual system_top_if)::get(null, "", "vif", vif)) begin
                    #50ns;
                    vif.rst_ni = 0;
                    #10ns;
                    vif.rst_ni = 1;
                end
            end
        join_any
        `uvm_info("TC34", "BIST Abort Tolerance complete.", UVM_LOW)
    endtask
endclass

// TC35: Consecutive BIST Stress Loop
class tc35_bist_consecutive_vseq extends top_vseq_base;
    `uvm_object_utils(tc35_bist_consecutive_vseq)
    function new(string name="tc35_bist_consecutive_vseq"); super.new(name); endfunction
    task body();
        bist_item b_item;
        repeat(5) begin
            `uvm_do_on_with(b_item, p_sequencer.bist_sqr_h, { bist_start == 1; })
        end
        `uvm_info("TC35", "Consecutive BIST Stress complete.", UVM_LOW)
    endtask
endclass

`endif
