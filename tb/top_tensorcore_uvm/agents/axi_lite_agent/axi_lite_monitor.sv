`ifndef AXI_LITE_MONITOR_SV
`define AXI_LITE_MONITOR_SV

class axi_lite_monitor extends uvm_monitor;
    `uvm_component_utils(axi_lite_monitor)
    
    virtual system_top_if vif;
    uvm_analysis_port #(axi_lite_item) ap;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
        ap = new("ap", this);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual system_top_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
    endfunction
    
    task run_phase(uvm_phase phase);
        axi_lite_item curr_wr_item;
        axi_lite_item curr_rd_item;
        
        fork
            // Monitor Writes
            forever begin
                @(vif.cb_mon);
                if (vif.cb_mon.s_axi_awvalid && vif.cb_mon.s_axi_awready) begin
                    curr_wr_item = axi_lite_item::type_id::create("curr_wr_item");
                    curr_wr_item.is_write = 1;
                    curr_wr_item.addr = vif.cb_mon.s_axi_awaddr;
                    // Note: In strict AXI, W and AW can be independent. For simplicity, we capture here.
                end
                if (vif.cb_mon.s_axi_wvalid && vif.cb_mon.s_axi_wready && curr_wr_item != null) begin
                    curr_wr_item.data = vif.cb_mon.s_axi_wdata;
                end
                if (vif.cb_mon.s_axi_bvalid && vif.cb_mon.s_axi_bready && curr_wr_item != null) begin
                    curr_wr_item.bresp = vif.cb_mon.s_axi_bresp;
                    ap.write(curr_wr_item);
                    curr_wr_item = null;
                end
            end
            
            // Monitor Reads
            forever begin
                @(vif.cb_mon);
                if (vif.cb_mon.s_axi_arvalid && vif.cb_mon.s_axi_arready) begin
                    curr_rd_item = axi_lite_item::type_id::create("curr_rd_item");
                    curr_rd_item.is_write = 0;
                    curr_rd_item.addr = vif.cb_mon.s_axi_araddr;
                end
                if (vif.cb_mon.s_axi_rvalid && vif.cb_mon.s_axi_rready && curr_rd_item != null) begin
                    curr_rd_item.data = vif.cb_mon.s_axi_rdata;
                    curr_rd_item.rresp = vif.cb_mon.s_axi_rresp;
                    ap.write(curr_rd_item);
                    curr_rd_item = null;
                end
            end
        join
    endtask
endclass

`endif
