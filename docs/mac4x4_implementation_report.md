# MAC4x4 timing and utilization report

Generated on 2026-11-13 using Vivado 2026.1, build 6511674, from the current local RTL.
The top module is `MAC4x4`; UART and FPGA wrapper logic are excluded.
Target: Artix-7 `xc7a100tcsg324-1`. Results are from a fresh out-of-context synthesis,
optimization, placement, physical optimization, and routing run.

## Timing

Clock `core_clk` is constrained to 10.000 ns (100 MHz).

| Metric | Post-route result |
| --- | ---: |
| Worst setup slack (WNS) | +5.532 ns |
| Total negative setup slack (TNS) | 0.000 ns |
| Setup failing endpoints | 0 / 4672 |
| Worst hold slack (WHS) | +0.096 ns |
| Total negative hold slack (THS) | 0.000 ns |
| Hold failing endpoints | 0 / 4672 |
| Worst pulse-width slack | +4.500 ns |
| Unconstrained internal endpoints | 0 |

All specified timing constraints are met. This validates the constrained internal
paths at 100 MHz under this out-of-context timing model.

Boundary timing remains unspecified: 131 input ports lack input delays and 161
output ports lack output delays. No boundary timing exceptions are added to hide
these checks. Vivado also warns that `HD.CLK_SRC` is unset, so top-level clock
insertion delay and skew are not modeled. Interface ports have no
`HD.PARTPIN_LOCS`; their partial routing is unavailable. Vivado additionally
reported Constraints 18-8777 (unable to split tiles because required files are
unavailable) and the standard out-of-context connectivity DRC limitation.
These results do not establish board/interface timing closure or a measured
maximum operating frequency. Recheck timing after integration with the clock,
reset, and external interface constraints.

## Utilization

| Resource | Used | Available | Utilization |
| --- | ---: | ---: | ---: |
| Slice LUTs | 1524 | 63400 | 2.40% |
| Flip-flops | 3024 | 126800 | 2.38% |
| Occupied slices | 643 | 15850 | 4.06% |
| Block RAM tiles | 0 | 135 | 0.00% |
| DSPs | 0 | 240 | 0.00% |

Arithmetic maps to LUT logic. No I/O buffers or global clock buffers are inserted
for this out-of-context core. All 3220 routable nets are fully routed, with zero
routing errors; the 293 interface ports are listed as implicitly routed.

## Full reports and reproduction

- [Post-route timing summary and paths](mac4x4_timing.rpt)
- [Post-route utilization](mac4x4_utilization.rpt)
- [Hierarchical utilization](mac4x4_utilization_hierarchical.rpt)
- [Route status](mac4x4_route_status.rpt)
- [Vivado generation script](generate_mac4x4_reports.tcl)

From the repository root, with Vivado on PATH:

```powershell
vivado -mode batch -source docs/generate_mac4x4_reports.tcl -log build/mac4x4_reports.log -journal build/mac4x4_reports.jou
```

The script reads `ADDER.sv`, `MULTIPLIER.sv`, `VEDIC4_PIPELINED.sv`, `MAC.sv`,
and `MAC4x4.sv` from `rtl/`. The routed checkpoint is saved under
`build/mac4x4_reports/`; full run logs are under `build/`.
