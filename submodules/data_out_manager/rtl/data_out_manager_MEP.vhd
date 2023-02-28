-------------------------------------------------------------------------------
-- Title	  : Data output manager_MEP
-- Project	  : test project
-------------------------------------------------------------------------------
-- File		  : data_out_manager.vhd
-- Author	  :	  <grussy@pcfr16.physik.uni-freiburg.de>
-- Company	  : 
-- Created	  : 2014-01-07
-- Last update: 2023-01-17
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
-- 2023-01-17  3.0      Marco   Introducing and managing MEP format
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

-------------------------------------------------------------------------------

entity data_out_manager_MEP is
	port (
-------------------------------------------------------------------------------
-- control stuff
		fr_out_manager  : in  std_logic_vector(2 downto 0);
		slink_clk	    : in  std_logic; --40 MHz
		flt_err		    : in  std_logic;
		ev_num_err	    : in  std_logic;
-------------------------------------------------------------------------------



-------------------------------------------------------------------------------
-- Inputs data_out_main_FIFO
		data_clk	    : in  std_logic; --TCS_CLK 155 MHz
		data_in		    : in  std_logic_vector(32 downto 0); --dati per la data_out_main_FIFO
		data_wen	    : in  std_logic;
		fifo_prog_full  : out std_logic;
-------------------------------------------------------------------------------
--Inputs header_FIFO
        --data_clk -> stesso definito sopra
        --header_fifo_din		    : in std_logic_vector(32 downto 0);
        header_fifo_wr_en		: in std_logic;
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

end entity data_out_manager_MEP;

-------------------------------------------------------------------------------

architecture behav of data_out_manager_MEP is
-------------------------------------------------------------------------------
-- main fifo
	component data_out_main_fifo  --FIFO con la parte di dati del pacchetto
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

	signal data_fifo_rd_en	   : std_logic;
	signal arwen_data_out	   : std_logic_vector(32 downto 0);
	signal data_fifo_prog_full : std_logic;
	signal data_fifo_empty	   : std_logic;
	signal data_fifo_valid	   : std_logic;
-------------------------------------------------------------------------------


----------header_fifo_1 : header_fifo
	component header_fifo 
		port(
			clk	  	  : in	std_logic;			
			din		  : in	std_logic_vector(32 downto 0);
			wr_en	  : in	std_logic;
			rd_en	  : in	std_logic;
			dout	  : out std_logic_vector(32 downto 0);
			full	  : out std_logic;
			empty	  : out std_logic;
			valid	  : out std_logic
			);
	end component;		
			-----------------------------------------------------

	signal header_fifo_wr_clk	    : std_logic;
	signal header_fifo_rd_clk	    : std_logic;
	--signal header_fifo_din		    : std_logic_vector(32 downto 0);
	--signal header_fifo_wr_en		: std_logic;
	signal header_fifo_rd_en		: std_logic;
	signal header_fifo_prog_full   : std_logic;
	signal header_fifo_empty		: std_logic;
	signal header_fifo_valid		: std_logic;
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

-------------------------------------------------------------------------------
-- state
	type state_t is (
		idle,
		read_1,
		read_2,
		read_data
	);
	signal read_MEP : state_t := idle;




-- arwen
	signal data_fifo_out    : std_logic_vector(32 downto 0);  
	signal header_fifo_out  : std_logic_vector(32 downto 0); 

	
	
	attribute safe_implementation				 : string;
	attribute safe_implementation of state	 : signal is "yes";	
	
	attribute safe_recovery_state				 : string;
	attribute safe_recovery_state of state	 : signal is "poweron";	
-------------------------------------------------------------------------------
-- error
signal frame_dim_err  : std_logic;

-------------------------------------------------------------------------------

signal MEP_length     : integer range 0 to 65535:= 0; --  range 0 to 65535; --lunghezza totale MEP

signal header_cnt : integer range 0 to 2 := 0;






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
	fifo_prog_full <= data_fifo_prog_full;
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
 


-------------------------------------------------------------------------------
-- main state machine (data from main fifo to arwen)
	process
	
	variable cnt_a          : integer range 0 to 1; 
	

	begin
		wait until rising_edge(data_clk);
		--always forward fifo out to all inputs
		--spy_data	    <= arwen_data_out(31 downto 0); --uscita dalla MAIN_FIFO riempita con i dati nel slink_data proveniente da data_out_logic
		--vxs_data	    <= arwen_data_out;


		--SISTEMA1 header_fifo_din  <= arwen_data_out;
        -- arwen added always on ...
        --arwen_data      <= arwen_data_out(31 downto 0); --DA SPOSTARE NEL CASE! Devo switchare tra main_fifo e header_fifo

		--defaults
		--SISTEMA1 header_fifo_wr_en <= '0';
		vxs_data_valid	 <= '0';
		spy_wen			 <= '0';
		data_fifo_rd_en	 <= '0';
		vxs_rst			 <= '1';
        arwen_rst        <= '0';
		frame_dim_err 	 <= '0';

			-- ARWEN

			case read_MEP is

				when idle => 

					header_fifo_rd_en <= '0';
					arwen_wen <= '0';
					read_MEP <= idle;
					
					if (header_fifo_empty = '0') then --così sono sicuro di aver scritto le due parole su arwen
						read_MEP <= read_1;
						header_fifo_rd_en <= '1';
					end if;
										

				when read_1 => --LEGGO 1 RIGA HEADER MEP

					arwen_data      <= header_fifo_out(31 downto 0);  --leggo 1 riga header MEP
					arwen_add       <= "00" & count_add; --Scelto del link_ottico in uscita (parto da quello 0 e poi lo modifico fino a 3 successivamente nel codice)									
					read_MEP <= read_1;

					if (arwen_ff(to_integer(unsigned(count_add))) /= '1') then
						header_fifo_rd_en <= '1';
						arwen_wen <= '1';
						read_MEP <= read_2;
					end if;

					

				when read_2 => --LEGGO 2 RIGA HEADER MEP

					arwen_data      <= header_fifo_out(31 downto 0);  --leggo 2 riga header MEP
					arwen_add       <= "00" & count_add; --Scelto del link_ottico in uscita (parto da quello 0 e poi lo modifico fino a 3 successivamente nel codice)				
					MEP_length <= to_integer(unsigned(header_fifo_out(15 downto 2))) - 2;
					read_MEP <= read_2;
					
					if (arwen_ff(to_integer(unsigned(count_add))) /= '1') then
						header_fifo_rd_en <= '0';
						arwen_wen <= '1';
						data_fifo_rd_en <= '1';
						read_MEP <= read_data;
					end if;



				when read_data => --LEGGO DATI MEP

					arwen_data 		<= data_fifo_out(31 downto 0); --mi collego alla FIFO dei dati
					arwen_add       <= "00" & count_add; --Scelto del link_ottico in uscita
					
					
					if (MEP_length /= 0) then
						read_MEP <= read_data;
						if ( arwen_ff(to_integer(unsigned(count_add))) /= '1') then --link ottico non occupato
							data_fifo_rd_en <= '1'; --abilito lettura
							arwen_wen <= '1';
							MEP_length <= MEP_length - 1;
						end if;
					else 
						
							arwen_wen <= '0'; --metti a 1 se vuoi scrivere il footer
							data_fifo_rd_en <= '0';
							read_MEP <= idle; 
							if (data_fifo_out(31 downto 0) = x"cfed1200") then --leggo il footer
																

								if (count_add /= "11") then
									count_add <= count_add + 1; --passo al link_ottico successivo
								else 
									count_add <= "00"; --ritorno al primo link ottico se ero all'ultimo
								end if;
							else 
								frame_dim_err <= '1';	
							end if;											
					end if;

					when others =>
						read_MEP <= idle;

			end case;

	
		----------------  SPY_FIFO  ----------------------------------------------------------------------------
		--Se viene richiesto di inviare i dati nella SPY_FIFO (fr_state(2)=1) oppure se ci sono errori -> abilita scrittura nella SPY_FIFO
		--La SPY_FIFO serve da debug per verificare i dati in qualsiasi momento. I dati arrivano in parallelo a questa FIFO.

		if fr_state(2) = '1' or flt_err = '1' or ev_num_err = '1' then --se uno di questi è a 1 ()
			if (read_MEP = idle) then
				spy_wen		<= '0';
			
			elsif (read_MEP /= read_data) then  						--read_1, read_2
				spy_data	<= header_fifo_out(31 downto 0);
				spy_wen		<= '1';
			else 														--read_data	
				spy_data	<= data_fifo_out(31 downto 0);														
				if(data_fifo_out(31 downto 0) = x"cfed1200")	then
					spy_wen		<= '0'; 
				else															
					spy_wen		<= '1'; 
				end if;
			end if;
			--se sono nello stato RESET ARWEN:
			--modifico l'abilitazione alla lettura della MAIN_FIFO cosi: 1:se MAIN_FIFO non è vuota  e SPY_FIFO non è FULL
			--															 0:se una qualsiasi delle due sopra non è cosi.
			if fr_state(1 downto 0) = "00" then
				data_fifo_rd_en <= data_fifo_empty nor spy_full;
			end if;
		end if;
		----------------------------------------------------------------------------------------------------------
	end process;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- main fifo
	data_fifo_1 : data_out_main_fifo
		port map (
			clk	  => data_clk,
			din	  => data_in, --MEP_data da data_out_logic
			wr_en => data_wen,
			rd_en => data_fifo_rd_en,
			dout  => data_fifo_out,
			full  => open,
			empty => data_fifo_empty,
			valid => data_fifo_valid,
			prog_full => data_fifo_prog_full
		);
------------------------------------------------------------------------------- 

-------------------------------------------------------------------------------
-- header_fifo
	header_fifo_1 : header_fifo
		port map (
			clk	  	  => data_clk, --tutto 155 MHz
			din		  => data_in,
			wr_en	  => header_fifo_wr_en,
			rd_en	  => header_fifo_rd_en,
			dout	  => header_fifo_out,
			full	  => open,
			empty	  => header_fifo_empty,
			valid	  => header_fifo_valid
		);
-------------------------------------------------------------------------------

end architecture behav;

-------------------------------------------------------------------------------
