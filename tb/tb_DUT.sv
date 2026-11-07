`timescale 1ns/1ps

module tb_DUT;
`define USE_4MAC
    //==================================================
    // DUT signals
    //==================================================

    logic        clk;
    logic        rst_n;
    logic        LOAD;
    logic        START;
    logic [3:0]  SELECT;
    logic [63:0] A;
    logic [63:0] B;
    logic [9:0]  C;
    logic        DONE;

    logic [9:0] C_result [0:15];

    integer C_expected [0:15];

    integer error_count;
    integer total_error_count;
    integer test_number;

    //==================================================
    // Instantiate DUT
    //==================================================
`ifdef USE_4MAC
	DUT_4MAC dut (
        .clk    (clk),
        .rst_n  (rst_n),
        .LOAD   (LOAD),
        .START  (START),
        .SELECT (SELECT),
        .A      (A),
        .B      (B),
        .C      (C),
        .DONE   (DONE)
    );
`else
	DUT dut (
        .clk    (clk),
        .rst_n  (rst_n),
        .LOAD   (LOAD),
        .START  (START),
        .SELECT (SELECT),
        .A      (A),
        .B      (B),
        .C      (C),
        .DONE   (DONE)
    );
`endif
	
    //==================================================
    // Clock generation
    // Period = 10 ns
    //==================================================

    initial begin
        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end
    end

    //==================================================
    // M[63:60] = M[0][0]
    // M[59:56] = M[0][1]
    // ...
    // M[3:0]   = M[3][3]
    //==================================================

    function automatic logic [3:0] get_matrix_element(
        input logic [63:0] matrix_bus,
        input integer      matrix_row,
        input integer      matrix_column
    );
        integer index;

        begin
            index = matrix_row * 4 + matrix_column;

            get_matrix_element =
                matrix_bus[63 - index*4 -: 4];
        end
    endfunction

    //==================================================
    //==================================================

    task automatic randomize_matrices;
        integer index;
        integer random_A_value;
        integer random_B_value;

        begin
            A = 64'd0;
            B = 64'd0;

            for (index = 0; index < 16; index = index + 1) begin
                random_A_value = $urandom_range(15, 0);
                random_B_value = $urandom_range(15, 0);

                A[63 - index*4 -: 4] = random_A_value[3:0];
                B[63 - index*4 -: 4] = random_B_value[3:0];
            end
        end
    endtask

    //==================================================
    //==================================================

    task automatic print_input_matrix(
        input string       matrix_name,
        input logic [63:0] matrix_bus
    );
        integer row;
        integer column;

        begin
            $display("");
            $display("%s =", matrix_name);
            $display("---------------------------------");

            for (row = 0; row < 4; row = row + 1) begin
                $write("| ");

                for (
                    column = 0;
                    column < 4;
                    column = column + 1
                ) begin
                    $write(
                        "%4d",
                        get_matrix_element(
                            matrix_bus,
                            row,
                            column
                        )
                    );
                end

                $write(" |\n");
            end

            $display("---------------------------------");
        end
    endtask

    //==================================================
    //==================================================

    task automatic calculate_expected_result;
        integer row;
        integer column;
        integer index;
        integer sum;

        begin
            for (row = 0; row < 4; row = row + 1) begin
                for (
                    column = 0;
                    column < 4;
                    column = column + 1
                ) begin

                    sum = 0;

                    for (
                        index = 0;
                        index < 4;
                        index = index + 1
                    ) begin
                        sum = sum
                            + get_matrix_element(A, row, index)
                            * get_matrix_element(B, index, column);
                    end

                    C_expected[row*4 + column] = sum;
                end
            end
        end
    endtask

    //==================================================
    //==================================================

    task automatic print_expected_matrix;
        integer row;
        integer column;

        begin
            $display("");
            $display("EXPECTED C = A x B");
            $display("---------------------------------");

            for (row = 0; row < 4; row = row + 1) begin
                $write("| ");

                for (
                    column = 0;
                    column < 4;
                    column = column + 1
                ) begin
                    $write(
                        "%4d",
                        C_expected[row*4 + column]
                    );
                end

                $write(" |\n");
            end

            $display("---------------------------------");
        end
    endtask

    //==================================================
    //==================================================

    task automatic load_matrices;
        begin
            @(negedge clk);
            LOAD = 1'b1;

            @(negedge clk);
            LOAD = 1'b0;

            $display(
                "[%0t] Matrix A and B loaded",
                $time
            );
        end
    endtask

    //==================================================
    //==================================================

    task automatic start_calculation;
        begin
            @(negedge clk);

            START = 1'b1;

            @(negedge clk);
            START = 1'b0;

            $display(
                "[%0t] START pulse generated",
                $time
            );
        end
    endtask

    //==================================================
    //==================================================

    task automatic wait_for_done;
        integer timeout_counter;

        begin
            timeout_counter = 0;

            // B?o ??m DONE c?a l?n ch?y tr??c ?ã tr? v? 0
            while (
                DONE !== 1'b0 &&
                timeout_counter < 30
            ) begin
                @(posedge clk);
                timeout_counter = timeout_counter + 1;
            end

            timeout_counter = 0;

            while (
                DONE !== 1'b1 &&
                timeout_counter < 100
            ) begin
                @(posedge clk);
                timeout_counter = timeout_counter + 1;
            end

            if (DONE !== 1'b1) begin
                $display("");
                $display("=========================================");
                $display("ERROR: TIMEOUT WAITING FOR DONE");
                $display("Test number = %0d", test_number);
                $display("Internal Done vector = %b", dut.Done);
                $display("=========================================");

                $fatal(1);
            end
            #1;

            $display(
                "[%0t] DONE received",
                $time
            );
        end
    endtask

    //==================================================
    //==================================================

    task automatic read_and_print_result;
        integer index;
        integer row;
        integer column;

        begin
            $display("");
            $display("READ C USING SELECT");
            $display("==================================================");
            $display(" SELECT     ELEMENT       DUT C       EXPECTED");
            $display("==================================================");

            for (index = 0; index < 16; index = index + 1) begin
                SELECT = index[3:0];

                // Ch? multiplexer ??u ra ?n ??nh
                #1;

                C_result[index] = C;

                row    = index / 4;
                column = index % 4;

                $display(
                    "  %2d        C[%0d][%0d]        %4d          %4d",
                    SELECT,
                    row,
                    column,
                    C,
                    C_expected[index]
                );
            end

            $display("==================================================");
        end
    endtask

    //==================================================
    //==================================================

    task automatic print_result_matrix;
        integer row;
        integer column;

        begin
            $display("");
            $display("DUT RESULT C");
            $display("---------------------------------");

            for (row = 0; row < 4; row = row + 1) begin
                $write("| ");

                for (
                    column = 0;
                    column < 4;
                    column = column + 1
                ) begin
                    $write(
                        "%4d",
                        C_result[row*4 + column]
                    );
                end

                $write(" |\n");
            end

            $display("---------------------------------");
        end
    endtask

    //==================================================
    //==================================================

    task automatic check_result;
        integer index;
        integer row;
        integer column;

        begin
            error_count = 0;

            $display("");
            $display("CHECK TEST %0d", test_number);
            $display("==================================================");

            for (index = 0; index < 16; index = index + 1) begin
                row    = index / 4;
                column = index % 4;

                if (
                    C_result[index] ===
                    C_expected[index][9:0]
                ) begin
                    $display(
                        "PASS: C[%0d][%0d] = %0d",
                        row,
                        column,
                        C_result[index]
                    );
                end
                else begin
                    $display(
                        "FAIL: C[%0d][%0d] = %0d, expected = %0d",
                        row,
                        column,
                        C_result[index],
                        C_expected[index]
                    );

                    error_count       = error_count + 1;
                    total_error_count = total_error_count + 1;
                end
            end

            $display("==================================================");

            if (error_count == 0) begin
                $display(
                    "TEST %0d PASSED: ALL 16 RESULTS CORRECT",
                    test_number
                );
            end
            else begin
                $display(
                    "TEST %0d FAILED: %0d INCORRECT RESULTS",
                    test_number,
                    error_count
                );
            end
        end
    endtask

    //==================================================
    // Task: th?c hi?n m?t l?n ki?m tra hoàn ch?nh
    //==================================================

    task automatic run_one_test(
        input integer current_test_number
    );
        begin
            test_number = current_test_number;

            $display("");
            $display("");
            $display("##################################################");
            $display("                START TEST %0d", test_number);
            $display("##################################################");


            randomize_matrices();

            print_input_matrix("MATRIX A", A);
            print_input_matrix("MATRIX B", B);

            calculate_expected_result();
            print_expected_matrix();

            load_matrices();


            start_calculation();

            $display(
                "[%0t] Waiting for DONE...",
                $time
            );

            wait_for_done();

            read_and_print_result();

            print_result_matrix();

            check_result();

            $display("##################################################");
            $display("                 END TEST %0d", test_number);
            $display("##################################################");

            // ??m b?o DONE tr? v? 0 tr??c phép tính ti?p theo
            @(posedge clk);
            wait (DONE === 1'b0);
        end
    endtask

    //==================================================
    // Main test sequence
    //==================================================

    initial begin
        rst_n  = 1'b0;
        LOAD   = 1'b0;
        START  = 1'b0;
        SELECT = 4'd0;
        A      = 64'd0;
        B      = 64'd0;

        error_count       = 0;
        total_error_count = 0;
        test_number       = 0;

        void'($urandom(32'h2026_1025));

        // Reset DUT
        repeat (3) @(posedge clk);

        @(negedge clk);
        rst_n = 1'b1;

        $display("");
        $display("DUT RESET RELEASED AT %0t", $time);

        //==================================================
        //==================================================

        run_one_test(1);
        run_one_test(2);
        run_one_test(3);

        //==================================================
        // T?ng k?t
        //==================================================

        $display("");
        $display("");
        $display("==================================================");
        $display("             FINAL TEST SUMMARY");
        $display("==================================================");
        $display("Total tests          : 3");
        $display("Total matrix elements: 48");
        $display("Total errors         : %0d", total_error_count);

        if (total_error_count == 0) begin
            $display("");
            $display("**************************************************");
            $display(" ALL 3 RANDOM MATRIX TESTS PASSED");
            $display(" ALL 48 RESULT ELEMENTS ARE CORRECT");
            $display("**************************************************");
        end
        else begin
            $display("");
            $display("**************************************************");
            $display(
                " TEST FAILED WITH %0d TOTAL ERRORS",
                total_error_count
            );
            $display("**************************************************");
        end

        $display("==================================================");

        #20;
        $finish;
    end

    //==================================================
    // Waveform
    //==================================================

    initial begin
        $dumpfile("tb_DUT_random.vcd");
        $dumpvars(0, tb_DUT);
    end

endmodule