`ifndef TOP_VSEQ_BASE_SV
`define TOP_VSEQ_BASE_SV

class top_vseq_base extends uvm_sequence;
    `uvm_object_utils(top_vseq_base)
    `uvm_declare_p_sequencer(top_vsequencer)
    
    function new(string name = "top_vseq_base");
        super.new(name);
    endfunction
    
    // Helper task to stream a matrix (Weights or Activations) via RX
    virtual task send_matrix(int num_rows = 16, int default_delay = 0);
        axis_rx_item rx_item;
        for (int i=0; i<num_rows; i++) begin
            `uvm_do_on_with(rx_item, p_sequencer.axis_rx_sqr_h, {
                tlast == (i == num_rows - 1);
                delay == default_delay;
            })
        end
    endtask
    
    // Helper task to trigger AXI-Lite computation
    virtual task trigger_compute();
        axi_lite_item ctrl_item;
        axi_lite_item stat_item;
        
        // Wait for rx_matrix_done (Bit 2) to be set
        forever begin
            `uvm_do_on_with(stat_item, p_sequencer.axi_lite_sqr_h, {
                addr == 32'h04;
                is_write == 0;
            })
            if (stat_item.data[2] == 1'b1) break;
        end
        
        // Send start_compute (Bit 0)
        `uvm_do_on_with(ctrl_item, p_sequencer.axi_lite_sqr_h, {
            addr == 32'h00;
            data == 32'h01;
            is_write == 1;
        })
    endtask
    
    // Helper task to poll mac_done
    virtual task wait_for_mac_done();
        axi_lite_item stat_item;
        forever begin
            `uvm_do_on_with(stat_item, p_sequencer.axi_lite_sqr_h, {
                addr == 32'h04;
                is_write == 0;
            })
            if (stat_item.data[1] == 1'b1) break;
        end
    endtask
endclass

`endif
