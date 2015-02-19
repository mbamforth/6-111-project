// Miren Bamforth | A Motion-Tracking DMX512 Controller
// 6.111 Final Project | Fall 2014
// This code was modified from code on the 6.111 website.

// This module finds the center of mass of all pixels of a certain 
// color as a way to do simple motion tracking.
module tracker(
    input clk,
    input reset,
    input [10:0] hcount,
    input [9:0] vcount,
    input [23:0] hsv,
	 input [7:0] low,
	 input [7:0] high,
    output reg [10:0] x_com,
    output reg [9:0] y_com,
	 output reg data_ready
    );
	 
	// TODO: is this considering the error on the left of the screen?
	// TODO: consider making hsum, vsum, and color count bigger or smaller
	
	// we only pay attention to the visible pixels
	// we ignore anything with HSV = 24'd0 because earlier we
	// 	set all the pixels other than the ones from the video 
	// 	input to 24'd0
	// we have a lower bound so that we don't double count pixels because
	// 	of the weird error on the left side of the screen
	// the upper bounds were determined by finding the right and bottom edges
	// 	of the video on the screen since it doesn't take up the whole screen
	localparam HCOUNT_MIN = 11'd33;
	localparam HCOUNT_MAX = 11'd755;
	localparam VCOUNT_MIN = 10'd70;
	localparam VCOUNT_MAX = 10'd768;
	
	// we assume that at most ~10% of pixels can be part of the tracked obj
	// hence the bit width
	reg [20:0] color_count;
	// adds up all of the locations of pixels in the color range
	// since we are assuming that at most ~10% of pixels are part 
	// of the object, we can use only 22 bits for the sums
	reg [25:0] h_sum;
	reg [25:0] v_sum;
	
	// saves the previous h_sum, v_sum, and color_count from previous three 
	reg [25:0] h_sum_prev, h_sum_prev1, h_sum_prev2;
	reg [25:0] v_sum_prev, v_sum_prev1, v_sum_prev2;
	initial h_sum_prev = 26'd0;
	initial h_sum_prev1 = 26'd0;
	initial h_sum_prev2 = 26'd0;
	initial v_sum_prev = 26'd0;
	initial v_sum_prev1 = 26'd0;
	initial v_sum_prev2 = 26'd0;
	reg [20:0] color_count_prev, color_count_prev1, color_count_prev2;
	initial color_count_prev = 21'd0;
	initial color_count_prev1 = 21'd0;
	initial color_count_prev2 = 21'd0;
	
	// state for telling whether we should sum or not
	localparam IDLE = 2'b00;
	localparam COUNTING = 2'b01;
	localparam DIVIDING_START = 2'b10;
	localparam DIVIDING_WAIT = 2'b11;
	reg [1:0] state = IDLE;
	
	// remembers which dividers have returned
	reg [1:0] div_ready;
	
	// some wires to make the code cleaner when dealing with hsv
	wire [7:0] hue, sat, val;
	assign hue = hsv[23:16];
	assign sat = hsv[15:8];
	assign val = hsv[7:0];
	
	// minimum values for the saturation and value
	localparam SAT_MIN = 8'h88;
	localparam VAL_MIN = 8'h88;
	
	// bool tells us whether a pixel is within our three hsv ranges
	// the range for hue comes from outside of the module (maybe switches)
	wire bool;
	assign bool = (hue>=low && hue<=high && 
			sat > SAT_MIN && val > VAL_MIN);
	
	// dividers and necessary wires
	// the dividers are 29 bits wide
	// the delays are acceptable given the speed of the clock vs. the display
	wire [25:0] h_quotient, v_quotient, h_remainder, v_remainder;
	reg start; 
	wire h_ready, v_ready;
	
	// horizontal divider
	divider #(26) h_div(
		.clk(clk),
		.sign(1'b0),
		.start(start),
		.dividend(h_sum),
		.divider({5'd0, color_count}),
		.quotient(h_quotient),
		.fractional(h_remainder),
		.ready(h_ready)
		);
		
	// vertical divider
	divider #(26) v_div(
		.clk(clk),
		.sign(1'b0),
		.start(start),
		.dividend(v_sum),
		.divider({5'd0, color_count}),
		.quotient(v_quotient),
		.fractional(v_remainder),
		.ready(v_ready)
		);
	
	// always block for counting pixels
	always@(posedge clk) begin
		if (reset) begin
			// reset everything
			state <= IDLE;
			data_ready <= 1'b0;
		end
		else begin
			case(state)
				IDLE: begin
					// detect if we should start counting
					if(hcount==0 && vcount==0) begin
						state <= COUNTING;
						h_sum <= 26'd0;
						v_sum <= 26'd0;
						color_count <= bool ? 21'd1: 21'd0;
						start <= 1'b0;
						div_ready <= 2'b00;
					end
					
					data_ready <= 1'b0;
				end
				COUNTING: begin
					// if we are in the visible range of pixels
					if(hsv != 24'd0 && hcount < HCOUNT_MAX && 
							hcount > HCOUNT_MIN &&
							vcount > VCOUNT_MIN &&
							vcount < VCOUNT_MAX) begin
						// if the color is in range, increment everything
						if (bool) begin
							h_sum <= h_sum + hcount;
							v_sum <= v_sum + vcount;
							color_count <= color_count + 1;
						end
					end
					
					// if we have gone through all visible pixels, divide
					if(hcount > HCOUNT_MAX && vcount > VCOUNT_MAX) begin
						state <= DIVIDING_START;
						
						// add the previous hsum, vsum, and count together
						h_sum <= h_sum + h_sum_prev + h_sum_prev1 + h_sum_prev2;
						v_sum <= v_sum + v_sum_prev + v_sum_prev1 + v_sum_prev2;
						color_count <= color_count + color_count_prev + 
								color_count_prev1 + color_count_prev2;
						
						// record these values for the next round
						// hsum
						h_sum_prev <= h_sum;
						h_sum_prev1 <= h_sum_prev;
						h_sum_prev2 <= h_sum_prev1;
						
						// vsum
						v_sum_prev <= v_sum;
						v_sum_prev1 <= v_sum_prev;
						v_sum_prev2 <= v_sum_prev1;
						
						// color count
						color_count_prev <= color_count;
						color_count_prev1 <= color_count_prev;
						color_count_prev2 <= color_count_prev1;
					end
				end
				DIVIDING_START: begin
					// starts the divider modules
					start <= 1'b1;
					state <= DIVIDING_WAIT;
				end
				DIVIDING_WAIT: begin
					start <= 1'b0;
					// wait for both dividers to return
					if (h_ready) begin
						x_com <= h_quotient[10:0];
						div_ready[1] <= 1'b1;
					end
					if (v_ready) begin
						y_com <= v_quotient[9:0];
						div_ready[0] <= 1'b1;
					end
					
					// figure out if both have returned
					if (div_ready == 2'b11) begin
						state <= IDLE;
						data_ready <= 1'b1;
					end
				end
				default: begin
					state <= IDLE;
					data_ready <= 1'b0;
				end
			endcase
		end
	end

endmodule
