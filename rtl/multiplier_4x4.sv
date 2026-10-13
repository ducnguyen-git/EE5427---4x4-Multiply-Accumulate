// ==============================================================================
// Module: multiplier_4x4
// Description: 4-bit x 4-bit Unsigned Multiplier
// Output: 8-bit unsigned product (Max value: 15 * 15 = 225)
// ==============================================================================
`timescale 1ns / 1ps

module multiplier_4x4 (
    input  logic [3:0] a,
    input  logic [3:0] b,
    output logic [7:0] p
);
    assign p = a * b;
endmodule
