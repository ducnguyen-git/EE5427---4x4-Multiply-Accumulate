# UART compute top

`rtl/compute_unit.sv` is the FPGA top. Ports: `sys_clk`, active-low
`rst_n`, UART `rx` input, UART `tx` output, sticky `finish` and `err` outputs.
Hold reset low at startup. UART is 8 data bits, no parity, one stop bit.
Top parameters `XTAL_FREQ` and `BAUD_RATE` default to 100 MHz and 9600 baud;
set `XTAL_FREQ` to the actual board oscillator frequency.

## Byte protocol

All commands and values are binary bytes, not ASCII.

| Command | Payload | Action |
| --- | --- | --- |
| `00` | 32 bytes, each 0–15 | Load 16 row-major A elements, then 16 row-major B elements |
| `01` | None | Compute A × B after a complete load |
| `02` | One index byte, 0–15 | Read C[index] after `finish`; returns low byte, then upper two bits in a byte |
| `03` | None | Clear finish/error status; retain loaded matrices |

A new load clears `finish`. Compute also clears `finish`, then sets it on
completion. Invalid commands, values, framing errors, and commands while busy
set `err`. An invalid load element aborts that load; restart with `00`.
There are no command acknowledgment bytes. Wait at least five character times
after the final load byte before compute, and after compute before reading.
Wait for both result bytes before sending another command. RX overrun is sticky
inside the UART and requires reset to clear.

## Vivado

Create/open a project for your board's FPGA, then in its Tcl console run:

```tcl
source /path/to/4x4-mac/DUT_4MAC/vivado/compute_unit.tcl
# Example only: replace with the actual board frequency.
set_property generic {XTAL_FREQ=100000000 BAUD_RATE=9600} [current_fileset]
```

This adds the UART package/interface/modules and the RTL, and selects
`compute_unit` as synthesis top. `uart_loop` and the older FPGA wrappers are
not needed. Add a board-specific XDC for all six ports and the input clock.
The UART implementation uses divided pulse signals as clocks; constrain both
`uart_clk_i` TX/RX clock-divider register outputs as generated clocks with
ratios `XTAL_FREQ / BAUD_RATE` and
`(XTAL_FREQ / BAUD_RATE) / 16` (integer division). Review CDC/timing reports for
the RX mailbox crossing before programming hardware. No board pins are assumed.

## Integration simulation

```sh
verilator --binary --timing --assert -Wno-fatal \
  --Mdir /tmp/4mac-compute-test --top-module tb_compute_unit \
  DUT_4MAC/uart/uart_pkg.sv DUT_4MAC/uart/uart_if.sv \
  DUT_4MAC/uart/uart_clk.sv DUT_4MAC/uart/uart_rx.sv \
  DUT_4MAC/uart/uart_tx.sv DUT_4MAC/rtl/*.sv \
  DUT_4MAC/tb/tb_compute_unit.sv
/tmp/4mac-compute-test/Vtb_compute_unit
```
