# Run from any directory with Vivado -mode batch -source <this file>.
# Core-only out-of-context implementation; boundary I/O timing is unspecified.
set root [file normalize [file join [file dirname [info script]] ..]]
set out [file join $root docs]
set scratch [file join $root build mac4x4_reports]
file mkdir $scratch
set_part xc7a100tcsg324-1
read_verilog -sv [list [file join $root rtl ADDER.sv] [file join $root rtl MULTIPLIER.sv] [file join $root rtl VEDIC4_PIPELINED.sv] [file join $root rtl MAC.sv] [file join $root rtl MAC4x4.sv]]
synth_design -top MAC4x4 -part xc7a100tcsg324-1 -mode out_of_context
create_clock -name core_clk -period 10.000 [get_ports clk]
opt_design
place_design
phys_opt_design
route_design
report_timing_summary -delay_type min_max -report_unconstrained -max_paths 10 -file [file join $out mac4x4_timing.rpt]
report_utilization -file [file join $out mac4x4_utilization.rpt]
report_utilization -hierarchical -file [file join $out mac4x4_utilization_hierarchical.rpt]
report_route_status -file [file join $out mac4x4_route_status.rpt]
write_checkpoint -force [file join $scratch mac4x4_routed.dcp]
exit
