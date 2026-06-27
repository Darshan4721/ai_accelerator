`ifndef CORE_CTRL_DRIVER_SV
`define CORE_CTRL_DRIVER_SV

class core_ctrl_driver extends uvm_driver #(core_ctrl_seq_item);
    `uvm_component_utils(core_ctrl_driver)

    virtual axi_lite_if vif;

    function new(string name = "core_ctrl_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual axi_lite_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "virtual interface must be set for: vif")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);
        vif.mac_done <= 1'b0;

        forever begin
            seq_item_port.get_next_item(req);

            // Wait for start_compute pulse
            do begin
                @(posedge vif.clk);
            end while (vif.start_compute !== 1'b1);
            
            // Wait the randomized delay
            if (req.mac_done_delay > 0) begin
                repeat(req.mac_done_delay) @(posedge vif.clk);
            end

            // Assert mac_done (it is sticky, but we can clear it on the next start pulse in real HW, here we just pulse it or hold it)
            // Real hardware mac_done is sticky until the next compute cycle
            vif.mac_done <= 1'b1;
            
            // We just hold it HIGH until the next sequence item requires it to clear or wait again.
            // Actually, we'll clear it when start_compute goes high again
            fork
                begin
                    do begin
                        @(posedge vif.clk);
                    end while (vif.start_compute !== 1'b1);
                    vif.mac_done <= 1'b0;
                end
            join_none

            seq_item_port.item_done();
        end
    endtask
endclass

`endif
