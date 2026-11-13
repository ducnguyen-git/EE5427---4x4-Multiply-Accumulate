`timescale 1ns/1ps
module tb_fpga_reset;
    logic clk = 0, cpu_reset_n = 1, soft_reset = 0;
    logic [15:0] switches = 0;
    wire tx;
    always #5 clk = ~clk;
    top_fpga_wrapper board (
        .CLK100MHZ(clk), .CPU_RESETN(cpu_reset_n), .UART_RXD(1'b1),
        .UART_TXD(tx), .BTNC(1'b0), .BTNU(1'b0), .BTND(soft_reset),
        .BTNL(1'b0), .BTNR(1'b0), .SW(switches),
        .LED(), .seg(), .dp(), .an()
    );
    initial begin
        #1; cpu_reset_n = 0;
        #1;
        if (board.rst_n !== 0) $fatal(1, "CPU reset must assert asynchronously");
        #20; cpu_reset_n = 1;
        repeat (5) @(negedge clk);
        if (board.rst_n !== 1 || tx !== 1) $fatal(1, "Reset release failed");
        switches = 16'h1234;
        repeat (3) @(negedge clk);
        if (board.sw_sync !== switches) $fatal(1, "Switch synchronization failed");
        soft_reset = 1;
        repeat (5) @(negedge clk);
        if (board.rst_n !== 0) $fatal(1, "Soft reset did not assert");
        soft_reset = 0;
        repeat (5) @(negedge clk);
        if (board.rst_n !== 1 || tx !== 1) $fatal(1, "Soft reset did not release");
        $display("PASS: CPU reset, soft reset, switch synchronization");
        $finish;
    end
    initial begin
        #1000;
        $fatal(1, "Reset test timeout");
    end
endmodule
