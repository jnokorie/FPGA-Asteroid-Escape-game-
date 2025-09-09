`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.04.2025 13:35:24
// Design Name: 
// Module Name: segmentinterface
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module segmentinterface(
    input clk, rst,
    input [3:0] dig7, dig6, dig5, dig4, dig3, dig2, dig1, dig0,
    output div_clk,
    output A, B, C, D, E, F, G, DP,
    output [7:0] an // Output for each of the seven segment display anodes
);

    reg [28:0] clk_count = 29'd0; // Initial state for clock counter
    wire led_clk;

    // Clock divider for generating the refresh clock
    always @(posedge clk) begin
        clk_count <= clk_count + 1'b1;  // Increment the clock counter
    end

    assign led_clk = clk_count[16]; // LED refresh clock (adjust as needed)
    
    reg [26:0] precise_counter = 27'd0;  // 27 bits to count to 100M
    reg precise_1hz_clk = 1'b0;          // 1Hz clock signal

    // Clock divider for exactly 1 second period (1Hz)
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            precise_counter <= 27'd0;
            precise_1hz_clk <= 1'b0;
        end else begin
            if (precise_counter == 27'd49_999_999) begin  // Half of 100M-1 for 1Hz
                precise_counter <= 27'd0;
                precise_1hz_clk <= ~precise_1hz_clk;  // Toggle to create 1Hz clock
            end else begin
                precise_counter <= precise_counter + 1'b1;
            end
        end
    end

    assign div_clk = precise_1hz_clk;  // Use precise 1Hz clock for div_clk

    reg [7:0] led_strobe = 8'b11111110; // Initial state for LED strobe
    reg [2:0] led_index = 3'd0;  // Initial state for LED index

    // LED strobe handling with circular shift
    always @(posedge led_clk) begin
        led_strobe <= {led_strobe[6:0], led_strobe[7]}; // Circular shift without reset
    end

    assign an = led_strobe; // Driving anodes based on strobe pattern

    // Cycle through LEDs based on led_clk
    always @(posedge led_clk) begin
        led_index <= led_index + 1'b1; // Increment to select the next LED
    end

    reg [3:0] dig_sel;  // Register to hold selected digit for display

    // Select the correct digit to display based on led_index
    always @* begin
        case (led_index)
            3'd0: dig_sel = dig0;
            3'd1: dig_sel = dig1;
            3'd2: dig_sel = dig2;
            3'd3: dig_sel = dig3;
            3'd4: dig_sel = dig4;
            3'd5: dig_sel = dig5;
            3'd6: dig_sel = dig6;
            3'd7: dig_sel = dig7;
            default: dig_sel = 4'b0000; // Default case to avoid latches
        endcase
    end

    // Decimal point control for colons (using active low for segments)
    reg dp_reg = 1'b0;
    assign DP = ~dp_reg; // Active low DP

    // Control which decimal points light up based on led_index
    always @* begin
        case (led_index)
            3'd2: dp_reg = 1'b1; // Light up DP after digit 2 
            3'd6: dp_reg = 1'b1; // Light up DP after digit 6 
            default: dp_reg = 1'b0;
        endcase
    end

    // Seven segment display logic instance
    sevenseg_behav seg_inst (
        .sw(dig_sel), .A(A), .B(B), .C(C), .D(D), .E(E), .F(F), .G(G)
    );

endmodule


