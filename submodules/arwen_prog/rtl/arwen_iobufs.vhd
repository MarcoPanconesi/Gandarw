-- vsg_off
-------------------------------------------------------------------------------
-- Title	  : arwen iobufs
-- Project	  : test project
-------------------------------------------------------------------------------
-- File		  : arwen_iobufs.vhd
-- Author	  :	  <grussy@pcfr16.physik.uni-freiburg.de>
-- Company	  : 
-- Created	  : 2013-03-12
-- Last update: 2013-03-12
-- Platform	  : 
-- Standard	  : VHDL'93
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2013 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date		   Version	Author	Description
-- 2013-03-12  1.0		grussy	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
library UNISIM;
use UNISIM.VComponents.all;
-------------------------------------------------------------------------------

entity arwen_iobufs is
	port (
-------------------------------------------------------------------------------
-- lanes to use
		arwen_prog : in	 std_logic_vector(1 downto 0);
		arwen_init : out std_logic_vector(1 downto 0);
		arwen_done : out std_logic_vector(1 downto 0);
		arwen_cclk : in	 std_logic;
		arwen_d0   : in	 std_logic;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Programming lanes from toplevel
		ARWEN_PROG_P : out std_logic_vector(1 downto 0);
		ARWEN_PROG_N : out std_logic_vector(1 downto 0);
		ARWEN_INIT_P : in  std_logic_vector(1 downto 0);
		ARWEN_INIT_N : in  std_logic_vector(1 downto 0);
		ARWEN_DONE_P : in  std_logic_vector(1 downto 0);
		ARWEN_DONE_N : in  std_logic_vector(1 downto 0);

		ARWEN_D0_P : out std_logic_vector(1 downto 0);
		ARWEN_D0_N : out std_logic_vector(1 downto 0);

		ARWEN_CCLK_P : out std_logic_vector(1 downto 0);
		ARWEN_CCLK_N : out std_logic_vector(1 downto 0)
-------------------------------------------------------------------------------			
		);

end entity arwen_iobufs;

-------------------------------------------------------------------------------

architecture behav of arwen_iobufs is

begin  -- architecture behav
	prog : for i in 0 to 1 generate
		inst_arwen_prog : OBUFDS
			port map
			(
				I  => arwen_prog(i),
				O  => ARWEN_PROG_P(i),
				OB => ARWEN_PROG_N(i)
				);
	end generate prog;

	d0 : for i in 0 to 1 generate
		inst_arwen_d0 : OBUFDS
			port map
			(
				I  => arwen_d0,
				O  => ARWEN_D0_P(i),
				OB => ARWEN_D0_N(i)
				);
	end generate d0;

	cclk : for i in 0 to 1 generate
		inst_arwen_cclk : OBUFDS
			port map
			(
				I  => arwen_cclk,
				O  => ARWEN_CCLK_P(i),
				OB => ARWEN_CCLK_N(i)
				);
	end generate cclk;

	init : for i in 0 to 1 generate
		inst_arwen_init : IBUFDS
			port map
			(
				O  => arwen_init(i),
				I  => ARWEN_INIT_P(i),
				IB => ARWEN_INIT_N(i)
				);
	end generate init;

	done : for i in 0 to 1 generate
		inst_arwen_done : IBUFDS
			port map
			(
				O  => arwen_done(i),
				I  => ARWEN_DONE_P(i),
				IB => ARWEN_DONE_N(i)
				);
	end generate done;
	
end architecture behav;

-------------------------------------------------------------------------------
