// 16 request bytes, then one continuous 32-byte response. See docs/UART.md.
module MAC4x4_uart #(
    parameter int unsigned CLK_FREQ = 100_000_000,
    parameter int unsigned BAUD_RATE = 9600
) (
    input logic clk, rst_n,
    input logic rx,
    output logic tx,
    output logic busy,
    output logic LOAD, START,
    output logic [63:0] A, B,
    input logic [159:0] C,
    input logic DONE
);
    logic tx_tick, rx_tick;
    logic [7:0] rx_data;
    logic [255:0] response;
    logic [3:0] tx_bit;
    logic rx_ack, rx_finish, rx_err, rx_overrun;
    uart_clk #(.XTAL_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) u_clk (
        .sys_clk(clk), .rst_n(rst_n), .tx_tick(tx_tick), .rx_tick(rx_tick)
    );
    uart_rx u_rx (
        .sys_clk(clk), .rst_n(rst_n), .rx_tick(rx_tick), .rx_en(1'b1),
        .rx(rx), .rx_ack(rx_ack), .rx_finish(rx_finish), .rx_data(rx_data),
        .rx_err(rx_err), .rx_overrun(rx_overrun)
    );

    typedef enum logic [3:0] {
        RECEIVE, LOAD_MATRIX, START_MATRIX, COMPUTE,
        SEND
    } state_t;
    state_t state;
    // shortcut: no packet timeout/resync; add framing for recovery without reset.
    logic [3:0] rx_count;
    logic [4:0] tx_count;
    logic rx_ready_meta, rx_ready;
    assign busy = state != RECEIVE || rx_count != 0;
    assign LOAD = state == LOAD_MATRIX;
    assign START = state == START_MATRIX;

    // RX holds its data/status until this four-phase acknowledgment completes.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_ready_meta <= 0;
            rx_ready <= 0;
        end else begin
            rx_ready_meta <= rx_finish;
            rx_ready <= rx_ready_meta;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= RECEIVE;
            rx_count <= 0;
            tx_count <= 0;
            A <= 0;
            B <= 0;
            rx_ack <= 0;
            response <= 0;
            tx_bit <= 0;
            tx <= 1;
        end else begin
            if (!rx_ready) rx_ack <= 0;
            if (rx_ready && !rx_ack) begin
                rx_ack <= 1;
                if (state == RECEIVE) begin
                    if (rx_err || rx_overrun) begin
                        rx_count <= 0;
                    end else begin
                        if (rx_count < 8) A <= {A[55:0], rx_data};
                        else B <= {B[55:0], rx_data};
                        rx_count <= rx_count + 1'b1;
                        if (rx_count == 15) state <= LOAD_MATRIX;
                    end
                end
            end
            case (state)
                LOAD_MATRIX: state <= START_MATRIX;
                START_MATRIX: state <= COMPUTE;
                COMPUTE: if (DONE) begin
                    tx_count <= 0;
                    tx_bit <= 0;
                    // Snapshot all elements together; core may change afterward.
                    for (int i = 0; i < 16; i++) begin
                        response[16*i +: 8] <= {6'b0, C[159-10*i -: 2]};
                        response[16*i+8 +: 8] <= C[157-10*i -: 8];
                    end
                    state <= SEND;
                end
                SEND: if (tx_tick) begin
                    if (tx_bit == 0) begin
                        tx <= 0;
                        tx_bit <= 1;
                    end else if (tx_bit <= 8) begin
                        tx <= response[0];
                        response <= {1'b0, response[255:1]};
                        tx_bit <= tx_bit + 1'b1;
                    end else if (tx_bit == 9) begin
                        tx <= 1;
                        tx_bit <= 10;
                    end else if (tx_count == 31) begin
                        // Last stop bit has occupied a full baud interval.
                        state <= RECEIVE;
                        tx_bit <= 0;
                    end else begin
                        // Start the next byte immediately after its stop bit.
                        tx <= 0;
                        tx_count <= tx_count + 1'b1;
                        tx_bit <= 1;
                    end
                end
                default: ;
            endcase
        end
    end
endmodule
