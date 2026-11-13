`timescale 1ns/1ps

module adder_width_check #(parameter WIDTH = 4)(output logic done = 0);
    logic [WIDTH-1:0] a, b, sum;
    logic [WIDTH-1:0] expected;
    Multiple_adder #(.WIDTH(WIDTH)) dut (.A(a), .B(b), .C(sum));

    initial begin
        for (int i = 0; i < (1 << WIDTH); i++) begin
            for (int j = 0; j < (1 << WIDTH); j++) begin
                a = i;
                b = j;
                expected = i + j;
                #1;
                if (sum !== expected)
                    $fatal(1, "WIDTH=%0d: %0d + %0d = %0d, expected %0d",
                           WIDTH, a, b, sum, expected);
            end
        end
        done = 1;
    end
endmodule

module wide_adder_check #(parameter WIDTH = 32)(output logic done = 0);
    logic [WIDTH-1:0] a, b, sum, expected;
    Multiple_adder #(.WIDTH(WIDTH)) dut (.A(a), .B(b), .C(sum));
    task automatic check;
        expected = a + b;
        #1;
        if (sum !== expected) $fatal(1, "Wide CLA mismatch, WIDTH=%0d", WIDTH);
    endtask
    initial begin
        // Carry propagation across every 4-bit boundary, plus full overflow.
        for (int bit_index = 0; bit_index < WIDTH; bit_index++) begin
            a = ({WIDTH{1'b1}} >> (WIDTH-1-bit_index));
            b = 1;
            check();
        end
        for (int i = 0; i < 10000; i++) begin
            a = $urandom;
            b = $urandom;
            check();
        end
        done = 1;
    end
endmodule

module tb_ADDER;
    logic [7:0] done;
    logic [3:0] a, b, sum;
    logic cin, cout, group_p, group_g;
    logic [4:0] expected;
    CLA4 dut (.a(a), .b(b), .cin(cin), .s(sum), .cout(cout),
              .group_p(group_p), .group_g(group_g));
    adder_width_check #(.WIDTH(1)) w1(done[0]);
    adder_width_check #(.WIDTH(3)) w3(done[1]);
    adder_width_check #(.WIDTH(4)) w4(done[2]);
    adder_width_check #(.WIDTH(5)) w5(done[3]);
    adder_width_check #(.WIDTH(8)) w8(done[4]);
    adder_width_check #(.WIDTH(10)) w10(done[5]);
    wide_adder_check #(.WIDTH(17)) w17(done[6]);
    wide_adder_check #(.WIDTH(32)) w32(done[7]);

    initial begin
        for (int i = 0; i < 16; i++) begin
            for (int j = 0; j < 16; j++) begin
                for (int k = 0; k < 2; k++) begin
                    a = i;
                    b = j;
                    cin = k;
                    expected = i + j + k;
                    #1;
                    if ({cout, sum} !== expected)
                        $fatal(1, "CLA4: %0d + %0d + %0d failed", a, b, cin);
                    if (group_p !== (&(a ^ b)) || cout !== (group_g | (group_p & cin)))
                        $fatal(1, "CLA4 group propagate/generate mismatch");
                end
            end
        end
        wait (&done);
        $display("PASS: exhaustive CLA4/widths 1,3,4,5,8,10; wide carry/random tests 17,32");
        $finish;
    end
endmodule
