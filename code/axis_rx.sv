`timescale 1ns/1ps

module axis_rx (
    input  logic         aclk,
    input  logic         aresetn,
    
    // AXI-Stream Slave Interface
    input  logic [127:0] s_axis_tdata,
    input  logic         s_axis_tvalid,
    output logic         s_axis_tready,
    input  logic         s_axis_tlast,
    
    // SRAM Interface
    output logic         sram_we,
    output logic [7:0]   sram_w_addr,
    output logic [127:0] sram_w_data,
    
    // Controller Interface
    output logic         rx_matrix_done
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
    // 2. Skid Buffer Logic
    // --------------------------------------------------------
    // A standard 1-stage skid buffer ensures s_axis_tready has no 
    // combinatorial dependence on s_axis_tvalid.
    
    logic [127:0] skid_data;
    logic         skid_last;
    logic         skid_valid;
    logic         skid_ready; // Internal ready
    
    // The skid buffer absorbs 1 cycle of data if the internal pipeline stalls
    always_ff @(posedge aclk) begin
        if (rst) begin
            skid_valid <= 1'b0;
            skid_data  <= 128'h0;
            skid_last  <= 1'b0;
            s_axis_tready <= 1'b1; // Default to ready
        end else begin
            if (s_axis_tready && s_axis_tvalid) begin
                if (!skid_ready) begin
                    // Internal is stalled, skid buffer catches data
                    skid_valid <= 1'b1;
                    skid_data  <= s_axis_tdata;
                    skid_last  <= s_axis_tlast;
                    s_axis_tready <= 1'b0; // Drop ready to pause AXI stream
                end
            end else if (skid_ready && skid_valid) begin
                // Internal accepts data, clear skid buffer
                skid_valid <= 1'b0;
                s_axis_tready <= 1'b1; // Re-open AXI stream
            end
        end
    end

    // Muxing logic for what goes to the SRAM:
    // If skid buffer is valid, output it. Else, pass-through if ready.
    logic [127:0] internal_data;
    logic         internal_valid;
    logic         internal_last;
    
    assign internal_data  = skid_valid ? skid_data : s_axis_tdata;
    assign internal_valid = skid_valid ? 1'b1 : (s_axis_tvalid && s_axis_tready);
    assign internal_last  = skid_valid ? skid_last : s_axis_tlast;
    
    // In this simplified block, the SRAM is always ready to write.
    // So skid_ready is always 1, meaning we never actually need to stall the AXI bus.
    assign skid_ready = 1'b1; 

    // --------------------------------------------------------
    // 3. SRAM Write & Address Counter
    // --------------------------------------------------------
    logic [7:0] addr_cnt;
    always_ff @(posedge aclk) begin
        if (rst) begin
            addr_cnt <= 8'h0;
            sram_w_addr <= 8'h0;
            sram_we <= 1'b0;
            sram_w_data <= 128'h0;
            rx_matrix_done <= 1'b0;
        end else begin
            rx_matrix_done <= 1'b0; // Default pulse low
            sram_we <= 1'b0;
            
            if (internal_valid && skid_ready) begin
                sram_we <= 1'b1;
                sram_w_data <= internal_data;
                sram_w_addr <= addr_cnt;
                
                if (internal_last) begin
                    addr_cnt <= (addr_cnt == 8'd31) ? 8'h0 : (addr_cnt + 1);
                    // ONLY pulse done when the full 32-row payload (W + A) is loaded.
                    rx_matrix_done <= (addr_cnt == 8'd31) ? 1'b1 : 1'b0;
                end else begin
                    addr_cnt <= addr_cnt + 1;
                end
            end
        end
    end

    // --------------------------------------------------------
    // 4. Embedded Functional Coverage Hooks (SVA)
    // --------------------------------------------------------
`ifndef SYNTHESIS
    property p_axi_tdata_stable;
        @(posedge aclk) disable iff (!aresetn)
        (s_axis_tvalid && !s_axis_tready) |=> ($stable(s_axis_tdata) && s_axis_tvalid);
    endproperty

    assert property (p_axi_tdata_stable) else $error("AXI RX Violation: tdata changed while stalled!");
    cover property (p_axi_tdata_stable);
`endif

endmodule
