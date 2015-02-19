// Miren Bamforth | A Motion-Tracking DMX512 Controller
// 6.111 Final Project | Fall 2014

// counts the transitions from high to low of vsync so that
// we store only every 6th frame
// vsync goes from low to high twice each frame
module frame_counter(
    input reset,
    input vsync_in,
    output reg frame_enable
    );

	// if we see vsync 10 times, we have seen 5 frames
	localparam 	COUNTER_MAX	= 5'd20;
	localparam 	COUNTER_HOLD = 5'd25;
	reg [4:0] counter = 5'd0;
	
	always@(posedge vsync_in) begin
		// reset everything on reset
		if (reset) begin
			counter <= 5'd0;
			frame_enable <= 1'b0;
		end
		// we hold the enable pulse high for two cycles
		else if (counter == COUNTER_HOLD) begin
			counter <= 5'd0;
			frame_enable <= 1'b0;
		end
		// this starts holding the enable pulse high
		else if (counter >= COUNTER_MAX) begin
			counter <= counter + 1;
			frame_enable <= 1'b1;
		end
		else begin
			counter <= counter + 1;
			frame_enable <= 1'b0;
		end
	end

endmodule
