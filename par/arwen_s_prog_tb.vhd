--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   12:33:48 05/17/2022
-- Design Name:   
-- Module Name:   C:/Users/fragb/OneDrive - Istituto Nazionale di Fisica Nucleare/Xil_14.7/GandArw/par/arwen_s_prog_tb.vhd
-- Project Name:  gandarw
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: arwen_s_prog
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY arwen_s_prog_tb IS
END arwen_s_prog_tb;
 
ARCHITECTURE behavior OF arwen_s_prog_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT arwen_s_prog
    PORT(
         control                : INOUT std_logic_vector(35 downto 0);
         clk                    : IN    std_logic;
         fastreg_prog           : IN    std_logic;
         start_reading          : OUT   std_logic;
         start_addr             : OUT   std_logic_vector(28 downto 0);
         end_addr               : OUT   std_logic_vector(28 downto 0);
         binfile_fifo_data      : IN    std_logic_vector(33 downto 0);
         binfile_fifo_empty     : IN    std_logic;
         binfile_fifo_valid     : IN    std_logic;
         binfile_fifo_ren       : OUT   std_logic;
         wb_cyc                 : OUT   std_logic;
         wb_stb                 : OUT   std_logic;
         wb_we                  : OUT   std_logic_vector(3 downto 0);
         wb_adr                 : OUT   std_logic_vector(9 downto 0);
         wb_dat_o               : OUT   std_logic_vector(31 downto 0);
         wb_dat_i               : IN    std_logic_vector(31 downto 0);
         wb_ack                 : IN    std_logic;
         ARWEN_PROG_P           : OUT   std_logic;
         ARWEN_PROG_N           : OUT   std_logic;
         ARWEN_INIT_P           : IN    std_logic;
         ARWEN_INIT_N           : IN    std_logic;
         ARWEN_DONE_P           : IN    std_logic;
         ARWEN_DONE_N           : IN    std_logic;
         ARWEN_D0_P             : OUT   std_logic;
         ARWEN_D0_N             : OUT   std_logic;
         ARWEN_CCLK_P           : OUT   std_logic;
         ARWEN_CCLK_N           : OUT   std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk                   : std_logic := '0';
   signal fastreg_prog          : std_logic := '0';
   signal binfile_fifo_data     : std_logic_vector(33 downto 0) := (others => '1');
   signal binfile_fifo_empty    : std_logic := '0';
   signal binfile_fifo_valid    : std_logic := '1';
   signal wb_dat_i              : std_logic_vector(31 downto 0) := (others => '0');
   signal wb_ack                : std_logic := '0';
   signal ARWEN_INIT_P          : std_logic := '0';
   signal ARWEN_INIT_N          : std_logic := '0';
   signal ARWEN_DONE_P          : std_logic := '0';
   signal ARWEN_DONE_N          : std_logic := '0';

	--BiDirs
   signal control : std_logic_vector(35 downto 0);

 	--Outputs
   signal start_reading         : std_logic;
   signal start_addr            : std_logic_vector(28 downto 0);
   signal end_addr              : std_logic_vector(28 downto 0);
   signal binfile_fifo_ren      : std_logic;
   signal wb_cyc                : std_logic;
   signal wb_stb                : std_logic;
   signal wb_we                 : std_logic_vector(3 downto 0);
   signal wb_adr                : std_logic_vector(9 downto 0);
   signal wb_dat_o              : std_logic_vector(31 downto 0);
   signal ARWEN_PROG_P          : std_logic;
   signal ARWEN_PROG_N          : std_logic;
   signal ARWEN_D0_P            : std_logic;
   signal ARWEN_D0_N            : std_logic;
   signal ARWEN_CCLK_P          : std_logic;
   signal ARWEN_CCLK_N          : std_logic;

   -- Clock period definitions
   constant clk_period          : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: arwen_s_prog PORT MAP (
          control               => control,
          clk                   => clk,
          fastreg_prog          => fastreg_prog,
          start_reading         => start_reading,
          start_addr            => start_addr,
          end_addr              => end_addr,
          binfile_fifo_data     => binfile_fifo_data,
          binfile_fifo_empty    => binfile_fifo_empty,
          binfile_fifo_valid    => binfile_fifo_valid,
          binfile_fifo_ren      => binfile_fifo_ren,
          wb_cyc                => wb_cyc,
          wb_stb                => wb_stb,
          wb_we                 => wb_we,
          wb_adr                => wb_adr,
          wb_dat_o              => wb_dat_o,
          wb_dat_i              => wb_dat_i,
          wb_ack                => wb_ack,
          ARWEN_PROG_P          => ARWEN_PROG_P,
          ARWEN_PROG_N          => ARWEN_PROG_N,
          ARWEN_INIT_P          => ARWEN_INIT_P,
          ARWEN_INIT_N          => ARWEN_INIT_N,
          ARWEN_DONE_P          => ARWEN_DONE_P,
          ARWEN_DONE_N          => ARWEN_DONE_N,
          ARWEN_D0_P            => ARWEN_D0_P,
          ARWEN_D0_N            => ARWEN_D0_N,
          ARWEN_CCLK_P          => ARWEN_CCLK_P,
          ARWEN_CCLK_N          => ARWEN_CCLK_N
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 
   wb_process: process
   begin
        wait until wb_stb = '1';
        wb_ack <= '1' after clk_period;
        wait until wb_stb = '0';
        wb_ack <= '0' after clk_period; 
   end process;

   -- Stimulus process
   stim_proc: process
   begin		
    -- hold reset state for 100 ns.
    wait for 100 ns;
    binfile_fifo_data(32 downto 0) <= '0' & x"DEADBEEF";	
    binfile_fifo_data(33) <= '0';
    wait for clk_period*10;
    -- insert stimulus here 
    fastreg_prog <= '1'; wait for 100 ns;
    fastreg_prog <= '0'; wait for 2 ns;
    ARWEN_INIT_P <= '1'; ARWEN_INIT_N <= '0'; wait for 100 ns; -- aerwn:init high
    wait for 50 us;
    binfile_fifo_valid <= '0'; binfile_fifo_data(33) <= '1'; wait for 1 us;-- end of data in fifo ...

    wait;
   end process;

END;
