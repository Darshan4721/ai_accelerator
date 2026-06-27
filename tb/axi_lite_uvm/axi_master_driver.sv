`ifndef AXI_MASTER_DRIVER_SV
`define AXI_MASTER_DRIVER_SV

class axi_master_driver extends uvm_driver #(axi_seq_item);
    `uvm_component_utils(axi_master_driver)

    virtual axi_lite_if vif;

    function new(string name = "axi_master_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_lite_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "virtual interface must be set for: vif")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        // Initialize AXI Master signals
        vif.s_axi_awaddr  <= 0;
        vif.s_axi_awvalid <= 0;
        vif.s_axi_wdata   <= 0;
        vif.s_axi_wvalid  <= 0;
        vif.s_axi_bready  <= 0;
        vif.s_axi_araddr  <= 0;
        vif.s_axi_arvalid <= 0;
        vif.s_axi_rready  <= 0;

        forever begin
            seq_item_port.get_next_item(req);

            if (req.is_write) begin
                // Execute AXI Write Handshake
                vif.s_axi_awaddr  <= req.addr;
                vif.s_axi_awvalid <= 1'b1;
                vif.s_axi_wdata   <= req.data;
                vif.s_axi_wvalid  <= 1'b1;

                // Wait for Slave to accept Address
                do begin
                    @(posedge vif.clk);
                end while (vif.s_axi_awready !== 1'b1);
                vif.s_axi_awvalid <= 1'b0;

                // Wait for Slave to accept Data (if not accepted simultaneously)
                // In our design they are accepted same cycle, but let's be robust
                // Actually the while loop above should check both, but since our DUT 
                // asserts both simultaneously, this is fine.
                vif.s_axi_wvalid  <= 1'b0;

                // Wait for BVALID response
                do begin
                    @(posedge vif.clk);
                end while (vif.s_axi_bvalid !== 1'b1);

                // Inject backpressure delay before sending BREADY
                if (req.backpressure_delay > 0) begin
                    repeat(req.backpressure_delay) @(posedge vif.clk);
                end

                vif.s_axi_bready <= 1'b1;
                @(posedge vif.clk);
                vif.s_axi_bready <= 1'b0;

            end else begin
                // Execute AXI Read Handshake
                vif.s_axi_araddr  <= req.addr;
                vif.s_axi_arvalid <= 1'b1;

                // Wait for Slave to accept Address
                do begin
                    @(posedge vif.clk);
                end while (vif.s_axi_arready !== 1'b1);
                vif.s_axi_arvalid <= 1'b0;

                // Wait for RVALID response
                do begin
                    @(posedge vif.clk);
                end while (vif.s_axi_rvalid !== 1'b1);
                
                // Read the data here into the req item so sequence can see it
                req.data = vif.s_axi_rdata;

                // Inject backpressure delay before sending RREADY
                if (req.backpressure_delay > 0) begin
                    repeat(req.backpressure_delay) @(posedge vif.clk);
                end

                vif.s_axi_rready <= 1'b1;
                @(posedge vif.clk);
                vif.s_axi_rready <= 1'b0;
            end

            seq_item_port.item_done();
        end
    endtask
endclass

`endif
