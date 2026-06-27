package dpi_pkg;
    // DPI-C Import for bit-accurate 16x16 Matrix Multiplication Golden Model
    
    // The C++ function expects flattened arrays.
    // SystemVerilog 'byte' maps to C++ 'int8_t'
    // SystemVerilog 'int' maps to C++ 'int32_t'
    
    import "DPI-C" function void sysmac_golden_matmul(
        input  byte act_mat [256],
        input  byte wgt_mat [256],
        output int  res_mat [256]
    );

    // Convenience wrapper task to convert 2D matrices to 1D and back
    task call_golden_model(
        input  byte act_2d [16][16],
        input  byte wgt_2d [16][16],
        output int  res_2d [16][16]
    );
        byte act_flat [256];
        byte wgt_flat [256];
        int  res_flat [256];

        // Flatten
        for (int i=0; i<16; i++) begin
            for (int j=0; j<16; j++) begin
                act_flat[i*16 + j] = act_2d[i][j];
                wgt_flat[i*16 + j] = wgt_2d[i][j];
            end
        end

        // Call DPI-C
        sysmac_golden_matmul(act_flat, wgt_flat, res_flat);

        // Reshape
        for (int i=0; i<16; i++) begin
            for (int j=0; j<16; j++) begin
                res_2d[i][j] = res_flat[i*16 + j];
            end
        end
    endtask

endpackage
