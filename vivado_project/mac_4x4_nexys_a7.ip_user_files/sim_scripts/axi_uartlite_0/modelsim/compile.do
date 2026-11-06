vlib modelsim_lib/work
vlib modelsim_lib/msim

vlib modelsim_lib/msim/xpm
vlib modelsim_lib/msim/axi_lite_ipif_v3_1_0
vlib modelsim_lib/msim/axi_uartlite_v2_0_40
vlib modelsim_lib/msim/xil_defaultlib

vmap xpm modelsim_lib/msim/xpm
vmap axi_lite_ipif_v3_1_0 modelsim_lib/msim/axi_lite_ipif_v3_1_0
vmap axi_uartlite_v2_0_40 modelsim_lib/msim/axi_uartlite_v2_0_40
vmap xil_defaultlib modelsim_lib/msim/xil_defaultlib

vlog -work xpm -64 -incr -mfcu  -sv "+incdir+../../../../../../../../Xilinx/2026.1/data/rsb/busdef" \
"/home/thomasle/Xilinx/2026.1/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \

vcom -work xpm -64 -93  \
"/home/thomasle/Xilinx/2026.1/data/ip/xpm/xpm_VCOMP.vhd" \

vcom -work axi_lite_ipif_v3_1_0 -64 -93  \
"../../../ipstatic/hdl/axi_lite_ipif_v3_1_rfs.vhd" \

vcom -work axi_uartlite_v2_0_40 -64 -93  \
"../../../ipstatic/hdl/axi_uartlite_v2_0_rfs.vhd" \

vcom -work xil_defaultlib -64 -93  \
"../../../../mac_4x4_nexys_a7.gen/sources_1/ip/axi_uartlite_0/sim/axi_uartlite_0.vhd" \


vlog -work xil_defaultlib \
"glbl.v"

