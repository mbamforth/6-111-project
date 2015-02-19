`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   22:59:34 11/25/2014
// Design Name:   calc_setup
// Module Name:   /afs/athena.mit.edu/user/m/i/miren/Desktop/6.111/final project/tracking_dmx/calc_setup_tb.v
// Project Name:  tracking_DMX
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: calc_setup
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module calc_setup_tb;

	// Inputs
	reg clk;
	reg reset;
	reg [10:0] x_com;
	reg [10:0] x_light1;
	reg [9:0] y_com;
	reg [9:0] y_light1;

	// Outputs
	wire [21:0] x_dif_sq;
	wire [19:0] y_dif_sq;
	wire x_greater_than_y;
	wire [10:0] pan_dividend;
	wire [10:0] pan_divisor;

	// Instantiate the Unit Under Test (UUT)
	calc_setup uut (
		.clk(clk), 
		.reset(reset), 
		.x_com(x_com), 
		.x_light1(x_light1), 
		.y_com(y_com), 
		.y_light1(y_light1), 
		.x_dif_sq(x_dif_sq), 
		.y_dif_sq(y_dif_sq), 
		.x_greater_than_y(x_greater_than_y), 
		.pan_dividend(pan_dividend), 
		.pan_divisor(pan_divisor)
	);

	always #5 clk=!clk;

	initial begin
		// Initialize Inputs
		clk = 0;
		reset = 0;
		x_com = 400;
		x_light1 = 200;
		y_com = 500;
		y_light1 = 600;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

	end
      
endmodule

