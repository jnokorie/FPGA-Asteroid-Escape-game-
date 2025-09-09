`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.04.2025 21:52:11
// Design Name: 
// Module Name: border_drawer
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
module border_drawer(
    input clk,
    input [10:0] curr_x,
    input [9:0] curr_y,
    output [3:0] border_r,
    output [3:0] border_g,
    output [3:0] border_b
);
    // Parameters
    parameter SCREEN_WIDTH = 1440;
    parameter SCREEN_HEIGHT = 890;
    parameter BORDER_LEFT = 50;
    parameter BORDER_RIGHT = 50;
    parameter BORDER_BOTTOM = 100;
    parameter INFOBAR_WIDTH = 1340;
    parameter INFOBAR_HEIGHT = 100;

    // Wires for border detection
    wire inside_left_border, inside_right_border, inside_bottom_border;
    wire [10:0] info_x;
    wire [9:0] info_y;
    wire [20:0] info_addr;
    
    wire [11:0] rom_pixel2; // output from BRAM

    assign inside_left_border = (curr_x < BORDER_LEFT);
    assign inside_right_border = (curr_x >= (SCREEN_WIDTH - BORDER_RIGHT));
    assign inside_bottom_border = (curr_y >= (SCREEN_HEIGHT - BORDER_BOTTOM)) && 
                                   (curr_x >= BORDER_LEFT) && (curr_x < (SCREEN_WIDTH - BORDER_RIGHT));

    // Info bar pixel location calculation
    assign info_x = curr_x - BORDER_LEFT; // Remove left padding
    assign info_y = curr_y - (SCREEN_HEIGHT - BORDER_BOTTOM); // Align bottom
    assign info_addr = info_y * INFOBAR_WIDTH + info_x; // Flatten 2D to 1D address

    // Instantiate the Info Bar BRAM
    blk_mem_gen_3 infobar_inst (
        .clka(clk),
        .ena(inside_bottom_border), // enable BRAM only during bottom border access
        .addra(info_addr),
        .douta(rom_pixel2)
    );

    // Color logic directly from wires (combinational)
    assign border_r = (inside_left_border || inside_right_border) ? 4'b0000 :
                      (inside_bottom_border) ? rom_pixel2[11:8] :
                      4'b0000;

    assign border_g = (inside_left_border || inside_right_border) ? 4'b0000 :
                      (inside_bottom_border) ? rom_pixel2[7:4] :
                      4'b0000;

    assign border_b = (inside_left_border || inside_right_border) ? 4'b0000 :
                      (inside_bottom_border) ? rom_pixel2[3:0] :
                      4'b0000;

endmodule


