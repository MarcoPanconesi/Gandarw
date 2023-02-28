----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:47:50 02/08/2008 
-- Design Name: 
-- Module Name:    adc - Behavioral 
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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity adc is
    Port ( 	  analog 		: in  real;
			  clk			: in STD_LOGIC;
			  DRY_p			: out STD_LOGIC;
			  DRY_n			: out STD_LOGIC;
	          data_p 		: out  STD_LOGIC_VECTOR (13 downto 0) := b"00000000000000";
			  data_n 		: out  STD_LOGIC_VECTOR (13 downto 0) := b"11111111111111"
			  );		  
			  
end adc;

architecture Behavioral of adc is
signal temp				: STD_LOGIC_VECTOR (13 downto 0);
signal DATARY			: STD_LOGIC := '0';
constant scale			: real := 1000.0; -- :=4000.0 ->14bit conversion, :=1000 ->12bit conversion,

begin

process
begin
	wait until rising_edge(clk);
	temp <= conv_std_logic_vector(integer(scale*(4.096+analog)),14); --convert from 4V to 12/14bits

	data_p <= temp(13 downto 0);
	data_n <= not temp (13 downto 0);
	wait for 1 ns; --timing contsrain by hand!!!! Think about for post route simulation!!!
	DATARY <= not DATARY;
end process;

DRY_p <= not DATARY;
DRY_n <= DATARY;



end Behavioral;

