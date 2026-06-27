`timescale 1ns/1ps

module axi_lite_config (
    input  logic        clk,
    input  logic        rst, // Synchronous Active-High Reset
    
    // --------------------------------------------------------
    // Custom Accelerator Control Plane
    // --------------------------------------------------------
    output logic        start_compute,
    input  logic        mac_done,
    input  logic        rx_matrix_done,
    input  logic        wt_locked,
    
    // --------------------------------------------------------
    // AXI4-Lite Slave Interface
    // --------------------------------------------------------
    // Write Address Channel (AW)
    input  logic [31:0] s_axi_awaddr,
    input  logic        s_axi_awvalid,
    output logic        s_axi_awready,
    
    // Write Data Channel (W)
    input  logic [31:0] s_axi_wdata,
    input  logic        s_axi_wvalid,
    output logic        s_axi_wready,
    
    // Write Response Channel (B)
    output logic [1:0]  s_axi_bresp,
    output logic        s_axi_bvalid,
    input  logic        s_axi_bready,
    
    // Read Address Channel (AR)
    input  logic [31:0] s_axi_araddr,
    input  logic        s_axi_arvalid,
    output logic        s_axi_arready,
    
    // Read Data Channel (R)
    output logic [31:0] s_axi_rdata,
    output logic [1:0]  s_axi_rresp,
    output logic        s_axi_rvalid,
    input  logic        s_axi_rready
);

    // --------------------------------------------------------
    // 1. Write Channel FSM (Independent)
    // --------------------------------------------------------
    typedef enum logic [1:0] {
        S_WR_IDLE    = 2'b00,
        S_WR_PROCESS = 2'b01,
        S_WR_RESP    = 2'b10
    } wr_state_t;
    
    wr_state_t wr_state;
    logic [31:0] latched_awaddr;
    logic [31:0] latched_wdata;
    
    always_ff @(posedge clk) begin
        if (rst) begin
            wr_state       <= S_WR_IDLE;
            s_axi_awready  <= 1'b0;
            s_axi_wready   <= 1'b0;
            s_axi_bvalid   <= 1'b0;
            s_axi_bresp    <= 2'b00;
            start_compute  <= 1'b0;
            latched_awaddr <= 32'h0;
            latched_wdata  <= 32'h0;
        end else begin
            // Default Auto-Clears
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            start_compute <= 1'b0; // Ensures 1-cycle exact pulse
            
            case (wr_state)
                S_WR_IDLE: begin
                    if (s_axi_awvalid && s_axi_wvalid) begin
                        latched_awaddr <= s_axi_awaddr;
                        latched_wdata  <= s_axi_wdata;
                        wr_state       <= S_WR_PROCESS;
                    end
                end
                
                S_WR_PROCESS: begin
                    // Acknowledge the address and data
                    s_axi_awready <= 1'b1;
                    s_axi_wready  <= 1'b1;
                    
                    // Address Decoding & Trigger Generation
                    if (latched_awaddr == 32'h00) begin
                        if (latched_wdata[0] == 1'b1) begin
                            start_compute <= 1'b1; // Trigger generated out of D-FF
                        end
                    end
                    // If address is unmapped, we silently drop the data (No trigger)
                    
                    wr_state <= S_WR_RESP;
                end
                
                S_WR_RESP: begin
                    // Setup Response
                    if (!s_axi_bvalid) begin
                        s_axi_bvalid <= 1'b1;
                        s_axi_bresp  <= 2'b00; // OKAY status
                    end
                    
                    // Wait for Master to acknowledge response
                    if (s_axi_bvalid && s_axi_bready) begin
                        s_axi_bvalid <= 1'b0;
                        wr_state     <= S_WR_IDLE;
                    end
                end
                
                default: wr_state <= S_WR_IDLE;
            endcase
        end
    end

    // --------------------------------------------------------
    // Sticky Register Logic for 1-cycle pulses
    // --------------------------------------------------------
    logic sticky_rx_done;

    always_ff @(posedge clk) begin
        if (rst) begin
            sticky_rx_done <= 1'b0;
        end else begin
            // 1. Hardware sets the flag on the 1-cycle pulse from axis_rx
            if (rx_matrix_done) begin
                sticky_rx_done <= 1'b1;
            end
            
            // 2. Software clears the flag when writing to the Control Register (0x00)
            if (wr_state == S_WR_PROCESS && latched_awaddr == 32'h00 && latched_wdata[0] == 1'b1) begin
                sticky_rx_done <= 1'b0;
            end
        end
    end

    // --------------------------------------------------------
    // 2. Read Channel FSM (Independent)
    // --------------------------------------------------------
    typedef enum logic [1:0] {
        S_RD_IDLE    = 2'b00,
        S_RD_PROCESS = 2'b01,
        S_RD_DATA    = 2'b10
    } rd_state_t;
    
    rd_state_t rd_state;
    logic [31:0] latched_araddr;
    
    always_ff @(posedge clk) begin
        if (rst) begin
            rd_state       <= S_RD_IDLE;
            s_axi_arready  <= 1'b0;
            s_axi_rvalid   <= 1'b0;
            s_axi_rdata    <= 32'h0;
            s_axi_rresp    <= 2'b00;
            latched_araddr <= 32'h0;
        end else begin
            // Default Auto-Clears
            s_axi_arready <= 1'b0;
            
            case (rd_state)
                S_RD_IDLE: begin
                    if (s_axi_arvalid) begin
                        latched_araddr <= s_axi_araddr;
                        rd_state       <= S_RD_PROCESS;
                    end
                end
                
                S_RD_PROCESS: begin
                    // Acknowledge the address
                    s_axi_arready <= 1'b1;
                    
                    // Address Decoding & Data Fetching
                    if (latched_araddr == 32'h04) begin
                        // Map Status Reg: Bit 2: RX_DONE | Bit 1: MAC_DONE | Bit 0: WT_LOCKED
                        s_axi_rdata <= {29'b0, sticky_rx_done, mac_done, wt_locked};
                    end else begin
                        // Unmapped Address Protection: Return all zeroes
                        s_axi_rdata <= 32'h0;
                    end
                    
                    rd_state <= S_RD_DATA;
                end
                
                S_RD_DATA: begin
                    if (!s_axi_rvalid) begin
                        // Setup Data Response
                        s_axi_rvalid <= 1'b1;
                        s_axi_rresp  <= 2'b00; // OKAY status
                    end
                    
                    // Wait for Master to acknowledge data
                    if (s_axi_rvalid && s_axi_rready) begin
                        s_axi_rvalid <= 1'b0;
                        rd_state     <= S_RD_IDLE;
                    end
                end
                
                default: rd_state <= S_RD_IDLE;
            endcase
        end
    end

endmodule
