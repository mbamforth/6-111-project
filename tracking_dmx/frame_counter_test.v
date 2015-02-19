`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   19:36:09 11/11/2014
// Design Name:   frame_counter
// Module Name:   /afs/athena.mit.edu/user/m/i/miren/Desktop/6.111/final project/frame_counter_test.v
// Project Name:  tracking_DMX
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: frame_counter
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module frame_counter_test;

	// Inputs
	reg reset;
	reg vsync_in;

	// Outputs
	wire frame_enable;

	// Instantiate the Unit Under Test (UUT)
	frame_counter uut (
		.reset(reset), 
		.vsync_in(vsync_in), 
		.frame_enable(frame_enable)
	);
	
	always #5 vsync_in = !vsync_in;

	initial begin
		// Initialize Inputs
		reset = 0;
		vsync_in = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		
	end
      
endmodule

