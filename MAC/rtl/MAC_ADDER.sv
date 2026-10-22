// ADDER Module in MAC Block
module MAC_ADDER  #(
	parameter WIDTH = 8
)(
	input logic [WIDTH-1:0]A,	
	input logic [WIDTH-1:0]B,
	output logic [WIDTH-1:0]C	
);
	Multiple_adder #(
		.WIDTH(WIDTH)
	) MAC_ADDER_inst (
		.A(A),
		.B(B),
		.C(C)
	);
endmodule