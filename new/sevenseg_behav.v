`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03.04.2025 13:49:36
// Design Name: 
// Module Name: sevenseg_behav
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


module sevenseg_behav(
    input wire [3:0] sw,  // 4-bit binary input
    output reg A, B, C, D, E, F, G // Active-low for common anode
);
always @(*) begin
    case (sw)
        4'b0000: {A, B, C, D, E, F, G} = 7'b0000001; // 0
        4'b0001: {A, B, C, D, E, F, G} = 7'b1001111; // 1
        4'b0010: {A, B, C, D, E, F, G} = 7'b0010010; // 2
        4'b0011: {A, B, C, D, E, F, G} = 7'b0000110; // 3
        4'b0100: {A, B, C, D, E, F, G} = 7'b1001100; // 4
        4'b0101: {A, B, C, D, E, F, G} = 7'b0100100; // 5
        4'b0110: {A, B, C, D, E, F, G} = 7'b0100000; // 6
        4'b0111: {A, B, C, D, E, F, G} = 7'b0001111; // 7
        4'b1000: {A, B, C, D, E, F, G} = 7'b0000000; // 8
        4'b1001: {A, B, C, D, E, F, G} = 7'b0000100; // 9
        4'b1010: {A, B, C, D, E, F, G} = 7'b0001000; // A
        4'b1011: {A, B, C, D, E, F, G} = 7'b1100000; // B
        4'b1100: {A, B, C, D, E, F, G} = 7'b0110001; // C
        4'b1101: {A, B, C, D, E, F, G} = 7'b1000010; // D
        4'b1110: {A, B, C, D, E, F, G} = 7'b0110000; // E
        4'b1111: {A, B, C, D, E, F, G} = 7'b0111000; // F
        default: {A, B, C, D, E, F, G} = 7'b1111111; // Blank display
    endcase
end

endmodule

