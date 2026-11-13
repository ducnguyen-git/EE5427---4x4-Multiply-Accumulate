# MAC4x4 module specification

Version 1.0 · 2026-11-13 · Specification of the current RTL

## 1. Purpose and scope

`MAC4x4` computes the product of two 4 × 4 matrices of unsigned 4-bit
integers. It produces all sixteen unsigned 10-bit result elements in parallel.
This document covers the matrix core and its internal MAC datapath. UART
transport, FPGA board integration, and host software are outside its scope.

The implementation sources are [MAC4x4.sv](../rtl/MAC4x4.sv),
[MAC.sv](../rtl/MAC.sv), [VEDIC4_PIPELINED.sv](../rtl/VEDIC4_PIPELINED.sv),
[MULTIPLIER.sv](../rtl/MULTIPLIER.sv), and [ADDER.sv](../rtl/ADDER.sv).
See the [architectural block diagram](mac4x4_architecture.svg).

## 2. Interface

```systemverilog
module MAC4x4 (
    input  logic         clk, rst_n, LOAD, START,
    input  logic [63:0]  A, B,
    output wire  [159:0] C,
    output wire          DONE
);
```

| Port | Direction | Width | Definition |
| --- | --- | ---: | --- |
| `clk` | Input | 1 | Rising-edge clock for all registers |
| `rst_n` | Input | 1 | Asynchronous, active-low reset; overrides LOAD and START |
| `LOAD` | Input | 1 | Capture both A and B into internal matrix registers on this edge |
| `START` | Input | 1 | Submit the previously stored matrices on this edge |
| `A` | Input | 64 | Packed row-major matrix A; sixteen unsigned 4-bit elements |
| `B` | Input | 64 | Packed row-major matrix B; sixteen unsigned 4-bit elements |
| `C` | Output | 160 | Packed row-major result; sixteen unsigned 10-bit elements |
| `DONE` | Output | 1 | Output-valid indication for the complete result matrix |

All ports listed above are exposed at the module boundary. The dimensions and
widths are fixed; the module has no parameters. There is no ready/busy signal
or output backpressure. Inputs must satisfy the implementing device's setup
and hold requirements at their sampling edges. Reset release must satisfy the
device's recovery/removal requirements; any required synchronization belongs
to the integrating design.

## 3. Arithmetic and packing

For row `r` and column `c` in 0 through 3:

```text
C[r,c] = A[r,0] × B[0,c]
       + A[r,1] × B[1,c]
       + A[r,2] × B[2,c]
       + A[r,3] × B[3,c]
```

Each input element is an integer in [0, 15]. Products are in [0, 225], pair
sums are in [0, 450], and final results are in [0, 900]. The respective storage
widths are 8, 9, and 10 bits. Results are exact for all legal inputs; no
rounding, saturation, signed arithmetic, or overflow flag is needed.
Each request computes a new matrix product; results are not accumulated
across requests and the previous C is not an arithmetic operand.

The first element is at the most significant end of each packed bus:

```systemverilog
A_rc = A[63  - 4*(4*r+c)  -: 4];
B_rc = B[63  - 4*(4*r+c)  -: 4];
C_rc = C[159 - 10*(4*r+c) -: 10];
```

| Row | A/B element slices, columns 0 → 3 | C element slices, columns 0 → 3 |
| --- | --- | --- |
| 0 | [63:60], [59:56], [55:52], [51:48] | [159:150], [149:140], [139:130], [129:120] |
| 1 | [47:44], [43:40], [39:36], [35:32] | [119:110], [109:100], [99:90], [89:80] |
| 2 | [31:28], [27:24], [23:20], [19:16] | [79:70], [69:60], [59:50], [49:40] |
| 3 | [15:12], [11:8], [7:4], [3:0] | [39:30], [29:20], [19:10], [9:0] |

## 4. Input transaction behavior

The following table applies on each rising edge while `rst_n=1`.

| LOAD | START | Behavior |
| ---: | ---: | --- |
| 0 | 0 | Retain stored matrices; accept no new operation; in-flight work advances |
| 1 | 0 | Capture A and B; accept no new operation |
| 0 | 1 | Submit the stored matrices; retain them for possible reuse |
| 1 | 1 | Submit the old stored matrices and capture A/B for a subsequent request |

LOAD and START are independent level-sampled strobes. Each high clock cycle
performs the corresponding action; there is no rising-edge detector. A/B are
ignored when LOAD is low. START does not directly sample the external A/B buses.

To compute newly supplied matrices, assert LOAD at edge L and START at edge
L+1 or later. Once START is accepted, later LOAD operations cannot alter that
request. With LOAD and START continuously high, every edge submits the pair
loaded on the preceding edge and loads the next pair. After reset, a START
before the first LOAD submits the reset-initialized zero matrices.

## 5. Pipeline timing and output behavior

For START sampled at rising edge N, the corresponding C and DONE become valid
after edge N+4, following register propagation. This is four clock intervals
of latency across five registered arithmetic stages. The input matrix storage
is separate from these five stages.

| Edge | Stage | Work for the request sampled at N |
| --- | --- | --- |
| N | 1: quadrant products | Register the 2 × 2-bit partial products of all element multiplications |
| N+1 | 2: crosswise sums | Register crosswise sums and aligned diagonal products |
| N+2 | 3: complete products | Register all 64 unsigned 8-bit products |
| N+3 | 4: pair sums | Register two unsigned 9-bit sums per MAC |
| N+4 | 5: final results | Register sixteen unsigned 10-bit results; assert DONE |

While reset stays inactive, the output valid sampled just after edge N+4 equals
the START sampled at edge N. Reset cancels that relationship for flushed work.

- The initiation interval is one clock: consecutive START cycles are accepted.
- Results remain in request order; all sixteen elements update together.
- DONE is an output-valid signal. Consecutive results may keep it high for
  multiple cycles; consumers must sample each high cycle rather than only its
  rising edge.
- A low START cycle inserts a valid bubble that appears at DONE four edges later.
- When DONE is low, C retains its last valid result, except that reset clears C.
- C connects directly to the MAC result registers; there is no extra matrix
  output-copy cycle or sequential element-selection interface.

Example for two requests, X and Y, starting with no in-flight work:

| Edge | LOAD | START | Input matrices | Operation submitted | DONE after edge | C after edge |
| --- | ---: | ---: | --- | --- | ---: | --- |
| 0 | 1 | 0 | X | — | 0 | Previous/reset value |
| 1 | 1 | 1 | Y | X | 0 | Held |
| 2 | 0 | 1 | Ignored | Y | 0 | Held |
| 3 | 0 | 0 | Ignored | — | 0 | Held |
| 4 | 0 | 0 | Ignored | — | 0 | Held |
| 5 | 0 | 0 | Ignored | — | 1 | Product X |
| 6 | 0 | 0 | Ignored | — | 1 | Product Y |
| 7 | 0 | 0 | Ignored | — | 0 | Product Y held |

A receiving synchronous block observes the newly updated outputs after the
listed edge and can capture them at the next rising edge.

## 6. Reset

Asserting rst_n low clears both internal input matrices, all arithmetic pipeline
registers, the result matrix C, and all valid registers, including DONE,
without waiting for a clock edge. Reset has priority over all other activity.

All in-flight requests are discarded. No completion for a discarded request
may be expected after reset. Following reset release, normal acceptance resumes
on rising edges; the earliest result follows a new START by four clock intervals.

## 7. Internal architecture

Two 64-bit LOAD-enabled registers store the matrices. Static wiring distributes
each 16-bit A row and each assembled 16-bit B column to the appropriate MAC.
Sixteen parallel MAC instances compute the sixteen dot products.

Each MAC contains four parallel three-stage `VEDIC4_PIPELINED` multipliers,
two 9-bit pair-sum adders with registers, and one 10-bit final adder with an
output register. Arithmetic additions use the reusable CLA-based
`Multiple_adder`. There are 64 logical 4 × 4-bit multipliers and 48 dot-product
tree adders across the core; the multiplier pipelines contain additional
partial-product arithmetic. These logical counts are distinct from mapped
FPGA primitive utilization.

All MACs share clk, rst_n, and START. Their output-valid signals form
`done[15:0]`, and module DONE is the combinational reduction `&done`.

## 8. Performance and implementation evidence

The functional contract requires a one-clock initiation interval and four-clock
START-to-result latency. Operating frequency depends on implementation and
integration constraints.

The 2026-11-13 Vivado 2026.1 out-of-context routed run for
`xc7a100tcsg324-1` used a 10 ns clock constraint:

| Metric | Recorded result |
| --- | ---: |
| Target clock | 100 MHz |
| Worst setup slack | +5.532 ns |
| Worst hold slack | +0.096 ns |
| LUTs | 1524 (2.40%) |
| Flip-flops | 3024 (2.38%) |
| Block RAM / DSPs | 0 / 0 |

These are implementation observations, not portable resource or frequency
guarantees. External I/O delays and integrated clock insertion/skew remain
unspecified in that run. See the [implementation report](mac4x4_implementation_report.md)
for the complete scope and limitations. At the 100 MHz target, the core's
functional timing corresponds to 40 ns from START sampling to updated output,
with a steady-state capacity of 100 million matrix products per second when
the surrounding system supplies and consumes a transaction every clock.

## 9. Verification acceptance criteria

An implementation conforming to this specification must satisfy:

| Area | Required behavior |
| --- | --- |
| Arithmetic | Every valid result equals the unsigned mathematical matrix product |
| Packing | All sixteen elements occupy the slices specified in section 3 |
| Maximum values | All-15 input matrices produce 900 in every output element |
| Identity / zero | Identity multiplication preserves elements; zero operands produce zero |
| Valid timing | DONE follows START by four clock intervals while reset remains inactive |
| Streaming | Consecutive START cycles produce consecutive ordered results |
| Bubbles | Low START cycles produce matching DONE bubbles and C holds |
| Loading | START uses stored matrices; simultaneous LOAD uses old data for that request |
| Reset | Clears outputs and stored operands and flushes pending requests |

The existing [matrix testbench](../tb/tb_MAC4x4.sv) checks full-rate streams,
matrix ordering, valid bubbles, LOAD/START ordering, result holding, maximum
inputs, and reset during traffic against a software-style mathematical model.
Supporting arithmetic and pipeline tests are run by:

```powershell
powershell -NoProfile -File tb/run_tests.ps1
```

This specification was checked against the RTL and existing testbench; no new
simulation run is implied by the creation of this document.
