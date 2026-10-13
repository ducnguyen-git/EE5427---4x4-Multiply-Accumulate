// ==============================================================================
// Course: EE5427 - Digital Integrated Circuit Design / VLSI
// Project: 4-element 4-bit Pipelined Multiply-Accumulate (MAC) Unit
// File: mac_top.sv
//
// Description:
// Top-level module for 4-element 4-bit unsigned MAC unit.
// Computes: C = A0*B0 + A1*B1 + A2*B2 + A3*B3
//
// Datapath:
// - Parallel-load shift registers for A[15:0] and B[15:0]
// - 4x4 Unsigned Multiplier
// - 1-stage Multiplier Pipeline Register
// - 10-bit Accumulator Adder
// - Accumulator Output Pipeline Register with feedback
// ==============================================================================
`timescale 1ns / 1ps

module mac_top (
    input  logic        clk,     // Operating clock (rising edge active)
    input  logic        rst_n,   // Asynchronous reset (active low)
    input  logic        START,   // 1-clock cycle pulse to start computation
    input  logic [15:0] A,       // Packed input vector A: {A3, A2, A1, A0}
    input  logic [15:0] B,       // Packed input vector B: {B3, B2, B1, B0}
    output logic [9:0]  C,       // 10-bit final accumulated result
    output logic        DONE     // High indicates computation complete & C is valid
);

    // -------------------------------------------------------------------------
    // Internal Signals
    // -------------------------------------------------------------------------
    logic [3:0]  a_elem;
    logic [3:0]  b_elem;
    logic [7:0]  mult_product;
    logic [7:0]  mult_pipe_reg;
    logic [9:0]  adder_in_a;
    logic [9:0]  adder_in_b;
    logic [9:0]  adder_sum;
    logic [9:0]  accum_reg;

    logic        shift_en;
    logic        accum_en;
    logic        accum_clr;
    logic [2:0]  count;
    logic        busy;

    // -------------------------------------------------------------------------
    // Shift Registers for Input Vectors A and B
    // -------------------------------------------------------------------------
    shift_reg u_shift_reg_a (
        .clk      (clk),
        .rst_n    (rst_n),
        .load     (START),
        .shift_en (shift_en),
        .data_in  (A),
        .data_out (a_elem)
    );

    shift_reg u_shift_reg_b (
        .clk      (clk),
        .rst_n    (rst_n),
        .load     (START),
        .shift_en (shift_en),
        .data_in  (B),
        .data_out (b_elem)
    );

    // -------------------------------------------------------------------------
    // Multiplier (4-bit x 4-bit -> 8-bit)
    // -------------------------------------------------------------------------
    multiplier_4x4 u_multiplier (
        .a (a_elem),
        .b (b_elem),
        .p (mult_product)
    );

    // -------------------------------------------------------------------------
    // Multiplier Pipeline Register
    // -------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mult_pipe_reg <= 8'h00;
        end else if (busy || START) begin
            mult_pipe_reg <= mult_product;
        end
    end

    // Zero-extend product to 10 bits for addition
    assign adder_in_a = {2'b00, mult_pipe_reg};
    assign adder_in_b = accum_clr ? 10'd0 : accum_reg;

    // -------------------------------------------------------------------------
    // 10-bit Accumulator Adder
    // -------------------------------------------------------------------------
    adder_10bit u_adder (
        .a   (adder_in_a),
        .b   (adder_in_b),
        .sum (adder_sum)
    );

    // -------------------------------------------------------------------------
    // Accumulator / Output Pipeline Register
    // -------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            accum_reg <= 10'd0;
        end else if (accum_en) begin
            accum_reg <= adder_sum;
        end
    end

    assign C = accum_reg;

    // -------------------------------------------------------------------------
    // Control FSM / Counter Logic
    //
    // Cycle 0: START = 1 -> Load A, B, start mult A0*B0
    // Cycle 1: Mult Pipe Reg gets P0, shift to A1*B1
    // Cycle 2: Accum Reg gets P0, Mult Pipe Reg gets P1, shift to A2*B2
    // Cycle 3: Accum Reg gets P0+P1, Mult Pipe Reg gets P2, shift to A3*B3
    // Cycle 4: Accum Reg gets P0+P1+P2, Mult Pipe Reg gets P3
    // Cycle 5: Accum Reg gets P0+P1+P2+P3, DONE = 1
    // -------------------------------------------------------------------------
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count     <= 3'd0;
            busy      <= 1'b0;
            DONE      <= 1'b0;
            shift_en  <= 1'b0;
            accum_en  <= 1'b0;
            accum_clr <= 1'b1;
        end else begin
            if (START) begin
                busy      <= 1'b1;
                count     <= 3'd1;
                DONE      <= 1'b0;
                shift_en  <= 1'b1;
                accum_en  <= 1'b0;
                accum_clr <= 1'b1;
            end else if (busy) begin
                count <= count + 1'b1;
                case (count)
                    3'd1: begin
                        // Mult Pipe Reg has P0
                        shift_en  <= 1'b1; // Shift to element 2
                        accum_en  <= 1'b1; // Accumulate P0 + 0
                        accum_clr <= 1'b1; // Ensure feedback is 0 for first term
                    end
                    3'd2: begin
                        // Accum Reg has P0, Mult Pipe Reg has P1
                        shift_en  <= 1'b1; // Shift to element 3
                        accum_en  <= 1'b1; // Accumulate P1 + P0
                        accum_clr <= 1'b0; // Normal feedback active
                    end
                    3'd3: begin
                        // Accum Reg has P0+P1, Mult Pipe Reg has P2
                        shift_en  <= 1'b0; // All elements shifted
                        accum_en  <= 1'b1; // Accumulate P2 + (P0+P1)
                        accum_clr <= 1'b0;
                    end
                    3'd4: begin
                        // Accum Reg has P0+P1+P2, Mult Pipe Reg has P3
                        shift_en  <= 1'b0;
                        accum_en  <= 1'b1; // Accumulate P3 + (P0+P1+P2)
                        accum_clr <= 1'b0;
                    end
                    3'd5: begin
                        // Accum Reg has full sum C = P0+P1+P2+P3
                        shift_en  <= 1'b0;
                        accum_en  <= 1'b0;
                        accum_clr <= 1'b0;
                        busy      <= 1'b0;
                        DONE      <= 1'b1;
                    end
                    default: begin
                        busy     <= 1'b0;
                        shift_en <= 1'b0;
                        accum_en <= 1'b0;
                    end
                endcase
            end
        end
    end

endmodule
