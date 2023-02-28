-------------------------------------------------------------------------------
-- Company:         INFN-LNF
-- Engineer:        alessandro.balla@lnf.infn.it
-- 
-- Create Date:     11:43:03 05/24/2021 
-- Design Name: 
-- Module Name:     arwen_s_iobufs 
-- Project Name:    GANDARW
-- Target Devices:  XC5VSX95T-2FF1136
-- Tool versions:   ISE 14.7
-- Description:     differential io buffer 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 -  File Created
-- More Comments:   Modified version of arwen_iobufs.vhd  
--                  of <grussy@pcfr16.physik.uni-freiburg.de>
--                  but for one board only
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
library UNISIM;
use UNISIM.VComponents.all;
-------------------------------------------------------------------------------

entity arwen_s_iobufs is
	port (
-------------------------------------------------------------------------------
-- lanes to use
		arwen_prog : in	 std_logic;
		arwen_init : out std_logic;
		arwen_done : out std_logic;
		arwen_cclk : in	 std_logic;
		arwen_d0   : in	 std_logic;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Programming lanes from toplevel
		ARWEN_PROG_P : out std_logic;
		ARWEN_PROG_N : out std_logic;
		ARWEN_INIT_P : in  std_logic;
		ARWEN_INIT_N : in  std_logic;
		ARWEN_DONE_P : in  std_logic;
		ARWEN_DONE_N : in  std_logic;

		ARWEN_D0_P : out std_logic;
		ARWEN_D0_N : out std_logic;

		ARWEN_CCLK_P : out std_logic;
		ARWEN_CCLK_N : out std_logic
-------------------------------------------------------------------------------			
		);

end entity arwen_s_iobufs;

-------------------------------------------------------------------------------

architecture behav of arwen_s_iobufs is

begin  -- architecture behav
		iobuf_prog : OBUFDS
            generic map (
                IOSTANDARD => "LVDS_25"
            )			
            port map (
				I  => arwen_prog,
				O  => ARWEN_PROG_P,
				OB => ARWEN_PROG_N
			);

        iobuf_d0 : OBUFDS
            generic map (
                IOSTANDARD => "LVDS_25"
            )			
			port map (
				I  => arwen_d0,
				O  => ARWEN_D0_P,
				OB => ARWEN_D0_N
			);

        iobuf_cclk : OBUFDS
            generic map (
                IOSTANDARD => "LVDS_25"
            )			
		    port map (
				I  => arwen_cclk,
				O  => ARWEN_CCLK_P,
				OB => ARWEN_CCLK_N
		    );

        iobuf_init : IBUFDS
            generic map (
                IOSTANDARD => "LVDS_25"
            )			
			port map (
				O  => arwen_init,
				I  => ARWEN_INIT_P,
				IB => ARWEN_INIT_N
			);

        iobuf_done : IBUFDS
            generic map (
                IOSTANDARD => "LVDS_25"
            )			
			port map (
				O  => arwen_done,
				I  => ARWEN_DONE_P,
				IB => ARWEN_DONE_N
			);
	
end architecture behav;

-------------------------------------------------------------------------------
