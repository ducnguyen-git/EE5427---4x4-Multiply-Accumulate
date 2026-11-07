`timescale 1ns/1ps
module tb_DUT_uart;
    logic clk = 0, rst_n = 1, rx = 1;
    wire tx, busy, load, start, done;
    wire [63:0] a, b;
    wire [3:0] select;
    wire [9:0] c;
    localparam time BIT_TIME = 320ns;
    always #5 clk = ~clk;
    DUT_uart #(.CLK_FREQ(320_000), .BAUD_RATE(10_000)) transport (
        .clk(clk), .rst_n(rst_n), .rx(rx), .tx(tx), .busy(busy),
        .LOAD(load), .START(start), .A(a), .B(b), .SELECT(select), .C(c), .DONE(done)
    );
    DUT core (.clk(clk), .rst_n(rst_n), .LOAD(load), .START(start),
              .A(a), .B(b), .SELECT(select), .C(c), .DONE(done));

    task automatic send_byte(input logic [7:0] data, input bit bad_stop = 0);
        rx = 0; #(BIT_TIME);
        for (int i = 0; i < 8; i++) begin
            rx = data[i]; #(BIT_TIME);
        end
        rx = !bad_stop; #(BIT_TIME);
        rx = 1;
    endtask

    task automatic receive_byte(output logic [7:0] data);
        @(negedge tx);
        #(BIT_TIME / 2);
        if (tx !== 0) $fatal(1, "Bad start bit");
        for (int i = 0; i < 8; i++) begin
            #(BIT_TIME); data[i] = tx;
        end
        #(BIT_TIME);
        if (tx !== 1) $fatal(1, "Bad stop bit");
    endtask

    task automatic transaction(input logic [63:0] matrix_a, matrix_b);
        logic [7:0] hi_byte, lo_byte;
        int expected;
        fork
            begin
                for (int i = 7; i >= 0; i--) send_byte(matrix_a[i*8 +: 8]);
                for (int i = 7; i >= 0; i--) send_byte(matrix_b[i*8 +: 8]);
            end
            begin
                for (int row = 0; row < 4; row++) begin
                    for (int col = 0; col < 4; col++) begin
                        expected = 0;
                        for (int k = 0; k < 4; k++)
                            expected += int'(matrix_a[60-(row*4+k)*4 +: 4]) *
                                        int'(matrix_b[60-(k*4+col)*4 +: 4]);
                        receive_byte(hi_byte);
                        receive_byte(lo_byte);
                        if ({hi_byte, lo_byte} !== 16'(expected))
                            $fatal(1, "C[%0d,%0d]: got %0d expected %0d", row, col,
                                   {hi_byte, lo_byte}, expected);
                    end
                end
            end
        join
        wait (!busy);
        #(BIT_TIME * 2);
    endtask

    initial begin
        #1; rst_n = 0;
        #24; rst_n = 1;
        #(BIT_TIME * 2);
        transaction(64'h1000010000100001, 64'h123456789abcdef0);
        transaction(64'hffffffffffffffff, 64'hffffffffffffffff);
        transaction(64'h1234234134124123, 64'h2010020110200102);
        // A framing error discards a partial request.
        send_byte(8'h55);
        send_byte(8'h00, 1);
        #(BIT_TIME * 3);
        if (busy) $fatal(1, "Framing error did not discard request");
        transaction(64'h0, 64'hffffffffffffffff);
        // Reset also discards a partial request and returns TX to idle.
        send_byte(8'h12);
        #(BIT_TIME);
        rst_n = 0; #25; rst_n = 1;
        #(BIT_TIME * 2);
        if (busy || !tx) $fatal(1, "Reset failed");
        transaction(64'h1111111111111111, 64'h2222222222222222);
        $display("PASS: UART matrix transactions, framing recovery, reset");
        $finish;
    end
    initial begin
        #2_000_000;
        $fatal(1, "UART test timeout");
    end
endmodule
