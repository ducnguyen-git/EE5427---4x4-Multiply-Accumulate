// ==============================================================================
// Module: shift_reg
// Description: 16-bit to 4-bit Right Shift Register
// Stores {D3, D2, D1, D0} and delivers D0, D1, D2, D3 consecutively on each shift
// ==============================================================================
`timescale 1ns / 1ps

module shift_reg (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        load,
    input  logic        shift_en,
    input  logic [15:0] data_in,
    output logic [3:0]  data_out
);
    logic [15:0] sreg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sreg <= 16'h0000;
        end else if (load) begin
            sreg <= data_in;
        end else if (shift_en) begin
            sreg <= {4'h0, sreg[15:4]};
        end
    end

    assign data_out = sreg[3:0];

endmodule
