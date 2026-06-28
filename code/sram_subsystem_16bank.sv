`timescale 1ns/1ps

module sram_subsystem_16bank (
    input  logic         clk,
    input  logic         cen,      // Active-low Chip Enable
    input  logic         gwen,     // Active-low Global Write Enable
    input  logic [127:0] wen,      // Active-low Bit-Write Enable mask (128 bits)
    input  logic [7:0]   addr,     // 8-bit Address (for 256 depth)
    input  logic [127:0] din,      // 128-bit Data In  (16 x 8-bit weights)
    output logic [127:0] dout      // 128-bit Data Out (16 x 8-bit weights)
);

    genvar i;
    generate
        // Instantiate 16 of the 8-bit GF180 macros in parallel to create a 128-bit bus
        for (i = 0; i < 16; i = i + 1) begin : sram_array
            gf180mcu_fd_ip_sram__sram256x8m8wm1 u_sram_8bit (
                .CLK  (clk),
                .CEN  (cen),
                .GWEN (gwen),
                .WEN  (wen[(i*8)+7 : i*8]), // Slice 8 bits of Write Enable per macro
                .A    (addr),
                .D    (din[(i*8)+7 : i*8]), // Slice 8 bits of Data In per macro
                .Q    (dout[(i*8)+7 : i*8]) // Slice 8 bits of Data Out per macro
                
                // Note: VDD and VSS are intentionally left unconnected in the RTL.
                // .VDD  (),
                // .VSS  ()
            );
        end
    endgenerate

endmodule
