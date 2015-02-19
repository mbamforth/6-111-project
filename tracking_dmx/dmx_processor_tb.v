`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   20:41:05 12/03/2014
// Design Name:   dmx_processor
// Module Name:   /afs/athena.mit.edu/user/m/i/miren/Desktop/6.111/final project/dmxwriter/dmx_processor_tb.v
// Project Name:  dmxwriter
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: dmx_processor
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module dmx_processor_tb;

	// Inputs
	reg reset;
	reg clk;
	reg [8:0] request_addr;
	reg request_pulse;
	reg [8:0] pan_addr,
	reg [8:0] tilt_addr,
	reg [7:0] pan,
	reg [7:0] tilt,
	reg calc_ready,

	// Outputs
	wire [8:0] addr_out;
	wire [7:0] data_out;

	// Instantiate the Unit Under Test (UUT)
	dmx_processor uut (
		.reset(reset), 
		.clk(clk), 
		.pan_addr(pan_addr),
		.tilt_addr(tilt_addr),
		.pan(pan),
		.tilt(tilt),
		.calc_ready(calc_ready),
		.request_addr(request_addr), 
		.request_pulse(request_pulse), 
		.addr_out(addr_out), 
		.data_out(data_out)
	);
	
	always #5 clk=!clk;

	initial begin
		// Initialize Inputs
		reset = 0;
		clk = 0;
		request_addr = 0;
		request_pulse = 0;
		pan_addr = 0;
		tilt_addr = 0;
		pan = 0;
		tilt = 0;
		calc_ready = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		request_addr = 2;
		#50;
		request_pulse = 1;
		#10;
		request_pulse = 0;
		#50;
		
		request_addr = 1;
		#50;
		request_pulse = 1;
		#10;
		request_pulse = 0;
		#50;
		
		request_addr = 3;
		#50;
		request_pulse = 1;
		#10;
		request_pulse = 0;
		#50;
	end
      
endmodule


