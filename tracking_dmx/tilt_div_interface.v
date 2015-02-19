// Miren Bamforth | A Motion-Tracking DMX512 Controller
// 6.111 Final Project | Fall 2014

// needs testing 11/25
module tilt_div_interface(
	input reset,
	input clk,
	input tilt_div_ready,
	input d_greater_than_h_del,
	input [11:0] tilt_quotient,
	input [7:0] tilt_remainder,
	output reg [9:0] arctan_tilt_in_x,
	output reg [9:0] arctan_tilt_in_y
   );

	always @(posedge clk) begin
		if(tilt_div_ready) begin
			// if d was greater than height, y = 1 and x = value from div
			// TODO: how do d an h map to x and y?
			// d is y, h is x
			if (d_greater_than_h_del) begin
				arctan_tilt_in_x <= {tilt_quotient[11], 
					tilt_quotient[0], tilt_remainder};
				arctan_tilt_in_y <= 10'b01_0000_0000;
			end
			// if deltay was greater than deltax, x = 1 and y = value from div			
			else begin
				arctan_tilt_in_x <= 10'b01_0000_0000;
				arctan_tilt_in_y <= {tilt_quotient[11], 
					tilt_quotient[0], tilt_remainder};
			end
		end
	end
endmodule
