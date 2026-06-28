# ==============================================================================
# TOP TENSORCORE: UNIFIED GENUS SYNTHESIS & DFT SCRIPT
# Technology: GF180MCU (180nm) | Target Freq: 250MHz (4.0ns)
# ==============================================================================

# ------------------------------------------------------------------------------
# PHASE 1: Initialization & Library Loading
# ------------------------------------------------------------------------------
set_db / .information_level 7

# Correctly define search paths for the GF180MCU server directories
set_db / .init_lib_search_path {
    ./libs 
    /home/DARSHAN/volare/volare/gf180mcu/versions/c6d73a35f524070e85faff4a6a9eef49553ebc2b/gf180mcuD/libs.ref/gf180mcu_fd_sc_mcu7t5v0/lib 
    /home/DARSHAN/volare/volare/gf180mcu/versions/c6d73a35f524070e85faff4a6a9eef49553ebc2b/gf180mcuD/libs.ref/gf180mcu_fd_sc_mcu7t5v0/lef 
    /home/DARSHAN/volare/volare/gf180mcu/versions/c6d73a35f524070e85faff4a6a9eef49553ebc2b/gf180mcuD/libs.ref/gf180mcu_fd_sc_mcu7t5v0/techlef
    /home/DARSHAN/volare/volare/gf180mcu/versions/c6d73a35f524070e85faff4a6a9eef49553ebc2b/gf180mcuD/libs.ref/gf180mcu_fd_ip_sram/lib
    /home/DARSHAN/volare/volare/gf180mcu/versions/c6d73a35f524070e85faff4a6a9eef49553ebc2b/gf180mcuD/libs.ref/gf180mcu_fd_ip_sram/lef
}
set_db / .init_hdl_search_path {./rtl ../code}

# Load Timing (.lib) - Using SS (Slow-Slow) corner for worst-case setup timing
set_db / .library {gf180mcu_fd_sc_mcu7t5v0__ss_125C_1v62.lib gf180mcu_fd_ip_sram__sram256x8m8wm1__ss_125C_1v62.lib}

# Define absolute paths to physical LEF files
set tech_lef "/home/DARSHAN/volare/volare/gf180mcu/versions/c6d73a35f524070e85faff4a6a9eef49553ebc2b/gf180mcuD/libs.ref/gf180mcu_fd_sc_mcu7t5v0/techlef/gf180mcu_fd_sc_mcu7t5v0__max.tlef"
set cell_lef "/home/DARSHAN/volare/volare/gf180mcu/versions/c6d73a35f524070e85faff4a6a9eef49553ebc2b/gf180mcuD/libs.ref/gf180mcu_fd_sc_mcu7t5v0/lef/gf180mcu_fd_sc_mcu7t5v0.lef"
set sram_lef "/home/DARSHAN/volare/volare/gf180mcu/versions/c6d73a35f524070e85faff4a6a9eef49553ebc2b/gf180mcuD/libs.ref/gf180mcu_fd_ip_sram/lef/gf180mcu_fd_ip_sram__sram256x8m8wm1.lef"

# Load Physical (.lef) - TechLEF must ALWAYS be loaded before the Cell LEF
set_db / .lef_library [list $tech_lef $cell_lef $sram_lef]

# ------------------------------------------------------------------------------
# PHASE 2: RTL Reading & Elaboration
# ------------------------------------------------------------------------------
read_hdl -sv top_tensorcore_lite.sv
elaborate top_tensorcore_lite

# Check for any missing modules or floating wires before proceeding
check_design -unresolved

# ------------------------------------------------------------------------------
# PHASE 3: Timing Constraints & Floorplan Prediction
# ------------------------------------------------------------------------------
# Loaded the specific constraints file as requested
read_sdc ../synthesis/constraints/input_constraints.sdc
