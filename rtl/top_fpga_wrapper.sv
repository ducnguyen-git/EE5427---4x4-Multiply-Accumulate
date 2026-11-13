// Nexys A7-100T board top. Only the oscillator and USB-UART are external.
module top_fpga_wrapper #(
    parameter int unsigned CLK_FREQ = 100_000_000,
    parameter int unsigned BAUD_RATE = 9600
)(
    input wire CLK100MHZ,
    input wire UART_RXD,
    output wire UART_TXD
);
    // FPGA configuration initializes this register. Release reset on a clock
    // edge after four oscillator cycles; no physical reset button is required.
    (* SHREG_EXTRACT = "NO" *) logic [3:0] startup = 4'b0000;
    wire rst_n = startup[3];
    always_ff @(posedge CLK100MHZ) startup <= {startup[2:0], 1'b1};

    wire load, start, done;
    wire [63:0] a, b;
    wire [159:0] c;
    MAC4x4_uart #(.CLK_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) transport (
        .clk(CLK100MHZ), .rst_n(rst_n), .rx(UART_RXD), .tx(UART_TXD),
        .busy(), .LOAD(load), .START(start), .A(a), .B(b), .C(c), .DONE(done)
    );
    MAC4x4 core (
        .clk(CLK100MHZ), .rst_n(rst_n), .LOAD(load), .START(start),
        .A(a), .B(b), .C(c), .DONE(done)
    );
endmodule
