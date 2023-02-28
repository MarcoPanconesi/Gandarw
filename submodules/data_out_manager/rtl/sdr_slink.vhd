-------------------------------------------------------------------------------
-- Title	  : single data rate slink gandalf to tiger link over 5 lanes
-- Project	  : test project
-------------------------------------------------------------------------------
-- File		  : sdr_slink.vhd
-- Author	  :	  <grussy@pcfr16.physik.uni-freiburg.de>
-- Company	  : 
-- Created	  : 2012-09-13
-- Last update: 2012-09-14
-- Platform	  : 
-- Standard	  : VHDL'93
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2012 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date		   Version	Author	Description
-- 2012-09-13  1.0		grussy	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library UNISIM;
use unisim.vcomponents.all;

library UNIMACRO;
use UNIMACRO.vcomponents.all;

-------------------------------------------------------------------------------

entity sdr_slink is
	port (
		vxs_lanes_p : inout std_logic_vector(4 downto 0);
		vxs_lanes_n : inout std_logic_vector(4 downto 0);
		data_in		: in  std_logic_vector(32 downto 0);
		data_valid	: in  std_logic;
		data_clk	: in  std_logic;
		link_clk	: in  std_logic;
		rst			: in  std_logic;
		lff			: out	std_logic
		);

end entity sdr_slink;

-------------------------------------------------------------------------------

architecture behav of sdr_slink is
	type state_type is (
		reset,
		startup,
		sleep,
		prepare,
		readdata,
		senddata
		);
	signal state : state_type := reset;

---------------------------------------------------------------------------
-- Internal signal declarations
---------------------------------------------------------------------------
	signal fifo_ren		: std_logic						:= '0';
	signal fifo_wen		: std_logic						:= '0';
	signal fifo_rst		: std_logic						:= '1';
	signal fifo_empty	: std_logic						:= '1';
	signal fifo_full	: std_logic						:= '0';
	signal fifo_rdcount : std_logic_vector(9 downto 0);
	signal fifo_wrcount : std_logic_vector(9 downto 0);
	signal resetdone	: std_logic						:= '0';
	signal fifo_dout	: std_logic_vector(32 downto 0) := (others => '0');

	signal startupcounter : integer range 0 to 30       := 30;
	signal sendcounter	  : integer range 0 to 10       := 10;

	signal data_out_sr : std_logic_vector(32 downto 0)  := (others => '0');

	signal link_marker : std_logic					    := '0';
	signal link_out	   : std_logic_vector(2 downto 0)   := (others => '0');

	signal ddr1 : std_logic_vector(4 downto 0)          := (others => '0');
	signal ddr2 : std_logic_vector(4 downto 0)          := (others => '0');

	signal output_enable : std_logic                    := '1';

	signal ddr_out : std_logic_vector(4 downto 0)       := (others => '0');

begin  -- architecture behav

-------------------------------------------------------------------------------
-- connections
	fifo_wen <= data_valid and resetdone;
	output_enable <= not resetdone;

	ddr1(0) <= '0';  					--clock output
	ddr2(0) <= '1';--clock output

	ddr1(4 downto 2) <= link_out;
	ddr2(4 downto 2) <= link_out;

	ddr1(1) <= link_marker;
	ddr2(1) <= link_marker;	
	
	lff <= fifo_full;
------------------------------------------------------------------------------- 

	process
	begin
		wait until rising_edge(link_clk);
		fifo_ren	<= '0';
		link_marker <= '0';
		resetdone <= '1';		
		link_out	<= (others => '0');
		if rst = '1' then
			state <= reset;
		end if;
		
		case state is
			when reset =>
				resetdone <= '0';
				fifo_rst  <= '1';
				resetdone <= '0';
				if rst = '0' then
					state		   <= startup;
					startupcounter <= 30;
				end if;
				
			when startup =>
				resetdone <= '0';
				if startupcounter = 15 then
					fifo_rst <= '0';
				end if;
				if startupcounter = 0 then
					state	  <= sleep;
				else
					startupcounter <= startupcounter - 1;
				end if;

			when sleep =>
				if fifo_empty = '0' then
					fifo_ren <= '1';
					state	 <= prepare;
				end if;

			when prepare =>
				state <= readdata;

			when readdata =>
				data_out_sr <= fifo_dout;
				state		<= senddata;
				sendcounter <= 10;
				link_marker <= '1';

			when senddata =>
				link_out	<= data_out_sr(2 downto 0);
				data_out_sr <= "000" & data_out_sr(32 downto 3);
				if sendcounter = 0 then
					state <= sleep;
				else
					sendcounter <= sendcounter - 1; 
				end if;
		end case;
	end process;

---------------------------------------------------------------------------
-- Component instantiations
---------------------------------------------------------------------------

	data_out_ddrs : for i in 0 to 4 generate

		   IOBUFDS_inst : IOBUFDS
   generic map (
      IOSTANDARD => "BLVDS_25")
   port map (
      O => open,     -- Buffer output
      IO => vxs_lanes_p(i),   -- Diff_p inout (connect directly to top-level port)
      IOB => vxs_lanes_n(i), -- Diff_n inout (connect directly to top-level port)
      I => ddr_out(i),     -- Buffer input
      T => output_enable      -- 3-state enable input, high=input, low=output
   );
		
		ODDR_inst : ODDR
			generic map(
				DDR_CLK_EDGE => "SAME_EDGE",  -- "OPPOSITE_EDGE" or "SAME_EDGE" 
				INIT		 => '0',  -- Initial value for Q port ('1' or '0')
				SRTYPE		 => "SYNC")		  -- Reset Type ("ASYNC" or "SYNC")
			port map (
				Q  => ddr_out(i),				-- 1-bit DDR output
				C  => link_clk,				-- 1-bit clock input
				CE => '1',				-- 1-bit clock enable input
				D1 => ddr1(i),			-- 1-bit data input (positive edge)
				D2 => ddr2(i),			-- 1-bit data input (negative edge)
				R  => '0',				-- 1-bit reset input
				S  => '0'				-- 1-bit set input
				);
	end generate data_out_ddrs;

	FIFO_DUALCLOCK_MACRO_inst : FIFO_DUALCLOCK_MACRO
		generic map (
			DEVICE					=> "VIRTEX5",  -- Target Device: "VIRTEX5", "VIRTEX6" 
			ALMOST_FULL_OFFSET		=> X"0040",	 -- Sets almost full threshold
			ALMOST_EMPTY_OFFSET		=> X"0080",	 -- Sets the almost empty threshold
			DATA_WIDTH				=> 33,	-- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
			FIFO_SIZE				=> "36Kb",	-- Target BRAM, "18Kb" or "36Kb" 
			FIRST_WORD_FALL_THROUGH => false,  -- Sets the FIFO FWFT to TRUE or FALSE
			SIM_MODE				=> "SAFE")	-- Simulation "SAFE" vs "FAST", 
								-- see "Synthesis and Simulation Design Guide" for details
		port map (
			ALMOSTEMPTY => open,		-- Output almost empty 
			ALMOSTFULL	=> fifo_full,		-- Output almost full
			DO			=> fifo_dout,	-- Output data
			EMPTY		=> fifo_empty,	-- Output empty
			FULL		=> open,	-- Output full
			RDCOUNT		=> fifo_rdcount,	-- Output read count
			RDERR		=> open,		-- Output read error
			WRCOUNT		=> fifo_wrcount,	-- Output write count
			WRERR		=> open,		-- Output write error
			DI			=> data_in,		-- Input data
			RDCLK		=> link_clk,	-- Input read clock
			RDEN		=> fifo_ren,	-- Input read enable
			RST			=> fifo_rst,	-- Input reset
			WRCLK		=> data_clk,	-- Input write clock
			WREN		=> fifo_wen		-- Input write enable
			);
											-- End of FIFO_DUALCLOCK_MACRO_inst instantiation


end architecture behav;

-------------------------------------------------------------------------------
