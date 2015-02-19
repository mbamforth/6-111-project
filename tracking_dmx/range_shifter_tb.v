`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   21:46:59 11/25/2014
// Design Name:   range_shifter
// Module Name:   /afs/athena.mit.edu/user/m/i/miren/Desktop/6.111/final project/tracking_dmx/range_shifter_tb.v
// Project Name:  tracking_DMX
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: range_shifter
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module range_shifter_tb;

	// Inputs
	reg reset;
	reg clk;
	reg [10:0] in;

	// Outputs
	wire [7:0] out;

	// Instantiate the Unit Under Test (UUT)
	range_shifter uut (
		.reset(reset), 
		.clk(clk), 
		.in(in), 
		.out(out)
	);

	always #5 clk = !clk;

	initial begin
		// Initialize Inputs
		reset = 0;
		clk = 0;
		in = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		in = 11'b00011010110;
		#100;
		// -pi
		in = 11'b10011011100;
		#100;
		// pi
		in = 11'b011_0010_0100;

	end
      
endmodule

