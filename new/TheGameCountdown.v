`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09.04.2025 18:36:00
// Design Name: 
// Module Name: TheGameCountdown
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

module TheGameCountdown(
    input clk,
    input rst,
    output A, B, C, D, E, F, G, DP,
    output [7:0] an,
    input [1:0] game_state_w,
    output  [3:0] num0_w , num1_w , num2_w , num3_w
    );
    
    wire div_clk;
    reg [3:0] num0 = 4'd5, num1 = 4'd2, num2 = 4'd0, num3 = 4'd0;
    assign num0_w = num0, num1_w = num1, num2_w = num2, num3_w = num3;
  
 
    localparam
        IDLE            = 2'b00,
        OPENING_SCREEN  = 2'b01,
        GAME_RUNNING    = 2'b10,
        GAME_OVER       = 2'b11;
    // Instance of the segmentinterface module
    segmentinterface timer_inst(
        .clk(clk),
        .rst(rst),
        .dig0(num0), .dig1(num1), .dig2(num2), .dig3(num3),
        .div_clk(div_clk), 
        .A(A), .B(B), .C(C), .D(D), .E(E), .F(F), .G(G),
        .an(an), .DP(DP)
    );
    
//     always @(posedge div_clk or negedge rst) begin
//        if (!rst) begin
//            delay <= delay + 1
//        end
//        else begin
//            if(game_state == GAME_OVER)begin
//            delay <= delay
    
    
    // Countdown logic
    always @(posedge div_clk or negedge rst) begin
        if (!rst) begin
            // Reset to 25 if reset button is pressed
            num0 <= 4'd5;
            num1 <= 4'd2;
            num2 <= 4'd0;
            num3 <= 4'd0;
        end else begin
        if (game_state_w == IDLE) begin
  
            num0 <= 4'd5;
            num1 <= 4'd2;
            num2 <= 4'd0;
            num3 <= 4'd0;
            
        end
       else if (num0 == 4'd0 && num1 == 4'd0 && num2 == 4'd0 && num3 == 4'd0 && game_state_w == GAME_RUNNING) begin
            // Once the countdown reaches 0, hold the 0
            num0 <= 4'd0;
            num1 <= 4'd0;
            num2 <= 4'd0;
            num3 <= 4'd0;
        end else if (num0 != 4'd0 && game_state_w == GAME_RUNNING) begin
            // Decrement the rightmost digit
            num0 <= num0 - 1;
        end else if (num0 == 4'd0 && num1 != 4'd0 && game_state_w == GAME_RUNNING) begin
            // Decrement the second rightmost digit
            num1 <= num1 - 1;
            num0 <= 4'd9;  // Reset the rightmost digit to 9
        end
        end
    end
    
    
endmodule
