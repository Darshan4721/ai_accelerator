// 16x16 Systolic Array Wrapper - The Orchestrator
`timescale 1ns/1ps

module systolic_array_16x16 (
    input  logic        clk,
    input  logic        rst,

    // Control In
    input  logic        i_load_weight_valid,
    input  logic        i_compute_valid,

    // Data In (Flat Arrays)
    input  logic [7:0]  i_w [0:15],
    input  logic [7:0]  i_a [0:15],

    // Control Out
    output logic        o_weight_locked,
    output logic        o_valid,

    // Data Out (Flat Array)
    output logic [31:0] o_psum [0:15]
);

    // -------------------------------------------------------------------------
    // Phase 1: Weight Loading Mapping
    // -------------------------------------------------------------------------
    logic        ack_weight_locked [0:15][0:15];
    
    // The entire array is locked when the bottom row (row 15) is fully locked.
    // We logically AND all ack_weight_locked signals from row 15.
    logic locked_and;
    always_comb begin
        locked_and = 1'b1;
        for (int j = 0; j < 16; j++) begin
            locked_and = locked_and & ack_weight_locked[15][j];
        end
    end
    assign o_weight_locked = locked_and;

    // -------------------------------------------------------------------------
    // Phase 2: Input Skewing (The Wedge)
    // -------------------------------------------------------------------------
    // Row `i` must be delayed by `i` clock cycles.
    logic [7:0] a_skewed    [0:15];
    logic       work_skewed [0:15];

    genvar i, j;
    generate
        for (i = 0; i < 16; i++) begin : gen_input_wedge
            if (i == 0) begin
                assign a_skewed[i]    = i_a[i];
                assign work_skewed[i] = i_compute_valid;
            end else begin
                // Shift register of depth 'i'
                logic [7:0] a_delay [1:i];
                logic       w_delay [1:i];
                
                always_ff @(posedge clk) begin
                    if (rst) begin
                        for (int k = 1; k <= i; k++) begin
                            a_delay[k] <= 8'h0;
                            w_delay[k] <= 1'b0;
                        end
                    end else begin
                        a_delay[1] <= i_a[i];
                        w_delay[1] <= i_compute_valid;
                        for (int k = 1; k < i; k++) begin
                            a_delay[k+1] <= a_delay[k];
                            w_delay[k+1] <= w_delay[k];
                        end
                    end
                end
                assign a_skewed[i]    = a_delay[i];
                assign work_skewed[i] = w_delay[i];
            end
        end
    endgenerate

    // -------------------------------------------------------------------------
    // PE Grid Instantiation
    // -------------------------------------------------------------------------
    logic [7:0]  w_wires    [0:16][0:15];
    logic        w_req_wires[0:16][0:15];
    
    logic [7:0]  a_wires    [0:15][0:16];
    logic        a_req_wires[0:15][0:16];
    
    logic [31:0] psum_wires [0:16][0:15];

    generate
        // Boundary Wiring
        for (j = 0; j < 16; j++) begin : col_boundary
            assign w_wires[0][j]     = i_w[j];
            assign w_req_wires[0][j] = i_load_weight_valid;
            assign psum_wires[0][j]  = 32'h0; // Top row receives 0 psum
        end

        for (i = 0; i < 16; i++) begin : row_boundary
            assign a_wires[i][0]     = a_skewed[i];
            assign a_req_wires[i][0] = work_skewed[i];
        end

        // PE Grid
        for (i = 0; i < 16; i++) begin : rows
            for (j = 0; j < 16; j++) begin : cols
                pe_pipelined pe_inst (
                    .clk(clk),
                    .rst(rst),
                    
                    // Control
                    .req_load_weight_in(w_req_wires[i][j]),
                    .req_work_in(a_req_wires[i][j]),
                    .req_load_weight_out(w_req_wires[i+1][j]),
                    .req_work_out(a_req_wires[i][j+1]),
                    .ack_weight_locked(ack_weight_locked[i][j]),
                    
                    // Data
                    .w_in(w_wires[i][j]),
                    .a_in(a_wires[i][j]),
                    .psum_in(psum_wires[i][j]),
                    
                    .w_out(w_wires[i+1][j]),
                    .a_out(a_wires[i][j+1]),
                    .psum_out(psum_wires[i+1][j])
                );
            end
        end
    endgenerate

    // -------------------------------------------------------------------------
    // Phase 3: Output Deskewing (The Reverse Wedge) & Valid Generation
    // -------------------------------------------------------------------------
    // Column `j` raw output emerges at cycle `32 + j` relative to Row 0 input.
    // However, it must be delayed by `15 - j` cycles to perfectly align with Column 15.
    // Total latency for all synchronized deskewed outputs is exactly 32 clock cycles!
    generate
        for (j = 0; j < 16; j++) begin : gen_output_wedge
            localparam int DELAY = 15 - j;
            
            if (DELAY == 0) begin
                assign o_psum[j] = psum_wires[16][j];
            end else begin
                // Shift register of depth 'DELAY'
                logic [31:0] psum_delay [1:DELAY];
                
                always_ff @(posedge clk) begin
                    if (rst) begin
                        for (int k = 1; k <= DELAY; k++) begin
                            psum_delay[k] <= 32'h0;
                        end
                    end else begin
                        psum_delay[1] <= psum_wires[16][j];
                        for (int k = 1; k < DELAY; k++) begin
                            psum_delay[k+1] <= psum_delay[k];
                        end
                    end
                end
                assign o_psum[j] = psum_delay[DELAY];
            end
        end
    endgenerate

    // Valid Generation: Delay i_compute_valid by 32 cycles
    logic [32:0] valid_pipe;
    assign valid_pipe[0] = i_compute_valid;

    always_ff @(posedge clk) begin
        if (rst) begin
            valid_pipe[32:1] <= 32'h0;
        end else begin
            valid_pipe[32:1] <= valid_pipe[31:0];
        end
    end
    assign o_valid = valid_pipe[32];

endmodule
