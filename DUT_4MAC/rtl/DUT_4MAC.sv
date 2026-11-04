module DUT_4MAC (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        LOAD,
    input  logic        START,
    input  logic [3:0]  SELECT,
    input  logic [63:0] A,
    input  logic [63:0] B,
    output logic [9:0]  C,
    output logic        DONE
);

    //==================================================
    // Internal matrix registers
    //==================================================
    logic [3:0] matrix_A [0:15];
    logic [3:0] matrix_B [0:15];
    logic [9:0] matrix_C [0:15];

    //==================================================
    // MAC control signals
    //==================================================
    logic       mac_start;
    logic [3:0] Done;
    logic [9:0] mac_result [0:3];

    // Column matrix B
    logic [1:0] column_counter;


    logic [15:0] selected_B_column;

    logic all_Done;
    logic busy;
    integer index;


	//==================================================
    // Load matrix A and matrix B
    //==================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
			matrix_A[0] <= 4'd0;
			matrix_A[1] <= 4'd0;
			matrix_A[2] <= 4'd0;
			matrix_A[3] <= 4'd0;
			matrix_A[4] <= 4'd0;
			matrix_A[5] <= 4'd0;
			matrix_A[6] <= 4'd0;
			matrix_A[7] <= 4'd0;
			matrix_A[8] <= 4'd0;
			matrix_A[9] <= 4'd0;
			matrix_A[10] <= 4'd0;
			matrix_A[11] <= 4'd0;
			matrix_A[12] <= 4'd0;
			matrix_A[13] <= 4'd0;
			matrix_A[14] <= 4'd0;
			matrix_A[15] <= 4'd0;
		end
		else if (LOAD && !busy) begin
		// First Row
			matrix_A[0] <= A[63:60];
			matrix_A[1] <= A[59:56];
			matrix_A[2] <= A[55:52];
			matrix_A[3] <= A[51:48];
			
		//Second Row
			matrix_A[4] <= A[47:44];
			matrix_A[5] <= A[43:40];
			matrix_A[6] <= A[39:36];
			matrix_A[7] <= A[35:32];
			
		//Third Row
			matrix_A[8] <= A[31:28];
			matrix_A[9] <= A[27:24];
			matrix_A[10] <= A[23:20];
			matrix_A[11] <= A[19:16];
			
		// Fouth Row
			matrix_A[12] <= A[15:12];
			matrix_A[13] <= A[11:8];
			matrix_A[14] <= A[7:4];
			matrix_A[15] <= A[3:0];
		end 
		else begin
			matrix_A[0] <= matrix_A[0];
			matrix_A[1] <= matrix_A[1];
			matrix_A[2] <= matrix_A[2];
			matrix_A[3] <= matrix_A[3];
			matrix_A[4] <= matrix_A[4];
			matrix_A[5] <= matrix_A[5];
			matrix_A[6] <= matrix_A[6];
			matrix_A[7] <= matrix_A[7];
			matrix_A[8] <= matrix_A[8];
			matrix_A[9] <= matrix_A[9];
			matrix_A[10] <= matrix_A[10];
			matrix_A[11] <= matrix_A[11];
			matrix_A[12] <= matrix_A[12];
			matrix_A[13] <= matrix_A[13];
			matrix_A[14] <= matrix_A[14];
			matrix_A[15] <= matrix_A[15];		
		end
    end
	
	always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
			matrix_B[0] <= 4'd0;
			matrix_B[1] <= 4'd0;
			matrix_B[2] <= 4'd0;
			matrix_B[3] <= 4'd0;
			matrix_B[4] <= 4'd0;
			matrix_B[5] <= 4'd0;
			matrix_B[6] <= 4'd0;
			matrix_B[7] <= 4'd0;
			matrix_B[8] <= 4'd0;
			matrix_B[9] <= 4'd0;
			matrix_B[10] <= 4'd0;
			matrix_B[11] <= 4'd0;
			matrix_B[12] <= 4'd0;
			matrix_B[13] <= 4'd0;
			matrix_B[14] <= 4'd0;
			matrix_B[15] <= 4'd0;
		end
		else if (LOAD && !busy) begin
		// First Row
			matrix_B[0] <= B[63:60];
			matrix_B[1] <= B[59:56];
			matrix_B[2] <= B[55:52];
			matrix_B[3] <= B[51:48];
			
		//Second Row
			matrix_B[4] <= B[47:44];
			matrix_B[5] <= B[43:40];
			matrix_B[6] <= B[39:36];
			matrix_B[7] <= B[35:32];
			
		//Third Row
			matrix_B[8] <= B[31:28];
			matrix_B[9] <= B[27:24];
			matrix_B[10] <= B[23:20];
			matrix_B[11] <= B[19:16];
			
		// Fouth Row
			matrix_B[12] <= B[15:12];
			matrix_B[13] <= B[11:8];
			matrix_B[14] <= B[7:4];
			matrix_B[15] <= B[3:0];
		end 
		else begin
			matrix_B[0] <= matrix_B[0];
			matrix_B[1] <= matrix_B[1];
			matrix_B[2] <= matrix_B[2];
			matrix_B[3] <= matrix_B[3];
			matrix_B[4] <= matrix_B[4];
			matrix_B[5] <= matrix_B[5];
			matrix_B[6] <= matrix_B[6];
			matrix_B[7] <= matrix_B[7];
			matrix_B[8] <= matrix_B[8];
			matrix_B[9] <= matrix_B[9];
			matrix_B[10] <= matrix_B[10];
			matrix_B[11] <= matrix_B[11];
			matrix_B[12] <= matrix_B[12];
			matrix_B[13] <= matrix_B[13];
			matrix_B[14] <= matrix_B[14];
			matrix_B[15] <= matrix_B[15];		
		end
    end

    //==================================================
    // Select current column of matrix B
    //==================================================
    always_comb begin
        case (column_counter)
            // Column 0 of matrix B
            2'd0: begin
                selected_B_column = {
                    matrix_B[0],
                    matrix_B[4],
                    matrix_B[8],
                    matrix_B[12]
                };
            end
            // Column 1 of matrix B
            2'd1: begin
                selected_B_column = {
                    matrix_B[1],
                    matrix_B[5],
                    matrix_B[9],
                    matrix_B[13]
                };
            end
            // Column 2 of matrix B
            2'd2: begin
                selected_B_column = {
                    matrix_B[2],
                    matrix_B[6],
                    matrix_B[10],
                    matrix_B[14]
                };
            end
            // Column 3 of matrix B
            2'd3: begin
                selected_B_column = {
                    matrix_B[3],
                    matrix_B[7],
                    matrix_B[11],
                    matrix_B[15]
                };
            end
            default: begin
                selected_B_column = 16'd0;
            end
        endcase
    end

    //==================================================
    // Instantiate four MAC modules
    //
    // MAC0: row 0 of A x current column of B
    // MAC1: row 1 of A x current column of B
    // MAC2: row 2 of A x current column of B
    // MAC3: row 3 of A x current column of B
    //==================================================
    genvar row;
    generate
        for (row = 0; row < 4; row = row + 1) begin : GEN_MAC

            MAC mac_inst (
                .clk   (clk),
                .rst_n (rst_n),
                .START (mac_start),
                .A ({
                    matrix_A[4*row],
                    matrix_A[4*row + 1],
                    matrix_A[4*row + 2],
                    matrix_A[4*row + 3]
                }),
                // Current column of matrix B
                .B (selected_B_column),
                .C    (mac_result[row]),
                .DONE (Done[row])
            );
        end
    endgenerate


    //==================================================
    // Detect when all four MAC modules are done
    //==================================================
    assign all_Done = &Done;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            column_counter <= 2'd0;
            mac_start      <= 1'b0;
            busy           <= 1'b0;
            DONE           <= 1'b0;
        end
        else begin
            mac_start <= 1'b0;
            DONE      <= 1'b0;
            if (START && !LOAD && !busy) begin
                column_counter <= 2'd0;
                busy           <= 1'b1;

                // Start all four MAC modules
                mac_start <= 1'b1;
            end
            else if (busy && all_Done) begin
                // Result from MAC0: row 0
                matrix_C[column_counter]
                    <= mac_result[0];

                // Result from MAC1: row 1
                matrix_C[4 + column_counter]
                    <= mac_result[1];

                // Result from MAC2: row 2
                matrix_C[8 + column_counter]
                    <= mac_result[2];

                // Result from MAC3: row 3
                matrix_C[12 + column_counter]
                    <= mac_result[3];

                //======================================
                // Current column is the last column
                //======================================
                if (column_counter == 2'd3) begin
                    busy <= 1'b0;
                    DONE <= 1'b1;
                end
                else begin
                    column_counter <= column_counter + 1'b1;
                    // Start all four MAC modules again
                    mac_start <= 1'b1;
                end
            end
        end
    end


    always_comb begin
        C = matrix_C[SELECT];
    end

endmodule