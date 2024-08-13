`timescale 1ns / 1ps

module counter(
	clk, 								// Clock signal
	enable,							// Trigger input
	trigger_out,					// Trigger output
	time_count						// Counts sync time
    );
	
	parameter MAX_VALUE = 799;	// The max horizontal or vertical value of the screen
	parameter SIZE = 10;			// How many bits are required for max value
	
	input clk;
	input enable;
	output reg trigger_out = 0;
	output reg [SIZE - 1: 0] time_count = MAX_VALUE;
	
	always @ (posedge clk) begin
		if(enable)
		begin
			if(time_count == MAX_VALUE)				// Reset if max value reached
				time_count <= 0;
			else
				time_count <= time_count + 1;
		end
	end

	always @ (posedge clk)
	begin
		if (enable && (time_count == MAX_VALUE - 1)) 	// If counting enabled & max value reached
			trigger_out <= 1;										// Then trigger out a pulse for one clock cycle
		else													
			trigger_out <= 0;										// Else don't trigger pulse
	end
endmodule
