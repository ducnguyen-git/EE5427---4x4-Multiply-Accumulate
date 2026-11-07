# GUI: source in an open project. Batch: synthesize for the Nexys A7-100T.
set source_dir [file normalize [file join [file dirname [info script]] ..]]
set run_synthesis [expr {[llength [get_projects -quiet]] == 0}]
if {$run_synthesis} {
    create_project -in_memory -part xc7a100tcsg324-1
}
add_files [list \
    $source_dir/uart/uart_pkg.sv \
    $source_dir/uart/uart_if.sv \
    $source_dir/uart/uart_clk.sv \
    $source_dir/uart/uart_rx.sv \
    $source_dir/uart/uart_tx.sv]
add_files [glob $source_dir/rtl/*.sv]
set_property top compute_unit [current_fileset]
update_compile_order -fileset sources_1

if {$run_synthesis} {
    set output_dir [file join $source_dir build compute_unit]
    file mkdir $output_dir
    synth_design -top compute_unit -part [get_property PART [current_project]]
    write_checkpoint -force [file join $output_dir compute_unit_synth.dcp]
    report_utilization -file [file join $output_dir utilization.rpt]
    puts "Synthesis complete: $output_dir"
}
