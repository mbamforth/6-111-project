// Miren Bamforth | A Motion-Tracking DMX512 Controller
// 6.111 Final Project | Fall 2014
// This code was modified from code on the 6.111 website.

// changes 24 bits of RGB to 24 bits of HSV
module rgb2hsv(clock, reset, r, g, b, h, s, v);
		input wire clock;
		input wire reset;
		input wire [7:0] r;
		input wire [7:0] g;
		input wire [7:0] b;
		output reg [7:0] h;
		output reg [7:0] s;
		output reg [7:0] v;
		reg [7:0] my_r_delay1, my_g_delay1, my_b_delay1;
		reg [7:0] my_r_delay2, my_g_delay2, my_b_delay2;
		reg [7:0] my_r, my_g, my_b;
		reg [7:0] min, max, delta;
		reg [15:0] s_top;
		reg [15:0] s_bottom;
		reg [15:0] h_top;
		reg [15:0] h_bottom;
		wire [15:0] s_quotient;
		wire [15:0] s_remainder;
		wire s_rfd;
		wire [15:0] h_quotient;
		wire [15:0] h_remainder;
		wire h_rfd;
		reg [7:0] v_delay [19:0];
		reg [18:0] h_negative;
		reg [15:0] h_add [18:0];
		reg [4:0] i;
		// Clocks 4-18: perform all the divisions
		//the s_divider (16/16) has delay 18
		//the hue_div (16/16) has delay 18

		wire sign;
		assign sign = 1'b0;
		reg start = 1'b0;
		reg [4:0] counter = 5'd0;

		hsv_divider hue_div1(
		.clk(clock),
		.dividend(s_top),
		.divisor(s_bottom),
		.quot(s_quotient),
	        // note: the "fractional" output was originally named "remainder" in this
		// file -- it seems coregen will name this output "fractional" even if
		// you didn't select the remainder type as fractional.
		.remd(s_remainder),
		.rfd(s_rfd)
		);
		hsv_divider hue_div2(
		.clk(clock),
		.dividend(h_top),
		.divisor(h_bottom),
		.quot(h_quotient),
		.remd(h_remainder),
		.rfd(h_rfd)
		);
		always @ (posedge clock) begin
			if (reset) begin
				start <= 1'b0;
				counter <= 5'd0;
			end
			else begin
				if (counter == 5'd3) start <= 1'b1;
				else start <= 1'b0;
			
				if (counter < 5'd21) counter <= counter + 1;
				else counter <= 5'd0;
		
				// Clock 1: latch the inputs (always positive)
				{my_r, my_g, my_b} <= {r, g, b};

				
				// Clock 2: compute min, max
				{my_r_delay1, my_g_delay1, my_b_delay1} <= {my_r, my_g, my_b};
				
				if((my_r >= my_g) && (my_r >= my_b)) //(B,S,S)
					max <= my_r;
				else if((my_g >= my_r) && (my_g >= my_b)) //(S,B,S)
					max <= my_g;
				else	max <= my_b;
			
				if((my_r <= my_g) && (my_r <= my_b)) //(S,B,B)
					min <= my_r;
				else if((my_g <= my_r) && (my_g <= my_b)) //(B,S,B)
					min <= my_g;
				else
					min <= my_b;
					
				// Clock 3: compute the delta
				{my_r_delay2, my_g_delay2, my_b_delay2} <= {my_r_delay1, my_g_delay1, my_b_delay1};
				v_delay[0] <= max;
				delta <= max - min;
				
				// Clock 4: compute the top and bottom of whatever divisions we need to do
				s_top <= 8'd255 * delta;
				s_bottom <= (v_delay[0]>0)?{8'd0, v_delay[0]}: 16'd1;
				
			
				if(my_r_delay2 == v_delay[0]) begin
					h_top <= (my_g_delay2 >= my_b_delay2)?(my_g_delay2 - my_b_delay2) * 8'd255:(my_b_delay2 - my_g_delay2) * 8'd255;
					h_negative[0] <= (my_g_delay2 >= my_b_delay2)?0:1;
					h_add[0] <= 16'd0;
				end 
				else if(my_g_delay2 == v_delay[0]) begin
					h_top <= (my_b_delay2 >= my_r_delay2)?(my_b_delay2 - my_r_delay2) * 8'd255:(my_r_delay2 - my_b_delay2) * 8'd255;
					h_negative[0] <= (my_b_delay2 >= my_r_delay2)?0:1;
					h_add[0] <= 16'd85;
				end 
				else if(my_b_delay2 == v_delay[0]) begin
					h_top <= (my_r_delay2 >= my_g_delay2)?(my_r_delay2 - my_g_delay2) * 8'd255:(my_g_delay2 - my_r_delay2) * 8'd255;
					h_negative[0] <= (my_r_delay2 >= my_g_delay2)?0:1;
					h_add[0] <= 16'd170;
				end
				
				h_bottom <= (delta > 0)?delta * 8'd6:16'd6;
		
			
				//delay the v and h_negative signals 18 times
				for(i=1; i<19; i=i+1) begin
					v_delay[i] <= v_delay[i-1];
					h_negative[i] <= h_negative[i-1];
					h_add[i] <= h_add[i-1];
				end
			
				v_delay[19] <= v_delay[18];
				//Clock 22: compute the final value of h
				//depending on the value of h_delay[18], we need to subtract 255 from it to make it come back around the circle
				if(h_negative[18] && (h_quotient > h_add[18])) begin
					h <= 8'd255 - h_quotient[7:0] + h_add[18];
				end 
				else if(h_negative[18]) begin
					h <= h_add[18] - h_quotient[7:0];
				end 
				else begin
					h <= h_quotient[7:0] + h_add[18];
				end
				
				//pass out s and v straight
				s <= s_quotient;
				v <= v_delay[19];
			end
		end
endmodule
