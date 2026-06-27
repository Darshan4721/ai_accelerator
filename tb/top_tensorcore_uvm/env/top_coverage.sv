`ifndef TOP_COVERAGE_SV
`define TOP_COVERAGE_SV

class top_coverage extends uvm_subscriber #(axis_rx_item);
    `uvm_component_utils(top_coverage)
    
    axis_rx_item rx_item;
    
    // Functional coverage for extreme boundaries
    covergroup cg_rx_payloads;
        cp_tdata_bound: coverpoint rx_item.tdata[7:0] {
            bins max_pos = {127};
            bins min_neg = {-128};
            bins zero    = {0};
        }
    endgroup
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg_rx_payloads = new();
    endfunction
    
    virtual function void write(axis_rx_item t);
        rx_item = t;
        cg_rx_payloads.sample();
    endfunction
endclass

`endif
