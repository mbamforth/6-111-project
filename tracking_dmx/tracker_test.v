`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   22:17:39 11/11/2014
// Design Name:   tracker
// Module Name:   /afs/athena.mit.edu/user/m/i/miren/Desktop/6.111/final project/tracker_test.v
// Project Name:  tracking_DMX
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: tracker
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module tracker_test;

	// Inputs
	reg clk;
	reg reset;
	reg [10:0] hcount;
	reg [9:0] vcount;
	reg [23:0] hsv;
	reg [7:0] low;
	reg [7:0] high;

	// Outputs
	wire [10:0] x_com;
	wire [9:0] y_com;
	wire data_ready;

	// Instantiate the Unit Under Test (UUT)
	tracker uut (
		.clk(clk), 
		.reset(reset), 
		.hcount(hcount), 
		.vcount(vcount), 
		.hsv(hsv), 
		.low(low), 
		.high(high), 
		.x_com(x_com), 
		.y_com(y_com), 
		.data_ready(data_ready)
	);
	
	always #5 clk = !clk;

	initial begin
		// Initialize Inputs
		clk = 0;
		reset = 0;
		hcount = 1100;
		vcount = 0;
		hsv = 24'b1111_1110_1111_1110_1111_1110;
		low = 8'b0000_1111;
		high = 8'b1111_1111;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		hcount = 0;
		#10;
		hcount = 1;
		#10;
		hcount = 2;
		#10;
		hcount = 10;
		#10;
		hcount = 600;
		vcount = 500;
		#10;
		hcount = 200;
		#10;
		hcount = 11'd1050;
		vcount = 10'd800;

	end
      
endmodule

