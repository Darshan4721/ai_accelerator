`ifndef AXI_LITE_COVERAGE_SV
`define AXI_LITE_COVERAGE_SV

class axi_lite_coverage extends uvm_subscriber #(axi_seq_item);
    `uvm_component_utils(axi_lite_coverage)

    virtual axi_lite_if vif;

    covergroup axi_cg;
        option.per_instance = 1;
        
        // Address hit coverage
        cp_awaddr: coverpoint vif.s_axi_awaddr {
            bins ctrl_reg = {32'h00};
            bins other    = {[32'h01:32'hFF]};
        }
        
        cp_araddr: coverpoint vif.s_axi_araddr {
            bins status_reg = {32'h04};
            bins other      = {[32'h00:32'h03], [32'h05:32'hFF]};
        }
        
        // Backpressure coverage
        cp_bready_stall: coverpoint vif.s_axi_bready {
            bins stalled = {0};
            bins ready   = {1};
        }
        
        cp_rready_stall: coverpoint vif.s_axi_rready {
            bins stalled = {0};
            bins ready   = {1};
        }
    endgroup

    function new(string name = "axi_lite_coverage", uvm_component parent = null);
        super.new(name, parent);
        axi_cg = new();
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_lite_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "virtual interface must be set for: vif")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        forever begin
            @(posedge vif.clk);
            axi_cg.sample();
        end
    endtask
    
    virtual function void write(axi_seq_item t);
        // Passive coverage sample
    endfunction

endclass

`endif
