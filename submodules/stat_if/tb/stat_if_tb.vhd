-------------------------------------------------------------------------------
-- Title	  : Testbench for design "gp_if"
-- Project	  : test project
-------------------------------------------------------------------------------
-- File		  : gp_if_tb.vhd
-- Author	  : Philipp	 <philipp@pcfr58.physik.uni-freiburg.de>
-- Company	  : 
-- Created	  : 2013-08-16
-- Last update: 2013-09-05
-- Platform	  : 
-- Standard	  : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2013 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date		   Version	Author	Description
-- 2013-08-16  1.0		philipp Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity stat_if_tb is

end entity stat_if_tb;

-------------------------------------------------------------------------------

architecture behv of stat_if_tb is

	signal clk			 : std_logic:='0';
	signal stat_flags	 : std_logic_vector(15 downto 0):=(others => '0');
	signal wr_stats		 : std_logic:='0';
	signal wr_sys_mon	 : std_logic:='0';
	signal cfmem_wb_cyc	 : std_logic:='0';
	signal cfmem_wb_stb	 : std_logic:='0';
	signal cfmem_wb_we	 : std_logic_vector(3 downto 0):="0000";
	signal cfmem_wb_ack	 : std_logic:='0';
	signal cfmem_wb_addr : std_logic_vector (9 downto 0);
	signal cfmem_wb_din	 : std_logic_vector (31 downto 0):=(others => '0');
	signal cfmem_wb_dout : std_logic_vector (31 downto 0);


	signal startup	 : std_logic := '0';
	signal wait_done : std_logic := '0';

begin  -- architecture behv

	stat_if_1 : entity work.stat_if
		port map (
			clk			  => clk,
			stat_flags	  => stat_flags,
			wr_stats	  => wr_stats,
			wr_sys_mon	  => wr_sys_mon,
			cfmem_wb_cyc  => cfmem_wb_cyc,
			cfmem_wb_stb  => cfmem_wb_stb,
			cfmem_wb_we	  => cfmem_wb_we,
			cfmem_wb_ack  => cfmem_wb_ack,
			cfmem_wb_addr => cfmem_wb_addr,
			cfmem_wb_din  => cfmem_wb_din,
			cfmem_wb_dout => cfmem_wb_dout);

	clk <= not clk after 5 ns;
										--cfmem_wb_ack <= not cfmem_wb_ack after 10 ns;
	process
	begin

		if wait_done = '0' then
			wait for 1000 us;
			wait_done <= '1';
		end if;

		wait until rising_edge(clk);

		if startup = '0' then
			
			wr_sys_mon <= '1';
			startup	 <= '1';
		else
			
			wr_sys_mon <= '0';
			
		end if;

		if cfmem_wb_stb = '1' and cfmem_wb_ack = '0' then
			cfmem_wb_ack <= '1';
		else
			cfmem_wb_ack <= '0';

		end if;

	end process;

end architecture behv;
