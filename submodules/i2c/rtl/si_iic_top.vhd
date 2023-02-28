-------------------------------------------------------------------------------
-- Title	  : si iic top module
-- Project	  : test project
-------------------------------------------------------------------------------
-- File		  : si_iic_top.vhd
-- Author	  :	  <grussy@pcfr16.physik.uni-freiburg.de>
-- Company	  : 
-- Created	  : 2013-06-20
-- Last update: 2013-06-20
-- Platform	  : 
-- Standard	  : VHDL'93
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2013 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date		   Version	Author	Description
-- 2013-06-20  1.0		grussy	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity si_iic_top is
	port (
		clk		   : in	   std_logic;
		stb		   : in	   std_logic;
		we		   : in	   std_logic;
		err		   : out   std_logic;
		ack		   : out   std_logic;
		reg_addr   : in	   std_logic_vector(7 downto 0);
		write_data : in	   std_logic_vector(7 downto 0);
		read_data  : out   std_logic_vector(7 downto 0);
		si_nr	   : in	   std_logic_vector(2 downto 0);
		SCL		   : inout std_logic;
		SDA		   : inout std_logic
		);


end entity si_iic_top;

-------------------------------------------------------------------------------

architecture behav of si_iic_top is


	signal wb_rst_i	  : std_logic := '0';
	signal arst_i	  : std_logic := '0';
	signal wb_adr_i	  : std_logic_vector(2 downto 0);
	signal wb_dat_i	  : std_logic_vector(7 downto 0);
	signal wb_dat_o	  : std_logic_vector(7 downto 0);
	signal wb_we_i	  : std_logic;
	signal wb_stb_i	  : std_logic;
	signal wb_cyc_i	  : std_logic;
	signal wb_ack_o	  : std_logic;
	signal wb_inta_o  : std_logic;


	signal scl_pad_i	: std_logic;
	signal scl_pad_o	: std_logic;
	signal scl_padoen_o : std_logic;
	signal sda_pad_i	: std_logic;
	signal sda_pad_o	: std_logic;
	signal sda_padoen_o : std_logic;

begin  -- architecture behav
-------------------------------------------------------------------------------
-- let xst insert the tristate buffers
	SCL		  <= scl_pad_o when (scl_padoen_o = '0') else 'Z';
	SDA		  <= sda_pad_o when (sda_padoen_o = '0') else 'Z';
	scl_pad_i <= SCL;
	sda_pad_i <= SDA;
-------------------------------------------------------------------------------

	si_iic_wrapper_1 : entity work.si_iic_wrapper
		port map (
			clk		   => clk,
			stb		   => stb,
			we		   => we,
			err		   => err,
			ack		   => ack,
			reg_addr   => reg_addr,
			write_data => write_data,
			read_data  => read_data,
			si_nr	   => si_nr,
			wb_rst_i   => wb_rst_i,
			arst_i	   => arst_i,
			wb_adr_i   => wb_adr_i,
			wb_dat_i   => wb_dat_i,
			wb_dat_o   => wb_dat_o,
			wb_we_i	   => wb_we_i,
			wb_stb_i   => wb_stb_i,
			wb_cyc_i   => wb_cyc_i,
			wb_ack_o   => wb_ack_o,
			wb_inta_o  => wb_inta_o);

	i2c_master_top_1 : entity work.i2c_master_top
		generic map (
			ARST_LVL => '0')
		port map (
			wb_clk_i	 => clk,
			wb_rst_i	 => '0',
			arst_i		 => '1',
			wb_adr_i	 => wb_adr_i,
			wb_dat_i	 => wb_dat_i,
			wb_dat_o	 => wb_dat_o,
			wb_we_i		 => wb_we_i,
			wb_stb_i	 => wb_stb_i,
			wb_cyc_i	 => wb_cyc_i,
			wb_ack_o	 => wb_ack_o,
			wb_inta_o	 => wb_inta_o,
			scl_pad_i	 => scl_pad_i,
			scl_pad_o	 => scl_pad_o,
			scl_padoen_o => scl_padoen_o,
			sda_pad_i	 => sda_pad_i,
			sda_pad_o	 => sda_pad_o,
			sda_padoen_o => sda_padoen_o);

end architecture behav;

-------------------------------------------------------------------------------
