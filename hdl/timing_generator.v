`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Sergiusz Bazanski <sergiusz@bazanski.pl>
// Licensed under BSD 2-Clause, see COPYING.
// 
// Create Date: 11/10/2015 10:42:10 PM
// Design Name: 
// Module Name: timing_generator
// Project Name: LED Controller for GRAET JUSTICE
// Target Devices: MYiR ZTurn Board with Zynq-7010
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// 
//////////////////////////////////////////////////////////////////////////////////
module timing_generator #(
    // Number of display chains
    parameter integer C_LED_CHAINS = 4,
    // Maximum length of display chain
    parameter integer C_LED_CHAIN_LENGTH = 4,
    // Number of banks in one chain
    parameter integer C_LED_NBANKS = 16,
    // Width of one display
    parameter integer C_LED_WIDTH = 32,
    // Clock divider from system clock to LED blit clock
    parameter integer C_LED_CLKDIV = 16,
    // Bits per pixel colour
    parameter integer C_BPC = 12
)
(
    // TODO: change to target config registers
    /*input [31:0] bufa_base,
    input [31:0] bufa_limit,
    input [31:0] bufb_base,
    input [31:0] bufb_limit,
    input buf_sel,*/
    
    input sys_en,
    input sys_clk,
    input sys_rst,
    
    output reg led_clk,
    output reg led_stb,
    output reg led_oe,
    output [$clog2(C_LED_NBANKS)-1 : 0] led_bank,
    
    output [$clog2(C_LED_WIDTH * C_LED_CHAIN_LENGTH)-1 : 0] ctl_cur_x,
    output [$clog2(C_LED_NBANKS)-1 : 0] ctl_cur_y,
    output [$clog2(C_BPC)-1 : 0] ctl_cur_bit,
    output ctl_vsync
);    

/// Counters
// Current line pixel counter
reg [$clog2(C_LED_WIDTH * C_LED_CHAIN_LENGTH)-1 : 0] pixel_counter;
assign ctl_cur_x = pixel_counter;
// Frame bank counter
reg [$clog2(C_LED_NBANKS)-1 : 0] bank_counter;
assign led_bank = bank_counter;
assign ctl_cur_y = bank_counter;
// Individual pixel divider
reg [$clog2(C_LED_CLKDIV)-1 : 0] divider_counter;
// Subframe counter (for pixel bits)
reg [$clog2(C_BPC)-1 : 0] subframe_counter;
assign ctl_cur_bit = subframe_counter;

/// Internal condition signals
// Are we blitting out the last pixel in the current line?
wire last_pixel = (pixel_counter >= (C_LED_WIDTH * C_LED_CHAIN_LENGTH) - 1);
// Are we blitting out the last line in the current subframe?
wire last_line = (bank_counter >= C_LED_NBANKS - 1);
// Are we blitting out the last subframe in the frame?
wire last_subframe = (subframe_counter >= C_BPC - 1);

/// Line FSM
// Idle
`define LINE_IDLE 3'b000
// Preparation before first pixel of line
`define LINE_PREPARE_FOR_BURST 3'b001
// Burst out a pixel, switch to next one if divider counter reaches zero
`define LINE_BURST 3'b010
// Wait for latch confirmation
`define LINE_WAIT_FOR_CONFIRMATION 3'b011
// Latch out this row, 
`define LINE_LATCH 3'b100
reg [2:0] line_fsm_state;
wire line_fsm_start;
reg line_fsm_busy;

always @(posedge sys_clk or negedge sys_rst)
begin
    if (~sys_rst) begin
        /// Reset counters
        // New output period
        divider_counter <= 0;
        // New column
        pixel_counter <= 0;
        
        line_fsm_busy <= 0;
        line_fsm_state <= `LINE_IDLE;
    end else begin
        case (line_fsm_state)
            `LINE_IDLE: begin
                // Two-step for potential clock domain cross
                if (~line_fsm_busy) begin
                    if (line_fsm_start) begin
                        line_fsm_busy <= 1;
                    end else begin
                        line_fsm_busy <= 0;
                    end
                end else begin
                    line_fsm_state <= `LINE_PREPARE_FOR_BURST;
                end
            end
            `LINE_PREPARE_FOR_BURST: begin
                // Begin new pixel
                divider_counter <= C_LED_CLKDIV - 1;
                // Begin new row
                pixel_counter <= 0;
                
                // Set outputs
                led_clk <= 0;
                led_stb <= 0;
                
                line_fsm_state <= `LINE_BURST;
            end
            `LINE_BURST: begin
                // Count down divider_counter, increment pixel_counter on underflow
                if (divider_counter == 0) begin
                    // Count up pixel counter, see if we blitted all pixels in this row
                    if (last_pixel) begin
                        pixel_counter <= 0;
                        line_fsm_state <= `LINE_LATCH;
                    end else begin
                        pixel_counter <= pixel_counter + 1;
                    end
                    divider_counter <= C_LED_CLKDIV - 1;
                end else begin
                    divider_counter <= divider_counter - 1;
                end
                // Stretch LED clock accross countdown domain (so that we clock out the data in the middle of the period)
                //             _______        _______
                //            |       |      |       |
                // clk  ______|       |______|       |____
                // dat ><=============><=============><=====
                // ctr  80---------> 0 80 --------> 0 80 ----
                if (divider_counter >= (C_LED_CLKDIV / 2))
                    led_clk <= 0;
                else
                    led_clk <= 1;
            end
            `LINE_LATCH: begin
                // Cleanup after previous state...
                led_clk <= 0;
                
                if (divider_counter == 0) begin
                    line_fsm_state <= `LINE_IDLE;
                    line_fsm_busy <= 0;
                end else begin
                    divider_counter <= divider_counter - 1;
                end
                
                if (divider_counter < ((C_LED_CLKDIV >> 1) + (C_LED_CLKDIV >> 2)))
                    led_stb <= 0;
                else
                    led_stb <= 1;
            end
        endcase
    end
end

/// Subframe FSM
`define SUBFRAME_IDLE 3'b000
`define SUBFRAME_CALIBRATE 3'b001
`define SUBFRAME_CALIBRATE2 3'b010
`define SUBFRAME_WAIT 3'b011
`define SUBFRAME_WAIT2 3'b100
`define SUBFRAME_VSYNC1 3'b101
`define SUBFRAME_VSYNC2 3'b110
reg [2:0] subframe_fsm_state;

// Create some register for Line FSM control lines
reg subframe_line_start;
assign line_fsm_start = subframe_line_start;

// Delay counter for subframe, and calibration counter (for first, smaller interval)
// We need to do some calculations... this should be able to fit
//  2**C_BPC  * (C_LED_WIDTH * C_LED_CHAIN_LENGTH) * C_LED_CLKDIV  * 2
//    |         |                                       |           \____ convservative guesstimate :v
//    |         |                                       \____ amounts of sysclocks we spend on a pixel
//    |         \___ number of LEDs we drive in one line
//    \___ bits per pixel timeslot change (if shortest period is X, longest is X * 2**C_BPC) 
reg [$clog2(2**C_BPC  * (C_LED_WIDTH * C_LED_CHAIN_LENGTH) * C_LED_CLKDIV * 2)-1: 0] subframe_delay;
reg [$clog2((C_LED_WIDTH * C_LED_CHAIN_LENGTH) * C_LED_CLKDIV * 2)-1: 0] subframe_calibration_delay;

reg vsync;
assign ctl_vsync = vsync;
always @(posedge sys_clk or negedge sys_rst)
begin
    if (~sys_rst) begin
        subframe_counter <= 0;
        subframe_calibration_delay <= 0;
        subframe_delay <= 0;
        bank_counter <= 0;
        vsync <= 0;
        
        subframe_line_start <= 0;
        subframe_fsm_state <= `SUBFRAME_IDLE;
    end else begin
        case (subframe_fsm_state)
            `SUBFRAME_IDLE: begin
                led_oe <= 1;
                if (!line_fsm_busy) begin
                    subframe_line_start <= 1;
                    //if (subframe_counter == 0 && bank_counter == 0) begin
                        // we're running the first, smallest subframe interval - start calibration
                    //    subframe_fsm_state <= `SUBFRAME_CALIBRATE;
                    //    subframe_delay <= 0;
                    //end else begin
                        subframe_fsm_state <= `SUBFRAME_WAIT;
                        subframe_delay <= (8 << subframe_counter); 
                    //end
                end else begin
                end
            end
            `SUBFRAME_CALIBRATE: begin
                subframe_line_start <= 0;
                subframe_calibration_delay <= 0;
                subframe_fsm_state <= `SUBFRAME_CALIBRATE2;
            end
            `SUBFRAME_CALIBRATE2: begin
                if (!line_fsm_busy) begin
                    //subframe_calibration_delay <= (subframe_calibration_delay >> 8);
                    subframe_calibration_delay <= 1;
                    subframe_delay <= ((subframe_calibration_delay>>1) << subframe_counter);
                    subframe_fsm_state <= `SUBFRAME_WAIT2;
                end else begin
                    subframe_calibration_delay <= subframe_calibration_delay + 1;
                end
            end
            `SUBFRAME_WAIT: begin
                subframe_line_start <= 0;
                subframe_fsm_state <= `SUBFRAME_WAIT2;
            end
            `SUBFRAME_WAIT2: begin
                if (!line_fsm_busy) begin
                    led_oe <= 0;
                    if (subframe_delay == 0) begin
                        
                        
                        if (last_subframe) begin
                            subframe_counter <= 0;
                            if (last_line) begin
                                bank_counter <= 0;
                                subframe_fsm_state <= `SUBFRAME_VSYNC1;
                                subframe_delay = 10;
                            end else begin
                                bank_counter <= bank_counter + 1;
                                subframe_fsm_state <= `SUBFRAME_IDLE;
                            end
                        end else begin
                            subframe_counter <= subframe_counter + 1;
                            subframe_fsm_state <= `SUBFRAME_IDLE;
                        end
                    end else begin
                        subframe_delay <= subframe_delay - 1;
                    end
                end else begin
                    led_oe <= 1;
                end
            end
            `SUBFRAME_VSYNC1: begin
                led_oe <= 1;
                vsync <= 1;
                if (subframe_delay == 0) begin
                    subframe_fsm_state <= `SUBFRAME_VSYNC2;
                    subframe_delay <= 50;
                end else begin
                    subframe_delay <= subframe_delay - 1;
                end
            end
            `SUBFRAME_VSYNC2: begin
                vsync <= 0;
                if (subframe_delay == 0) begin
                    subframe_fsm_state <= `SUBFRAME_IDLE;
                end else begin
                    subframe_delay <= subframe_delay - 1;
                end
            end
        endcase
    end
end

endmodule
