-------------------------------------------------------------------------------
-- Title	  : stat_if
-- Project	  : test project
-------------------------------------------------------------------------------
-- File		  : stat_if.vhd
-- Author	  : Philipp	 <philipp@pcfr58.physik.uni-freiburg.de>
-- Company	  : 
-- Created	  : 2013-08-28
-- Last update: 2013-09-05
-- Platform	  : 
-- Standard	  : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: the status interface
-------------------------------------------------------------------------------
-- Copyright (c) 2013 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date		   Version	Author	Description
-- 2013-08-28  1.0		philipp productions
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use WORK.TOP_LEVEL_DESC.all;
use WORK.G_PARAMETERS.ALL;

-------------------------------------------------------------------------------

entity stat_if is

	port (
		clk			  : in	std_logic;
		stat_flags	  : in	std_logic_vector(15 downto 0);
		wr_stats	  : in	std_logic;
		wr_sys_mon	  : in	std_logic;
		cfmem_wb_cyc  : out std_logic;
		cfmem_wb_stb  : out std_logic;
		cfmem_wb_we	  : out std_logic_vector(3 downto 0);
		cfmem_wb_ack  : in	std_logic;
		cfmem_wb_addr : out std_logic_vector (9 downto 0);
		cfmem_wb_din  : in	std_logic_vector (31 downto 0);
		cfmem_wb_dout : out std_logic_vector (31 downto 0)
		);

end entity stat_if;

-------------------------------------------------------------------------------

architecture behav of stat_if is

--------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- sys_mon control signals

	signal RESET  : std_logic			  := '0';
	signal TEMP	  : mon_vals (2 downto 0) := (others => (others => '0'));
	signal VCCINT : mon_vals (2 downto 0) := (others => (others => '0'));
	signal VCCAUX : mon_vals (2 downto 0) := (others => (others => '0'));
	signal ALARM  : std_logic_vector(2 downto 0);
--------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- internal logic signals and constants

	type shift_regs is array (0 to 1) of std_logic_vector(1 downto 0);
	type state_type is (
		st_sleep,
		st_wr_stats,
		st_wr_sysmon
		);
	signal state : state_type := st_sleep;

	signal shift_reg	: shift_regs := (b"00", b"00");
	signal wr_stats_i	: std_logic	 := '0';
	signal wr_sys_mon_i : std_logic	 := '0';
	signal counter		: integer	 := 0;
--------------------------------------------------------------------------------------------------------------------------------------------------------------
	constant stats_adr : std_logic_vector(9 downto 0):=std_logic_vector(GNDLF_addr_offset+status_addr_offset+1);
--------------------------------------------------------------------------------------------------------------------------------------------------------------
	type sysmon_data is array (0 to 2) of std_logic_vector(29 downto 0);
	type sysmon_adrs is array (0 to 2) of std_logic_vector(9 downto 0);

	signal sysmon_data_i : sysmon_data;
	constant sysmon_adr : sysmon_adrs := (std_logic_vector(GNDLF_addr_offset+temp_addr_offset) + ("10" & "000"),
										  std_logic_vector(GNDLF_addr_offset+temp_addr_offset) + ("01" & "000"),
										  std_logic_vector(GNDLF_addr_offset+temp_addr_offset) + ("00" & "000"));
--------------------------------------------------------------------------------------------------------------------------------------------------------------
begin

	sysmon_data_i(0) <= VCCINT(2) & VCCINT(1) & VCCINT(0);
	sysmon_data_i(1) <= VCCAUX(2) & VCCAUX(1) & VCCAUX(0);
	sysmon_data_i(2) <= TEMP(2) & TEMP(1) & TEMP(0);

	process
	begin
		wait until rising_edge(clk);
-------------------------------------------------------------------------------shift in fast_registers
		shift_reg(0) <= shift_reg(0)(0) & wr_stats;
		shift_reg(1) <= shift_reg(1)(0) & wr_sys_mon;
		if shift_reg(0) = "01" then
			wr_stats_i <= '1';
		end if;
		if shift_reg(1) = "01" then
			wr_sys_mon_i <= '1';
		end if;
-------------------------------------------------------------------------------defaults
		cfmem_wb_stb  <= '0';
		cfmem_wb_cyc  <= '0';
		cfmem_wb_we	  <= (others => '1');
		cfmem_wb_dout <= (others => '0');
		cfmem_wb_addr <= (others => '0');
-------------------------------------------------------------------------------
		case state is
			when st_sleep =>
				if wr_stats_i = '1' then
					state <= st_wr_stats;
				elsif wr_sys_mon_i = '1' then
					state	<= st_wr_sysmon;
					counter <= sysmon_adr'length - 1;
				end if;

			when st_wr_stats =>
				if cfmem_wb_ack = '1' then
					wr_stats_i <= '0';
					state	   <= st_sleep;
				else
					cfmem_wb_stb			   <= '1';
					cfmem_wb_cyc			   <= '1';
					cfmem_wb_dout(31 downto 0) <= x"CF"
												  & "0" & ALARM	 --sysmon Alarm (Temp-,V-Problem)
												  & "0" & stat_flags(15 downto 13)	--Gandalf Resets
												  & stat_flags(12)		--IO-Manager not ready
												  & stat_flags(11) 		--lff
												  & not stat_flags(10) 	--TCS sync ok, 
												  & stat_flags(9) 		--TCS LOL
												  & "0" & stat_flags(8 downto 6)  --Si-A
												  & "0" & stat_flags(5 downto 3)  --Si-B
												  & "0" & stat_flags(2 downto 0);  --Si-G
					cfmem_wb_addr <= stats_adr;
				end if;

			when st_wr_sysmon =>
				if cfmem_wb_ack = '1' then
					if counter = 0 then
						wr_sys_mon_i <= '0';
						state		 <= st_sleep;
					else
						counter <= counter - 1;
					end if;
				else
					cfmem_wb_stb			   <= '1';
					cfmem_wb_cyc			   <= '1';
					cfmem_wb_dout(29 downto 0) <= sysmon_data_i(counter);
					cfmem_wb_addr			   <= sysmon_adr(counter);
				end if;

			when others => null;

		end case;
	end process;

	sys_mon_1 : entity work.sys_mon
		port map (
			CLK	   => CLK,
			RESET  => RESET,
			TEMP   => TEMP,
			VCCINT => VCCINT,
			VCCAUX => VCCAUX,
			ALARM  => ALARM);


end architecture behav;

-------------------------------------------------------------------------------
