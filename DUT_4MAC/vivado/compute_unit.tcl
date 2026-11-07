# Source in an open Vivado project with the desired FPGA part selected.
set source_dir [file normalize [file join [file dirname [info script]] ..]]
add_files [list \
    $source_dir/uart/uart_pkg.sv \
    $source_dir/uart/uart_if.sv \
    $source_dir/uart/uart_clk.sv \
    $source_dir/uart/uart_rx.sv \
    $source_dir/uart/uart_tx.sv]
add_files [glob $source_dir/rtl/*.sv]
set_property top compute_unit [current_fileset]
update_compile_order -fileset sources_1
