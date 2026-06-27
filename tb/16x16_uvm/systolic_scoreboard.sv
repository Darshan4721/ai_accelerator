class systolic_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(systolic_scoreboard)
    uvm_tlm_analysis_fifo #(matrix_seq_item) fifo_in;
    uvm_tlm_analysis_fifo #(matrix_seq_item) fifo_out;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        fifo_in = new("fifo_in", this);
        fifo_out = new("fifo_out", this);
    endfunction
    
    // NATIVE SV GOLDEN MODEL (Bypasses RHEL 8 DPI-C Linker Bug)
    function void golden_matmul(input byte w[16][16], input byte a[16][16], output int c[16][16]);
        for(int i=0; i<16; i++) begin
            for(int j=0; j<16; j++) begin
                c[i][j] = 0;
                for(int k=0; k<16; k++) begin
                    c[i][j] += int'(signed'(a[i][k])) * int'(signed'(w[k][j]));
                end
            end
        end
    endfunction

    task run_phase(uvm_phase phase);
        matrix_seq_item item_in, item_out;
        int expected_c[16][16];
        int match_count;
        
        forever begin
            fifo_in.get(item_in);
            fifo_out.get(item_out);
            
            golden_matmul(item_in.w_mat, item_in.a_mat, expected_c);
            
            match_count = 0;
            for(int i=0; i<16; i++) begin
                for(int j=0; j<16; j++) begin
                    if (expected_c[i][j] !== item_out.dut_psum[i][j]) begin
                        `uvm_error("SCB_FAIL", $sformatf("Mismatch at [%0d][%0d]: Expected %0d, Got %0d", i, j, expected_c[i][j], item_out.dut_psum[i][j]))
                    end else begin
                        match_count++;
                    end
                end
            end
            
            if (match_count == 256) begin
                `uvm_info("SCB_PASS", "16x16 Matrix Multiplication PERFECT MATCH!", UVM_NONE)
            end
        end
    endtask
endclass
