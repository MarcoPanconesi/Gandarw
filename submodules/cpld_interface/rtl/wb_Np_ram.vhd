----------------------------------------------------------------------------------
-- Company:		  VISENGI S.L. (www.visengi.com)
-- Engineer:	  Victor Lopez Lorenzo (victor.lopez (at) visengi (dot) com)
-- 
-- Create Date:	   23:44:13 22/August/2008 
-- Project Name:   Triple Port WISHBONE SPRAM Wrapper
-- Tool versions:  Xilinx ISE 9.2i
-- Description: 
--
-- Description: This is a wrapper for an inferred single port RAM, that converts it
--				into a Three-port RAM with one WISHBONE slave interface for each port. 
--
--
-- LICENSE TERMS: GNU LESSER GENERAL PUBLIC LICENSE Version 2.1
--	   That is you may use it in ANY project (commercial or not) without paying a cent.
--	   You are only required to include in the copyrights/about section of accompanying 
--	   software and manuals of use that your system contains a "3P WB SPRAM Wrapper
--	   (C) VISENGI S.L. under LGPL license"
--	   This holds also in the case where you modify the core, as the resulting core
--	   would be a derived work.
--	   Also, we would like to know if you use this core in a project of yours, just an email will do.
--
--	  Please take good note of the disclaimer section of the LPGL license, as we don't
--	  take any responsability for anything that this core does.
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity wb_Np_ram is
	generic (data_width : integer := 32;
			 addr_width : integer := 9);
	port (
		-- control	  : inout std_logic_vector(35 downto 0);
		mem_clka  : out	  std_logic;
		mem_wea	  : out	  std_logic_vector(3 downto 0);
		mem_addra : out	  std_logic_vector(15 downto 0);
		mem_dina  : out	  std_logic_vector(data_width-1 downto 0);
		mem_douta : in	  std_logic_vector(data_width-1 downto 0);

		wb_clk : in std_logic;
		wb_rst : in std_logic;

		wb1_cyc	  : in	std_logic;
		wb1_stb	  : in	std_logic;
		wb1_we	  : in	std_logic_vector(3 downto 0);
		wb1_adr	  : in	std_logic_vector(addr_width-1 downto 0);
		wb1_dat_i : in	std_logic_vector(data_width-1 downto 0);
		wb1_dat_o : out std_logic_vector(data_width-1 downto 0);
		wb1_ack	  : out std_logic;

		wb2_cyc	  : in	std_logic;
		wb2_stb	  : in	std_logic;
		wb2_we	  : in	std_logic_vector(3 downto 0);
		wb2_adr	  : in	std_logic_vector(addr_width-1 downto 0);
		wb2_dat_i : in	std_logic_vector(data_width-1 downto 0);
		wb2_dat_o : out std_logic_vector(data_width-1 downto 0);
		wb2_ack	  : out std_logic;

		wb3_cyc	  : in	std_logic;
		wb3_stb	  : in	std_logic;
		wb3_we	  : in	std_logic_vector(3 downto 0);
		wb3_adr	  : in	std_logic_vector(addr_width-1 downto 0);
		wb3_dat_i : in	std_logic_vector(data_width-1 downto 0);
		wb3_dat_o : out std_logic_vector(data_width-1 downto 0);
		wb3_ack	  : out std_logic;

		wb4_cyc	  : in	std_logic;
		wb4_stb	  : in	std_logic;
		wb4_we	  : in	std_logic_vector(3 downto 0);
		wb4_adr	  : in	std_logic_vector(addr_width-1 downto 0);
		wb4_dat_i : in	std_logic_vector(data_width-1 downto 0);
		wb4_dat_o : out std_logic_vector(data_width-1 downto 0);
		wb4_ack	  : out std_logic;

		wb5_cyc	  : in	std_logic;
		wb5_stb	  : in	std_logic;
		wb5_we	  : in	std_logic_vector(3 downto 0);
		wb5_adr	  : in	std_logic_vector(addr_width-1 downto 0);
		wb5_dat_i : in	std_logic_vector(data_width-1 downto 0);
		wb5_dat_o : out std_logic_vector(data_width-1 downto 0);
		wb5_ack	  : out std_logic

		);
end wb_Np_ram;

architecture Behavioral of wb_Np_ram is
	
	signal we	: std_logic_vector(3 downto 0);
	signal a	: std_logic_vector(addr_width-1 downto 0);
	signal d, q : std_logic_vector(data_width-1 downto 0);
	signal State						   : integer range 0 to 15;
	attribute safe_implementation		   : string;
	attribute safe_implementation of State : signal is "yes";

-------------------------------------------------------------------------------
-- we or funtion
	function we_or (din : std_logic_vector(3 downto 0))
		return std_logic is
		variable t : std_logic := '0';	-- variable mit default Zuweisung
	begin
		for i in din'range loop			-- ganze Busbreite
			t := t or din(i);
		end loop;
		return t;
	end we_or;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- new signals
	signal ack1_r : std_logic := '0';
	signal ack2_r : std_logic := '0';
	signal ack3_r : std_logic := '0';
	signal ack4_r : std_logic := '0';
	signal ack5_r : std_logic := '0';
------------------------------------------------------------------------------- 
	
begin

	mem_clka  <= wb_clk;
	mem_wea	  <= we;
	mem_addra <= "1" & a & "11111";
	mem_dina  <= d;
	q		  <= mem_douta;

	wb1_dat_o <= q;
	wb2_dat_o <= q;
	wb3_dat_o <= q;
	wb4_dat_o <= q;
	wb5_dat_o <= q;

	WB_interconnect : process
		variable ack1, ack2, ack3, ack4, ack5 : std_logic;
		variable lock						  : integer range 0 to 5;
	begin
		wait until rising_edge(wb_clk);



		--defaults (unless overriden afterwards)
		we	   <= x"0";
		ack1_r <= '0';
		ack2_r <= '0';
		ack3_r <= '0';
		ack4_r <= '0';
		ack5_r <= '0';


		--unlockers
		if (lock = 1 and wb1_cyc = '0') then lock := 0; end if;
		if (lock = 2 and wb2_cyc = '0') then lock := 0; end if;
		if (lock = 3 and wb3_cyc = '0') then lock := 0; end if;
		if (lock = 4 and wb4_cyc = '0') then lock := 0; end if;
		if (lock = 5 and wb5_cyc = '0') then lock := 0; end if;

		if (wb1_cyc = '1' and (lock = 0 or lock = 1)) then	--lock request (grant if lock is available)
			ack2 := '0';
			ack3 := '0';
			ack4 := '0';
			ack5 := '0';
			lock := 1;
			if (wb1_stb = '1' and ack1 = '0' and ack1_r = '0') then	 --operation request
				we <= wb1_we;
				a  <= wb1_adr;
				d  <= wb1_dat_i;
				if (we_or(wb1_we) = '1') then -- si poteva scrivere piu' semplicemente : if (wb1_we /="0000") then
					ack1 := '1';  --ack now and stay in this state waiting for new ops
				else
					ack1_r <= '1';		--ack later
				end if;
			else
				ack1 := '0';	  --force one cycle wait between operations
					  --or else the wb master could issue a write, then receive two acks (first legal ack and then
					  --a spurious one due to being in the cycle where the master is still reading the first ack)
					  --followed by a read and misinterpret the spurious ack as an ack for the read
			end if;
		elsif (wb2_cyc = '1' and (lock = 0 or lock = 2)) then  --lock request (grant if lock is available)
			ack1 := '0';
			ack3 := '0';
			ack4 := '0';
			ack5 := '0';
			lock := 2;
			if (wb2_stb = '1' and ack2 = '0' and ack2_r = '0') then	 --operation request
				we <= wb2_we;
				a  <= wb2_adr;
				d  <= wb2_dat_i;
				if (we_or(wb2_we) = '1') then
					ack2 := '1';  --ack now and stay in this state waiting for new ops
				else
					ack2_r <= '1';		--ack later					
				end if;
			else
				ack2 := '0';	  --force one cycle wait between operations
			end if;
		elsif (wb3_cyc = '1' and (lock = 0 or lock = 3)) then  --lock request (grant if lock is available)
			ack1 := '0';
			ack2 := '0';
			ack4 := '0';
			ack5 := '0';
			lock := 3;
			if (wb3_stb = '1' and ack3 = '0' and ack3_r = '0') then	 --operation request
				we <= wb3_we;
				a  <= wb3_adr;
				d  <= wb3_dat_i;
				if (we_or(wb3_we) = '1') then
					ack3 := '1';  --ack now and stay in this state waiting for new ops
				else
					ack3_r <= '1';		--ack later					
				end if;
			else
				ack3 := '0';	  --force one cycle wait between operations
			end if;
		elsif (wb4_cyc = '1' and (lock = 0 or lock = 4)) then  --lock request (grant if lock is available)
			ack1 := '0';
			ack2 := '0';
			ack3 := '0';
			ack5 := '0';
			lock := 4;
			if (wb4_stb = '1' and ack4 = '0' and ack4_r = '0') then	 --operation request
				we <= wb4_we;
				a  <= wb4_adr;
				d  <= wb4_dat_i;
				if (we_or(wb4_we) = '1') then
					ack4 := '1';  --ack now and stay in this state waiting for new ops
				else
					ack4_r <= '1';		--ack later					
				end if;
			else
				ack4 := '0';	  --force one cycle wait between operations
			end if;
		elsif (wb5_cyc = '1' and (lock = 0 or lock = 5)) then  --lock request (grant if lock is available)
			ack1 := '0';
			ack2 := '0';
			ack3 := '0';
			ack4 := '0';
			lock := 5;
			if (wb5_stb = '1' and ack5 = '0' and ack5_r = '0') then	 --operation request
				we <= wb5_we;
				a  <= wb5_adr;
				d  <= wb5_dat_i;
				if (we_or(wb5_we) = '1') then
					ack5 := '1';  --ack now and stay in this state waiting for new ops
				else
					ack5_r <= '1';		--ack later					
				end if;
			else
				ack5 := '0';	  --force one cycle wait between operations
			end if;
		end if;




		wb1_ack <= ((ack1 xor ack1_r) and wb1_stb and wb1_cyc);	 --to don't ack aborted operations
		wb2_ack <= ((ack2 xor ack2_r) and wb2_stb and wb2_cyc);	 --to don't ack aborted operations
		wb3_ack <= ((ack3 xor ack3_r) and wb3_stb and wb3_cyc);	 --to don't ack aborted operations
		wb4_ack <= ((ack4 xor ack4_r) and wb4_stb and wb4_cyc);	 --to don't ack aborted operations
		wb5_ack <= ((ack5 xor ack5_r) and wb5_stb and wb5_cyc);	 --to don't ack aborted operations					   
	end process WB_interconnect;
end Behavioral;

