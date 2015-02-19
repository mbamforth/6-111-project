// Miren Bamforth | A Motion-Tracking DMX512 Controller
// 6.111 Final Project | Fall 2014

// needs testing 11/25
module pan_div_interface(
	input reset,
	input clk,
	input pan_div_ready,
	input x_greater_than_y_del,
	input [9:0] pan_quot,
	input [7:0] pan_remd,
	output reg [9:0] arctan_pan_in_x,
	output reg [9:0] arctan_pan_in_y
	);

	always @ (posedge clk) begin
		// arctan inputs are in 1Q10 form, see cordic data sheet pg. 21
		if(pan_div_ready) begin
			// if deltax was greater than deltay, x = 1 and y = value from div
			if (x_greater_than_y_del) begin
				arctan_pan_in_x <= 10'b01_0000_0000;
				arctan_pan_in_y <= {pan_quot[9], pan_quot[0], pan_remd};
			end
			// if deltay was greater than deltax, y = 1 and x = value from div			
			
			else begin
				arctan_pan_in_x <= {pan_quot[9], pan_quot[0], pan_remd};
				arctan_pan_in_y <= 10'b01_0000_0000;
			end
		end
	end

endmodule
