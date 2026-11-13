`timescale 1ns/1ps
// Board-level startup and UART test: no button/reset/LED/switch ports.
module tb_fpga_reset;
    logic clk = 0, rx = 1;
    wire tx;
    localparam time BIT_TIME = 320ns;
    always #5 clk = ~clk;
    top_fpga_wrapper #(.CLK_FREQ(320_000), .BAUD_RATE(10_000)) board (
        .CLK100MHZ(clk), .UART_RXD(rx), .UART_TXD(tx)
    );
    task automatic send_byte(input logic [7:0] data);
        rx = 0; #(BIT_TIME);
        for (int i = 0; i < 8; i++) begin rx = data[i]; #(BIT_TIME); end
        rx = 1; #(BIT_TIME);
    endtask
    task automatic receive_byte(output logic [7:0] data);
        @(negedge tx);
        #(BIT_TIME / 2);
        if (tx !== 0) $fatal(1, "Board UART start error");
        for (int i = 0; i < 8; i++) begin #(BIT_TIME); data[i] = tx; end
        #(BIT_TIME);
        if (tx !== 1) $fatal(1, "Board UART stop error");
    endtask
    initial begin
        #1;
        if (board.rst_n !== 0) $fatal(1, "Startup reset must be asserted");
        repeat (3) @(negedge clk);
        if (board.rst_n !== 0) $fatal(1, "Startup reset released early");
        repeat (3) @(negedge clk);
        if (board.rst_n !== 1 || tx !== 1) $fatal(1, "Startup failed");
        #(BIT_TIME * 2);
        repeat (2) begin
            fork
                begin
                    for (int i = 0; i < 16; i++) send_byte(8'hff);
                end
                begin
                    logic [7:0] hi_byte, lo_byte;
                    for (int i = 0; i < 16; i++) begin
                        receive_byte(hi_byte);
                        receive_byte(lo_byte);
                        if ({hi_byte, lo_byte} !== 16'd900)
                            $fatal(1, "Board matrix result mismatch");
                    end
                end
            join
            #(BIT_TIME * 2);
        end
        $display("PASS: UART-only board startup and repeated matrix transactions");
        $finish;
    end
    initial begin #400000; $fatal(1, "Board test timeout"); end
endmodule
