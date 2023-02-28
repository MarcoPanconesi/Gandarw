-------------------------------------------------------------------------------
-- Title	  : slink interface
-- Project	  : test project
-------------------------------------------------------------------------------
-- File		  : slink_if.vhd
-- Author	  :	  <grussy@pcfr16.physik.uni-freiburg.de>
-- Company	  : 
-- Created	  : 2014-01-08
-- Last update: 2014-01-08
-- Platform	  : 
-- Standard	  : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: This is a simple interface to guarantee the slink timing
-------------------------------------------------------------------------------
-- Copyright (c) 2014 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date		   Version	Author	Description
-- 2014-01-08  1.0		grussy	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
library UNISIM;
use UNISIM.vcomponents.all;
-------------------------------------------------------------------------------

entity slink_if is
	port (
-------------------------------------------------------------------------------
-- SLINK from toplevel port
		VUD		: out std_logic_vector (31 downto 0);
		VLFF	: in  std_logic;
		VURESET : out std_logic;
		VSRESET : out std_logic;
		VUTEST	: out std_logic;
		VUDW	: out std_logic_vector (1 downto 0);
		VUCTRL	: out std_logic;
		VUWEN	: out std_logic;
		VUCLK	: out std_logic;
		VLDOWN	: in  std_logic;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- SLINK from fabric
		UD	   : in	 std_logic_vector (31 downto 0);
		LFF	   : out std_logic;
		URESET : in	 std_logic;
		UTEST  : in	 std_logic;
		UDW	   : in	 std_logic_vector (1 downto 0);
		UCTRL  : in	 std_logic;
		UWEN   : in	 std_logic;
		UCLK   : in	 std_logic;
		LDOWN  : out std_logic
-------------------------------------------------------------------------------		
		);

end entity slink_if;

-------------------------------------------------------------------------------

architecture behav of slink_if is

begin  -- architecture behav

-------------------------------------------------------------------------------
-- inputs
	LFF	  <= VLFF;
	LDOWN <= VLDOWN;
------------------------------------------------------------------------------- 

-------------------------------------------------------------------------------
-- outputs
    VSRESET <= '1'; -- DA CONTROLLARE SE DEVE ESSERE AD '1' ...

-- UD
	ud_oddrs : for i in 0 to 31 generate
		UD_ODDR : ODDR
			generic map(
				DDR_CLK_EDGE => "SAME_EDGE",    -- "OPPOSITE_EDGE" or "SAME_EDGE" 
				INIT		 => '0',            -- Initial value for Q port ('1' or '0')
				SRTYPE		 => "SYNC")		    -- Reset Type ("ASYNC" or "SYNC")
			port map (
				Q  => VUD(i),			        -- 1-bit DDR output
				C  => UCLK,				        -- 1-bit clock input
				CE => '1',				        -- 1-bit clock enable input
				D1 => UD(i),			        -- 1-bit data input (positive edge)
				D2 => UD(i),			        -- 1-bit data input (negative edge)
				R  => '0',				        -- 1-bit reset input
				S  => '0'				        -- 1-bit set input
				);
	end generate ud_oddrs;

-- URESET
	URESET_ODDR : ODDR
		generic map(
			DDR_CLK_EDGE => "SAME_EDGE",        -- "OPPOSITE_EDGE" or "SAME_EDGE" 
			INIT		 => '0',                -- Initial value for Q port ('1' or '0')
			SRTYPE		 => "SYNC")		        -- Reset Type ("ASYNC" or "SYNC")
		port map (      
			Q  => VURESET,				        -- 1-bit DDR output
			C  => UCLK,					        -- 1-bit clock input
			CE => '1',					        -- 1-bit clock enable input
			D1 => URESET,				        -- 1-bit data input (positive edge)
			D2 => URESET,				        -- 1-bit data input (negative edge)
			R  => '0',					        -- 1-bit reset input
			S  => '0'					        -- 1-bit set input
			);

-- UTEST
	UTEST_ODDR : ODDR
		generic map(
			DDR_CLK_EDGE => "SAME_EDGE",        -- "OPPOSITE_EDGE" or "SAME_EDGE" 
			INIT		 => '0',                -- Initial value for Q port ('1' or '0')
			SRTYPE		 => "SYNC")		        -- Reset Type ("ASYNC" or "SYNC")
		port map (      
			Q  => VUTEST,				        -- 1-bit DDR output
			C  => UCLK,					        -- 1-bit clock input
			CE => '1',					        -- 1-bit clock enable input
			D1 => UTEST,				        -- 1-bit data input (positive edge)
			D2 => UTEST,				        -- 1-bit data input (negative edge)
			R  => '0',					        -- 1-bit reset input
			S  => '0'					        -- 1-bit set input
			);

-- UDW
	udw_oddrs : for i in 0 to 1 generate
		UDW_ODDR : ODDR
			generic map(
				DDR_CLK_EDGE => "SAME_EDGE",    -- "OPPOSITE_EDGE" or "SAME_EDGE" 
				INIT		 => '0',            -- Initial value for Q port ('1' or '0')
				SRTYPE		 => "SYNC")		    -- Reset Type ("ASYNC" or "SYNC")
			port map (
				Q  => VUDW(i),			        -- 1-bit DDR output
				C  => UCLK,				        -- 1-bit clock input
				CE => '1',				        -- 1-bit clock enable input
				D1 => UDW(i),			        -- 1-bit data input (positive edge)
				D2 => UDW(i),			        -- 1-bit data input (negative edge)
				R  => '0',				        -- 1-bit reset input
				S  => '0'				        -- 1-bit set input
				);
	end generate udw_oddrs;

-- UCTRL
	UCTRL_ODDR : ODDR
		generic map(
			DDR_CLK_EDGE => "SAME_EDGE",        -- "OPPOSITE_EDGE" or "SAME_EDGE" 
			INIT		 => '0',                -- Initial value for Q port ('1' or '0')
			SRTYPE		 => "SYNC")		        -- Reset Type ("ASYNC" or "SYNC")
		port map (      
			Q  => VUCTRL,				        -- 1-bit DDR output
			C  => UCLK,					        -- 1-bit clock input
			CE => '1',					        -- 1-bit clock enable input
			D1 => UCTRL,				        -- 1-bit data input (positive edge)
			D2 => UCTRL,				        -- 1-bit data input (negative edge)
			R  => '0',					        -- 1-bit reset input
			S  => '0'					        -- 1-bit set input
			);

-- UWEN
	UWEN_ODDR : ODDR
		generic map(
			DDR_CLK_EDGE => "SAME_EDGE",        -- "OPPOSITE_EDGE" or "SAME_EDGE" 
			INIT		 => '0',                -- Initial value for Q port ('1' or '0')
			SRTYPE		 => "SYNC")		        -- Reset Type ("ASYNC" or "SYNC")
		port map (      
			Q  => VUWEN,				        -- 1-bit DDR output
			C  => UCLK,					        -- 1-bit clock input
			CE => '1',					        -- 1-bit clock enable input
			D1 => UWEN,					        -- 1-bit data input (positive edge)
			D2 => UWEN,					        -- 1-bit data input (negative edge)
			R  => '0',					        -- 1-bit reset input
			S  => '0'					        -- 1-bit set input
			);

-- UCLK
	UCLK_ODDR : ODDR
		generic map(
			DDR_CLK_EDGE => "SAME_EDGE",        -- "OPPOSITE_EDGE" or "SAME_EDGE" 
			INIT		 => '0',                -- Initial value for Q port ('1' or '0')
			SRTYPE		 => "SYNC")		        -- Reset Type ("ASYNC" or "SYNC")
		port map (      
			Q  => VUCLK,				        -- 1-bit DDR output
			C  => UCLK,					        -- 1-bit clock input
			CE => '1',					        -- 1-bit clock enable input
			D1 => '0',					        -- 1-bit data input (positive edge)
			D2 => '1',					        -- 1-bit data input (negative edge)
			R  => '0',					        -- 1-bit reset input
			S  => '0'					        -- 1-bit set input
			);		
------------------------------------------------------------------------------- 
end architecture behav;

-------------------------------------------------------------------------------
