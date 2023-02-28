----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    12:10:02 04/04/2008 
-- Design Name: 
-- Module Name:    TCS decode - Behavioral 
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
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
--USE IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity TCS_DECODE is
    Port ( DATA : in  STD_LOGIC;
           CLK : in  STD_LOGIC;
           CE38MHz : out std_logic;
           FLT : out  STD_LOGIC;
		   TCS_WORD : out  STD_LOGIC_VECTOR (31 downto 0);
		   START : out  STD_LOGIC;
		   SYNCED : out STD_LOGIC
		   -- debug
		   ; tcs_error_phase : out  STD_LOGIC
		   ; tcs_error_chan : out  STD_LOGIC
			  );
end TCS_DECODE;

architecture Behavioral of TCS_DECODE is
	signal state: STD_LOGIC_VECTOR(1 downto 0);
	signal chanSwap: integer range 0 to 7 := 0;
	signal reg: STD_LOGIC_VECTOR(3 downto 0):="0000";		-- 2 bit would be enough
	
	signal tcsCLK :     STD_LOGIC;
	signal tcsCLK_BUF : STD_LOGIC;
	signal sCE38MHz   : std_logic := '0';
	signal sQA :   STD_LOGIC;
	signal sQB :   STD_LOGIC;
	
	signal sync_ok : std_logic := '0';
	signal error_phase : std_logic := '0';
	signal error_chan : std_logic := '0';
	
	signal par_reg: STD_LOGIC_VECTOR (31 downto 0) := X"00000000";
	signal count: integer range 0 to 29 := 0;
begin
	
	
	tcs_error_phase <= error_phase;
	tcs_error_chan <= error_chan;
	SYNCED <= sync_ok;
	
	demux: process (CLK)
	begin
		-- on rising edge of CLK
		if ( CLK='1' and CLK'event ) then

			-- shift DATA in register
			reg <= reg(2 downto 0) & DATA;
			
			-- debug
			error_phase <= '0';
			error_chan <= '0';
			
			-- test if we are phase shifted
			if ( (reg(0) xnor reg(1))='1' and state(0)='1' ) then
				-- wait to correct phase shift
				error_phase <= '1'; --null;
			else
				case state is
					when "00" =>
						-- Channel A
						sQA <= reg(0) xnor reg(1);
						state <= "01";
						sCE38MHz <= '1';
					when "01" =>
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
						tcsCLK <= '1';
					when "10" =>
						-- Channel B
						sQB <= reg(0) xnor reg(1);
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
						tcsCLK <= '0';
					when others =>
						state <= "11";
				end case;
			end if;
		
		end if;
	end process;


	-- this is the replacement for the 38 MHz clock
	-- it is a clock enable which is '1' every 4 cycles
	CE38MHz <= sCE38MHz;
	
	
	out_sync_proc: process (CLK)
	begin
		if ( CLK='1' and CLK'event ) then
			if (sCE38MHz='1' and sync_ok='1') then
				FLT <= sQA;	-- synchronize Trigger with Clock
			end if;
		end if;
	end process;
	
	ser2par: process (CLK)
	begin
		-- on rising edge of CLK
		if ( CLK='1' and CLK'event ) then
			if (error_phase='1' or error_chan='1') then
				sync_ok <= '0';
			elsif (sCE38MHz='1') then
				if (count=0) then
					if(par_reg(28)='1' and (par_reg(29) or par_reg(30) or par_reg(31))='0') then -- quando ho 0001....(qualsiasi roba dopo) soddisfo la condizione
						sync_ok <= '1';
					end if;
				end if;
			end if;
			
			if (sCE38MHz='1') then			
				-- shift DATA in register
				par_reg <= par_reg(30 downto 0) & sQB;	--butto 32esimo bit facendo lo shift e aggiungendo sQB in coda		
				
				if (count=0) then
					if(par_reg(28)='1' and (par_reg(29) or par_reg(30) or par_reg(31))='0') then -- quando ho 0001....(qualsiasi roba dopo) soddisfo la condizione
						-- start when 0001....
						if (sync_ok='1') then
							START <= '1';
							TCS_WORD <= par_reg;
						end if;
						count <= 29;
					end if;
				else
					START <= '0';
					count <= count-1;
				end if;
			else
				START <= '0';
			end if;
		end if;
	end process;
	
end Behavioral;

