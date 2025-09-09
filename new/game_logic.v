`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.04.2025 21:33:34
// Design Name: 
// Module Name: game_logic
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


module game_logic(
    input game_clk,
    input rst,
    input [4:0] btn,
    output [1:0] game_state_w,
    input collision_detected_w,
    input go_back_to_idle,
    input  [3:0] num0_w , num1_w , num2_w , num3_w,
    input exit_reached_w,
    input [3:0] game_over_seconds_w
    );

reg [1:0] game_state;
assign game_state_w = game_state;


    localparam
        IDLE            = 2'b00,
        OPENING_SCREEN  = 2'b01,
        GAME_RUNNING    = 2'b10, 
        GAME_OVER       = 2'b11;
        
            

    // Game state FSM
    always @(posedge game_clk or negedge rst) begin
        if (!rst) begin
            game_state <= OPENING_SCREEN;
        end else begin
            case (game_state)
                IDLE: 
                    if (game_over_seconds_w == 8)begin
                    game_state <= OPENING_SCREEN;
                    end
                OPENING_SCREEN:
                    if (btn[0])
                        game_state <= GAME_RUNNING;

                GAME_RUNNING:
                    if (collision_detected_w 
                    || (num0_w == 4'd0 
                    && num1_w == 4'd0 
                    && num2_w == 4'd0 
                    && num3_w == 4'd0)
                    ||exit_reached_w)
                        game_state <= GAME_OVER;
                GAME_OVER:
                    if (go_back_to_idle)
                        game_state <= IDLE;
                    else
                        game_state <= GAME_OVER;
                default:
                    game_state <= IDLE;
            endcase
        end
        
        
    end

endmodule

