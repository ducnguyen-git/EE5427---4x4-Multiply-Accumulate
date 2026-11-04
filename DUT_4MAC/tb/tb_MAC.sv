`timescale 1ns/1ps

module tb_MAC;

    logic        clk;
    logic        rst_n;
    logic        START;
    logic [15:0] A;
    logic [15:0] B;

    logic [9:0]  C;
    logic        DONE;

    logic [9:0] expected;

    // ==========================================
    // DUT
    // ==========================================

    MAC dut (
        .clk   (clk),
        .rst_n (rst_n),
        .START (START),
        .A     (A),
        .B     (B),
        .C     (C),
        .DONE  (DONE)
    );


    // ==========================================
    // Clock: period = 10 ns
    // ==========================================

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end


    // ==========================================
    // Test
    // ==========================================

    initial begin

        // Initial values
        rst_n = 1'b0;
        START = 1'b0;
        A     = 16'b0;
        B     = 16'b0;

        #20;

        // Release reset
        rst_n = 1'b1;


        // ======================================
        // TEST 1
        // ======================================
        //
        // A = {4,3,2,1}
        // B = {8,7,6,5}
        //
        // Result:
        //
        // 1*5 + 2*6 + 3*7 + 4*8
        // = 5 + 12 + 21 + 32
        // = 70
        //

        @(negedge clk);

        A = {4'd4, 4'd3, 4'd2, 4'd1};
        B = {4'd8, 4'd7, 4'd6, 4'd5};

        expected = 10'd70;

        START = 1'b1;

        // START only one clock
        @(negedge clk);

        START = 1'b0;


        // Wait until MAC asserts DONE
        wait(DONE == 1'b1);

        #1;

        $display("======================================");
        $display("MAC TEST 1");
        $display("======================================");
        $display("A        = %h", A);
        $display("B        = %h", B);
        $display("C        = %0d", C);
        $display("Expected = %0d", expected);

        if (C === expected)
            $display("RESULT   = PASS");
        else
            $display("RESULT   = FAIL");

        $display("======================================");


        // ======================================
        // Reset MAC after DONE
        // ======================================

        @(negedge clk);

        rst_n = 1'b0;
        START = 1'b0;

        #10;

        rst_n = 1'b1;


        // ======================================
        // TEST 2
        // ======================================
        //
        // 2*1 + 4*2 + 6*3 + 8*4
        // = 2 + 8 + 18 + 32
        // = 60
        //

        @(negedge clk);

        A = {4'd8, 4'd6, 4'd4, 4'd2};
        B = {4'd4, 4'd3, 4'd2, 4'd1};

        expected = 10'd60;

        START = 1'b1;

        @(negedge clk);

        START = 1'b0;


        // Wait for DONE
        wait(DONE == 1'b1);

        #1;

        $display("======================================");
        $display("MAC TEST 2");
        $display("======================================");
        $display("A        = %h", A);
        $display("B        = %h", B);
        $display("C        = %0d", C);
        $display("Expected = %0d", expected);

        if (C === expected)
            $display("RESULT   = PASS");
        else
            $display("RESULT   = FAIL");

        $display("======================================");


        // ======================================
        // End simulation
        // ======================================

        #20;

        $finish;

    end


    // ==========================================
    // Monitor internal MAC behavior
    // ==========================================

    initial begin

        $monitor(
            "Time=%0t | START=%b | count=%d | A_r=%h | B_r=%d | C = %d | MUL_C_r=%d | ACC=%d | DONE=%b",
            $time,
            START,
            dut.count,
            dut.A_r,
            dut.B_r,
	    C,
            dut.MUL_C_r,
            dut.ADDER_C_r,
            DONE
        );

    end

endmodule