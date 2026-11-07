# DUT UART interface

`DUT_uart` connects the existing UART RX/TX modules to the parallel `DUT`
controls. `fpga/top_fpga_wrapper.sv` instantiates both and gives UART priority
while a request or response is in progress. The parallel DUT interface is
unchanged; the original DUT testbench still works.

## Wire protocol

- Nexys A7: 100 MHz clock, **9600 baud, 8 data bits, no parity, 1 stop bit**.
- No hardware flow control. Send raw binary, not ASCII hex or text.
- Request: **16 bytes**, A first (8 bytes), then B (8 bytes), most significant
  byte first. Each byte contains two unsigned 4-bit matrix elements, high
  nibble first. Both matrices use row-major order.
- Receiving byte 16 automatically pulses LOAD, then START on the next cycle.
- Response: **32 bytes**, C[0,0] through C[3,3], row-major. Each unsigned 10-bit
  result is zero-extended to 16 bits and sent high byte first.
- Wait for the entire response before sending another request. Bytes arriving
  during computation/transmission are discarded. Avoid button operations while
  using UART; after transmission the buttons regain control of the DUT.
- A framing error discards the partial request. A missing byte cannot be
  detected by this fixed-length protocol: reset before retrying. RX overrun is
  sticky in the existing UART receiver and requires reset.
- CPU_RESETN or BTND clears partial requests and aborts transmission.

For example, A = identity and B = all ones:

```text
Send:    10 00 01 00 00 10 00 01 11 11 11 11 11 11 11 11
Receive: 00 01 repeated 16 times
```

USB-UART pins (FPGA perspective) are RX = C4, TX = D4, from the
[Digilent master constraints](https://github.com/Digilent/digilent-xdc/blob/master/Nexys-A7-100T-Master.xdc).
The UART uses clock-enable pulses; all logic runs on the system clock.
The Nexys build assumes inactive reset buttons for its vectorless power estimate.

## Simulation

Run from the repository root (requires Verilator and a C++ compiler):

```sh
verilator --binary --timing -Wno-fatal --top-module tb_DUT_uart \
  --Mdir /tmp/4x4-uart-test \
  DUT/rtl/uart/uart_pkg.sv DUT/rtl/uart/uart_if.sv \
  DUT/rtl/uart/uart_clk.sv DUT/rtl/uart/uart_rx.sv DUT/rtl/uart/uart_tx.sv \
  DUT/rtl/*.sv DUT/tb/tb_DUT_uart.sv
/tmp/4x4-uart-test/Vtb_DUT_uart
```

The test uses faster clock/baud parameters with the same 16x oversampling.
It checks five complete transactions (identity, full scale, mixed matrices,
zero and uniform values), framing-error recovery, and reset during reception.

## Vivado constraints

The board controls and UART pins are asynchronous. Their delay references span
one 100 MHz clock period, and explicit false paths exclude the external I/O
paths from synchronous setup/hold analysis. Register-to-register timing remains
fully checked. Button, switch, and UART RX inputs use two-stage synchronizers.
Configuration voltage settings follow the
[Digilent schematic](https://digilent.com/reference/_media/reference/programmable-logic/nexys-a7/nexys-a7-sch.pdf).

`fpga/power_activity.tcl` assumes the reset buttons are inactive during the
vectorless power estimate; it does not change hardware reset behavior.
