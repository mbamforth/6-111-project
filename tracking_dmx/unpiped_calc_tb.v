`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   17:47:40 12/01/2014
// Design Name:   unpiped_calc
// Module Name:   C:/Users/admin/Documents/miren/tracking_dmx 11-26/tracking_dmx/unpiped_calc_tb.v
// Project Name:  tracking_DMX
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: unpiped_calc
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module unpiped_calc_tb;

	// Inputs
	reg reset;
	reg clk;
	reg [10:0] x_com;
	reg [9:0] y_com;
	reg height_cal_up;
	reg height_cal_down;
	
	// Intermediates
	wire [10:0] x_real_world;
	wire [9:0] y_real_world;
	wire [11:0] z_real_world;
	wire [10:0] x_light1;
	wire [9:0] y_light1;
	wire [8:0] pan_addr_light1;
	wire [8:0] tilt_addr_light1;

	// Outputs
	wire [7:0] pan;
	wire [8:0] pan_addr;
	wire [7:0] tilt;
	wire [8:0] tilt_addr;

	// Instantiate the Unit Under Test (UUT)
	unpiped_calc uut (
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
		.tilt_addr(tilt_addr), 
		.ready(ready)
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
	
	always #5 clk=!clk;

	initial begin
		// Initialize Inputs
		reset = 0;
		clk = 0;
		x_com = 100;
		y_com = 700;
		height_cal_up = 0;
		height_cal_down = 0;

		// Wait 100 ns for global reset to finish
		#601;
        
		// Add stimulus here
		
		// testing near 0
		x_com = 50;
		y_com = 380;
		#601;
		
		// testing near 255
		x_com = 80;
		y_com = 410;
		#601;
		
		// values equal to the light's position
		x_com = 200;
		y_com = 400;
		
		#601;
		// both values smaller than light
		x_com = 0;
		y_com = 0;
		
		#601;
		// both values bigger than light
		x_com = 1024;
		y_com = 768;
		
		#601;
		// x bigger, y smaller
		x_com = 800;
		y_com = 150;
		
		#601;
		// x smaller, y bigger
		x_com = 50;
		y_com = 600;
		

	end
      
endmodule

