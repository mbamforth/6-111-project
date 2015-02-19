// Miren Bamforth | A Motion-Tracking DMX512 Controller
// 6.111 Final Project | Fall 2014
// This code was modified from code on the 6.111 website.

//
// File:   zbt_6111_sample.v
// Date:   26-Nov-05
// Author: I. Chuang <ichuang@mit.edu>
//
// Sample code for the MIT 6.111 labkit demonstrating use of the ZBT
// memories for video display.  Video input from the NTSC digitizer is
// displayed within an XGA 1024x768 window.  One ZBT memory (ram0) is used
// as the video frame buffer, with 8 bits used per pixel (black & white).
//
// Since the ZBT is read once for every four pixels, this frees up time for 
// data to be stored to the ZBT during other pixel times.  The NTSC decoder
// runs at 27 MHz, whereas the XGA runs at 65 MHz, so we synchronize
// signals between the two (see ntsc2zbt.v) and let the NTSC data be
// stored to ZBT memory whenever it is available, during cycles when
// pixel reads are not being performed.
//
// We use a very simple ZBT interface, which does not involve any clock
// generation or hiding of the pipelining.  See zbt_6111.v for more info.
//
// switch[7] selects between display of NTSC video and test bars
// switch[6] is used for testing the NTSC decoder
// switch[1] selects between test bar periods; these are stored to ZBT
//           during blanking periods
// switch[0] selects vertical test bars (hardwired; not stored in ZBT)
//
//
// Bug fix: Jonathan P. Mailoa <jpmailoa@mit.edu>
// Date   : 11-May-09
//
// Use ramclock module to deskew clocks;  GPH
// To change display from 1024*787 to 800*600, use clock_40mhz and change
// accordingly. Verilog ntsc2zbt.v will also need changes to change resolution.
//
// Date   : 10-Nov-11

///////////////////////////////////////////////////////////////////////////////
//
// 6.111 FPGA Labkit -- Template Toplevel Module
//
// For Labkit Revision 004
//
//
// Created: October 31, 2004, from revision 003 file
// Author: Nathan Ickes
//
///////////////////////////////////////////////////////////////////////////////
//
// CHANGES FOR BOARD REVISION 004
//
// 1) Added signals for logic analyzer pods 2-4.
// 2) Expanded "tv_in_ycrcb" to 20 bits.
// 3) Renamed "tv_out_data" to "tv_out_i2c_data" and "tv_out_sclk" to
//    "tv_out_i2c_clock".
// 4) Reversed disp_data_in and disp_data_out signals, so that "out" is an
//    output of the FPGA, and "in" is an input.
//
// CHANGES FOR BOARD REVISION 003
//
// 1) Combined flash chip enables into a single signal, flash_ce_b.
//
// CHANGES FOR BOARD REVISION 002
//
// 1) Added SRAM clock feedback path input and output
// 2) Renamed "mousedata" to "mouse_data"
// 3) Renamed some ZBT memory signals. Parity bits are now incorporated into 
//    the data bus, and the byte write enables have been combined into the
//    4-bit ram#_bwe_b bus.
// 4) Removed the "systemace_clock" net, since the SystemACE clock is now
//    hardwired on the PCB to the oscillator.
//
///////////////////////////////////////////////////////////////////////////////
//
// Complete change history (including bug fixes)
//
// 2011-Nov-10: Changed resolution to 1024 * 768.
//					 Added back ramclok to deskew RAM clock
//
// 2009-May-11: Fixed memory management bug by 8 clock cycle forecast. 
//              Changed resolution to  800 * 600.
//              Reduced clock speed to 40MHz.
//              Disconnected zbt_6111's ram_clk signal. 
//              Added ramclock to control RAM.
//              Added notes about ram1 default values.
//              Commented out clock_feedback_out assignment.
//              Removed delayN modules because ZBT's latency has no more effect.
//
// 2005-Sep-09: Added missing default assignments to "ac97_sdata_out",
//              "disp_data_out", "analyzer[2-3]_clock" and
//              "analyzer[2-3]_data".
//
// 2005-Jan-23: Reduced flash address bus to 24 bits, to match 128Mb devices
//              actually populated on the boards. (The boards support up to
//              256Mb devices, with 25 address lines.)
//
// 2004-Oct-31: Adapted to new revision 004 board.
//
// 2004-May-01: Changed "disp_data_in" to be an output, and gave it a default
//              value. (Previous versions of this file declared this port to
//              be an input.)
//
// 2004-Apr-29: Reduced SRAM address busses to 19 bits, to match 18Mb devices
//              actually populated on the boards. (The boards support up to
//              72Mb devices, with 21 address lines.)
//
// 2004-Apr-29: Change history started
//
///////////////////////////////////////////////////////////////////////////////

module labkit(beep, audio_reset_b, 
		       ac97_sdata_out, ac97_sdata_in, ac97_synch,
	       ac97_bit_clock,
	       
	       vga_out_red, vga_out_green, vga_out_blue, vga_out_sync_b,
	       vga_out_blank_b, vga_out_pixel_clock, vga_out_hsync,
	       vga_out_vsync,

	       tv_out_ycrcb, tv_out_reset_b, tv_out_clock, tv_out_i2c_clock,
	       tv_out_i2c_data, tv_out_pal_ntsc, tv_out_hsync_b,
	       tv_out_vsync_b, tv_out_blank_b, tv_out_subcar_reset,

	       tv_in_ycrcb, tv_in_data_valid, tv_in_line_clock1,
	       tv_in_line_clock2, tv_in_aef, tv_in_hff, tv_in_aff,
	       tv_in_i2c_clock, tv_in_i2c_data, tv_in_fifo_read,
	       tv_in_fifo_clock, tv_in_iso, tv_in_reset_b, tv_in_clock,

	       ram0_data, ram0_address, ram0_adv_ld, ram0_clk, ram0_cen_b,
	       ram0_ce_b, ram0_oe_b, ram0_we_b, ram0_bwe_b, 

	       ram1_data, ram1_address, ram1_adv_ld, ram1_clk, ram1_cen_b,
	       ram1_ce_b, ram1_oe_b, ram1_we_b, ram1_bwe_b,

	       clock_feedback_out, clock_feedback_in,

	       flash_data, flash_address, flash_ce_b, flash_oe_b, flash_we_b,
	       flash_reset_b, flash_sts, flash_byte_b,

	       rs232_txd, rs232_rxd, rs232_rts, rs232_cts,

	       mouse_clock, mouse_data, keyboard_clock, keyboard_data,

	       clock_27mhz, clock1, clock2,

	       disp_blank, disp_data_out, disp_clock, disp_rs, disp_ce_b,
	       disp_reset_b, disp_data_in,

	       button0, button1, button2, button3, button_enter, button_right,
	       button_left, button_down, button_up,

	       switch,

	       led,
	       
	       user1, user2, user3, user4,
	       
	       daughtercard,

	       systemace_data, systemace_address, systemace_ce_b,
	       systemace_we_b, systemace_oe_b, systemace_irq, systemace_mpbrdy,
	       
	       analyzer1_data, analyzer1_clock,
 	       analyzer2_data, analyzer2_clock,
 	       analyzer3_data, analyzer3_clock,
 	       analyzer4_data, analyzer4_clock);

   output beep, audio_reset_b, ac97_synch, ac97_sdata_out;
   input  ac97_bit_clock, ac97_sdata_in;
   
   output [7:0] vga_out_red, vga_out_green, vga_out_blue;
   output vga_out_sync_b, vga_out_blank_b, vga_out_pixel_clock,
	  vga_out_hsync, vga_out_vsync;

   output [9:0] tv_out_ycrcb;
   output tv_out_reset_b, tv_out_clock, tv_out_i2c_clock, tv_out_i2c_data,
	  tv_out_pal_ntsc, tv_out_hsync_b, tv_out_vsync_b, tv_out_blank_b,
	  tv_out_subcar_reset;
   
   input  [19:0] tv_in_ycrcb;
   input  tv_in_data_valid, tv_in_line_clock1, tv_in_line_clock2, tv_in_aef,
	  tv_in_hff, tv_in_aff;
   output tv_in_i2c_clock, tv_in_fifo_read, tv_in_fifo_clock, tv_in_iso,
	  tv_in_reset_b, tv_in_clock;
   inout  tv_in_i2c_data;
        
   inout  [35:0] ram0_data;
   output [18:0] ram0_address;
   output ram0_adv_ld, ram0_clk, ram0_cen_b, ram0_ce_b, ram0_oe_b, ram0_we_b;
   output [3:0] ram0_bwe_b;
   
   inout  [35:0] ram1_data;
   output [18:0] ram1_address;
   output ram1_adv_ld, ram1_clk, ram1_cen_b, ram1_ce_b, ram1_oe_b, ram1_we_b;
   output [3:0] ram1_bwe_b;

   input  clock_feedback_in;
   output clock_feedback_out;
   
   inout  [15:0] flash_data;
   output [23:0] flash_address;
   output flash_ce_b, flash_oe_b, flash_we_b, flash_reset_b, flash_byte_b;
   input  flash_sts;
   
   output rs232_txd, rs232_rts;
   input  rs232_rxd, rs232_cts;

   input  mouse_clock, mouse_data, keyboard_clock, keyboard_data;

   input  clock_27mhz, clock1, clock2;

   output disp_blank, disp_clock, disp_rs, disp_ce_b, disp_reset_b;  
   input  disp_data_in;
   output  disp_data_out;
   
   input  button0, button1, button2, button3, button_enter, button_right,
	  button_left, button_down, button_up;
   input  [7:0] switch;
   output [7:0] led;

   inout [31:0] user1, user2, user3, user4;
   
   inout [43:0] daughtercard;

   inout  [15:0] systemace_data;
   output [6:0]  systemace_address;
   output systemace_ce_b, systemace_we_b, systemace_oe_b;
   input  systemace_irq, systemace_mpbrdy;

   output [15:0] analyzer1_data, analyzer2_data, analyzer3_data, 
		 analyzer4_data;
   output analyzer1_clock, analyzer2_clock, analyzer3_clock, analyzer4_clock;

   ////////////////////////////////////////////////////////////////////////////
   //
   // I/O Assignments
   //
   ////////////////////////////////////////////////////////////////////////////
   
   // Audio Input and Output
   assign beep= 1'b0;
   assign audio_reset_b = 1'b0;
   assign ac97_synch = 1'b0;
   assign ac97_sdata_out = 1'b0;
/*
*/
   // ac97_sdata_in is an input

   // Video Output
   assign tv_out_ycrcb = 10'h0;
   assign tv_out_reset_b = 1'b0;
   assign tv_out_clock = 1'b0;
   assign tv_out_i2c_clock = 1'b0;
   assign tv_out_i2c_data = 1'b0;
   assign tv_out_pal_ntsc = 1'b0;
   assign tv_out_hsync_b = 1'b1;
   assign tv_out_vsync_b = 1'b1;
   assign tv_out_blank_b = 1'b1;
   assign tv_out_subcar_reset = 1'b0;
   
   // Video Input
   //assign tv_in_i2c_clock = 1'b0;
   assign tv_in_fifo_read = 1'b1;
   assign tv_in_fifo_clock = 1'b0;
   assign tv_in_iso = 1'b1;
   //assign tv_in_reset_b = 1'b0;
   assign tv_in_clock = clock_27mhz;//1'b0;
   //assign tv_in_i2c_data = 1'bZ;
   // tv_in_ycrcb, tv_in_data_valid, tv_in_line_clock1, tv_in_line_clock2, 
   // tv_in_aef, tv_in_hff, and tv_in_aff are inputs
   
   // SRAMs

/* change lines below to enable ZBT RAM bank0 */

/*
   assign ram0_data = 36'hZ;
   assign ram0_address = 19'h0;
   assign ram0_clk = 1'b0;
   assign ram0_we_b = 1'b1;
   assign ram0_cen_b = 1'b0;	// clock enable
*/

/* enable RAM pins */

   assign ram0_ce_b = 1'b0;
   assign ram0_oe_b = 1'b0;
   assign ram0_adv_ld = 1'b0;
   assign ram0_bwe_b = 4'h0; 

/**********/

   assign ram1_data = 36'hZ; 
   assign ram1_address = 19'h0;
   assign ram1_adv_ld = 1'b0;
   assign ram1_clk = 1'b0;
   
   //These values has to be set to 0 like ram0 if ram1 is used.
   assign ram1_cen_b = 1'b1;
   assign ram1_ce_b = 1'b1;
   assign ram1_oe_b = 1'b1;
   assign ram1_we_b = 1'b1;
   assign ram1_bwe_b = 4'hF;

   // clock_feedback_out will be assigned by ramclock
   // assign clock_feedback_out = 1'b0;  //2011-Nov-10
   // clock_feedback_in is an input
   
   // Flash ROM
   assign flash_data = 16'hZ;
   assign flash_address = 24'h0;
   assign flash_ce_b = 1'b1;
   assign flash_oe_b = 1'b1;
   assign flash_we_b = 1'b1;
   assign flash_reset_b = 1'b0;
   assign flash_byte_b = 1'b1;
   // flash_sts is an input

   // RS-232 Interface
   assign rs232_txd = 1'b1;
   assign rs232_rts = 1'b1;
   // rs232_rxd and rs232_cts are inputs

   // PS/2 Ports
   // mouse_clock, mouse_data, keyboard_clock, and keyboard_data are inputs

   // LED Displays
/*
   assign disp_blank = 1'b1;
   assign disp_clock = 1'b0;
   assign disp_rs = 1'b0;
   assign disp_ce_b = 1'b1;
   assign disp_reset_b = 1'b0;
   assign disp_data_out = 1'b0;
*/
   // disp_data_in is an input

   // Buttons, Switches, and Individual LEDs
   //lab3 assign led = 8'hFF;
   // button0, button1, button2, button3, button_enter, button_right,
   // button_left, button_down, button_up, and switches are inputs

   // User I/Os
   assign user1 = 32'hZ;
   assign user2 = 32'hZ;
   assign user3 = 32'hZ;
   assign user4[30:0] = 31'hZ;

   // Daughtercard Connectors
   assign daughtercard = 44'hZ;

   // SystemACE Microprocessor Port
   assign systemace_data = 16'hZ;
   assign systemace_address = 7'h0;
   assign systemace_ce_b = 1'b1;
   assign systemace_we_b = 1'b1;
   assign systemace_oe_b = 1'b1;
   // systemace_irq and systemace_mpbrdy are inputs

   // Logic Analyzer
   assign analyzer1_data = 16'h0;
   assign analyzer1_clock = 1'b1;
   assign analyzer2_data = 16'h0;
   assign analyzer2_clock = 1'b1;
   assign analyzer3_data = 16'h0;
   assign analyzer3_clock = 1'b1;
   assign analyzer4_data = 16'h0;
   assign analyzer4_clock = 1'b1;
			    
	///////////////////////////
	// Clock and Reset Setup //
	///////////////////////////

    ////////////////////////////////////////////////////////////////////////////
    // Demonstration of ZBT RAM as video memory

    // use FPGA's digital clock manager to produce a
    // 65MHz clock (actually 64.8MHz)
    wire clock_65mhz_unbuf,clock_65mhz;
    DCM vclk1(.CLKIN(clock_27mhz),.CLKFX(clock_65mhz_unbuf));
    // synthesis attribute CLKFX_DIVIDE of vclk1 is 10
    // synthesis attribute CLKFX_MULTIPLY of vclk1 is 24
    // synthesis attribute CLK_FEEDBACK of vclk1 is NONE
    // synthesis attribute CLKIN_PERIOD of vclk1 is 37
    BUFG vclk2(.O(clock_65mhz),.I(clock_65mhz_unbuf));

//   wire clk = clock_65mhz;  // gph 2011-Nov-10

/*   ////////////////////////////////////////////////////////////////////////////
    // Demonstration of ZBT RAM as video memory

    // use FPGA's digital clock manager to produce a
    // 40MHz clock (actually 40.5MHz)
    wire clock_40mhz_unbuf,clock_40mhz;
    DCM vclk1(.CLKIN(clock_27mhz),.CLKFX(clock_40mhz_unbuf));
    // synthesis attribute CLKFX_DIVIDE of vclk1 is 2
    // synthesis attribute CLKFX_MULTIPLY of vclk1 is 3
    // synthesis attribute CLK_FEEDBACK of vclk1 is NONE
    // synthesis attribute CLKIN_PERIOD of vclk1 is 37
    BUFG vclk2(.O(clock_40mhz),.I(clock_40mhz_unbuf));

    wire clk = clock_40mhz;
    */
    wire locked;
    //assign clock_feedback_out = 0; // gph 2011-Nov-10

    ramclock rc(.ref_clock(clock_65mhz), .fpga_clock(clk),
                    .ram0_clock(ram0_clk), 
                    //.ram1_clock(ram1_clk),   //uncomment if ram1 is used
                    .clock_feedback_in(clock_feedback_in),
                    .clock_feedback_out(clock_feedback_out), .locked(locked));


    // power-on reset generation
    wire power_on_reset;    // remain high for first 16 clocks
    SRL16 reset_sr (.D(1'b0), .CLK(clk), .Q(power_on_reset),
           .A0(1'b1), .A1(1'b1), .A2(1'b1), .A3(1'b1));
    defparam reset_sr.INIT = 16'hFFFF;

    // ENTER button is user reset
    wire reset,user_reset;
    debounce db1(power_on_reset, clk, ~button_enter, user_reset);
    assign reset = user_reset | power_on_reset;

	////////////////////////////////////////////////////////////////
	// Configuration of the switches:   
	// switch[0]: turns on cursor that follows the center of mass
	// switch[1]: turns on moveable cursor
    // 1 + 2: turns on HSV view
	// switch[2]: squishes video
	// switch[3]: changes from video input to black
	// switch[4]: 
	// switch[5]: 
	// switch[6]: 
	// switch[7]: 
	////////////////////////////////////////////////////////////////

	//////////////////////////////////////
	// High-level Motion Tracking Block //
	//////////////////////////////////////

	// ADV7185 NTSC decoder interface code
    // adv7185 initialization module
    adv7185init adv7185(.reset(reset), .clock_27mhz(clock_27mhz), 
		       .source(1'b0), .tv_in_reset_b(tv_in_reset_b), 
		       .tv_in_i2c_clock(tv_in_i2c_clock), 
		       .tv_in_i2c_data(tv_in_i2c_data));
				 
    // takes digital NTSC data and creates YCrCb data
    wire [29:0] ycrcb;	// video data (luminance, chrominance)
    wire [2:0] fvh;	// sync for field, vertical, horizontal
    wire       dv;	// data valid
    ntsc_decode decode (.clk(tv_in_line_clock1), .reset(reset),
               .tv_in_ycrcb(tv_in_ycrcb[19:10]), 
               .ycrcb(ycrcb), .f(fvh[2]),
               .v(fvh[1]), .h(fvh[0]), .data_valid(dv));

    // changes YCrCb to RGB
	wire [23:0] rgb;
	YCrCb2RGB color ( .R(rgb[23:16]), .G(rgb[15:8]), .B(rgb[7:0]), 
					.clk(tv_in_line_clock1) , .rst(reset), 
					.Y(ycrcb[29:20]), .Cr(ycrcb[19:10]), .Cb(ycrcb[9:0]) );

	// delays because YCrCb takes 3 cycles
	// delay fvh[2:0]
	wire [2:0] fvh_del;
	delayN delay1 (.clk(tv_in_line_clock1),.in(fvh[2]),.out(fvh_del[2]));
	delayN delay2 (.clk(tv_in_line_clock1),.in(fvh[1]),.out(fvh_del[1]));
	delayN delay3 (.clk(tv_in_line_clock1),.in(fvh[0]),.out(fvh_del[0]));
	// delay dv
	wire dv_del;
	delayN delay4 (.clk(tv_in_line_clock1),.in(dv),.out(dv_del));

    // writes RGB data to ZBT memory
    // drops the lowest two bits of R, G, & B for better memory utilization
    wire [18:0] ntsc_addr;
    wire [35:0] ntsc_data;
    wire        ntsc_we;
    ntsc_to_zbt n2z (clk, tv_in_line_clock1, fvh_del, dv_del, 
            {rgb[23:18], rgb[15:10], rgb[7:2]},
            ntsc_addr, ntsc_data, ntsc_we, switch[2]);

    // wire NTSC reader to ZBT ram
    wire [35:0] vram_write_data;
    wire [35:0] vram_read_data;
    wire [18:0] vram_addr;
    wire        vram_we;
    wire ram0_clk_not_used;
    zbt_6111 zbt1(clk, 1'b1, vram_we, vram_addr,
           vram_write_data, frame_enable, vram_read_data,
           ram0_clk_not_used,   //to get good timing, don't connect ram_clk to zbt_6111
           ram0_we_b, ram0_address, ram0_data, ram0_cen_b);

    // generate basic XVGA video signals
    wire [10:0] hcount;
    wire [9:0]  vcount;
    wire hsync,vsync,blank;
    xvga xvga1(clk,hcount,vcount,hsync,vsync,blank);

    // generate pixel value from reading ZBT memory
	wire [17:0] 	vr_pixel;
    wire [18:0] 	vram_addr1;
    vram_display vd1(reset,clk,hcount,vcount,vr_pixel,
		    vram_addr1,vram_read_data);
			 
	// RGB from memory to HSV for use in tracker module
	wire [23:0] hsv;
	rgb2hsv find_hue (.clock(clk), 
							.reset(reset), 
							.r({vr_pixel[17:12], 2'b00}), 
							.g({vr_pixel[11:6], 2'b00}), 
							.b({vr_pixel[5:0], 2'b00}), 
							.h(hsv[23:16]), .s(hsv[15:8]), 
							.v(hsv[7:0]));
	
	// delay hcount and vcount so the color_tracker can use hsv correctly
	// hsv uses 22 clock cycles because of dividers
	wire [10:0] hcount_del;
    wire [9:0]  vcount_del;
	delayN#(22) delayh0 (.clk(clk),.in(hcount[0]),.out(hcount_del[0]));
	delayN#(22) delayh1 (.clk(clk),.in(hcount[1]),.out(hcount_del[1]));
	delayN#(22) delayh2 (.clk(clk),.in(hcount[2]),.out(hcount_del[2]));
	delayN#(22) delayh3 (.clk(clk),.in(hcount[3]),.out(hcount_del[3]));
	delayN#(22) delayh4 (.clk(clk),.in(hcount[4]),.out(hcount_del[4]));
	delayN#(22) delayh5 (.clk(clk),.in(hcount[5]),.out(hcount_del[5]));
	delayN#(22) delayh6 (.clk(clk),.in(hcount[6]),.out(hcount_del[6]));
	delayN#(22) delayh7 (.clk(clk),.in(hcount[7]),.out(hcount_del[7]));
	delayN#(22) delayh8 (.clk(clk),.in(hcount[8]),.out(hcount_del[8]));
	delayN#(22) delayh9 (.clk(clk),.in(hcount[9]),.out(hcount_del[9]));
	delayN#(22) delayh10 (.clk(clk),.in(hcount[10]),.out(hcount_del[10]));
	
	delayN#(22) delayv0 (.clk(clk),.in(vcount[0]),.out(vcount_del[0]));
	delayN#(22) delayv1 (.clk(clk),.in(vcount[1]),.out(vcount_del[1]));
	delayN#(22) delayv2 (.clk(clk),.in(vcount[2]),.out(vcount_del[2]));
	delayN#(22) delayv3 (.clk(clk),.in(vcount[3]),.out(vcount_del[3]));
	delayN#(22) delayv4 (.clk(clk),.in(vcount[4]),.out(vcount_del[4]));
	delayN#(22) delayv5 (.clk(clk),.in(vcount[5]),.out(vcount_del[5]));
	delayN#(22) delayv6 (.clk(clk),.in(vcount[6]),.out(vcount_del[6]));
	delayN#(22) delayv7 (.clk(clk),.in(vcount[7]),.out(vcount_del[7]));
	delayN#(22) delayv8 (.clk(clk),.in(vcount[8]),.out(vcount_del[8]));
	delayN#(22) delayv9 (.clk(clk),.in(vcount[9]),.out(vcount_del[9]));
	
	// delay hsync, vsync, and blank too for use in the HSV view mode
	wire hsync_del, vsync_del, blank_del;
	delayN#(22) delayhsync (.clk(clk),.in(hsync),.out(hsync_del));
	delayN#(22) delayvsync (.clk(clk),.in(vsync),.out(vsync_del));
	delayN#(22) delayblank (.clk(clk),.in(blank),.out(blank_del));
	
	// motion/color tracker module
	// TODO: consider attaching low/high to switches
	// low has to not be equal to zero or all of the black 
	//	  background will be tracked
	wire [7:0] low, high;
	assign low = 8'hEB;
	assign high = 8'hFA;
	wire [10:0] x_com;
	wire [9:0] y_com;
	wire data_ready;
	
	// the tracking module takes in all pixels being sent to
    // the VGA output and finds the center of mass of all pixels
    // of a certain color
	tracker color_tracker(.clk(clk), .reset(reset),
			.hcount(hcount_del), .vcount(vcount_del), .hsv(hsv),
			.low(low), .high(high), .x_com(x_com),
			.y_com(y_com), .data_ready(data_ready));
	
	// output wires for the motion calculation module
	wire [7:0] pan_out, tilt_out;
	wire [8:0] pan_address, tilt_address;
	
	// wires from the calibration block, must be here because verilog
	wire [10:0] x_real_world;
	wire [9:0] y_real_world;
	wire [11:0] z_real_world;
	wire [10:0] x_light1;
	wire [9:0] y_light1;
	wire [8:0] pan_addr_light1, tilt_addr_light1;
	
    // the values that come out of the mux and into the calculator
	reg [10:0] x_com_in;
	reg [9:0] y_com_in;
	
	// cursor movement block wires must be up here
	reg [10:0] cursor_x;
	reg [9:0] cursor_y;
	initial cursor_x = 11'd0;
	initial cursor_y = 10'd0;
	reg [10:0] x_pos;
	reg [9:0] y_pos;
    
	// mux for the motion calculator input
	always @* begin
		if (switch[1]) begin
			x_com_in <= cursor_x;
			y_com_in <= cursor_y;
		end
		else begin
			x_com_in <= x_pos;
			y_com_in <= y_pos;
		end
		
		// every time we compute a new center of mass, record the location
		if(data_ready) begin
			x_pos <= x_com;
			y_pos <= y_com;
		end
	end
	
	// new calculator created with ISim on another computer
	wire calculator_ready;
	unpiped_calc my_calc(.reset(reset), .clk(clk),
			.x_com(x_com_in), .y_com(y_com_in), .x_real(x_real_world), 
			.y_real(y_real_world), .z_real(z_real_world),
			.x_light1(x_light1), .y_light1(y_light1), 
			.pan_addr_light1(pan_addr_light1),
			.tilt_addr_light1(tilt_addr_light1),
			.pan(pan_out), .pan_addr(pan_address),
			.tilt(tilt_out), .tilt_addr(tilt_address),
			.ready(calculator_ready)
			);
	
    // grab the pan and tilt data on the calc's ready pulse
	reg [7:0] pan, tilt;	
	always @* begin
		if(calculator_ready) begin
			pan <= pan_out;
			tilt <= tilt_out;
		end
	end
	

    // code that controls what is written to ZBT memory
    reg [31:0] 	count;
    always @(posedge clk) count <= reset ? 0 : count + 1;
	// these alternate inputs set everything to black to 
    // get rid of the noise of the unwritten memory
	wire [18:0] 	vram_addr2 = count[0+18:0];
    wire [35:0] 	vpat = 36'd0;

    // mux selecting read/write to memory based on which write-enable is chosen
    // switch 3 changes from video input to black, used to be stripes
	wire 	sw_ntsc = ~switch[3];
    wire 	my_we = sw_ntsc ? (hcount[0]==1'd1) : blank;
    wire [18:0] 	write_addr = sw_ntsc ? ntsc_addr : vram_addr2;
    wire [35:0] 	write_data = sw_ntsc ? ntsc_data : vpat;
    assign 	vram_addr = my_we ? write_addr : vram_addr1;
    assign 	vram_we = my_we;
    assign 	vram_write_data = write_data;
	
	//////////////////////////////////
	// End of Motion Tracking Block //
	//////////////////////////////////
	
	//////////////////////////////////
	// High-level Calibration Block //
	//////////////////////////////////
	
	// set up calibration wires
	// optionally, height_cal_up and down can be linked to buttons
	wire height_cal_up, height_cal_down;
	debounce db_btn3(power_on_reset, clk, ~button3, height_cal_up);
	debounce db_btn2(power_on_reset, clk, ~button2, height_cal_down);
	
	calibration cal(.reset(reset), .clk(clk), 
			.height_cal_up(height_cal_up), .height_cal_down(height_cal_down),
			.x_real_world(x_real_world), .y_real_world(y_real_world),
			.z_real_world(z_real_world), .x_light1(x_light1),
			.y_light1(y_light1), .pan_addr_light1(pan_addr_light1),
			.tilt_addr_light1(tilt_addr_light1));

	//////////////////////////////
	// End of Calibration Block //
	//////////////////////////////
	
	////////////////////////////////////////
	// High-level DMX512 Processing Block //
	////////////////////////////////////////
	
	// wires for the DMX block
	wire [8:0] request_addr;
	wire request_pulse;
	wire [8:0] dmx_write_addr;
	wire [7:0] dmx_write_data;
	wire dmx_out;
	
	// assumes a 27MHz clock
    // theoretically might be out of sync from the rest of the project
	// this module takes in data from the motion calculator block
	// this module outputs data to the dmx writer block
	dmx_processor dmx_proc(.reset(reset), .clk(clock_27mhz),
		.pan_addr(pan_address), .tilt_addr(tilt_address),
		.pan(pan_out), .tilt(tilt_out), .calc_ready(calculator_ready),
		.request_addr(request_addr), .request_pulse(request_pulse),
		.addr_out(dmx_write_addr), .data_out(dmx_write_data)
		);
	
	// assumes a 27MHz clock
	// this module writes out the data+ line of the DMX512 protocol
	// to go to the MAX485 chip
	dmx_writer my_dmx_writer(.reset(reset), .clk(clock_27mhz),
		.addr(dmx_write_addr), .data(dmx_write_data),
		.dmx_out(dmx_out), .request_addr(request_addr),
		.request_pulse(request_pulse)
		);
	
	// assign data+ for the DMX512 output to user4[31]
	// the max 485 chip will create the differential signal
	assign user4[31] = dmx_out;
	
	//////////////////////
	// End of DMX Block //
	//////////////////////

	//////////////////////////////////////////
	// High-level Display and Testing Block //
	//////////////////////////////////////////

	// hex data display block
    reg [63:0] dispdata;
	// would changing the clock to clock_27mhz help? the jitteryness?
    // something weird is going on here with the timing
    display_16hex hexdisp1(reset, clk, dispdata,
			  disp_blank, disp_clock, disp_rs, disp_ce_b,
			  disp_reset_b, disp_data_out);
			  
	// cursor movement FSM
	reg [17:0] cursor_counter = 18'd0;
	localparam CXMIN = 11'd0;
	localparam CXMAX = 11'd1024;
	localparam CYMIN = 10'd0;
	localparam CYMAX = 10'd768;
	
	// debounce the buttons for the cursor
	wire c_up, c_down, c_left, c_right;
	debounce db_up(power_on_reset, clk, ~button_up, c_up);
	debounce db_down(power_on_reset, clk, ~button_down, c_down);
	debounce db_left(power_on_reset, clk, ~button_left, c_left);
	debounce db_right(power_on_reset, clk, ~button_right, c_right);
	
	always @(posedge clk) begin
        // slow down the cursor movement by adding a counter
		if (cursor_counter == 18'd0) begin
			// scroll up
			if (c_up && cursor_y > CYMIN) cursor_y <= cursor_y - 1;
			
			// scroll down
			if (c_down && cursor_y < CYMAX) cursor_y <= cursor_y + 1;
			
			// scroll left
			if (c_left && cursor_x > CXMIN) cursor_x <= cursor_x - 1;
			
			// scroll right
			if (c_right && cursor_x < CXMAX) cursor_x <= cursor_x + 1;
		end
		
		// always increment the counter
		cursor_counter <= cursor_counter + 1;
	end

    // select output pixel data --> this is the main part of the cursor FSM
	localparam X_TEMP = 11'd400;
	localparam Y_TEMP = 10'd200;
    reg [17:0] pixel;
    reg b,hs,vs;
	wire [1:0] cursor_sw;
	assign cursor_sw = {switch[1], switch[0]};
    always @(posedge clk) begin
		case(cursor_sw)
			// switch 0 turns on the cursor that follows the center of mass
			// switch 1 turns on a fixed cursor
			// both switches overwrites pixels based on color
			2'b00: begin // mode with cursors
				// this overwrites the weird error on the left of the screen, but
                // it breaks the hex display...
				//if (hcount < 11'd33 || vcount < 10'd70) pixel <= 18'd0;
				//else pixel <= vr_pixel;
				pixel <= vr_pixel;
			end
			2'b01: begin // motion tracking mode
				if (((hcount + 2>=x_pos) && (hcount - 2<=x_pos)) 
					|| ((vcount + 2>=y_pos) && (vcount - 2<=y_pos)))
					pixel <= 18'b000000_111111__000000; 
				else if ((hcount == x_light1) || (vcount == y_light1))
					pixel <= 18'b000000_000000__111111; 
				// this overwrites the weird error on the left of the screen
				// this breaks the hex display...
				//else if (hcount < 11'd33 || vcount < 10'd70) pixel <= 18'd0;
				else pixel <= vr_pixel;	
			end
			2'b10: begin // moveable cursor with buttons mode
				if ((hcount == cursor_x) || (vcount == cursor_y))
					pixel <= 18'b000000_111111__000000;
				else if ((hcount == x_light1) || (vcount == y_light1))
					pixel <= 18'b000000_000000__111111; 
				else pixel <= vr_pixel;
			end
			2'b11: begin // HSV mode
				// if hsv is within our range, overwrite the pixel
				if (hsv[23:16] >= 8'hEB && hsv[23:16] <= 8'hFA && 
						hsv[15:8] > 8'h88 && hsv[7:0] > 8'h88) begin
					// pixel is white if with all ranges
					pixel <= 18'b111111_111111_111111;
				end
				else if (hsv[23:16] >= 8'hEB && hsv[23:16] <= 8'hFA) begin
					// pixel is red if within hue but not s and v ranges
					pixel <= 18'b111111_000000_000000;
				end
				else if (hsv[15:8] > 8'h88 && hsv[7:0] > 8'h88) begin
					// pixel is blue if within s and v but not hue range
					pixel <= 18'b000000_000000_111111;
				end
				else pixel<= 18'd0; // pixel is black if not in any range
			end
			default: pixel <= vr_pixel; // do nothing unusual on default
		endcase
		
        // delay the correct VGA signals if necessary
		if (cursor_sw == 2'b11) begin
			b <= blank_del;
			hs <= hsync_del;
			vs <= vsync_del;
		end
		else begin
			b <= blank;
			hs <= hsync;
			vs <= vsync;
		end
    end

    // VGA Output.  In order to meet the setup and hold times of the
    // AD7125, we send it ~clk.
    assign vga_out_red = {pixel[17:12], 2'b00};
    assign vga_out_green = {pixel[11:6], 2'b00};
    assign vga_out_blue = {pixel[5:0], 2'b00};
    assign vga_out_sync_b = 1'b1;    // not used
    assign vga_out_pixel_clock = ~clk;
    assign vga_out_blank_b = ~b;
    assign vga_out_hsync = hs;
    assign vga_out_vsync = vs;
	
	// LEDs left over from example code
    //assign led = ~{vram_addr[18:13],reset,switch[1]};
	assign led = ~8'd0;

    // this block takes care of changing the values going to the hex display
    // there is probably a timing issue here which is making the hex display
    // act weirdly in the motion tracking mode
    always @(posedge clk) begin
		// display the RGB data for the pixel at the cursors' intersection
		if (switch[0] && (hcount_del==x_pos) && (vcount_del==y_pos)) begin
			/*
			dispdata <= {hsv[23:16], 4'd0, 1'd0, x_pos, 2'd0, y_pos, 4'b0, 
				{vr_pixel[17:12], 2'b00}, 
				{vr_pixel[11:6], 2'b00}, 
				{vr_pixel[5:0], 2'b00}};
			*/
			dispdata <= {hsv[23:16], 4'd0, 1'd0, x_pos, 2'd0, y_pos, 4'd0, 
				8'd0, pan, tilt};
		end
		else if ((hcount_del==cursor_x) && (vcount_del==cursor_y)) begin
			/*
			dispdata <= {hsv[23:16], 4'd0, 1'd0, cursor_x, 2'd0, 
			cursor_y, 4'b0, 
				{vr_pixel[17:12], 2'b00}, 
				{vr_pixel[11:6], 2'b00}, 
				{vr_pixel[5:0], 2'b00}};
			*/
			dispdata <= {hsv[23:16], 4'd0, 1'd0, cursor_x, 2'd0, 
				cursor_y, 4'd0, 8'd0, pan, tilt};
		end
    end
	
	//////////////////////////////////////
	// End of Display and Testing Block //
	//////////////////////////////////////
	
endmodule
