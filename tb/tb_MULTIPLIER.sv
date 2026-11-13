`timescale 1ns/1ps

module multiplier_width_check #(parameter WIDTH = 4)(output logic done = 0);
    logic [WIDTH-1:0] a, b;
    logic [2*WIDTH-1:0] product, expected;
    Multiple_multiplier #(.WIDTH(WIDTH)) dut (.A(a), .B(b), .C(product));

    initial begin
        for (int i = 0; i < (1 << WIDTH); i++) begin
            for (int j = 0; j < (1 << WIDTH); j++) begin
                a = i;
                b = j;
                expected = a * b;
                #1;
                if (product !== expected)
                    $fatal(1, "WIDTH=%0d: %0d * %0d = %0d, expected %0d",
                           WIDTH, a, b, product, expected);
            end
        end
        done = 1;
    end
endmodule

module tb_MULTIPLIER;
    logic [5:0] done;
    multiplier_width_check #(.WIDTH(1)) w1(done[0]);
    multiplier_width_check #(.WIDTH(2)) w2(done[1]);
    multiplier_width_check #(.WIDTH(3)) w3(done[2]);
    multiplier_width_check #(.WIDTH(4)) w4(done[3]);
    multiplier_width_check #(.WIDTH(5)) w5(done[4]);
    multiplier_width_check #(.WIDTH(8)) w8(done[5]);

    initial begin
        wait (&done);
        $display("PASS: exhaustive Vedic multiplier widths 1, 2, 3, 4, 5, 8");
        $finish;
    end
endmodule
