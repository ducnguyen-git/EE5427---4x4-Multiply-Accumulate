`timescale 1ns/1ps
module tb_MAC;
    logic clk = 0, rst_n = 0, START = 0;
    logic [15:0] A = 0, B = 0;
    wire [9:0] C;
    wire DONE;
    logic [4:0] valid = 0;
    logic [9:0] expected [0:4];
    logic [9:0] held = 0;
    int checked = 0;
    MAC dut (.*);
    always #5 clk = ~clk;

    function automatic [9:0] dot(input logic [15:0] a, b);
        int result;
        result = 0;
        for (int i = 0; i < 4; i++) result += int'(a[4*i +: 4]) * int'(b[4*i +: 4]);
        return 10'(result);
    endfunction

    always @(posedge clk) begin
        if (!rst_n) begin
            valid = 0;
            held = 0;
            for (int i = 0; i < 5; i++) expected[i] = 0;
        end else begin
            valid = {valid[3:0], START};
            for (int i = 4; i > 0; i--) expected[i] = expected[i-1];
            expected[0] = dot(A, B);
            if (valid[4]) held = expected[4];
        end
        #1;
        if (DONE !== valid[4] || C !== held)
            $fatal(1, "MAC pipeline mismatch: valid=%b DONE=%b C=%0d expected=%0d",
                   valid[4], DONE, C, held);
        if (DONE) checked++;
    end

    initial begin
        repeat (3) @(negedge clk);
        rst_n = 1;
        for (int i = 0; i < 520; i++) begin
            START = (i < 260) || (($urandom % 4) != 0);
            A = $urandom;
            B = $urandom;
            if (i == 0) begin A = '1; B = '1; end
            if (i == 1) A = 0;
            // Reset with operations in flight, then resume a full-rate stream.
            if (i == 250) rst_n = 0;
            if (i == 252) rst_n = 1;
            @(negedge clk);
        end
        START = 0;
        repeat (7) @(negedge clk);
        if (checked < 400) $fatal(1, "Insufficient completed requests");
        $display("PASS: MAC full-rate pipeline, bubbles, overflow boundaries, reset (%0d results)", checked);
        $finish;
    end
    initial begin #10000; $fatal(1, "MAC timeout"); end
endmodule
