# vivado -mode batch -source docs/generate_comparison_reports.tcl
# Compare core-only OOC implementations at 100 MHz on the same part.
set root [file normalize [file join [file dirname [info script]] ..]]
set out [file join $root docs]
set scratch [file join $root build baseline_reports]
file mkdir $scratch
set baseline_revision [string trim [exec git -C $root rev-parse main]]
set sources {}
foreach name {ADDER COUNT_ADDER MULTIPLIER MAC_ADDER MAC_MULTIPLIER MAC DUT} {
    set path [file join $scratch ${name}.sv]
    set fd [open $path w]
    puts $fd [exec git -C $root show ${baseline_revision}:DUT/rtl/${name}.sv]
    close $fd
    lappend sources $path
}
proc power_report {destination} {
    # Common vectorless assumptions, not a measured or simulated workload.
    set data_inputs [get_ports -filter {DIRECTION == IN && NAME != clk && NAME != rst_n}]
    set_switching_activity -toggle_rate 12.5 -static_probability 0.5 $data_inputs
    set_switching_activity -toggle_rate 0 -static_probability 1 [get_ports rst_n]
    report_power -file $destination
}
create_project -in_memory baseline -part xc7a100tcsg324-1
read_verilog -sv $sources
synth_design -top DUT -part xc7a100tcsg324-1 -mode out_of_context
create_clock -name core_clk -period 10.000 [get_ports clk]
opt_design
place_design
phys_opt_design
route_design
report_timing_summary -delay_type min_max -report_unconstrained -max_paths 10 -file [file join $out baseline_timing.rpt]
report_utilization -file [file join $out baseline_utilization.rpt]
report_utilization -hierarchical -file [file join $out baseline_utilization_hierarchical.rpt]
report_route_status -file [file join $out baseline_route_status.rpt]
power_report [file join $out baseline_power.rpt]
write_checkpoint -force [file join $scratch baseline_routed.dcp]
close_project
open_checkpoint [file join $root build mac4x4_reports mac4x4_routed.dcp]
power_report [file join $out mac4x4_power.rpt]
set fd [open [file join $out comparison_report_provenance.txt] w]
puts $fd "Baseline revision: $baseline_revision"
puts $fd "Improved timing/utilization/power checkpoint: build/mac4x4_reports/mac4x4_routed.dcp"
puts $fd "Improved checkpoint must be regenerated with docs/generate_mac4x4_reports.tcl after RTL changes."
puts $fd "Part: xc7a100tcsg324-1; OOC clock: 100 MHz"
puts $fd "Power: vectorless; non-clock inputs 12.5% toggle, 0.5 static probability; reset inactive."
puts $fd "No SAIF/VCD workload annotation; no board clock tree or I/O buffers."
close $fd
exit
