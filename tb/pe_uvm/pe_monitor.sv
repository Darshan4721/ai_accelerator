class pe_monitor extends uvm_monitor;
    `uvm_component_utils(pe_monitor)
    virtual pe_if vif;
    uvm_analysis_port #(pe_seq_item) ap;

    function new(string name, uvm_component parent); super.new(name, parent); endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if(!uvm_config_db#(virtual pe_if)::get(this, "", "vif", vif))
            `uvm_fatal("NO_VIF", "virtual pe_if not found")
        ap = new("ap", this);
    endfunction

    task run_phase(uvm_phase phase);
        byte current_w;
        forever begin
            @(posedge vif.clk);
            if (!vif.rst) begin
                if(vif.req_load_weight_in) current_w = vif.w_in;
                if(vif.req_work_in) begin
                    pe_seq_item item = pe_seq_item::type_id::create("item");
                    item.w_val = current_w;
                    item.a_val = new[1];
                    item.a_val[0] = vif.a_in;
                    item.psum_val = new[1];
                    
                    fork capture_output(item); join_none
                end
            end
        end
    endtask
    
    task capture_output(pe_seq_item item);
        @(posedge vif.clk);
        if (vif.rst) return;
        item.psum_val[0] = vif.psum_in; // captured 1 cycle after a_in
        @(posedge vif.clk);
        if (vif.rst) return;
        item.dut_psum = vif.psum_out; // 2 cycles after req_work_in
        ap.write(item);
    endtask
endclass
