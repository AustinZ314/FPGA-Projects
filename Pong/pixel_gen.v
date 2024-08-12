`timescale 1ns / 1ps

module pixel_gen(
    input clk,  
    input reset,    
    input up,
    input down,
    input video_on,
    input [9:0] x,
    input [9:0] y,
    output reg [11:0] rgb
    );
    
    // Maximum x, y values in display area
    parameter X_MAX = 639;
    parameter Y_MAX = 479;
    
    // Create 60Hz refresh tick
    wire refresh_tick;
    assign refresh_tick = ((y == 481) && (x == 0)) ? 1 : 0; // Start of vsync
    
    // Wall boundaries
    parameter X_WALL_L = 32;    
    parameter X_WALL_R = 39;    // 8 pixels wide
    
    // Paddle horizontal boundaries
    parameter X_PAD_L = 600;
    parameter X_PAD_R = 603;    // 4 pixels wide
    // Paddle vertical boundary signals
    wire [9:0] y_pad_t, y_pad_b;
    parameter PAD_HEIGHT = 72;  // 72 pixels high
    // Register to track top boundary and buffer
    reg [9:0] y_pad_reg, y_pad_next;
    // Paddle moving velocity when a button is pressed
    parameter PAD_VELOCITY = 3;
    
    // Square rom boundaries for ball
    parameter BALL_SIZE = 8;
    // Ball horizontal boundary signals
    wire [9:0] x_ball_l, x_ball_r;
    // Ball vertical boundary signals
    wire [9:0] y_ball_t, y_ball_b;
    // Register to track top left position
    reg [9:0] y_ball_reg, x_ball_reg;
    // Signals for register buffer
    wire [9:0] y_ball_next, x_ball_next;
    // Registers to track ball speed and buffers
    reg [9:0] x_delta_reg, x_delta_next;
    reg [9:0] y_delta_reg, y_delta_next;
    // Positive or negative ball velocity
    parameter BALL_VELOCITY_POS = 2;
    parameter BALL_VELOCITY_NEG = -2;
    // Round ball from square image
    wire [2:0] rom_addr, rom_col;   // 3-bit rom address and rom column
    reg [7:0] rom_data;             // Data at current rom address
    wire rom_bit;                   // Signify when rom data is 1 or 0 for ball rgb control
    
    // Register Control
    always @(posedge clk or negedge reset)
        if(~reset) begin
            y_pad_reg <= 0;
            x_ball_reg <= 0;
            y_ball_reg <= 0;
            x_delta_reg <= 10'h002;
            y_delta_reg <= 10'h002;
        end
        else begin
            y_pad_reg <= y_pad_next;
            x_ball_reg <= x_ball_next;
            y_ball_reg <= y_ball_next;
            x_delta_reg <= x_delta_next;
            y_delta_reg <= y_delta_next;
        end
    
    // Ball rom
    always @ (*)
        case(rom_addr)
            3'b000 :    rom_data = 8'b00111100; //   ****  
            3'b001 :    rom_data = 8'b01111110; //  ******
            3'b010 :    rom_data = 8'b11111111; // ********
            3'b011 :    rom_data = 8'b11111111; // ********
            3'b100 :    rom_data = 8'b11111111; // ********
            3'b101 :    rom_data = 8'b11111111; // ********
            3'b110 :    rom_data = 8'b01111110; //  ******
            3'b111 :    rom_data = 8'b00111100; //   ****
        endcase
    
    // Object status signals
    wire wall_on, pad_on, sq_ball_on, ball_on;
    wire [11:0] wall_rgb, pad_rgb, ball_rgb, bg_rgb;
    
    // Pixel within wall boundaries
    assign wall_on = ((X_WALL_L <= x) && (x <= X_WALL_R)) ? 1 : 0;
    
    // Assign object colors
    assign wall_rgb = 12'hFFF;
    assign pad_rgb = 12'hAAA;
    assign ball_rgb = 12'hFFF;
    assign bg_rgb = 12'h111;
    
    // Paddle 
    assign y_pad_t = y_pad_reg;                             // Paddle top position
    assign y_pad_b = y_pad_t + PAD_HEIGHT - 1;              // Paddle bottom position
    assign pad_on = (X_PAD_L <= x) && (x <= X_PAD_R) &&     // Pixel within paddle boundaries
                    (y_pad_t <= y) && (y <= y_pad_b);
                    
    // Paddle control
    always @ (*) begin
        y_pad_next = y_pad_reg;
        if(refresh_tick)
            if(~up & (y_pad_t > PAD_VELOCITY))
                y_pad_next = y_pad_reg - PAD_VELOCITY;  // Move up
            else if(~down & (y_pad_b < (Y_MAX - PAD_VELOCITY)))
                y_pad_next = y_pad_reg + PAD_VELOCITY;  // Move down
    end
    
    // Rom data square boundaries
    assign x_ball_l = x_ball_reg;
    assign y_ball_t = y_ball_reg;
    assign x_ball_r = x_ball_l + BALL_SIZE - 1;
    assign y_ball_b = y_ball_t + BALL_SIZE - 1;
    // Pixel within rom square boundaries
    assign sq_ball_on = (x_ball_l <= x) && (x <= x_ball_r) &&
                        (y_ball_t <= y) && (y <= y_ball_b);
    // Map current pixel location to rom addr/col
    assign rom_addr = y[2:0] - y_ball_t[2:0];   // 3-bit address
    assign rom_col = x[2:0] - x_ball_l[2:0];    // 3-bit column index
    assign rom_bit = rom_data[rom_col];         // 1-bit signal rom data by column
    // Pixel within round ball
    assign ball_on = sq_ball_on & rom_bit;      // Within square boundaries AND rom data bit == 1
    // New ball position
    assign x_ball_next = (refresh_tick) ? x_ball_reg + x_delta_reg : x_ball_reg;
    assign y_ball_next = (refresh_tick) ? y_ball_reg + y_delta_reg : y_ball_reg;
    
    // Change ball direction after collision
    always @ (*) begin
        x_delta_next = x_delta_reg;
        y_delta_next = y_delta_reg;
        if(y_ball_t < 1)                                            // Collide with top
            y_delta_next = BALL_VELOCITY_POS;
        else if(y_ball_b > Y_MAX)                                   // Collide with bottom
            y_delta_next = BALL_VELOCITY_NEG;
        else if(x_ball_l <= X_WALL_R)                               // Collide with wall
            x_delta_next = BALL_VELOCITY_POS;
        else if((X_PAD_L <= x_ball_r) && (x_ball_r <= X_PAD_R) &&
                (y_pad_t <= y_ball_b) && (y_ball_t <= y_pad_b))     // Collide with paddle
            x_delta_next = BALL_VELOCITY_NEG;
    end                    
    
    // RGB multiplexing circuit
    always @ (*)
        if(~video_on)
            rgb = 12'h000;      		// No value if not in display area
        else
            if(wall_on)
                rgb = wall_rgb;     // Wall color
            else if(pad_on)
                rgb = pad_rgb;      // Paddle color
            else if(ball_on)
                rgb = ball_rgb;     // Ball color
            else
                rgb = bg_rgb;       // Background
       
endmodule