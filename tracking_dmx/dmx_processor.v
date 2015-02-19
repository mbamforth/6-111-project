// Miren Bamforth | A Motion-Tracking DMX512 Controller
// 6.111 Final Project | Fall 2014

// This module takes in data from the motion tracking block and stores it.
// It then passes this data to the DMX writer as requested.

// Tested and working as of 10:30pm 12-3
module dmx_processor(
	input reset,
	input clk,
	input [8:0] pan_addr,
	input [8:0] tilt_addr,
	input [7:0] pan,
	input [7:0] tilt,
	input calc_ready,
	input [8:0] request_addr,
	input request_pulse,
	output reg [8:0] addr_out,
	output reg [7:0] data_out
	);
	
	// test light addressing for CH-6 setting
	// 1: pan (0 to 540 deg) ... this setting can and should be changed
	// 2: tilt (0 to 270 deg)
	// 3: color wheel (red is 112 to 127, so we choose 120)
	// 4: shutter ... unclear if this must be set or not
	// 5: dimmer (we set this to 100/255 below)
	// 6: gobo (0 is open, so we leave it as the default zero)
	
	// we save the most recent data
	reg [8:0] saved_pan_addr, saved_tilt_addr; 
	reg [8:0] saved_dimmer_addr, saved_color_addr;
	reg [7:0] saved_pan, saved_tilt;
	reg [7:0] saved_dimmer, saved_color;
	initial saved_pan_addr = 9'd0;
	initial saved_tilt_addr = 9'd0;
	initial saved_pan = 8'd0;
	initial saved_tilt = 8'd0;
	localparam DATA_ZERO = 8'd0; // should be zero

	always @(posedge clk) begin
		if (reset) begin
			// set everything to zero during reset
			saved_pan_addr <= 9'd0;
			saved_tilt_addr <= 9'd0;
			saved_pan <= 8'd0;
			saved_tilt <= 8'd0;
		end
		else begin
			// let calc updates and dmx request happen at the same time 
			if (calc_ready) begin
				// update the stored data when the input data changes
				saved_pan_addr <= pan_addr;
				saved_tilt_addr <= tilt_addr;
				saved_pan <= pan;
				saved_tilt <= tilt;
			end
			
			// if the write asks for data, send the data
			if (request_pulse) begin
				// send the correct output data
				if (request_addr == saved_pan_addr) 
					data_out <= saved_pan;
				else if (request_addr == saved_tilt_addr) 
					data_out <= saved_tilt;
				else data_out <= DATA_ZERO;
				// we overwrite some of this data with hardcoded data, so send
				// 	zero for now to be overwritten later
				
				// send the output address that goes with the sent data
				addr_out <= request_addr;
			end
		end
	end
endmodule
