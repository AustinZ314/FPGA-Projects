`timescale 1ns / 1ps

module top(
  input clk,							  // 50MHz clock signal
  output [11:0] rgb_out,		// Bit pattern for color that goes to VGA port
  output hsync,						  // Horizontal sync signal that goes to VGA port
  output vsync,						  // Vertical sync signal that goes to VGA port
	input zoom_in,
	input zoom_out,
	input letterbox,
	input invert,
	input rotate
	);
	
	// Image Parameters
	parameter width = 7'd100;					    // Width of image in pixels
	parameter height = 7'd100;					  // Height of image in pixels
	parameter total_pixels = 14'd10005;		// Total amount of pixels in image = width * height
	
	reg clk_25MHz = 0;							      // clk_25MHz to 25MHz
	
	always @ (posedge clk)
	begin     
		clk_25MHz <= ~clk_25MHz;				    // Slow down the counter to 25MHz
	end
	
	reg [11:0] rgb_in;
	reg [11:0] rgb [0:total_pixels - 1];
	reg [14:0] state;
	wire trigger_refresh;						// Trigger gives a pulse when display is refreshed
	wire [9:0] x;									  // Horizontal pixel value
	wire [8:0] y;									  // Vertical pixel value		
	
	// VGA Interface gets values of x & y and generates rgb_out
	// Also gets a trigger when the screen is refreshed
	vga_controller vga(
				.clk(clk),
			   .rgb_in (rgb_in),
				.rgb_out(rgb_out),
				.hsync(hsync),
				.vsync(vsync),
				.refresh(trigger_refresh),
				.x(x),
				.y(y),
				.clk_25MHz(clk_25MHz)
				);
	
	initial
		$readmemh ("Gimp.list", rgb);

	reg signed [10:0] X = 10'd280;
	reg signed [9:0] Y = 9'd200;
	
	reg signed [4:0] X_delta = -3;
	reg signed [4:0] Y_delta = -3;
	reg [3:0] IMAGE_VELOCITY = 3;
	reg [7:0] size = 0;
	reg [5:0] border = 0;
	reg [1:0] orientation = 0;
	
	always @ (posedge clk)
	begin
		if(zoom_in)
			size <= width * 2;
		else if(zoom_out)
			size <= width / 2;
		else
			size <= width;
		
		if(letterbox)				// Add top and bottom borders with a width of 60 pixels
			border <= 60;
		else
			border <= 0;
	end
	
	// Change image position and detect wall collision
	always @ (posedge clk)
	begin 
		if(trigger_refresh)
		begin
			if(X + size + 5 >= 639)  	// Right
				X_delta <= -IMAGE_VELOCITY;	 		
			if(X <= 5)				 		// Left
				X_delta <= IMAGE_VELOCITY;
			if(Y + size + border + 5 >= 479)		// Bottom
				Y_delta <= -IMAGE_VELOCITY;
			if(Y - border <= 5)						      // Top
				Y_delta <= IMAGE_VELOCITY;
		
			X <= X + X_delta;				// Get a new position every frame
			Y <= Y + Y_delta;
		end
	end
	
	// On button press, rotate image 90 degrees clockwise
	always @ (negedge rotate)
		orientation = orientation + 1;
	
	// Assign rgb input and image size
	always @ (posedge clk)
	begin
		if(y <= border || y >= 479 - border)
			state <= 10004;
		else if(~zoom_out && ~zoom_in && x >= X && x < X + width && y >= Y && y < Y + height) // Display image at normal size
		begin
			case(orientation)
				0: state <= (x - X) * width + (y - Y);
				1: state <= (y - Y + 1) * width + (-x + X);
				2: state <= (x - X + 1) * width + (-y + Y);
				3: state <= (y - Y) * width + (x - X);
			endcase
		end
		else if(zoom_out && ~zoom_in && x >= X && x < X + width / 2 && y >= Y && y < Y + height / 2) // Decrease size of image
		begin
			case(orientation)
				0: state <= (x - X) * 2 * width + (y - Y) * 2;
				1: state <= (y - Y + 1) * 2 * width + (-x + X) * 2;
				2: state <= (x - X + 1) * 2 * width + (-y + Y) * 2;
				3: state <= (y - Y) * 2 * width + (x - X) * 2;
			endcase
		end
		else if(zoom_in && x >= X && x < X + width * 2 && y >= Y && y < Y + height * 2) // Increase size of image
		begin
			case(orientation)
				0: state <= (x - X) / 2 * width + (y - Y) / 2;
				1: state <= (y - Y + 2) / 2 * width + (-x + X) / 2;
				2: state <= (x - X + 2) / 2 * width + (-y + Y) / 2;
				3: state <= (y - Y) / 2 * width + (x - X) / 2;
			endcase
		end
		else
			state <= 9999;
		
		// Invert image colors
		if(invert)
			rgb_in = 12'hFFF - rgb[{state}];
		else
			rgb_in = rgb[{state}];
	end
	
endmodule
