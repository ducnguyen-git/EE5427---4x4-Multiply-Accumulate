module compute_unit #(
    parameter int unsigned XTAL_FREQ = 100_000_000,
    parameter int unsigned BAUD_RATE = uart_pkg::BAUD_RATE
)(
    input  logic sys_clk,
    input  logic rst_n,
    input  logic rx,
    output logic tx,
    output logic finish,
    output logic err
);
    typedef enum logic [3:0] {
        CP_IDLE, CP_LOAD, CP_LATCH, CP_START, CP_COMPUTE,
        CP_SELECT, CP_READ, CP_TX_ACCEPT, CP_TX_WAIT
    } cp_state_e;
    cp_state_e state;
    logic [63:0] matrix_a, matrix_b;
    logic [4:0] element_count;
    logic [3:0] select_index;
    logic [9:0] result, saved_result;
    logic done, loaded, high_byte;
    (* ASYNC_REG = "TRUE" *) logic finish_meta, finish_sync;
    (* ASYNC_REG = "TRUE" *) logic overrun_meta, overrun_sync;

    uart_if uart_if_i();
    assign uart_if_i.sys_clk = sys_clk;
    assign uart_if_i.rst_n = rst_n;
    assign uart_if_i.rx = rx;
    assign tx = uart_if_i.tx;
    assign uart_if_i.rx_en = 1'b1;

    uart_clk #(.XTAL_FREQ(XTAL_FREQ), .BAUD_RATE(BAUD_RATE)) uart_clk_i (
        .sys_clk(uart_if_i.sys_clk),
        .rst_n(uart_if_i.rst_n),
        .tx_clk(uart_if_i.tx_clk),
        .rx_clk(uart_if_i.rx_clk)
    );
    uart_tx uart_tx_i (
        .tx_clk(uart_if_i.tx_clk),
        .rst_n(uart_if_i.rst_n),
        .tx_start(uart_if_i.tx_start),
        .tx_data(uart_if_i.tx_data),
        .tx_finish(uart_if_i.tx_finish),
        .tx(uart_if_i.tx)
    );
    uart_rx uart_rx_i (
        .rx_clk(uart_if_i.rx_clk),
        .rst_n(uart_if_i.rst_n),
        .rx_en(uart_if_i.rx_en),
        .rx_ack(uart_if_i.rx_ack),
        .rx(uart_if_i.rx),
        .rx_err(uart_if_i.rx_err),
        .rx_finish(uart_if_i.rx_finish),
        .rx_overrun(uart_if_i.rx_overrun),
        .rx_data(uart_if_i.rx_data)
    );

    // Keep the command controller, transmitter and MAC in one clock domain.
    DUT_4MAC dut_i (
        .clk(uart_if_i.tx_clk), .rst_n(rst_n),
        .LOAD(state == CP_LATCH), .START(state == CP_START),
        .SELECT(select_index), .A(matrix_a), .B(matrix_b),
        .C(result), .DONE(done)
    );

    // RX holds data/status stable until the four-phase acknowledgment completes.
    always_ff @(posedge uart_if_i.tx_clk or negedge rst_n) begin
        if (!rst_n) begin
            finish_meta <= 1'b0;
            finish_sync <= 1'b0;
            overrun_meta <= 1'b0;
            overrun_sync <= 1'b0;
        end else begin
            finish_meta <= uart_if_i.rx_finish;
            finish_sync <= finish_meta;
            overrun_meta <= uart_if_i.rx_overrun;
            overrun_sync <= overrun_meta;
        end
    end

    always_ff @(posedge uart_if_i.tx_clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= CP_IDLE;
            matrix_a <= '0;
            matrix_b <= '0;
            element_count <= '0;
            select_index <= '0;
            saved_result <= '0;
            loaded <= 1'b0;
            high_byte <= 1'b0;
            finish <= 1'b0;
            err <= 1'b0;
            uart_if_i.rx_ack <= 1'b0;
            uart_if_i.tx_start <= 1'b0;
            uart_if_i.tx_data <= '0;
        end else begin
            uart_if_i.tx_start <= 1'b0;
            if (!finish_sync) uart_if_i.rx_ack <= 1'b0;
            if (overrun_sync) err <= 1'b1;
            case (state)
                CP_LATCH: begin
                    loaded <= 1'b1;
                    state <= CP_IDLE;
                end
                CP_START: state <= CP_COMPUTE;
                CP_COMPUTE: if (done) begin
                    finish <= 1'b1;
                    state <= CP_IDLE;
                end
                CP_READ: begin
                    saved_result <= result;
                    uart_if_i.tx_data <= result[7:0];
                    uart_if_i.tx_start <= 1'b1;
                    high_byte <= 1'b0;
                    state <= CP_TX_ACCEPT;
                end
                CP_TX_ACCEPT: state <= CP_TX_WAIT;
                CP_TX_WAIT: if (uart_if_i.tx_finish) begin
                    if (!high_byte) begin
                        uart_if_i.tx_data <= {6'b0, saved_result[9:8]};
                        uart_if_i.tx_start <= 1'b1;
                        high_byte <= 1'b1;
                        state <= CP_TX_ACCEPT;
                    end else state <= CP_IDLE;
                end
                default: begin end
            endcase

            if (finish_sync && !uart_if_i.rx_ack) begin
                uart_if_i.rx_ack <= 1'b1;
                if (uart_if_i.rx_err) begin
                    err <= 1'b1;
                    if (state == CP_LOAD || state == CP_SELECT) state <= CP_IDLE;
                end else begin
                    case (state)
                        CP_IDLE: case (uart_if_i.rx_data)
                            8'h00: begin
                                element_count <= '0;
                                loaded <= 1'b0;
                                finish <= 1'b0;
                                state <= CP_LOAD;
                            end
                            8'h01: if (loaded) begin
                                finish <= 1'b0;
                                state <= CP_START;
                            end else err <= 1'b1;
                            8'h02: if (finish) state <= CP_SELECT;
                                   else err <= 1'b1;
                            8'h03: begin
                                finish <= 1'b0;
                                err <= overrun_sync;
                            end
                            default: err <= 1'b1;
                        endcase
                        CP_LOAD: if (uart_if_i.rx_data[7:4] != 0) begin
                            err <= 1'b1;
                            state <= CP_IDLE;
                        end else begin
                            if (!element_count[4])
                                matrix_a <= {matrix_a[59:0], uart_if_i.rx_data[3:0]};
                            else matrix_b <= {matrix_b[59:0], uart_if_i.rx_data[3:0]};
                            element_count <= element_count + 1'b1;
                            if (element_count == 31) state <= CP_LATCH;
                        end
                        CP_SELECT: if (uart_if_i.rx_data[7:4] != 0) begin
                            err <= 1'b1;
                            state <= CP_IDLE;
                        end else begin
                            select_index <= uart_if_i.rx_data[3:0];
                            state <= CP_READ;
                        end
                        default: err <= 1'b1;
                    endcase
                end
            end
        end
    end
endmodule
