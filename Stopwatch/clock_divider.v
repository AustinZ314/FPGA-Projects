module clock_divider(
	input clock,
	input reset,
	input start_stop,
	output reg [3:0] reg_0, reg_1, reg_2, reg_3, reg_4, reg_5 // Registers to hold individal digits of the time
	);
	
	reg [19:0] ticker; // 19-bit register needed to count to 500000 clock cycles (50MHz for 0.01sec)
	wire increment;
	
	always @ (posedge clock or negedge reset)
	begin
		if(!reset)
			ticker <= 0;
		else if(ticker == 500000) // Reset when ticker reaches max value
			ticker <= 0;
		else if(start_stop) // Start when the input is set high, pause when set low
			ticker <= ticker + 1'd1;
	end
	
	assign increment = ((ticker == 500000) ? 1'b1 : 1'b0); // Increment at every 500000 ticks
	
	always @ (posedge clock or negedge reset)
	begin
		if(!reset)
		begin
			reg_0 <= 0;
			reg_1 <= 0;
			reg_2 <= 0;
			reg_3 <= 0;
			reg_4 <= 0;
			reg_5 <= 0;
		end
		else if(increment)
		begin
			if(reg_0 == 9) // x.x9 seconds
			begin // 1
				reg_0 <= 0;
				
				if(reg_1 == 9) // x.99 seconds
				begin // 2
					reg_1 <= 0;
					
					if(reg_2 == 9) // 9.99 seconds
					begin // 3
						reg_2 <= 0;
						
						if(reg_3 == 5) // 59.99 seconds
						begin // 4
							reg_3 <= 0;
							
							if(reg_4 == 9) // 9 minutes 59.99 seconds
							begin // 5
								reg_4 <= 0;
								
								if(reg_5 == 5) // 59 minutes 59.99 seconds
									reg_5 <= 0;
								else
									reg_5 <= reg_5 + 1'd1;
							end
							else // 5
								reg_4 <= reg_4 + 1'd1;
						end
						else // 4
							reg_3 <= reg_3 + 1'd1;
					end
					else // 3
						reg_2 <= reg_2 + 1'd1;
				end
				else // 2
					reg_1 <= reg_1 + 1'd1;
			end
			else // 1
				reg_0 <= reg_0 + 1'd1;
		end
	end

endmodule
