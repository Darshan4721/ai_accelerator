`ifndef AXI_LITE_SCOREBOARD_SV
`define AXI_LITE_SCOREBOARD_SV

`uvm_analysis_imp_decl(_axi)
`uvm_analysis_imp_decl(_core)

class axi_lite_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(axi_lite_scoreboard)

    uvm_analysis_imp_axi  #(axi_seq_item, axi_lite_scoreboard) axi_export;
    uvm_analysis_imp_core #(core_ctrl_seq_item, axi_lite_scoreboard) core_export;

    // Tracking states
    int expected_start_pulses;
    int observed_start_pulses;
    
    // Core state
    virtual axi_lite_if vif;

    function new(string name = "axi_lite_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        axi_export  = new("axi_export", this);
        core_export = new("core_export", this);
        
        expected_start_pulses = 0;
        observed_start_pulses = 0;
        
        if (!uvm_config_db#(virtual axi_lite_if)::get(this, "", "vif", vif)) begin
            `uvm_fatal("NOVIF", "virtual interface must be set for: vif")
        end
    endfunction

    virtual function void write_axi(axi_seq_item item);
        if (item.is_write) begin
            if (item.addr == 32'h00) begin
                if (item.data[0] == 1'b1) begin
                    expected_start_pulses++;
                    `uvm_info("SCB_AXI", "AXI Write to 0x00 with data[0]=1. Expecting start_compute pulse.", UVM_LOW)
                end
            end else begin
                `uvm_info("SCB_AXI", $sformatf("AXI Write to unmapped addr %0h. Expecting NO pulse.", item.addr), UVM_LOW)
            end
        end else begin
            // Read
            if (item.addr == 32'h04) begin
                if (item.data == {31'b0, vif.mac_done}) begin
                    `uvm_info("SCB_PASS", $sformatf("Read 0x04 returned correct mac_done state: %0b", vif.mac_done), UVM_LOW)
                end else begin
                    `uvm_error("SCB_FAIL", $sformatf("Read 0x04 mismatch! Expected: %0b, Actual: %0d", vif.mac_done, item.data))
                end
            end else begin
                if (item.data == 32'h0) begin
                    `uvm_info("SCB_PASS", $sformatf("Read unmapped addr %0h returned 0 gracefully.", item.addr), UVM_LOW)
                end else begin
                    `uvm_error("SCB_FAIL", $sformatf("Read unmapped addr %0h returned %0d instead of 0!", item.addr, item.data))
                end
            end
        end
    endfunction

    virtual function void write_core(core_ctrl_seq_item item);
        // We received a start_compute pulse from the core monitor
        observed_start_pulses++;
        `uvm_info("SCB_CORE", "Observed start_compute pulse from DUT.", UVM_LOW)
        
        // Let's assume the core model will assert mac_done after some delay.
        // The scoreboard simply tracks it to predict AXI reads.
        // Actually, we don't have visibility into the driver's delay from the scoreboard 
        // unless we model it or just tap the interface. But since the interface is physical,
        // we can just check it if we really need to, but the scoreboard's job is translation check.
        // We'll update current_mac_done when it actually changes via an interface tap or we can just 
        // rely on the UVM test to check it.
        // For simplicity, we just expect the AXI reads to match whatever the physical mac_done is.
    endfunction

    virtual function void check_phase(uvm_phase phase);
        super.check_phase(phase);
        if (expected_start_pulses != observed_start_pulses) begin
            `uvm_error("SCB_FAIL", $sformatf("Pulse mismatch! Expected: %0d, Observed: %0d", expected_start_pulses, observed_start_pulses))
        end else begin
            `uvm_info("SCB_PASS", $sformatf("All %0d start_compute pulses were correctly generated.", expected_start_pulses), UVM_NONE)
        end
    endfunction

endclass

`endif
