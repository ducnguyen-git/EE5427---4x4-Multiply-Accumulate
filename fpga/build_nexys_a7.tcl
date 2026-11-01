# ==============================================================================
# Vivado Automated Build Script for Nexys A7-100T (Artix-7 xc7a100tcsg324-1)
# Project: EE5427 - 4x4 Multiply-Accumulate Matrix Processor
# File: build_nexys_a7.tcl
#
# Usage:
#   vivado -mode batch -source fpga/build_nexys_a7.tcl
# ==============================================================================

set proj_name "mac_4x4_nexys_a7"
set proj_dir  "./vivado_project"
set part      "xc7a100tcsg324-1"

# Create project
create_project -force $proj_name $proj_dir -part $part

# Add RTL source files
add_files -norecurse [list \
    "DUT/rtl/ADDER.sv" \
    "DUT/rtl/COUNT_ADDER.sv" \
    "DUT/rtl/MULTIPLIER.sv" \
    "DUT/rtl/MAC_ADDER.sv" \
    "DUT/rtl/MAC_MULTIPLIER.sv" \
    "DUT/rtl/MAC.sv" \
    "DUT/rtl/DUT.sv" \
    "fpga/top_fpga_wrapper.sv" \
]

# Set SystemVerilog filetype
set_property file_type SystemVerilog [get_files *.sv]

# Add constraint file
add_files -fileset constrs_1 -norecurse "fpga/constraints/nexys_a7_100t.xdc"

# Set Top Level Entity
set_property top top_fpga_wrapper [current_fileset]
update_compile_order -fileset sources_1

# Run Synthesis
puts "===> Starting Synthesis..."
launch_runs synth_1 -jobs 6
wait_on_run synth_1

# Check Synthesis Status
if {[get_property STATUS [get_runs synth_1]] != "synth_design Complete!"} {
    puts "ERROR: Synthesis failed!"
    exit 1
}

# Run Implementation and Bitstream Generation
puts "===> Starting Implementation and Bitstream Generation..."
launch_runs impl_1 -to_step write_bitstream -jobs 6
wait_on_run impl_1

# Check Implementation Status
if {[get_property STATUS [get_runs impl_1]] != "write_bitstream Complete!"} {
    puts "ERROR: Implementation / Bitstream generation failed!"
    exit 1
}

puts "=================================================================="
puts "SUCCESS: Bitstream generated successfully at:"
puts "$proj_dir/${proj_name}.runs/impl_1/top_fpga_wrapper.bit"
puts "=================================================================="

