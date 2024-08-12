module multiplexer (
	input clock,
	input wire [3:0] reg_0, reg_1, reg_2, reg_3, reg_4, reg_5, 
	output reg [6:0] seven_seg_0, seven_seg_1, seven_seg_2, seven_seg_3, seven_seg_4, seven_seg_5
	);
	
	wire a, b, c, d, e, f, g; // Each letter corresponds to 1 segment in the 7-segment display
	reg [2:0] count; // 3 bit multiplexer counter
	
	always @ (posedge clock)
	begin
		if(count == 3'b101)
			count <= 1'd0;
		else
			count <= count + 1'd1;
	end
	
	reg [3:0] sseg; // 7 bit register to hold output data
	
	always @ (*)
	begin
		case(count) // Only use the 3 MSBs of the counter to accommodate 6 displays
			3'b000: // When the MSBs are 000, enable first (rightmost) display
			begin
				sseg = reg_0;
				seven_seg_0 = {g, f, e, d, c, b, a};
			end
			
			3'b001: // When the MSBs are 001, enable second display
			begin
				sseg = reg_1;
				seven_seg_1 = {g, f, e, d, c, b, a};
			end
			
			3'b010: // When the MSBs are 010, enable the third display
			begin
				sseg = reg_2;
				seven_seg_2 = {g, f, e, d, c, b, a};
			end
			
			3'b011: // When the MSBs are 011, enable the fourth display
			begin
				sseg = reg_3;
				seven_seg_3 = {g, f, e, d, c, b, a};
			end
			
			3'b100: // When the MSBs are 100, enable the fifth display
			begin
				sseg = reg_4;
				seven_seg_4 = {g, f, e, d, c, b, a};
			end
			
			3'b101: //When the MSBs are 101, enable the sixth (leftmost) display
			begin
				sseg = reg_5;
				seven_seg_5 = {g, f, e, d, c, b, a};
			end
			
			default: sseg = 10;
		endcase
	end
	
	reg [6:0] sseg_temp; // 7 bit register to hold binary value of each input
	
	always @ (*)
	begin
		case(sseg)
			4'd0: sseg_temp = 7'b1000000; // 0
			4'd1: sseg_temp = 7'b1111001; // 1
			4'd2: sseg_temp = 7'b0100100; // 2
			4'd3: sseg_temp = 7'b0110000; // 3
			4'd4: sseg_temp = 7'b0011001; // 4
			4'd5: sseg_temp = 7'b0010010; // 5
			4'd6: sseg_temp = 7'b0000010; // 6
			4'd7: sseg_temp = 7'b1111000; // 7
			4'd8: sseg_temp = 7'b0000000; // 8
			4'd9: sseg_temp = 7'b0010000; // 9
			default: sseg_temp = 7'b1000000; // Default to 0
		endcase
	end
	
	assign {g, f, e, d, c, b, a} = sseg_temp;
	
endmodule