// Parallel products and registered balanced tree; accepts START every clock.
// A request sampled on edge N produces C/DONE on edge N+4.
module MAC (
    input logic clk, rst_n, START,
    input logic [15:0] A, B,
    output logic [9:0] C,
    output logic DONE
);
    logic [7:0] product [0:3];
    logic [3:0] product_valid;
    logic [8:0] pair_sum [0:1], pair_r [0:1];
    logic [9:0] result;
    logic pair_valid;
    for (genvar i = 0; i < 4; i++) begin : GEN_PRODUCT
        VEDIC4_PIPELINED multiplier (
            .clk(clk), .rst_n(rst_n), .valid_in(START),
            .A(A[4*i +: 4]), .B(B[4*i +: 4]),
            .C(product[i]), .valid_out(product_valid[i])
        );
    end
    for (genvar i = 0; i < 2; i++) begin : GEN_PAIR
        Multiple_adder #(.WIDTH(9)) adder (
            .A({1'b0, product[2*i]}), .B({1'b0, product[2*i+1]}), .C(pair_sum[i])
        );
    end
    Multiple_adder #(.WIDTH(10)) final_adder (
        .A({1'b0, pair_r[0]}), .B({1'b0, pair_r[1]}), .C(result)
    );
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pair_valid <= 0;
            DONE <= 0;
            pair_r[0] <= 0;
            pair_r[1] <= 0;
            C <= 0;
        end else begin
            pair_valid <= &product_valid;
            DONE <= pair_valid;
            if (&product_valid) begin
                pair_r[0] <= pair_sum[0];
                pair_r[1] <= pair_sum[1];
            end
            if (pair_valid) C <= result;
        end
    end
endmodule
