# GUI: load sources/constraints. Batch: build a Nexys A7-100T bitstream.
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
add_files -fileset constrs_1 $source_dir/vivado/nexys_a7_100t.xdc
set_property top compute_unit [current_fileset]
set_property generic {XTAL_FREQ=100000000 BAUD_RATE=9600} [current_fileset]
update_compile_order -fileset sources_1

if {$run_synthesis} {
    set output_dir [file join $source_dir build compute_unit]
    file mkdir $output_dir
    synth_design -top compute_unit -part [get_property PART [current_project]]
    write_checkpoint -force [file join $output_dir compute_unit_synth.dcp]
    report_utilization -file [file join $output_dir utilization.rpt]
    opt_design
    place_design
    route_design
    write_checkpoint -force [file join $output_dir compute_unit_routed.dcp]
    report_timing_summary -file [file join $output_dir timing_summary.rpt]
    report_cdc -file [file join $output_dir cdc.rpt]
    report_drc -file [file join $output_dir drc.rpt]
    write_bitstream -force [file join $output_dir compute_unit.bit]
    puts "Bitstream complete: [file join $output_dir compute_unit.bit]"
}
