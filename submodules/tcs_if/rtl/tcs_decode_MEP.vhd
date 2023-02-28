----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:10:02 04/01/2023 
-- Design Name: 
-- Module Name:    TCS_DECODE_MEP - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
				
-- Additional Comments: ADDED ECRST and BCRST signals
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
--USE IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity TCS_DECODE_MEP is
    port ( DATA     : in  std_logic;
           CLK      : in  std_logic; --155mhz
           CE38MHZ  : out std_logic;
           FLT      : out  std_logic;
           ECRST    : out  std_logic;
           BCRST    : out  std_logic;
		   TCS_WORD : out  std_logic_vector (15 downto 0);
		   START    : out  std_logic;
		   SYNCED   : out std_logic
			  );
end TCS_DECODE_MEP;

architecture Behavioral of TCS_DECODE_MEP is
	signal state: STD_LOGIC_VECTOR(1 downto 0); -- := "00";
	signal chanSwap: integer range 0 to 7 := 0;
	signal reg: STD_LOGIC_VECTOR(3 downto 0):="0000";		-- 2 bit would be enough
	
	signal sCE38MHz   : std_logic := '0';
	signal sQA :   STD_LOGIC;
	signal sQB :   STD_LOGIC;
	
	signal sync_ok : std_logic := '0';
	signal error_phase : std_logic := '0';
	signal error_chan : std_logic := '0';
	signal error_start : std_logic := '1';
	signal sr_error_phase : std_logic_vector(1 downto 0) := "00";
	signal cnt_start : integer range 0 to 32 := 31;--std_logic_vector (5 downto 0) := (others=>'1');
	
	signal par_reg: STD_LOGIC_VECTOR (16 downto 0) := (others => '0');
	signal count: integer range 0 to 29 := 0;
begin
	
	

	SYNCED <= sync_ok; -- aggiunto segnale sync_ok  
	--SYNCED <= not (error_phase or error_chan ); 
	
	demux: process (CLK)
	begin
		-- on rising edge of CLK
		if ( CLK='1' and CLK'event ) then

			-- shift DATA in register
			reg <= reg(2 downto 0) & DATA; --CH A e CH B insieme  
																			
			-- debug
			error_phase <= '0';
			error_chan <= '0';
			
			-- test if we are phase shifted
			--xnor: diversi=0  uguali=1
			if ( (reg(0) xnor reg(1))='1' and state(0)='1' ) then --reg precedenti uguali e sono in stato 01,11 -> errore
				-- wait to correct phase shift
				error_phase <= '1'; --null;
			else 
				case state is
					when "00" =>
						-- Channel A
	
						sQA <= reg(0) xor reg(1); --mette'1' perchè arrivo qui quando sono diversi -> C'è UN FRONTE DEL SEGNALE
						state <= "01";
						sCE38MHz <= '1'; --scrivo canale B
					when "01" => --qui non leggo reg perchè devo lasciare che entrino 2 nuovi valori per vedere il valore di CH B
						if chanSwap=7 then 
							state <= "00";
							chanSwap <= 0;
							error_chan <= '1';
						else
							state <= "10";
							if (sQA='1') then
								chanSwap <= chanSwap + 1; 
							end if;
						end if;
						sCE38MHz <= '0';
					when "10" =>
						-- Channel B

						sQB <= reg(0) xor reg(1);
						state <= "11";
						sCE38MHz <= '0';
					when "11" =>
						if chanSwap=7 then 
							state <= "10";
							chanSwap <= 0;
							error_chan <= '1';
						else 
							state <= "00";
							if (sQB='1' and chanSwap /= 0) then
								chanSwap <= chanSwap - 1;
							end if;
						end if;
						sCE38MHz <= '0';
					when others =>
						state <= "11"; 
				end case;
			end if;
		
		end if;
	end process;




	-- this is the replacement for the 38 MHz clock
	-- it is a clock enable which is '1' every 4 cycles
	CE38MHz <= sCE38MHz;  -- alex/marco
	
	
	out_sync_proc: process (CLK)
	begin
		if ( CLK='1' and CLK'event ) then	
			if (sCE38MHz='1' and sync_ok='1') then
				FLT <= sQA;	-- synchronize Trigger with Clock
			elsif(sCE38MHz='1') then
				FLT <= '0';			
			end if;
		end if;
	end process;


	ser2par: process (CLK)
	begin
		-- on rising edge of CLK
		if ( CLK='1' and CLK'event ) then	
			if (error_phase='1' or error_chan='1') then --se ho errori non sono sincronizzato
				sync_ok <= '0';
			elsif (sCE38MHz='1') then   --NON ho errori -> tutto bene
				
				if(cnt_start=0) then
				--Se supero questo if significa che ho finito la prima parte di simulazione in cui non sono sincronizzato
				--e in cui decodifico dati errati.
				--Quindi se supero l'if sono sincronizzato.						
				sync_ok <= '1';

				else 
					cnt_start <= cnt_start - 1;	
				end if;

			end if;
			
			--scrivo sempre par_reg aggiornandolo. All'inizio lo aggiorno all'infinito finchè non trovo la combinaz. 100
			--a questo punto setto contatore a 15 in modo da andare a controllare se in par_reg ho scritto
			--una parola di trigger, solo quanda sarà stato completamente sovrascritto. A questo punto controllerò i nuovi bit
			--in par_reg e verifico se è un trigger e così via.
			--il contatore sotto però vuole a 17 perchè faccio sempre count+1 iteraz. e una volta scaricato par_reg
			--devo aspettare si riempia dinuovo tutto (17 colpi di clock) per leggerlo. 
			--Conto pero 17+1 e quindi 18 iterazioni perchè quando scrivo par_reg la 18esima volta,
			--subito sotto controllo cosa c'è in par_reg ma il segnale sopra non si è ancora aggiornato
			--per cui ha perfettamente i 17 bit nuovi da controllare.

			--tieni conto che quando controlli par reg stai già leggendo un bit del nuovo par reg !!!!!!

			--ATTENZIONE: metto CE38MHz a 1 quando leggo il nuovo canale A; quando però CE38MHz=1 (vedi sotto)
			-- aggiorno anche par_reg col valore del canale B ma DOVENDO ANCORA VEDERE IL NUOVO VALORE, ci metterò sempre quello precedente
			
			if (sCE38MHz='1') then			--ogni 4 colpi ho 2 bit CH.B che in xor fanno 1 bit (sQB)
				-- shift DATA in register
				par_reg <= par_reg(15 downto 0) & sQB;	--scrivo 16 bit		
				ECRST <= '0';
                BCRST <= '0';
				if (count = 0) then
					--if(par_reg(18 downto 16)="111" and par_reg(15 downto 14)="00") then --1.0.7
					if (par_reg(16)='1' and par_reg(15 downto 14)="00") then
						-- start when idle and 00 ....
						if (sync_ok='1') then
						    START <= '1';
						    TCS_WORD <= par_reg(15 downto 0);
                            ECRST <= par_reg(7);
                            BCRST <= par_reg(6);
						end if;
						count <= 15;--1.0.7
					end if;
				else --faccio count+1 iterazioni qui dentro (16)
					START <= '0';
					count <= count-1;
				end if;
			else
				START <= '0';
			end if;
		end if;
	end process;
	
end Behavioral;

