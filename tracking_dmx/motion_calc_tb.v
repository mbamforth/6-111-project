
module motion_calc_tb;

	// Inputs
	reg reset;
	reg clk;
	reg x_com;
	reg y_com;
	
	// Intermediates
	wire [10:0] x_real_world;
	wire [9:0] y_real_world;
	wire [11:0] z_real_world;
	wire x_light1;
	wire y_light1;
	wire [8:0] pan_addr_light1;
	wire [8:0] tilt_addr_light1;

	// Outputs
	wire [7:0] pan;
	wire [8:0] pan_addr;
	wire [7:0] tilt;
	wire [8:0] tilt_addr;

	// Instantiate the Unit Under Test (UUT)
	motion_calc uut (
		.reset(reset), 
		.clk(clk), 
		.x_com(x_com), 
		.y_com(y_com), 
		.x_real(x_real_world), 
		.y_real(y_real_world), 
		.z_real(z_real_world), 
		.x_light1(x_light1), 
		.y_light1(y_light1), 
		.pan_addr_light1(pan_addr_light1), 
		.tilt_addr_light1(tilt_addr_light1), 
		.pan(pan), 
		.pan_addr(pan_addr), 
		.tilt(tilt), 
		.tilt_addr(tilt_addr)
	);
	
	// Instantiate the Unit Under Test (UUT)
	calibration uut1 (
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

	initial begin
		// Initialize Inputs
		reset = 0;
		clk = 0;
		x_com = 0;
		y_com = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		x_com = 11'd100;
		y_com = 10'd700;

	end
      
endmodule

