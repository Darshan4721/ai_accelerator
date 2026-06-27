# ==============================================================================
# SysMAC-Hybrid: AI Accelerator - Master SDC Constraints File
# Target Frequency: 250 MHz (4.0 ns period)
# Module: top_tensorcore_lite
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Clock Definitions
# ------------------------------------------------------------------------------
# Primary System Clock (250 MHz)
create_clock -name sys_clk -period 4.0 [get_ports clk_i]

# Clock Uncertainties (Jitter & Skew margin)
set_clock_uncertainty -setup 0.2 [get_clocks sys_clk]
set_clock_uncertainty -hold  0.1 [get_clocks sys_clk]

# Clock Transition (Slew Rate)
set_clock_transition 0.1 [get_clocks sys_clk]

# ------------------------------------------------------------------------------
# 2. Clock Domain Crossings (CDC) & False Paths
# ------------------------------------------------------------------------------
# Asynchronous Reset (Active-Low)
set_false_path -from [get_ports rst_ni]

# Asynchronous JTAG Control Trigger (Captured by 2-FF synchronizer)
set_false_path -from [get_ports bist_start_i]

# ------------------------------------------------------------------------------
# 3. Quasi-Static Data Coherency (The 512-bit MISR Signature CDC)
# ------------------------------------------------------------------------------
# Create a Virtual Clock for the external JTAG controller (e.g., 20MHz / 50ns period)
create_clock -name v_jtag_clk -period 50.0

# Apply an input delay to the bus bound to the virtual clock to create a valid startpoint
set_input_delay 0.0 -clock v_jtag_clk [get_ports expected_misr_sig_i*]

# Now the STA tool can perfectly calculate the 4.0ns datapath-only physical routing constraint
set_max_delay 4.0 -datapath_only \
    -from [get_ports expected_misr_sig_i*] \
    -to   [get_cells -hierarchical *u_bist_ctrl*]

# ------------------------------------------------------------------------------
# 4. Input / Output Delays (System I/O)
# ------------------------------------------------------------------------------
# Assume 30% of clock period (1.2ns) is consumed externally by SoC/DMA
set in_delay_val 1.2
set out_delay_val 1.2

# AXI-Lite Input/Output Delays
set axi_lite_inputs [get_ports {s_axi_awaddr* s_axi_awvalid s_axi_wdata* s_axi_wvalid s_axi_bready s_axi_araddr* s_axi_arvalid s_axi_rready}]
set axi_lite_outputs [get_ports {s_axi_awready s_axi_wready s_axi_bresp* s_axi_bvalid s_axi_arready s_axi_rdata* s_axi_rresp* s_axi_rvalid}]

set_input_delay  -max $in_delay_val  -clock sys_clk $axi_lite_inputs
set_input_delay  -min 0.0            -clock sys_clk $axi_lite_inputs
set_output_delay -max $out_delay_val -clock sys_clk $axi_lite_outputs
set_output_delay -min 0.0            -clock sys_clk $axi_lite_outputs

# AXI-Stream Input Delays (DMA -> RX)
set axi_rx_inputs [get_ports {s_axis_tdata* s_axis_tvalid s_axis_tlast}]
set axi_rx_outputs [get_ports {s_axis_tready}]

set_input_delay  -max $in_delay_val  -clock sys_clk $axi_rx_inputs
set_input_delay  -min 0.0            -clock sys_clk $axi_rx_inputs
set_output_delay -max $out_delay_val -clock sys_clk $axi_rx_outputs
set_output_delay -min 0.0            -clock sys_clk $axi_rx_outputs

# AXI-Stream Output Delays (TX -> DMA)
set axi_tx_inputs [get_ports {m_axis_tready}]
set axi_tx_outputs [get_ports {m_axis_tdata* m_axis_tvalid m_axis_tlast}]

set_input_delay  -max $in_delay_val  -clock sys_clk $axi_tx_inputs
set_input_delay  -min 0.0            -clock sys_clk $axi_tx_inputs
set_output_delay -max $out_delay_val -clock sys_clk $axi_tx_outputs
set_output_delay -min 0.0            -clock sys_clk $axi_tx_outputs

# BIST Output Status Delays
set bist_outputs [get_ports {bist_done_o bist_fail_o}]
set_output_delay -max $out_delay_val -clock sys_clk $bist_outputs
set_output_delay -min 0.0            -clock sys_clk $bist_outputs

# ------------------------------------------------------------------------------
# 5. Environmental Attributes
# ------------------------------------------------------------------------------
# Set maximum transition time for all nets
set_max_transition 0.5 [current_design]

# Set maximum fanout limit
set_max_fanout 20 [current_design]
