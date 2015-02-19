// Miren Bamforth | A Motion-Tracking DMX512 Controller
// 6.111 Final Project | Fall 2014

// needs testing 11/25
module sqrt_interface(
	input clk,
	input reset,
	input sqrt_ready,
	input [11:0] sqrt_out,
	input [11:0] height,
	output reg [11:0] tilt_dividend,
	output reg [11:0] tilt_divisor,
	output reg d_greater_than_h
	);
	
	localparam NO = 1'b0;
	localparam YES = 1'b1;

	always @ (posedge clk) begin
		if (sqrt_ready) begin
			// if sqrt_out is bigger than height, normalize by height/sqrt
			if (sqrt_out > height) begin
				tilt_dividend <= height;
				tilt_divisor <= sqrt_out;
				d_greater_than_h <= YES;
			end
			// if height is bigger than sqrt_out, normalize by sqrt/height
			else begin
				tilt_dividend <= sqrt_out;
				tilt_divisor <= height;
				d_greater_than_h <= NO;
			end
		end
	end
endmodule
