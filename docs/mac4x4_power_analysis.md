# MAC4x4 power analysis

Vivado 2026.1 generated the [improved core power report](mac4x4_power.rpt)
on 2026-11-13 from the routed `MAC4x4` checkpoint for `refactor/v2`.
The [baseline main report](baseline_power.rpt) covers the routed `DUT` core.
Both target Artix-7 `xc7a100tcsg324-1` at 100 MHz in out-of-context mode.

| Estimate | Baseline main | Improved refactor/v2 |
| --- | ---: | ---: |
| Total on-chip power | 0.102 W | 0.129 W |
| Dynamic power | 0.018 W | 0.045 W |
| Device static power | 0.084 W | 0.084 W |
| Confidence | Medium | Medium |

The improved design's additional parallel datapaths and pipeline registers
increase estimated dynamic power. Total on-chip power increases by 27 mW
(26.5%) under the specified activity model. This comparison does not measure
power for equal delivered matrix rates or peak-throughput operation.

The analysis uses vectorless activity propagation. Non-clock inputs are assigned
12.5% toggle rate and 0.5 static probability; reset is held inactive. No workload
simulation activity file is annotated. Typical process and Vivado default
thermal assumptions are used: 25 C ambient and board temperatures, 250 LFM
airflow, a medium heatsink, a medium 10-inch board, and 12–15 layers. These
defaults are not verified physical properties of the target board.

Static power is device-level leakage rather than the isolated core's incremental
cost. The estimates omit external board components, UART, physical I/O buffers,
and full integrated clock infrastructure. Vivado emits OOC port-connectivity
warnings (Power 33-294), while rating input activity coverage High and internal
activity Medium. No measured board-power or energy-per-operation claim follows
from these results. Workload-based SAIF annotation and integrated implementation
are needed for a more representative estimate.

See [baseline versus improved comparison](baseline_vs_improved_comparison.md)
for timing, utilization, power component tables, assumptions, and reproduction
commands. [generate_mac4x4_reports.tcl](generate_mac4x4_reports.tcl) regenerates
improved power with its implementation reports;
[generate_comparison_reports.tcl](generate_comparison_reports.tcl) generates
both power reports using the saved improved checkpoint and a fresh baseline build.
