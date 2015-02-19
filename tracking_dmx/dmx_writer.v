// Miren Bamforth | A Motion-Tracking DMX512 Controller
// 6.111 Final Project | Fall 2014

// This module writes DMX512 serial data out. It requests data from the DMX
// 	processor module. It is capped at a certain number of frames, but this
// 	could be expanded to the whole 512 frames.

// Tested and working as of 12-3 9:10pm
module dmx_writer(
	input reset,
	input clk,
	input [8:0] addr,
	input [7:0] data,
	output reg dmx_out,
	output reg [8:0] request_addr,
	output reg request_pulse
	);
	
	initial request_addr = 9'd0;
	initial request_pulse = 1'b0;
	
	// values for the dmx output
	localparam LOW = 1'b0;
	localparam HIGH = 1'b1;
	
	// values for the state
	localparam BREAK = 4'd0;
	localparam MAB = 4'd1;
	localparam START_CODE = 4'd2;
	localparam MTB_FRAMES = 4'd3;
	localparam CHANNEL_DATA = 4'd4;
	localparam MTB_PACKETS = 4'd5;
	localparam CD_HARDCODED = 4'd6;
	reg [3:0] state;
	initial state = BREAK;
	
	// Counter that deals with the incoming data from the processor
	// 	and the frames that are about to be transmitted
	reg [8:0] addr_count;
	// for now, we arbitrarily restrict ourselves to sending 12 frames at most
	// there is no zeroth frame, so we start at 1
	localparam ADDR_COUNT_MIN = 9'd1;
	localparam ADDR_COUNT_MAX = 9'd6;
	initial addr_count = ADDR_COUNT_MIN;
	
	// output from the data mux that chooses which dat to output
	reg [7:0] data_mux;
	initial data_mux = 8'd0;
	
	// various counters to control the duration of each state
	// break state counter
	reg [11:0] break_counter;
	localparam BREAK_COUNTER_MIN = 12'd0;
	localparam BREAK_COUNTER_MAX = 12'd2700;
	initial break_counter = BREAK_COUNTER_MIN;
	// mark after break state counter
	reg [8:0] mab_counter;
	localparam MAB_COUNTER_MIN = 9'd0;
	localparam MAB_COUNTER_MAX = 9'd270;
	initial mab_counter = MAB_COUNTER_MIN;
	// start code state counter
	reg [3:0] sc_counter;
	localparam SC_COUNTER_MIN = 4'd0;
	initial sc_counter = SC_COUNTER_MIN;
	// mark time between frames state counter
	reg [8:0] mtbframes_counter;
	localparam MTBFRAMES_COUNTER_MIN = 9'd0;
	localparam MTBFRAMES_COUNTER_MAX = 9'd270;
	initial mtbframes_counter = MTBFRAMES_COUNTER_MIN;
	// 4us counter used in a few places
	reg [7:0] four_us_counter;
	localparam FOUR_US_COUNTER_MIN = 9'd0;
	localparam FOUR_US_COUNTER_MAX = 9'd108;
	initial four_us_counter = FOUR_US_COUNTER_MIN;
	// channel data state counter
	reg [3:0] cd_counter;
	localparam CD_COUNTER_MIN = 4'd0;
	initial cd_counter = CD_COUNTER_MIN;
	// mark time between packets state counter
	reg [11:0] mtbpackets_counter;
	localparam MTBPACKETS_COUNTER_MIN = 12'd0;
	localparam MTBPACKETS_COUNTER_MAX = 12'd2700;
	initial mtbpackets_counter = MTBPACKETS_COUNTER_MIN;
	
	// always block controls dmx output
	always @(posedge clk) begin
		if (reset) begin
			state <= BREAK;
		end
		else begin
			case(state)
				BREAK: begin
					// hold low for 88 us to 1 sec
					// choose 100 us which is approx. 2700 cycles at 27MHz
					if (break_counter < BREAK_COUNTER_MAX) begin
						// dmx_out is low during break
						dmx_out <= LOW;
						break_counter <= break_counter + 1;
					end
					else begin
						// once we have waited for long enough, go to next state
						state <= MAB;
						break_counter <= BREAK_COUNTER_MIN;
						dmx_out <= HIGH;
					end
				end
				MAB: begin
					// hold high for 8us to 1 sec
					// choose 10 us which is approx. 270 cycles at 27MHz
					if (mab_counter < MAB_COUNTER_MAX) begin
						// dmx is high during mark after break
						dmx_out <= HIGH;
						mab_counter <= mab_counter + 1;
					end
					else begin
						// once we have waited long enough, go to next state
						state <= START_CODE;
						mab_counter <= MAB_COUNTER_MIN;
						// keep it high for now; the next state will change it
						dmx_out <= HIGH;
						// reset 4us counter too
						four_us_counter <= FOUR_US_COUNTER_MIN;
					end
				end
				START_CODE: begin
					// The start code is formatted like the channel data with a
					// 	value of zero. In order, its bits are: 0_0000_0000_11.
					// 	The first bit is the start bit (low) and the last two
					// 	bits are stop bits (high).
					// The total start code is 44us, so each bit is held for 4us
					
					// only change the counter every 4us
					if (four_us_counter == FOUR_US_COUNTER_MAX) begin
						sc_counter <= sc_counter + 1;
						four_us_counter <= FOUR_US_COUNTER_MIN;
					end
					else four_us_counter <= four_us_counter + 1;
					
					// dmx_out control
					if (sc_counter < 4'd9) begin
						// bits 0 to 8 are low
						dmx_out <= LOW;
					end
					else if (sc_counter == 4'd9) begin
						// bit 9 is high
						dmx_out <= HIGH;
					end
					else if (sc_counter == 4'd10) begin
						// bit 10 is high
						// go to the next state
						dmx_out <= HIGH;
						sc_counter <= SC_COUNTER_MIN;
						state <= MTB_FRAMES;
					end
				end
				MTB_FRAMES: begin
					// The mark between frames is up to 1 second long
					// choose 10 us which is approx. 270 cycles at 27MHz
					if (mtbframes_counter < MTBFRAMES_COUNTER_MAX) begin
						// dmx is high during mark time between frames
						dmx_out <= HIGH;
						
						// request the data for the next channel data output now
						if (mtbframes_counter == MTBFRAMES_COUNTER_MIN) begin
							// if we have sent all of the frames already, go to 
							// 	the mtb_packets state
							if (addr_count == ADDR_COUNT_MAX) begin
								mtbframes_counter <= MTBFRAMES_COUNTER_MIN;
								addr_count <= ADDR_COUNT_MIN;
								state <= MTB_PACKETS;
							end
							else begin
								request_pulse <= HIGH;
								request_addr <= addr_count;
								addr_count <= addr_count + 1;
								mtbframes_counter <= mtbframes_counter + 1;
							end
						end
						else begin
							request_pulse <= LOW;
							mtbframes_counter <= mtbframes_counter + 1;
						end
					end
					else begin
						// once we have waited long enough, go to next state
						// go the correct state depending on the address
						if (addr_count == 9'd4 || addr_count == 9'd5 ||
								addr_count == 9'd6)
							state <= CD_HARDCODED;
						else
							state <= CHANNEL_DATA;
						mtbframes_counter <= MTBFRAMES_COUNTER_MIN;
						// keep it high for now; the next state will change it
						dmx_out <= HIGH;
						// reset 4us counter too
						four_us_counter <= FOUR_US_COUNTER_MIN;
					end
				end
				CHANNEL_DATA: begin
					// The channel data has one start bit (low), 8 data bits
					// 	from LSB to MSB, and two stop bits (high) in that 
					// 	order. The whole frame takes 44us, so each bit is 
					// 	held for 4us.
					// This state outputs data when it is from the dmx processor
					
					// only change the counter every 4us
					if (four_us_counter == FOUR_US_COUNTER_MAX) begin
						cd_counter <= cd_counter + 1;
						four_us_counter <= FOUR_US_COUNTER_MIN;
					end
					else four_us_counter <= four_us_counter + 1;
					
					// dmx_out control
					// data has already been loaded with the next frame
					case (cd_counter)
						4'd0: dmx_out <= LOW; // bit 0 is low
						4'd1: dmx_out <= data[0];
						4'd2: dmx_out <= data[1];
						4'd3: dmx_out <= data[2];
						4'd4: dmx_out <= data[3];
						4'd5: dmx_out <= data[4];
						4'd6: dmx_out <= data[5];
						4'd7: dmx_out <= data[6];
						4'd8: dmx_out <= data[7];
						4'd9: dmx_out <= HIGH; // bit 9 is high
						4'd10: dmx_out <= HIGH; // bit 10 is high
						4'd11: begin
							// go to the next state
							cd_counter <= CD_COUNTER_MIN;
							four_us_counter <= FOUR_US_COUNTER_MIN;
							// go back to mtb frames, and we will decided whether to
							// 	go to mtb packets there
							state <= MTB_FRAMES;
						end
					endcase
				end
				CD_HARDCODED: begin
					// this is exactly like channel data state, but it gets its
					// 	data from hardcoded info, not the processor block
					
					// only change the counter every 4us
					if (four_us_counter == FOUR_US_COUNTER_MAX) begin
						cd_counter <= cd_counter + 1;
						four_us_counter <= FOUR_US_COUNTER_MIN;
					end
					else four_us_counter <= four_us_counter + 1;
					
					// select the data that we want to output
					// we use this to output hardcoded data that was failing
					// 	in the dmx_processor if/else block
					// 3: color wheel (red is ~90)
					// 4: shutter must be open, so it has a value of 254
					// 5: dimmer (we set this to 100/255 below)
					// the address count has already been incremented, so the 
					// 	addresses are off by one
					if (four_us_counter == FOUR_US_COUNTER_MAX &&
							cd_counter == CD_COUNTER_MIN) begin
						if (addr_count == 9'd4) data_mux <= 8'd90;
						else if (addr_count == 9'd5) data_mux <= 8'd254;
						else if (addr_count == 9'd6) data_mux <= 8'd160;
						else data_mux <= data;
					end
					
					// dmx_out control
					// data has already been loaded with the next frame
					case (cd_counter)
						4'd0: dmx_out <= LOW; // bit 0 is low
						4'd1: dmx_out <= data_mux[0];
						4'd2: dmx_out <= data_mux[1];
						4'd3: dmx_out <= data_mux[2];
						4'd4: dmx_out <= data_mux[3];
						4'd5: dmx_out <= data_mux[4];
						4'd6: dmx_out <= data_mux[5];
						4'd7: dmx_out <= data_mux[6];
						4'd8: dmx_out <= data_mux[7];
						4'd9: dmx_out <= HIGH; // bit 9 is high
						4'd10: dmx_out <= HIGH; // bit 10 is high
						4'd11: begin
							// go to the next state
							cd_counter <= CD_COUNTER_MIN;
							four_us_counter <= FOUR_US_COUNTER_MIN;
							// go back to mtb frames, and we will decided whether to
							// 	go to mtb packets there
							state <= MTB_FRAMES;
						end
					endcase
				end
				MTB_PACKETS: begin
					// mark time between packets is up to 1 second
					// choose 100us which is approx. 2700 cycles at 27MHz
					if (mtbpackets_counter < MTBPACKETS_COUNTER_MAX) begin
						// dmx_out is low during break
						dmx_out <= HIGH;
						mtbpackets_counter <= mtbpackets_counter + 1;
					end
					else begin
						// once we have waited for long enough, go to next state
						state <= BREAK;
						mtbpackets_counter <= MTBPACKETS_COUNTER_MIN;
						dmx_out <= LOW;
					end
				end
				default: begin
					// treat default kind of like a reset
					state <= BREAK;
				end
			endcase
		end
	end
endmodule
