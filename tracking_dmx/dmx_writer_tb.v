`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   20:54:01 12/03/2014
// Design Name:   dmx_writer
// Module Name:   /afs/athena.mit.edu/user/m/i/miren/Desktop/6.111/final project/dmxwriter/dmx_writer_tb.v
// Project Name:  dmxwriter
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: dmx_writer
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module dmx_writer_tb;

	// Inputs
	reg reset;
	reg clk;
	reg [8:0] pan_addr;
	reg [8:0] tilt_addr;
	reg [7:0] pan;
	reg [7:0] tilt;
	reg calc_ready;

	// Intermediate wires
	wire [8:0] request_addr;
	wire request_pulse;
	wire [8:0] addr;
	wire [7:0] data;

	// Outputs
	wire dmx_out;
	
	// Instantiate the Unit Under Test (UUT)
	dmx_writer uut (
		.reset(reset), 
		.clk(clk), 
		.addr(addr), 
		.data(data), 
		.dmx_out(dmx_out), 
		.request_addr(request_addr), 
		.request_pulse(request_pulse)
	);
	
	// Instantiate the Unit Under Test (UUT)
	dmx_processor uut1 (
		.reset(reset), 
		.clk(clk), 
		.pan_addr(pan_addr),
		.tilt_addr(tilt_addr),
		.pan(pan),
		.tilt(tilt),
		.calc_ready(calc_ready),
		.request_addr(request_addr), 
		.request_pulse(request_pulse), 
		.addr_out(addr), 
		.data_out(data)
	);
	
	always #1 clk=!clk;

	initial begin
		// Initialize Inputs
		reset = 0;
		clk = 0;
		pan_addr = 0;
		tilt_addr = 0;
		pan = 0;
		tilt = 0;
		calc_ready = 0;

		// Wait 100 ns for global reset to finish
		#5000;
        
		// Add stimulus here
		pan_addr = 1;
		pan = 53;
		#100;
		calc_ready = 1;
		#2;
		calc_ready = 0;
		
		#40000;
		tilt_addr = 2;
		tilt = 242;
		pan_addr = 4;
		pan = 170;
		#100;
		calc_ready = 1;
		#2;
		calc_ready = 0;
	end
      
endmodule

