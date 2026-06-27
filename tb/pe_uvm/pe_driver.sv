class pe_driver extends uvm_driver #(pe_seq_item);
    `uvm_component_utils(pe_driver)
    virtual pe_if vif;

    function new(string name, uvm_component parent); super.new(name, parent); endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual pe_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "virtual pe_if not found")
    endfunction

    task run_phase(uvm_phase phase);
        forever begin
            seq_item_port.get_next_item(req);
            
            if (req.rst_assert) begin
                @(negedge vif.clk);
                vif.rst <= 1;
                repeat(2) @(negedge vif.clk);
                vif.rst <= 0;
            end else begin
                // Load weight
                @(negedge vif.clk);
                vif.req_load_weight_in <= 1;
                vif.w_in <= req.w_val;
                @(negedge vif.clk);
                vif.req_load_weight_in <= 0;
                
                // Wait for lock
                wait(vif.ack_weight_locked == 1);

                // Stream activations
                for(int i = 0; i < req.a_val.size(); i++) begin
                    if($urandom_range(0, 100) < 15) @(negedge vif.clk); // Random bubbles
                    
                    @(negedge vif.clk);
                    vif.req_work_in <= 1;
                    vif.a_in <= req.a_val[i];
                    
                    fork 
                        begin
                            int idx = i;
                            @(negedge vif.clk);
                            vif.psum_in <= req.psum_val[idx]; // Staggered by 1 cycle
                        end
                    join_none
                end

                @(negedge vif.clk);
                vif.req_work_in <= 0;
                repeat(5) @(negedge vif.clk);
            end
            seq_item_port.item_done();
        end
    endtask
endclass
