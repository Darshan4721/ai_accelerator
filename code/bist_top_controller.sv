`timescale 1ns/1ps

module bist_top_controller #(
    parameter LBIST_CYCLES = 10000
)(
    input  logic         clk,
    input  logic         rst_n,
    
    // Global BIST Control
    input  logic         bist_start,
    output logic         bist_done,
    output logic         bist_fail,
    input  logic [511:0] expected_misr_sig,
    
    // SRAM Interface (Routed from internal MBIST)
    output logic         mbist_we,
    output logic         mbist_re,
    output logic [7:0]   mbist_w_addr,
    output logic [7:0]   mbist_r_addr,
    output logic [127:0] mbist_w_data_128b,
    input  logic [127:0] sram_r_data_128b,
    
    // Compute Core Interface
    output logic [127:0] lfsr_prpg_out,
    input  logic [511:0] array_results_in
);

    // --------------------------------------------------------
    // INTERNAL SIGNALS
    // --------------------------------------------------------
    logic mbist_en, mbist_done_int, mbist_fail_int;
    logic lfsr_en;
    logic misr_en;
    
    logic [127:0] lfsr_seed = 128'hDEADBEEF;
    logic [511:0] misr_signature;
    
    // --------------------------------------------------------
    // SUB-MODULE INSTANTIATIONS
    // --------------------------------------------------------
    
    mbist_march_c u_mbist (
        .clk(clk),
        .rst_n(rst_n),
        .mbist_en(mbist_en),
        .mbist_done(mbist_done_int),
        .mbist_fail(mbist_fail_int),
        
        .mbist_we(mbist_we),
        .mbist_re(mbist_re),
        .mbist_w_addr(mbist_w_addr),
        .mbist_r_addr(mbist_r_addr),
        .mbist_w_data_128b(mbist_w_data_128b),
        .sram_r_data_128b(sram_r_data_128b)
    );
    
    lfsr_prpg u_lfsr (
        .clk(clk),
        .rst_n(rst_n),
        .en(lfsr_en),
        .seed(lfsr_seed),
        .prpg_out(lfsr_prpg_out)
    );
    
    misr_compressor u_misr (
        .clk(clk),
        .rst_n(rst_n),
        .en(misr_en),
        .data_in(array_results_in),
        .signature(misr_signature)
    );

    // --------------------------------------------------------
    // FSM LOGIC
    // --------------------------------------------------------
    typedef enum logic [2:0] {
        S_IDLE        = 3'd0,
        S_RUN_MBIST   = 3'd1,
        S_RUN_LBIST   = 3'd2,
        S_CHECK_LBIST = 3'd3,
        S_DONE        = 3'd4
    } state_t;
    
    state_t state;
    logic [31:0] lbist_counter;
    logic latched_mbist_fail;
    logic latched_lbist_fail;
    
    // As per the specification, this is evaluated continuously and latched into the outputs at S_DONE
    // Or we can drive bist_fail directly as an assign if the module allows, but since it's an output logic,
    // we will drive it in the S_DONE state using this logic.

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
            mbist_en <= 0;
            lfsr_en <= 0;
            misr_en <= 0;
                    bist_done <= 0;
                    bist_fail <= 0;
                    lbist_counter <= 0;
                    latched_mbist_fail <= 0;
                    latched_lbist_fail <= 0;
                end else begin
                    case (state)
                        S_IDLE: begin
                            mbist_en <= 0;
                            lfsr_en <= 0;
                            misr_en <= 0;
                            bist_done <= 0;
                            bist_fail <= 0;
                            lbist_counter <= 0;
                            latched_mbist_fail <= 0;
                            latched_lbist_fail <= 0;
                            
                            if (bist_start) begin
                        state <= S_RUN_MBIST;
                    end
                end
                
                S_RUN_MBIST: begin
                    mbist_en <= 1;
                    if (mbist_done_int) begin
                        mbist_en <= 0;
                        latched_mbist_fail <= mbist_fail_int;
                        state <= S_RUN_LBIST;
                    end
                end
                
                S_RUN_LBIST: begin
                    lfsr_en <= 1;
                    misr_en <= 1;
                    
                    if (lbist_counter == LBIST_CYCLES - 1) begin
                        lfsr_en <= 0;
                        misr_en <= 0;
                        lbist_counter <= 0;
                        state <= S_CHECK_LBIST;
                    end else begin
                        lbist_counter <= lbist_counter + 1;
                    end
                end
                
                S_CHECK_LBIST: begin
                    // LFSR/MISR are disabled. Compare signature strictly in this 1 cycle window.
                    if (misr_signature !== expected_misr_sig) begin
                        latched_lbist_fail <= 1;
                    end else begin
                        latched_lbist_fail <= 0;
                    end
                    state <= S_DONE;
                end
                
                S_DONE: begin
                    bist_done <= 1;
                    // The OR gate evaluates the failure correctly
                    if (latched_mbist_fail | latched_lbist_fail) begin
                        bist_fail <= 1;
                    end else begin
                        bist_fail <= 0;
                    end
                end
                
                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
