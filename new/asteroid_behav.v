`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10.04.2025 22:33:54
// Design Name: 
// Module Name: asteroid_behav
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

module asteroid_behav(
    input         clk,              
    input         rst,              
    input         game_clk,         
    input  [1:0]  game_state_w,     
    input  [4:0]  btn,
    input  [10:0] blkpos_x,
    input  [10:0] blkpos_y,
    output        collision_detected_w,
    output        game_over_w,

    // asteroid positions
    output [10:0] ast_x_0_w, ast_x_1_w, ast_x_2_w, ast_x_3_w,
                  ast_x_4_w, ast_x_5_w, ast_x_6_w, ast_x_7_w,
    output  [9:0] ast_y_0_w, ast_y_1_w, ast_y_2_w, ast_y_3_w,
                  ast_y_4_w, ast_y_5_w, ast_y_6_w, ast_y_7_w,

    // exit block
    output [10:0] exit_x_w,
    output        exit_reached_w
);

    parameter SCREEN_WIDTH  = 1439;
    parameter SCREEN_HEIGHT =  830;
    parameter AST_SIZE      =   40;
    parameter MIN_SPD       =    5;
    parameter MAX_SPD       =    7;
    parameter EXIT_WIDTH    =  100; // width of the blue exit
    parameter BORDER        =   50; // Border width on each side
    
    localparam ACTIVE_W     = SCREEN_WIDTH - AST_SIZE - (BORDER * 2);
    localparam ACTIVE_H     = SCREEN_HEIGHT - AST_SIZE;
    localparam NUM_AST      = 8;
    localparam HALF_H       = (ACTIVE_H>>1);
    localparam GAME_RUNNING = 2'b10;
    
    localparam
        IDLE            = 2'b00,
        OPENING_SCREEN  = 2'b01,
        GAME_OVER       = 2'b11;

    // random number generator
    wire [31:0] random_number;
    LFSR_random lfsr_inst (
        .game_clk(game_clk),
        .rst(rst),
        .random_number(random_number),
        .game_state_w(game_state_w)
    );

    // asteroid registers
    reg [10:0] asteroid_x [0:NUM_AST-1];
    reg  [9:0] asteroid_y [0:NUM_AST-1];
    reg  [2:0] asteroid_speed [0:NUM_AST-1];
    reg second_wave;
    reg collision_detected, game_over;

    assign collision_detected_w = collision_detected;
    assign game_over_w = game_over;

    assign {ast_x_0_w,ast_x_1_w,ast_x_2_w,ast_x_3_w,
            ast_x_4_w,ast_x_5_w,ast_x_6_w,ast_x_7_w} =
           {asteroid_x[0],asteroid_x[1],asteroid_x[2],asteroid_x[3],
            asteroid_x[4],asteroid_x[5],asteroid_x[6],asteroid_x[7]};

    assign {ast_y_0_w,ast_y_1_w,ast_y_2_w,ast_y_3_w,
            ast_y_4_w,ast_y_5_w,ast_y_6_w,ast_y_7_w} =
           {asteroid_y[0],asteroid_y[1],asteroid_y[2],asteroid_y[3],
            asteroid_y[4],asteroid_y[5],asteroid_y[6],asteroid_y[7]};

    // exit registers
    reg [10:0] exit_x;
    reg exit_reached;

    assign exit_x_w = exit_x;
    assign exit_reached_w = exit_reached;

    integer j;
    always @(posedge game_clk or negedge rst) begin
        if (!rst) begin
            for (j = 0; j < NUM_AST; j = j + 1) begin
                asteroid_speed[j] <= MIN_SPD;
                asteroid_x[j]     <= BORDER + j * (ACTIVE_W / NUM_AST); // Add border offset
                asteroid_y[j]     <= (j < 4) ? 0 : (SCREEN_HEIGHT + AST_SIZE);
            end
            second_wave <= 1'b0;
            // reset exit
            exit_x <= 11'd300;  // default
        end
        else begin
            if (btn[0] && game_state_w != GAME_RUNNING) begin
                asteroid_speed[0] <= random_number[2:0]   % (MAX_SPD-MIN_SPD+1) + MIN_SPD;
                asteroid_x[0]     <= BORDER + (random_number[10:0]  % ACTIVE_W);
                asteroid_speed[1] <= random_number[5:3]   % (MAX_SPD-MIN_SPD+1) + MIN_SPD;
                asteroid_x[1]     <= BORDER + (random_number[16:6]  % ACTIVE_W);
                asteroid_speed[2] <= random_number[8:6]   % (MAX_SPD-MIN_SPD+1) + MIN_SPD;
                asteroid_x[2]     <= BORDER + (random_number[19:9]  % ACTIVE_W);
                asteroid_speed[3] <= random_number[11:9]  % (MAX_SPD-MIN_SPD+1) + MIN_SPD;
                asteroid_x[3]     <= BORDER + (random_number[28:18] % ACTIVE_W);

                for (j = 0; j < 4; j = j + 1)
                    asteroid_y[j] <= 0;

                for (j = 4; j < NUM_AST; j = j + 1)
                    asteroid_y[j] <= SCREEN_HEIGHT + AST_SIZE;

                second_wave <= 1'b0;

                // re-roll exit location (ensure it stays within borders)
                exit_x <= BORDER + (random_number[13:3] % (ACTIVE_W - EXIT_WIDTH + AST_SIZE));
            end

            else if (game_state_w == GAME_RUNNING) begin
                if (!second_wave && asteroid_y[1] >= HALF_H) begin
                    second_wave <= 1'b1;

                    asteroid_speed[4] <= random_number[14:12] % (MAX_SPD-MIN_SPD+1)+MIN_SPD;
                    asteroid_x[4]     <= BORDER + (random_number[31:21] % ACTIVE_W);
                    asteroid_speed[5] <= random_number[17:15] % (MAX_SPD-MIN_SPD+1)+MIN_SPD;
                    asteroid_x[5]     <= BORDER + (random_number[24:14] % ACTIVE_W);
                    asteroid_speed[6] <= random_number[20:18] % (MAX_SPD-MIN_SPD+1)+MIN_SPD;
                    asteroid_x[6]     <= BORDER + (random_number[17:7]  % ACTIVE_W);
                    asteroid_speed[7] <= random_number[23:21] % (MAX_SPD-MIN_SPD+1)+MIN_SPD; 
                    asteroid_x[7]     <= BORDER + (random_number[22:12] % ACTIVE_W);

                    for (j = 4; j < NUM_AST; j = j + 1)
                        asteroid_y[j] <= 0;
                end

                for (j = 0; j < NUM_AST; j = j + 1) begin
                    if (j < 4 || second_wave) begin
                        asteroid_y[j] <= asteroid_y[j] + asteroid_speed[j];
                        if (asteroid_y[j] > (SCREEN_HEIGHT - AST_SIZE)) begin
                            case (j)
                            0: begin
                                   asteroid_x[j] <= BORDER + (random_number[10:0]  % ACTIVE_W);
                                   asteroid_speed[j] <= random_number[2:0]  % (MAX_SPD-MIN_SPD+1)+MIN_SPD;
                               end
                            1: begin
                                   asteroid_x[j] <= BORDER + (random_number[16:6] % ACTIVE_W);
                                   asteroid_speed[j] <= random_number[5:3]  % (MAX_SPD-MIN_SPD+1)+MIN_SPD;
                               end
                            2: begin
                                   asteroid_x[j] <= BORDER + (random_number[19:9]  % ACTIVE_W);
                                   asteroid_speed[j] <= random_number[8:6]  % (MAX_SPD-MIN_SPD+1)+MIN_SPD;
                               end
                            3: begin
                                   asteroid_x[j] <= BORDER + (random_number[28:18] % ACTIVE_W);
                                   asteroid_speed[j] <= random_number[11:9] % (MAX_SPD-MIN_SPD+1)+MIN_SPD;
                               end
                            4: begin
                                   asteroid_x[j] <= BORDER + (random_number[29:19] % ACTIVE_W);
                                   asteroid_speed[j] <= random_number[14:12]% (MAX_SPD-MIN_SPD+1)+MIN_SPD;
                               end
                            5: begin
                                   asteroid_x[j] <= BORDER + (random_number[24:14] % ACTIVE_W);
                                   asteroid_speed[j] <= random_number[17:15]% (MAX_SPD-MIN_SPD+1)+MIN_SPD;
                               end
                            6: begin
                                   asteroid_x[j] <= BORDER + (random_number[17:7]  % ACTIVE_W);
                                   asteroid_speed[j] <= random_number[20:18]% (MAX_SPD-MIN_SPD+1)+MIN_SPD;
                               end
                            7: begin
                                   asteroid_x[j] <= BORDER + (random_number[22:12] % ACTIVE_W);
                                   asteroid_speed[j] <= random_number[23:21]% (MAX_SPD-MIN_SPD+1)+MIN_SPD;
                               end
                            endcase
                            asteroid_y[j] <= 0;
                        end          
                    end
                end
            end
        end
    end

    always @(posedge game_clk or negedge rst) begin
        if (!rst) begin
            collision_detected <= 1'b0;
            game_over <= 1'b0;
        end else begin
            collision_detected <= 1'b0;
            for (j = 0; j < NUM_AST; j = j + 1) begin
                if ((asteroid_x[j] < blkpos_x + 32) &&
                    (asteroid_x[j] + AST_SIZE > blkpos_x) &&
                    (asteroid_y[j] < blkpos_y + 32) &&
                    (asteroid_y[j] + AST_SIZE > blkpos_y))
                        collision_detected <= 1'b1;
            end
            if (collision_detected) game_over <= 1'b1;
        end
    end
    
    always @(posedge game_clk or negedge rst) begin
        if (!rst) begin
            exit_reached <= 1'b0;
        end else begin
            if (game_state_w == OPENING_SCREEN) begin
                exit_reached <= 1'b0; 
            end
            if (((blkpos_x+11'd16 >= exit_x) &&
                    (blkpos_x+11'd16 <= exit_x+EXIT_WIDTH) &&
                    (blkpos_y <= 11'd5) &&
                    (game_state_w == GAME_RUNNING))) begin
                exit_reached <= 1'b1;
            end
        end
    end

endmodule

