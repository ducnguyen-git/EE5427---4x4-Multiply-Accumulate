`timescale 1ns/1ps
module tb_uart_clk #(
    parameter int unsigned XTAL_FREQ = 100_000_000,
    parameter int unsigned BAUD_RATE = 9600
);
    logic clk = 0, rst_n = 0;
    wire tx_clk, rx_clk;
    always #5 clk = ~clk;
    uart_clk #(.XTAL_FREQ(XTAL_FREQ), .BAUD_RATE(BAUD_RATE)) dut (
        .sys_clk(clk), .rst_n(rst_n), .tx_clk(tx_clk), .rx_clk(rx_clk)
    );
    initial begin
        #20;
        rst_n = 1;
        #100;
        $display("PASS: UART clock parameters accepted");
        $finish;
    end
endmodule
