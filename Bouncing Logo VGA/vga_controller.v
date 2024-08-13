`timescale 1ns / 1ps

module vga_controller(
    input clk,							// 50MHz clock
	 output refresh,					// Gives trigger when display is refreshed
    input [11:0] rgb_in,			// Color to be displayed
    output reg [11:0] rgb_out,	// Register that produces rgb_in when in display area
    output [9:0] x,					// Address of the horizontal pixel
    output [8:0] y,	   			// Address of vertical pixel
    output reg hsync,				// Horizontal sync signal, active low
    output reg vsync,				// Vertical sync signal, active low
	 input clk_25MHz
    );
	
	wire [9:0] vsync_counter;		// Vertical sync time counter
	wire [9:0] hsync_counter;		// Horizontal sync time counter
	wire hmax_reached;				// Trigger to detect end of line

	initial begin		// Initial values 
		hsync = 0;
		vsync = 0;
		rgb_out = 0;
	end
	
	// Time for horizontal sections
	parameter HR = 10'd96;		// Horizontal retrace
	parameter HB = 10'd144;		// Back porch
	parameter HD = 10'd784;		// Display area
	parameter HF = 10'd800;		// Front porch
	
	// Time for vertical sections
	parameter VR = 10'd2;		// Vertical retrace
	parameter VB = 10'd31;		// Back porch
	parameter VD = 10'd511;		// Display area
	parameter VF = 10'd521;		// Front porch
	
	
	counter # (
				.MAX_VALUE(HF - 1),						// Max horizontal value - 1 
				.SIZE(10)									// Size of max value in bits
			)
	h_counter(
				.clk(clk),									// Clock signal
				.enable(clk_25MHz),						// Divided clock signal, 25MHz
				.trigger_out(hmax_reached),			// Triggers when line ends
				.time_count(hsync_counter)				// Horizontal sync
			);		
			
	counter # (
				.MAX_VALUE(VF - 1),						// Max vertical value - 1
				.SIZE(10)									// Size of max balue in bits
			)			
	v_counter(
				.clk(clk),									// Clock signal
				.enable(hmax_reached),					// Set high at the end of horizontal lines
				.trigger_out(refresh),					// Produces a signal to refresh the screen
				.time_count(vsync_counter)				// Vertical sync
			);	
					
	// Set hsync low
	always @ (posedge clk)
	begin
		if((hsync_counter < HR - 1) || (hsync_counter == HF - 1)) // If in horizontal retrace or at the end of horizontal front porch
			hsync <= 1'b0;
		else 
			hsync <= 1'b1;
	end
	
	// Set vsync low
	always @ (posedge clk)
	begin
		if(hmax_reached) // At the end of a horizontal line
		begin
			if((vsync_counter < VR - 1) || (vsync_counter == VF - 1)) // If in vertical sync pulse or at the end of vertical front porch
				vsync <= 1'b0;
			else 
				vsync <= 1'b1;
		end
	end
	
	// Set rgb output value
	always @ (posedge clk)
	begin
		if(clk_25MHz)
		begin
			if((hsync_counter > HB - 2)
				&& (hsync_counter <= HD - 2)
				&& (vsync_counter > VB - 1)
				&& (vsync_counter <= VD - 1))
				rgb_out <= rgb_in;
			else
				rgb_out <= 0;
		end
	end

	// Gets horizontal address of the pixel
	pixel_counter # (
					.ADDR_SIZE(10),						// Size of the largest address
					.BACK_PORCH_END(HB - 1),			// Lower value of sync count
					.DISPLAY_END(HD - 1)					// Upper value of sync count
					)
				h_pixel_counter(
					.clk(clk),								// Clock signal
					.sync_count(hsync_counter),		// Gets sync time
					.enable(clk_25MHz),					// 25MHz from divided clock signal
					.pixel_addr(x)							// Horizontal address
					);
	
	// Gets vertical address of the pixel
	pixel_counter # (
					.ADDR_SIZE(9),
					.BACK_PORCH_END(VB - 1),
					.DISPLAY_END(VD - 1)
					)
				
				v_pixel_counter(
					.clk(clk),
					.sync_count(vsync_counter),
					.enable(hmax_reached),				// Checks if horizontal line ended
					.pixel_addr(y)							// Vertical address
					);
endmodule
