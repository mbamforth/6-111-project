// Miren Bamforth | A Motion-Tracking DMX512 Controller
// 6.111 Final Project | Fall 2014
// This code was modified from code on the 6.111 website.

// This module finds the center of mass of all pixels of a certain 
// color as a way to do simple motion tracking.

// This module is the same as the tracker module except it uses RGB 
// instead of HSV because I was having issues with the RGB2HSV module
// as of 11/17
module rgb_tracker(
    input clk,
    input reset,
    input [10:0] hcount,
    input [9:0] vcount,
    input [23:0] rgb,
	 input [7:0] low,
	 input [7:0] high,
    output reg [10:0] x_com,
    output reg [9:0] y_com,
	 output reg data_ready
    );

	// TODO: figure out clock and timing issues for this module
	// TODO: think about whether this is taking the whole frame or just
	// the video input into account
	
	// we only pay attention to the visible pixels
	// we ignore anything with HSV = 24'd0 because earlier we
	// set all the pixels other than the ones from the video 
	// input to 24'd0
	localparam HCOUNT_MAX = 11'd1024;
	localparam VCOUNT_MAX = 10'd768;
	
	// we assume that at most ~10% of pixels can be part of the tracked obj
	// hence the bit width
	reg [16:0] color_count;
	// adds up all of the locations of pixels in the color range
	// since we are assuming that at most ~10% of pixels are part 
	// of the object, we can use only 22 bits for the sums
	reg [21:0] h_sum;
	reg [21:0] v_sum;
	
	// state for telling whether we should sum or not
	localparam IDLE = 2'b00;
	localparam COUNTING = 2'b01;
	localparam DIVIDING_START = 2'b10;
	localparam DIVIDING_WAIT = 2'b11;
	reg [1:0] state = IDLE;
	
	// remembers which dividers have returned
	reg [1:0] div_ready;
	
	//wire [7:0] hue;
	//assign hue = hsv[23:16];
	wire [7:0] red;
	assign red = rgb[23:16];
	wire [7:0] green;
	assign green = rgb[15:8];
	wire [7:0] blue;
	assign blue = rgb[7:0];
	
	// dividers and necessary wires
	// the dividers are 29 bits wide
	// TODO: consider narrowing the divider
	wire [21:0] h_quotient, v_quotient, h_remainder, v_remainder;
	reg start; 
	wire h_ready, v_ready;
	
	// horizontal divider
	divider #(22) h_div(
		.clk(clk),
		.sign(1'b0),
		.start(start),
		.dividend(h_sum),
		.divider({9'd0, color_count}),
		.quotient(h_quotient),
		.fractional(h_remainder),
		.ready(h_ready)
		);
		
	// vertical divider
	divider #(22) v_div(
		.clk(clk),
		.sign(1'b0),
		.start(start),
		.dividend(v_sum),
		.divider({9'd0, color_count}),
		.quotient(v_quotient),
		.fractional(v_remainder),
		.ready(v_ready)
		);
		
	wire r_low, r_high, g_low, g_high, b_low, b_high;
	// these are temporary, they match the red piece of paper
	assign r_low = 8'hF8;
	assign r_high = 8'hFF;
	assign g_low = 8'h40;
	assign g_high = 8'h60;
	assign b_low = 8'h50;
	assign b_high = 8'h70;
		
	reg check;
	always @* begin
		check = (red >= r_low && red <= r_high) &&
					(green >= g_low && green <= g_high);
		/*check = (red >= r_low && red <= r_high) &&
					(green >= g_low && green <= g_high) &&
					(blue >= b_low && blue <= b_high);*/
	end
	
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
						h_sum <= 32'd0;
						v_sum <= 32'd0;
						color_count <= (check) ? 20'd1: 20'd0;
						start <= 1'b0;
						div_ready <= 2'b00;
					end
					
					data_ready <= 1'b0;
				end
				COUNTING: begin
					// if we are in the visible range of pixels
					if(rgb != 24'd0 && hcount < HCOUNT_MAX && 
							vcount < VCOUNT_MAX) begin
						// if the color is in range, increment everything
						if(check) begin
							h_sum <= h_sum + hcount;
							v_sum <= v_sum + vcount;
							color_count <= color_count + 1;
						end
					end
					
					// if we have gone through all visible pixels, divide
					if(hcount > HCOUNT_MAX && vcount > VCOUNT_MAX) begin
						state <= DIVIDING_START;
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
