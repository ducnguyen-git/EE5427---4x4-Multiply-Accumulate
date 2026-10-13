// ==============================================================================
// Module: adder_10bit
// Description: 10-bit Unsigned Adder for Accumulator datapath
// Max accumulation sum: 4 * 225 = 900 (fits comfortably in 10 bits: max 1023)
// ==============================================================================
`timescale 1ns / 1ps

module adder_10bit (
    input  logic [9:0] a,
    input  logic [9:0] b,
    output logic [9:0] sum
);
    assign sum = a + b;
endmodule
