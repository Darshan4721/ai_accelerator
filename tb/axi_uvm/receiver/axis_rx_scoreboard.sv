`ifndef AXIS_RX_SCOREBOARD_SV
`define AXIS_RX_SCOREBOARD_SV

`uvm_analysis_imp_decl(_axi)
`uvm_analysis_imp_decl(_sram)

class axis_rx_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(axis_rx_scoreboard)

    uvm_analysis_imp_axi  #(axi_dma_seq_item, axis_rx_scoreboard) axi_export;
    uvm_analysis_imp_sram #(sram_out_mon_item, axis_rx_scoreboard) sram_export;

    // --------------------------------------------------------
    // Senior Engineer Request #3: Scoreboard Queues
    // --------------------------------------------------------
    // Using a standard SV queue to safely hold the expected AXI data 
    // until the SRAM monitor actually captures the delayed write.
    logic [127:0] expected_data_queue[$];
    
    int expected_addr = 0;

    function new(string name = "axis_rx_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        axi_export = new("axi_export", this);
        sram_export = new("sram_export", this);
    endfunction

    // --------------------------------------------------------
    // Write function for AXI (DMA Ingress)
    // --------------------------------------------------------
    virtual function void write_axi(axi_dma_seq_item item);
        expected_data_queue.push_back(item.tdata);
        `uvm_info("SCB_AXI", $sformatf("Queued DMA data. Queue Size: %0d", expected_data_queue.size()), UVM_HIGH)
        
        // Check TLAST framing on push if we wanted, but we verify through matrix_done
    endfunction

    // --------------------------------------------------------
    // Write function for SRAM (DUT Egress)
    // --------------------------------------------------------
    virtual function void write_sram(sram_out_mon_item item);
        if (item.we === 1'b1) begin
            logic [127:0] exp_data;

            if (expected_data_queue.size() == 0) begin
                `uvm_error("SCB_FAIL", "SRAM Write occurred but AXI queue is empty!")
                return;
            end

            exp_data = expected_data_queue.pop_front();

            // 1. Check Data Match
            if (item.data !== exp_data) begin
                `uvm_error("SCB_FAIL", $sformatf("Data Mismatch! Expected: %h, Actual: %h", exp_data, item.data))
            end else begin
                `uvm_info("SCB_PASS", "SRAM Data Match Successful.", UVM_HIGH)
            end

            // 2. Check Address Increments
            if (item.addr !== expected_addr) begin
                `uvm_error("SCB_FAIL", $sformatf("Address Mismatch! Expected: %0d, Actual: %0d", expected_addr, item.addr))
            end else begin
                `uvm_info("SCB_PASS", "SRAM Address Match Successful.", UVM_HIGH)
            end

            if (expected_addr == 15) begin
                expected_addr = 0;
            end else begin
                expected_addr++;
            end
        end

        // 3. Check Matrix Done pulse (should pulse when address wraps to 0 right after 15)
        if (item.matrix_done === 1'b1) begin
            if (expected_addr !== 0) begin
                // The address should have already wrapped to 0 at the end of the 15th write.
                `uvm_error("SCB_FAIL", $sformatf("Matrix Done pulsed prematurely! Addr was: %0d", expected_addr))
            end else begin
                `uvm_info("SCB_PASS", "Matrix Done pulsed correctly.", UVM_HIGH)
            end
        end
    endfunction

endclass

`endif
