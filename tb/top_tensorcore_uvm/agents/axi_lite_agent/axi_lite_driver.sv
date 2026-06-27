`ifndef AXI_LITE_DRIVER_SV
`define AXI_LITE_DRIVER_SV

class axi_lite_driver extends uvm_driver #(axi_lite_item);
    `uvm_component_utils(axi_lite_driver)
    
    virtual system_top_if vif;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual system_top_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOVIF", {"virtual interface must be set for: ", get_full_name(), ".vif"});
    endfunction
    
    task run_phase(uvm_phase phase);
        // Initialize lines
        vif.cb_drv.s_axi_awaddr <= 0;
        vif.cb_drv.s_axi_awvalid <= 0;
        vif.cb_drv.s_axi_wdata <= 0;
        vif.cb_drv.s_axi_wvalid <= 0;
        vif.cb_drv.s_axi_bready <= 0;
        vif.cb_drv.s_axi_araddr <= 0;
        vif.cb_drv.s_axi_arvalid <= 0;
        vif.cb_drv.s_axi_rready <= 0;
        
        forever begin
            seq_item_port.get_next_item(req);
            
            if (req.is_write) begin
                do_write(req);
            end else begin
                do_read(req);
            end
            
            seq_item_port.item_done();
        end
    endtask
    
    task do_write(axi_lite_item req);
        vif.cb_drv.s_axi_awaddr <= req.addr;
        vif.cb_drv.s_axi_awvalid <= 1'b1;
        vif.cb_drv.s_axi_wdata <= req.data;
        vif.cb_drv.s_axi_wvalid <= 1'b1;
        vif.cb_drv.s_axi_bready <= 1'b1;
        
        // Wait for AWREADY and WREADY
        fork
            begin
                do begin
                    @(vif.cb_drv);
                end while (vif.cb_drv.s_axi_awready !== 1'b1);
                vif.cb_drv.s_axi_awvalid <= 1'b0;
            end
            begin
                do begin
                    @(vif.cb_drv);
                end while (vif.cb_drv.s_axi_wready !== 1'b1);
                vif.cb_drv.s_axi_wvalid <= 1'b0;
            end
        join
        
        // Wait for BVALID
        do begin
            @(vif.cb_drv);
        end while (vif.cb_drv.s_axi_bvalid !== 1'b1);
        req.bresp = vif.cb_drv.s_axi_bresp;
        vif.cb_drv.s_axi_bready <= 1'b0;
    endtask
    
    task do_read(axi_lite_item req);
        vif.cb_drv.s_axi_araddr <= req.addr;
        vif.cb_drv.s_axi_arvalid <= 1'b1;
        vif.cb_drv.s_axi_rready <= 1'b1;
        
        do begin
            @(vif.cb_drv);
        end while (vif.cb_drv.s_axi_arready !== 1'b1);
        vif.cb_drv.s_axi_arvalid <= 1'b0;
        
        do begin
            @(vif.cb_drv);
        end while (vif.cb_drv.s_axi_rvalid !== 1'b1);
        req.data = vif.cb_drv.s_axi_rdata;
        req.rresp = vif.cb_drv.s_axi_rresp;
        vif.cb_drv.s_axi_rready <= 1'b0;
    endtask
endclass

`endif
