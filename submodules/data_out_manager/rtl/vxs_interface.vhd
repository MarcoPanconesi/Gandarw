-------------------------------------------------------------------------------
-- Title	  : vxs interface
-- Project	  : test project
-------------------------------------------------------------------------------
-- File		  : vxs_interface.vhd
-- Author	  :	  <grussy@pcfr16.physik.uni-freiburg.de>
-- Company	  : 
-- Created	  : 2013-10-18
-- Last update: 2014-07-28
-- Platform	  : 
-- Standard	  : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: wrapper for the vxs lanes
-------------------------------------------------------------------------------
-- Copyright (c) 2013 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date		   Version	Author	Description
-- 2013-10-18  1.0		grussy	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity vxs_interface is
	port (
-------------------------------------------------------------------------------
-- toplevel
		VXS_A_P : inout std_logic_vector(7 downto 0);
		VXS_A_N : inout std_logic_vector(7 downto 0);

--Trigger output
--		VXS_B_P : out std_logic_vector(7 downto 0);
--		VXS_B_N : out std_logic_vector(7 downto 0);

		VXS_SCL : out std_logic;
		VXS_SDA : in  std_logic;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- to other interfaces
		vxs_tcs_clk_p  : out std_logic;
		vxs_tcs_clk_n  : out std_logic;
		vxs_tcs_data_p : out std_logic;
		vxs_tcs_data_n : out std_logic;

		vxs_request_tcs_from_tiger : in std_logic;
-------------------------------------------------------------------------------		

-------------------------------------------------------------------------------
-- to/from data_out_manager
		sdr_link_data_in	: in  std_logic_vector(32 downto 0);
		sdr_link_data_valid : in  std_logic;
		sdr_link_data_clk	: in  std_logic;
		sdr_link_link_clk	: in  std_logic;
		sdr_link_rst		: in  std_logic;
		sdr_link_lff		: out std_logic
-------------------------------------------------------------------------------
		);

end entity vxs_interface;

-------------------------------------------------------------------------------

architecture behav of vxs_interface is


begin  -- architecture behav

	VXS_SCL <= not vxs_request_tcs_from_tiger;	--	request TCS over Backplane

	vxs_tcs_clk_p  <= VXS_A_P(7);
	vxs_tcs_clk_n  <= VXS_A_N(7);
	vxs_tcs_data_p <= VXS_A_P(6);
	vxs_tcs_data_n <= VXS_A_N(6);

-------------------------------------------------------------------------------
-- sdr link to tiger for data readout
	sdr_slink_to_tiger : entity work.sdr_slink
		port map (
			vxs_lanes_p => VXS_A_P(4 downto 0),
			vxs_lanes_n => VXS_A_N(4 downto 0),
			data_in		=> sdr_link_data_in,
			data_valid	=> sdr_link_data_valid,
			data_clk	=> sdr_link_data_clk,
			link_clk	=> sdr_link_link_clk,
			rst			=> sdr_link_rst,
			lff			=> sdr_link_lff);
-------------------------------------------------------------------------------		

end architecture behav;

-------------------------------------------------------------------------------
