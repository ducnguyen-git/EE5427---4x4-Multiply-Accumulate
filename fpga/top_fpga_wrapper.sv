// ==============================================================================
// Course: EE5427 - Digital Integrated Circuit Design / VLSI
// Project: 4-element 4-bit Pipelined Multiply-Accumulate (MAC) Unit
// File: top_fpga_wrapper.sv
// Target EDA: Intel Quartus Prime (Lite / Standard Edition)
// Target Hardware: Intel MAX 10 / Cyclone IV (e.g., Terasic DE10-Lite / DE2-115)
//
// Description:
// FPGA top-level evaluation wrapper module for Intel FPGA development boards.
// Interfaces physical board peripherals:
// - clk_50mhz : 50 MHz onboard oscillator
// - key[0]    : Push button 0 (Active-Low) -> Global Reset (rst_n)
// - key[1]    : Push button 1 (Active-Low) -> START computation pulse
// - sw[9:0]   : Slide switches for input vectors
//               sw[9] = Mode toggle (0: Lower 8 bits, 1: Upper 8 bits of vector)
//               sw[8] = Vector Select (0: Vector A, 1: Vector B)
//               sw[7:0] = 8-bit vector slice data
// - ledr[9:0] : 10 Red LEDs displaying 10-bit MAC result C[9:0]
// - hex0      : 7-segment display for status / low nibble
// ==============================================================================
`timescale 1ns / 1ps

module top_fpga_wrapper (
    input  logic        clk_50mhz,  // 50 MHz onboard oscillator
    input  logic [1:0]  key,        // Active-low push buttons: KEY[0]=rst_n, KEY[1]=START
    input  logic [9:0]  sw,         // Slide switches: [8]=Vector Sel, [7:0]=Data
    output logic [9:0]  ledr,       // 10 LEDs displaying output C[9:0]
    output logic [6:0]  hex0        // 7-segment display (active low)
);

    // Active-low reset from KEY[0]
    logic rst_n;
    assign rst_n = key[0];

    // Synchronize and detect falling edge of KEY[1] to generate 1-cycle START pulse
    logic key1_sync0, key1_sync1, key1_prev;
    logic start_pulse;

    always_ff @(posedge clk_50mhz or negedge rst_n) begin
        if (!rst_n) begin
            key1_sync0 <= 1'b1;
            key1_sync1 <= 1'b1;
            key1_prev  <= 1'b1;
        end else begin
            key1_sync0 <= key[1];
            key1_sync1 <= key1_sync0;
            key1_prev  <= key1_sync1;
        end
    end

    // KEY is active-low: pressed means falling edge (1 -> 0)
    assign start_pulse = (key1_prev == 1'b1) && (key1_sync1 == 1'b0);

    // Input vector holding registers (16-bit each)
    logic [15:0] reg_a;
    logic [15:0] reg_b;
    logic [9:0]  mac_result;
    logic        mac_done;

    // Load vector slices using switches
    // sw[8] == 0: Configure Vector A; sw[8] == 1: Configure Vector B
    // sw[9] == 0: Lower bytes [7:0]; sw[9] == 1: Upper bytes [15:8]
    always_ff @(posedge clk_50mhz or negedge rst_n) begin
        if (!rst_n) begin
            reg_a <= 16'h4321; // Default demo vector: A = {4, 3, 2, 1}
            reg_b <= 16'h1234; // Default demo vector: B = {1, 2, 3, 4}
        end else begin
            if (sw[8] == 1'b0) begin
                if (sw[9] == 1'b0) reg_a[7:0]  <= sw[7:0];
                else               reg_a[15:8] <= sw[7:0];
            end else begin
                if (sw[9] == 1'b0) reg_b[7:0]  <= sw[7:0];
                else               reg_b[15:8] <= sw[7:0];
            end
        end
    end

    // Instantiate MAC Core
    mac_top u_mac_core (
        .clk   (clk_50mhz),
        .rst_n (rst_n),
        .START (start_pulse),
        .A     (reg_a),
        .B     (reg_b),
        .C     (mac_result),
        .DONE  (mac_done)
    );

    // Output result to LEDs
    // When DONE is high, LEDs show C[9:0]
    assign ledr = mac_result;

    // 7-segment decoder function for hex display
    function automatic [6:0] hex_decoder(input [3:0] val);
        case (val)
            4'h0: hex_decoder = 7'b1000000;
            4'h1: hex_decoder = 7'b1111001;
            4'h2: hex_decoder = 7'b0100100;
            4'h3: hex_decoder = 7'b0110000;
            4'h4: hex_decoder = 7'b0011001;
            4'h5: hex_decoder = 7'b0010010;
            4'h6: hex_decoder = 7'b0000010;
            4'h7: hex_decoder = 7'b1111000;
            4'h8: hex_decoder = 7'b0000000;
            4'h9: hex_decoder = 7'b0010000;
            4'hA: hex_decoder = 7'b0001000;
            4'hb: hex_decoder = 7'b0000011;
            4'hC: hex_decoder = 7'b1000110;
            4'hd: hex_decoder = 7'b0100001;
            4'hE: hex_decoder = 7'b0000110;
            4'hF: hex_decoder = 7'b0001110;
            default: hex_decoder = 7'b1111111;
        endcase
    endfunction

    // Show lowest nibble of C on HEX0
    assign hex0 = hex_decoder(mac_result[3:0]);

endmodule
