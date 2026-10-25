module MAC_MULTIPLIER #(
	parameter WIDTH = 4
)(
	input logic [WIDTH-1:0]A,	
	input logic [WIDTH-1:0]B,
	output logic [2*WIDTH-1:0]C	
);
	Multiple_multiplier # (
		.WIDTH(WIDTH)
	) MAC_MULTIPLIER_inst (
		.A(A),
		.B(B),
		.C(C)
	);
endmodule