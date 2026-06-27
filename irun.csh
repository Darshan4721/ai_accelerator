#!/bin/tcsh -f

# TensorCore_Lite Simulation Wrapper Script (TCSH Version)
# Usage: Run from 'work' directory using: source ../irun.csh [module_tag]
#
# Module Tags Available:
#   ksa       : 32-bit Kogge-Stone Adder
#   mult      : Booth-Wallace Multiplier Leaf Nodes
#   pe        : Fused MAC Processing Element
#   array     : 16x16 Systolic Array (DPI-C Golden Model)
#   sram      : Single SRAM Bank
#   subsystem : 16-bank Staggered SRAM Subsystem
#   axilite   : AXI4-Lite Configuration Registers
#   rx        : AXI-Stream Receiver
#   tx        : AXI-Stream Transmitter
#   mbist     : Memory BIST March C- Engine
#   lfsr      : 128-bit PRPG
#   misr      : 512-bit Compressor
#   topbist   : Top-Level BIST Integration

# --- CONFIGURATION ---
set CODE_DIR = "../code"
set TB_DIR   = "../tb"
set FLAGS    = "-64bit -sv -uvm -access +rwc -R"

# --- ARGUMENT PARSING ---
if ( $#argv == 0 ) then
    echo "Usage: source ../irun.csh [module_tag]"
    exit 1
endif

set MODULE = $1
set TOP = ""
set TB_FILE = ""
set RTL_FILES = ""
set CPP_FILES = "$TB_DIR/golden/golden_model.cpp"

switch ($MODULE)
    case ksa:
        set TOP = "tb_ksa_hostile"
        set TB_FILE = "$TB_DIR/tb_ksa_hostile.sv"
        set RTL_FILES = "$CODE_DIR/ksa_32bit.sv"
        breaksw
    case mult:
        set TOP = "tb_multiplier_hostile"
        set TB_FILE = "$TB_DIR/tb_multiplier_hostile.sv"
        set RTL_FILES = "$CODE_DIR/booth_encoder.sv $CODE_DIR/partial_product_gen.sv $CODE_DIR/wallace_tree.sv"
        breaksw
    case pe:
        set TOP = "tb_pe_hostile"
        set TB_FILE = "$TB_DIR/tb_pe_hostile.sv"
        set RTL_FILES = "$CODE_DIR/pe_pipelined.sv $CODE_DIR/ksa_32bit.sv $CODE_DIR/booth_encoder.sv $CODE_DIR/partial_product_gen.sv $CODE_DIR/wallace_tree.sv"
        breaksw
    case pe_uvm:
        set TOP = "tb_pe_uvm_top"
        set TB_FILE = "$TB_DIR/pe_uvm/tb_pe_uvm_top.sv"
        set RTL_FILES = "$CODE_DIR/pe_pipelined.sv $CODE_DIR/ksa_32bit.sv $CODE_DIR/booth_encoder.sv $CODE_DIR/partial_product_gen.sv $CODE_DIR/wallace_tree.sv $TB_DIR/pe_uvm/pe_if.sv $TB_DIR/pe_uvm/pe_uvm_pkg.sv"
        set CPP_FILES = "$TB_DIR/pe_uvm/golden_pe_model.cpp"
        breaksw
    case array:
        set TOP = "tb_systolic_array_hostile"
        set TB_FILE = "$TB_DIR/tb_systolic_array_hostile.sv"
        set RTL_FILES = "$CODE_DIR/systolic_array_16x16.sv $CODE_DIR/pe_pipelined.sv $CODE_DIR/ksa_32bit.sv $CODE_DIR/booth_encoder.sv $CODE_DIR/partial_product_gen.sv $CODE_DIR/wallace_tree.sv"
        breaksw
    case sram:
        set TOP = "tb_sram_bank"
        set TB_FILE = "$TB_DIR/tb_sram_bank.sv"
        set RTL_FILES = "$CODE_DIR/sram_bank_256x8.sv"
        breaksw
    case subsystem:
        set TOP = "tb_sram_subsystem"
        set TB_FILE = "$TB_DIR/tb_sram_subsystem.sv"
        set RTL_FILES = "$CODE_DIR/sram_subsystem_16bank.sv $CODE_DIR/sram_bank_256x8.sv"
        breaksw
    case axilite:
        set TOP = "tb_axi_lite_config"
        set TB_FILE = "$TB_DIR/tb_axi_lite_config.sv"
        set RTL_FILES = "$CODE_DIR/axi_lite_config.sv"
        breaksw
    case rx:
        set TOP = "tb_axis_rx"
        set TB_FILE = "$TB_DIR/tb_axis_rx.sv"
        set RTL_FILES = "$CODE_DIR/axis_rx.sv"
        breaksw
    case tx:
        set TOP = "tb_axis_tx"
        set TB_FILE = "$TB_DIR/tb_axis_tx.sv"
        set RTL_FILES = "$CODE_DIR/axis_tx.sv"
        breaksw
    case mbist:
        set TOP = "tb_mbist_hostile"
        set TB_FILE = "$TB_DIR/tb_mbist_hostile.sv"
        set RTL_FILES = "$CODE_DIR/mbist_march_c.sv"
        breaksw
    case lfsr:
        set TOP = "tb_lfsr_hostile"
        set TB_FILE = "$TB_DIR/tb_lfsr_hostile.sv"
        set RTL_FILES = "$CODE_DIR/lfsr_prpg.sv"
        breaksw
    case misr:
        set TOP = "tb_misr_hostile"
        set TB_FILE = "$TB_DIR/tb_misr_hostile.sv"
        set RTL_FILES = "$CODE_DIR/misr_compressor.sv"
        breaksw
    case topbist:
        set TOP = "tb_top_bist_hostile"
        set TB_FILE = "$TB_DIR/tb_top_bist_hostile.sv"
        set RTL_FILES = "$CODE_DIR/*.sv" # Top level needs everything
        breaksw
    case top:
        set TOP = "tb_top_tensorcore"
        set TB_FILE = "$TB_DIR/tb_top_tensorcore.sv"
        set RTL_FILES = "$CODE_DIR/*.sv $TB_DIR/top_tensorcore_uvm/system_top_if.sv $TB_DIR/top_tensorcore_uvm/top_uvm_pkg.sv"
        breaksw
    default:
        echo "Error: Unknown module tag '$MODULE'"
        exit 1
        breaksw
endsw

# --- EXECUTION ---
echo "---------------------------------------------------------"
echo " RUNNING SURGICAL VERIFICATION FOR: $MODULE"
echo "---------------------------------------------------------"

# Run irun with only the required dependencies
irun $FLAGS -top $TOP \
    $TB_DIR/uvm_report_pkg.sv \
    $TB_DIR/dpi_pkg.sv \
    $RTL_FILES \
    $CPP_FILES \
    $TB_FILE

echo "---------------------------------------------------------"
echo " SIMULATION COMPLETE"
echo "---------------------------------------------------------"