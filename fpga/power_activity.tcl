# Vectorless power estimate: reset buttons are inactive during normal operation.
set_switching_activity -static_probability 1 -toggle_rate 0 [get_ports CPU_RESETN]
set_switching_activity -static_probability 0 -toggle_rate 0 [get_ports BTND]
