module Multiple_multiplier #(
    parameter WIDTH = 4
)(
    input  logic [WIDTH-1:0]   A,
    input  logic [WIDTH-1:0]   B,
    output logic [2*WIDTH-1:0] C
);

    // Partial products
    logic [2*WIDTH-1:0] partial [0:WIDTH-1];

    // Intermediate sums
    logic [2*WIDTH-1:0] sum [0:WIDTH-1];


    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : GEN_PP

            assign partial[i] =
                ({{WIDTH{1'b0}}, A} & {2*WIDTH{B[i]}}) << i;

        end
    endgenerate

    assign sum[0] = partial[0];

    genvar j;
    generate
        for (j = 1; j < WIDTH; j = j + 1) begin : GEN_ADD

            Multiple_adder #(
                .WIDTH(2*WIDTH)
            ) ADDER (
                .A(sum[j-1]),
                .B(partial[j]),
                .C(sum[j])
            );

        end
    endgenerate

    assign C = sum[WIDTH-1];
endmodule
