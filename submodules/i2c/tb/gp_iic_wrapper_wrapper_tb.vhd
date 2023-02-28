-------------------------------------------------------------------------------
-- Title	  : Testbench for design "gp_iic_wrapper"
-- Project	  : test project
-------------------------------------------------------------------------------
-- File		  : gp_iic_wrapper_tb.vhd
-- Author	  :	  <grussy@pcfr16.physik.uni-freiburg.de>
-- Company	  : 
-- Created	  : 2013-08-12
-- Last update: 2013-08-19
-- Platform	  : 
-- Standard	  : VHDL'93
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2013 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date		   Version	Author	Description
-- 2013-08-12  1.0		grussy	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity gp_iic_wrapper_wrapper_tb is

end entity gp_iic_wrapper_wrapper_tb;

-------------------------------------------------------------------------------

architecture behv of gp_iic_wrapper_wrapper_tb is

	signal sda : std_logic_vector(1 downto 0) := (others => '0');
	signal scl : std_logic_vector(1 downto 0);

										-- component ports
	signal clk			: std_logic						:= '0';
	signal stb			: std_logic						:= '0';
	signal we			: std_logic						:= '0';
	signal wr_part		: std_logic_vector(3 downto 0)	:= "0011";
	signal err			: std_logic;
	signal ack			: std_logic;
	signal reg_addr		: std_logic_vector(15 downto 0) := (others => '0');
	signal write_data	: std_logic_vector(31 downto 0) := (others => '0');
	signal read_data	: std_logic_vector(15 downto 0);
	signal slave_addr	: std_logic_vector(6 downto 0)	:= (others => '0');
	signal reg_16_bit	: std_logic						:= '0';
	signal data_16_bit	: std_logic						:= '0';
	signal upper_iic_on : std_logic						:= '0';





begin  -- architecture behv

										-- component instantiation
	DUT : entity work.gp_iic_wrapper_wrapper
		generic map (
			SIM => true)
		port map (
			clk			 => clk,
			stb			 => stb,
			we			 => we,
			wr_part		 => wr_part,
			err			 => err,
			ack			 => ack,
			reg_addr	 => reg_addr,
			write_data	 => write_data,
			read_data	 => read_data,
			slave_addr	 => slave_addr,
			reg_16_bit	 => reg_16_bit,
			data_16_bit	 => data_16_bit,
			upper_iic_on => upper_iic_on,

			SDA => SDA,
			SCL => SCL);

	clk <= not clk after 5 ns;

	process
	begin
		wait for 8600 ns;
		wait until rising_edge(clk);
		stb			 <= '1';
		we			 <= '0';
		reg_addr	 <= x"2f3f";
--		write_data	<= x"abcd";
		slave_addr	 <= "0110011";
		reg_16_bit	 <= '0';
		data_16_bit	 <= '1';
		upper_iic_on <= '0';

		wait until rising_edge(ack);
		stb <= '0';
		we	<= '0';
		wait;
	end process;

end architecture behv;
