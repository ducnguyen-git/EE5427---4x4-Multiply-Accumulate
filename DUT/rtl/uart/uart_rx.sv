module uart_rx
#(
  parameter int unsigned DATA_WIDTH = uart_pkg::DATA_WIDTH,
  parameter uart_pkg::parity_bit_e PARITY_BIT = uart_pkg::PARITY_BIT,
  parameter int unsigned STOP_WIDTH = uart_pkg::STOP_WIDTH
)
(
  input logic sys_clk, rst_n, rx_tick, rx_en, rx_ack, rx,
  output logic rx_err, rx_finish, rx_overrun,
  output logic [7:0] rx_data
);
  import uart_pkg::*;

  rx_state_e curr_state;
  localparam int unsigned SAMPLE_CNT_WIDTH =
    OVERSAMPLING_RATE > 1 ? $clog2(OVERSAMPLING_RATE) : 1;
  logic [SAMPLE_CNT_WIDTH-1:0] bit_sample_cnt;
  logic [7:0] bit_recv_cnt;
  logic rx_prev;
  (* ASYNC_REG = "TRUE" *) logic rx_meta, rx_sync;
  logic start_edge;
  logic sampling_active;
  logic [OVERSAMPLING_RATE-1:0] oversampling_data;
  logic [OVERSAMPLING_RATE-1:0] vote_window;
  logic inferred_bit;
  logic bit_valid;
  logic frame_end;
  logic frame_err;
  logic ack_meta, ack_sync;
  logic pending_start;
  logic [SAMPLE_CNT_WIDTH-1:0] pending_sample_cnt;
  logic [OVERSAMPLING_RATE-1:0] pending_samples;
  logic [7:0] data;
  logic parity_result;
  integer unsigned ones_cnt;
  integer unsigned zeros_cnt;

  assign parity_result = calc_parity(PARITY_BIT, data);

  function automatic integer unsigned ones_cnt_fn
  (
    logic [OVERSAMPLING_RATE-1:0] data_to_cnt_ones
  );
    integer unsigned ones = 0;
    for (int unsigned i = 0; i < OVERSAMPLING_RATE; i++) begin
      if (data_to_cnt_ones[i]) ones += 1;
    end
    return ones;
  endfunction

  function automatic integer unsigned zeros_cnt_fn
  (
    logic [OVERSAMPLING_RATE-1:0] data_to_cnt_zeroes
  );
    integer unsigned zeros = 0;
    for (int unsigned i = 0; i < OVERSAMPLING_RATE; i++) begin
      if (!data_to_cnt_zeroes[i]) zeros += 1;
    end
    return zeros;
  endfunction

  always_comb begin
    vote_window = {
      oversampling_data[OVERSAMPLING_RATE-2:0],
      rx_sync
    };
    ones_cnt = ones_cnt_fn(vote_window);
    zeros_cnt = zeros_cnt_fn(vote_window);
  end

  always_ff @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_meta <= 1'b1;
      rx_sync <= 1'b1;
      ack_meta <= 1'b0;
      ack_sync <= 1'b0;
    end else begin
      rx_meta <= rx;
      rx_sync <= rx_meta;
      ack_meta <= rx_ack;
      ack_sync <= ack_meta;
    end
  end

  always_ff @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n)
      rx_prev <= 1'b1;
    else if (rx_tick)
      rx_prev <= rx_sync;
  end

  assign start_edge = rx_prev && !rx_sync;

  // A voted start is consumed in RX_IDLE. Errors do not stop the clock.
  assign frame_end = bit_valid &&
    ((curr_state == RX_IDLE && inferred_bit != START_SIG) ||
     (curr_state == RX_STOP &&
      (inferred_bit != STOP_SIG || bit_recv_cnt == STOP_WIDTH - 1)));


  always_ff @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
      sampling_active <= '0;
      inferred_bit <= '1;
      bit_valid <= 1'b0;
      pending_start <= 1'b0;
      pending_sample_cnt <= '0;
      pending_samples <= '0;
      bit_sample_cnt <= '0;
      oversampling_data <= '0;
    end else if (rx_tick) begin
      bit_valid <= 1'b0;
      if (!rx_en) begin
        sampling_active <= '0;
        pending_start <= 1'b0;
        pending_sample_cnt <= '0;
        pending_samples <= '0;
        bit_sample_cnt <= '0;
        oversampling_data <= '0;
      end else if (frame_end) begin
        // A following start can precede the final stop-window vote. Carry
        // every sample since that edge into the new window, including this
        // tick; restarting at zero here would accumulate alignment error.
        sampling_active <= pending_start || start_edge;
        pending_start <= 1'b0;
        if (pending_start) begin
          bit_sample_cnt <= pending_sample_cnt + 1'b1;
          oversampling_data <= {
            pending_samples[OVERSAMPLING_RATE-2:0], rx_sync
          };
        end else if (rx_tick) begin
          bit_sample_cnt <= '0;
          oversampling_data <= '0;
        end
      end else if (!sampling_active) begin
        if (start_edge) begin
          sampling_active <= '1;
          pending_start <= 1'b0;
          bit_sample_cnt <= '0;
          oversampling_data <= '0;
        end
      end else if (rx_tick) begin
        // Only the latter half of the final stop window can contain a
        // following start. Data transitions must not realign reception.
        if (!pending_start && start_edge && curr_state == RX_STOP &&
            bit_recv_cnt == STOP_WIDTH - 1 &&
            bit_sample_cnt >= OVERSAMPLING_RATE / 2) begin
          pending_start <= 1'b1;
          pending_sample_cnt <= '0;
          pending_samples <= '0;
        end else if (pending_start) begin
          pending_sample_cnt <= pending_sample_cnt + 1'b1;
          pending_samples <= {
            pending_samples[OVERSAMPLING_RATE-2:0], rx_sync
          };
        end
        if (bit_sample_cnt + 1 < OVERSAMPLING_RATE) begin
          oversampling_data <= oversampling_data << 1;
          oversampling_data[0] <= rx_sync;
          bit_sample_cnt <= bit_sample_cnt + 1'b1;
        end else if (rx_tick) begin
          if (ones_cnt > zeros_cnt) inferred_bit <= '1;
          else if (ones_cnt < zeros_cnt) inferred_bit <= '0;
          else inferred_bit <= rx_sync;
          bit_valid <= 1'b1;
          bit_sample_cnt <= '0;
          oversampling_data <= '0;
        end
      end
    end
  end

  always_ff @(posedge sys_clk or negedge rst_n) begin
    if (!rst_n) begin
      curr_state <= RX_IDLE;
      bit_recv_cnt <= '0;
      data <= '0;
      rx_data <= '0;
      rx_err <= '0;
      rx_finish <= '0;
      rx_overrun <= 1'b0;
      frame_err <= 1'b0;
    end else if (rx_tick && !rx_en) begin
      curr_state <= RX_IDLE;
      bit_recv_cnt <= '0;
      data <= '0;
      frame_err <= 1'b0;
      rx_data <= '0;
      rx_err <= 1'b0;
      rx_finish <= 1'b0;
      rx_overrun <= 1'b0;
    end else if (rx_tick) begin
      // Four-phase mailbox: hold data/status until acknowledged; do not
      // reuse the mailbox until the synchronized acknowledgment returns low.
      if (ack_sync) rx_finish <= 1'b0;

      if (bit_valid)
      case (curr_state)
        RX_IDLE:
          if (inferred_bit == START_SIG) begin
            bit_recv_cnt <= '0;
            data <= '0;
            frame_err <= 1'b0;
            curr_state <= RX_DATA;
          end
        RX_DATA: begin
          if (bit_recv_cnt < DATA_WIDTH) begin
            data <= data >> 1;
            data[DATA_WIDTH-1] <= inferred_bit;
            bit_recv_cnt <= bit_recv_cnt + 1'b1;
          end
          if (bit_recv_cnt + 1 == DATA_WIDTH) begin
            bit_recv_cnt <= '0;
            curr_state <= (PARITY_BIT != NONE) ? RX_PARITY : RX_STOP;
          end
        end
        RX_PARITY: begin
          if (parity_result != inferred_bit) frame_err <= 1'b1;
          curr_state <= RX_STOP;
        end
        RX_STOP: begin
          if (frame_end) begin
            curr_state <= RX_IDLE;
            bit_recv_cnt <= '0;
            if (!rx_finish && !ack_sync) begin
              rx_data <= data;
              rx_err <= frame_err || inferred_bit != STOP_SIG;
              rx_finish <= 1'b1;
            end else if (rx_tick) begin
              // Preserve the older result and report a dropped new frame.
              rx_overrun <= 1'b1;
            end
          end else if (rx_tick) begin
            bit_recv_cnt <= bit_recv_cnt + 1'b1;
          end
        end
        default: curr_state <= RX_IDLE;
      endcase
    end
  end
endmodule
