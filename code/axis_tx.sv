`timescale 1ns/1ps

module axis_tx (
    input  logic         aclk,
    input  logic         aresetn,
    
    // Array Interface
    input  logic         array_o_valid,
    input  logic [511:0] array_o_psum,
    
    // AXI-Stream Master Interface
    output logic [511:0] m_axis_tdata,
    output logic         m_axis_tvalid,
    input  logic         m_axis_tready,
    output logic         m_axis_tlast
);

    // --------------------------------------------------------
    // 1. Reset Synchronization (aresetn -> rst)
    // --------------------------------------------------------
    logic rst_sync1, rst_sync2;
    logic rst; // Internal synchronous active-high reset
    
    always_ff @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            rst_sync1 <= 1'b1;
            rst_sync2 <= 1'b1;
        end else begin
            rst_sync1 <= 1'b0;
            rst_sync2 <= rst_sync1;
        end
    end
    assign rst = rst_sync2;

    // --------------------------------------------------------
    // 2. Synchronous Output FIFO
    // --------------------------------------------------------
    // The systolic array cannot stall, so we use a FIFO to catch data
    // if the AXI Master stalls.
    localparam FIFO_DEPTH = 32;
    logic [511:0] fifo_mem [0:FIFO_DEPTH-1];
    logic [5:0]   wr_ptr;
    logic [5:0]   rd_ptr;
    logic [5:0]   fifo_count;
    
    logic fifo_full;
    logic fifo_empty;
    
    assign fifo_full  = (fifo_count == FIFO_DEPTH);
    assign fifo_empty = (fifo_count == 0);
    
    logic fifo_push;
    logic fifo_pop;
    
    assign fifo_push = array_o_valid && !fifo_full;
    assign fifo_pop  = m_axis_tready && !fifo_empty;
    
    always_ff @(posedge aclk) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            fifo_count <= 0;
        end else begin
            case ({fifo_push, fifo_pop})
                2'b10: begin
                    fifo_mem[wr_ptr] <= array_o_psum;
                    wr_ptr <= (wr_ptr == FIFO_DEPTH-1) ? 0 : wr_ptr + 1;
                    fifo_count <= fifo_count + 1;
                end
                2'b01: begin
                    rd_ptr <= (rd_ptr == FIFO_DEPTH-1) ? 0 : rd_ptr + 1;
                    fifo_count <= fifo_count - 1;
                end
                2'b11: begin
                    fifo_mem[wr_ptr] <= array_o_psum;
                    wr_ptr <= (wr_ptr == FIFO_DEPTH-1) ? 0 : wr_ptr + 1;
                    rd_ptr <= (rd_ptr == FIFO_DEPTH-1) ? 0 : rd_ptr + 1;
                    // fifo_count remains the same
                end
            endcase
        end
    end
    
    logic [511:0] fifo_rdata;
    assign fifo_rdata = fifo_mem[rd_ptr];

    // --------------------------------------------------------
    // 3. AXI Driving & TLAST Generation
    // --------------------------------------------------------
    logic [3:0] pop_counter;
    
    always_ff @(posedge aclk) begin
        if (rst) begin
            pop_counter <= 4'h0;
        end else begin
            if (fifo_pop) begin
                pop_counter <= pop_counter + 1;
            end
        end
    end

    // Combinational AXI Driving
    assign m_axis_tvalid = !fifo_empty;
    assign m_axis_tdata  = fifo_rdata;
    assign m_axis_tlast  = (pop_counter == 4'd15); // On the 16th valid handshake

    // --------------------------------------------------------
    // 4. Embedded Functional Coverage Hooks (SVA)
    // --------------------------------------------------------
`ifndef SYNTHESIS
    property p_axi_tx_tdata_stable;
        @(posedge aclk) disable iff (!aresetn)
        (m_axis_tvalid && !m_axis_tready) |=> ($stable(m_axis_tdata) && m_axis_tvalid);
    endproperty

    assert property (p_axi_tx_tdata_stable) else $error("AXI TX Violation: tdata changed while stalled!");
    cover property (p_axi_tx_tdata_stable);
`endif

endmodule
