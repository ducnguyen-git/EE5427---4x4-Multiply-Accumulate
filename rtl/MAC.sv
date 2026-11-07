module MAC (
	input logic clk,
	input logic rst_n,
	input logic START,
	input logic [15:0]A,
	input logic [15:0]B,
	output logic [9:0]C,
	output logic DONE
);

    //==================================================
    // DONE Signal
    //==================================================
	
	logic [2:0] count, count_next;
	logic busy;
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
		else if (START && !busy) begin
			count      <= 3'b0;
		end
		else if (busy && count != 3'd4) begin 
			count <= count_next;
		end
 		else begin
			count <= count;
		end
	end

	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			busy <= 1'b0;
		end
		else if (START && !busy) begin
			busy <= 1'b1;
		end
		else if (busy && count == 3'd4) begin
			busy <= 1'b0;
		end
	end

	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			DONE <= 1'b0;
		end
		else if (busy && count == 3'd4) begin
			DONE <= 1'b1;
		end
		else begin
			DONE <= 1'b0;
		end
	end
	
    //==================================================
    // Shift registers for A and B
    //==================================================

    logic [15:0] A_r;
    logic [15:0] B_r;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            A_r <= 16'd0;
            B_r <= 16'd0;
        end
        else if (START && !busy) begin
            A_r <= A;
            B_r <= B;
        end
        else if (busy) begin
            A_r <= A_r >> 4;
            B_r <= B_r >> 4;
        end
		else begin
            A_r <= A_r;
            B_r <= B_r;
		end
    end

    //==================================================
    // 4-bit x 4-bit multiplier
    //==================================================

    logic [7:0] MUL_C;

    MAC_MULTIPLIER #(
        .WIDTH(4)
    ) Multiplier (
        .A(A_r[3:0]),
        .B(B_r[3:0]),
        .C(MUL_C)
    );

    //==================================================
    // Multiplier pipeline register
    //==================================================

    logic [7:0] MUL_C_r;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            MUL_C_r <= 8'd0;
        end
        else if (START && !busy) begin
            MUL_C_r <= 8'd0;
        end
        else if (busy) begin
            MUL_C_r <= MUL_C;
        end
		else begin
			MUL_C_r <= MUL_C_r;
		end
    end

    //==================================================
    // Accumulator
    //==================================================

    logic [9:0] ADDER_C;
    logic [9:0] ADDER_C_r;

    MAC_ADDER #(
        .WIDTH(10)
    ) Adder (
        .A({2'b00, MUL_C_r}),
        .B(ADDER_C_r),
        .C(ADDER_C)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ADDER_C_r <= 10'd0;
        end
        else if (START && !busy) begin
            // Xóa k?t qu? phép MAC tr??c
            ADDER_C_r <= 10'd0;
        end
        else if (busy) begin
            ADDER_C_r <= ADDER_C;
        end
		else begin
            ADDER_C_r <= ADDER_C_r;
        end
    end

    //==================================================
    // Output
    //==================================================

    assign C = ADDER_C_r;

endmodule
