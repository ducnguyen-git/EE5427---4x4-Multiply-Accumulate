# ==============================================================================
# Intel Quartus Prime Automated Synthesis Script
# Project: EE5427 - 4x4 Multiply-Accumulate Matrix Processor
# File: build_quartus.tcl
#
# Usage:
#   quartus_sh -t fpga/build_quartus.tcl
# ==============================================================================

load_package flow
project_new mac_4x4_top -overwrite

# Target Family and Device (Cyclone V default or MAX 10)
set_global_assignment -name FAMILY "Cyclone V"
set_global_assignment -name DEVICE 5CSXFC6D6F31C6
set_global_assignment -name TOP_LEVEL_ENTITY top_fpga_wrapper

# Source files
set_global_assignment -name SYSTEMVERILOG_FILE DUT/rtl/ADDER.sv
set_global_assignment -name SYSTEMVERILOG_FILE DUT/rtl/COUNT_ADDER.sv
set_global_assignment -name SYSTEMVERILOG_FILE DUT/rtl/MULTIPLIER.sv
set_global_assignment -name SYSTEMVERILOG_FILE DUT/rtl/MAC_ADDER.sv
set_global_assignment -name SYSTEMVERILOG_FILE DUT/rtl/MAC_MULTIPLIER.sv
set_global_assignment -name SYSTEMVERILOG_FILE DUT/rtl/MAC.sv
set_global_assignment -name SYSTEMVERILOG_FILE DUT/rtl/DUT.sv
set_global_assignment -name SYSTEMVERILOG_FILE DUT/rtl/uart/uart_pkg.sv
set_global_assignment -name SYSTEMVERILOG_FILE DUT/rtl/uart/uart_if.sv
set_global_assignment -name SYSTEMVERILOG_FILE DUT/rtl/uart/uart_clk.sv
set_global_assignment -name SYSTEMVERILOG_FILE DUT/rtl/uart/uart_rx.sv
set_global_assignment -name SYSTEMVERILOG_FILE DUT/rtl/uart/uart_tx.sv
set_global_assignment -name SYSTEMVERILOG_FILE DUT/rtl/DUT_uart.sv
set_global_assignment -name SYSTEMVERILOG_FILE fpga/top_fpga_wrapper.sv

# Compilation Flow
execute_module -tool map
puts "===> Analysis & Synthesis finished successfully!"
project_close

