# UART compute top

`rtl/compute_unit.sv` is the FPGA top. Ports: `sys_clk`, active-low
`rst_n`, UART `rx` input, UART `tx` output, sticky `finish` and `err` outputs.
Hold reset low at startup. UART is 8 data bits, no parity, one stop bit.
Top parameters `XTAL_FREQ` and `BAUD_RATE` default to 100 MHz and 9600 baud;
set `XTAL_FREQ` to the actual board oscillator frequency.
Clock parameter validation rejects settings where either TX or RX divider
rounding raises the effective baud rate by more than 2%. Choose a lower baud
or another clock frequency if this check fails.

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

For synthesis, implementation and bitstream generation on the Nexys A7-100T
(`xc7a100tcsg324-1`), run from `DUT_4MAC`:

```sh
vivado -mode batch -source vivado/compute_unit.tcl
```

With no project open, the script creates an in-memory project and writes
`build/compute_unit/compute_unit.bit`, synthesis/routed checkpoints, and
utilization, timing, CDC and DRC reports. Review timing and CDC reports before
programming hardware, especially the RX mailbox crossing.

To add sources and constraints to an existing Nexys A7-100T project, run:

```tcl
source /path/to/4x4-mac/DUT_4MAC/vivado/compute_unit.tcl
```

With a project open, the script loads sources/constraints and selects
`compute_unit` as top; use Vivado's synthesis, implementation and Generate
Bitstream commands to build. The script sets 100 MHz / 9600 baud parameters;
the generated-clock constraints in `vivado/nexys_a7_100t.xdc` match these values
and must be updated if the clock or baud rate changes.

The constraints map `sys_clk` to E3 (100 MHz), active-low `rst_n` to the CPU
RESET button C12, `finish` to LED0 (H17), and `err` to LED1 (K15).
Press CPU RESET after programming before sending commands.
FPGA `rx` is C4 (USB bridge TX) and FPGA `tx` is D4 (USB bridge RX), following
[Digilent's master constraints](https://github.com/Digilent/digilent-xdc/blob/master/Nexys-A7-100T-Master.xdc).
Connect the computer to the board's **J6 USB PROG/UART** connector with a data
cable, then open its serial port at **9600 baud, 8N1, no hardware flow control**.
The onboard USB-UART bridge handles USB; no external UART adapter is needed.

To program the powered Nexys A7-100T over the same J6 cable after building,
run from `DUT_4MAC` with only that JTAG target connected:

```sh
vivado -mode batch -source vivado/program_board.tcl
```

The script programs `build/compute_unit/compute_unit.bit` into FPGA SRAM,
checks that exactly one target and one matching xc7a100t FPGA are present,
and closes Hardware Manager afterward. Press CPU RESET before using UART.
This configuration is lost when the board is powered off; rerun to reload it.
The bitstream and programming script target the 100T variant, not the 50T.

## Integration simulation

`tb/tb_uart_clk.sv` checks clock parameter acceptance. Simulate it with the
UART package and clock module: defaults and `BAUD_RATE=3125000` must pass;
`BAUD_RATE=2222222` and `BAUD_RATE=3000000` must fail the baud-error check
at time zero (100 MHz clock).

```sh
verilator --binary --timing --assert -Wno-fatal \
  --Mdir /tmp/4mac-compute-test --top-module tb_compute_unit \
  DUT_4MAC/uart/uart_pkg.sv DUT_4MAC/uart/uart_if.sv \
  DUT_4MAC/uart/uart_clk.sv DUT_4MAC/uart/uart_rx.sv \
  DUT_4MAC/uart/uart_tx.sv DUT_4MAC/rtl/*.sv \
  DUT_4MAC/tb/tb_compute_unit.sv
/tmp/4mac-compute-test/Vtb_compute_unit
```
