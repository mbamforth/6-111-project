

// tests the calibration block
module calibration_tb;

	// Inputs
	reg reset;
	reg clk;
	reg height_cal_up;
	reg height_cal_down;

	// Outputs
	wire [10:0] x_real_world;
	wire [9:0] y_real_world;
	wire [11:0] z_real_world;
	wire [10:0] x_light1;
	wire [9:0] y_light1;
	wire [8:0] pan_addr_light1;
	wire [8:0] tilt_addr_light1;

	// Instantiate the Unit Under Test (UUT)
	calibration uut (
		.reset(reset), 
		.clk(clk), 
		.height_cal_up(height_cal_up), 
		.height_cal_down(height_cal_down), 
		.x_real_world(x_real_world), 
		.y_real_world(y_real_world), 
		.z_real_world(z_real_world), 
		.x_light1(x_light1), 
		.y_light1(y_light1), 
		.pan_addr_light1(pan_addr_light1), 
		.tilt_addr_light1(tilt_addr_light1)
	);
	
	always #5 clk = !clk;
	always #5 height_cal_up = !height_cal_up;

	initial begin
		// Initialize Inputs
		reset = 0;
		clk = 0;
		height_cal_up = 0;
		height_cal_down = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		//height_cal_up = 1;
		#10;

	end
      
endmodule

