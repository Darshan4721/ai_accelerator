class systolic_agent extends uvm_agent;
    `uvm_component_utils(systolic_agent)
    systolic_driver drv;
    systolic_monitor mon;
    uvm_sequencer#(matrix_seq_item) seqr;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        drv = systolic_driver::type_id::create("drv", this);
        mon = systolic_monitor::type_id::create("mon", this);
        seqr = uvm_sequencer#(matrix_seq_item)::type_id::create("seqr", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        drv.seq_item_port.connect(seqr.seq_item_export);
    endfunction
endclass
