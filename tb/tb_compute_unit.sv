`timescale 1ns/1ps
module tb_compute_unit;
    logic clk = 0, rst_n = 1, rx = 1;
    wire tx, finish, err;
    localparam integer BIT_TIME = 320;
    always #5 clk = ~clk;
    compute_unit #(.XTAL_FREQ(100000000), .BAUD_RATE(3125000)) dut (
        .sys_clk(clk), .rst_n(rst_n), .rx(rx), .tx(tx),
        .finish(finish), .err(err)
    );
    task automatic send_byte(input logic [7:0] data);
        @(negedge clk);
        rx = 0;
        #(BIT_TIME);
        for (int i = 0; i < 8; i++) begin
            rx = data[i];
            #(BIT_TIME);
        end
        rx = 1;
        // Allow the mailbox acknowledgment and command state to settle.
        #(BIT_TIME * 5);
    endtask
    task automatic receive_byte(output logic [7:0] data);
        @(negedge tx);
        #(BIT_TIME + BIT_TIME/2);
        for (int i = 0; i < 8; i++) begin
            data[i] = tx;
            #(BIT_TIME);
        end
        assert(tx) else $fatal(1, "Missing stop bit");
    endtask
    logic [7:0] response [0:31];
    logic [7:0] received;
    integer received_count = 0;
    initial begin
        @(negedge rst_n);
        @(posedge rst_n);
        forever begin
            receive_byte(received);
            response[received_count] = received;
            received_count++;
        end
    end
    integer expected;
    initial begin
        #10;
        rst_n = 0;
        #100;
        rst_n = 1;
        #(BIT_TIME * 5);
        send_byte(0);
        for (int i = 0; i < 16; i++) send_byte(8'(i));
        for (int i = 0; i < 16; i++) send_byte(8'(15-i));
        send_byte(1);
        wait(finish);
        $display("Compute finished at %0t", $time);
        for (int i = 0; i < 16; i++) begin
            send_byte(2);
            send_byte(8'(i));
            wait(received_count == 2 * (i + 1));
            expected = 0;
            for (int k = 0; k < 4; k++)
                expected += (4*(i/4) + k) * (15 - (4*k + i%4));
            assert({response[2*i+1], response[2*i]} == 16'(expected)) else
                $fatal(1, "C[%0d]=%0d expected %0d", i, {response[2*i+1], response[2*i]}, expected);
        end
        assert(!err) else $fatal(1, "Unexpected UART/command error");
        send_byte(8'hff);
        assert(err) else $fatal(1, "Invalid command was not rejected");
        send_byte(3);
        assert(!err && !finish) else $fatal(1, "Status did not clear");
        send_byte(1);
        wait(finish);
        send_byte(0);
        send_byte(16);
        assert(err && !finish) else $fatal(1, "Invalid element was not rejected");
        rst_n = 0;
        #100;
        assert(!err && !finish && tx) else $fatal(1, "Reset failed");
        assert(dut.dut_i.matrix_C[15] == 10'(expected)) else
            $fatal(1, "Reset changed the retained matrix result");
        $display("PASS: UART load, compute, 16 results, validation and reset");
        $finish;
    end
    initial begin
        #2000000;
        $fatal(1, "Timeout state=%0d count=%0d loaded=%0b finish=%0b err=%0b", dut.state, dut.element_count, dut.loaded, finish, err);
    end
endmodule
