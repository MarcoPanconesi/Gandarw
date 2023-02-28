----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:	   17:51:14 04/29/2008 
-- Design Name: 
-- Module Name:	   tcs_if VEN - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY UNISIM;
USE UNISIM.VCOMPONENTS.ALL;

entity tcs_if_VEN is
	generic (
		GEN_BOARD_TYPE : string	 := "GANDALF";
		GEN_GIMLI_TYPE : string := "TCS";
		GEN_IBUF_TYPE  : string := "BUFG"; -- BUFG, BUFR, NONE
--		GEN_TCS_RATE   : std_logic := '1';
		GEN_SLINK_DSP  : boolean := true;
		CHIPSCOPE      : boolean := false
		);
	port (
		-- tcs inputs
		TCS_CLK_N  : in	   std_logic;
		TCS_CLK_P  : in	   std_logic;
		TCS_DATA_N : in	   std_logic;
		TCS_DATA_P : in	   std_logic;
		TCS_LOCK   : in	   std_logic;
		-- smux reset clock
		CLK_40MHz_IN 	: in std_logic;
		-- fast register inputs
		FR_BOS : in std_logic;
		FR_EOS : in std_logic;
		FR_TRG : in std_logic;
		-- tcs outputs
		TCS_RATE  : out std_logic;
		TCS_CLK	  : out std_logic;		-- 155.52 MHz
		TCS_DATA  : out std_logic;
		TCS_RESET : out std_logic := '0';
		CLKOUT	  : out std_logic;		-- 38.88 MHz
		--CE38MHz   : out std_logic;
		BOS		  : out std_logic;
		EOS		  : out std_logic;
		FLT		  : out std_logic;
		-- event fifo
		EVENT_NO   : out std_logic_vector (19 downto 0);
		SPILL_NO   : out std_logic_vector (10 downto 0);
		EVENT_TYPE : out std_logic_vector (7 downto 0);
		FIFO_EMPTY : out std_logic;
		FIFO_FULL  : out std_logic;
		FIFO_RDCLK : in	 std_logic;
		FIFO_RDEN  : in	 std_logic;
		-- resets
		SMUX_RESET : out std_logic := '1';	-- active low
		RESET	   : in	 std_logic;
		-- chipscope
		CONTROL	   : inout std_logic_vector(35 downto 0)
		-- debug
		; tcs_error_phase : out  STD_LOGIC
		; tcs_error_chan : out  STD_LOGIC
		);
end tcs_if_VEN;

architecture Behavorial of tcs_if_VEN is

	signal TCS_DATA_DIFF  : std_logic;
	signal TCS_CLK_DIFF	  : std_logic;
	signal sDATOUT		  : std_logic;
	signal sFLT			  : std_logic;
	signal sCLKOUT		  : std_logic;
	signal sCE38MHz		  : std_logic;
													 --signal tcsCLKOUT			   : std_logic;
	signal STROBE		  : std_logic;
	signal sBOS			  : std_logic;
	signal sEOS			  : std_logic;
	signal NIM_TRG		  : std_logic;
	signal NIM_TRG_meta	  : std_logic			 := '0';
	signal NIM_TRG_sync	  : std_logic			 := '0';
	signal NIM_TRG_x	  : std_logic			 := '0';
	signal FR_TRGi		  : std_logic;
	signal sEVENT_NO       	: UNSIGNED (19 downto 0); -- it was std_logic_vector
	signal TCS_WORD		  : std_logic_vector (16 downto 0);
	signal FIFO_WREN	  : std_logic;
	signal FIFO_WRCLK     : std_logic;
	signal threePeriodBOS : integer range 0 to 3 := 3;
	signal twoPeriodEOS	  : integer range 0 to 2 := 2;
	signal EventToFIFO	  : std_logic;
	signal SaveEvent	  : std_logic;
	signal RESET_i		  : std_logic;
	signal RESET_fifo	  : std_logic;
	signal vsreset_done  : std_logic			 := '0';
	signal postFirstBOS  : std_logic			 := '0';
	type state_type is (
		st0_sleep,
		st1_bos,
		st2_eos,
		st3_greset,
										--st4_smuxreset
		st4_onspill
		); 
	signal state : state_type := st0_sleep;

	signal FIFO_DI	: std_logic_vector (35 downto 0) := (others => '0');
	signal FIFO_DO	: std_logic_vector (35 downto 0);
	signal count_a	: integer range 0 to 4			 := 4;
	signal count_aa : integer range 0 to 4			 := 4;
	signal count_b	: integer range 0 to 2			 := 2;
	signal count_c	: integer range 0 to 32767		 := 26;	 --12+14

	alias regEVENT_NO	: std_logic_vector (19 downto 0) is FIFO_DI(19 downto 0);
	--alias regSPILL_NO	: std_logic_vector (10 downto 0) is FIFO_DI(30 downto 20);
	alias regEVENT_TYPE : std_logic_vector (7 downto 0) is FIFO_DI(35 downto 28);

	signal TCS_CMD_ID : std_logic_vector (3 downto 0):="0000"; --not used in NA62
	alias TCS_CMD	 : std_logic_vector (7 downto 0) is TCS_WORD(13 downto 6);
	alias TCS_CHKSUM : std_logic_vector (4 downto 0) is TCS_WORD(5 downto 1);

	component TCS_DECODE_VEN
		port (DATA	   : in	 std_logic;
			  CLK	   : in	 std_logic;
			  CLKOUT   : out std_logic;
			  CE38MHz : out std_logic;
			  FLT    : out  STD_LOGIC;
			  TCS_WORD : out  STD_LOGIC_VECTOR (16 downto 0);
			  START  : out  STD_LOGIC
			  -- debug
			  ; tcs_error_phase : out  STD_LOGIC
			  ; tcs_error_chan : out  STD_LOGIC
		   );
	end component;
	
begin	
--	ratenormal : if GEN_GIMLI_TYPE /= "VXS" generate
--		TCS_RATE <= GEN_TCS_RATE;
--	end generate ratenormal;
--	rateled : if GEN_GIMLI_TYPE = "VXS" generate
--		TCS_RATE <= TCS_LOCK;
--	end generate rateled;

	RESET_i	<= RESET OR sBOS OR FR_BOS;

	atigertcs : if GEN_IBUF_TYPE = "NONE" generate
		TCS_CLK_DIFF <= TCS_CLK_P;
	end generate atigertcs;

	use_BUFR_TCS_CLK	:	if  GEN_IBUF_TYPE = "BUFR" generate
		signal TCS_CLK_DIFF_i   	: std_logic;
		attribute buffer_type: string;
		attribute buffer_type of TCS_CLK_DIFF_i: signal is "bufr";
	begin
		in_clk : IBUFDS
				generic map (
				IOSTANDARD => "LVDS_25",
				DIFF_TERM  => TRUE
				)
				port map (
					I=>	TCS_CLK_P,
					IB=>TCS_CLK_N,
					O=>	TCS_CLK_DIFF_i
				);
				
		TCS_CLK_DIFF <= TCS_CLK_DIFF_i;

	end generate;

	use_BUFG_TCS_CLK	:	if  GEN_IBUF_TYPE = "BUFG" generate
		in_clk : IBUFGDS
					generic map (
					IOSTANDARD => "LVDS_25",
					DIFF_TERM  => TRUE
					)
					port map (
						I=>	TCS_CLK_P,
						IB=>TCS_CLK_N,
						O=>	TCS_CLK_DIFF
					);
	end generate;	

	TCS_CLK <= TCS_CLK_DIFF;


	inst_tcs_trg : if GEN_GIMLI_TYPE = "TCS" or GEN_GIMLI_TYPE = "VXS" generate

		ctigertcs : if GEN_IBUF_TYPE = "NONE" generate
			TCS_DATA_DIFF <= TCS_DATA_P;
		end generate ctigertcs;
		dtigertcs : if GEN_IBUF_TYPE /= "NONE" generate
			in_data : IBUFDS
				generic map (
					IOSTANDARD => "LVDS_25",
			DIFF_TERM  => TRUE
					)
				port map (
					I  => TCS_DATA_P,
					IB => TCS_DATA_N,
					O  => TCS_DATA_DIFF
					);
		end generate dtigertcs;


		TCS_DATA <= TCS_DATA_DIFF;

		gen_smux_res : if (GEN_BOARD_TYPE = "GANDALF" and GEN_SLINK_DSP = TRUE) generate
			SMUX_RES : process(CLK_40MHz_IN)
			begin

				if (CLK_40MHz_IN = '0' and CLK_40MHz_IN'event) then	 ---try inverse
					
					SMUX_RESET <= '1';

					if RESET = '0' then
						if count_c /= 0 then
							count_c <= count_c-1;
						end if;
					end if;

					if sBOS = '1' then
						count_c <= 32766;
					end if;

					if vsreset_done = '0' then
						if count_c = 25 or count_c = 24 then
							SMUX_RESET <= '0';
						end if;
					end if;

					if count_c = 2 or count_c = 1 then
						SMUX_RESET	 <= '0';
						vsreset_done <= '1';
					end if;
					
				end if;
				
			end process;
		end generate;

		no_smux_res	: if (GEN_BOARD_TYPE = "GANDALF" and GEN_SLINK_DSP = FALSE) generate
			SMUX_RESET <= 'Z';
		end generate;
		
		EVENT_NO   <= FIFO_DO(19 downto 0);
		SPILL_NO   <= FIFO_DO(30 downto 20);
		EVENT_TYPE <= FIFO_DO(35 downto 28);
		BOS		   <= sBOS;
		EOS		   <= sEOS;

		-- no write to FIFO at reset or pre first BOS
		--FIFO_WREN <= EventToFIFO and ( not RESET_fifo ) and ( postFirstBOS );
		FIFO_WREN <= EventToFIFO;
		
		-- no FLT at reset or pre first BOS
		--FLT <= sFLT and ( not RESET_fifo ) and ( postFirstBOS );
		FLT <= sFLT ; --NA62 test pass it out whenever
		
		FIFO_WRCLK <= TCS_CLK_DIFF; 										

		--Count events internally (NA62)
		count_events: process(TCS_CLK_DIFF)
		begin
			if (TCS_CLK_DIFF = '1' and TCS_CLK_DIFF'event) then
				if(sCE38MHz='1') then
					if sFLT = '1' then
						sEVENT_NO <= sEVENT_NO+1;
					end if;
					
					if sBOS = '1' then
						sEVENT_NO <= (others => '0');
					end if;
				end if;
			end if;			
		end process;

				
		on_rising_strobe: process (TCS_CLK_DIFF)
		begin
										-- on rising edge of STROBE
			if (TCS_CLK_DIFF = '1' and TCS_CLK_DIFF'event) then
			
				regEVENT_NO 	<= std_logic_vector(sEVENT_NO);
				regEVENT_TYPE 	<= TCS_CMD(7 downto 0);
				
				if(STROBE = '1') then
				
							EventToFIFO		<= '1';
							
--					case TCS_CMD_ID is
--						when "0001" =>	-- BC1
--							regSPILL_NO(10 downto 0) <= TCS_CMD(10 downto 0);
--										--GEAENDERT 03.04.12
--							if TCS_CMD(13) = '1' then
--								regEVENT_NO(19 downto 8) <= x"000";
--							end if;
--										--------------------------------------
--							EventToFIFO <= '0';
--						when "0110" =>	-- BC2 Part 1
--							regEVENT_NO(7 downto 0)	  <= TCS_CMD(15 downto 8);
--							regEVENT_TYPE(4 downto 0) <= TCS_CMD(4 downto 0);
--							EventToFIFO				  <= '1';
--						when "0111" =>	-- BC2 Part 2
--							regEVENT_NO(19 downto 8) <= TCS_CMD(11 downto 0);
--							EventToFIFO				 <= '0';
--						when others =>
--							EventToFIFO <= '0';
--					end case;
				else
					EventToFIFO <= '0';
				end if;
			end if;
		end process;


		inst_tcs_decode : TCS_DECODE_VEN
			port map (CLK	   => TCS_CLK_DIFF,
					  DATA	   => TCS_DATA_DIFF,
					  CLKOUT   => CLKOUT,
					  CE38MHz  => sCE38MHz,
					  FLT	   => sFLT,
					  TCS_WORD => TCS_WORD,
					  START	   => STROBE
					--debug
					, tcs_error_phase => tcs_error_phase
					, tcs_error_chan => tcs_error_chan
					);


		BOS_EOS : process(TCS_CLK_DIFF)
		begin
			if (TCS_CLK_DIFF = '1' and TCS_CLK_DIFF'event) then
				if(sCE38MHz='1') then
					sBOS <= '0';
					sEOS <= '0';
	
					if RESET = '0' then
						reset_fifo <= '0';
					else
						reset_fifo <= '1';
					end if;
	
					if reset_i = '1' then
						count_a <= 4;
					end if;
	
					if count_a /= 0 then
						count_a	   <= count_a-1;
					end if;
	
					case state is
						
						when st0_sleep =>
							TCS_RESET <= '0';
							count_b	  <= 2;
							--if TCS_CMD(13) = '1' and TCS_CMD_ID = "0001" then
							--if TCS_CMD = b"10001011" then --expected NA62 BOS
							if TCS_CMD(1 downto 0) = b"11" then --NA62 BOS
								state		   <= st1_BOS;
								threePeriodBOS <= 3;
							end if;							
							
						when st1_BOS =>
							sBOS		   <= '1';
							postFirstBOS   <= '1';
							threePeriodBOS <= threePeriodBOS-1;
							if threePeriodBOS = 1 then		
								state <= st4_onspill;
							end if;
							
						when st2_EOS =>
							sEOS		 <= '1';
							twoPeriodEOS <= twoPeriodEOS-1;
							if twoPeriodEOS = 1 then
								state	<= st3_greset;
								count_a <= 3;
							end if;
							
						when st4_onspill =>
							--if TCS_CMD(14) = '1' AND TCS_CMD_ID = "0001" then			
							--if TCS_CMD = b"10001110" then	--expected NA62 EOS		
							if TCS_CMD(1 downto 0) = b"10" then	--expected NA62 EOS		
								state		 <= st2_EOS;
								twoPeriodEOS <= 2;
							end if;
							
						when st3_greset =>
							count_a	  <= count_a-1;
							TCS_RESET <= '1';
							if count_a = 1 then
								state	<= st0_sleep;
								count_a <= 3;
							end if;
	
						when others =>
							state <= st0_sleep;
					end case;
				end if;
			end if;
		end process;
	end generate;


	inst_GIMLI_OCXO : if GEN_GIMLI_TYPE = "OCX" generate

		in_data : IBUFDS
		generic map( DIFF_TERM => TRUE)
			port map (I	 => TCS_DATA_P,
					  IB => TCS_DATA_N,
					  O	 => NIM_TRG);



		nim_sync : process(FIFO_RDCLK)
		begin
			if (FIFO_RDCLK = '1' and FIFO_RDCLK'event) then
				NIM_TRG_meta <= not(NIM_TRG);
				if (NIM_TRG_x = '0' and NIM_TRG_meta = '1') then
					NIM_TRG_sync <= '1';
					NIM_TRG_x	 <= '1';
				elsif (NIM_TRG_meta = '0') then
					NIM_TRG_sync <= '0';
					NIM_TRG_x	 <= '0';
				else
					NIM_TRG_sync <= '0';
				end if;
			end if;
		end process;


		TCS_DATA <= NIM_TRG_sync;
		FR_TRGi	 <= NIM_TRG_sync or FR_TRG;
		FLT		 <= FR_TRGi;

		FIFO_WRCLK <= FIFO_RDCLK;	  --this is needed for FIFO readout see below..
		CLKOUT	<= TCS_CLK_DIFF;  --this is routed to si_if for phase calibration


		EVENT_NO <= FIFO_DO(19 downto 0);
		SPILL_NO <= "00000000001";
		sBOS	 <= '0';
		BOS		 <= FR_BOS;
		EOS		 <= FR_EOS;


		EVENT_CNT : process(FIFO_RDCLK)
		begin
			
			if (FIFO_RDCLK = '1' and FIFO_RDCLK'event) then
				
				reset_fifo <= '0';

				if reset_i = '1' then
					--EVENT_TYPE <= "11011";
					sEVENT_NO  <= (others => '0');
					count_aa   <= 3;
				end if;

				if count_aa /= 0 then
					count_aa   <= count_aa-1;
					reset_fifo <= '1';
				end if;

				if FR_BOS = '1' then
					sEVENT_NO  <= (others => '0');
					EVENT_TYPE <= "00000000";
				end if;

				if FR_EOS = '1' then
					EVENT_TYPE <= "00000000";
				end if;

				SaveEvent <= '0';
				if FR_TRGi = '1' then
					sEVENT_NO <= sEVENT_NO+1;
					SaveEvent <= '1';
				end if;

				FIFO_WREN <= '0';
				if SaveEvent = '1' then
					regEVENT_NO <= std_logic_vector(sEVENT_NO);
					FIFO_WREN	<= '1';
				end if;
				
				
			end if;
			
		end process;
	end generate;




	FIFO36_inst : FIFO36
		generic map (
			ALMOST_FULL_OFFSET		=> X"0080",	 -- Sets almost full threshold
			ALMOST_EMPTY_OFFSET		=> X"0080",	 -- Sets the almost empty threshold
			DATA_WIDTH				=> 36,	-- Sets data width to 4, 9, 18, or 36
			DO_REG					=> 1,  -- Enable output register ( 0 or 1)	  -- Must be 1 if the EN_SYN = FALSE
		EN_SYN => FALSE, -- Specified FIFO as Asynchronous (FALSE) or Synchronous (TRUE)
		FIRST_WORD_FALL_THROUGH => FALSE) -- Sets the FIFO FWFT to TRUE or FALSE
		port map (
			DI			=> FIFO_DI(31 downto 0),   -- 32-bit data input
			DIP			=> FIFO_DI(35 downto 32),  -- 4-bit parity input
			DO			=> FIFO_DO(31 downto 0),   -- 32-bit data output
			DOP			=> FIFO_DO(35 downto 32),  -- 4-bit parity data output
			EMPTY		=> FIFO_EMPTY,	-- 1-bit empty output flag
			FULL		=> FIFO_FULL,	-- 1-bit full output flag
			RDERR		=> open,		-- 1-bit read error output
			WRERR		=> open,		-- 1-bit write error
			WRCLK		=> FIFO_WRCLK,	-- 1-bit write clock input
			WREN		=> FIFO_WREN,	-- 1-bit write enable input
			RDCLK		=> FIFO_RDCLK,	-- 1-bit read clock input
			RDEN		=> FIFO_RDEN,	-- 1-bit read enable input
			RST			=> RESET_fifo,	-- 1-bit reset input
			ALMOSTEMPTY => open,		-- 1-bit almost empty output flag
			ALMOSTFULL	=> open,		-- 1-bit almost full output flag
			RDCOUNT		=> open,		-- 13-bit read count output
			WRCOUNT		=> open			-- 13-bit write count output

			);

end Behavorial;
