// ==============================================================================
// Module: top_tensorcore_lite.sv
// Description: The Phase 7 System Wrapper for the 256-PE Matrix Accelerator.
//              Stitches AXI-Lite, AXI-Stream, SRAM, Core FSM, Array, and BIST.
// Technology: TSMC 180nm (cadence slow.lib) target, 250MHz-350MHz
// ==============================================================================
`timescale 1ns/1ps

module top_tensorcore_lite (
    // --------------------------------------------------------
    // 1. System Clock & Reset
    // --------------------------------------------------------
    input  logic         clk_i,
    input  logic         rst_ni, // Synchronous Active-Low from SoC

    // --------------------------------------------------------
    // 2. AXI4-Lite Configuration Interface (From CPU)
    // --------------------------------------------------------
    input  logic [31:0]  s_axi_awaddr,
    input  logic         s_axi_awvalid,
    output logic         s_axi_awready,
    input  logic [31:0]  s_axi_wdata,
    input  logic         s_axi_wvalid,
    output logic         s_axi_wready,
    output logic [1:0]   s_axi_bresp,
    output logic         s_axi_bvalid,
    input  logic         s_axi_bready,
    input  logic [31:0]  s_axi_araddr,
    input  logic         s_axi_arvalid,
    output logic         s_axi_arready,
    output logic [31:0]  s_axi_rdata,
    output logic [1:0]   s_axi_rresp,
    output logic         s_axi_rvalid,
    input  logic         s_axi_rready,

    // --------------------------------------------------------
    // 3. AXI-Stream RX (Incoming Matrices from DMA)
    // --------------------------------------------------------
    input  logic [127:0] s_axis_tdata,
    input  logic         s_axis_tvalid,
    output logic         s_axis_tready,
    input  logic         s_axis_tlast,

    // --------------------------------------------------------
    // 4. AXI-Stream TX (Outgoing Partial Sums to DMA)
    // --------------------------------------------------------
    output logic [511:0] m_axis_tdata,
    output logic         m_axis_tvalid,
    input  logic         m_axis_tready,
    output logic         m_axis_tlast,

    // --------------------------------------------------------
    // 5. DFT / BIST External Pins
    // --------------------------------------------------------
    input  logic         bist_start_i,
    input  logic [511:0] expected_misr_sig_i,
    output logic         bist_done_o,
    output logic         bist_fail_o,

    // --------------------------------------------------------
    // 6. DFT (Scan Chain) Pins for Genus Insertion
    // --------------------------------------------------------
    input  logic         scan_clk_port,
    input  logic         scan_en_port,
    input  logic         test_mode_port,
    input  logic [3:0]   scan_in_port,
    output logic [3:0]   scan_out_port
);

    // ========================================================
    // INTERNAL ROUTING WIRES
    // ========================================================
    // Reset generation (2-FF Synchronizer for External Async Reset)
    logic rst_sync1;
    logic rst_i;
    
    always_ff @(posedge clk_i) begin
        // The external reset is active-low (rst_ni). 
        // We invert it and synchronize it to generate the internal active-high synchronous reset.
        rst_sync1 <= ~rst_ni;
        rst_i     <= rst_sync1;
    end

    // ========================================================
    // CLOCK DOMAIN CROSSING (JTAG TCK -> System clk_i)
    // ========================================================
    logic bist_start_sync1;
    logic bist_start_sync2;

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            bist_start_sync1 <= 1'b0;
            bist_start_sync2 <= 1'b0;
        end else begin
            // Stage 1: Sample the asynchronous JTAG signal
            bist_start_sync1 <= bist_start_i;
            // Stage 2: Stabilize the signal for the 250MHz domain
            bist_start_sync2 <= bist_start_sync1;
        end
    end

    // Control Plane Wires
    logic start_compute_wire;
    logic mac_done_wire;
    logic rx_matrix_done_wire;

    // SRAM Subsystem Wires
    logic         rx_sram_we;
    logic [7:0]   rx_sram_w_addr;
    logic [127:0] rx_sram_w_data;
    
    logic         fsm_sram_re;
    logic [7:0]   fsm_sram_r_addr;
    logic [127:0] sram_r_data_out;

    // BIST Subsystem Wires
    logic         mbist_we_wire;
    logic         mbist_re_wire;
    logic [7:0]   mbist_w_addr_wire;
    logic [7:0]   mbist_r_addr_wire;
    logic [127:0] mbist_w_data_wire;
    logic [127:0] lfsr_prpg_out_wire;

    // Systolic Array Wires
    logic         fsm_array_load_w_valid;
    logic         fsm_array_comp_valid;
    logic [127:0] fsm_array_w_in_packed;
    logic [127:0] fsm_array_a_in_packed;
    
    logic         array_w_locked_wire;
    logic         array_o_valid_early;
    logic         array_o_valid_wire;
    logic [511:0] array_o_psum_packed;

    logic [511:0] array_o_psum_packed_aligned;

    always_ff @(posedge clk_i) begin
        if (rst_i) begin
            array_o_valid_wire <= 1'b0;
            array_o_psum_packed_aligned <= 512'b0;
        end else begin
            array_o_valid_wire <= array_o_valid_early;
            array_o_psum_packed_aligned <= array_o_psum_packed;
        end
    end

    // Unpacked 2D Arrays for the Systolic Grid
    logic [7:0]   array_w_in_unpacked [0:15];
    logic [7:0]   array_a_in_unpacked [0:15];
    logic [31:0]  array_o_psum_unpacked [0:15];

    // ========================================================
    // MULTIPLEXERS (BIST vs. FUNCTIONAL MODE)
    // ========================================================
    logic         sram_we_mux;
    logic         sram_re_mux;
    logic [7:0]   sram_w_addr_mux;
    logic [7:0]   sram_r_addr_mux;
    logic [127:0] sram_w_data_mux;

    logic [127:0] array_w_in_mux;
    logic [127:0] array_a_in_mux;
    logic         array_load_w_valid_mux;
    logic         array_comp_valid_mux;

    assign sram_we_mux       = bist_start_sync2 ? mbist_we_wire     : rx_sram_we;
    assign sram_re_mux       = bist_start_sync2 ? mbist_re_wire     : fsm_sram_re;
    assign sram_w_addr_mux   = bist_start_sync2 ? mbist_w_addr_wire : rx_sram_w_addr;
    assign sram_r_addr_mux   = bist_start_sync2 ? mbist_r_addr_wire : fsm_sram_r_addr;
    assign sram_w_data_mux   = bist_start_sync2 ? mbist_w_data_wire : rx_sram_w_data;

    assign array_w_in_mux    = bist_start_sync2 ? lfsr_prpg_out_wire : fsm_array_w_in_packed;
    assign array_a_in_mux    = bist_start_sync2 ? lfsr_prpg_out_wire : fsm_array_a_in_packed;
    assign array_load_w_valid_mux = bist_start_sync2 ? 1'b1 : fsm_array_load_w_valid;
    assign array_comp_valid_mux   = bist_start_sync2 ? 1'b1 : fsm_array_comp_valid;

    // ========================================================
    // DATA PACKING / UNPACKING (Flattening 2D Arrays)
    // ========================================================
    genvar i;
    generate
        for (i = 0; i < 16; i++) begin : gen_pack_unpack
            // Unpack 128-bit flat busses into 16x8-bit memory structures for the array
            assign array_w_in_unpacked[i] = array_w_in_mux[i*8 +: 8];
            assign array_a_in_unpacked[i] = array_a_in_mux[i*8 +: 8];
            
            // Pack the 16x32-bit partial sums out of the array into a 512-bit flat bus
            assign array_o_psum_packed[i*32 +: 32] = array_o_psum_unpacked[i];
        end
    endgenerate


    // ========================================================
    // 1. AXI-Lite Configuration Module
    // ========================================================
    axi_lite_config u_axi_lite (
        .clk             (clk_i),
        .rst             (rst_i),
        .start_compute   (start_compute_wire),
        .mac_done        (mac_done_wire),
        .rx_matrix_done  (rx_matrix_done_wire),
        .wt_locked       (array_w_locked_wire),
        
        .s_axi_awaddr    (s_axi_awaddr),
        .s_axi_awvalid   (s_axi_awvalid),
        .s_axi_awready   (s_axi_awready),
        .s_axi_wdata     (s_axi_wdata),
        .s_axi_wvalid    (s_axi_wvalid),
        .s_axi_wready    (s_axi_wready),
        .s_axi_bresp     (s_axi_bresp),
        .s_axi_bvalid    (s_axi_bvalid),
        .s_axi_bready    (s_axi_bready),
        .s_axi_araddr    (s_axi_araddr),
        .s_axi_arvalid   (s_axi_arvalid),
        .s_axi_arready   (s_axi_arready),
        .s_axi_rdata     (s_axi_rdata),
        .s_axi_rresp     (s_axi_rresp),
        .s_axi_rvalid    (s_axi_rvalid),
        .s_axi_rready    (s_axi_rready)
    );

    // ========================================================
    // 2. Core Controller FSM (The Brain)
    // ========================================================
    core_fsm_ctrl u_core_fsm (
        .clk                     (clk_i),
        .rst                     (rst_i),
        .start_compute           (start_compute_wire),
        .mac_done                (mac_done_wire),
        
        .sram_re                 (fsm_sram_re),
        .sram_r_addr             (fsm_sram_r_addr),
        .sram_r_data             (sram_r_data_out),
        
        .array_load_weight_valid (fsm_array_load_w_valid),
        .array_compute_valid     (fsm_array_comp_valid),
        .array_w_in              (fsm_array_w_in_packed),
        .array_a_in              (fsm_array_a_in_packed),
        .array_weight_locked     (array_w_locked_wire)
    );

    // ========================================================
    // 3. AXI-Stream Receiver (DMA -> SRAM)
    // ========================================================
    axis_rx u_axis_rx (
        .aclk            (clk_i),
        .aresetn         (rst_ni),
        .s_axis_tdata    (s_axis_tdata),
        .s_axis_tvalid   (s_axis_tvalid),
        .s_axis_tready   (s_axis_tready),
        .s_axis_tlast    (s_axis_tlast),
        
        .sram_we         (rx_sram_we),
        .sram_w_addr     (rx_sram_w_addr),
        .sram_w_data     (rx_sram_w_data),
        .rx_matrix_done  (rx_matrix_done_wire)
    );

    // ========================================================
    // 4. AXI-Stream Transmitter (Array -> DMA)
    // ========================================================
    axis_tx u_axis_tx (
        .aclk            (clk_i),
        .aresetn         (rst_ni),
        .array_o_valid   (array_o_valid_wire),
        .array_o_psum    (array_o_psum_packed_aligned),
        
        .m_axis_tdata    (m_axis_tdata),
        .m_axis_tvalid   (m_axis_tvalid),
        .m_axis_tready   (m_axis_tready),
        .m_axis_tlast    (m_axis_tlast)
    );

    // ========================================================
    // 5. 4KB SRAM Subsystem
    // ========================================================
    logic [7:0]   sram_addr;
    logic [127:0] sram_write_mask;
    
    // Address muxing (Write takes priority in a single-port memory)
    assign sram_addr = sram_we_mux ? sram_w_addr_mux : sram_r_addr_mux;
    
    // 128-bit Active-Low Write Enable Mask (0 = Write, 1 = Read/Idle)
    assign sram_write_mask = sram_we_mux ? 128'h0 : {128{1'b1}};

    sram_subsystem_16bank u_sram_4kb (
        .clk  (clk_i),
        .cen  (~(sram_we_mux | sram_re_mux)), // Active-Low chip enable
        .gwen (~sram_we_mux),                 // Active-Low global write enable
        .wen  (sram_write_mask),              // Active-Low bit-write mask
        .addr (sram_addr),
        .din  (sram_w_data_mux),
        .dout (sram_r_data_out)
    );

    // ========================================================
    // 6. The 256-PE Systolic Array Math Core
    // ========================================================
    systolic_array_16x16 u_systolic_array (
        .clk                 (clk_i),
        .rst                 (rst_i),
        .i_load_weight_valid (array_load_w_valid_mux),
        .i_compute_valid     (array_comp_valid_mux),
        .i_w                 (array_w_in_unpacked),
        .i_a                 (array_a_in_unpacked),
        
        .o_weight_locked     (array_w_locked_wire),
        .o_valid             (array_o_valid_early),
        .o_psum              (array_o_psum_unpacked)
    );

    // ========================================================
    // 7. BIST / DFT Top Controller
    // ========================================================
    bist_top_controller #(
        .LBIST_CYCLES(10000)
    ) u_bist_ctrl (
        .clk                 (clk_i),
        .rst_n               (rst_ni),
        .bist_start          (bist_start_sync2),
        .bist_done           (bist_done_o),
        .bist_fail           (bist_fail_o),
        .expected_misr_sig   (expected_misr_sig_i),
        
        .mbist_we            (mbist_we_wire),
        .mbist_re            (mbist_re_wire),
        .mbist_w_addr        (mbist_w_addr_wire),
        .mbist_r_addr        (mbist_r_addr_wire),
        .mbist_w_data_128b   (mbist_w_data_wire),
        .sram_r_data_128b    (sram_r_data_out),
        
        .lfsr_prpg_out       (lfsr_prpg_out_wire),
        .array_results_in    (array_o_psum_packed)
    );

endmodule
