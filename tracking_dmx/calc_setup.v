// Miren Bamforth | A Motion-Tracking DMX512 Controller
// 6.111 Final Project | Fall 2014

// this module does the first two clock cycles' work for the calculator
// tested and working 11/25
module calc_setup(
	input clk,
	input reset,
	input [10:0] x_com,
	input [10:0] x_light1,
	input [9:0] y_com,
	input [9:0] y_light1,
	output reg [21:0] x_dif_sq,
	output reg [19:0] y_dif_sq,
	output reg x_greater_than_y,
	output reg [10:0] pan_dividend,
	output reg [10:0] pan_divisor
	);
	
	localparam NO = 1'b0;
	localparam YES = 1'b1;
	
	// needs an extra bit for signed number
	reg [11:0] x_dif;
	reg [10:0] y_dif;
	// magnitude is positive, so no extra bit
	reg [10:0] x_mag;
	reg [9:0] y_mag;
	 
	always @ (posedge clk) begin
		// clock 1: latch x_com - x_light and y_com - y_light and magnitudes
		x_dif <= x_com - x_light1;
		if (x_com > x_light1) x_mag <= x_com - x_light1;
		else x_mag <= x_light1 - x_com;
		
		y_dif <= y_com - y_light1;
		if (y_com > y_light1) y_mag <= y_com - y_light1;
		else y_mag <= y_light1 - y_com;
		
////////////////////////////////////////////////////////////////////////

		// clock 2: tilt: calculate x_dif^2 and y_dif^2
		// pan: set up normalizing divider
		// TODO: does the multiplication take only one clock cycle?
		x_dif_sq <= x_mag*x_mag;
		y_dif_sq <= y_mag*y_mag;
		
		// if deltax is greater than deltay, normalize by doing deltay/deltax
		if(x_mag > y_mag) begin
			x_greater_than_y <= YES;
			// sign extend y
			pan_dividend <= {y_dif[10], y_dif};
			pan_divisor <= x_dif;
		end
		// if deltay is greater than deltax, normalize by doing deltax/deltay		
		else begin
			x_greater_than_y <= NO;
			pan_dividend <= x_dif;
			// sign extend y
			pan_divisor <= {y_dif[10], y_dif};
		end

////////////////////////////////////////////////////////////////////////	
		
		
	 end


endmodule
