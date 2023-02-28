----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:15:23 02/21/2009 
-- Design Name: 
-- Module Name:    Trigger_LED - Behavioral 
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
--library IEEE;
--use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Trigger_LED is
    Port ( 
			clk 			: IN  STD_LOGIC;          
			GREEN 			: IN  STD_LOGIC;
			ORANGE     		: IN  STD_LOGIC;
			RED				: IN  STD_LOGIC;
			trigger_LED 	: OUT STD_LOGIC_VECTOR(1 downto 0)
			  );
end Trigger_LED;

architecture Behavioral of Trigger_LED is


--SIGNAL COUNT_A : INTEGER range 0 to 8388608  :=1;
SIGNAL COUNT_A : INTEGER range 0 to 33554431  :=1;

SIGNAL LED : STD_LOGIC_VECTOR(1 downto 0) := "00"; 

	
	type state_type is (	
				do_orange, 
				do_red, 
				do_green,
				led_off
							); 
signal state : state_type := led_off; 

begin


LEDCTRL: PROCESS(CLK)

BEGIN

	if (CLK'event and CLK ='1') then

				
			if state /= led_off then
			COUNT_A<=COUNT_A-1;
			end if;
			
		case state is	
						
			when led_off => 
				
				LED 	<= "00";	
					
				if ORANGE = '1' then
					state <=do_orange;
					COUNT_A	<=33554431;
				end if;			
				
				if RED = '1' then				 
					state <=do_red;
					COUNT_A	<=33554431;
				end if;	
				
				if GREEN = '1' then				 
					state <=do_green;
					COUNT_A	<=1048500;
				end if;			
						
			when do_orange => 
			
				LED <= "11";
				if COUNT_A = 1 then 
				state <=led_off;
				end if;
								
		
			when do_red => 
				LED <= "01";
				
				if COUNT_A = 1 then 
				state <=led_off;
				end if;
			
			when do_green => 	
				LED <= "10"; 
			
				if COUNT_A = 1 then 
				state <=led_off;
				end if;
				
				if GREEN = '1' then
				COUNT_A	<=1048500;
				end if;	
				
				if ORANGE = '1' then
					state <=do_orange;
					COUNT_A	<=33554431;
				end if;			
				
				if RED = '1' then				 
					state <=do_red;
					COUNT_A	<=33554431;
				end if;			
				
			when others => 
				state <=led_off;	
				
		end case;
	
		
	end if;

END PROCESS;

trigger_LED<=LED;

end Behavioral;

