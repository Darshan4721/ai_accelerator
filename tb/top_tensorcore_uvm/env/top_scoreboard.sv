`ifndef TOP_SCOREBOARD_SV
`define TOP_SCOREBOARD_SV

`uvm_analysis_imp_decl(_rx)
`uvm_analysis_imp_decl(_tx)

class top_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(top_scoreboard)
    
    uvm_analysis_imp_rx #(axis_rx_item, top_scoreboard) rx_export;
    uvm_analysis_imp_tx #(axis_tx_item, top_scoreboard) tx_export;
    
    byte w_matrix[256];
    byte a_matrix[256];
    int expected_psum[256];
    
    bit is_act_matrix = 0;
    int row_idx = 0;
    int tx_row = 0;
    
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction
    
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        rx_export = new("rx_export", this);
        tx_export = new("tx_export", this);
    endfunction
    
    function void golden_matmul(ref byte w[256], ref byte a[256], ref int p[256]);
        for (int i = 0; i < 16; i++) begin
            for (int j = 0; j < 16; j++) begin
                int sum = 0;
                for (int k = 0; k < 16; k++) begin
                    sum += int'(signed'(a[i * 16 + k])) * int'(signed'(w[k * 16 + j]));
                end
                p[i * 16 + j] = sum;
            end
        end
    endfunction
    
    virtual function void write_rx(axis_rx_item item);
        // The RX Driver packs 128-bit tdata (16 elements of 8 bits) per transfer
        if (!is_act_matrix) begin
            for (int i=0; i<16; i++) w_matrix[row_idx*16 + i] = item.tdata[i*8 +: 8];
            if (item.tlast) begin
                is_act_matrix = 1;
                row_idx = 0;
            end else begin
                row_idx++;
            end
        end else begin
            for (int i=0; i<16; i++) a_matrix[row_idx*16 + i] = item.tdata[i*8 +: 8];
            if (item.tlast) begin
                is_act_matrix = 0; // Reset for the next pair
                row_idx = 0;
                golden_matmul(w_matrix, a_matrix, expected_psum);
                `uvm_info("SCB", "Golden model computation complete for new inference pair.", UVM_LOW)
            end else begin
                row_idx++;
            end
        end
    endfunction
    
    virtual function void write_tx(axis_tx_item item);
        // TX receives 16 rows of 512-bit (16 elements of 32 bits)
        bit [511:0] tdata = item.tdata;
        bit fail = 0;
        
        for (int i=0; i<16; i++) begin
            int actual_val = tdata[i*32 +: 32];
            int expected_val = expected_psum[tx_row*16 + i];
            
            if (actual_val !== expected_val) begin
                `uvm_error("SCB_FAIL", $sformatf("Mismatch at row %0d, col %0d. Expected: %0d, Got: %0d", tx_row, i, expected_val, actual_val))
                fail = 1;
            end
        end
        
        if (!fail) `uvm_info("SCB_PASS", $sformatf("TX Row %0d perfectly matches golden model.", tx_row), UVM_HIGH)
        
        tx_row++;
        if (item.tlast || tx_row == 16) tx_row = 0;
    endfunction
endclass

`endif
