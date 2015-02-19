--------------------------------------------------------------------------------
--     This file is owned and controlled by Xilinx and must be used           --
--     solely for design, simulation, implementation and creation of          --
--     design files limited to Xilinx devices or technologies. Use            --
--     with non-Xilinx devices or technologies is expressly prohibited        --
--     and immediately terminates your license.                               --
--                                                                            --
--     XILINX IS PROVIDING THIS DESIGN, CODE, OR INFORMATION "AS IS"          --
--     SOLELY FOR USE IN DEVELOPING PROGRAMS AND SOLUTIONS FOR                --
--     XILINX DEVICES.  BY PROVIDING THIS DESIGN, CODE, OR INFORMATION        --
--     AS ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE, APPLICATION            --
--     OR STANDARD, XILINX IS MAKING NO REPRESENTATION THAT THIS              --
--     IMPLEMENTATION IS FREE FROM ANY CLAIMS OF INFRINGEMENT,                --
--     AND YOU ARE RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY REQUIRE       --
--     FOR YOUR IMPLEMENTATION.  XILINX EXPRESSLY DISCLAIMS ANY               --
--     WARRANTY WHATSOEVER WITH RESPECT TO THE ADEQUACY OF THE                --
--     IMPLEMENTATION, INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR         --
--     REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE FROM CLAIMS OF        --
--     INFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS        --
--     FOR A PARTICULAR PURPOSE.                                              --
--                                                                            --
--     Xilinx products are not intended for use in life support               --
--     appliances, devices, or systems. Use in such applications are          --
--     expressly prohibited.                                                  --
--                                                                            --
--     (c) Copyright 1995-2007 Xilinx, Inc.                                   --
--     All rights reserved.                                                   --
--------------------------------------------------------------------------------
-- You must compile the wrapper file hsv_divider.vhd when simulating
-- the core, hsv_divider. When compiling the wrapper file, be sure to
-- reference the XilinxCoreLib VHDL simulation library. For detailed
-- instructions, please refer to the "CORE Generator Help".

-- The synthesis directives "translate_off/translate_on" specified
-- below are supported by Xilinx, Mentor Graphics and Synplicity
-- synthesis tools. Ensure they are correct for your synthesis tool(s).

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
-- synthesis translate_off
Library XilinxCoreLib;
-- synthesis translate_on
ENTITY hsv_divider IS
	port (
	dividend: IN std_logic_VECTOR(15 downto 0);
	divisor: IN std_logic_VECTOR(15 downto 0);
	quot: OUT std_logic_VECTOR(15 downto 0);
	remd: OUT std_logic_VECTOR(15 downto 0);
	clk: IN std_logic;
	rfd: OUT std_logic);
END hsv_divider;

ARCHITECTURE hsv_divider_a OF hsv_divider IS
-- synthesis translate_off
component wrapped_hsv_divider
	port (
	dividend: IN std_logic_VECTOR(15 downto 0);
	divisor: IN std_logic_VECTOR(15 downto 0);
	quot: OUT std_logic_VECTOR(15 downto 0);
	remd: OUT std_logic_VECTOR(15 downto 0);
	clk: IN std_logic;
	rfd: OUT std_logic);
end component;

-- Configuration specification 
	for all : wrapped_hsv_divider use entity XilinxCoreLib.sdivider_v3_0(behavioral)
		generic map(
			c_has_ce => 0,
			divclk_sel => 1,
			dividend_width => 16,
			fractional_width => 16,
			c_sync_enable => 1,
			signed_b => 0,
			divisor_width => 16,
			c_has_aclr => 0,
			fractional_b => 0,
			c_has_sclr => 0);
-- synthesis translate_on
BEGIN
-- synthesis translate_off
U0 : wrapped_hsv_divider
		port map (
			dividend => dividend,
			divisor => divisor,
			quot => quot,
			remd => remd,
			clk => clk,
			rfd => rfd);
-- synthesis translate_on

END hsv_divider_a;

