`ifndef AXI_MASTER_MONITOR_SV
`define AXI_MASTER_MONITOR_SV

class axi_master_monitor extends uvm_monitor;
    `uvm_component_utils(axi_master_monitor)

    virtual axi_lite_if vif;
    uvm_analysis_port #(axi_seq_item) ap;

    function new(string name = "axi_master_monitor", uvm_component parent = null);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_lite_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "virtual interface must be set for: vif")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        axi_seq_item item;
        
        // Parallel loops for Read and Write observation
        fork
            // Write Monitor Thread
            forever begin
                @(posedge vif.clk);
                if (vif.s_axi_awvalid && vif.s_axi_awready) begin
                    item = axi_seq_item::type_id::create("item");
                    item.is_write = 1;
                    item.addr = vif.s_axi_awaddr;
                    item.data = vif.s_axi_wdata;
                    
                    // Wait for BVALID response to confirm it finished
                    do begin
                        @(posedge vif.clk);
                    end while (!(vif.s_axi_bvalid && vif.s_axi_bready));
                    
                    ap.write(item);
                end
            end
            
            // Read Monitor Thread
            forever begin
                @(posedge vif.clk);
                if (vif.s_axi_arvalid && vif.s_axi_arready) begin
                    item = axi_seq_item::type_id::create("item");
                    item.is_write = 0;
                    item.addr = vif.s_axi_araddr;
                    
                    // Wait for RVALID response to capture data
                    do begin
                        @(posedge vif.clk);
                    end while (!(vif.s_axi_rvalid && vif.s_axi_rready));
                    
                    item.data = vif.s_axi_rdata;
                    ap.write(item);
                end
            end
        join
    endtask
endclass

`endif
