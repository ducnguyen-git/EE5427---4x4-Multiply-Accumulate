# Pin assignments: Digilent Nexys-A7-100T-Master.xdc.
set_property -dict {PACKAGE_PIN E3 IOSTANDARD LVCMOS33} [get_ports sys_clk]
create_clock -name sys_clk -period 10.000 [get_ports sys_clk]
set_property -dict {PACKAGE_PIN C12 IOSTANDARD LVCMOS33} [get_ports rst_n]
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVCMOS33} [get_ports finish]
set_property -dict {PACKAGE_PIN K15 IOSTANDARD LVCMOS33} [get_ports err]

# Onboard USB-UART bridge (J6): bridge TX drives FPGA RX, and vice versa.
set_property -dict {PACKAGE_PIN C4 IOSTANDARD LVCMOS33} [get_ports rx]
set_property -dict {PACKAGE_PIN D4 IOSTANDARD LVCMOS33} [get_ports tx]

# These dividers match the script's 100 MHz / 9600 baud parameters.
create_generated_clock -name uart_tx_clk -source [get_ports sys_clk] -divide_by 10416 [get_pins uart_clk_i/tx_clk_reg/Q]
create_generated_clock -name uart_rx_clk -source [get_ports sys_clk] -divide_by 651 [get_pins uart_clk_i/rx_clk_reg/Q]
