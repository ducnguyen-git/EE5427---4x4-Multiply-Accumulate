`timescale 1ns/1ps
module tb_VEDIC4_PIPELINED;
    logic clk = 0, rst_n = 0, valid_in = 0;
    logic [3:0] A = 0, B = 0;
    wire [7:0] C;
    wire valid_out;
    logic [2:0] valid = 0;
    logic [7:0] expected [0:2];
    logic [7:0] held = 0;
    int checked = 0;
    VEDIC4_PIPELINED dut (.*);
    always #5 clk = ~clk;
    always @(posedge clk) begin
        if (!rst_n) begin
            valid = 0;
            held = 0;
            for (int i = 0; i < 3; i++) expected[i] = 0;
        end else begin
            valid = {valid[1:0], valid_in};
            for (int i = 2; i > 0; i--) expected[i] = expected[i-1];
            expected[0] = A * B;
            if (valid[2]) held = expected[2];
        end
        #1;
        if (valid_out !== valid[2] || C !== held)
            $fatal(1, "Pipelined Vedic valid/product mismatch");
        if (valid_out) checked++;
    end
    initial begin
        repeat (3) @(negedge clk);
        rst_n = 1;
        for (int pass = 0; pass < 2; pass++) begin
            for (int i = 0; i < 256; i++) begin
                A = 4'(i >> 4);
                B = 4'(i);
                valid_in = 1;
                @(negedge clk);
                if (pass == 1 && i % 3 == 0) begin
                    valid_in = 0;
                    @(negedge clk);
                end
            end
            valid_in = 0;
            repeat (4) @(negedge clk);
        end
        if (checked != 512) $fatal(1, "Lost pipeline requests");
        valid_in = 1;
        @(negedge clk);
        rst_n = 0;
        @(negedge clk);
        rst_n = 1;
        valid_in = 0;
        repeat (4) @(negedge clk);
        if (checked != 512) $fatal(1, "Reset did not flush multiplier pipeline");
        $display("PASS: exhaustive pipelined Vedic, consecutive requests, bubbles, reset");
        $finish;
    end
endmodule
