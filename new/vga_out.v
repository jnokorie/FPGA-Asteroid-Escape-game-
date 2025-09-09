`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.03.2025 17:17:15
// Design Name: 
// Module Name: vga_out
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

module vga_out(
    input clk,
    input rst,
    //input [2:0] sw,
    input [3:0] draw_r,
    input [3:0] draw_g,
    input[3:0] draw_b,
    output [3:0] pix_r,
    output [3:0] pix_g,
    output[3:0] pix_b,
    output [10:0] curr_x, 
    output [9:0] curr_y,    
    output hsync,
    output vsync
    );
    
    // internal signals
    reg [10:0] hcount;
    reg [9:0] vcount;
    reg [10:0] curr_x_r;
    reg [9:0] curr_y_r;
    
   // wire pixclk;
    
    wire display_region;
    wire line_end = (hcount == 11'd1903);
    wire frame_end = (vcount == 10'd931);

    
    // hsync vsync assign combinational
    assign hsync = ((hcount >= 11'd0) && (hcount <= 11'd151));
    assign vsync = ((vcount >= 10'd0) && (vcount <= 10'd2));
    assign display_region = ((hcount >= 11'd384) && (hcount <= 11'd1823) 
                            && (vcount >= 10'd31) && (vcount <= 10'd930));
    
    
    // pix assign combinational
    assign pix_r = (display_region) ? draw_r : 4'b0000;
    assign pix_g = (display_region) ? draw_g : 4'b0000;
    assign pix_b = (display_region) ? draw_b : 4'b0000;
    
    // hcount synchronous
    always @(posedge clk) begin
        if (!rst) // Active low
            hcount <= 11'd0;
        else begin
            if (line_end)
                hcount <= 11'd0;
            else        
                hcount <= hcount + 11'd1;  
        end
    end 
   
    // vcount synchronous
    always @(posedge clk or negedge rst)begin
        if (!rst) // Active low
           vcount <= 10'd0;
        else begin
            if (line_end) begin
                if (frame_end) 
                    vcount <= 10'd0;
                else
                    vcount <= vcount + 10'd1;
                end
        end
    end     
    
    // Current X synchronous
    always @(posedge clk or negedge rst)begin
        if (!rst) // Active low
            curr_x_r <= 11'd0;
        else begin
             if (display_region)  
                curr_x_r <= (hcount - 11'd384);
             else
                curr_x_r <= 11'd0;        
        end
    end  

    // Current Y synchronous
    always @(posedge clk or negedge rst)begin
        if (!rst) // Active low
            curr_y_r <= 11'd0;
        else begin
             if (display_region)  
                curr_y_r <= (vcount - 11'd31);
             else
                curr_y_r <= 11'd0;        
        end
    end  
     
    assign curr_x = curr_x_r;  
    assign curr_y = curr_y_r;     


endmodule

