-------------------------------------------------------------------------------
-- Title	  : Data output mangager
-- Project	  : test project
-------------------------------------------------------------------------------
-- File		  : data_out_manager.vhd
-- Author	  :	  <grussy@pcfr16.physik.uni-freiburg.de>
-- Company	  : 
-- Created	  : 2014-01-07
-- Last update: 2014-12-11
-- Platform	  : 
-- Standard	  : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Manages the data output of gandalf
-------------------------------------------------------------------------------
-- Copyright (c) 2014 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date		   Version	Author	Description
-- 2014-01-07  1.0		grussy	Created
-- 2014-11-27  2.0		grussy	Using fifo prog full (bugfix)
-- 2021-07-77  2.1		Alex    added Arwen data output (always on)
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

-------------------------------------------------------------------------------

entity data_out_manager is
	port (
-------------------------------------------------------------------------------
-- control stuff
		fr_out_manager  : in  std_logic_vector(2 downto 0);
		slink_clk	    : in  std_logic; --40 MHz
		flt_err		    : in  std_logic;
		ev_num_err	    : in  std_logic;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Inputs
		data_clk	    : in  std_logic; --TCS_CLK
		data_in		    : in  std_logic_vector(32 downto 0); --slink_data
		data_wen	    : in  std_logic;
		fifo_prog_full  : out std_logic;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- SpyRead
        spy_data        : out std_logic_vector(31 downto 0);
        spy_wen	        : out std_logic;
        spy_clk	        : out std_logic;
        spy_full        : in  std_logic;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Arwen
        arwen_data      : out std_logic_vector(31 downto 0);
        arwen_ff 	    : in  std_logic_vector( 3 downto 0);
        arwen_wen	    : out std_logic;
        arwen_clk	    : out std_logic;
        arwen_add       : out std_logic_vector( 3 downto 0);
        arwen_rdy       : in  std_logic;
        arwen_rst       : out std_logic;
-------------------------------------------------------------------------------





--PER IL MOMENTO TRALASCIO  DA QUI:-----------------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-- VXS to Tiger
		vxs_data	    : out std_logic_vector(32 downto 0);
		vxs_data_valid  : out std_logic;
		vxs_data_clk    : out std_logic;
		vxs_rst		    : out std_logic;
		vxs_lff		    : in  std_logic;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- SLINK
		UD	            : out std_logic_vector (31 downto 0);
		LFF	            : in  std_logic;
		URESET          : out std_logic;
		UTEST           : out std_logic;
		UDW	            : out std_logic_vector (1 downto 0);
		UCTRL           : out std_logic;
		UWEN            : out std_logic;
		UCLK            : out std_logic;
		LDOWN           : in  std_logic
-------------------------------------------------------------------------------
--FINO A QUI.---------------------------------------------------------------------------------------------------------------






		);

end entity data_out_manager;

-------------------------------------------------------------------------------

architecture behav of data_out_manager is
-------------------------------------------------------------------------------
-- main fifo
	component data_out_main_fifo
		port (
			clk		  : in	std_logic;
			din		  : in	std_logic_vector(32 downto 0);
			wr_en	  : in	std_logic;
			rd_en	  : in	std_logic;
			dout	  : out std_logic_vector(32 downto 0);
			full	  : out std_logic;
			empty	  : out std_logic;
			valid	  : out std_logic;
			prog_full : out std_logic
			);
	end component;

	signal main_fifo_rd_en	   : std_logic;
	signal main_fifo_dout	   : std_logic_vector(32 downto 0);
	signal main_fifo_prog_full : std_logic;
	signal main_fifo_empty	   : std_logic;
	signal main_fifo_valid	   : std_logic;
-------------------------------------------------------------------------------




--PER IL MOMENTO TRALASCIO  DA QUI:-----------------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- to slink fifo
	component to_slink_fifo
		port (
			wr_clk	  : in	std_logic;
			rd_clk	  : in	std_logic;
			din		  : in	std_logic_vector(32 downto 0);
			wr_en	  : in	std_logic;
			rd_en	  : in	std_logic;
			dout	  : out std_logic_vector(32 downto 0);
			full	  : out std_logic;
			empty	  : out std_logic;
			valid	  : out std_logic;
			prog_full : out std_logic			
			);	
	end component;

	signal slink_fifo_wr_clk	: std_logic;
	signal slink_fifo_rd_clk	: std_logic;
	signal slink_fifo_din		: std_logic_vector(32 downto 0);
	signal slink_fifo_wr_en		: std_logic;
	signal slink_fifo_rd_en		: std_logic;
	signal slink_fifo_dout		: std_logic_vector(32 downto 0);
	signal slink_fifo_prog_full : std_logic;
	signal slink_fifo_empty		: std_logic;
	signal slink_fifo_valid		: std_logic;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- slink
	signal slink_lff   : std_logic;
	signal slink_reset : std_logic;
	signal slink_cw	   : std_logic;
	signal slink_wen   : std_logic;
	signal slink_ldown : std_logic;
-------------------------------------------------------------------------------
-- FINO A QUI --------------------------------------------------------------------------------------------------------------




-------------------------------------------------------------------------------
-- main state machine and fastregisters
	signal fr_out_manager_r : std_logic_vector(2 downto 0) := "000";
	signal fr_state			: std_logic_vector(2 downto 0) := "000";
    signal count_add        : std_logic_vector(1 downto 0) := "00";

-------------------------------------------------------------------------------
-- arwen

-------------------------------------------------------------------------------
-- slink output state machine
	type state_type is (
		poweron,
		link_down,
		do_reset,
		wait4cyc,
		link_up
		);
	signal state		 : state_type			   := link_down;
	signal wait4cnt		 : integer range 0 to 4	   := 0;
	signal ldown_counter : integer range 0 to 7000 := 0;


	
	
	attribute safe_implementation				 : string;
	attribute safe_implementation of state	 : signal is "yes";	
	
	attribute safe_recovery_state				 : string;
	attribute safe_recovery_state of state	 : signal is "poweron";	
-------------------------------------------------------------------------------

begin  -- architecture behav
-------------------------------------------------------------------------------
-- static slink stuff
	slink_lff	<= not LFF;
	URESET		<= not slink_reset;
	UTEST		<= '1';					--disable testmode
	UDW			<= "00";				--data width 32 Bits
	UCTRL		<= not slink_cw;
	UWEN		<= not slink_wen;
	UCLK		<= slink_clk;
	slink_ldown <= not LDOWN;

-- static vxs stuff
	vxs_data_clk <= data_clk;

-- static spy stuff
    spy_clk <= data_clk;

-- static arwen stuff
    arwen_clk <= data_clk;

-- other static stuff
	fifo_prog_full <= main_fifo_prog_full;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- clock in the Fastregisters:
	process
	begin
		wait until rising_edge(data_clk);
		fr_out_manager_r <= fr_out_manager;
		fr_state		 <= fr_out_manager_r;
	end process;
------------------------------------------------------------------------------- 
 

--DA MODIFICARE--------------------------------------------------------------------------->>>>>>>>>>>>
-------------------------------------------------------------------------------
-- main state machine (data from main fifo to either slink, spy, vxs or arwen)
	process
	begin
		wait until rising_edge(data_clk);
		--always forward fifo out to all inputs
		spy_data	    <= main_fifo_dout(31 downto 0); --uscita dalla MAIN_FIFO riempita con i dati nel slink_data proveniente da data_out_logic
		vxs_data	    <= main_fifo_dout;
		slink_fifo_din  <= main_fifo_dout;
        -- arwen added always on ...
        arwen_data      <= main_fifo_dout(31 downto 0);

		--defaults
		slink_fifo_wr_en <= '0';
		vxs_data_valid	 <= '0';
		spy_wen			 <= '0';
		main_fifo_rd_en	 <= '0';
		vxs_rst			 <= '1';
        arwen_rst        <= '0';

		case fr_state(1 downto 0) is
			when "01" =>				-- slink									--|
				slink_fifo_wr_en <= main_fifo_valid;								--|	
				main_fifo_rd_en	 <= main_fifo_empty nor slink_fifo_prog_full;		--| non vuota la main fifo, non piena la slink fifo
																					--|
			when "10" =>				-- vxs										--| NON UTILIZZATA
				vxs_rst			<= '0';												--|
				vxs_data_valid	<= main_fifo_valid;									--|
				main_fifo_rd_en <= main_fifo_empty nor vxs_lff;						--|
																					--|
            when "11" =>				-- ARWEN 
                arwen_wen       <= main_fifo_valid; --Abilitazione alla scrittura su ARWEN
                arwen_add       <= "00" & count_add; --Scelto del link_ottico in uscita (parto da quello 0 e poi lo modifico fino a 3 successivamente nel codice)
				--Abilito lettura MAIN_FIFO.
				--1: se sono entrambi 0 (la main_fifo NON è vuota + il link_ottico scelto non è occupato)
				--0: se anche solo uno è a 1 (c'è un problema)
                main_fifo_rd_en	<= main_fifo_empty nor arwen_ff(to_integer(unsigned(count_add)));   -- aggiunto controllo con la fifo dell'arwen ...
				--se nella MAIN_FIFO leggo la END_WORD (e il dato è valido per essere scritto su arwen [arwen_wen <= main_fifo_valid]) allora passo al successivo link ottico
                if ((main_fifo_dout(31 downto 0) = x"cfed1200") and (main_fifo_valid = '1')) then   -- ultimo dato della fifo, scambio indirizzo ...
                    count_add <= count_add + 1; --passo al link_ottico successivo
                end if; 

            when "00" => 				--RESET ARWEN
                count_add <= (others => '0');
                arwen_add <= "0000";
                arwen_rst <= '1';
			when others =>
				null;	
			
		end case;
																									-- allow the data to be send to the spy fifo all the time;
																									-- when some error appears, write words to spy fifo; TODO: maybe generalize this
		--Se viene richiesto di inviare i dati nella SPY_FIFO (fr_state(2)=1) oppure se ci sono errori -> abilita scrittura nella SPY_FIFO
		--La SPY_FIFO serve da debug per verificare i dati in qualsiasi momento. I dati arrivano in parallelo a questa FIFO.
		if fr_state(2) = '1' or flt_err = '1' or ev_num_err = '1' then --se uno di questi è a 1 ()
			spy_wen			<= main_fifo_valid; -- attivo scrittura SPY_FIFO
			-- data to spy fifo controls the main fifo only, when the other drains are off
			--se sono nello stato RESET ARWEN:
			--modifico l'abilitazione alla lettura della MAIN_FIFO cosi: 1:se MAIN_FIFO non è vuota  e SPY_FIFO non è FULL
			--															 0:se una qualsiasi delle due sopra non è cosi.
			if fr_state(1 downto 0) = "00" then
				main_fifo_rd_en <= main_fifo_empty nor spy_full;
			end if;
		end if;
	end process;
-------------------------------------------------------------------------------

------------------------------------------------------------------------------- NON CI INTERESSA
-- slink output
	process
	begin
		wait until rising_edge(slink_clk);
		UD		  <= slink_fifo_dout(31 downto 0);
		slink_cw  <= slink_fifo_dout(32);
		slink_wen <= slink_fifo_valid;

		wait4cnt		 <= 0;
		ldown_counter	 <= 0;
		slink_reset		 <= '0';
		slink_fifo_rd_en <= '0';
		case state is
			when poweron =>
				--wait for ldown
				if slink_ldown = '0' then
					state <= wait4cyc;
				end if;
				
			when link_down =>
				--link went down somehow, maybe reset some fifos?
				state <= do_reset;

			when do_reset =>
				--wait for the link to come up on its own!
				if slink_ldown = '0' then
					state <= link_up;
					--try a reset, because link doesn't come up
				elsif ldown_counter > 5000 then
					slink_reset <= '1';
				end if;

				ldown_counter <= ldown_counter + 1;	 --overflows at 7000 so we have 2000 cycles reset

			when wait4cyc =>
				wait4cnt <= wait4cnt + 1;
				if wait4cnt = 4 then
					state <= link_up;
				end if;
				
			when link_up =>
				if slink_ldown = '1' then
					state <= link_down;
				else
					slink_fifo_rd_en <= slink_fifo_empty nor slink_lff;
				end if;
		end case;
	end process;
------------------------------------------------------------------------------- 

-------------------------------------------------------------------------------
-- main fifo
	data_out_main_fifo_1 : data_out_main_fifo
		port map (
			clk	  => data_clk,
			din	  => data_in, --slink_data da data_out_logic
			wr_en => data_wen,
			rd_en => main_fifo_rd_en,
			dout  => main_fifo_dout,
			full  => open,
			empty => main_fifo_empty,
			valid => main_fifo_valid,
			prog_full => main_fifo_prog_full);
------------------------------------------------------------------------------- 

-------------------------------------------------------------------------------
-- slink fifo
	to_slink_fifo_1 : to_slink_fifo
		port map (
			wr_clk	  => data_clk, --si scrive a 155MHz
			rd_clk	  => slink_clk, --si legge a 40MHz
			din		  => slink_fifo_din,
			wr_en	  => slink_fifo_wr_en,
			rd_en	  => slink_fifo_rd_en,
			dout	  => slink_fifo_dout,
			full	  => open,
			empty	  => slink_fifo_empty,
			valid	  => slink_fifo_valid,
			prog_full => slink_fifo_prog_full);
-------------------------------------------------------------------------------

end architecture behav;

-------------------------------------------------------------------------------
