// Row-major unsigned matrices: input element 0 is A/B[63:60].
// Output element i is C[159-10*i -: 10]. No selection cycles.
module MAC4x4 (
    input logic clk, rst_n, LOAD, START,
    input logic [63:0] A, B,
    output wire [159:0] C,
    output wire DONE
);
    logic [63:0] matrix_A, matrix_B;
    wire [15:0] done;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            matrix_A <= 0;
            matrix_B <= 0;
        end else if (LOAD) begin
            matrix_A <= A;
            matrix_B <= B;
        end
    end
    for (genvar row = 0; row < 4; row++) begin : GEN_ROW
        for (genvar col = 0; col < 4; col++) begin : GEN_MAC
            MAC mac (
                .clk(clk), .rst_n(rst_n), .START(START),
                .A(matrix_A[63-16*row -: 16]),
                .B({matrix_B[63-4*col -: 4], matrix_B[47-4*col -: 4],
                    matrix_B[31-4*col -: 4], matrix_B[15-4*col -: 4]}),
                .C(C[159-10*(4*row+col) -: 10]), .DONE(done[4*row+col])
            );
        end
    end
    assign DONE = &done;
endmodule
