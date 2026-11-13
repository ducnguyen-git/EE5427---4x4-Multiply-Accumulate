// Multi-bit adder built from 4-bit carry look-ahead blocks.
module Multiple_adder #(
	parameter WIDTH = 8
)(
	input logic [WIDTH-1:0]A,	
	input logic [WIDTH-1:0]B,
	output logic [WIDTH-1:0]C	
);
	localparam BLOCKS = (WIDTH + 3) / 4;
	localparam PAD_WIDTH = BLOCKS * 4;
	logic [PAD_WIDTH-1:0] padded_a, padded_b, sum;
	logic [BLOCKS:0] carry;
	logic [BLOCKS-1:0] group_p, group_g;
	assign padded_a = {{(PAD_WIDTH-WIDTH){1'b0}}, A};
	assign padded_b = {{(PAD_WIDTH-WIDTH){1'b0}}, B};
	assign carry[0] = 1'b0;
	assign C = sum[WIDTH-1:0];
	
	genvar i;
	generate
		for (i = 0; i < BLOCKS; i = i + 1) begin : Generate_CLA
			logic [i:0] carry_terms;
			for (genvar j = 0; j <= i; j = j + 1) begin : Generate_Lookahead
				if (j == i) begin : GEN_LAST
					assign carry_terms[j] = group_g[j];
				end else begin : GEN_PROPAGATE
					assign carry_terms[j] = group_g[j] & (&group_p[i:j+1]);
				end
			end
			// Every block carry is computed directly, without a block ripple.
			assign carry[i+1] = |carry_terms;
			CLA4 cla (
				.a(padded_a[4*i +: 4]),
				.b(padded_b[4*i +: 4]),
				.cin(carry[i]),
				.cout(),
				.group_p(group_p[i]),
				.group_g(group_g[i]),
				.s(sum[4*i +: 4])
			);
		end
	endgenerate
endmodule

// Carries within each block are computed directly from propagate/generate.
module CLA4 (
	input logic [3:0] a, b,
	input logic cin,
	output logic [3:0] s,
	output logic cout,
	output logic group_p, group_g
);
	logic [3:0] p, g;
	logic [4:0] c;
	assign p = a ^ b;
	assign g = a & b;
	assign group_p = &p;
	assign group_g = g[3] | (p[3] & g[2])
	               | (p[3] & p[2] & g[1])
	               | (p[3] & p[2] & p[1] & g[0]);
	assign c[0] = cin;
	assign c[1] = g[0] | (p[0] & cin);
	assign c[2] = g[1] | (p[1] & g[0])
	            | (p[1] & p[0] & cin);
	assign c[3] = g[2] | (p[2] & g[1])
	            | (p[2] & p[1] & g[0])
	            | (p[2] & p[1] & p[0] & cin);
	assign c[4] = g[3] | (p[3] & g[2])
	            | (p[3] & p[2] & g[1])
	            | (p[3] & p[2] & p[1] & g[0])
	            | (p[3] & p[2] & p[1] & p[0] & cin);
	assign s = p ^ c[3:0];
	assign cout = c[4];
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

