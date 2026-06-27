`ifndef TOP_TESTS_ALL_SV
`define TOP_TESTS_ALL_SV

class tc1_test extends top_test_base;
    `uvm_component_utils(tc1_test)
    function new(string name="tc1_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc1_hw_in_the_loop_vseq vseq;
        phase.raise_objection(this);
        vseq = tc1_hw_in_the_loop_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc2_test extends top_test_base;
    `uvm_component_utils(tc2_test)
    function new(string name="tc2_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc2_crosstalk_rejection_vseq vseq;
        phase.raise_objection(this);
        vseq = tc2_crosstalk_rejection_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc3_test extends top_test_base;
    `uvm_component_utils(tc3_test)
    function new(string name="tc3_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc3_invalid_addr_vseq vseq;
        phase.raise_objection(this);
        vseq = tc3_invalid_addr_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc4_test extends top_test_base;
    `uvm_component_utils(tc4_test)
    function new(string name="tc4_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc4_spin_poll_sync_vseq vseq;
        phase.raise_objection(this);
        vseq = tc4_spin_poll_sync_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc5_test extends top_test_base;
    `uvm_component_utils(tc5_test)
    function new(string name="tc5_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc5_bist_override_vseq vseq;
        phase.raise_objection(this);
        vseq = tc5_bist_override_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc6_test extends top_test_base;
    `uvm_component_utils(tc6_test)
    function new(string name="tc6_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc6_latency_proof_vseq vseq;
        phase.raise_objection(this);
        vseq = tc6_latency_proof_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc7_test extends top_test_base;
    `uvm_component_utils(tc7_test)
    function new(string name="tc7_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc7_wedge_deskew_vseq vseq;
        phase.raise_objection(this);
        vseq = tc7_wedge_deskew_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc8_test extends top_test_base;
    `uvm_component_utils(tc8_test)
    function new(string name="tc8_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc8_data_starvation_vseq vseq;
        phase.raise_objection(this);
        vseq = tc8_data_starvation_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc9_test extends top_test_base;
    `uvm_component_utils(tc9_test)
    function new(string name="tc9_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc9_max_throughput_vseq vseq;
        phase.raise_objection(this);
        vseq = tc9_max_throughput_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc10_test extends top_test_base;
    `uvm_component_utils(tc10_test)
    function new(string name="tc10_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc10_midflight_reset_vseq vseq;
        phase.raise_objection(this);
        vseq = tc10_midflight_reset_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc11_test extends top_test_base;
    `uvm_component_utils(tc11_test)
    function new(string name="tc11_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc11_burst_packing_vseq vseq;
        phase.raise_objection(this);
        vseq = tc11_burst_packing_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc12_test extends top_test_base;
    `uvm_component_utils(tc12_test)
    function new(string name="tc12_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc12_rx_tready_tolerance_vseq vseq;
        phase.raise_objection(this);
        vseq = tc12_rx_tready_tolerance_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc13_test extends top_test_base;
    `uvm_component_utils(tc13_test)
    function new(string name="tc13_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc13_non_contiguous_tvalid_vseq vseq;
        phase.raise_objection(this);
        vseq = tc13_non_contiguous_tvalid_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc14_test extends top_test_base;
    `uvm_component_utils(tc14_test)
    function new(string name="tc14_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc14_tlast_misalignment_vseq vseq;
        phase.raise_objection(this);
        vseq = tc14_tlast_misalignment_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc15_test extends top_test_base;
    `uvm_component_utils(tc15_test)
    function new(string name="tc15_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc15_extreme_int8_bounds_vseq vseq;
        phase.raise_objection(this);
        vseq = tc15_extreme_int8_bounds_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc16_test extends top_test_base;
    `uvm_component_utils(tc16_test)
    function new(string name="tc16_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc16_tx_drain_integrity_vseq vseq;
        phase.raise_objection(this);
        vseq = tc16_tx_drain_integrity_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc17_test extends top_test_base;
    `uvm_component_utils(tc17_test)
    function new(string name="tc17_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc17_tx_backpressure_lock_vseq vseq;
        phase.raise_objection(this);
        vseq = tc17_tx_backpressure_lock_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc18_test extends top_test_base;
    `uvm_component_utils(tc18_test)
    function new(string name="tc18_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc18_mid_drain_interruption_vseq vseq;
        phase.raise_objection(this);
        vseq = tc18_mid_drain_interruption_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc19_test extends top_test_base;
    `uvm_component_utils(tc19_test)
    function new(string name="tc19_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc19_eof_tlast_validation_vseq vseq;
        phase.raise_objection(this);
        vseq = tc19_eof_tlast_validation_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc20_test extends top_test_base;
    `uvm_component_utils(tc20_test)
    function new(string name="tc20_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc20_staggered_tready_polling_vseq vseq;
        phase.raise_objection(this);
        vseq = tc20_staggered_tready_polling_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc21_test extends top_test_base;
    `uvm_component_utils(tc21_test)
    function new(string name="tc21_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc21_sram_ping_pong_conflict_vseq vseq;
        phase.raise_objection(this);
        vseq = tc21_sram_ping_pong_conflict_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc22_test extends top_test_base;
    `uvm_component_utils(tc22_test)
    function new(string name="tc22_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc22_sram_asymmetric_bw_vseq vseq;
        phase.raise_objection(this);
        vseq = tc22_sram_asymmetric_bw_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc23_test extends top_test_base;
    `uvm_component_utils(tc23_test)
    function new(string name="tc23_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc23_oob_addr_forcing_vseq vseq;
        phase.raise_objection(this);
        vseq = tc23_oob_addr_forcing_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc24_test extends top_test_base;
    `uvm_component_utils(tc24_test)
    function new(string name="tc24_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc24_multi_matrix_overwrite_vseq vseq;
        phase.raise_objection(this);
        vseq = tc24_multi_matrix_overwrite_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc25_test extends top_test_base;
    `uvm_component_utils(tc25_test)
    function new(string name="tc25_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc25_dual_port_coherency_vseq vseq;
        phase.raise_objection(this);
        vseq = tc25_dual_port_coherency_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc26_test extends top_test_base;
    `uvm_component_utils(tc26_test)
    function new(string name="tc26_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc26_sparse_matrix_vseq vseq;
        phase.raise_objection(this);
        vseq = tc26_sparse_matrix_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc27_test extends top_test_base;
    `uvm_component_utils(tc27_test)
    function new(string name="tc27_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc27_dense_all_ones_vseq vseq;
        phase.raise_objection(this);
        vseq = tc27_dense_all_ones_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc28_test extends top_test_base;
    `uvm_component_utils(tc28_test)
    function new(string name="tc28_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc28_checkerboard_vseq vseq;
        phase.raise_objection(this);
        vseq = tc28_checkerboard_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc29_test extends top_test_base;
    `uvm_component_utils(tc29_test)
    function new(string name="tc29_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc29_overflow_bound_vseq vseq;
        phase.raise_objection(this);
        vseq = tc29_overflow_bound_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc30_test extends top_test_base;
    `uvm_component_utils(tc30_test)
    function new(string name="tc30_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc30_zero_weight_vseq vseq;
        phase.raise_objection(this);
        vseq = tc30_zero_weight_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc31_test extends top_test_base;
    `uvm_component_utils(tc31_test)
    function new(string name="tc31_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc31_bist_standard_vseq vseq;
        phase.raise_objection(this);
        vseq = tc31_bist_standard_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc32_test extends top_test_base;
    `uvm_component_utils(tc32_test)
    function new(string name="tc32_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc32_bist_failure_vseq vseq;
        phase.raise_objection(this);
        vseq = tc32_bist_failure_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc33_test extends top_test_base;
    `uvm_component_utils(tc33_test)
    function new(string name="tc33_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc33_bist_axi_polling_vseq vseq;
        phase.raise_objection(this);
        vseq = tc33_bist_axi_polling_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc34_test extends top_test_base;
    `uvm_component_utils(tc34_test)
    function new(string name="tc34_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc34_bist_abort_vseq vseq;
        phase.raise_objection(this);
        vseq = tc34_bist_abort_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc35_test extends top_test_base;
    `uvm_component_utils(tc35_test)
    function new(string name="tc35_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc35_bist_consecutive_vseq vseq;
        phase.raise_objection(this);
        vseq = tc35_bist_consecutive_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc36_test extends top_test_base;
    `uvm_component_utils(tc36_test)
    function new(string name="tc36_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc36_bist_compute_bist_vseq vseq;
        phase.raise_objection(this);
        vseq = tc36_bist_compute_bist_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc37_test extends top_test_base;
    `uvm_component_utils(tc37_test)
    function new(string name="tc37_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc37_async_traffic_jam_vseq vseq;
        phase.raise_objection(this);
        vseq = tc37_async_traffic_jam_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc38_test extends top_test_base;
    `uvm_component_utils(tc38_test)
    function new(string name="tc38_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc38_compute_overlap_vseq vseq;
        phase.raise_objection(this);
        vseq = tc38_compute_overlap_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc39_test extends top_test_base;
    `uvm_component_utils(tc39_test)
    function new(string name="tc39_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc39_power_virus_vseq vseq;
        phase.raise_objection(this);
        vseq = tc39_power_virus_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc40_test extends top_test_base;
    `uvm_component_utils(tc40_test)
    function new(string name="tc40_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc40_hang_recovery_vseq vseq;
        phase.raise_objection(this);
        vseq = tc40_hang_recovery_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc41_test extends top_test_base;
    `uvm_component_utils(tc41_test)
    function new(string name="tc41_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc41_illegal_protocol_vseq vseq;
        phase.raise_objection(this);
        vseq = tc41_illegal_protocol_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

class tc42_ultimate_signoff_test extends top_test_base;
    `uvm_component_utils(tc42_ultimate_signoff_test)
    function new(string name="tc42_ultimate_signoff_test", uvm_component parent=null); super.new(name, parent); endfunction
    task run_phase(uvm_phase phase);
        tc42_ultimate_signoff_vseq vseq;
        phase.raise_objection(this);
        vseq = tc42_ultimate_signoff_vseq::type_id::create("vseq");
        vseq.start(env.vsqr);
        phase.drop_objection(this);
    endtask
endclass

`endif
