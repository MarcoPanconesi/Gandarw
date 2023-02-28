-------------------------------------------------------------------------------
-- Title	  : tranceiver for singlechannel aurora on gandalf
-- Project	  : test project
-------------------------------------------------------------------------------
-- File		  : tranceiver_main.vhd
-- Author	  :	  <grussy@pcfr16.physik.uni-freiburg.de>
-- Company	  : 
-- Created	  : 2013-03-06
-- Last update: 2013-03-07
-- Platform	  : 
-- Standard	  : VHDL'93
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2013 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date		   Version	Author	Description
-- 2013-03-06  1.0		grussy	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library UNISIM;
use UNISIM.vcomponents.all;

use WORK.G_PARAMETERS.all;
-------------------------------------------------------------------------------

entity tranceiver_main is
	port (
		control	 : inout std_logic_vector(35 downto 0);
		reset_in : in	 std_logic;
		clk40_in : in	 std_logic;

		gtp_clk_out : out std_logic;
		tx_data_in	: in  std_logic_vector(15 downto 0);
		rx_data_out : out std_logic_vector(15 downto 0);
		tx_isk_in	: in  std_logic_vector(1 downto 0);
		rx_isk_out	: out std_logic_vector(1 downto 0);

--from toplevel
		REFCLK_P : in  std_logic;
		REFCLK_N : in  std_logic;
		RXN		 : in  std_logic;
		RXP		 : in  std_logic;
		TXN		 : out std_logic;
		TXP		 : out std_logic
		);

end entity tranceiver_main;
architecture behav of tranceiver_main is

-------------------------------------------------------------------------------
-- wrapper
	component single_channel_aurora_xc5vsx95t
		generic
			(
				wrapper_sim_gtpreset_speedup : integer	  := 0;	 -- set to 1 to speed up sim reset
				wrapper_sim_pll_perdiv2		 : bit_vector := x"141"	 -- set to the vco unit interval time
				);
		port
			(
----------------------- receive ports - 8b10b decoder ----------------------
				tile0_rxchariscomma0_out   : out std_logic_vector(1 downto 0);
				tile0_rxchariscomma1_out   : out std_logic_vector(1 downto 0);
				tile0_rxcharisk0_out	   : out std_logic_vector(1 downto 0);
				tile0_rxcharisk1_out	   : out std_logic_vector(1 downto 0);
				tile0_rxdisperr0_out	   : out std_logic_vector(1 downto 0);
				tile0_rxdisperr1_out	   : out std_logic_vector(1 downto 0);
				tile0_rxnotintable0_out	   : out std_logic_vector(1 downto 0);
				tile0_rxnotintable1_out	   : out std_logic_vector(1 downto 0);
--------------- receive ports - comma detection and alignment --------------
				tile0_rxbyteisaligned0_out : out std_logic;
				tile0_rxbyteisaligned1_out : out std_logic;
				tile0_rxenmcommaalign0_in  : in	 std_logic;
				tile0_rxenmcommaalign1_in  : in	 std_logic;
				tile0_rxenpcommaalign0_in  : in	 std_logic;
				tile0_rxenpcommaalign1_in  : in	 std_logic;
------------------- receive ports - rx data path interface -----------------
				tile0_rxdata0_out		   : out std_logic_vector(15 downto 0);
				tile0_rxdata1_out		   : out std_logic_vector(15 downto 0);
				tile0_rxusrclk0_in		   : in	 std_logic;
				tile0_rxusrclk1_in		   : in	 std_logic;
				tile0_rxusrclk20_in		   : in	 std_logic;
				tile0_rxusrclk21_in		   : in	 std_logic;
------- receive ports - rx driver,oob signalling,coupling and eq.,cdr ------
				tile0_rxn0_in			   : in	 std_logic;
				tile0_rxn1_in			   : in	 std_logic;
				tile0_rxp0_in			   : in	 std_logic;
				tile0_rxp1_in			   : in	 std_logic;
--------------------- shared ports - tile and pll ports --------------------
				tile0_clkin_in			   : in	 std_logic;
				tile0_gtpreset_in		   : in	 std_logic;
				tile0_plllkdet_out		   : out std_logic;
				tile0_refclkout_out		   : out std_logic;
				tile0_resetdone0_out	   : out std_logic;
				tile0_resetdone1_out	   : out std_logic;
---------------- transmit ports - 8b10b encoder control ports --------------
				tile0_txcharisk0_in		   : in	 std_logic_vector(1 downto 0);
				tile0_txcharisk1_in		   : in	 std_logic_vector(1 downto 0);
------------------ transmit ports - tx data path interface -----------------
				tile0_txdata0_in		   : in	 std_logic_vector(15 downto 0);
				tile0_txdata1_in		   : in	 std_logic_vector(15 downto 0);
				tile0_txoutclk0_out		   : out std_logic;
				tile0_txoutclk1_out		   : out std_logic;
				tile0_txusrclk0_in		   : in	 std_logic;
				tile0_txusrclk1_in		   : in	 std_logic;
				tile0_txusrclk20_in		   : in	 std_logic;
				tile0_txusrclk21_in		   : in	 std_logic;
--------------- transmit ports - tx driver and oob signalling --------------
				tile0_txn0_out			   : out std_logic;
				tile0_txn1_out			   : out std_logic;
				tile0_txp0_out			   : out std_logic;
				tile0_txp1_out			   : out std_logic
				);
	end component;

	signal rxchariscomma   : std_logic_vector(1 downto 0);
	signal rxcharisk	   : std_logic_vector(1 downto 0);
	signal rxdisperr	   : std_logic_vector(1 downto 0);
	signal rxnotintable	   : std_logic_vector(1 downto 0);
	signal rxbyteisaligned : std_logic;
	signal rxenmcommaalign : std_logic;
	signal rxenpcommaalign : std_logic;
	signal rxdata		   : std_logic_vector(15 downto 0);
	signal gtpreset		   : std_logic;
	signal plllkdet		   : std_logic;
	signal refclkout	   : std_logic;
	signal resetdone	   : std_logic;
	signal resetdone_r1	   : std_logic;
	signal resetdone_r2	   : std_logic;
	signal txcharisk	   : std_logic_vector(1 downto 0);
	signal txdata		   : std_logic_vector(15 downto 0);
	signal txusrclk		   : std_logic;
	signal txusrclk2	   : std_logic;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- chipscope
	component tranceiver_ila
		port (
			CONTROL : inout std_logic_vector(35 downto 0);
			CLK		: in	std_logic;
			DATA	: in	std_logic_vector(63 downto 0);
			TRIG0	: in	std_logic_vector(7 downto 0));
	end component;

	signal ila_data : std_logic_vector(63 downto 0);
	signal ila_trg	: std_logic_vector(7 downto 0);
------------------------------------------------------------------------------- 

-------------------------------------------------------------------------------
-- clock
	component MGT_USRCLK_SOURCE_PLL
		generic
			(
				MULT			: integer		   := 2;
				DIVIDE			: integer		   := 2;
				CLK_PERIOD		: real			   := 6.43;
				OUT0_DIVIDE		: integer		   := 2;
				OUT1_DIVIDE		: integer		   := 2;
				OUT2_DIVIDE		: integer		   := 2;
				OUT3_DIVIDE		: integer		   := 2;
				SIMULATION_P	: integer		   := 1;
				LOCK_WAIT_COUNT : std_logic_vector := "1000001000110101"
				);
		port
			(
				CLK0_OUT	   : out std_logic;
				CLK1_OUT	   : out std_logic;
				CLK2_OUT	   : out std_logic;
				CLK3_OUT	   : out std_logic;
				CLK_IN		   : in	 std_logic;
				PLL_LOCKED_OUT : out std_logic;
				PLL_RESET_IN   : in	 std_logic
				);
	end component;

	signal refclk : std_logic;

	signal refclkout_to_cmt		: std_logic;
	signal refclkout_pll0_reset : std_logic;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- realignment
	signal realign_reset   : std_logic := '0';
	signal realign_doreset : std_logic := '0';

	signal realign_reset_cnt : integer range 0 to 2000 := 2000;
	signal missaligned_cnt : integer range 0 to 20 := 0;	
	
	type reset_state_type is (
		sleep,
		reset
		); 
	signal reset_state : reset_state_type := reset;

	type realign_state_type is (
		aligned,
		realign
		); 
	signal realign_state : realign_state_type := aligned;
------------------------------------------------------------------------------- 

begin  -- architecture behav
-------------------------------------------------------------------------------
-- static
	txdata		<= tx_data_in;
	rx_data_out <= rxdata;
	txcharisk	<= tx_isk_in;
	rx_isk_out	<= rxcharisk;

	gtp_clk_out <= txusrclk2;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- chipscope
Inst_chipscope : if USE_CHIPSCOPE_ILA_2 generate

	ila_trg				   <= rxcharisk & rxnotintable & resetdone & txcharisk & plllkdet;
	ila_data(1 downto 0)   <= rxcharisk;
	ila_data(3 downto 2)   <= rxdisperr;
	ila_data(5 downto 4)   <= rxnotintable;
	ila_data(6)			   <= rxenmcommaalign;
	ila_data(7)			   <= rxenpcommaalign;
	ila_data(23 downto 8)  <= rxdata;
	ila_data(24)		   <= gtpreset;
	ila_data(25)		   <= plllkdet;
	ila_data(26)		   <= resetdone;
	ila_data(27)		   <= resetdone_r1;
	ila_data(28)		   <= resetdone_r2;
	ila_data(30 downto 29) <= txcharisk;
	ila_data(46 downto 31) <= txdata;

	ila_data(47) <= '1' when reset_state = sleep else '0';
	ila_data(48) <= '1' when reset_state = reset else '0';

	ila_data(49) <= '1' when realign_state = aligned else '0';
	ila_data(50) <= '1' when realign_state = realign else '0';

	ila_data(52 downto 51) <= realign_reset & realign_doreset;
	ila_data(57 downto 53) <= std_logic_vector(to_unsigned(realign_reset_cnt, 5));

	tranceiver_ila_1 : tranceiver_ila
		port map (
			CONTROL => control,
			CLK		=> txusrclk2,
			DATA	=> ila_data,
			TRIG0	=> ila_trg);

end generate;


------------------------------------------------------------------------------- 

-------------------------------------------------------------------------------
-- reset
	gtpreset <= reset_in or realign_reset;

	process
	begin
		wait until rising_edge(clk40_in);
		case reset_state is
			when sleep =>
				realign_reset_cnt <= 2000;
				realign_reset	  <= '0';

				if resetdone_r2 = '1' and resetdone_r1 = '1' and resetdone = '1' and realign_doreset = '1' then
					reset_state <= reset;
				end if;

			when reset =>
				realign_reset <= '1';
				if realign_reset_cnt = 0 then
					reset_state <= sleep;
				else
					realign_reset_cnt <= realign_reset_cnt - 1;
				end if;
		end case;
	end process;

	process is
	begin
		wait until rising_edge(txusrclk2);
		case realign_state is
			when aligned =>
				realign_doreset <= '0';
				if rxbyteisaligned = '1' and (rxchariscomma = "10" or rxchariscomma = "01") then
					missaligned_cnt <= missaligned_cnt + 1;
				end if;
				if missaligned_cnt = 20 then
					realign_state <= realign;
				end if;
				
			when realign =>
				realign_doreset <= '1';
				if rxbyteisaligned = '0' or resetdone = '0' then
					realign_state	<= aligned;
					missaligned_cnt <= 0;
				end if;
		end case;
	end process;

	process
	begin
		wait until rising_edge(txusrclk2);
		resetdone_r1 <= resetdone;
		resetdone_r2 <= resetdone_r1;
	end process;

	process
	begin
		wait until rising_edge(txusrclk2);
		if resetdone_r2 = '1' then
			rxenmcommaalign <= '1';
			rxenpcommaalign <= '1';
		else
			rxenmcommaalign <= '0';
			rxenpcommaalign <= '0';
		end if;
	end process;
------------------------------------------------------------------------------- 

-------------------------------------------------------------------------------
-- clock
	tile0_refclk_ibufds_i : IBUFDS
		port map
		(
			O  => refclk,
			I  => REFCLK_P,
			IB => REFCLK_N
			);

	refclkout_pll0_bufg_i : BUFG
		port map
		(
			I => refclkout,
			O => refclkout_to_cmt
			);

	refclkout_pll0_reset <= not plllkdet;

	refclkout_pll0_i : MGT_USRCLK_SOURCE_PLL
		generic map
		(
			MULT			=> 10,
			DIVIDE			=> 1,
			CLK_PERIOD		=> 12.86,
			OUT0_DIVIDE		=> 10,
			OUT1_DIVIDE		=> 5,
			OUT2_DIVIDE		=> 1,
			OUT3_DIVIDE		=> 1,
			LOCK_WAIT_COUNT => "0011110011000000"
			)
		port map
		(
			CLK0_OUT	   => txusrclk2,
			CLK1_OUT	   => txusrclk,
			CLK2_OUT	   => open,
			CLK3_OUT	   => open,
			CLK_IN		   => refclkout_to_cmt,
			PLL_LOCKED_OUT => open,
			PLL_RESET_IN   => refclkout_pll0_reset
			);	
------------------------------------------------------------------------------- 

-------------------------------------------------------------------------------
-- the wrapper
	single_channel_aurora_xc5vsx95t_1 : single_channel_aurora_xc5vsx95t
		port map (
			tile0_rxchariscomma1_out   => open,
			tile0_rxchariscomma0_out   => rxchariscomma,
			tile0_rxcharisk1_out	   => open,
			tile0_rxcharisk0_out	   => rxcharisk,
			tile0_rxdisperr1_out	   => open,
			tile0_rxdisperr0_out	   => rxdisperr,
			tile0_rxnotintable1_out	   => open,
			tile0_rxnotintable0_out	   => rxnotintable,
			tile0_rxbyteisaligned1_out => open,
			tile0_rxbyteisaligned0_out => rxbyteisaligned,
			tile0_rxenmcommaalign1_in  => '0',
			tile0_rxenmcommaalign0_in  => rxenmcommaalign,
			tile0_rxenpcommaalign1_in  => '0',
			tile0_rxenpcommaalign0_in  => rxenpcommaalign,
			tile0_rxdata1_out		   => open,
			tile0_rxdata0_out		   => rxdata,
			tile0_rxusrclk1_in		   => txusrclk,
			tile0_rxusrclk0_in		   => txusrclk,
			tile0_rxusrclk21_in		   => txusrclk2,
			tile0_rxusrclk20_in		   => txusrclk2,
			tile0_rxn1_in			   => '1',
			tile0_rxn0_in			   => RXN,
			tile0_rxp1_in			   => '0',
			tile0_rxp0_in			   => RXP,
			tile0_clkin_in			   => refclk,
			tile0_gtpreset_in		   => gtpreset,
			tile0_plllkdet_out		   => plllkdet,
			tile0_refclkout_out		   => refclkout,
			tile0_resetdone1_out	   => open,
			tile0_resetdone0_out	   => resetdone,
			tile0_txcharisk1_in		   => "00",
			tile0_txcharisk0_in		   => txcharisk,
			tile0_txdata1_in		   => x"0000",
			tile0_txdata0_in		   => txdata,
			tile0_txoutclk1_out		   => open,
			tile0_txoutclk0_out		   => open,
			tile0_txusrclk1_in		   => txusrclk,
			tile0_txusrclk0_in		   => txusrclk,
			tile0_txusrclk21_in		   => txusrclk2,
			tile0_txusrclk20_in		   => txusrclk2,
			tile0_txn1_out			   => open,
			tile0_txn0_out			   => TXN,
			tile0_txp1_out			   => open,
			tile0_txp0_out			   => TXP
			);
------------------------------------------------------------------------------- 
end architecture behav;

-------------------------------------------------------------------------------
