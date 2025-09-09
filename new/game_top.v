`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.03.2025 17:59:46
// Design Name: 
// Module Name: game_top
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


module game_top(
    input clk,
    input rst,
    input [2:0] sw,
    input [4:0] btn,
    output [3:0] pix_r,
    output [3:0] pix_g,
    output[3:0] pix_b,
    output hsync,
    output vsync,
    output A, B, C, D, E, F, G, DP,
    output [7:0] an
    );
    
    // Internal wires
    wire pixclk;
    wire [10:0] curr_x;
    wire [9:0] curr_y;  
    wire [3:0] draw_r;
    wire [3:0] draw_g;
    wire [3:0] draw_b;
    wire [1:0] game_state_w;
    wire go_back_to_idle;
    
    
    // Wires for the block
    reg [20:0] clk_div;
    reg  game_clk;
    reg [10:0] blkpos_x;  
    reg [10:0] blkpos_y;
    
     // Asteroid position and active status
    wire [10:0] ast_x_0_w, ast_x_1_w, ast_x_2_w, ast_x_3_w,
                ast_x_4_w, ast_x_5_w, ast_x_6_w, ast_x_7_w;  
    wire  [9:0] ast_y_0_w, ast_y_1_w, ast_y_2_w, ast_y_3_w,
                ast_y_4_w, ast_y_5_w, ast_y_6_w, ast_y_7_w;  
    wire collision_detected_w;
    wire game_over_w;
    wire [7:0] time_remaining_w;
    wire [3:0] num0_w , num1_w , num2_w , num3_w;
    wire [15:0] time_remaining_;
    wire [10:0] exit_x_w;
    wire exit_reached_w;
    wire [3:0] game_over_seconds_w;
    
    // SCREEN PARAMETERS
    parameter SCREEN_HEIGHT = 890, SCREEN_WIDTH = 1439;
    parameter EXIT_WIDTH    = 100;  
    
       localparam
        IDLE            = 2'b00,
        OPENING_SCREEN  = 2'b01,
        GAME_RUNNING    = 2'b10,
        GAME_OVER       = 2'b11;
            
    clk_wiz_0 inst
    (
    // Clock out ports  
    .clk_out1(pixclk),
    // Clock in ports
    .clk_in1(clk)
    );
    
     
    
                                    // Ship speed control based on switches
    reg [3:0] ship_speed;
    wire [1:0] switch_count; // Wire to hold the count of active switches
    // Calculate ship speed based on number of active switches
    
        // Count the number of active switches
    assign switch_count = sw[0] + sw[1] + sw[2];
    
    always @(*) begin
        case(switch_count)
            2'd0: ship_speed = 4'd1;  // Slowest speed when no switches are up
            2'd1: ship_speed = 4'd2;  // Normal speed with one switch up
            2'd2: ship_speed = 4'd3;  // Faster with two switches up
            2'd3: ship_speed = 4'd4;  // Fastest with all three switches up
            default: ship_speed = 4'd4;
        endcase
    end
        
    // Game clock generation
    always @ (posedge clk or negedge rst)begin
        if (!rst) begin
            clk_div <= 0;
            game_clk <= 0;
        end else begin
            if (clk_div == 21'd1666666) begin
                clk_div <= 0;
                game_clk <= !game_clk; 
            end else begin
                clk_div <= clk_div + 1;
            end 
        end
    end
    
    
    // Slower clock called anim_clk time period 2 seconds
    reg [27:0] anim_clk_div;
    reg anim_clk;
    
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            anim_clk_div <= 0;
            anim_clk <= 0;
        end else begin
            if (anim_clk_div == 29'd99_999_999) begin  // 
                anim_clk_div <= 0;
                anim_clk <= ~anim_clk;
            end else begin
                anim_clk_div <= anim_clk_div + 1;
            end
        end
    end
 
    // Block movement
        always @(posedge game_clk or negedge rst) begin
                if (!rst)begin
                      blkpos_x <= 11'd650;
                      blkpos_y <= 11'd750;
                 end 
                else begin 
                    if (game_state_w == OPENING_SCREEN)begin
                        blkpos_x <= 11'd650;
                        blkpos_y <= 11'd750;
                end else
               if (game_state_w == GAME_RUNNING)begin
                      case (btn[4:1])
                      4'b0001: begin  // Up
                         if (blkpos_y > 11'd10) begin
                             // Normal move up if not too close to top
                             blkpos_y <= blkpos_y - ship_speed;
                         end else if ((blkpos_x + 11'd16 >= exit_x_w) 
                             && (blkpos_x + 11'd16 <= exit_x_w + EXIT_WIDTH)) begin
                             // Even if at the top, allow moving into exit
                             blkpos_y <= blkpos_y - ship_speed;
                         end
                           // Else: do not move up (at top, and not inside exit)
                         end// Up (prevent y < 0)
                      4'b0010: if (blkpos_x > 11'd50) blkpos_x <= blkpos_x - ship_speed;  // Left (prevent x < 0)
                      4'b0100: if (blkpos_x < 11'd1330) blkpos_x <= blkpos_x + ship_speed; // Right (prevent x > max)
                      4'b1000: if (blkpos_y < 11'd750) blkpos_y <= blkpos_y + ship_speed;  // Down (prevent y > max)
                      default: ;
                      endcase
                end 
                end
    end  
    


// Instantiate asteroid behavior module
    asteroid_behav asteroid_inst (
        .clk(clk),
        .rst(rst),
        .game_clk(game_clk),
        .game_over_w(game_over_w), 
        .blkpos_x(blkpos_x),
        .blkpos_y(blkpos_y),
        .collision_detected_w(collision_detected_w),
        .ast_x_0_w (ast_x_0_w), .ast_y_0_w (ast_y_0_w),
        .ast_x_1_w (ast_x_1_w), .ast_y_1_w (ast_y_1_w),
        .ast_x_2_w (ast_x_2_w), .ast_y_2_w (ast_y_2_w),
        .ast_x_3_w (ast_x_3_w), .ast_y_3_w (ast_y_3_w),
        .ast_x_4_w (ast_x_4_w), .ast_y_4_w (ast_y_4_w),
        .ast_x_5_w (ast_x_5_w), .ast_y_5_w (ast_y_5_w),
        .ast_x_6_w (ast_x_6_w), .ast_y_6_w (ast_y_6_w),
        .ast_x_7_w (ast_x_7_w), .ast_y_7_w (ast_y_7_w),
        .game_state_w(game_state_w), 
        .btn(btn),
        .exit_x_w(exit_x_w),
        .exit_reached_w(exit_reached_w)
    );




     // Pass asteroid positions and active states to drawcon
    drawcon drawcon_inst(
        .clk(pixclk),
        .rst(rst),
        .anim_clk(anim_clk),
        .blkpos_x(blkpos_x),
        .blkpos_y(blkpos_y),
        .draw_r(draw_r),
        .draw_g(draw_g),
        .draw_b(draw_b),
        .curr_x(curr_x),
        .curr_y(curr_y),
        .game_state_w(game_state_w),
        .ast_x_0_w (ast_x_0_w), .ast_y_0_w (ast_y_0_w),
        .ast_x_1_w (ast_x_1_w), .ast_y_1_w (ast_y_1_w),
        .ast_x_2_w (ast_x_2_w), .ast_y_2_w (ast_y_2_w),
        .ast_x_3_w (ast_x_3_w), .ast_y_3_w (ast_y_3_w),
        .ast_x_4_w (ast_x_4_w), .ast_y_4_w (ast_y_4_w),
        .ast_x_5_w (ast_x_5_w), .ast_y_5_w (ast_y_5_w),
        .ast_x_6_w (ast_x_6_w), .ast_y_6_w (ast_y_6_w),
        .ast_x_7_w (ast_x_7_w), .ast_y_7_w (ast_y_7_w),
        .time_remaining_w(time_remaining_w),
        .go_back_to_idle(go_back_to_idle),
        .collision_detected_w(collision_detected_w),
        .num0_w(num0_w), .num1_w(num1_w),.num2_w(num2_w),.num3_w(num3_w),
        .exit_x_w(exit_x_w),
        .exit_reached_w(exit_reached_w),
        .game_over_seconds_w(game_over_seconds_w)
    );

    vga_out vga_inst(
    .clk(pixclk),
    .rst(rst),
    .draw_r(draw_r),
    .draw_g(draw_g),
    .draw_b(draw_b),
    .pix_r(pix_r),
    .pix_g(pix_g),
    .pix_b(pix_b),
    .hsync(hsync),
    .curr_x(curr_x),
    .curr_y(curr_y),
    .vsync(vsync)
    );
    
    TheGameCountdown countdown_inst(
    .clk(clk),
    .rst(rst),
    .A(A), .B(B), .C(C), .D(D), .E(E), .F(F), .G(G),
    .game_state_w(game_state_w),
    .DP(DP),
    .an(an),
    .num0_w(num0_w), .num1_w(num1_w),.num2_w(num2_w),.num3_w(num3_w)
    );
    
    game_logic game_logic_inst(
        .game_clk(game_clk),
        .rst(rst),
        .btn(btn),
        .game_state_w(game_state_w),
        .collision_detected_w(collision_detected_w),
        .go_back_to_idle(go_back_to_idle),
        .num0_w(num0_w), .num1_w(num1_w),.num2_w(num2_w),.num3_w(num3_w),
        .exit_reached_w(exit_reached_w),
        .game_over_seconds_w(game_over_seconds_w)
    );

endmodule


