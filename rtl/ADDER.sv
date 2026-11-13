// Multi-bit adder built from 4-bit CLA blocks with direct block look-ahead.
module Multiple_adder #(
    parameter WIDTH = 8
)(
    input logic [WIDTH-1:0] A, B,
    output wire [WIDTH-1:0] C
);
    localparam BLOCKS = (WIDTH + 3) / 4;
    localparam PAD_WIDTH = BLOCKS * 4;
    wire [PAD_WIDTH-1:0] padded_a = PAD_WIDTH'(A);
    wire [PAD_WIDTH-1:0] padded_b = PAD_WIDTH'(B);

    generate
        if (BLOCKS == 1) begin : GEN_SINGLE
            CLA4 #(.SUM_WIDTH(WIDTH)) cla (
                .a(padded_a), .b(padded_b), .cin(1'b0), .s(C),
                .cout(), .group_p(), .group_g()
            );
        end else begin : GEN_MULTI
            // Only the lower blocks generate carries consumed by another block.
            wire [BLOCKS-2:0] group_g;
            for (genvar i = 0; i < BLOCKS; i++) begin : GEN_BLOCK
                localparam SUM_WIDTH = (WIDTH-4*i >= 4) ? 4 : WIDTH-4*i;
                wire carry_in;
                if (i == 0) begin : GEN_FIRST
                    assign carry_in = 1'b0;
                end else begin : GEN_LOOKAHEAD
                    wire [i-1:0] terms;
                    for (genvar j = 0; j < i; j++) begin : GEN_TERM
                        if (j == i-1) begin : GEN_DIRECT
                            assign terms[j] = group_g[j];
                        end else begin : GEN_PROPAGATE
                            // Propagate across all intervening bits in parallel.
                            assign terms[j] = group_g[j] &
                                (&(padded_a[4*i-1:4*(j+1)] ^ padded_b[4*i-1:4*(j+1)]));
                        end
                    end
                    assign carry_in = |terms;
                end
                if (i == BLOCKS-1) begin : GEN_LAST
                    CLA4 #(.SUM_WIDTH(SUM_WIDTH)) cla (
                        .a(padded_a[4*i +: 4]), .b(padded_b[4*i +: 4]),
                        .cin(carry_in), .s(C[4*i +: SUM_WIDTH]),
                        .cout(), .group_p(), .group_g()
                    );
                end else begin : GEN_LOWER
                    CLA4 cla (
                        .a(padded_a[4*i +: 4]), .b(padded_b[4*i +: 4]),
                        .cin(carry_in), .s(C[4*i +: 4]),
                        .cout(), .group_p(), .group_g(group_g[i])
                    );
                end
            end
        end
    endgenerate
endmodule

// SUM_WIDTH trims only the sum port of a partially used final block.
// The propagate/generate and carry-out ports always describe all four bits.
module CLA4 #(
    parameter SUM_WIDTH = 4
)(
    input logic [3:0] a, b,
    input logic cin,
    output wire [SUM_WIDTH-1:0] s,
    output wire cout, group_p, group_g
);
    wire [3:0] p = a ^ b;
    wire [3:0] g = a & b;
    wire [SUM_WIDTH-1:0] c;
    assign group_p = &p;
    assign group_g = g[3] | (p[3] & g[2])
                   | (p[3] & p[2] & g[1])
                   | (p[3] & p[2] & p[1] & g[0]);
    assign c[0] = cin;
    generate
        if (SUM_WIDTH > 1) begin : GEN_C1
            assign c[1] = g[0] | (p[0] & cin);
        end
        if (SUM_WIDTH > 2) begin : GEN_C2
            assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & cin);
        end
        if (SUM_WIDTH > 3) begin : GEN_C3
            assign c[3] = g[2] | (p[2] & g[1])
                        | (p[2] & p[1] & g[0])
                        | (p[2] & p[1] & p[0] & cin);
        end
    endgenerate
    assign s = p[SUM_WIDTH-1:0] ^ c;
    assign cout = group_g | (group_p & cin);
endmodule

module Full_Adder (
    input logic a, b, cin,
    output wire s, cout
);
    assign s = a ^ b ^ cin;
    assign cout = (a & b) | (cin & (a ^ b));
endmodule

module Half_Adder (
    input logic a, b,
    output wire s, cout
);
    assign s = a ^ b;
    assign cout = a & b;
endmodule
