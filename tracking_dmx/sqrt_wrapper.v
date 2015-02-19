`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:29:04 11/30/2014 
// Design Name: 
// Module Name:    sqrt_wrapper 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module sqrt_wrapper(
    input reset,
    input clk,
    input [21:0] in,
    output [11:0] out,
	 output ready
    );
	 
	 tilt_sqrt my_tilt_sqrt (
		.x_in(in), // input [21 : 0] x_in
		.x_out(out), // output [11 : 0] x_out
		.rdy(ready), // output rdy
		.clk(clk) // input clk
		);


endmodule
