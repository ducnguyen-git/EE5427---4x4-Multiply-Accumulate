set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports CLK100MHZ]
set_property -dict {PACKAGE_PIN C12 IOSTANDARD LVCMOS33} [get_ports CPU_RESETN]
set_property -dict {PACKAGE_PIN N17 IOSTANDARD LVCMOS33} [get_ports BTNC]
set_property -dict {PACKAGE_PIN M18 IOSTANDARD LVCMOS33} [get_ports BTNU]
set_property -dict {PACKAGE_PIN P18 IOSTANDARD LVCMOS33} [get_ports BTND]
set_property -dict {PACKAGE_PIN P17 IOSTANDARD LVCMOS33} [get_ports BTNL]
set_property -dict {PACKAGE_PIN M17 IOSTANDARD LVCMOS33} [get_ports BTNR]
set_property -dict {PACKAGE_PIN J15 IOSTANDARD LVCMOS33} [get_ports {SW[0]}]
set_property -dict {PACKAGE_PIN L16 IOSTANDARD LVCMOS33} [get_ports {SW[1]}]
set_property -dict {PACKAGE_PIN M13 IOSTANDARD LVCMOS33} [get_ports {SW[2]}]
set_property -dict {PACKAGE_PIN R15 IOSTANDARD LVCMOS33} [get_ports {SW[3]}]
set_property -dict {PACKAGE_PIN R17 IOSTANDARD LVCMOS33} [get_ports {SW[4]}]
set_property -dict {PACKAGE_PIN T18 IOSTANDARD LVCMOS33} [get_ports {SW[5]}]
set_property -dict {PACKAGE_PIN U18 IOSTANDARD LVCMOS33} [get_ports {SW[6]}]
set_property -dict {PACKAGE_PIN R13 IOSTANDARD LVCMOS33} [get_ports {SW[7]}]
set_property -dict {PACKAGE_PIN T8 IOSTANDARD LVCMOS18} [get_ports {SW[8]}]
set_property -dict {PACKAGE_PIN U8 IOSTANDARD LVCMOS18} [get_ports {SW[9]}]
set_property -dict {PACKAGE_PIN R16 IOSTANDARD LVCMOS33} [get_ports {SW[10]}]
set_property -dict {PACKAGE_PIN T13 IOSTANDARD LVCMOS33} [get_ports {SW[11]}]
set_property -dict {PACKAGE_PIN H6 IOSTANDARD LVCMOS33} [get_ports {SW[12]}]
set_property -dict {PACKAGE_PIN U12 IOSTANDARD LVCMOS33} [get_ports {SW[13]}]
set_property -dict {PACKAGE_PIN U11 IOSTANDARD LVCMOS33} [get_ports {SW[14]}]
set_property -dict {PACKAGE_PIN V10 IOSTANDARD LVCMOS33} [get_ports {SW[15]}]
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS33} [get_ports {LED[0]}]
set_property -dict {PACKAGE_PIN K15 IOSTANDARD LVCMOS33} [get_ports {LED[1]}]
set_property -dict {PACKAGE_PIN J13 IOSTANDARD LVCMOS33} [get_ports {LED[2]}]
set_property -dict {PACKAGE_PIN N14 IOSTANDARD LVCMOS33} [get_ports {LED[3]}]
set_property -dict {PACKAGE_PIN R18 IOSTANDARD LVCMOS33} [get_ports {LED[4]}]
set_property -dict {PACKAGE_PIN V17 IOSTANDARD LVCMOS33} [get_ports {LED[5]}]
set_property -dict {PACKAGE_PIN U17 IOSTANDARD LVCMOS33} [get_ports {LED[6]}]
set_property -dict {PACKAGE_PIN U16 IOSTANDARD LVCMOS33} [get_ports {LED[7]}]
set_property -dict {PACKAGE_PIN V16 IOSTANDARD LVCMOS33} [get_ports {LED[8]}]
set_property -dict {PACKAGE_PIN T15 IOSTANDARD LVCMOS33} [get_ports {LED[9]}]
set_property -dict {PACKAGE_PIN U14 IOSTANDARD LVCMOS33} [get_ports {LED[10]}]
set_property -dict {PACKAGE_PIN T16 IOSTANDARD LVCMOS33} [get_ports {LED[11]}]
set_property -dict {PACKAGE_PIN V15 IOSTANDARD LVCMOS33} [get_ports {LED[12]}]
set_property -dict {PACKAGE_PIN V14 IOSTANDARD LVCMOS33} [get_ports {LED[13]}]
set_property -dict {PACKAGE_PIN V12 IOSTANDARD LVCMOS33} [get_ports {LED[14]}]
set_property -dict {PACKAGE_PIN V11 IOSTANDARD LVCMOS33} [get_ports {LED[15]}]
set_property -dict {PACKAGE_PIN T10 IOSTANDARD LVCMOS33} [get_ports {seg[0]}]
set_property -dict {PACKAGE_PIN R10 IOSTANDARD LVCMOS33} [get_ports {seg[1]}]
set_property -dict {PACKAGE_PIN K16 IOSTANDARD LVCMOS33} [get_ports {seg[2]}]
set_property -dict {PACKAGE_PIN K13 IOSTANDARD LVCMOS33} [get_ports {seg[3]}]
set_property -dict {PACKAGE_PIN P15 IOSTANDARD LVCMOS33} [get_ports {seg[4]}]
set_property -dict {PACKAGE_PIN T11 IOSTANDARD LVCMOS33} [get_ports {seg[5]}]
set_property -dict {PACKAGE_PIN L18 IOSTANDARD LVCMOS33} [get_ports {seg[6]}]
set_property -dict {PACKAGE_PIN H15 IOSTANDARD LVCMOS33} [get_ports dp]
set_property -dict {PACKAGE_PIN J17 IOSTANDARD LVCMOS33} [get_ports {an[0]}]
set_property -dict {PACKAGE_PIN J18 IOSTANDARD LVCMOS33} [get_ports {an[1]}]
set_property -dict {PACKAGE_PIN T9 IOSTANDARD LVCMOS33} [get_ports {an[2]}]
set_property -dict {PACKAGE_PIN J14 IOSTANDARD LVCMOS33} [get_ports {an[3]}]
set_property -dict {PACKAGE_PIN P14 IOSTANDARD LVCMOS33} [get_ports {an[4]}]
set_property -dict {PACKAGE_PIN T14 IOSTANDARD LVCMOS33} [get_ports {an[5]}]
set_property -dict {PACKAGE_PIN K2 IOSTANDARD LVCMOS33} [get_ports {an[6]}]
set_property -dict {PACKAGE_PIN U13 IOSTANDARD LVCMOS33} [get_ports {an[7]}]
set_property -dict {PACKAGE_PIN C4 IOSTANDARD LVCMOS33} [get_ports UART_RXD]
set_property -dict {PACKAGE_PIN D4 IOSTANDARD LVCMOS33} [get_ports UART_TXD]
## ==============================================================================
## Xilinx Design Constraints (.xdc) for Digilent Nexys A7-100T
## Target Board: Nexys A7-100T (or Nexys 4 DDR)
## Target Device: xc7a100tcsg324-1
## Project: EE5427 - 4x4 Multiply-Accumulate Matrix Processor
## File: nexys_a7_100t.xdc
## ==============================================================================

## --------------------------------------------------------------------------
## Clock Signal (100 MHz Onboard Oscillator)
## --------------------------------------------------------------------------
# Clocking Wizard defines the 100 MHz primary clock and derived 200 MHz clock.
# Reuse that definition instead of adding or overriding an IP clock.

## --------------------------------------------------------------------------
## Push Buttons
## --------------------------------------------------------------------------
## CPU Reset Button (Active-Low Red Button)

## Directional Push Buttons (Active-High)

## --------------------------------------------------------------------------
## Slide Switches (SW[15:0])
## --------------------------------------------------------------------------

## --------------------------------------------------------------------------
## User LEDs (LED[15:0])
## --------------------------------------------------------------------------

## --------------------------------------------------------------------------
## 7-Segment Display Cathodes (CA through CG, Active-Low)
## --------------------------------------------------------------------------

## --------------------------------------------------------------------------
## 7-Segment Display Anodes (an[7:0], Active-Low Digit Enables)
## --------------------------------------------------------------------------

## USB-UART bridge (RXD/TXD are named from the FPGA perspective).

## Configuration bank 0 is powered at 3.3 V on the Nexys A7.
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

## Buttons, switches and UART RX are asynchronous to the system clock.
## Use a full clock-period phase window as the delay reference, then cut
## external paths: these ports have no synchronous setup/hold relationship.
set_input_delay -clock [get_clocks -of_objects [get_ports CLK100MHZ]] -min 0.000 [get_ports {CPU_RESETN BTNC BTNU BTND BTNL BTNR {SW[*]} UART_RXD}]
set_input_delay -clock [get_clocks -of_objects [get_ports CLK100MHZ]] -max 10.000 [get_ports {CPU_RESETN BTNC BTNU BTND BTNL BTNR {SW[*]} UART_RXD}]
set_false_path -from [get_ports {CPU_RESETN BTNC BTNU BTND BTNL BTNR {SW[*]} UART_RXD}]

## LEDs/display and UART TX have no external synchronous capture clock.
set_output_delay -clock [get_clocks -of_objects [get_ports CLK100MHZ]] -min 0.000 [get_ports {{LED[*]} {seg[*]} dp {an[*]} UART_TXD}]
set_output_delay -clock [get_clocks -of_objects [get_ports CLK100MHZ]] -max 10.000 [get_ports {{LED[*]} {seg[*]} dp {an[*]} UART_TXD}]
set_false_path -to [get_ports {{LED[*]} {seg[*]} dp {an[*]} UART_TXD}]

set_switching_activity -toggle_rate 0.000 -static_probability 1.000 [get_ports CPU_RESETN]
set_switching_activity -toggle_rate 0.000 -static_probability 0.000 [get_ports BTND]
set_load 5.000 [all_outputs]
set_property LOAD 5 [get_ports {LED[0]}]
set_property LOAD 5 [get_ports {LED[10]}]
set_property LOAD 5 [get_ports {LED[11]}]
set_property LOAD 5 [get_ports {LED[12]}]
set_property LOAD 5 [get_ports {LED[13]}]
set_property LOAD 5 [get_ports {LED[14]}]
set_property LOAD 5 [get_ports {LED[15]}]
set_property LOAD 5 [get_ports {LED[1]}]
set_property LOAD 5 [get_ports {LED[2]}]
set_property LOAD 5 [get_ports {LED[3]}]
set_property LOAD 5 [get_ports {LED[4]}]
set_property LOAD 5 [get_ports {LED[5]}]
set_property LOAD 5 [get_ports {LED[6]}]
set_property LOAD 5 [get_ports {LED[7]}]
set_property LOAD 5 [get_ports {LED[8]}]
set_property LOAD 5 [get_ports {LED[9]}]
set_property LOAD 5 [get_ports UART_TXD]
set_property LOAD 5 [get_ports {an[0]}]
set_property LOAD 5 [get_ports {an[1]}]
set_property LOAD 5 [get_ports {an[2]}]
set_property LOAD 5 [get_ports {an[3]}]
set_property LOAD 5 [get_ports {an[4]}]
set_property LOAD 5 [get_ports {an[5]}]
set_property LOAD 5 [get_ports {an[6]}]
set_property LOAD 5 [get_ports {an[7]}]
set_property LOAD 5 [get_ports dp]
set_property LOAD 5 [get_ports {seg[0]}]
set_property LOAD 5 [get_ports {seg[1]}]
set_property LOAD 5 [get_ports {seg[2]}]
set_property LOAD 5 [get_ports {seg[3]}]
set_property LOAD 5 [get_ports {seg[4]}]
set_property LOAD 5 [get_ports {seg[5]}]
set_property LOAD 5 [get_ports {seg[6]}]
