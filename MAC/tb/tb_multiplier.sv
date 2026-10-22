`timescale 1ns/1ps

module tb_MAC_MULTIPLIER;

    logic [15:0] A;
    logic [15:0] B;
    logic [31:0] z;
integer a_test;
integer b_test;
    // DUT
    Multiple_multiplier #(
	.WIDTH(16)
    ) dut (
        .A(A),
        .B(B),
        .C(z)
    );
    initial begin
        $display("=======================================");
        $display("  TEST 8x8 UNSIGNED ARRAY MULTIPLIER");
        $display("=======================================");
        $display(" A    B    |   C");
        $display("-------------------");
end
       initial begin
    for (a_test = 0; a_test < 65536; a_test++) begin
        for (b_test = 0; b_test < 65536; b_test++) begin

            A = a_test;
            B = b_test;

            #1;

            if (z !== A * B)
                $display(
                    "FAIL: A=%d B=%d z=%d expected=%d",
                    A, B, z, A*B
                );

        end
    end

    $display("TEST COMPLETED");
    $finish;
end

endmodule
