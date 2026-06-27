`ifndef AXIS_TX_SCOREBOARD_SV
`define AXIS_TX_SCOREBOARD_SV

`uvm_analysis_imp_decl(_sys_tx)
`uvm_analysis_imp_decl(_axi_rx)

class axis_tx_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(axis_tx_scoreboard)

    uvm_analysis_imp_sys_tx #(sys_tx_seq_item, axis_tx_scoreboard) sys_tx_export;
    uvm_analysis_imp_axi_rx #(axi_rx_mon_item, axis_tx_scoreboard) axi_rx_export;

    // Golden FIFO Queue
    logic [511:0] expected_queue[$];
    
    // TLAST 4-bit pop counter
    int pop_count = 0;

    function new(string name = "axis_tx_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sys_tx_export = new("sys_tx_export", this);
        axi_rx_export = new("axi_rx_export", this);
    endfunction

    // --------------------------------------------------------
    // Write function for SysTx (Array Data Ingress)
    // --------------------------------------------------------
    virtual function void write_sys_tx(sys_tx_seq_item item);
        expected_queue.push_back(item.psum_row);
        `uvm_info("SCB_SYS_TX", $sformatf("Pushed Data to Golden FIFO. Queue Size: %0d", expected_queue.size()), UVM_HIGH)
    endfunction

    // --------------------------------------------------------
    // Write function for AxiRx (DMA Data Egress)
    // --------------------------------------------------------
    virtual function void write_axi_rx(axi_rx_mon_item item);
        logic [511:0] exp_data;
        bit           expected_tlast;

        if (expected_queue.size() == 0) begin
            `uvm_error("SCB_FAIL", "Received AXI pop but Golden FIFO is empty!")
            return;
        end

        exp_data = expected_queue.pop_front();
        expected_tlast = (pop_count == 15);

        // Check Data Match
        if (item.tdata !== exp_data) begin
            `uvm_error("SCB_FAIL", $sformatf("Data Mismatch! Expected: %h, Actual: %h", exp_data, item.tdata))
        end else begin
            `uvm_info("SCB_PASS", "Data Match Successful.", UVM_HIGH)
        end

        // Check TLAST Generation
        if (item.tlast !== expected_tlast) begin
            `uvm_error("SCB_FAIL", $sformatf("TLAST Mismatch! Expected: %b (Pop Count: %0d), Actual: %b", expected_tlast, pop_count, item.tlast))
        end else begin
            `uvm_info("SCB_PASS", "TLAST Framing Successful.", UVM_HIGH)
        end

        // Increment and wrap 4-bit pop counter
        if (pop_count == 15) begin
            pop_count = 0;
        end else begin
            pop_count++;
        end
    endfunction

endclass

`endif
