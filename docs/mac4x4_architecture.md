# MAC4x4 architecture

Based on `rtl/MAC4x4.sv` and `rtl/MAC.sv`. Only the matrix core is shown.

```mermaid
flowchart LR
    A["A[63:0]"] --> AR["matrix_A register · 64 bits\nLOAD enable"]
    B["B[63:0]"] --> BR["matrix_B register · 64 bits\nLOAD enable"]
    LOAD["LOAD"] -.-> AR
    LOAD -.-> BR
    AR --> ROW["4 row buses · 16 bits each\nrow r = matrix_A[63−16r −: 16]"]
    BR --> COL["4 column buses · 16 bits each\ncolumn c = {B₀c, B₁c, B₂c, B₃c}"]
    ROW --> ARRAY["4 × 4 parallel MAC array\n16 instances: MAC(r,c)\nEach receives row r and column c\nCᵣc = Σₖ₌₀³ Aᵣₖ × Bₖc"]
    COL --> ARRAY
    START["START · shared input valid"] -.-> ARRAY
    CLK["clk / rst_n\nshared clock / asynchronous active-low reset"] -.-> AR
    CLK -.-> BR
    CLK -.-> ARRAY
    ARRAY -->|"16 × 10-bit registered results"| PACK["Row-major wiring\nC[159−10(4r+c) −: 10] = Cᵣc"]
    PACK --> C["C[159:0]"]
    ARRAY -->|"done[15:0]"| AND["Reduction AND · &done"]
    AND --> DONE["DONE"]
```

- Matrices contain sixteen unsigned 4-bit elements; element 0 is bits [63:60].
- Each MAC contains four parallel, three-stage `VEDIC4_PIPELINED` multipliers, two registered 9-bit pair sums, and a registered 10-bit final sum.
- START sampled at edge N produces C and DONE at edge N+4; initiation interval is one clock.
- LOAD and START on the same edge submit the previously stored matrices and capture the next matrices.
- C holds its last result when DONE is low. The output packing is wiring, with no extra output register or readout cycle.
