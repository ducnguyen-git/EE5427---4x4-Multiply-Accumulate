`timescale 1ns/1ps
// Compile separately against current RTL or main's DUT/rtl with -DLEGACY.
module tb_performance;
    logic clk = 0, rst_n = 0, START = 0, LOAD = 0;
    logic [63:0] A = 64'h1111111111111111, B = 64'h1111111111111111;
    wire [9:0] dot;
    wire dot_done, matrix_done;
`ifdef LEGACY
    localparam DOT_LATENCY = 5, MATRIX_LATENCY = 6, INTERVAL = 6;
    wire [9:0] matrix;
    DUT core (.clk(clk), .rst_n(rst_n), .LOAD(LOAD), .START(START),
              .A(A), .B(B), .SELECT(4'd0), .C(matrix), .DONE(matrix_done));
`else
    localparam DOT_LATENCY = 4, MATRIX_LATENCY = 4, INTERVAL = 1;
    wire [159:0] matrix;
    MAC4x4 core (.clk(clk), .rst_n(rst_n), .LOAD(LOAD), .START(START),
                  .A(A), .B(B), .C(matrix), .DONE(matrix_done));
`endif
    MAC single_mac (.clk(clk), .rst_n(rst_n), .START(START),
                    .A(16'h1111), .B(16'h1111), .C(dot), .DONE(dot_done));
    always #5 clk = ~clk;
    integer edge_index, dots = 0, matrices = 0;
    logic expected_dot, expected_matrix;
    initial begin
        repeat (2) @(negedge clk);
        rst_n = 1; LOAD = 1;
        @(negedge clk);
        LOAD = 0; START = 1;
        for (edge_index = 0; edge_index < 30; edge_index = edge_index + 1) begin
            @(posedge clk); #1;
            expected_dot = edge_index >= DOT_LATENCY &&
                           ((edge_index-DOT_LATENCY) % INTERVAL == 0);
            expected_matrix = edge_index >= MATRIX_LATENCY &&
                              ((edge_index-MATRIX_LATENCY) % INTERVAL == 0);
            if (dot_done !== expected_dot || matrix_done !== expected_matrix)
                $fatal(1, "Unexpected valid at edge %0d: dot=%b matrix=%b", edge_index, dot_done, matrix_done);
            if (dot_done) begin
                if (dot !== 10'd4) $fatal(1, "Incorrect dot product");
                dots = dots + 1;
            end
            if (matrix_done) begin
`ifdef LEGACY
                if (matrix !== 10'd4) $fatal(1, "Incorrect selected matrix result");
`else
                for (integer i = 0; i < 16; i = i + 1)
                    if (matrix[10*i +: 10] !== 10'd4) $fatal(1, "Incorrect matrix result");
`endif
                matrices = matrices + 1;
            end
        end
        if (dots < 4 || matrices < 4) $fatal(1, "Insufficient completions");
        $display("PASS: MAC latency=%0d, matrix latency=%0d, initiation interval=%0d clocks; %0d dot / %0d matrix results", DOT_LATENCY, MATRIX_LATENCY, INTERVAL, dots, matrices);
        $finish;
    end
    initial begin #10000; $fatal(1, "Timeout"); end
endmodule
