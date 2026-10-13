// ==============================================================================
// Course: EE5427 - Digital Integrated Circuit Design / VLSI
// Project: 4-element 4-bit Pipelined Multiply-Accumulate (MAC) Unit
// File: top_fpga_wrapper.sv
//
// Description:
// FPGA top-level evaluation wrapper module.
// Maps physical board resources (Switches, Push Buttons, LEDs, 7-Segment)
// to the MAC core for hardware lab bring-up and physical demonstration.
// ==============================================================================
`timescale 1ns / 1ps

module top_fpga_wrapper (
    input  logic        clk_100mhz,  // 100MHz onboard oscillator
    input  logic        btnC,        // Push button center: START
    input  logic        btnU,        // Push button up: rst_n (or reset btn)
    input  logic [15:0] sw,          // 16 slide switches for input vector A or B
    input  logic        btnL,        // Button left: latch vector A from switches
    input  logic        btnR,        // Button right: latch vector B from switches
    output logic [9:0]  led,         // 10 LEDs displaying output C[9:0]
    output logic        led15_done,  // LED 15 indicates DONE
    output logic [6:0]  seg,         // 7-segment display cathodes
    output logic [3:0]  an           // 7-segment display anodes
);

    // Active-low asynchronous reset
    logic rst_n;
    assign rst_n = ~btnU;

    // Registers to capture vectors A and B from the 16 slide switches
    logic [15:0] reg_a;
    logic [15:0] reg_b;
    logic [9:0]  mac_result;
    logic        mac_done;

    always_ff @(posedge clk_100mhz or negedge rst_n) begin
        if (!rst_n) begin
            reg_a <= 16'h0000;
            reg_b <= 16'h0000;
        end else begin
            if (btnL) reg_a <= sw;
            if (btnR) reg_b <= sw;
        end
    end

    // MAC Core Instance
    mac_top u_mac_core (
        .clk   (clk_100mhz),
        .rst_n (rst_n),
        .START (btnC),
        .A     (reg_a),
        .B     (reg_b),
        .C     (mac_result),
        .DONE  (mac_done)
    );

    // Output assignments
    assign led        = mac_result;
    assign led15_done = mac_done;

    // Default 7-segment tie-offs (can be connected to 7-seg hex decoder module)
    assign seg = 7'b1111111;
    assign an  = 4'b1111;

endmodule
