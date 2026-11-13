module Multiple_multiplier #(
    parameter WIDTH = 4
)(
    input logic [WIDTH-1:0] A, B,
    output wire [2*WIDTH-1:0] C
);
    // Urdhva Tiryagbhyam: vertical products and crosswise quadrant sums.
    // Explicit generated levels avoid a self-instantiating module hierarchy.
    generate
        if (WIDTH == 1) begin : GEN_BIT
            assign C = {1'b0, A[0] & B[0]};
        end else if (WIDTH == 2) begin : GEN_2X2
            wire cross_carry;
            assign C[0] = A[0] & B[0];
            Half_Adder cross_adder (
                .a(A[1] & B[0]), .b(A[0] & B[1]),
                .s(C[1]), .cout(cross_carry)
            );
            Half_Adder high_adder (
                .a(A[1] & B[1]), .b(cross_carry), .s(C[2]), .cout(C[3])
            );
        end else begin : GEN_VEDIC
            localparam LEVELS = $clog2(WIDTH);
            localparam PAD_WIDTH = 2**LEVELS;
            wire [PAD_WIDTH-1:0] padded_a = PAD_WIDTH'(A);
            wire [PAD_WIDTH-1:0] padded_b = PAD_WIDTH'(B);
            for (genvar level = 0; level <= LEVELS; level++) begin : GEN_LEVEL
                localparam CHUNK = 2**level;
                localparam COUNT = PAD_WIDTH / CHUNK;
                wire [2*CHUNK-1:0] product [0:COUNT-1][0:COUNT-1];
                for (genvar row = 0; row < COUNT; row++) begin : GEN_ROW
                    for (genvar col = 0; col < COUNT; col++) begin : GEN_COL
                        if (level == 0) begin : GEN_LEAF
                            assign product[row][col] = {1'b0, padded_a[row] & padded_b[col]};
                        end else begin : GEN_COMBINE
                            localparam HALF = CHUNK / 2;
                            wire [CHUNK:0] cross_sum;
                            wire [2*CHUNK-1:0] diagonal, cross_shifted;
                            Multiple_adder #(.WIDTH(CHUNK+1)) add_cross (
                                .A({1'b0, GEN_LEVEL[level-1].product[2*row+1][2*col]}),
                                .B({1'b0, GEN_LEVEL[level-1].product[2*row][2*col+1]}),
                                .C(cross_sum)
                            );
                            assign diagonal = {GEN_LEVEL[level-1].product[2*row+1][2*col+1],
                                               GEN_LEVEL[level-1].product[2*row][2*col]};
                            assign cross_shifted = (2*CHUNK)'(cross_sum) << HALF;
                            Multiple_adder #(.WIDTH(2*CHUNK)) add_product (
                                .A(diagonal), .B(cross_shifted), .C(product[row][col])
                            );
                        end
                    end
                end
            end
            assign C = GEN_LEVEL[LEVELS].product[0][0][2*WIDTH-1:0];
        end
    endgenerate
endmodule
