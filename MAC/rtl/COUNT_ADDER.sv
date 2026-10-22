module COUNT_ADDER #(
	parameter WIDTH = 3
)(
	input logic [WIDTH-1:0]A,	
	input logic [WIDTH-1:0]B,
	output logic [WIDTH-1:0]C	
);
	Multiple_adder #(
		.WIDTH(WIDTH)
	) COUNT_ADDER_inst (
		.A(A),
		.B(B),
		.C(C)
	);
endmodule
