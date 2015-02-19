////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   22:02:53 11/17/2014
// Design Name:   rgb2hsv
// Module Name:   /afs/athena.mit.edu/user/m/i/miren/Desktop/6.111/final project/rgb2hsv_tb.v
// Project Name:  tracking_DMX
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: rgb2hsv
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module rgb2hsv_tb;

	// Inputs
	reg clock;
	reg reset;
	reg [7:0] r;
	reg [7:0] g;
	reg [7:0] b;

	// Outputs
	wire [7:0] h;
	wire [7:0] s;
	wire [7:0] v;

	// Instantiate the Unit Under Test (UUT)
	rgb2hsv uut (
		.clock(clock), 
		.reset(reset), 
		.r(r), 
		.g(g), 
		.b(b), 
		.h(h), 
		.s(s), 
		.v(v)
	);

	always #5 clock = !clock;

	initial begin
		// Initialize Inputs
		clock = 0;
		reset = 0;
		#10 reset = 1;
		#15 reset = 0;
		
		r = 8'd32;
		g = 8'd64;
		b = 8'd96;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

	end
      
endmodule

