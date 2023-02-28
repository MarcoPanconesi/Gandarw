-------------------------------------------------------------------------------
-- Title	  : Testbench for design "si_iic_wrapper"
-- Project	  : test project
-------------------------------------------------------------------------------
-- File		  : si_iic_wrapper_tb.vhd
-- Author	  :	  <grussy@pcfr16.physik.uni-freiburg.de>
-- Company	  : 
-- Created	  : 2013-06-20
-- Last update: 2013-06-25
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

entity si_iic_wrapper_tb is

end entity si_iic_wrapper_tb;

-------------------------------------------------------------------------------

architecture behav of si_iic_wrapper_tb is

	signal scl_pad_i	: std_logic := 'Z';
	signal scl_pad_o	: std_logic;
	signal scl_padoen_o : std_logic;
	signal sda_pad_i	: std_logic := '0';
	signal sda_pad_o	: std_logic;
	signal sda_padoen_o : std_logic;

										-- component ports
	signal clk		  : std_logic					 := '0';
	signal stb		  : std_logic					 := '0';
	signal we		  : std_logic					 := '0';
	signal err		  : std_logic;
	signal ack		  : std_logic;
	signal reg_addr	  : std_logic_vector(7 downto 0) := (others => '0');
	signal write_data : std_logic_vector(7 downto 0) := (others => '0');
	signal read_data  : std_logic_vector(7 downto 0);
	signal si_nr	  : std_logic_vector(2 downto 0) := (others => '0');
	signal wb_rst_i	  : std_logic					 := '0';
	signal arst_i	  : std_logic					 := '0';
	signal wb_adr_i	  : std_logic_vector(2 downto 0);
	signal wb_dat_i	  : std_logic_vector(7 downto 0);
	signal wb_dat_o	  : std_logic_vector(7 downto 0) := (others => '0');
	signal wb_we_i	  : std_logic;
	signal wb_stb_i	  : std_logic;
	signal wb_cyc_i	  : std_logic;
	signal wb_ack_o	  : std_logic					 := '0';
	signal wb_inta_o  : std_logic					 := '0';

										-- clock


begin  -- architecture behav

	i2c_master_top_1 : entity work.i2c_master_top
		generic map (
			ARST_LVL => '0')
		port map (
			wb_clk_i	 => clk,
			wb_rst_i	 => '0',
			arst_i		 => '0',
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

										-- component instantiation
	DUT : entity work.si_iic_wrapper
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

	clk <= not clk after 5 ns;

	process
	begin
		wait for 8600 ns;
		wait until rising_edge(clk);
		stb		   <= '1';
		we		   <= '1';
		reg_addr   <= x"2f";
		write_data <= x"ab";
		si_nr	   <= "001";

		wait until rising_edge(ack);
		stb		   <= '0';
		we		   <= '0';
		reg_addr   <= x"00";
		write_data <= x"00";
		si_nr	   <= "000";


		wait until rising_edge(clk);
		stb		   <= '1';
		we		   <= '0';
		reg_addr   <= x"2f";
		si_nr	   <= "001";

		wait until rising_edge(ack);
		stb		   <= '0';
		we		   <= '0';
		reg_addr   <= x"00";
		si_nr	   <= "000";		

		wait;
	end process;
end architecture behav;
