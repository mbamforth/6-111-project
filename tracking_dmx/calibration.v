// Miren Bamforth | A Motion-Tracking DMX512 Controller
// 6.111 Final Project | Fall 2014

// this module is initially hard-coded calibration
// optionally, more complicated calibration will be implemented
module calibration(
	input reset,
	input clk,
	input height_cal_up,
	input height_cal_down,
	output [10:0] x_real_world,
	output [9:0] y_real_world,
	output reg [11:0] z_real_world,
	output [10:0] x_light1,
	output [9:0] y_light1,
	output [8:0] pan_addr_light1,
	output [8:0] tilt_addr_light1
	);

	localparam X_PIXELS = 11'd1024;
	localparam Y_PIXELS = 10'd768;

	// assign x and y to their real world values, in pixels as units
	assign x_real_world = X_PIXELS;
	assign y_real_world = Y_PIXELS;
	
	// assign x_light and y_light to the position of the light
	// assign pan and tilt addresses to the light
	// TODO: replace the random values here
	assign x_light1 = 11'd380;
	assign y_light1 = 10'd350;
	assign pan_addr_light1 = 9'd1;
	assign tilt_addr_light1 = 9'd2;

	// assign z its real world value as a ratio; we store the value of
	// 	z by storing a ratio which is equal to z/x and between 1 and 2
	// ratio multiplication trick:
	//		1) express the ratio as n/512
	// 	1) multiply the number by the n
	// 	2) shift the result right 9 times, aka divide by 512
	// TODO: the ratio is (optionally) changed with the calibration inputs
	// ratio_n is 10 bits wide because its greatest possible value is 2^10
	reg [9:0] ratio_n;
	initial ratio_n = 10'd400; // was 300
	localparam DIV_SHIFT_512 = 5'd9;
	reg [20:0] z_temp;
	
	always @ * begin
		z_temp = x_real_world*ratio_n;
		z_real_world = z_temp >> DIV_SHIFT_512;
	end
	
	// a counter to slow down the button input
	reg [17:0] counter;
	initial counter = 18'd0;
	wire bool, bool1;
	assign bool = (counter == 18'd0);
	always @ (posedge clk) begin
		if (bool) begin
			// do nothing if both button are pushed
			// increase the height if this is true
			if (height_cal_up && !height_cal_down && ratio_n < 10'd1023) begin
				ratio_n <= ratio_n + 1;
			end
			
			// decrease the height if this is true
			if (height_cal_down && !height_cal_up && ratio_n > 0) begin
				ratio_n <= ratio_n - 1;
			end
		end
		counter <= counter + 1;
	end

endmodule
