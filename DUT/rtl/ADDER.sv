// Multi-bit Adder 
module Multiple_adder #(
	parameter WIDTH = 8
)(
	input logic [WIDTH-1:0]A,	
	input logic [WIDTH-1:0]B,
	output logic [WIDTH-1:0]C	
);
	logic [WIDTH:0] cout;
	assign cout[0] = 1'b0;
	
	genvar i;
	generate
		for (i = 0; i < WIDTH; i = i + 1) begin : Generate_FA
			Full_Adder FA (
				.a(A[i]),
				.b(B[i]),
				.cin(cout[i]),
				.cout(cout[i+1]),
				.s(C[i])
			);
		end
	endgenerate
endmodule
// 1 - bit Full Adder
module Full_Adder (
	input logic a,
	input logic b,
	input logic cin,
	output logic s,
	output logic cout
);
assign s = a ^ b ^ cin;
assign cout = (a & b) | (cin & (a ^ b));
endmodule

// 1 - bit Half Adder
module Half_Adder (
	input logic a,
	input logic b,
	output logic s,
	output logic cout
);
	assign s = a ^ b;
	assign cout = a & b;
endmodule

