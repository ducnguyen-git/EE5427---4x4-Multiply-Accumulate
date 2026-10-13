// ==============================================================================
// Course: EE5427 - Digital Integrated Circuit Design / VLSI
// Project: 4-element 4-bit Pipelined Multiply-Accumulate (MAC) Unit
// File: mac_top_tb.sv
//
// Description:
// Comprehensive, self-checking SystemVerilog testbench for mac_top.
// Verifies functionality against a golden behavioral reference model.
// ==============================================================================
`timescale 1ns / 1ps

module mac_top_tb;

    // Parameters
    localparam CLK_PERIOD = 10; // 10ns -> 100 MHz clock

    // Signals
    logic        clk;
    logic        rst_n;
    logic        START;
    logic [15:0] A;
    logic [15:0] B;
    logic [9:0]  C;
    logic        DONE;

    // Statistics
    int error_count = 0;
    int test_count  = 0;

    // Instantiate DUT (Device Under Test)
    mac_top dut (
        .clk   (clk),
        .rst_n (rst_n),
        .START (START),
        .A     (A),
        .B     (B),
        .C     (C),
        .DONE  (DONE)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end

    // Golden Reference Function
    function automatic [9:0] golden_mac(input [15:0] vec_a, input [15:0] vec_b);
        logic [3:0] a0, a1, a2, a3;
        logic [3:0] b0, b1, b2, b3;
        int p0, p1, p2, p3;
        begin
            a0 = vec_a[3:0];
            a1 = vec_a[7:4];
            a2 = vec_a[11:8];
            a3 = vec_a[15:12];

            b0 = vec_b[3:0];
            b1 = vec_b[7:4];
            b2 = vec_b[11:8];
            b3 = vec_b[15:12];

            p0 = a0 * b0;
            p1 = a1 * b1;
            p2 = a2 * b2;
            p3 = a3 * b3;

            golden_mac = p0 + p1 + p2 + p3;
        end
    endfunction

    // Task to run one test transaction
    task automatic run_test(
        input [15:0] in_a,
        input [15:0] in_b,
        input string test_name
    );
        logic [9:0] expected_c;
        int timeout_cycles;

        test_count++;
        expected_c = golden_mac(in_a, in_b);

        @(posedge clk);
        A     <= in_a;
        B     <= in_b;
        START <= 1'b1;

        @(posedge clk);
        START <= 1'b0;

        // Wait for DONE signal with watchdog
        timeout_cycles = 0;
        while (!DONE && timeout_cycles < 20) begin
            @(posedge clk);
            timeout_cycles++;
        end

        if (!DONE) begin
            $display("[ERROR] Test '%s' TIMED OUT waiting for DONE!", test_name);
            error_count++;
        end else begin
            // Check result
            if (C === expected_c) begin
                $display("[PASS] Test #%0d (%s): A=%h B=%h => C=%0d (Expected: %0d)",
                         test_count, test_name, in_a, in_b, C, expected_c);
            end else begin
                $display("[FAIL] Test #%0d (%s): A=%h B=%h => C=%0d (Expected: %0d) MISMATCH!",
                         test_count, test_name, in_a, in_b, C, expected_c);
                error_count++;
            end
        end

        // Idle delay between tests
        repeat (2) @(posedge clk);
    endtask

    // Main Test Sequence
    initial begin
        $display("==================================================================");
        $display(" Starting EE5427 4x4 Pipelined MAC Unit Verification ");
        $display("==================================================================");

        // Initialization & Reset
        rst_n = 0;
        START = 0;
        A     = 16'h0000;
        B     = 16'h0000;

        #(CLK_PERIOD * 3);
        @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        // 1. All Zeros Corner Case
        run_test(16'h0000, 16'h0000, "All Zeros");

        // 2. Unit Vectors
        run_test(16'h1111, 16'h1111, "All Ones (1*1 + 1*1 + 1*1 + 1*1 = 4)");

        // 3. Maximum Possible Value (All 15: 4 * (15*15) = 4 * 225 = 900)
        run_test(16'hFFFF, 16'hFFFF, "Maximum Value (15*15*4 = 900)");

        // 4. Alternating Zero / Non-zero
        run_test(16'hA0B0, 16'h0C0D, "Sparse Vectors");

        // 5. Specific Pattern
        // A = {4, 3, 2, 1}, B = {1, 2, 3, 4}
        // C = (1*4) + (2*3) + (3*2) + (4*1) = 4 + 6 + 6 + 4 = 20
        run_test(16'h4321, 16'h1234, "Orthogonal Pattern (Result = 20)");

        // 6. Random Stimulus Tests
        for (int i = 0; i < 20; i++) begin
            logic [15:0] rand_a, rand_b;
            rand_a = $urandom();
            rand_b = $urandom();
            run_test(rand_a, rand_b, $sformatf("Random Vector #%0d", i+1));
        end

        // Final Report
        $display("==================================================================");
        $display(" Verification Complete: Total Tests: %0d, Errors: %0d", test_count, error_count);
        if (error_count == 0) begin
            $display(" [SUCCESS] ALL TESTCASES PASSED! DUT matches specification.");
        end else begin
            $display(" [FAILURE] %0d TESTCASES FAILED. Please review waveforms.", error_count);
        end
        $display("==================================================================");

        $finish;
    end

endmodule
