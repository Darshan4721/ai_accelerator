class systolic_monitor extends uvm_monitor;
    `uvm_component_utils(systolic_monitor)
    virtual systolic_if vif;
    uvm_analysis_port #(matrix_seq_item) ap_in;
    uvm_analysis_port #(matrix_seq_item) ap_out;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual systolic_if)::get(this, "", "vif", vif))
            `uvm_fatal("NOMON", "virtual systolic_if not found")
        ap_in = new("ap_in", this);
        ap_out = new("ap_out", this);
    endfunction

    task run_phase(uvm_phase phase);
        matrix_seq_item item_in;
        matrix_seq_item item_out;
        byte current_w_mat[16][16];
        
        fork
            // Thread 1: Capture Inputs (W and A)
            forever begin
                item_in = matrix_seq_item::type_id::create("item_in");
                
                // Wait for either weight load or compute phase
                wait(vif.rst == 0);
                while(vif.i_load_weight_valid !== 1'b1 && vif.i_compute_valid !== 1'b1) @(posedge vif.clk);
                
                if (vif.i_load_weight_valid === 1'b1) begin
                    // Capture W (Row 0 to 15)
                    for(int r = 0; r < 16; r++) begin
                        if (vif.i_load_weight_valid) begin
                            for(int c=0; c<16; c++) current_w_mat[r][c] = vif.i_w[c];
                        end
                        if (r < 15) @(posedge vif.clk);
                    end
                    // Wait for next phase (compute valid)
                    @(posedge vif.clk);
                    while(vif.i_compute_valid !== 1'b1) @(posedge vif.clk);
                end
                
                // Assign stationary weights to the item for the scoreboard
                item_in.w_mat = current_w_mat;
                
                // Capture A (Row 0 to 15)
                for(int r = 0; r < 16; r++) begin
                    while(vif.i_compute_valid !== 1'b1) @(posedge vif.clk); // skip bubbles
                    for(int c=0; c<16; c++) item_in.a_mat[r][c] = vif.i_a[c];
                    if (r < 15) @(posedge vif.clk);
                end
                ap_in.write(item_in);
            end
            
            // Thread 2: Capture Outputs (C Matrix)
            forever begin
                item_out = matrix_seq_item::type_id::create("item_out");
                wait(vif.rst == 0);
                while(vif.o_valid !== 1'b1) @(posedge vif.clk);
                
                for(int r = 0; r < 16; r++) begin
                    while(vif.o_valid !== 1'b1) @(posedge vif.clk);
                    for(int c=0; c<16; c++) item_out.dut_psum[r][c] = vif.o_psum[c];
                    if (r < 15) @(posedge vif.clk);
                end
                ap_out.write(item_out);
            end
        join
    endtask
endclass
