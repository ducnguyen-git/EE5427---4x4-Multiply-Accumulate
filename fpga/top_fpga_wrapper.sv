// ==============================================================================
// Course: EE5427 - Digital Integrated Circuit Design / VLSI
// Project: 4x4 Multiply-Accumulate (MAC) Matrix Processor
// Target Board: Digilent Nexys A7 (Xilinx Artix-7 100T CSG324 - xc7a100tcsg324-1)
// File: top_fpga_wrapper.sv
//
// Description:
// Top-level FPGA evaluation wrapper for the 4x4 Matrix Multiply-Accumulate (DUT).
// Integrates physical board peripherals:
// - CLK100MHZ : 100 MHz onboard oscillator
// - CPU_RESETN: Active-low red CPU reset push button
// - BTNC      : Center push button -> Triggers automatic LOAD + START sequence
// - BTNU      : Up push button     -> Manual LOAD pulse
// - BTND      : Down push button   -> Soft reset
// - BTNL      : Left push button   -> Manual write element into custom matrix
// - SW[3:0]   : Result Element Select:
//               SW[3:2] = Row index (0 to 3)
//               SW[1:0] = Column index (0 to 3)
//               SELECT = {SW[3:2], SW[1:0]} (0 to 15)
// - SW[7:4]   : Manual element index (0 to 15) for editing custom matrix
// - SW[8]     : Target matrix for manual edit: 0 = Matrix A, 1 = Matrix B
// - SW[12:9]  : 4-bit Data value to write (0 to 15 / 4'h0 to 4'hF)
// - SW[14:13] : Built-in Test Pattern Selector:
//               2'b00: Pattern 0 (Identity Matrix A = I_4 -> Result C = B)
//               2'b01: Pattern 1 (Uniform: A=1, B=2 -> Result C = 8 everywhere)
//               2'b10: Pattern 2 (Full Scale: A=15, B=15 -> Result C = 900)
//               2'b11: Pattern 3 (Custom Interactive Matrix edited via switches)
// - SW[15]    : 7-segment display mode: 0 = Decimal (0..900), 1 = Hexadecimal
// - LED[9:0]  : 10-bit result C[9:0] for selected element C[row,col]
// - LED[10]   : DONE flag (Latched high on completion, cleared on new START)
// - LED[11]   : BUSY flag (High during computation)
// - LED[13:12]: Echoes active pattern mode SW[14:13]
// - LED[15:14]: Echoes active Row index SW[3:2]
// - seg[6:0]  : 7-segment cathode segments (CA..CG, active-low)
// - dp        : Decimal point (active-low, indicates Hex mode when lit)
// - an[7:0]   : 8-digit multiplexed anode enables (active-low)
// ==============================================================================

`timescale 1ns / 1ps
`include "vivado_interfaces.svh"


module top_fpga_wrapper (
    input  logic        CLK100MHZ,   // 100 MHz onboard oscillator (Nexys A7 pin E3)
    input  logic        CPU_RESETN,  // Active-low CPU reset push button (pin C12)
    input  logic        BTNC,        // Center push button: START (pin N17)
    input  logic        BTNU,        // Up push button: LOAD (pin M18)
    input  logic        BTND,        // Down push button: Soft Reset (pin P18)
    input  logic        BTNL,        // Left push button: Custom Store (pin P17)
    input  logic        BTNR,        // Right push button (pin M17)
    input  logic [15:0] SW,          // 16 slide switches
    output logic [15:0] LED,         // 16 user LEDs
    output logic [6:0]  seg,         // 7-segment cathodes: [6]=CG ... [0]=CA
    output logic        dp,          // 7-segment decimal point
    output logic [7:0]  an           // 7-segment anodes (active-low digit enable)
);

    // =========================================================================
    // 1. Reset Generation & Synchronization
    // =========================================================================
    // Asynchronous assert, synchronous deassert reset
    logic rst_raw;
    assign rst_raw = CPU_RESETN & (~BTND);

    logic rst_sync0, rst_sync1;
    always_ff @(posedge CLK100MHZ or negedge rst_raw) begin
        if (!rst_raw) begin
            rst_sync0 <= 1'b0;
            rst_sync1 <= 1'b0;
        end else begin
            rst_sync0 <= 1'b1;
            rst_sync1 <= rst_sync0;
        end
    end
    wire rst_n = rst_sync1;

    // =========================================================================
    // 2. Push Button Synchronization & Edge Detection
    // =========================================================================
    logic btnc_s0, btnc_s1, btnc_prev;
    logic btnu_s0, btnu_s1, btnu_prev;
    logic btnl_s0, btnl_s1, btnl_prev;
    logic btnr_s0, btnr_s1, btnr_prev;
    logic [3:0] btn_select_counter;

    always_ff @(posedge CLK100MHZ or negedge rst_n) begin
        if (!rst_n) begin
            btnc_s0            <= 1'b0;
            btnc_s1            <= 1'b0;
            btnc_prev          <= 1'b0;
            btnu_s0            <= 1'b0;
            btnu_s1            <= 1'b0;
            btnu_prev          <= 1'b0;
            btnl_s0            <= 1'b0;
            btnl_s1            <= 1'b0;
            btnl_prev          <= 1'b0;
            btnr_s0            <= 1'b0;
            btnr_s1            <= 1'b0;
            btnr_prev          <= 1'b0;
            btn_select_counter <= 4'd0;
        end else begin
            btnc_s0   <= BTNC;
            btnc_s1   <= btnc_s0;
            btnc_prev <= btnc_s1;

            btnu_s0   <= BTNU;
            btnu_s1   <= btnu_s0;
            btnu_prev <= btnu_s1;

            btnl_s0   <= BTNL;
            btnl_s1   <= btnl_s0;
            btnl_prev <= btnl_s1;

            btnr_s0   <= BTNR;
            btnr_s1   <= btnr_s0;
            btnr_prev <= btnr_s1;
            if (btnr_s1 & (~btnr_prev)) begin
                btn_select_counter <= btn_select_counter + 4'd1;
            end
        end
    end

    wire btnc_pulse = btnc_s1 & (~btnc_prev); // 1-cycle pulse on BTNC press
    wire btnu_pulse = btnu_s1 & (~btnu_prev); // 1-cycle pulse on BTNU press
    wire btnl_pulse = btnl_s1 & (~btnl_prev); // 1-cycle pulse on BTNL press

    // =========================================================================
    // 3. Custom Interactive Matrix Storage (Pattern 3)
    // =========================================================================
    logic [3:0] custom_a [0:15];
    logic [3:0] custom_b [0:15];

    always_ff @(posedge CLK100MHZ or negedge rst_n) begin
        if (!rst_n) begin
            // Default initial custom matrices: A = [1..16], B = [1..16]
            custom_a[0]  <= 4'd1;  custom_a[1]  <= 4'd2;  custom_a[2]  <= 4'd3;  custom_a[3]  <= 4'd4;
            custom_a[4]  <= 4'd2;  custom_a[5]  <= 4'd3;  custom_a[6]  <= 4'd4;  custom_a[7]  <= 4'd1;
            custom_a[8]  <= 4'd3;  custom_a[9]  <= 4'd4;  custom_a[10] <= 4'd1;  custom_a[11] <= 4'd2;
            custom_a[12] <= 4'd4;  custom_a[13] <= 4'd1;  custom_a[14] <= 4'd2;  custom_a[15] <= 4'd3;

            custom_b[0]  <= 4'd2;  custom_b[1]  <= 4'd0;  custom_b[2]  <= 4'd1;  custom_b[3]  <= 4'd0;
            custom_b[4]  <= 4'd0;  custom_b[5]  <= 4'd2;  custom_b[6]  <= 4'd0;  custom_b[7]  <= 4'd1;
            custom_b[8]  <= 4'd1;  custom_b[9]  <= 4'd0;  custom_b[10] <= 4'd2;  custom_b[11] <= 4'd0;
            custom_b[12] <= 4'd0;  custom_b[13] <= 4'd1;  custom_b[14] <= 4'd0;  custom_b[15] <= 4'd2;
        end else if (btnl_pulse && (SW[14:13] == 2'b11)) begin
            // Manual write into custom matrix
            if (SW[8] == 1'b0) begin
                custom_a[SW[7:4]] <= SW[12:9];
            end else begin
                custom_b[SW[7:4]] <= SW[12:9];
            end
        end
    end

    logic [63:0] packed_custom_a;
    logic [63:0] packed_custom_b;
    always_comb begin
        for (int m = 0; m < 16; m = m + 1) begin
            packed_custom_a[63 - 4*m -: 4] = custom_a[m];
            packed_custom_b[63 - 4*m -: 4] = custom_b[m];
        end
    end

    // =========================================================================
    // 4. Test Pattern Multiplexer
    // =========================================================================
    logic [63:0] matrix_a_in;
    logic [63:0] matrix_b_in;

    always_comb begin
        case (SW[14:13])
            // Pattern 0: Identity Matrix Test
            // A = I_4 (diagonal 1s, off-diagonal 0s)
            // B = {{1,2,3,4}, {5,6,7,8}, {9,1,2,3}, {4,5,6,7}}
            // Expected Result: C = A * B = B
            2'b00: begin
                matrix_a_in = 64'h1000_0100_0010_0001;
                matrix_b_in = 64'h1234_5678_9123_4567;
            end

            // Pattern 1: All 1s for A, all 2s for B
            // Each dot product: 1*2 + 1*2 + 1*2 + 1*2 = 8
            // Expected Result: Every element C[row,col] = 8
            2'b01: begin
                matrix_a_in = 64'h1111_1111_1111_1111;
                matrix_b_in = 64'h2222_2222_2222_2222;
            end

            // Pattern 2: Full-Scale Max Value Test
            // A = all 15s (4'hF), B = all 15s (4'hF)
            // Each dot product: 4 * (15 * 15) = 4 * 225 = 900 (0x384)
            // Tests 10-bit accumulator range without overflow (max 900 < 1023)
            2'b10: begin
                matrix_a_in = 64'hFFFF_FFFF_FFFF_FFFF;
                matrix_b_in = 64'hFFFF_FFFF_FFFF_FFFF;
            end

            // Pattern 3: Custom Interactive Matrices
            2'b11: begin
                matrix_a_in = packed_custom_a;
                matrix_b_in = packed_custom_b;
            end
        endcase
    end

    // =========================================================================
    // 5. Automatic Sequencer FSM (LOAD -> START -> WAIT DONE)
    // =========================================================================
    typedef enum logic [1:0] {
        ST_IDLE  = 2'b00,
        ST_LOAD  = 2'b01,
        ST_START = 2'b10,
        ST_CALC  = 2'b11
    } state_t;

    state_t state;
    logic dut_load;
    logic dut_start;
    logic dut_done;
    logic done_latched;
    logic is_busy;

    always_ff @(posedge CLK100MHZ or negedge rst_n) begin
        if (!rst_n) begin
            state        <= ST_IDLE;
            dut_load     <= 1'b0;
            dut_start    <= 1'b0;
            done_latched <= 1'b0;
            is_busy      <= 1'b0;
        end else begin
            case (state)
                ST_IDLE: begin
                    is_busy <= 1'b0;
                    if (btnc_pulse) begin
                        // Automatic sequence: first pulse LOAD, then START
                        done_latched <= 1'b0;
                        dut_load     <= 1'b1;
                        is_busy      <= 1'b1;
                        state        <= ST_LOAD;
                    end else if (btnu_pulse) begin
                        // Manual LOAD request
                        dut_load <= 1'b1;
                    end else begin
                        dut_load <= 1'b0;
                    end
                end

                ST_LOAD: begin
                    dut_load  <= 1'b0;
                    dut_start <= 1'b1; // Trigger START on the next cycle
                    state     <= ST_START;
                end

                ST_START: begin
                    dut_start <= 1'b0;
                    state     <= ST_CALC;
                end

                ST_CALC: begin
                    if (dut_done) begin
                        done_latched <= 1'b1;
                        is_busy      <= 1'b0;
                        state        <= ST_IDLE;
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

    // =========================================================================
    // 6. Instantiate 4x4 MAC Top (DUT from DUT/rtl)
    // =========================================================================
    logic [9:0] dut_c;
    logic [3:0] active_select;

    // SELECT maps to SW[3:0] offset by BTNR step counter:
    // SW[3:2] = Row (0..3)
    // SW[1:0] = Column (0..3)
    // Pressing BTNR cycles to the next element
    assign active_select = SW[3:0] + btn_select_counter;

    DUT u_dut_core (
        .clk    (CLK100MHZ),
        .rst_n  (rst_n),
        .LOAD   (dut_load),
        .START  (dut_start),
        .SELECT (active_select),
        .A      (matrix_a_in),
        .B      (matrix_b_in),
        .C      (dut_c),
        .DONE   (dut_done)
    );

    // =========================================================================
    // 7. On-board LED Indicators
    // =========================================================================
    // LED[9:0]  : 10-bit result of the selected element C[row, col]
    // LED[10]   : Calculation completed (latched high until new START)
    // LED[11]   : Busy / calculating indicator
    // LED[13:12]: Echoes active test pattern mode SW[14:13]
    // LED[15:14]: Echoes active Row index SW[3:2]
    assign LED[9:0]   = dut_c;
    assign LED[10]    = done_latched;
    assign LED[11]    = is_busy;
    assign LED[13:12] = SW[14:13];
    assign LED[15:14] = active_select[3:2];

    // =========================================================================
    // 8. Seven-Segment Multiplexed Display Controller (8 Digits)
    // =========================================================================
    // Refresh counter for 8 digits: 100 MHz / 2^17 ~= 763 Hz (~95 Hz full refresh)
    logic [19:0] refresh_counter;
    always_ff @(posedge CLK100MHZ or negedge rst_n) begin
        if (!rst_n) refresh_counter <= 20'd0;
        else        refresh_counter <= refresh_counter + 20'd1;
    end

    wire [2:0] digit_sel = refresh_counter[19:17];

    // Binary to BCD for decimal display (Max value is 900)
    logic [3:0] bcd_thou, bcd_hund, bcd_tens, bcd_unit;
    always_comb begin
        bcd_thou = 4'd0;
        bcd_hund = 4'((dut_c / 10'd100) % 10'd10);
        bcd_tens = 4'((dut_c / 10'd10)  % 10'd10);
        bcd_unit = 4'(dut_c % 10'd10);
    end

    // Active nibble / character selection for the current digit:
    // Digit 7: 'r' (Row prefix)
    // Digit 6: Row number (0..3)
    // Digit 5: 'c' (Col prefix)
    // Digit 4: Col number (0..3)
    // Digit 3..0: Result C[9:0] (Decimal or Hexadecimal)
    logic [6:0] current_segments;
    logic       current_dp;

    // Standard 7-segment hex decoder (active-low cathodes)
    function automatic [6:0] hex_to_seg(input [3:0] val);
        case (val)
            4'h0: hex_to_seg = 7'b1000000;
            4'h1: hex_to_seg = 7'b1111001;
            4'h2: hex_to_seg = 7'b0100100;
            4'h3: hex_to_seg = 7'b0110000;
            4'h4: hex_to_seg = 7'b0011001;
            4'h5: hex_to_seg = 7'b0010010;
            4'h6: hex_to_seg = 7'b0000010;
            4'h7: hex_to_seg = 7'b1111000;
            4'h8: hex_to_seg = 7'b0000000;
            4'h9: hex_to_seg = 7'b0010000;
            4'hA: hex_to_seg = 7'b0001000;
            4'hb: hex_to_seg = 7'b0000011;
            4'hC: hex_to_seg = 7'b1000110;
            4'hd: hex_to_seg = 7'b0100011;
            4'hE: hex_to_seg = 7'b0000110;
            4'hF: hex_to_seg = 7'b0001110;
            default: hex_to_seg = 7'b1111111;
        endcase
    endfunction

    always_comb begin
        current_dp = 1'b1; // Default DP off (active-low)
        case (digit_sel)
            // Digit 0: Result Lowest Nibble / Units
            3'd0: begin
                an = 8'b11111110;
                current_segments = (SW[15] == 1'b0) ? hex_to_seg(bcd_unit) : hex_to_seg(dut_c[3:0]);
            end

            // Digit 1: Result Middle Nibble / Tens
            3'd1: begin
                an = 8'b11111101;
                current_segments = (SW[15] == 1'b0) ? hex_to_seg(bcd_tens) : hex_to_seg(dut_c[7:4]);
            end

            // Digit 2: Result High Nibble / Hundreds
            3'd2: begin
                an = 8'b11111011;
                current_segments = (SW[15] == 1'b0) ? hex_to_seg(bcd_hund) : hex_to_seg({2'b00, dut_c[9:8]});
            end

            // Digit 3: Result Thousands / 0x indicator (DP indicates Hex mode)
            3'd3: begin
                an = 8'b11110111;
                current_dp = ~SW[15]; // Lit in Hex mode
                current_segments = (SW[15] == 1'b0) ? hex_to_seg(bcd_thou) : hex_to_seg(4'h0);
            end

            // Digit 4: Column Index (0..3)
            3'd4: begin
                an = 8'b11101111;
                current_segments = hex_to_seg({2'b00, active_select[1:0]});
            end

            // Digit 5: Letter 'c' for Column
            3'd5: begin
                an = 8'b11011111;
                current_segments = 7'b0100111; // segments d, e, g lit
            end

            // Digit 6: Row Index (0..3)
            3'd6: begin
                an = 8'b10111111;
                current_segments = hex_to_seg({2'b00, active_select[3:2]});
            end

            // Digit 7: Letter 'r' for Row
            3'd7: begin
                an = 8'b01111111;
                current_segments = 7'b0101111; // segments e, g lit
            end

            default: begin
                an = 8'b11111111;
                current_segments = 7'b1111111;
            end
        endcase
    end

    assign seg = current_segments;
    assign dp  = current_dp;

endmodule
