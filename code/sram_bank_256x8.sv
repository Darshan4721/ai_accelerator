// Parameterized Synchronous SRAM Bank
// Optimized for 45nm GPDK (Behavioral for simulation)
module sram_bank_256x8 #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 256
) (
    input  logic                   clk,
    input  logic                   we,     // Write Enable
    input  logic                   re,     // Read Enable
    input  logic [ADDR_WIDTH-1:0]  w_addr, // Write Address
    input  logic [ADDR_WIDTH-1:0]  r_addr, // Read Address
    input  logic [DATA_WIDTH-1:0]  w_data, // Write Data
    output logic [DATA_WIDTH-1:0]  r_data  // Read Data
);

    logic [DATA_WIDTH-1:0] ram [0:DEPTH-1];

    always_ff @(posedge clk) begin
        if (we) begin
            ram[w_addr] <= w_data;
        end
        
        if (re) begin
            // RAW Hazard Resolution: Write-First Bypass
            if (we && (w_addr == r_addr)) begin
                r_data <= w_data;
            end else begin
                r_data <= ram[r_addr];
            end
        end
    end

endmodule
