// Memory BIST (MBIST) Engine implementing the March-C Lite Algorithm
// Algorithm: {w0}up; {r0, w1}up; {r1, w0}down
module mbist_march_c (
    input  logic         clk,
    input  logic         rst,
    
    // BIST Control
    input  logic         mbist_en,
    output logic         mbist_done,
    output logic         mbist_fail,
    
    // SRAM Interface
    output logic         mbist_we,
    output logic         mbist_re,
    output logic [7:0]   mbist_w_addr,
    output logic [7:0]   mbist_r_addr,
    output logic [127:0] mbist_w_data_128b,
    input  logic [127:0] sram_r_data_128b
);

    typedef enum logic [2:0] {
        IDLE            = 3'd0,
        INIT_0_ASC      = 3'd1,
        R0_W1_ASC       = 3'd2,
        R1_W0_DESC      = 3'd3,
        DONE            = 3'd4
    } state_t;

    state_t state;

    logic [8:0] addr_ptr;   // 9-bit to allow 0-256 and underflow logic for loop tracking
    logic [7:0] req_addr;   // Address of current read request
    logic [7:0] check_addr; // Address of data currently arriving
    logic       read_req;   // True if we requested a read LAST cycle
    logic       read_pending; // True if data is arriving THIS cycle

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            addr_ptr <= 0;
            req_addr <= 0;
            check_addr <= 0;
            read_req <= 0;
            read_pending <= 0;
            
            mbist_we <= 0;
            mbist_re <= 0;
            mbist_w_addr <= 0;
            mbist_r_addr <= 0;
            mbist_w_data_128b <= 0;
            
            mbist_done <= 0;
            mbist_fail <= 0;
        end else begin
            // Default assignments to clear strobes
            mbist_we <= 0;
            mbist_re <= 0;
            
            case (state)
                IDLE: begin
                    mbist_done <= 0;
                    // mbist_fail remains sticky until hard reset
                    read_req <= 0;
                    read_pending <= 0;
                    if (mbist_en) begin
                        state <= INIT_0_ASC;
                        addr_ptr <= 0;
                    end
                end

                INIT_0_ASC: begin // Phase 1: Sweep ascending, Write 0s
                    mbist_we <= 1;
                    mbist_w_addr <= addr_ptr[7:0];
                    mbist_w_data_128b <= 128'h0;
                    
                    if (addr_ptr == 9'd255) begin
                        state <= R0_W1_ASC;
                        addr_ptr <= 0;
                    end else begin
                        addr_ptr <= addr_ptr + 1;
                    end
                end

                R0_W1_ASC: begin // Phase 2: Sweep ascending, Read 0, Write 1
                    // Pipeline Stage 3: Check & Write
                    if (read_pending) begin
                        if (sram_r_data_128b !== 128'h0) mbist_fail <= 1; // Instant latch on mismatch
                        mbist_we <= 1;
                        mbist_w_addr <= check_addr;
                        mbist_w_data_128b <= {128{1'b1}};
                    end
                    
                    // Pipeline Stage 2: Wait for SRAM
                    read_pending <= read_req;
                    check_addr <= req_addr;
                    
                    // Pipeline Stage 1: Request Read
                    if (addr_ptr <= 9'd255) begin
                        mbist_re <= 1;
                        mbist_r_addr <= addr_ptr[7:0];
                        req_addr <= addr_ptr[7:0];
                        read_req <= 1;
                        addr_ptr <= addr_ptr + 1;
                    end else begin
                        read_req <= 0;
                        if (!read_pending && !read_req) begin
                            // Pipeline completely drained
                            state <= R1_W0_DESC;
                            addr_ptr <= 9'd255; // Prepare for descending sweep
                        end
                    end
                end

                R1_W0_DESC: begin // Phase 3: Sweep descending, Read 1, Write 0
                    // Pipeline Stage 3: Check & Write
                    if (read_pending) begin
                        if (sram_r_data_128b !== {128{1'b1}}) mbist_fail <= 1; // Instant latch on mismatch
                        mbist_we <= 1;
                        mbist_w_addr <= check_addr;
                        mbist_w_data_128b <= 128'h0;
                    end
                    
                    // Pipeline Stage 2: Wait for SRAM
                    read_pending <= read_req;
                    check_addr <= req_addr;
                    
                    // Pipeline Stage 1: Request Read
                    if (addr_ptr <= 9'd255) begin 
                        mbist_re <= 1;
                        mbist_r_addr <= addr_ptr[7:0];
                        req_addr <= addr_ptr[7:0];
                        read_req <= 1;
                        addr_ptr <= addr_ptr - 1;
                    end else begin
                        read_req <= 0;
                        if (!read_pending && !read_req) begin
                            // Pipeline drained
                            state <= DONE;
                        end
                    end
                end

                DONE: begin
                    mbist_done <= 1;
                    if (!mbist_en) begin
                        state <= IDLE; // Return to idle when host acknowledges
                    end
                end
            endcase
        end
    end

endmodule
