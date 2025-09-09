`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 29.03.2025 17:50:30
// Design Name: 
// Module Name: drawcon
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


module drawcon(
    input clk,
    input rst,
    input anim_clk,
    input [10:0] blkpos_x,
    input [10:0] blkpos_y,
    input [1:0]  game_state_w,

    output [3:0] draw_r,
    output [3:0] draw_g,
    output [3:0] draw_b,
    output go_back_to_idle,

    input [10:0] curr_x,
    input  [9:0] curr_y,
    input sprite_enable,
    input collision_detected_w,
    input  [3:0] num0_w , num1_w , num2_w , num3_w,

    // ---------- asteroid inputs (now 0-7) ----------
    input [10:0] ast_x_0_w, input [9:0] ast_y_0_w,
    input [10:0] ast_x_1_w, input [9:0] ast_y_1_w,
    input [10:0] ast_x_2_w, input [9:0] ast_y_2_w,
    input [10:0] ast_x_3_w, input [9:0] ast_y_3_w,
    input [10:0] ast_x_4_w, input [9:0] ast_y_4_w,   
    input [10:0] ast_x_5_w, input [9:0] ast_y_5_w,   
    input [10:0] ast_x_6_w, input [9:0] ast_y_6_w,   
    input [10:0] ast_x_7_w, input [9:0] ast_y_7_w,    
    input [15:0] time_remaining_w,
    input [10:0] exit_x_w,
    input exit_reached_w,
    output [3:0] game_over_seconds_w
);

    // Background
    reg [3:0] blk_r, blk_b, blk_g;
    reg [3:0] bg_r, bg_b, bg_g;
    
    // Border
    wire [3:0] border_r, border_g, border_b;
    
    // Progress bar
    reg [10:0] bar_max_width;
    reg [10:0] bar_current_width;
    wire [3:0] bar_r, bar_b, bar_g;
    
    // Logo
    reg [3:0] logo_r, logo_g, logo_b;
    reg [18:0] logo_addr;
    wire [11:0] logo_pixel;
    
    // Address counters and RGBs
    wire [11:0] rom_pixel_asteroid;
    wire [11:0] rom_pixel_ast0;
    wire [11:0] rom_pixel_ast90;
    wire [11:0] rom_pixel_ast180;
    wire [11:0] rom_pixel_ast270;


    
    // Signals for image
    parameter BLK_SIZE_X = 32, BLK_SIZE_Y = 32;
    parameter AST_SIZE = 40; 
    reg [13:0] addr;
    wire [11:0] rom_pixel; 
    wire [11:0] rom_pixel2; 
    wire [11:0] rom_pixelshiphit1;
    wire [11:0] rom_pixelshiphit2;
    reg [18:0] addr_logo;
    wire [11:0] rom_pixel_logo;

    
    // Asteroid Frame Control 
    reg [1:0] asteroid_frame;
    reg [25:0] frame_counter; 
    
    // Reg and Wires for game_over
    reg [25:0] game_over_timer;  // 26 bits is enough for 4 seconds at 60MHz clock
    reg showing_shiphit2;
    reg go_back_to_idle_r;
    reg [3:0] game_over_seconds;
    assign game_over_seconds_w = game_over_seconds;
    assign go_back_to_idle = go_back_to_idle_r;
    reg show_blue_background;
    // Registers for asteroid data
    reg [11:0] ast0_data, ast90_data, ast180_data, ast270_data;
    reg [10:0] asteroid_addr_0, asteroid_addr_90, asteroid_addr_180, asteroid_addr_270;
    
    localparam
        IDLE            = 2'b00,
        OPENING_SCREEN  = 2'b01,
        GAME_RUNNING    = 2'b10,
        GAME_OVER       = 2'b11;
        
    
    
    wire draw_asteroids = (game_state_w == GAME_RUNNING); 
    
    // Enable pins    
    assign ena = (game_state_w == GAME_RUNNING) || (game_state_w == GAME_OVER);
    assign ena_op = (game_state_w == OPENING_SCREEN);
    assign ena_str32 = (game_state_w == OPENING_SCREEN);
    assign ena_str45 = (game_state_w == OPENING_SCREEN);
    assign ena_ast = (game_state_w == GAME_RUNNING);  
    assign ena_cl = (game_state_w == GAME_OVER);
    assign ena1 = (game_state_w == GAME_OVER);
    assign ena2 = (game_state_w == GAME_OVER);
    wire ena0 = (ena_ast && (asteroid_frame == 2'd0));  
    wire ena90 = (ena_ast && (asteroid_frame == 2'd1));
    wire ena180 = (ena_ast && (asteroid_frame == 2'd2));
    wire ena270 = (ena_ast && (asteroid_frame == 2'd3));
    
        // Bar properties;
    parameter SCREEN_HEIGHT = 890;
    parameter SCREEN_WIDTH = 1440;
    parameter BORDER_LEFT = 50;
    parameter BORDER_RIGHT = 50;
    parameter BORDER_BOTTOM = 100;
    parameter MAX_TIME = 4500;  // 45.00 seconds
    
    
    wire draw_exit = (game_state_w == GAME_RUNNING) &&
                   (curr_y <= 10) &&    // top edge of screen (say, first 10 pixels)
                   (curr_x >= exit_x_w) && (curr_x <= exit_x_w + 100);  // exit width 100

    wire draw_ast_0 = (game_state_w == GAME_RUNNING) &&
                      (curr_x >= ast_x_0_w) && (curr_x < ast_x_0_w + AST_SIZE) &&
                      (curr_y >= ast_y_0_w) && (curr_y < ast_y_0_w + AST_SIZE)
                      && (curr_y < SCREEN_HEIGHT - BORDER_BOTTOM);
    
    wire draw_ast_1 = (game_state_w == GAME_RUNNING) &&
                      (curr_x >= ast_x_1_w) && (curr_x < ast_x_1_w + AST_SIZE) &&
                      (curr_y >= ast_y_1_w) && (curr_y < ast_y_1_w + AST_SIZE)
                      && (curr_y < SCREEN_HEIGHT - BORDER_BOTTOM);
    
    wire draw_ast_2 = (game_state_w == GAME_RUNNING) &&
                      (curr_x >= ast_x_2_w) && (curr_x < ast_x_2_w + AST_SIZE) &&
                      (curr_y >= ast_y_2_w) && (curr_y < ast_y_2_w + AST_SIZE)
                      && (curr_y < SCREEN_HEIGHT - BORDER_BOTTOM);
    
    wire draw_ast_3 = (game_state_w == GAME_RUNNING) &&
                      (curr_x >= ast_x_3_w) && (curr_x < ast_x_3_w + AST_SIZE) &&
                      (curr_y >= ast_y_3_w) && (curr_y < ast_y_3_w + AST_SIZE)
                      && (curr_y < SCREEN_HEIGHT - BORDER_BOTTOM);
    
    wire draw_ast_4 = (game_state_w == GAME_RUNNING) &&
                      (curr_x >= ast_x_4_w) && (curr_x < ast_x_4_w + AST_SIZE) &&
                      (curr_y >= ast_y_4_w) && (curr_y < ast_y_4_w + AST_SIZE)
                      && (curr_y < SCREEN_HEIGHT - BORDER_BOTTOM);

    wire draw_ast_5 = (game_state_w == GAME_RUNNING) &&
                      (curr_x >= ast_x_5_w) && (curr_x < ast_x_5_w + AST_SIZE) &&
                      (curr_y >= ast_y_5_w) && (curr_y < ast_y_5_w + AST_SIZE)
                      && (curr_y < SCREEN_HEIGHT - BORDER_BOTTOM);

    wire draw_ast_6 = (game_state_w == GAME_RUNNING) &&
                      (curr_x >= ast_x_6_w) && (curr_x < ast_x_6_w + AST_SIZE) &&
                      (curr_y >= ast_y_6_w) && (curr_y < ast_y_6_w + AST_SIZE)
                      && (curr_y < SCREEN_HEIGHT - BORDER_BOTTOM);

    wire draw_ast_7 = (game_state_w == GAME_RUNNING) &&
                      (curr_x >= ast_x_7_w) && (curr_x < ast_x_7_w + AST_SIZE) &&
                      (curr_y >= ast_y_7_w) && (curr_y < ast_y_7_w + AST_SIZE)
                      && (curr_y < SCREEN_HEIGHT - BORDER_BOTTOM);
    
    wire draw_ast_any = draw_ast_0 || draw_ast_1 || draw_ast_2 || draw_ast_3 ||
                    draw_ast_4 || draw_ast_5 || draw_ast_6 || draw_ast_7;   
                    
                     
    // Constants
    // Logo image (e.g., 600x371)
    localparam LOGO_WIDTH  = 600;
    localparam LOGO_HEIGHT = 371;
    localparam LOGO_X = (1440 - LOGO_WIDTH) / 2; // Centered horizontally
    localparam LOGO_Y = (890 - LOGO_HEIGHT) / 2; // Centered vertically
    
    

    
    // Progress bar dimensions
    parameter BAR_HEIGHT = 20;
    parameter BAR_X_START = BORDER_LEFT + 970; 
    parameter BAR_Y_OFFSET = 70; // About 30-40 pixels lower to appear beneath the word
    parameter BAR_Y_START = SCREEN_HEIGHT - BORDER_BOTTOM + BAR_Y_OFFSET; 

     reg delay_r;
    
     // Frame counter slower clock for asteroid
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            // Asynchronous reset only
            frame_counter <= 0;
            asteroid_frame <= 0;
            game_over_seconds <= 0;
        end 
        else begin
            // Synchronous reset for OPENING_SCREEN
            if (game_state_w == OPENING_SCREEN) begin
                frame_counter <= 0;
                asteroid_frame <= 0;
                game_over_seconds <= 0;
            end
            else begin
                // Normal operation
                if (frame_counter >= 26'd60_000_000) begin 
                    frame_counter <= 0;  
                    asteroid_frame <= (asteroid_frame == 2'd3) ? 2'd0 : (asteroid_frame + 1);
                    if (game_state_w == GAME_OVER || game_state_w == IDLE ) begin
                        game_over_seconds <= game_over_seconds + 1;
                    end
                end 
                else begin
                    frame_counter <= frame_counter + 1;
                end
            end
        end
    end
    

    // Another frame for game_over
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            showing_shiphit2     <= 1'b0;
            go_back_to_idle_r    <= 1'b0;
            show_blue_background <= 1'b0;
        end
        else if (game_state_w == OPENING_SCREEN) begin
            // Reset all flags when returning to opening screen
            showing_shiphit2     <= 1'b0;
            go_back_to_idle_r    <= 1'b0;
            show_blue_background <= 1'b0;
        end
        else if (game_state_w == GAME_OVER) begin
            if (show_blue_background) begin
                // We are showing blue background already
                if (game_over_seconds == 4) begin
                    go_back_to_idle_r    <= 1'b1;
                    show_blue_background <= 1'b0;  // clear blue screen after 4s
                end
            end
            else if (exit_reached_w) begin
                // Just entered exit: start showing blue
                show_blue_background <= 1'b1;
                showing_shiphit2      <= 1'b0;
            end
            else begin
                // Normal crash/timeout behavior
                if (game_over_seconds == 2)
                    showing_shiphit2 <= 1'b1;
                if (game_over_seconds == 6)
                    go_back_to_idle_r <= 1'b1;
            end
        end
    end





   
                                                        // Code for screens   
    always @(posedge clk) begin
        if (!rst) begin
            // Reset all outputs
            addr_logo <= 0; logo_r <= 0; logo_g <= 0; logo_b <= 0;
        end else begin
            case (game_state_w)
                OPENING_SCREEN: begin
                // --- Draw opening screen logo ---
                if (curr_x >= LOGO_X && curr_x < LOGO_X + LOGO_WIDTH &&
                    curr_y >= LOGO_Y && curr_y < LOGO_Y + LOGO_HEIGHT) begin
                    addr_logo <= (curr_y - LOGO_Y) * LOGO_WIDTH + (curr_x - LOGO_X);
                    logo_r <= rom_pixel_logo[11:8];
                    logo_g <= rom_pixel_logo[7:4];
                    logo_b <= rom_pixel_logo[3:0];
                end else begin
                    logo_r <= 0; logo_g <= 0; logo_b <= 0;
                end
    
            end
            
            default: begin  // IDLE and GAME_RUNNING
                // Turn off all screen elements
                logo_r <= 0; logo_g <= 0; logo_b <= 0;
                end
            endcase
        end
    end
    
                                                    // Code for stars on game running screen
    reg [3:0] man_star_r, man_star_g, man_star_b;
    reg [10:0] man_star_x [0:19];
    reg [9:0]  man_star_y [0:19];
    
    integer i;

    initial begin
        man_star_x[0] = 100; man_star_y[0] = 100;
        man_star_x[1] = 200; man_star_y[1] = 300;
        man_star_x[2] = 300; man_star_y[2] = 500;
        man_star_x[3] = 400; man_star_y[3] = 150;
        man_star_x[4] = 500; man_star_y[4] = 400;
        man_star_x[5] = 600; man_star_y[5] = 200;
        man_star_x[6] = 700; man_star_y[6] = 600;
        man_star_x[7] = 800; man_star_y[7] = 100;
        man_star_x[8] = 900; man_star_y[8] = 250;
        man_star_x[9] = 1000; man_star_y[9] = 450;
        man_star_x[10] = 1100; man_star_y[10] = 350;
        man_star_x[11] = 1200; man_star_y[11] = 550;
        man_star_x[12] = 1300; man_star_y[12] = 300;
        man_star_x[13] = 1400; man_star_y[13] = 500;
        man_star_x[14] = 100; man_star_y[14] = 700;
        man_star_x[15] = 200; man_star_y[15] = 800;
        man_star_x[16] = 300; man_star_y[16] = 650;
        man_star_x[17] = 400; man_star_y[17] = 750;
        man_star_x[18] = 500; man_star_y[18] = 850;
        man_star_x[19] = 600; man_star_y[19] = 700;
    end
    
    always @* begin
        man_star_r = 0; man_star_g = 0; man_star_b = 0;
        if (game_state_w == GAME_RUNNING) begin
            for (i = 0; i < 20; i = i + 1) begin
                if ((curr_x >= man_star_x[i] && curr_x < man_star_x[i] + 2) &&
                    (curr_y >= man_star_y[i] && curr_y < man_star_y[i] + 2)) begin
                    man_star_r = 4'b1111;
                    man_star_g = 4'b1111;
                    man_star_b = 4'b1111;
                end
            end
        end
    end
    

    
    // Background colour  
    always @* begin
    if (show_blue_background) begin
        bg_r = 4'b0000;
        bg_g = 4'b0000;
        bg_b = 4'b1111;  // Blue
    end else begin
        case (game_state_w)
            IDLE: begin
                bg_r = 4'b0000;
                bg_g = 4'b0000;
                bg_b = 4'b0000;
            end
            OPENING_SCREEN: begin
                bg_r = 4'b0001;
                bg_g = 4'b0001;
                bg_b = 4'b0001;
            end
            GAME_RUNNING: begin
                bg_r = 4'b0000;
                bg_g = 4'b0000;
                bg_b = 4'b0000;
            end
            GAME_OVER: begin
                bg_r = 4'b0000;
                bg_g = 4'b0000;
                bg_b = 4'b0000;
            end
            default: begin
                bg_r = 4'b0000;
                bg_g = 4'b0000;
                bg_b = 4'b0000;
            end
        endcase
    end
    end
    
    
    
                                                     // Code for drawing Ship
    always @(posedge clk) begin
        if (!rst) begin
            blk_r <= 0;
            blk_g <= 0;
            blk_b <= 0;
            addr <= 0;  // <<< Reset address too
        end else begin
            if (ena &&
                curr_x >= blkpos_x && curr_x < blkpos_x + BLK_SIZE_X &&
                curr_y >= blkpos_y && curr_y < blkpos_y + BLK_SIZE_Y) begin
    
                // Set color
                if (game_state_w == GAME_RUNNING) begin
                    if (anim_clk) begin
                        blk_r <= rom_pixel[11:8];
                        blk_g <= rom_pixel[7:4];
                        blk_b <= rom_pixel[3:0];
                    end else begin
                        blk_r <= rom_pixel2[11:8];
                        blk_g <= rom_pixel2[7:4];
                        blk_b <= rom_pixel2[3:0];
                    end
                end
                else if (game_state_w == GAME_OVER) begin
                    if (showing_shiphit2) begin
                        blk_r <= rom_pixelshiphit2[11:8];
                        blk_g <= rom_pixelshiphit2[7:4];
                        blk_b <= rom_pixelshiphit2[3:0];
                    end else begin
                        blk_r <= rom_pixelshiphit1[11:8];
                        blk_g <= rom_pixelshiphit1[7:4];
                        blk_b <= rom_pixelshiphit1[3:0];
                    end
                end else begin
                    blk_r <= 0;
                    blk_g <= 0;
                    blk_b <= 0;
                end
    
                // Update address
                if ((curr_x == blkpos_x) && (curr_y == blkpos_y))
                    addr <= 0;
                else
                    addr <= addr + 1;
    
            end else begin
                blk_r <= 0;
                blk_g <= 0;
                blk_b <= 0;
            end
        end
    end
    
    
                                                             // Code for asteroids
    // Pipeline the ROM data to improve timing
    always @(posedge clk) begin
        if (ena_ast) begin
            ast0_data <= rom_pixel_ast0;
            ast90_data <= rom_pixel_ast90;
            ast180_data <= rom_pixel_ast180;
            ast270_data <= rom_pixel_ast270;
        end
    end

    // Asteroid address calculation - now split into separate always blocks for clarity
    always @* begin
        asteroid_addr_0 = 0;
        asteroid_addr_90 = 0;
        asteroid_addr_180 = 0;
        asteroid_addr_270 = 0;
        
        if (game_state_w == GAME_RUNNING) begin
            // Calculate addresses for all 8 asteroid ROMs at once
            // First asteroid
            if ((curr_x >= ast_x_0_w) && (curr_x < ast_x_0_w + AST_SIZE) &&
                (curr_y >= ast_y_0_w) && (curr_y < ast_y_0_w + AST_SIZE)) begin
                asteroid_addr_0 = (curr_y - ast_y_0_w) * AST_SIZE + (curr_x - ast_x_0_w);
                asteroid_addr_90 = (curr_y - ast_y_0_w) * AST_SIZE + (curr_x - ast_x_0_w);
                asteroid_addr_180 = (curr_y - ast_y_0_w) * AST_SIZE + (curr_x - ast_x_0_w);
                asteroid_addr_270 = (curr_y - ast_y_0_w) * AST_SIZE + (curr_x - ast_x_0_w);
            end
            // Second asteroid
            else if ((curr_x >= ast_x_1_w) && (curr_x < ast_x_1_w + AST_SIZE) &&
                    (curr_y >= ast_y_1_w) && (curr_y < ast_y_1_w + AST_SIZE)) begin
                asteroid_addr_0 = (curr_y - ast_y_1_w) * AST_SIZE + (curr_x - ast_x_1_w);
                asteroid_addr_90 = (curr_y - ast_y_1_w) * AST_SIZE + (curr_x - ast_x_1_w);
                asteroid_addr_180 = (curr_y - ast_y_1_w) * AST_SIZE + (curr_x - ast_x_1_w);
                asteroid_addr_270 = (curr_y - ast_y_1_w) * AST_SIZE + (curr_x - ast_x_1_w);
            end
            // Third asteroid
            else if ((curr_x >= ast_x_2_w) && (curr_x < ast_x_2_w + AST_SIZE) &&
                    (curr_y >= ast_y_2_w) && (curr_y < ast_y_2_w + AST_SIZE)) begin
                asteroid_addr_0 = (curr_y - ast_y_2_w) * AST_SIZE + (curr_x - ast_x_2_w);
                asteroid_addr_90 = (curr_y - ast_y_2_w) * AST_SIZE + (curr_x - ast_x_2_w);
                asteroid_addr_180 = (curr_y - ast_y_2_w) * AST_SIZE + (curr_x - ast_x_2_w);
                asteroid_addr_270 = (curr_y - ast_y_2_w) * AST_SIZE + (curr_x - ast_x_2_w);
            end
            // Fourth asteroid
            else if ((curr_x >= ast_x_3_w) && (curr_x < ast_x_3_w + AST_SIZE) &&
                     (curr_y >= ast_y_3_w) && (curr_y < ast_y_3_w + AST_SIZE)) begin
                asteroid_addr_0 = (curr_y - ast_y_3_w) * AST_SIZE + (curr_x - ast_x_3_w);
                asteroid_addr_90 = asteroid_addr_0;
                asteroid_addr_180 = asteroid_addr_0;
                asteroid_addr_270 = asteroid_addr_0;
            // Fifth asteroid ---------------------------------------------------- ★ NEW
            end else if ((curr_x >= ast_x_4_w) && (curr_x < ast_x_4_w + AST_SIZE) &&
                         (curr_y >= ast_y_4_w) && (curr_y < ast_y_4_w + AST_SIZE)) begin
                asteroid_addr_0 = (curr_y - ast_y_4_w) * AST_SIZE + (curr_x - ast_x_4_w);
                asteroid_addr_90 = asteroid_addr_0;
                asteroid_addr_180 = asteroid_addr_0;
                asteroid_addr_270 = asteroid_addr_0;
            // Sixth asteroid ---------------------------------------------------- 
            end else if ((curr_x >= ast_x_5_w) && (curr_x < ast_x_5_w + AST_SIZE) &&
                         (curr_y >= ast_y_5_w) && (curr_y < ast_y_5_w + AST_SIZE)) begin
                asteroid_addr_0 = (curr_y - ast_y_5_w) * AST_SIZE + (curr_x - ast_x_5_w);
                asteroid_addr_90 = asteroid_addr_0;
                asteroid_addr_180 = asteroid_addr_0;
                asteroid_addr_270 = asteroid_addr_0;
            // Seventh asteroid -------------------------------------------------- 
            end else if ((curr_x >= ast_x_6_w) && (curr_x < ast_x_6_w + AST_SIZE) &&
                         (curr_y >= ast_y_6_w) && (curr_y < ast_y_6_w + AST_SIZE)) begin
                asteroid_addr_0 = (curr_y - ast_y_6_w) * AST_SIZE + (curr_x - ast_x_6_w);
                asteroid_addr_90 = asteroid_addr_0;
                asteroid_addr_180 = asteroid_addr_0;
                asteroid_addr_270 = asteroid_addr_0;
            // Eighth asteroid --------------------------------------------------- 
            end else if ((curr_x >= ast_x_7_w) && (curr_x < ast_x_7_w + AST_SIZE) &&
                         (curr_y >= ast_y_7_w) && (curr_y < ast_y_7_w + AST_SIZE)) begin
                asteroid_addr_0 = (curr_y - ast_y_7_w) * AST_SIZE + (curr_x - ast_x_7_w);
                asteroid_addr_90 = asteroid_addr_0;
                asteroid_addr_180 = asteroid_addr_0;
                asteroid_addr_270 = asteroid_addr_0;
            end

        end
    end
    
    // 2. Pipeline registers for asteroid rendering
    reg [3:0] ast_r_reg, ast_g_reg, ast_b_reg;
    always @(posedge clk) begin
        if (!rst) begin
            ast_r_reg <= 0;
            ast_g_reg <= 0;
            ast_b_reg <= 0;
        end else begin
            if (game_state_w == GAME_RUNNING && draw_ast_any) begin
                case (asteroid_frame)
                    2'd0: begin
                        ast_r_reg <= ast0_data[11:8];
                        ast_g_reg <= ast0_data[7:4];
                        ast_b_reg <= ast0_data[3:0];
                    end
                    2'd1: begin
                        ast_r_reg <= ast90_data[11:8];
                        ast_g_reg <= ast90_data[7:4];
                        ast_b_reg <= ast90_data[3:0];
                    end
                    2'd2: begin
                        ast_r_reg <= ast180_data[11:8];
                        ast_g_reg <= ast180_data[7:4];
                        ast_b_reg <= ast180_data[3:0];
                    end
                    2'd3: begin
                        ast_r_reg <= ast270_data[11:8];
                        ast_g_reg <= ast270_data[7:4];
                        ast_b_reg <= ast270_data[3:0];
                    end
                endcase
            end else begin
                ast_r_reg <= 0;
                ast_g_reg <= 0;   //   (ast_r != bg_r)  is false 0;
                ast_b_reg <= 0; 
            end
        end
    end
        
    // Asteroid drawing - completely rewritten
    reg [3:0] ast_r, ast_g, ast_b;
    
    always @(posedge clk) begin
        if (!rst) begin
            ast_r <= 0;
            ast_g <= 0;
            ast_b <= 0;
        end else begin
            if (game_state_w == GAME_RUNNING &&
    ((curr_x >= ast_x_0_w && curr_x < ast_x_0_w + AST_SIZE && curr_y >= ast_y_0_w && curr_y < ast_y_0_w + AST_SIZE) ||
     (curr_x >= ast_x_1_w && curr_x < ast_x_1_w + AST_SIZE && curr_y >= ast_y_1_w && curr_y < ast_y_1_w + AST_SIZE) ||
     (curr_x >= ast_x_2_w && curr_x < ast_x_2_w + AST_SIZE && curr_y >= ast_y_2_w && curr_y < ast_y_2_w + AST_SIZE) ||
     (curr_x >= ast_x_3_w && curr_x < ast_x_3_w + AST_SIZE && curr_y >= ast_y_3_w && curr_y < ast_y_3_w + AST_SIZE) ||
     (curr_x >= ast_x_4_w && curr_x < ast_x_4_w + AST_SIZE && curr_y >= ast_y_4_w && curr_y < ast_y_4_w + AST_SIZE) || 
     (curr_x >= ast_x_5_w && curr_x < ast_x_5_w + AST_SIZE && curr_y >= ast_y_5_w && curr_y < ast_y_5_w + AST_SIZE) || 
     (curr_x >= ast_x_6_w && curr_x < ast_x_6_w + AST_SIZE && curr_y >= ast_y_6_w && curr_y < ast_y_6_w + AST_SIZE) || 
     (curr_x >= ast_x_7_w && curr_x < ast_x_7_w + AST_SIZE && curr_y >= ast_y_7_w && curr_y < ast_y_7_w + AST_SIZE)))  
 begin
                
                // Only show non-transparent pixels
                if ((asteroid_frame == 2'd0 && ast0_data != 0) ||
                    (asteroid_frame == 2'd1 && ast90_data != 0) ||
                    (asteroid_frame == 2'd2 && ast180_data != 0) ||
                    (asteroid_frame == 2'd3 && ast270_data != 0)) begin
                    ast_r <= ast_r_reg;
                    ast_g <= ast_g_reg;
                    ast_b <= ast_b_reg;
                end else begin
                    ast_r <= 0;
                    ast_g <= 0;
                    ast_b <= 0;
                end
            end else begin
                ast_r <= bg_r;
                ast_g <= bg_g;
                ast_b <= bg_b;
            end
        end
    end
    
    // Bar that increases by 20 pixels every 2 seconds
    parameter BAR_INCREMENT = 25;      // Increase by 20 pixels each step
    reg anim_clk_prev;                 // To detect rising edge
    
        // Draw the progress bar
    assign bar_r = (curr_y >= BAR_Y_START && curr_y < BAR_Y_START + BAR_HEIGHT &&
                    curr_x >= BAR_X_START && curr_x < BAR_X_START + bar_current_width) ? 4'hF : 4'h0;
    assign bar_g = 4'h0;
    assign bar_b = 4'h0;
            
    // Update the bar width every 2 seconds using anim_clk
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            bar_current_width <= 0;
            anim_clk_prev <= 0;
        end else begin
            anim_clk_prev <= anim_clk;
        
            if (game_state_w == 2'b10) begin // Only grow during GAME_RUNNING
                if (anim_clk && !anim_clk_prev) begin
                    if (bar_current_width + BAR_INCREMENT < SCREEN_WIDTH - BORDER_RIGHT)
                        bar_current_width <= bar_current_width + BAR_INCREMENT;
                    else
                        bar_current_width <= SCREEN_WIDTH - BORDER_RIGHT;  // Max width
                end
            end else begin
                bar_current_width <= 0; // Reset bar if not playing
            end
        end
    end

        // Composite color logic
    assign draw_r = (bar_r != 0) ? bar_r :
                    (border_r != 0) ? border_r :     
                    (logo_r != 0) ? logo_r :
                    (draw_exit) ? 4'b0000 :
                    (blk_r != 0) ? blk_r :
                    (ast_r != bg_r) ? ast_r :
                    (man_star_r != 0) ? man_star_r : 
                    
                    bg_r;
    
    assign draw_g = (bar_g != 0) ? bar_g :
                    (border_g != 0) ? border_g: 
                    (logo_g != 0) ? logo_g :
                    (draw_exit) ? 4'b0000 :
                    (blk_g != 0) ? blk_g :
                    (ast_g != bg_g) ? ast_g :                   
                    (man_star_g != 0) ? man_star_g :   
                   
                    bg_g;
    
    assign draw_b = (bar_b != 0) ? bar_b :
                    (border_b != 0) ? border_b : 
                    (logo_b != 0) ? logo_b :
                    (draw_exit) ? 4'b1111 :
                    (blk_b != 0) ? blk_b :
                    (ast_b != bg_b) ? ast_b :
                    (man_star_b != 0) ? man_star_b : 
                    
                    bg_b;
                        
    
    // Instantiate block ROM
    blk_mem_gen_1 inst_ship (
        .clka(clk),
        .addra(addr),
        .douta(rom_pixel),
        .ena(ena)
    );
    
    blk_mem_gen_0 inst_start (
        .clka(clk),
        .addra(addr_logo),
        .douta(rom_pixel_logo),
        .ena(ena_op)
    );
    
    
    blk_mem_gen_2 inst_asteroid_sprite (
    .clka(clk),
    .addra(asteroid_addr_0),
    .douta(rom_pixel_ast0),
    .ena(ena0)
    );
    
    blk_mem_gen_5 inst_asteroid_sprite90 (
    .clka(clk),
    .addra(asteroid_addr_90),
    .douta(rom_pixel_ast90),
    .ena(ena90)
    );
    
    blk_mem_gen_6 inst_asteroid_sprite180 (
    .clka(clk),
    .addra(asteroid_addr_180),
    .douta(rom_pixel_ast180),
    .ena(ena180)
    );
    
    blk_mem_gen_7 inst_asteroid_sprite270 (
    .clka(clk),
    .addra(asteroid_addr_270),
    .douta(rom_pixel_ast270),
    .ena(ena270)
    );
    
    blk_mem_gen_8 ship_hit1 (
        .clka(clk),
        .addra(addr),
        .douta(rom_pixelshiphit1),
        .ena(ena1)
    );
    
        blk_mem_gen_9 ship_hit2 (
        .clka(clk),
        .addra(addr),
        .douta(rom_pixelshiphit2),
        .ena(ena2)
    );
    
        blk_mem_gen_10 ship_inst2 (
        .clka(clk),
        .addra(addr),
        .douta(rom_pixel2),
        .ena(ena)
    );


    border_drawer border_inst (
        .clk(clk),
        .curr_x(curr_x),
        .curr_y(curr_y),
        .border_r(border_r),
        .border_g(border_g),
        .border_b(border_b)
    );
        
endmodule
