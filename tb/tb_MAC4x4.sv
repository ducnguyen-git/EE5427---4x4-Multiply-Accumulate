`timescale 1ns/1ps
module tb_MAC4x4;
    logic clk = 0, rst_n = 0, LOAD = 0, START = 0;
    logic [63:0] A = 0, B = 0;
    wire [159:0] C;
    wire DONE;
    logic [63:0] loaded_a = 0, loaded_b = 0;
    logic [4:0] valid = 0;
    logic [159:0] expected [0:4];
    logic [159:0] held = 0;
    int checked = 0;
    MAC4x4 dut (.*);
    always #5 clk = ~clk;

    function automatic [159:0] multiply(input logic [63:0] a, b);
        int value;
        for (int row = 0; row < 4; row++) begin
            for (int col = 0; col < 4; col++) begin
                value = 0;
                for (int k = 0; k < 4; k++)
                    value += int'(a[63-4*(4*row+k) -: 4]) * int'(b[63-4*(4*k+col) -: 4]);
                multiply[159-10*(4*row+col) -: 10] = 10'(value);
            end
        end
    endfunction

    always @(posedge clk) begin
        if (!rst_n) begin
            loaded_a = 0;
            loaded_b = 0;
            valid = 0;
            held = 0;
            for (int i = 0; i < 5; i++) expected[i] = 0;
        end else begin
            valid = {valid[3:0], START};
            for (int i = 4; i > 0; i--) expected[i] = expected[i-1];
            // Simultaneous LOAD/START computes the previously loaded matrices.
            expected[0] = multiply(loaded_a, loaded_b);
            if (valid[4]) held = expected[4];
            if (LOAD) begin loaded_a = A; loaded_b = B; end
        end
        #1;
        if (DONE !== valid[4] || C !== held)
            $fatal(1, "Matrix pipeline/order mismatch at %0t", $time);
        if (DONE) checked++;
    end

    initial begin
        repeat (3) @(negedge clk);
        rst_n = 1;
        for (int i = 0; i < 220; i++) begin
            LOAD = (i < 110) || (($urandom % 4) != 0);
            START = (i < 110) || (($urandom % 4) != 0);
            A = {$urandom, $urandom};
            B = {$urandom, $urandom};
            if (i == 0) begin A = '1; B = '1; end
            if (i == 1) begin A = 64'h1000010000100001; B = 64'h123456789abcdef0; end
            if (i == 2) A = 0;
            if (i == 100) rst_n = 0;
            if (i == 102) rst_n = 1;
            @(negedge clk);
        end
        LOAD = 0;
        START = 0;
        repeat (7) @(negedge clk);
        if (checked < 150) $fatal(1, "Insufficient matrices checked");
        $display("PASS: full matrix bus, one request/clock, bubbles, LOAD ordering, reset (%0d matrices)", checked);
        $finish;
    end
    initial begin #10000; $fatal(1, "Matrix timeout"); end
endmodule
