`timescale 1ns / 1ps

module pixel_counter(
	clk, 					// Clock signal
	sync_count,			// Value of sync time
	pixel_addr,			// Address of pixel
	enable
    );
	
	parameter ADDR_SIZE = 10;				// Size of the largest address
	parameter BACK_PORCH_END = 5;			// Start point of displaying
	parameter DISPLAY_END = 10;			// End point of displaying
	
	input clk;
	input enable;
	input [9:0] sync_count;
	output reg [ADDR_SIZE - 1: 0] pixel_addr = 0; // Address of the pixel
	
	always @ (posedge clk) begin
	if(enable)
	begin
			if ((sync_count > BACK_PORCH_END) && (sync_count <= DISPLAY_END - 1))
				pixel_addr <= pixel_addr + 1;	// Increment address
			else
				pixel_addr <= 0;					// Else reset address to 0
		end
	end
	
endmodule


				
