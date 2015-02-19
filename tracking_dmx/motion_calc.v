// Miren Bamforth | A Motion-Tracking DMX512 Controller
// 6.111 Final Project | Fall 2014

// The motion calculator takes in center of mass data and calibration data.
// It outputs two 8-bit values which describe the pan and the tilt which
// should be sent to a moving light at the location indicated in the
// calibration data to make the light point to the center of mass.
module motion_calc(
	input reset,
	input clk,
	input x_com,
	input y_com,
	input x_real,
	input y_real,
	input z_real, // 12 bits
	input x_light1,
	input y_light1,
	input [8:0] pan_addr_light1,
	input [8:0] tilt_addr_light1,
	output reg [7:0] pan,
	output [8:0] pan_addr,
	output reg [7:0] tilt,
	output [8:0] tilt_addr // no ready signal because this is pipelined
	);
	
	// only valid for a single light
	// for now we hard-code the addresses
	assign pan_addr = pan_addr_light1;
	assign tilt_addr = tilt_addr_light1;
	
	// making height an easier variable to use
	wire [11:0] height;
	assign height = z_real;
	
////////////////////////////////////////////////////////////////////////	
	// wires and regs for the always block and coregen components
	
	// values for initial math
	// values for x^2 + y^2
	reg [21:0] xsq_plus_ysq;
	wire [21:0] x_dif_sq; 
	wire [19:0] y_dif_sq;
	// remembers whether deltax or deltay was bigger before normalization
	wire x_greater_than_y, x_greater_than_y_del;
	// remembers whether d or h was bigger before normalization
	wire d_greater_than_h, d_greater_than_h_del;
	// wire that delays the pan value until the tilt value is ready
	wire [7:0] pan_temp;
	
////////////////////////////////////////////////////////////////////////
	// module that does some of the initial math
	
	// this needs to be here so that it's before this module
	wire [11:0] pan_dividend, pan_divisor;
	
	calc_setup setup(
		.clk(clk), .reset(reset), .x_com(x_com), 
		.x_light1(x_light1),
		.y_com(y_com), .y_light1(y_light1),
		.x_dif_sq(x_dif_sq), .y_dif_sq(y_dif_sq),
		.x_greater_than_y(x_greater_than_y), 
		.pan_dividend(pan_dividend),
		.pan_divisor(pan_divisor)
	);
	
////////////////////////////////////////////////////////////////////////
	// coregen modules
	
	// sqrt module for the tilt calculation
	// delay equal to width of output + 2 = (14)
	// DONE
	wire [11:0] sqrt_out;
	wire sqrt_ready;
	reg [11:0] my_sqrt;
	tilt_sqrt sqrt(
		.rdy(sqrt_ready),
		.clk(clk),
		.x_out(sqrt_out), // 12 bit
		.x_in(xsq_plus_ysq) // 22 bit
		);
		
	// a divider to normalize the inputs to arctan_pan
	// delay is dividend + remd + 4 = of 24
	// DONE
	wire [9:0] pan_quot;
	wire [7:0] pan_remd;
	wire pan_div_ready;
	pan_divider pan_div(
		.dividend(pan_dividend), // 12 bit
		.divisor(pan_divisor), // 12 bit
		.quot(pan_quot), // 10 bit
		.remd(pan_remd), // 8 bit
		.clk(clk),
		.rfd(pan_div_ready));
		
	// arctan module for the pan calculation
	// delay equal to output + 4 (15)
	// takes input in 1Q10 form: 01_0000_0000 = 1.00, 11_0000_0000 = -1.00
	wire [9:0] arctan_pan_in_x, arctan_pan_in_y; 
	wire [10:0] pan_val;
	reg [10:0] my_pan_val; 
	wire arc_pan_ready;
	arctan arctac_pan(
		.x_in(arctan_pan_in_x), // 10 bit
		.y_in(arctan_pan_in_y), // 10 bit
		.clk(clk), 
		.phase_out(pan_val), // 11 bit
		.rdy(arc_pan_ready));
		
	// a divider to normalize the inputs to arctan_tilt
	// delay is dividend + remd + 2 = 22
	// DONE
	wire [11:0] tilt_dividend, tilt_divisor;
	wire [11:0] tilt_quotient;
	wire [7:0] tilt_remainder;
	wire tilt_div_ready;
	tilt_divider tilt_div(
		.dividend(tilt_dividend), // 12 bit
		.divisor(tilt_divisor), // 12 bit
		.quot(tilt_quotient), // 12 bit
		.remd(tilt_remainder), // 8 bit
		.clk(clk),
		.rfd(tilt_div_ready));
		
	// arctan module for the tilt calculation
	// delay equal to output + 4 (15)
	wire [9:0] arctan_tilt_in_x, arctan_tilt_in_y; 
	wire [10:0] tilt_val;
	reg [10:0] my_tilt_val;
	wire arc_tilt_ready;
	arctan_tilt arctan_tilt(
		.x_in(arctan_tilt_in_x), // 10 bit
		.y_in(arctan_tilt_in_y), // 10 bit
		.clk(clk),
		.phase_out(tilt_val), // 11 bit
		.rdy(arc_tilt_ready));
		
////////////////////////////////////////////////////////////////////////
	// this takes care of clock cycle 17's work
	sqrt_interface sqrt_int(.clk(clk), .reset(reset),
		.sqrt_ready(sqrt_ready), .sqrt_out(sqrt_out),
		.height(height),
		.tilt_dividend(tilt_dividend),
		.tilt_divisor(tilt_divisor),
		.d_greater_than_h(d_greater_than_h));

////////////////////////////////////////////////////////////////////////
	// this takes care of clock cycle 26's work
	pan_div_interface pan_div_int(.reset(reset), .clk(clk),
		.pan_div_ready(pan_div_ready),
		.x_greater_than_y_del(x_greater_than_y_del),
		.pan_quot(pan_quot), .pan_remd(pan_remd),
		.arctan_pan_in_x(arctan_pan_in_x),
		.arctan_pan_in_y(arctan_pan_in_y));
		
////////////////////////////////////////////////////////////////////////
	// this takes care of clock cycle 39's work
	tilt_div_interface tilt_div_int(.reset(reset), .clk(clk),
		.tilt_div_ready(tilt_div_ready),
		.d_greater_than_h_del(d_greater_than_h_del),
		.tilt_quotient(tilt_quotient),
		.tilt_remainder(tilt_remainder),
		.arctan_tilt_in_x(arctan_tilt_in_x),
		.arctan_tilt_in_y(arctan_tilt_in_y));

////////////////////////////////////////////////////////////////////////
	// range shifter module that takes arctan output and makes the range
	// 	to the correct 0 to 255 byte range
	// delay of 21, see module code
	reg [10:0] pan_shift_in;
	wire [7:0] pan_shift_out;
	range_shifter pan_shifter (.reset(reset), .clk(clk),
			.in(pan_shift_in), .out(pan_shift_out)); 
			
	reg [10:0] tilt_shift_in;
	wire [7:0] tilt_shift_out;
	range_shifter tilt_shifter (.reset(reset), .clk(clk),
			.in(tilt_shift_in), .out(tilt_shift_out)); 

////////////////////////////////////////////////////////////////////////
	// delayed signals because of pipelining
	
	// TODO: verify the number of delays for these	
	delayN#(24) delayx_great_y (.clk(clk),.in(x_greater_than_y),
			.out(x_greater_than_y_del));
	delayN#(22) delayd_great_h (.clk(clk),.in(d_greater_than_h),
			.out(d_greater_than_h_del));		
	delayN#(13) delaypan0 (.clk(clk),.in(pan_shift_out[0]),
			.out(pan_temp[0]));	
	delayN#(13) delaypan1 (.clk(clk),.in(pan_shift_out[1]),
			.out(pan_temp[1]));
	delayN#(13) delaypan2 (.clk(clk),.in(pan_shift_out[2]),
			.out(pan_temp[2]));
	delayN#(13) delaypan3 (.clk(clk),.in(pan_shift_out[3]),
			.out(pan_temp[3]));
	delayN#(13) delaypan4 (.clk(clk),.in(pan_shift_out[4]),
			.out(pan_temp[4]));
	delayN#(13) delaypan5 (.clk(clk),.in(pan_shift_out[5]),
			.out(pan_temp[5]));
	delayN#(13) delaypan6 (.clk(clk),.in(pan_shift_out[6]),
			.out(pan_temp[6]));
	delayN#(13) delaypan7 (.clk(clk),.in(pan_shift_out[7]),
			.out(pan_temp[7]));
	
////////////////////////////////////////////////////////////////////////
	// pipelined always block
	
	// This is pipelined so that we can calculate the pan/tilt quickly
	// We calculate the magnitude of the values to go in the arctan
	//   modules, then deal with the signs later
	always @ (posedge clk) begin
	
////////////////////////////////////////////////////////////////////////	
	
		// clock 1: wait for calc_setup (1/2)
		
////////////////////////////////////////////////////////////////////////
		
		// clock 2: wait for calc_setup (2/2)

////////////////////////////////////////////////////////////////////////		
		
		// clock 3: tilt: calculate x_dif^2 + y_dif^2
		// pan: wait for normalizing divider (1/24)
		// delay signal x_greater_than_y (1/24)
		xsq_plus_ysq <= x_dif_sq + y_dif_sq;

////////////////////////////////////////////////////////////////////////

		// clock 4: tilt: wait for sqrt (1/14)
		// pan: wait for normalizing divider (2/24)
		// delay signal x_greater_than_y (2/24)

////////////////////////////////////////////////////////////////////////

		// clock 5: tilt: wait for sqrt (2/14)
		// pan: wait for normalizing divider (3/24)
		// delay signal x_greater_than_y (3/24)

////////////////////////////////////////////////////////////////////////

		// clock 6: tilt: wait for sqrt (3/14)
		// pan: wait for normalizing divider (4/24)
		// delay signal x_greater_than_y (4/24)

////////////////////////////////////////////////////////////////////////

		// clock 7: tilt: wait for sqrt (4/14)
		// pan: wait for normalizing divider (5/24)
		// delay signal x_greater_than_y (5/24)

////////////////////////////////////////////////////////////////////////

		// clock 8: tilt: wait for sqrt (5/14)
		// pan: wait for normalizing divider (6/24)
		// delay signal x_greater_than_y (6/24)

////////////////////////////////////////////////////////////////////////

		// clock 9: tilt: wait for sqrt (6/14)
		// pan: wait for normalizing divider (7/24)
		// delay signal x_greater_than_y (7/24)

////////////////////////////////////////////////////////////////////////

		// clock 10: tilt: wait for sqrt (7/14)
		// pan: wait for normalizing divider (8/24)
		// delay signal x_greater_than_y (8/24)

////////////////////////////////////////////////////////////////////////

		// clock 11: tilt: wait for sqrt (8/14)
		// pan: wait for normalizing divider (9/24)
		// delay signal x_greater_than_y (9/24)

////////////////////////////////////////////////////////////////////////

		// clock 12: tilt: wait for sqrt (9/14)
		// pan: wait for normalizing divider (10/24)
		// delay signal x_greater_than_y (10/24)

////////////////////////////////////////////////////////////////////////

		// clock 13: tilt: wait for sqrt (10/14)
		// pan: wait for normalizing divider (11/24)
		// delay signal x_greater_than_y (11/24)

////////////////////////////////////////////////////////////////////////

		// clock 14: tilt: wait for sqrt (11/14)
		// pan: wait for normalizing divider (12/24)
		// delay signal x_greater_than_y (12/24)

////////////////////////////////////////////////////////////////////////

		// clock 15: tilt: wait for sqrt (12/14)
		// pan: wait for normalizing divider (13/24)
		// delay signal x_greater_than_y (13/24)

////////////////////////////////////////////////////////////////////////

		// clock 16: tilt: wait for sqrt (13/14)
		// pan: wait for normalizing divider (14/24)
		// delay signal x_greater_than_y (14/24)

////////////////////////////////////////////////////////////////////////

		// clock 17: tilt: wait for sqrt (14/14), should be ready
		// pan: wait for normalizing divider (15/24)
		// delay signal x_greater_than_y (15/24)
		// this clock cycle is controlled with sqrt_interface

////////////////////////////////////////////////////////////////////////

		// clock 18: tilt: wait for normalizing divider (1/22)
		// pan: wait for normalizing divider (16/24)
		// delay signal x_greater_than_y (16/24)
		// delay signal d_greater_than_h (1/22)

////////////////////////////////////////////////////////////////////////

		// clock 19: tilt: wait for normalizing divider (2/22)
		// pan: wait for normalizing divider (17/24)
		// delay signal x_greater_than_y (17/24)
		// delay signal d_greater_than_h (2/22)

////////////////////////////////////////////////////////////////////////

		// clock 20: tilt: wait for normalizing divider (3/22)
		// pan: wait for normalizing divider (18/24)
		// delay signal x_greater_than_y (18/24)
		// delay signal d_greater_than_h (3/22)

////////////////////////////////////////////////////////////////////////

		// clock 21: tilt: wait for normalizing divider (4/22)
		// pan: wait for normalizing divider (19/24)
		// delay signal x_greater_than_y (19/24)
		// delay signal d_greater_than_h (4/22)

////////////////////////////////////////////////////////////////////////

		// clock 22: tilt: wait for normalizing divider (5/22)
		// pan: wait for normalizing divider (20/24)
		// delay signal x_greater_than_y (20/24)
		// delay signal d_greater_than_h (5/22)

////////////////////////////////////////////////////////////////////////

		// clock 23: tilt: wait for normalizing divider (6/22)
		// pan: wait for normalizing divider (21/24)
		// delay signal x_greater_than_y (21/24)
		// delay signal d_greater_than_h (6/22)

////////////////////////////////////////////////////////////////////////

		// clock 24: tilt: wait for normalizing divider (7/22)
		// pan: wait for normalizing divider (22/24)
		// delay signal x_greater_than_y (22/24)
		// delay signal d_greater_than_h (7/22)

////////////////////////////////////////////////////////////////////////

		// clock 25: tilt: wait for normalizing divider (8/22)
		// pan: wait for normalizing divider (23/24)
		// delay signal x_greater_than_y (23/24)
		// delay signal d_greater_than_h (8/22)

////////////////////////////////////////////////////////////////////////

		// clock 26: tilt: wait for normalizing divider (9/22)
		// pan: wait for normalizing divider (24/24), should be ready
		// delay signal x_greater_than_y (24/24), should be ready
		// delay signal d_greater_than_h (9/22)
		
		// this clock cycle is taken care of by pan_div_interface module
		
		// arctan inputs are in 1Q10 form, see cordic data sheet pg. 21

////////////////////////////////////////////////////////////////////////

		// clock 27: tilt: wait for normalizing divider (10/22)
		// pan: wait for arctan (1/15)
		// delay signal d_greater_than_h (10/22)

////////////////////////////////////////////////////////////////////////

		// clock 28: tilt: wait for normalizing divider (11/22)
		// pan: wait for arctan (2/15)
		// delay signal d_greater_than_h (11/22)

////////////////////////////////////////////////////////////////////////

		// clock 29: tilt: wait for normalizing divider (12/22)
		// pan: wait for arctan (3/15)
		// delay signal d_greater_than_h (12/22)

////////////////////////////////////////////////////////////////////////

		// clock 30: tilt: wait for normalizing divider (13/22)
		// pan: wait for arctan (4/15)
		// delay signal d_greater_than_h (13/22)

////////////////////////////////////////////////////////////////////////

		// clock 31: tilt: wait for normalizing divider (14/22)
		// pan: wait for arctan (5/15)
		// delay signal d_greater_than_h (14/22)

////////////////////////////////////////////////////////////////////////

		// clock 32: tilt: wait for normalizing divider (15/22)
		// pan: wait for arctan (6/15)
		// delay signal d_greater_than_h (15/22)

////////////////////////////////////////////////////////////////////////

		// clock 33: tilt: wait for normalizing divider (16/22)
		// pan: wait for arctan (7/15)
		// delay signal d_greater_than_h (16/22)

////////////////////////////////////////////////////////////////////////

		// clock 34: tilt: wait for normalizing divider (17/22)
		// pan: wait for arctan (8/15)
		// delay signal d_greater_than_h (17/22)

////////////////////////////////////////////////////////////////////////

		// clock 35: tilt: wait for normalizing divider (18/22)
		// pan: wait for arctan (9/15)
		// delay signal d_greater_than_h (18/22)

////////////////////////////////////////////////////////////////////////

		// clock 36: tilt: wait for normalizing divider (19/22)
		// pan: wait for arctan (10/15)
		// delay signal d_greater_than_h (19/22)

////////////////////////////////////////////////////////////////////////

		// clock 37: tilt: wait for normalizing divider (20/22)
		// pan: wait for arctan (11/15)
		// delay signal d_greater_than_h (20/22)

////////////////////////////////////////////////////////////////////////

		// clock 38: tilt: wait for normalizing divider (21/22)
		// pan: wait for arctan (12/15)
		// delay signal d_greater_than_h (21/22)

////////////////////////////////////////////////////////////////////////

		// clock 39: tilt: wait for normalizing divider (22/22), should be ready
		// pan: wait for arctan (13/15)
		// delay signal d_greater_than_h (22/22), should be ready
		
		// this clock cycle's work is done by tilt_div_interface

////////////////////////////////////////////////////////////////////////

		// clock 40: tilt: wait for arctan (1/15)
		// pan: wait for arctan (14/15)

////////////////////////////////////////////////////////////////////////

		// clock 41: tilt: wait for arctan (2/15)
		// pan: wait for arctan (15/15), should be ready
		// start the pan range shifter
		if(arc_pan_ready) pan_shift_in <= pan_val;

////////////////////////////////////////////////////////////////////////

		// clock 42: tilt: wait for arctan (3/15)
		// pan: wait for pan range shifter (1/21)

////////////////////////////////////////////////////////////////////////

		// clock 43: tilt: wait for arctan (4/15)
		// pan: wait for pan range shifter (2/21)

////////////////////////////////////////////////////////////////////////

		// clock 44: tilt: wait for arctan (5/15)
		// pan: wait for pan range shifter (3/21)

////////////////////////////////////////////////////////////////////////

		// clock 45: tilt: wait for arctan (6/15)
		// pan: wait for pan range shifter (4/21)

////////////////////////////////////////////////////////////////////////

		// clock 46: tilt: wait for arctan (7/15)
		// pan: wait for pan range shifter (5/21)

////////////////////////////////////////////////////////////////////////

		// clock 47: tilt: wait for arctan (8/15)
		// pan: wait for pan range shifter (6/21)

////////////////////////////////////////////////////////////////////////

		// clock 48: tilt: wait for arctan (9/15)
		// pan: wait for pan range shifter (7/21)

////////////////////////////////////////////////////////////////////////

		// clock 49: tilt: wait for arctan (10/15)
		// pan: wait for pan range shifter (8/21)

////////////////////////////////////////////////////////////////////////

		// clock 50: tilt: wait for arctan (11/15)
		// pan: wait for pan range shifter (9/21)

////////////////////////////////////////////////////////////////////////

		// clock 51: tilt: wait for arctan (12/15)
		// pan: wait for pan range shifter (10/21)

////////////////////////////////////////////////////////////////////////

		// clock 52: tilt: wait for arctan (13/15)
		// pan: wait for pan range shifter (11/21)

////////////////////////////////////////////////////////////////////////

		// clock 53: tilt: wait for arctan (14/15)
		// pan: wait for pan range shifter (12/21)

////////////////////////////////////////////////////////////////////////

		// clock 54: tilt: wait for arctan (15/15), should be ready
		// pan: wait for pan range shifter (13/21)
		// this starts the tilt range shifter
		if(arc_tilt_ready) tilt_shift_in <= tilt_val;

////////////////////////////////////////////////////////////////////////

		// clock 55: tilt: wait for tilt range shifter (1/21)
		// pan: wait for pan range shifter (14/21)

////////////////////////////////////////////////////////////////////////

		// clock 56: tilt: wait for tilt range shifter (2/21)
		// pan: wait for pan range shifter (15/21)

////////////////////////////////////////////////////////////////////////

		// clock 57: tilt: wait for tilt range shifter (3/21)
		// pan: wait for pan range shifter (16/21)

////////////////////////////////////////////////////////////////////////

		// clock 58: tilt: wait for tilt range shifter (4/21)
		// pan: wait for pan range shifter (17/21)

////////////////////////////////////////////////////////////////////////

		// clock 59: tilt: wait for tilt range shifter (5/21)
		// pan: wait for pan range shifter (18/21)

////////////////////////////////////////////////////////////////////////

		// clock 60: tilt: wait for tilt range shifter (6/21)
		// pan: wait for pan range shifter (19/21)

////////////////////////////////////////////////////////////////////////

		// clock 61: tilt: wait for tilt range shifter (7/21)
		// pan: wait for pan range shifter (20/21)

////////////////////////////////////////////////////////////////////////

		// clock 62: tilt: wait for tilt range shifter (8/21)
		// pan: wait for pan range shifter (21/21), should be ready

////////////////////////////////////////////////////////////////////////

		// clock 63: tilt: wait for tilt range shifter (9/21)
		// pan: delay signal pan_shift_out (1/13)

////////////////////////////////////////////////////////////////////////

		// clock 64: tilt: wait for tilt range shifter (10/21)
		// pan: delay signal pan_shift_out (2/13)

////////////////////////////////////////////////////////////////////////

		// clock 65: tilt: wait for tilt range shifter (11/21)
		// pan: delay signal pan_shift_out (3/13)

////////////////////////////////////////////////////////////////////////

		// clock 66: tilt: wait for tilt range shifter (12/21)
		// pan: delay signal pan_shift_out (4/13)

////////////////////////////////////////////////////////////////////////

		// clock 67: tilt: wait for tilt range shifter (13/21)
		// pan: delay signal pan_shift_out (5/13)

////////////////////////////////////////////////////////////////////////

		// clock 68: tilt: wait for tilt range shifter (14/21)
		// pan: delay signal pan_shift_out (6/13)

////////////////////////////////////////////////////////////////////////

		// clock 69: tilt: wait for tilt range shifter (15/21)
		// pan: delay signal pan_shift_out (7/13)

////////////////////////////////////////////////////////////////////////

		// clock 70: tilt: wait for tilt range shifter (16/21)
		// pan: delay signal pan_shift_out (8/13)

////////////////////////////////////////////////////////////////////////

		// clock 71: tilt: wait for tilt range shifter (17/21)
		// pan: delay signal pan_shift_out (9/13)

////////////////////////////////////////////////////////////////////////

		// clock 72: tilt: wait for tilt range shifter (18/21)
		// pan: delay signal pan_shift_out (10/13)

////////////////////////////////////////////////////////////////////////

		// clock 73: tilt: wait for tilt range shifter (19/21)
		// pan: delay signal pan_shift_out (11/13)

////////////////////////////////////////////////////////////////////////

		// clock 74: tilt: wait for tilt range shifter (20/21)
		// pan: delay signal pan_shift_out (12/13)

////////////////////////////////////////////////////////////////////////

		// clock 75: tilt: wait for tilt range shifter (21/21), should be ready
		// pan: delay signal pan_shift_out (13/13), should be ready
		pan <= pan_temp;
		tilt <= tilt_shift_out;

////////////////////////////////////////////////////////////////////////

	end
endmodule
