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

# Force Genus to auto-predict the floorplan to compensate for the missing .def file
set_db / .predict_floorplan_enable_during_generic true
set_db / .physical_force_predict_floorplan true
set_db / .predict_floorplan_use_innovus true

# ------------------------------------------------------------------------------
# PHASE 4: DFT Setup (Pre-Synthesis)
# ------------------------------------------------------------------------------
# Define the scan architecture based on the Spec Sheet
set_db / .dft_scan_style muxed_scan
set_db / .dft_prefix dft_
set_db design:top_tensorcore_lite .dft_min_number_of_scan_chains 4

# Define test signals (Ensure these ports exist in your top-level RTL)
define_test_clock -name scan_clk -period 4000 scan_clk_port
define_shift_enable -name SE -active high scan_en_port
define_test_mode -name TM -active high test_mode_port

# Run initial rule check to ensure clocks and resets are controllable
check_dft_rules

# ------------------------------------------------------------------------------
# PHASE 5: Core Physical Synthesis
# ------------------------------------------------------------------------------
# Effort levels set to high for maximum PPA optimization
set_db / .syn_generic_effort high
set_db / .syn_map_effort high
set_db / .syn_opt_effort high

# Safely cap the spatial effort to bypass the MMMC license block
set_db / .opt_spatial_effort standard

# 1. Map to generic gates
syn_generic -physical
# 2. Map to GF180MCU cells (Flops are converted to scan-flops here, but left unstitched)
syn_map -physical
# 3. Optimize placement and timing
syn_opt -spatial

# ------------------------------------------------------------------------------
# PHASE 6: EXPORT NETLIST 1 (NON-DFT / FUNCTIONAL ONLY)
# ------------------------------------------------------------------------------
puts "============================================================"
puts " EXPORTING FUNCTIONAL (PRE-STITCHED) NETLIST & REPORTS"
puts "============================================================"

report_timing > reports/top_tensorcore_func_timing.rpt
report_area   > reports/top_tensorcore_func_area.rpt
report_power  > reports/top_tensorcore_func_power.rpt

# Export the netlist where scan chains are NOT wired together
write_hdl > outputs/top_tensorcore_noscan.v

# ------------------------------------------------------------------------------
# PHASE 7: DFT Stitching & Incremental Synthesis
# ------------------------------------------------------------------------------
puts "============================================================"
puts " STITCHING SCAN CHAINS & RE-OPTIMIZING"
puts "============================================================"

# Re-check rules post-mapping
check_dft_rules -advanced

# Physically connect the scan flip-flops into 4 chains
connect_scan_chains -auto_create_chains

# Re-run physical optimization to fix any setup/hold violations 
# caused by the new scan routing wire capacitance
syn_opt -incremental -spatial

# ------------------------------------------------------------------------------
# PHASE 8: EXPORT NETLIST 2 (FULL DFT) & HANDOFF FILES
# ------------------------------------------------------------------------------
puts "============================================================"
puts " EXPORTING FULL DFT NETLIST & INNOVUS HANDOFF"
puts "============================================================"

# DFT Specific Reports
report_scan_chains > reports/top_tensorcore_scan_chains.rpt
check_dft_rules > reports/top_tensorcore_dft_final.rpt

# Final PPA Reports
report_timing > reports/top_tensorcore_dft_timing.rpt
report_area   > reports/top_tensorcore_dft_area.rpt
report_power  > reports/top_tensorcore_dft_power.rpt
report_qor    > reports/top_tensorcore_dft_qor.rpt

# Export the final netlist with fully connected scan chains
write_hdl > outputs/top_tensorcore_with_dft.v

# Export the ScanDEF file (Critical for Innovus Place & Route to reorder chains)
write_scandef > outputs/top_tensorcore_lite.scandef

# Export the full database for Innovus Place & Route
write_design -innovus -base_name outputs/innovus_handoff/top_tensorcore_lite