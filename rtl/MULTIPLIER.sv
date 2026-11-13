module Multiple_multiplier #(
    parameter WIDTH = 4
)(
    input  logic [WIDTH-1:0]   A,
    input  logic [WIDTH-1:0]   B,
    output logic [2*WIDTH-1:0] C
);
    // Recursive Urdhva Tiryagbhyam (vertical and crosswise) multiplication.
    // Split A/B into high and low halves:
    // A*B = low*low + ((high*low + low*high) << HALF)
    //                    + (high*high << (2*HALF)).
    generate
        if (WIDTH == 1) begin : GEN_BIT
            assign C = {1'b0, A[0] & B[0]};
        end else if (WIDTH == 2) begin : GEN_2X2
            // Direct vertical/crosswise base case: two half-adders.
            logic cross_carry;
            assign C[0] = A[0] & B[0];
            Half_Adder cross_adder (
                .a(A[1] & B[0]), .b(A[0] & B[1]),
                .s(C[1]), .cout(cross_carry)
            );
            Half_Adder high_adder (
                .a(A[1] & B[1]), .b(cross_carry), .s(C[2]), .cout(C[3])
            );
        end else begin : GEN_VEDIC
            localparam HALF = (WIDTH + 1) / 2;
            localparam PAD_WIDTH = 2 * HALF;
            logic [PAD_WIDTH-1:0] padded_a, padded_b;
            logic [2*HALF-1:0] low_low, high_low, low_high, high_high;
            logic [2*HALF:0] cross_sum;
            logic [4*HALF-1:0] cross_shifted, product;

            // Zero extension also supports odd operand widths.
            assign padded_a = {{(PAD_WIDTH-WIDTH){1'b0}}, A};
            assign padded_b = {{(PAD_WIDTH-WIDTH){1'b0}}, B};

            Multiple_multiplier #(.WIDTH(HALF)) mul_ll (
                .A(padded_a[HALF-1:0]), .B(padded_b[HALF-1:0]), .C(low_low)
            );
            Multiple_multiplier #(.WIDTH(HALF)) mul_hl (
                .A(padded_a[PAD_WIDTH-1:HALF]), .B(padded_b[HALF-1:0]), .C(high_low)
            );
            Multiple_multiplier #(.WIDTH(HALF)) mul_lh (
                .A(padded_a[HALF-1:0]), .B(padded_b[PAD_WIDTH-1:HALF]), .C(low_high)
            );
            Multiple_multiplier #(.WIDTH(HALF)) mul_hh (
                .A(padded_a[PAD_WIDTH-1:HALF]), .B(padded_b[PAD_WIDTH-1:HALF]), .C(high_high)
            );

            // Preserve the extra carry bit in the crosswise sum.
            Multiple_adder #(.WIDTH(2*HALF+1)) add_cross (
                .A({1'b0, high_low}), .B({1'b0, low_high}), .C(cross_sum)
            );
            assign cross_shifted = {{(HALF-1){1'b0}}, cross_sum, {HALF{1'b0}}};
            Multiple_adder #(.WIDTH(4*HALF)) add_product (
                .A({high_high, low_low}), .B(cross_shifted), .C(product)
            );
            assign C = product[2*WIDTH-1:0];
        end
    endgenerate
endmodule
