# Baseline versus improved: performance, timing, utilization, and power

Comparison date: 2026-11-13. Cycle counts below were verified with Icarus
Verilog simulation against the current RTL and the local `main` snapshot.
Throughout this document, **baseline** means the local `main` branch, and
**improved** means the current `refactor/v2` branch. Cached `origin/main` is
listed only to identify the repository state; it is not the physical-report baseline.

## Revisions and scope

| Implementation | Revision | Relevant sources |
| --- | --- | --- |
| Current branch `refactor/v2` | `c72ad8d4d1e0ed6b33d9df36a7d29a9678560294` | `rtl/MAC.sv`, `rtl/MAC4x4.sv`, `rtl/VEDIC4_PIPELINED.sv` |
| Local `main` baseline | `f08ffacd6b11e9832a40903bf0e6493a38d33748` | `DUT/rtl/MAC.sv`, `DUT/rtl/DUT.sv` |
| Cached `origin/main` | `fdba7e608536f72417fa9d4dfd8b18df2c9b5416` | Same MAC, matrix, and UART transport/TX sources as local main |

Local main and cached origin/main differ in board integration: local main
requests a 200 MHz clock through `clk_wiz_0`; cached origin/main uses the
100 MHz oscillator directly. Their arithmetic cycle counts are identical.
No remote fetch was performed; these are the repository's local refs.
The board instantiates `DUT/rtl/DUT.sv` on main, so that matrix implementation
and its `DUT/rtl/MAC.sv` dependencies are the comparison baseline. Main also
contains a separate `rtl/mac_top.sv`, which is not the instantiated matrix core.

## Definitions

Latency is the number of clock intervals from the edge accepting START to
the edge after which the corresponding result and valid signal are available.
Edge N to edge N+4 means four intervals, even though five rising edges are
involved. A synchronous receiver can capture those newly updated outputs on
the next rising edge.

The initiation interval (II) is the minimum number of clocks between accepted
requests. Steady-state throughput is `f_clk / II`. Pipeline latency does not
by itself determine throughput. Unless stated otherwise, inputs have already
been loaded, reset remains inactive, and the consumer can accept each result.

## Core comparison

| Metric | Main | Current `refactor/v2` | Change at equal clock frequency |
| --- | --- | --- | --- |
| Single-MAC architecture | One reused multiplier, shift registers, feedback accumulator | Four parallel 3-stage multipliers, registered balanced adder tree | More arithmetic parallelism |
| Single-MAC START-to-DONE latency | 5 clocks | 4 clocks | 20% less latency |
| Single-MAC II | 6 clocks | 1 clock | 6× dot-product throughput |
| Matrix parallelism | 16 MACs | 16 MACs | Same number of output dot products |
| Logical 4-bit multipliers across matrix core | 16 | 64 | 4× multiplier count |
| Matrix START-to-DONE latency | 6 clocks | 4 clocks | 33.3% less latency; 1.5× latency speedup |
| Matrix compute II | 6 clocks | 1 clock | 6× matrix compute throughput |
| Peak matrix compute throughput | f_clk / 6 | f_clk | Before output-bandwidth limits |
| Result interface | One selected 10-bit element, SELECT[3:0] | All sixteen elements on C[159:0] | Removes element-selection readout |
| LOAD-to-valid latency, START on next edge | 7 clocks | 5 clocks | Includes initial matrix loading |

Main's MAC accepts START only when its internal busy flag is low. START pulses
while busy are ignored. The current MAC treats START as an input-valid strobe
and accepts it on every clock, including consecutive high cycles.

### Where the cycle counts come from

| Edge relative to accepted START | Main MAC | Current MAC |
| --- | --- | --- |
| N | Load operands; clear accumulator/product register; set busy | Register all multiplier quadrant products |
| N+1 | Register product 0; shift operands | Register crosswise sums and diagonals |
| N+2 | Accumulate product 0; register product 1 | Register four completed products |
| N+3 | Accumulate product 1; register product 2 | Register two pair sums |
| N+4 | Accumulate product 2; register product 3 | Register C and assert DONE |
| N+5 | Accumulate product 3; assert MAC DONE; clear busy | Pipeline continues with later requests |
| N+6 | Next START can be accepted; matrix wrapper copies prior MAC results and asserts matrix DONE | Pipeline continues with later requests |

Main's matrix wrapper observes the registered MAC DONE signals on the next
edge, adding one cycle to the five-cycle MAC latency. The current matrix
wrapper wires the MAC results directly to C and reduction-ANDs their valid
signals, so it adds no output-copy cycle.

Both matrix cores have independent LOAD and START controls. If both are high
at one edge, the old stored matrices are submitted while the next pair is
loaded. The current implementation can therefore load the next pair and
start the previous pair every clock after an initial LOAD.

## Time and rate at a common 100 MHz clock

At 100 MHz, one clock interval is 10 ns.

| Metric | Main at 100 MHz | Current at 100 MHz |
| --- | ---: | ---: |
| Single-MAC latency | 50 ns | 40 ns |
| Matrix compute latency | 60 ns | 40 ns |
| Matrix LOAD-to-valid, START next edge | 70 ns | 50 ns |
| Minimum matrix request spacing | 60 ns | 10 ns |
| Peak matrix compute rate | 16.67 million/s | 100 million/s |
| Peak completed dot products across 16 MACs | 266.67 million/s | 1.6 billion/s |
| Equivalent scalar products evaluated | 1.067 billion/s | 6.4 billion/s |

The last row counts 64 scalar multiplications per matrix product, not FPGA
DSP utilization or a separate benchmark. Each dot product sums four products;
these figures are arithmetic capacity, not UART-delivered performance.

Local main's requested 200 MHz clock would give a 25 ns single-MAC latency,
30 ns matrix latency, and 33.33 million matrix computations/s if that
implementation meets timing. Compared with the current 100 MHz target, that
is a 3× compute-throughput improvement for current, while main's requested
200 MHz configuration has lower absolute latency. This is a clock-frequency
comparison, not the equal-frequency architectural comparison above. The physical
comparison below implements both cores at 100 MHz; it does not verify main's
requested 200 MHz board configuration.

The saved [current implementation report](mac4x4_implementation_report.md)
records routed out-of-context internal timing at 100 MHz, with WNS +5.532 ns
and WHS +0.096 ns. External I/O delays and integrated clock insertion/skew
are unspecified. These reports do not establish maximum operating frequency
or end-to-end board timing closure. Current
[`top_fpga_wrapper.sv`](../rtl/top_fpga_wrapper.sv) clocks the core directly
from CLK100MHZ; its CLK_FREQ parameter configures UART dividers rather than
generating a faster core clock.

## Design timing summary comparison

Both physical implementations target `xc7a100tcsg324-1` using Vivado 2026.1,
with an out-of-context 10.000 ns clock (100 MHz), followed by optimization,
placement, physical optimization, and routing. Baseline reports were generated
from local main. Improved reports use the existing routed refactor/v2
checkpoint that produced the saved timing and utilization reports.
UART logic, board peripherals, physical I/O buffers, and top-level clock
buffers are excluded from both cores.

| Post-route metric | Baseline: main | Improved: refactor/v2 |
| --- | ---: | ---: |
| Clock period | 10.000 ns | 10.000 ns |
| Worst setup slack (WNS) | +5.147 ns | +5.532 ns |
| Total negative setup slack (TNS) | 0.000 ns | 0.000 ns |
| Failing setup endpoints / total | 0 / 2001 | 0 / 4672 |
| Worst hold slack (WHS) | +0.113 ns | +0.096 ns |
| Total negative hold slack (THS) | 0.000 ns | 0.000 ns |
| Failing hold endpoints / total | 0 / 2001 | 0 / 4672 |
| Worst pulse-width slack | +4.500 ns | +4.500 ns |
| Pulse-width failing endpoints / total | 0 / 1169 | 0 / 3024 |
| Unconstrained internal endpoints | 0 | 0 |
| Inputs without input-delay constraints | 131 | 131 |
| Outputs without output-delay constraints | 11 | 161 |
| Fully routed / routable nets | 1545 / 1545 | 3220 / 3220 |
| Nets with routing errors | 0 | 0 |

Both pass their specified internal timing constraints. Improved has 0.385 ns
more setup slack and 0.017 ns less hold slack; both hold values remain positive.
Slack is timing margin, distinct from the request latency discussed above.
It does not by itself establish a maximum achievable clock frequency.

The OOC clock source location (`HD.CLK_SRC`) and boundary partition-pin locations
are unset. Actual integrated clock insertion/skew and interface routing/delays
remain unverified. The different output-delay counts reflect the narrow
baseline interface versus the improved full-matrix bus. These are core-only
results, not board-level timing signoff. Both runs also emit the OOC DRC and
unavailable tile-splitting-file warnings described in the implementation report.

Sources: [baseline timing](baseline_timing.rpt),
[improved timing](mac4x4_timing.rpt),
[baseline route status](baseline_route_status.rpt), and
[improved route status](mac4x4_route_status.rpt).

## Utilization comparison

| Post-route resource | Baseline: main | Improved: refactor/v2 | Change in used count |
| --- | ---: | ---: | ---: |
| Slice LUTs | 1060 / 63400 (1.67%) | 1524 / 63400 (2.40%) | +464 (+43.8%) |
| Flip-flops | 1169 / 126800 (0.92%) | 3024 / 126800 (2.38%) | +1855 (+158.7%) |
| Occupied slices | 325 / 15850 (2.05%) | 643 / 15850 (4.06%) | +318 (+97.8%) |
| Block RAM tiles | 0 / 135 | 0 / 135 | 0 |
| DSPs | 0 / 240 | 0 / 240 | 0 |

The improved core trades more arithmetic logic and pipeline registers for
six times the compute throughput at equal frequency. Both map multiplication
and addition to LUT logic rather than dedicated DSP blocks. Mapped resource
counts include synthesis optimizations and are not proportional to the number
of logical multiplier instances. The baseline includes its selection mux and
output-copy registers; improved includes its full parallel result interface.

Sources: [baseline utilization](baseline_utilization.rpt),
[improved utilization](mac4x4_utilization.rpt),
[baseline hierarchy](baseline_utilization_hierarchical.rpt), and
[improved hierarchy](mac4x4_utilization_hierarchical.rpt).

## Power comparison

The following are **post-route vectorless estimates**, not measured FPGA or
board power. Both use a 100 MHz clock, typical silicon process, commercial
grade, and the same Vivado environment defaults: 25 C ambient/board
temperature, 250 LFM airflow, medium heatsink, medium 10-inch board, and
12–15 board layers. These thermal defaults are modeling assumptions, not a
description of the Nexys board or laboratory conditions.

Non-clock input activity is specified as a 12.5% toggle rate with 0.5 static
probability; rst_n is held inactive (probability 1, toggle rate 0). Internal
activity is propagated by Vivado with no SAIF/VCD workload annotation.
Both reports rate overall confidence as **Medium**, with internal activity
the limiting factor. These assumptions do not model a legal stream of
requests at each architecture's maximum accepted rate or equal useful work.

| Estimated power metric | Baseline: main | Improved: refactor/v2 | Difference |
| --- | ---: | ---: | ---: |
| Total on-chip power | 0.102 W | 0.129 W | +0.027 W (+26.5%) |
| Dynamic power | 0.018 W | 0.045 W | +0.027 W (+150%) |
| Device static power | 0.084 W | 0.084 W | Unchanged at report precision |
| Clock component | 0.010 W | 0.023 W | +0.013 W |
| Slice logic component | 0.005 W | 0.013 W | +0.008 W |
| Signal component | 0.004 W | 0.009 W | +0.005 W |
| Estimated junction temperature | 25.5 C | 25.6 C | +0.1 C |
| Overall confidence | Medium | Medium | Same |

Values are rounded by Vivado, so rounded component sums may differ from the
reported total. Static power is a device-level estimate, not incremental power
attributable solely to the MAC core. OOC results exclude physical board I/O
and full top-level clock infrastructure. Vivado emits Power 33-294 port
connectivity warnings on the unbuffered OOC interfaces; both power reports
still classify input activity coverage as High. These warnings and the absence
of workload annotation limit interpretation of the estimates.

Under these assumptions, improved consumes more estimated dynamic power,
consistent with its additional parallel arithmetic and registers. The sixfold
architectural throughput gain must not be combined with this vectorless power
ratio to claim measured energy per matrix or energy efficiency. A defensible
energy comparison requires activity from matched legal workloads, annotated
onto each implemented netlist, and integration-aware power analysis.

Sources: [baseline power](baseline_power.rpt),
[improved power](mac4x4_power.rpt), and
[power analysis notes](mac4x4_power_analysis.md).

## Result readout and sustainable system throughput

Main computes all sixteen results together but exposes only one selected
element. A consumer reading one element per clock needs sixteen selection
slots per matrix, even though SELECT is combinational. There is only one
stored output matrix, so repeatedly computing every six clocks overwrites
results before such a consumer can read all sixteen. Its ideal complete-matrix
readout rate is at most `f_clk/16` under this sampling assumption, with
requests scheduled to prevent overwrites; controller overhead can reduce it.
The six-clock compute II is therefore not a sustainable full-matrix delivery
rate over that narrow interface. Adding six compute clocks and sixteen readout
clocks describes a non-overlapped controller schedule, not an intrinsic core II.

The current core exposes all 160 result bits simultaneously, allowing a suitably
wide downstream consumer to sustain one matrix per clock. At 100 MHz that
requires accepting 16 Gbit/s of result payload and supplying 12.8 Gbit/s of
new A/B payload. A slow consumer needs buffering or must limit START requests;
the core has no output backpressure or result queue.

### UART application

Both UART protocols receive 16 request bytes and return 32 response bytes
using 9600-baud 8N1 by default. One byte takes ten bit periods. Both transports
handle one transaction at a time, so request and response times must be added.

| Wire-time metric at nominal 9600 baud | Main | Current |
| --- | ---: | ---: |
| Request payload plus framing, 160 bits | 16.67 ms | 16.67 ms |
| Response, first start bit through final stop bit | Approximately 43.02 ms | 33.33 ms |
| Request + response wire-time lower bound | Approximately 59.69 ms | 50.00 ms |
| Transaction-rate upper bound from those times | Approximately 16.75 matrices/s | 20 matrices/s |

Main's `uart_tx` spends extra baud ticks finishing a byte, accepting the next
request, and latching the next frame. With its transport FSM and normal
system-clock/baud ratios, successive start bits are thirteen baud ticks apart:
ten frame bits plus three idle bit periods. Thus the first-to-last response
span is `32*10 + 31*3 = 413` bit periods. Current TX emits consecutive frames
with exactly one stop bit per byte, taking 320 bit periods. The response span
improves by approximately 1.29×, and the request-plus-response bound improves
by approximately 1.19×, rather than the core's 6× gain.

These UART figures are RTL-derived nominal wire-time estimates, not measured
host benchmarks. Receiver synchronization, LOAD/START, completion detection,
initial TX phase alignment, main's post-frame completion tick, host gaps, and
integer baud-divider rounding affect actual latency. Current removes the
inter-byte gaps, but serial transport still dominates the nanosecond-scale
core calculation.

## Reproducible cycle verification

[`tb_performance.sv`](../tb/tb_performance.sv) instantiates both a single MAC
and its matrix wrapper, loads all-one matrices, and holds START high for
thirty clocks. It checks the exact output-valid pattern, first-result latency,
completion spacing, and result values. Main's narrow output is checked at
SELECT=0; every element is checked on the current wide output.

Run from the repository root with Icarus Verilog and vvp on PATH:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File tb/run_performance_comparison.ps1
```

The runner exports baseline sources to `build/performance_comparison/`,
compiles each implementation separately, and leaves the working branch
unchanged. Pass `-Baseline origin/main` to compare the cached remote snapshot.
The execution-policy option applies only to that PowerShell process.

Observed results for local main:

```text
PASS: MAC latency=5, matrix latency=6, initiation interval=6 clocks; 5 dot / 4 matrix results
PASS: MAC latency=4, matrix latency=4, initiation interval=1 clocks; 26 dot / 26 matrix results
```

The existing randomized matrix regression additionally covers different input
matrices, valid bubbles, loading order, output holding, and reset. The focused
performance check validates architectural cycle counts; it does not measure
physical clock frequency or UART transaction timing.

## Reproducing physical reports

With Vivado on PATH, run from the repository root:

```powershell
vivado -mode batch -source docs/generate_mac4x4_reports.tcl -log build/mac4x4_reports.log -journal build/mac4x4_reports.jou
vivado -mode batch -source docs/generate_comparison_reports.tcl -log build/comparison_reports.log -journal build/comparison_reports.jou
```

The first command implements improved RTL and writes its routed checkpoint,
timing, utilization, route status, and power reports. The second exports local
main's sources without changing branches, implements the baseline with the
same flow, and produces baseline reports plus power for both routed designs.
Regenerate the improved checkpoint after any RTL changes before running the
second command. Scripts: [improved flow](generate_mac4x4_reports.tcl) and
[comparison flow](generate_comparison_reports.tcl).
The [provenance record](comparison_report_provenance.txt) identifies the
baseline revision, improved checkpoint, and analysis assumptions. Raw reports
are saved in docs; logs and checkpoints remain in build.
