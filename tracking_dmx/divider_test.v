`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   23:13:45 11/11/2014
// Design Name:   divider
// Module Name:   /afs/athena.mit.edu/user/m/i/miren/Desktop/6.111/final project/divider_test.v
// Project Name:  tracking_DMX
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: divider
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module divider_test;

	// Inputs
	reg clk;
	reg sign;
	reg start;
	reg [7:0] dividend;
	reg [7:0] divider;

	// Outputs
	wire [7:0] quotient;
	wire [7:0] fractional;
	wire ready;

	// Instantiate the Unit Under Test (UUT)
	divider uut (
		.clk(clk), 
		.sign(sign), 
		.start(start), 
		.dividend(dividend), 
		.divider(divider), 
		.quotient(quotient), 
		.fractional(fractional), 
		.ready(ready)
	);

	always #5 clk = !clk;

	initial begin
		// Initialize Inputs
		clk = 0;
		sign = 0;
		start = 0;
		dividend = 8'd12;
		divider = 8'd3;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		start = 1;
		#10
		start = 0;

	end
      
endmodule

