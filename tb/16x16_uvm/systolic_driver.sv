class systolic_driver extends uvm_driver #(matrix_seq_item);
    `uvm_component_utils(systolic_driver)
    virtual systolic_if vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual systolic_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "virtual systolic_if not found")
    endfunction

    task run_phase(uvm_phase phase);
        vif.i_load_weight_valid <= 0;
        vif.i_compute_valid <= 0;
        for (int i=0; i<16; i++) begin
            vif.i_w[i] <= 0;
            vif.i_a[i] <= 0;
        end
        @(negedge vif.clk);

        forever begin
            // Handshake: Driver asks sequencer for next item
            seq_item_port.get_next_item(req);
            
            // Wait for reset to be de-asserted
            wait(vif.rst == 0);
            
            if (req.load_weights) begin
                // State 1: Load Weights (Top row first, so row 0 down to 15)
                for (int r = 0; r < 16; r++) begin
                    @(negedge vif.clk);
                    vif.i_load_weight_valid <= 1;
                    for (int c = 0; c < 16; c++) begin
                        vif.i_w[c] <= req.w_mat[r][c];
                    end
                end
                @(negedge vif.clk);
                vif.i_load_weight_valid <= 0;
                for (int c = 0; c < 16; c++) vif.i_w[c] <= 0;
    
                // State 2: Wait for o_weight_locked
                while (vif.o_weight_locked !== 1'b1) begin
                    @(negedge vif.clk);
                end
            end

            // State 3: Stream Activations
            for (int r = 0; r < 16; r++) begin
                // Inject random bubble (10% chance)
                if ($urandom_range(0, 99) < 10) begin
                    int bubbles = $urandom_range(1, 3);
                    vif.i_compute_valid <= 0;
                    for (int c=0; c<16; c++) vif.i_a[c] <= 0;
                    repeat(bubbles) @(negedge vif.clk);
                end
                
                @(negedge vif.clk);
                vif.i_compute_valid <= 1;
                for (int c = 0; c < 16; c++) begin
                    vif.i_a[c] <= req.a_mat[r][c];
                end
            end
            @(negedge vif.clk);
            vif.i_compute_valid <= 0;
            for (int c = 0; c < 16; c++) vif.i_a[c] <= 0;
            
            // Handshake: Driver tells sequencer it's done with item
            seq_item_port.item_done();
        end
    endtask
endclass
