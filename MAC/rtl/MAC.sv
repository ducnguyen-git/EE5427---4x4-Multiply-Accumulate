module MAC (
	input logic clk,
	input logic rst_n,
	input logic START,
	input logic [15:0]A,
	input logic [15:0]B,
	output logic [9:0]C,
	output logic DONE
);

// Logic for DONE signal
	logic [2:0] count, count_next;
	COUNT_ADDER counter (
		.A(count),
		.B(3'b001),
		.C(count_next)
	);
	// count
	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			count <= 3'b0;
		end 
		else if (START) begin
			count      <= 3'b0;
		end
		else begin
			count <= count_next;
		end
	end
	// DONE Signal
	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			DONE  <= 1'b0;
		end 
		else if (START) begin
			DONE  <= 1'b0;
		end
		else begin
			if (count == 3'd4) begin
		            DONE <= 1'b1;
			end
		        else begin
		            DONE <= 1'b0;
			end
		end
	end
// End

// Logic for Shift Register A & B
	logic [15:0] A_r, B_r;
	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			A_r <= 16'b0;
			B_r <= 16'b0;
		end 
		else if (START) begin
			A_r <= A;
			B_r <= B;
		end
		else begin
			A_r <= A_r >> 4;
			B_r <= B_r >> 4;
		end

	end
// End


// Initiance MAC-MULTIPLIER & MULTIPLIER REG
	logic [7:0] MUL_C;
	MAC_MULTIPLIER # (
		.WIDTH(4)
	) Multiplier (
		.A(A_r[3:0]),
		.B(B_r[3:0]),
		.C(MUL_C)
	);

	logic [7:0]MUL_C_r;
	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			MUL_C_r <= 8'b0;
		end 
		else begin
			MUL_C_r <= MUL_C;
		end
	end		
// End


// Initiance MAC-ADDER & ADDER REG
	logic [9:0] ADDER_C;
	logic [9:0] ADDER_C_r;
 	MAC_ADDER # (
		.WIDTH(10)		
	) Adder (
		.A({2'b00,MUL_C_r}),
		.B(ADDER_C_r),
		.C(ADDER_C)
	);

	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			ADDER_C_r <= 10'b0;
		end 
		else begin
			ADDER_C_r <= ADDER_C;
		end
	end	
// End


// Assign Logic for C output
	assign 	C = ADDER_C_r;
// End

endmodule
