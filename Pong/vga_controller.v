 `timescale 1ns / 1ps

module vga_controller(
	input clk,
	input reset,
	output video_on,	// ON while pixel counts for x and y are within display area
	output hsync,		// Horizontal sync
	output vsync, 		// Vertical sync
	output p_tick,		// Pixel tick, 25MHz pixels/second rate signal
	output [9:0] x,	// Position of pixel x, 0-799
	output [9:0] y		// Position of pixel y, 0-524
	);
	
	// Based on VGA standards for 640x480 resolution
	// Total horizontal width of screen is 800 pixels, partitioned into sections
	parameter HD = 640; 								// Horizontal display area width in pixels
	parameter HF = 16;								// Horizontal front porch width in pixels
	parameter HB = 48;								// Horizontal back porch width in pixels
	parameter HR = 96;								// Horizontal retrace width in pixels
	parameter HMAX = HD + HF + HB + HR - 1;	// Max value of horizontal counter = 799
	// Total vertical length of screen = 525 pixels, partitioned into sections
   parameter VD = 480;             				// Vertical display area length in pixels 
   parameter VF = 10;              				// Vertical front porch length in pixels  
   parameter VB = 33;              				// Vertical back porch length in pixels   
   parameter VR = 2;               				// Vertical retrace length in pixels  
   parameter VMAX = VD + VF + VB + VR - 1;	// Max value of vertical counter = 524   
	
	// Generate 25MHz from 50MHz
	reg r_25MHz = 0;
	always @ (posedge clk or negedge reset)
		if(~reset)
		  r_25MHz <= 0;
		else
		  r_25MHz <= ~r_25MHz;
	 
	// Counter registers for buffering to avoid glitches
   reg [9:0] h_count_reg, h_count_next;
   reg [9:0] v_count_reg, v_count_next;
    
   // Output buffers
   reg v_sync_reg, h_sync_reg;
   wire v_sync_next, h_sync_next;
	
	// Register control
   always @(posedge clk or negedge reset)
       if(~reset)
		 begin
           v_count_reg <= 0;
           h_count_reg <= 0;
           v_sync_reg  <= 1'b0;
           h_sync_reg  <= 1'b0;
       end
       else
		 begin
           v_count_reg <= v_count_next;
           h_count_reg <= h_count_next;
           v_sync_reg  <= v_sync_next;
           h_sync_reg  <= h_sync_next;
       end
	
	// Logic for horizontal counter
    always @(posedge r_25MHz or negedge reset)     // Pixel tick
       if(~reset)
           h_count_next = 0;
       else
           if(h_count_reg == HMAX)                 // End of horizontal scan
               h_count_next = 0;
           else
               h_count_next = h_count_reg + 1;         
  
   // Logic for vertical counter
   always @(posedge r_25MHz or negedge reset)
       if(~reset)
           v_count_next = 0;
       else
           if(h_count_reg == HMAX)                 // End of horizontal scan
               if((v_count_reg == VMAX))           // End of vertical scan
                   v_count_next = 0;
               else
                   v_count_next = v_count_reg + 1;
						 
	// h_sync_next asserted within the horizontal retrace area
   assign h_sync_next = ((h_count_reg >= (HD+HB)) && (h_count_reg <= (HD+HB+HR-1)));
    
   // v_sync_next asserted within the vertical retrace area
   assign v_sync_next = ((v_count_reg >= (VD+VB)) && (v_count_reg <= (VD+VB+VR-1)));
    
   // Video ON/OFF - only ON while pixel counts are within the display area
   assign video_on = ((h_count_reg >= 0) && (h_count_reg < HD) && (v_count_reg >= 0) && (v_count_reg < VD)); // 0-639 and 0-479 respectively
            
   // Outputs
   assign hsync  = h_sync_reg;
   assign vsync  = v_sync_reg;
   assign x      = h_count_reg;
   assign y      = v_count_reg;
   assign p_tick = r_25MHz;
	
endmodule