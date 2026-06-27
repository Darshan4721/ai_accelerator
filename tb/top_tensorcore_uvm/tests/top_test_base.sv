`ifndef TOP_TEST_BASE_SV
`define TOP_TEST_BASE_SV

class top_test_base extends uvm_test;
    `uvm_component_utils(top_test_base)
    
    top_env env;
    
    function new(string name="top_test_base", uvm_component parent=null);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = top_env::type_id::create("env", this);
    endfunction
    
    function void end_of_elaboration_phase(uvm_phase phase);
        uvm_top.print_topology();
    endfunction
endclass

`endif
