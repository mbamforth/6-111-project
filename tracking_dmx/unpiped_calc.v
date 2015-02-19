// Miren Bamforth | A Motion-Tracking DMX512 Controller
// 6.111 Final Project | Fall 2014

// This module combines calculation and calibration data to output a pan byte and a tilt byte 
// It took a lot of effort to get this working because ModelSim cannot simulate coregen modules...
module unpiped_calc(
   input reset,
	input clk,
	input [10:0] x_com,
	input [9:0] y_com,
	input [10:0] x_real,
	input [9:0] y_real,
	input [11:0] z_real,
	input [10:0] x_light1,
	input [9:0] y_light1,
	input [8:0] pan_addr_light1,
	input [8:0] tilt_addr_light1,
	output reg [7:0] pan,
	output [8:0] pan_addr,
	output reg [7:0] tilt,
	output [8:0] tilt_addr,
	output reg ready
	);
	
	// TODO: as of 7pm on 12-2-14, this works in simulation on a windows 7 ise instance
	// To port this to the athena ise version, the sqrt and dividers must be restored 
	// 	to their old versions. 
	// Testing should be done with the moveable cursors set to x_com and y_com, and 
	// 	the hex display showing pan and tilt.
	
	// some local parameters
	localparam NO = 1'b0;
	localparam YES = 1'b1;
	
	// set up the state machine
	localparam IDLE = 3'd0;
	localparam SETUP = 3'd1;
	localparam WAIT_FOR_SQRT = 3'd2;
	localparam WAIT_FOR_PAN_DIV = 3'd3;
	localparam WAIT_FOR_TILT_DIV = 3'd4;
	localparam WAIT_FOR_PAN_ARCTAN = 3'd5;
	localparam WAIT_FOR_TILT_ARCTAN = 3'd6;
	localparam WAIT = 3'd7;
	reg [2:0] state;
	initial state = IDLE;
	
	// only valid for a single light
	// for now we hard-code the addresses
	assign pan_addr = pan_addr_light1;
	assign tilt_addr = tilt_addr_light1;
	
	// making height an easier variable to use
	wire [11:0] height;
	assign height = z_real;
	
	// module which contains the coregen sqrt
	reg [21:0] xsq_plus_ysq;
	wire [21:0] sqrt_in;
	assign sqrt_in = xsq_plus_ysq;
	wire [11:0] sqrt_out;
	wire sqrt_ready;
	sqrt_wrapper my_sqrt(
    .reset(reset), .clk(clk), .in(sqrt_in), .out(sqrt_out), .ready(sqrt_ready));
	 
	// pan divider module
	// a divider to normalize the inputs to arctan_pan
	// delay is dividend + remd + 4 = of 24
	// 16
	reg [11:0] pan_dividend, pan_divisor;
	wire [11:0] pan_quot_temp;
	wire [9:0] pan_quot;
	assign pan_quot = pan_quot_temp[9:0];
	wire [7:0] pan_remd;
	wire pan_div_ready;
	pan_divider pan_div(
		.clk(clk), // input clk
		.rfd(pan_div_ready), // output rfd
		.dividend(pan_dividend), // input [11 : 0] dividend
		.divisor(pan_divisor), // input [11 : 0] divisor
		.quot(pan_quot_temp), // output [11 : 0] quotient
		.remd(pan_remd)); // output [7 : 0] fractional
		
	// a divider to normalize the inputs to arctan_tilt
	// delay is dividend + remd + 2 = 2 --> actually is 24?
	reg [11:0] tilt_dividend, tilt_divisor;
	wire [11:0] tilt_quotient;
	wire [7:0] tilt_remainder;
	wire tilt_div_ready;
	tilt_divider tilt_div (
		.clk(clk), // input clk
		.rfd(tilt_div_ready), // output rfd
		.dividend(tilt_dividend), // input [11 : 0] dividend
		.divisor(tilt_divisor), // input [11 : 0] divisor
		.quot(tilt_quotient), // output [11 : 0] quotient
		.remd(tilt_remainder)); // output [7 : 0] fractional
	
	// arctan module for the pan calculation
	// delay equal to output + 4 (15)
	// takes input in 1Q10 form: 01_0000_0000 = 1.00, 11_0000_0000 = -1.00
	// gives output in 2Q10 format: 001_000_0000 = 1.00
	reg [9:0] arctan_pan_in_x, arctan_pan_in_y; 
	wire [9:0] pan_val;
	wire arc_pan_ready;
	arctan arctac_pan(
		.x_in(arctan_pan_in_x), // 10 bit
		.y_in(arctan_pan_in_y), // 10 bit
		.clk(clk), 
		.phase_out(pan_val), // 10 bit
		.rdy(arc_pan_ready));
	
	// arctan module for the tilt calculation
	// delay equal to output + 4 (15)
	reg [9:0] arctan_tilt_in_x, arctan_tilt_in_y; 
	wire [9:0] tilt_val;
	wire arc_tilt_ready;
	arctan_tilt_new my_arctan_tilt(
		.x_in(arctan_tilt_in_x), // 10 bit
		.y_in(arctan_tilt_in_y), // 10 bit
		.clk(clk),
		.phase_out(tilt_val), // 10 bit
		.rdy(arc_tilt_ready));
	
	// wires for the always block
	reg [10:0] my_x_com;
	initial my_x_com = 11'd0;
	reg [9:0] my_y_com;
	initial my_y_com = 10'd0;
	// needs an extra bit for signed number
	reg [11:0] x_dif;
	reg [10:0] y_dif;
	initial x_dif = 12'd0;
	initial y_dif = 11'd0;
	// magnitude is positive, so no extra bit
	reg [10:0] x_mag;
	reg [9:0] y_mag;
	initial x_mag = 11'd0;
	initial y_mag = 10'd0;
	// wires equal to deltax squared and deltay squared
	reg [21:0] x_dif_sq;
	reg [19:0] y_dif_sq;
	
	initial x_dif_sq = 22'd0;
	initial y_dif_sq = 20'd0;
	initial xsq_plus_ysq = 22'd0;
	// remembers whether deltax or deltay was bigger before normalization
	reg x_greater_than_y;
	// remembers whether d or h was bigger before normalization
	reg d_greater_than_h;
	// sotres pan while we wait for tilt
	reg [7:0] pan_prev;
	reg pan_out_ready;
	initial pan_out_ready = YES;
	
	// counters to stall the module while the coregen modules work
	// these ranges work for now with the setup on the win7 machine:
	// new sqrt: latency 13
	// new dividers: latency of 24
	// old arctans: latency of 14
	reg [3:0] sqrt_counter;
	initial sqrt_counter = 4'd0;
	localparam SQRT_COUNTER_MAX = 4'd13;
	reg [3:0] pan_div_counter;
	initial pan_div_counter = 4'd0;
	localparam PAN_DIV_COUNTER_MAX = 4'd11;
	reg [3:0] tilt_div_counter;
	initial tilt_div_counter = 4'd0;
	localparam TILT_DIV_COUNTER_MAX = 4'd14;
	reg [4:0] arctan_tilt_counter;
	initial arctan_tilt_counter = 4'd0;
	localparam ARCTAN_TILT_COUNTER_MAX = 4'd15;
	reg [3:0] wait_counter;
	initial wait_counter = 4'd0;
	localparam WAIT_MAX = 4'd15;
	
	// stuff for range shifting the arctan values from [-pi to pi] to [0 to 255]
	// pi in 2Q10 form (see cordic data sheet)
	// pi is equal to 011.0010010
	// -pi is equal to 100.1101110
	localparam PI = 10'b011_0010_010;
	// 127/73 is our scale, slightly off
	localparam SCALE = 6'b10_1000; // 40
	// wires for our pipelining and divider
	reg [9:0] pan_plus_pi, tilt_plus_pi;
	reg [7:0] short_pan, short_tilt;
	reg [15:0] pan_scaled, tilt_scaled;

	// using blocking statements (?)
	always @ (posedge clk) begin
		if (reset) begin
			// reset here
			state = IDLE;
			pan = 8'd0;
			tilt = 8'd0;
		end
		else begin
			// do things depending on the state
			case(state)
				IDLE: begin
					// latch values for now
					my_x_com = x_com;
					my_y_com = y_com;
					ready = NO;
					state = SETUP;
				end
				SETUP: begin
					// set up various necessary values
					x_dif = x_com - x_light1;
					if (x_com > x_light1) x_mag = x_com - x_light1;
					else x_mag = x_light1 - x_com;
					
					y_dif = y_com - y_light1;
					if (y_com > y_light1) y_mag = y_com - y_light1;
					else y_mag = y_light1 - y_com;
					
					// get some values
					x_dif_sq = x_mag*x_mag;
					y_dif_sq = y_mag*y_mag;
					xsq_plus_ysq = x_dif_sq + y_dif_sq;
					
					// if deltax is greater than deltay, normalize by doing deltay/deltax
					if(x_mag > y_mag) begin
						x_greater_than_y = YES;
						// sign extend y
						pan_dividend = {y_dif[10], y_dif};
						// we use a positive number in the denominator to preserve the signs correctly
						// this is accountde for when we set 1 or -1 to the arctan input for this value
						pan_divisor = {1'b0, x_mag};
						// avoid divide by zero case
						if (pan_divisor == 12'd0) pan_divisor = 12'd1;
					end
					// if deltay is greater than deltax, normalize by doing deltax/deltay		
					else begin
						x_greater_than_y = NO;
						pan_dividend = x_dif;
						// sign extend y
						pan_divisor = {2'b00, y_mag};
						// avoid divide by zero case
						if (pan_divisor == 12'd0) pan_divisor = 12'd1;
					end
			
					sqrt_counter = 4'd0;
					wait_counter = 4'd0;
					//state = WAIT;
					state = WAIT_FOR_SQRT;
				end
				/*WAIT: begin
					if (wait_counter < WAIT_MAX)	wait_counter = wait_counter + 1;
					else state = WAIT_FOR_SQRT;
				end*/
				WAIT_FOR_SQRT: begin
					// hold for the number of cycles it takes sqrt to complete
					if (sqrt_counter < SQRT_COUNTER_MAX) sqrt_counter = sqrt_counter + 1;
					else begin
						if (sqrt_ready) begin
							// if sqrt_out is bigger than height, normalize by height/sqrt
							if (sqrt_out > height) begin
								tilt_dividend = height;
								tilt_divisor = sqrt_out;
								// avoid divide by zero case
								if (tilt_divisor == 12'd0) tilt_divisor = 12'd1;
								d_greater_than_h = YES;
							end
							// if height is bigger than sqrt_out, normalize by sqrt/height
							else begin
								tilt_dividend = sqrt_out;
								tilt_divisor = height;
								// avoid divide by zero case
								if (tilt_divisor == 12'd0) tilt_divisor = 12'd1;
								d_greater_than_h = NO;
							end
							
							// go to next state
							pan_div_counter = 4'd0;
							state = WAIT_FOR_PAN_DIV;
						end
					end
				end
				WAIT_FOR_PAN_DIV: begin
					if (pan_div_counter < PAN_DIV_COUNTER_MAX) begin
						pan_div_counter = pan_div_counter + 1;
					end
					else begin
						if (x_greater_than_y) begin
							arctan_pan_in_x = {x_dif[11], 9'b1_0000_0000};
							
							if (pan_quot[9] || pan_remd[7]) 
								arctan_pan_in_y = {1'b1, pan_quot[0], pan_remd[6:0], 1'b0};
							else
								arctan_pan_in_y = {1'b0, pan_quot[0], pan_remd[6:0], 1'b0};
						end
						// if deltay was greater than deltax, y = 1 and x = value from div			
						else begin
							if (pan_quot[9] || pan_remd[7]) 
								// TODO: this might be missing an edge case
								arctan_pan_in_x = {2'b11, pan_remd[6:0], 1'b0};
							else
								arctan_pan_in_x = {1'b0, pan_quot[0], pan_remd[6:0], 1'b0};
								
							arctan_pan_in_y = {y_dif[10], 9'b1_0000_0000};
						end
						
						// go to next state
						tilt_div_counter = 4'd0;
						state = WAIT_FOR_TILT_DIV;
					end
				end
				WAIT_FOR_TILT_DIV: begin
					if (tilt_div_counter < TILT_DIV_COUNTER_MAX) begin
						tilt_div_counter = tilt_div_counter + 1;
					end
					else begin
						if (d_greater_than_h) begin
							arctan_tilt_in_x <= {tilt_quotient[11], 
								tilt_quotient[0], tilt_remainder[6:0], 1'b0};
							arctan_tilt_in_y <= 10'b01_0000_0000;
						end
						// if deltay was greater than deltax, x = 1 and y = value from div			
						else begin
							arctan_tilt_in_x <= 10'b01_0000_0000;
							arctan_tilt_in_y <= {tilt_quotient[11], 
								tilt_quotient[0], tilt_remainder[6:0], 1'b0};
						end
						
						// go to next state
						pan_out_ready = !pan_out_ready;
						state = WAIT_FOR_PAN_ARCTAN;
					end
				end
				WAIT_FOR_PAN_ARCTAN: begin
					// pan_val is actually already ready, so we don't have to wait at all
					// pan range shifting stuff here
					pan_plus_pi = pan_val + PI;
					// cut off lowest 2 bits
					// msb is no long signed, so it can stay
					short_pan = pan_plus_pi[9:2];
					pan_scaled = short_pan*SCALE;
					// pan and tilt will be outputted at slightly different times
					pan = pan_scaled[12:5];
					
					// proceed to next state
					arctan_tilt_counter = 0;
					state = WAIT_FOR_TILT_ARCTAN;
				end
				WAIT_FOR_TILT_ARCTAN: begin
					if (arctan_tilt_counter < ARCTAN_TILT_COUNTER_MAX) 
						arctan_tilt_counter = arctan_tilt_counter + 1;
					else begin
						// tilt range shifting stuff here
						tilt_plus_pi = tilt_val + PI;
						// cut off lowest 2 bits
						// msb is no long signed, so it can stay
						short_tilt = tilt_plus_pi[9:2];
						tilt_scaled = short_tilt*SCALE + 8'd3;
						// added this line because the middle of the light's tilt
						// 	range is actually not perfectly downwards
						
						// output pan and tilt
						pan = pan_scaled[12:5];
						tilt = tilt_scaled[12:5];
						
						// go back to the idle state
						ready = YES;
						state = IDLE;
					end
				end
				default: begin
					// reset on default
					pan = 8'd0;
					tilt = 8'd0;
					state = IDLE;
				end
			endcase
		end
	end

endmodule
