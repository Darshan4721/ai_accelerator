`ifndef CORE_FSM_CTRL_SV
`define CORE_FSM_CTRL_SV

module core_fsm_ctrl (
    input  logic         clk,
    input  logic         rst, // Synchronous active-high reset
    
    // AXI-Lite Control Plane Interface
    input  logic         start_compute,
    output logic         mac_done,
    
    // SRAM Subsystem Interface
    output logic         sram_re,
    output logic [7:0]   sram_r_addr,
    input  logic [127:0] sram_r_data,
    
    // Systolic Array Interface
    output logic         array_load_weight_valid,
    output logic         array_compute_valid,
    output logic [127:0] array_w_in,
    output logic [127:0] array_a_in,
    input  logic         array_weight_locked
);

    // -------------------------------------------------------------------------
    // 1. Pass-Through Datapath
    // -------------------------------------------------------------------------
    // Data passes directly from SRAM to Array. Alignment is handled by the valid 
    // control signals and the array's input skewer (Wedge Formatter).
    assign array_w_in = sram_r_data;
    assign array_a_in = sram_r_data;

    // -------------------------------------------------------------------------
    // 2. UVM-Compliant FSM Encoding
    // -------------------------------------------------------------------------
    typedef enum logic [1:0] {
        S_IDLE         = 2'b00,
        S_LOAD_WEIGHTS = 2'b01,
        S_COMPUTE      = 2'b10,
        S_DRAIN        = 2'b11
    } state_t;

    state_t current_state, next_state;
    
    // Internal Counters
    logic [7:0] addr_cnt;
    logic [5:0] drain_cnt;

    // -------------------------------------------------------------------------
    // Block 1: State Register (Synchronous)
    // -------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst) begin
            current_state <= S_IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // -------------------------------------------------------------------------
    // Block 2: Next State Logic (Combinational)
    // -------------------------------------------------------------------------
    always_comb begin
        next_state = current_state; // Default hold state
        case (current_state)
            S_IDLE: begin
                if (start_compute) begin
                    next_state = S_LOAD_WEIGHTS;
                end
            end
            
            S_LOAD_WEIGHTS: begin
                // Transition only after finishing reading all 16 rows (addr 15) AND array locks
                if (addr_cnt == 16 && array_weight_locked) begin
                    next_state = S_COMPUTE;
                end
            end
            
            S_COMPUTE: begin
                // Transition instantly after fetching the final activation row (addr 31)
                if (addr_cnt == 32) begin
                    next_state = S_DRAIN;
                end
            end
            
            S_DRAIN: begin
                // Wait exactly 48 cycles (0 to 47 inclusive) for the final row to drain
                if (drain_cnt == 47) begin
                    next_state = S_IDLE;
                end else begin
                    next_state = S_DRAIN;
                end
            end
            
            default: next_state = S_IDLE;
        endcase
    end

    // -------------------------------------------------------------------------
    // Block 3: Registered Outputs & Counters (Synchronous)
    // -------------------------------------------------------------------------
    // This block satisfies the strict ASIC Timing (Registered Outputs) and 
    // SRAM Power (Clock Gating) rules. It cleanly evaluates `next_state` to 
    // seamlessly pipeline memory addresses without 1-cycle hesitation.
    always_ff @(posedge clk) begin
        if (rst) begin
            addr_cnt                <= 8'd0;
            drain_cnt               <= 6'd0;
            mac_done                <= 1'b0;
            sram_re                 <= 1'b0;
            sram_r_addr             <= 8'd0;
            array_load_weight_valid <= 1'b0;
            array_compute_valid     <= 1'b0;
        end else begin
            
            // -----------------------------------------------------------------
            // Rule A: The 1-Cycle SRAM Read Latency Pipeline
            // By assigning valid flags combinationally based on the *previous* 
            // clock cycle's registered state of `sram_re` and `sram_r_addr`, 
            // we perfectly delay the valid flags by exactly 1 cycle.
            // -----------------------------------------------------------------
            array_load_weight_valid <= (current_state == S_LOAD_WEIGHTS) && sram_re && (sram_r_addr < 8'd16);
            array_compute_valid     <= (sram_re && sram_r_addr >= 16);
            
            // -----------------------------------------------------------------
            // Next State Output Evaluations
            // -----------------------------------------------------------------
            case (next_state)
                S_IDLE: begin
                    // Aggressive power clamping
                    sram_re   <= 1'b0;
                    addr_cnt  <= 8'd0;
                    drain_cnt <= 6'd0;
                    
                    // Assert sticky mac_done when we successfully drain.
                    if (current_state == S_DRAIN) begin
                        mac_done <= 1'b1;
                    end
                end

                S_LOAD_WEIGHTS: begin
                    if (current_state == S_IDLE) begin
                        // Entry Cycle: Start sweep immediately
                        sram_re     <= 1'b1;
                        sram_r_addr <= 8'd0;
                        addr_cnt    <= 8'd1;
                        mac_done    <= 1'b0; // Clear the sticky flag from last run
                    end else if (addr_cnt < 16) begin
                        // Sweeping Addrs 1 to 15
                        sram_re     <= 1'b1;
                        sram_r_addr <= addr_cnt;
                        addr_cnt    <= addr_cnt + 1;
                    end else begin
                        // Addr 15 fetched. Clamp power and wait for array lock flag
                        sram_re <= 1'b0;
                    end
                end

                S_COMPUTE: begin
                    if (current_state == S_LOAD_WEIGHTS) begin
                        // Entry Cycle: Start activation sweep immediately
                        sram_re     <= 1'b1;
                        sram_r_addr <= 8'd16;
                        addr_cnt    <= 8'd17;
                    end else if (addr_cnt < 32) begin
                        // Sweeping Addrs 17 to 31
                        sram_re     <= 1'b1;
                        sram_r_addr <= addr_cnt;
                        addr_cnt    <= addr_cnt + 1;
                    end else begin
                        // Failsafe clamp
                        sram_re <= 1'b0;
                    end
                end

                S_DRAIN: begin
                    // Clamp SRAM power immediately. SRAM is inactive during Drain phase.
                    sram_re   <= 1'b0;
                    drain_cnt <= drain_cnt + 1;
                end
                
                default: begin
                    sram_re <= 1'b0;
                end
            endcase
        end
    end

endmodule

`endif
