// Three-stage Vedic multiplier; accepts operands every valid_in.
// Stages: four 2x2 products; crosswise sum; aligned product sum.
module VEDIC4_PIPELINED (
    input logic clk, rst_n, valid_in,
    input logic [3:0] A, B,
    output logic [7:0] C,
    output logic valid_out
);
    logic [3:0] quadrant [0:3], quadrant_r [0:3];
    logic [4:0] cross_sum, cross_r;
    logic [7:0] diagonal_r, product;
    logic [1:0] valid;
    Multiple_multiplier #(.WIDTH(2)) ll (.A(A[1:0]), .B(B[1:0]), .C(quadrant[0]));
    Multiple_multiplier #(.WIDTH(2)) hl (.A(A[3:2]), .B(B[1:0]), .C(quadrant[1]));
    Multiple_multiplier #(.WIDTH(2)) lh (.A(A[1:0]), .B(B[3:2]), .C(quadrant[2]));
    Multiple_multiplier #(.WIDTH(2)) hh (.A(A[3:2]), .B(B[3:2]), .C(quadrant[3]));
    Multiple_adder #(.WIDTH(5)) cross_adder (
        .A({1'b0, quadrant_r[1]}), .B({1'b0, quadrant_r[2]}), .C(cross_sum)
    );
    Multiple_adder #(.WIDTH(8)) product_adder (
        .A(diagonal_r), .B({1'b0, cross_r, 2'b00}), .C(product)
    );
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid <= '0;
            valid_out <= 0;
            for (int i = 0; i < 4; i++) quadrant_r[i] <= 0;
            cross_r <= 0;
            diagonal_r <= 0;
            C <= 0;
        end else begin
            valid <= {valid[0], valid_in};
            valid_out <= valid[1];
            if (valid_in)
                for (int i = 0; i < 4; i++) quadrant_r[i] <= quadrant[i];
            if (valid[0]) begin
                cross_r <= cross_sum;
                diagonal_r <= {quadrant_r[3], quadrant_r[0]};
            end
            if (valid[1]) C <= product;
        end
    end
endmodule
