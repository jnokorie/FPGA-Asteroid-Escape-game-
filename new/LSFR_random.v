// Design Name: 
// Module Name: LFSR_random
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


module LFSR_random(
    input game_clk,
    input rst,
    output [31:0] random_number,
    input [1:0] game_state_w
);

//reg  [25:0] rand     = 26'd0;   // 26-bit counter (0 …  67 108 863)
//reg         rnd_clk  = 1'b0;    // must be reg because it is driven here

//localparam  DIV_VAL  = 26'd1666666;   // compare value WIDTH-MATCHED

//always @(posedge clk or negedge rst) begin
//    if (!rst) begin
//        rand    <= 26'd0;
//        rnd_clk <= 1'b0;
//    end
//    else begin
//        if (rand == DIV_VAL) begin
//            rand    <= 26'd0;        // restart count
//            rnd_clk <= ~rnd_clk;     // toggle output
//        end
//        else begin
//            rand <= rand + 26'd1;    // increment every clk
//        end
//    end
//end
    
    reg [31:0] lfsr_reg;
    assign random_number = lfsr_reg;
    
               localparam
        IDLE            = 2'b00,
        OPENING_SCREEN  = 2'b01,
        GAME_RUNNING    = 2'b10,
        GAME_OVER       = 2'b11;

    always @(posedge game_clk or negedge rst) begin
        if (!rst) begin
            lfsr_reg <= 16'hACE1;  // Seed value, can be any non-zero value
        end else if (game_state_w == GAME_RUNNING) begin
            // Shift LFSR and apply XOR
            lfsr_reg <= {lfsr_reg[30:0], lfsr_reg[28] ^ lfsr_reg[21] ^ lfsr_reg[18] ^ lfsr_reg[14]^ lfsr_reg[9] ^ lfsr_reg[5]};
        end
    end


endmodule
