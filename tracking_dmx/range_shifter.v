// Miren Bamforth | A Motion-Tracking DMX512 Controller
// 6.111 Final Project | Fall 2014

// This module takes in 8 bit values in the range -pi to pi and
// 	shifts the range to be 0 to 255

// As of 11/25, this works, not including the coregen divider
module range_shifter(
	input reset,
	input clk,
	input [10:0] in, // 11 bit because PI is 11 bit
	output [7:0] out // 8 bit because pan and tilt are 8 bit
	);
	 
	// pi in 2Q10 form (see cordic data sheet)
	// pi is equal to 011.00100100
	// -pi is equal to 100.11011100
	localparam PI = 11'b011_0010_0100;
	// 127/73 is our scale, slightly off
	localparam NUMERATOR = 7'b111_1111; // 127
	localparam DENOMINATOR = 7'b100_1001; // 73
	
	// wires for our pipelining and divider
	reg [10:0] in_plus_pi;
	reg [7:0] concat;
	reg [15:0] in_times_numerator;
	wire div_ready;
	
	// coregen divider
	// delay N = width of inputs
	// delay is dividend + 2 = 18
	range_divider range_div(
		.dividend(in_times_numerator), // 16 bit
		.divisor(DENOMINATOR), // 7 bit
		.quot(out), // 8 bit
		.clk(clk),
		.rfd(div_ready));

	// this is pipelined to fit in smoothly with the motion calculator
	always @ (posedge clk) begin
		// clock 1: add PI to shift the range from -pi to pi to 0 to 2pi
		in_plus_pi <= in + PI;
		
		// clock 2: concatenate result
		// msb is no longer a signed bit
		concat <= in_plus_pi[10:3];
		
		// clock 3: multiply by 127
		in_times_numerator <= concat*NUMERATOR;
		
		// clock 4: divide by 73 (slightly wrong to save time/space) (1/18)
		// clock 5: (2/18)
		// clock 6: (3/18)
		// clock 7: (4/18)
		// clock 8: (5/18)
		// clock 9: (6/18)
		// clock 10: (7/18)
		// clock 11: (8/18)
		// clock 12: (9/18)
		// clock 13: (10/18)
		// clock 14: (11/18)
		// clock 15: (12/18)
		// clock 16: (13/18)
		// clock 17: (14/18)
		// clock 18: (15/18)
		// clock 19: (16/18)
		// clock 20: (17/18)
		// clock 21: (18/18), now the output is correct
		
		
	end

endmodule
