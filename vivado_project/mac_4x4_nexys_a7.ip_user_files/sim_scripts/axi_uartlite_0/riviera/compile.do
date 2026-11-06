transcript off
onbreak {quit -force}
onerror {quit -force}
transcript on

vlib work
vlib riviera/xpm
vlib riviera/axi_lite_ipif_v3_1_0
vlib riviera/axi_uartlite_v2_0_40
vlib riviera/xil_defaultlib

vmap xpm riviera/xpm
vmap axi_lite_ipif_v3_1_0 riviera/axi_lite_ipif_v3_1_0
vmap axi_uartlite_v2_0_40 riviera/axi_uartlite_v2_0_40
vmap xil_defaultlib riviera/xil_defaultlib

vlog -work xpm  -incr "+incdir+../../../../../../../../Xilinx/2026.1/data/rsb/busdef" -l xpm -l axi_lite_ipif_v3_1_0 -l axi_uartlite_v2_0_40 -l xil_defaultlib \
"/home/thomasle/Xilinx/2026.1/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \

vcom -work xpm -93  -incr \
"/home/thomasle/Xilinx/2026.1/data/ip/xpm/xpm_VCOMP.vhd" \

vcom -work axi_lite_ipif_v3_1_0 -93  -incr \
"../../../ipstatic/hdl/axi_lite_ipif_v3_1_rfs.vhd" \

vcom -work axi_uartlite_v2_0_40 -93  -incr \
"../../../ipstatic/hdl/axi_uartlite_v2_0_rfs.vhd" \

vcom -work xil_defaultlib -93  -incr \
"../../../../mac_4x4_nexys_a7.gen/sources_1/ip/axi_uartlite_0/sim/axi_uartlite_0.vhd" \


vlog -work xil_defaultlib \
"glbl.v"

