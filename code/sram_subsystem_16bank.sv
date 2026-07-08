// 16-Bank SRAM Subsystem with Flat Addressing
// Feeds 128-bit wide data (16x8b) into the Systolic Array Input Wedge
module sram_subsystem_16bank (
    input  logic         clk,
    input  logic         rst_n,
    input  logic         en,            // Subsystem Enable (Chip Select)
    input  logic         we,            // Global Write Enable
    input  logic         re,            // Global Read Enable
    input  logic [7:0]   w_base_addr,   // Write Base Address
    input  logic [7:0]   r_base_addr,   // Read Base Address
    input  logic [127:0] w_data_128b,   // 16 bytes of incoming flat data
    output logic [127:0] r_data_flat_128b // 16 bytes of outgoing flat data
);

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_banks
            sram_bank_256x8 bank_inst (
                .clk(clk),
                .we(we & en), // Gate write with chip select
                .re(re & en), // Gate read with chip select
                .w_addr(w_base_addr), // Flat addressing: all banks get same write address
                .r_addr(r_base_addr), // Flat addressing: all banks get same read address
                .w_data(w_data_128b[i*8 +: 8]),
                .r_data(r_data_flat_128b[i*8 +: 8])
            );
        end
    endgenerate

endmodule
