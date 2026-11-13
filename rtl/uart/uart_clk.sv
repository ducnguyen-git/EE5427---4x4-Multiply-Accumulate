module uart_clk
#(
  parameter int unsigned XTAL_FREQ = uart_pkg::XTAL_FREQ,
  parameter int unsigned BAUD_RATE = uart_pkg::BAUD_RATE,
  parameter int unsigned OVERSAMPLING_RATE = uart_pkg::OVERSAMPLING_RATE
)
(
  input logic sys_clk, rst_n,
  output logic tx_tick, rx_tick
);
  localparam int unsigned BIT_PERIOD =
    XTAL_FREQ / (BAUD_RATE > 0 ? BAUD_RATE : 1);
  localparam int unsigned OVERSAMPLING_BIT_PERIOD =
    BIT_PERIOD / (OVERSAMPLING_RATE > 0 ? OVERSAMPLING_RATE : 1);
  localparam int unsigned TX_CNT_WIDTH = BIT_PERIOD > 1 ? $clog2(BIT_PERIOD) : 1;
  localparam int unsigned RX_CNT_WIDTH = OVERSAMPLING_BIT_PERIOD > 1
    ? $clog2(OVERSAMPLING_BIT_PERIOD) : 1;
  logic [TX_CNT_WIDTH-1:0] tx_counter;
  logic [RX_CNT_WIDTH-1:0] rx_counter;

  initial begin
    if (XTAL_FREQ == 0 || BAUD_RATE == 0 || OVERSAMPLING_RATE < 2)
      $fatal(1, "UART clock parameters must be positive, with oversampling >= 2");
    // These outputs are one-cycle clock enables, so each needs a low cycle.
    if (BIT_PERIOD < 2 || OVERSAMPLING_BIT_PERIOD < 2)
      $fatal(1, "UART clock dividers must each be at least two system cycles");
  end

  always_ff @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
      tx_counter <= '0;
      rx_counter <= '0;
      tx_tick <= '0;
      rx_tick <= '0;
    end else begin
      if (tx_counter < BIT_PERIOD - 1) begin
        tx_counter <= tx_counter + 1'b1;
        tx_tick <= '0;
      end else begin
        tx_counter <= '0;
        tx_tick <= '1;
      end
      if (rx_counter < OVERSAMPLING_BIT_PERIOD - 1) begin
        rx_counter <= rx_counter + 1'b1;
        rx_tick <= '0;
      end else begin
        rx_counter <= '0;
        rx_tick <= '1;
      end
    end
  end
endmodule
