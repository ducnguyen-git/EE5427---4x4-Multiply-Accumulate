## ==============================================================================
## Synopsys Design Constraints (.sdc) for Intel Quartus Prime / TimeQuest
## Target: Intel FPGA (MAX 10 / Cyclone IV / DE10-Lite / DE2-115)
## Course: EE5427 - 4x4 Multiply-Accumulate
## ==============================================================================

# Create Clock: 50 MHz onboard clock (20.0 ns period)
create_clock -name {clk_50mhz} -period 20.000 -waveform { 0.000 10.000 } [get_ports {clk_50mhz}]

# Automatically derive clock uncertainty for TimeQuest STA
derive_clock_uncertainty

# Set Input/Output delays for board-level peripherals
set_input_delay -clock {clk_50mhz} -max 2.0 [get_ports {sw[*] key[*]}]
set_input_delay -clock {clk_50mhz} -min 0.5 [get_ports {sw[*] key[*]}]

set_output_delay -clock {clk_50mhz} -max 2.0 [get_ports {ledr[*] hex*[*]}]
set_output_delay -clock {clk_50mhz} -min 0.5 [get_ports {ledr[*] hex*[*]}]
