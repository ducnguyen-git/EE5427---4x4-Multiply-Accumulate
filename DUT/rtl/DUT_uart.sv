// UART transport for the parallel DUT. See DUT/UART.md for the wire protocol.
module DUT_uart #(
    parameter int unsigned CLK_FREQ = 100_000_000,
    parameter int unsigned BAUD_RATE = 9600
) (
    input logic clk, rst_n,
    input logic rx,
    output logic tx,
    output logic busy,
    output logic LOAD, START,
    output logic [63:0] A, B,
    output logic [3:0] SELECT,
    input logic [9:0] C,
    input logic DONE
);
    logic tx_tick, rx_tick;
    logic tx_start, tx_finish;
    logic [7:0] tx_data, rx_data;
    logic rx_ack, rx_finish, rx_err, rx_overrun;
    uart_clk #(.XTAL_FREQ(CLK_FREQ), .BAUD_RATE(BAUD_RATE)) u_clk (
        .sys_clk(clk), .rst_n(rst_n), .tx_tick(tx_tick), .rx_tick(rx_tick)
    );
    uart_rx u_rx (
        .sys_clk(clk), .rst_n(rst_n), .rx_tick(rx_tick), .rx_en(1'b1),
        .rx(rx), .rx_ack(rx_ack), .rx_finish(rx_finish), .rx_data(rx_data),
        .rx_err(rx_err), .rx_overrun(rx_overrun)
    );
    uart_tx u_tx (
        .sys_clk(clk), .rst_n(rst_n), .tx_tick(tx_tick), .tx(tx),
        .tx_start(tx_start), .tx_data(tx_data), .tx_finish(tx_finish)
    );

    typedef enum logic [3:0] {
        RECEIVE, LOAD_MATRIX, START_MATRIX, COMPUTE,
        PREPARE, REQUEST, ACCEPT, SEND
    } state_t;
    state_t state;
    // shortcut: no packet timeout/resync; add framing for recovery without reset.
    logic [3:0] rx_count;
    logic [4:0] tx_count;
    logic rx_ready_meta, rx_ready;
    assign busy = state != RECEIVE || rx_count != 0;
    assign LOAD = state == LOAD_MATRIX;
    assign START = state == START_MATRIX;
    assign SELECT = tx_count[4:1];

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
            tx_start <= 0;
            tx_data <= 0;
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
                    state <= PREPARE;
                end
                PREPARE: begin
                    tx_data <= tx_count[0] ? C[7:0] : {6'b0, C[9:8]};
                    tx_start <= 1;
                    state <= REQUEST;
                end
                // TX accepts start on this enable; hold data until completion.
                REQUEST: if (tx_tick) begin
                    tx_start <= 0;
                    state <= ACCEPT;
                end
                ACCEPT: if (!tx_finish) state <= SEND;
                SEND: if (tx_finish) begin
                    if (tx_count == 31) state <= RECEIVE;
                    else begin
                        tx_count <= tx_count + 1'b1;
                        state <= PREPARE;
                    end
                end
                default: ;
            endcase
        end
    end
endmodule
