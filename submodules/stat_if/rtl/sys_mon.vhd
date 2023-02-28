----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:	   08:49:44 07/17/2009 
-- Design Name: 
-- Module Name:	   sys_mon - Behavioral 
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
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;
use WORK.TOP_LEVEL_DESC.all;
use WORK.G_PARAMETERS.all;

library UNISIM;
use UNISIM.VCOMPONENTS.all;

entity sys_mon is
	port (
		CLK	   : in	 std_logic;
		RESET  : in	 std_logic;
   		TEMP   : out mon_vals (2 downto 0) := (others => (others => '0'));
		VCCINT : out mon_vals (2 downto 0) := (others => (others => '0'));
		VCCAUX : out mon_vals (2 downto 0) := (others => (others => '0'));
		ALARM  : out std_logic_vector(2 downto 0)
		);
end sys_mon;

architecture Behavioral of sys_mon is

	signal BUSY	   : std_logic;
	signal EOC	   : std_logic					   := '1';
	signal DRDY	   : std_logic;
	signal DADDR   : std_logic_vector(6 downto 0)  := "0000010";
	signal CHANNEL : std_logic_vector(4 downto 0);
	signal Counter : std_logic_vector(1 downto 0)  := (others => '1');
	signal DO	   : std_logic_vector(15 downto 0) := (others => '0');
	signal ALARM_i : std_logic_vector(2 downto 0);



begin

	SYSMON_inst : SYSMON
		generic map (
			INIT_40			 => X"1000",  -- Configuration register 0
			INIT_41			 => X"20C1",  -- Configuration register 1
			INIT_42			 => X"3200",  -- according to 200MHz input divide by x32=d50
			INIT_43			 => X"0000",  -- Test register 0
			INIT_44			 => X"0000",  -- Test register 1
			INIT_45			 => X"0000",  -- Test register 2
			INIT_46			 => X"0000",  -- Test register 3
			INIT_47			 => X"0000",  -- Test register 4
			INIT_48			 => X"0701",  -- Sequence register 0
			INIT_49			 => X"0000",  -- Sequence register 1
			INIT_4A			 => X"0000",  -- Sequence register 2
			INIT_4B			 => X"0000",  -- Sequence register 3
			INIT_4C			 => X"0000",  -- Sequence register 4
			INIT_4D			 => X"0000",  -- Sequence register 5
			INIT_4E			 => X"0000",  -- Sequence register 6
			INIT_4F			 => X"0000",  -- Sequence register 7
			INIT_50			 => TEMP_UP,  -- Alarm limit temp upper 
			INIT_51			 => INT_UP,	  -- Alarm limit VCCINT upper 
			INIT_52			 => AUX_UP,	  -- Alarm limit VCCAUX upper 
			INIT_53			 => X"0000",  -- Alarm limit register 3
			INIT_54			 => X"0000",  -- Alarm limit temp lower	  
			INIT_55			 => TEMP_LW,  -- Alarm limit VCCINT lower
			INIT_56			 => INT_LW,	  -- Alarm limit VCCAUX lower 
			INIT_57			 => AUX_LW,	  -- Alarm limit register 7
			SIM_MONITOR_FILE => "../tb/vccaux_alarm.txt"  --Stimulus file for analog simulation
			)							-- Simulation analog entry file
		port map (
			ALM			 => ALARM_i,  -- 3-bit output for temp, Vccint and Vccaux
			BUSY		 => BUSY,		-- 1-bit output ADC busy signal
			CHANNEL		 => CHANNEL,	-- 5-bit output channel selection
			DO			 => DO,	 -- 16-bit output data bus for dynamic reconfig
			DRDY		 => DRDY,  -- 1-bit output data ready for dynamic reconfig
			EOC			 => EOC,		-- 1-bit output end of conversion
			EOS			 => open,		-- 1-bit output end of sequence
			JTAGBUSY	 => open,		-- 1-bit output JTAG DRP busy
			JTAGLOCKED	 => open,		-- 1-bit output DRP port lock
			JTAGMODIFIED => open,		-- 1-bit output JTAG write to DRP
			OT			 => open,		-- 1-bit output over temperature alarm
			CONVST		 => '0',  -- 1-bit input convert start EventMode only
			CONVSTCLK	 => '0',  -- 1-bit input convert start clock EventMode only
			DADDR		 => DADDR,	-- 7-bit input address bus for dynamic reconfig
			DCLK		 => CLK,  -- 1-bit input clock for dynamic reconfig
			DEN			 => EOC,  -- 1-bit input enable for dynamic reconfig
			DI			 => x"0000",  -- 16-bit input data bus for dynamic reconfig
			DWE			 => '0',  -- 1-bit input write enable for dynamic reconfig
			RESET		 => RESET,		-- 1-bit input active high reset
			VAUXN		 => x"0000",  -- 16-bit input N-side auxiliary analog input
			VAUXP		 => x"0000",  -- 16-bit input P-side auxiliary analog input
			VN			 => '0',		-- 1-bit input N-side analog input
			VP			 => '0'			-- 1-bit input P-side analog input
			);

	ALARM <= ALARM_i when RESET = '0' else "000";


	wr_addr : process(CLK)

	begin
		
		if rising_edge(CLK) then
			
			if (DRDY = '1') then

				if COUNTER = "11" then
					DADDR <= "00" & CHANNEL;

					if CHANNEL = "00000" then
						VCCAUX(0) <= DO(15 downto 6);
						
					elsif CHANNEL = "00001" then
						TEMP(0) <= DO(15 downto 6);
						
					elsif CHANNEL = "00010" then
						VCCINT(0) <= DO(15 downto 6);
						COUNTER	  <= "10";
						DADDR	  <= "01" & CHANNEL;
					end if;
					
				elsif COUNTER = "10" then
					DADDR <= "01" & CHANNEL;

					if CHANNEL = "00000" then
						VCCAUX(2) <= DO(15 downto 6);
						
					elsif CHANNEL = "00001" then
						TEMP(2) <= DO(15 downto 6);
						
					elsif CHANNEL = "00010" then
						VCCINT(2) <= DO(15 downto 6);
						COUNTER	  <= "01";
						DADDR	  <= ("01000" & CHANNEL(1 downto 0))+"100";
					end if;
					
					
				elsif COUNTER = "01" then
					DADDR <= ("01000" & CHANNEL(1 downto 0))+"100";


					if CHANNEL = "00000" then
						VCCAUX(1) <= DO(15 downto 6);
						
					elsif CHANNEL = "00001" then
						TEMP(1) <= DO(15 downto 6);
						
					elsif CHANNEL = "00010" then
						VCCINT(1) <= DO(15 downto 6);
						COUNTER	  <= "11";
						DADDR	  <= "00" & CHANNEL;
					end if;

				end if;
				
			end if;
			
		end if;
	end process;
	
	


end Behavioral;

