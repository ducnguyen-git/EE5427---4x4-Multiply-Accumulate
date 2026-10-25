module DUT (
	input logic clk,
	input logic rst_n,
	input logic LOAD,
	input logic START,
	input logic [3:0] SELECT,
	input logic [63:0]A,
	input logic [63:0]B,
	output logic [9:0]C,
	output logic DONE
);

    //==================================================
    // Internal matrix registers
    //==================================================
    logic [3:0] matrix_A [0:15];
    logic [3:0] matrix_B [0:15];
	logic [9:0] matrix_C [0:15];
	
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
		else if (LOAD) begin
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
		else if (LOAD) begin
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
    // Initiate 16 MAC blocks
    //==================================================
	logic [9:0] matrix_C_r [0:15];
	logic [15:0] Done;
	genvar i,j;
	generate
		for (i = 0; i < 4; i = i + 1) begin: GEN_ROW
			for (j = 0; j < 4; j = j + 1) begin: GEN_MAC
				MAC dut (
					.clk   (clk),
					.rst_n (rst_n),
					.START (START),
					.A     ({matrix_A[4*i], matrix_A[4*i+1], matrix_A[4*i+2], matrix_A[4*i+3]}),
					.B     ({matrix_B[j], matrix_B[j+4], matrix_B[j+8], matrix_B[j+12]}),
					.C     (matrix_C_r[4*i+j]),
					.DONE  (Done[4*i+j])
				);
			end
		end
	endgenerate
	
	genvar k;
	generate
		for (k = 0; k < 16; k = k + 1) begin : GEN_C_REGISTER
			always_ff @(posedge clk or negedge rst_n) begin
				if (!rst_n) begin
					matrix_C[k] <= 10'd0;
				end
				else if (Done[k]) begin
					matrix_C[k] <= matrix_C_r[k];
				end
			end

		end
	endgenerate
	
	//==================================================
    // Assign output C
    //==================================================
	assign C = matrix_C[SELECT];
	
	//==================================================
    // Assign output DONE
    //==================================================
	logic all_mac_done;
	assign all_mac_done = &Done;
	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			DONE <= 1'b0;
		end
		else begin
			DONE <= all_mac_done;
		end
	end
endmodule