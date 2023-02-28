--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   19:28:57 06/07/2022
-- Design Name:   
-- Module Name:   C:/Users/fragb/OneDrive - Istituto Nazionale di Fisica Nucleare/Xil_14.7/GandArw/par/wb_to_ram_tb.vhd
-- Project Name:  gandarw
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: wb_to_ram
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
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;

library work;
use work.top_level_desc.all;

ENTITY wb_to_ram_tb IS
END wb_to_ram_tb;
 
ARCHITECTURE behavior OF wb_to_ram_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    component wb_to_ram
	generic (data_width : integer;
			 addr_width : integer;
             n_port     : integer);
     port(
        control         : inout std_logic_vector(35 downto 0);
        mem_clka        : out   std_logic;
        mem_wea         : out   std_logic_vector(3 downto 0);
        mem_addra       : out   std_logic_vector(15 downto 0);
		mem_dina        : out   std_logic_vector(data_width-1 downto 0);
		mem_douta       : in    std_logic_vector(data_width-1 downto 0);
        wb_clk          : in    std_logic;
        wb_rst          : in    std_logic;
        wb_mosi         : out   wb_mosi(n_port-1 downto 0);
        wb_miso         : in    wb_miso(n_port-1 downto 0)
         );
    end component;
    
    constant n_port      : integer := 1;
    constant data_width  : integer := 32;
    constant addr_width  : integer := 10;

    --Inputs
    signal mem_douta     : std_logic_vector(31 downto 0) := (others => '0');
    signal wb_clk        : std_logic := '0';
    signal wb_rst        : std_logic := '0';
    signal wb_miso       : wb_miso(n_port-1 downto 0);

	--BiDirs
    signal control       : std_logic_vector(35 downto 0);

 	--Outputs
    signal mem_clka      : std_logic;
    signal mem_wea       : std_logic_vector(3 downto 0);
    signal mem_addra     : std_logic_vector(15 downto 0);
    signal mem_dina      : std_logic_vector(31 downto 0);
    signal wb_mosi       : wb_mosi(n_port-1 downto 0);

   -- Clock period definitions
   constant wb_clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: wb_to_ram 
   generic map (
        data_width => data_width, 
        addr_width => addr_width, 
        n_port     => n_port     
        )
    PORT MAP (
        control   => control,
        mem_clka  => mem_clka,
        mem_wea   => mem_wea,
        mem_addra => mem_addra,
        mem_dina  => mem_dina,
        mem_douta => mem_douta,
        wb_clk    => wb_clk,
        wb_rst    => wb_rst,
        wb_mosi   => wb_mosi,
        wb_miso   => wb_miso
    );

   -- Clock process definitions
   wb_clk_process :process
   begin
		wb_clk <= '1';
		wait for wb_clk_period/2;
		wb_clk <= '0';
		wait for wb_clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
        wb_rst <= '1';
        wb_miso(0).cyc <= '0'; wb_miso(0).stb <= '0'; wb_miso(0).we <= X"0"; wb_miso(0).adr <= B"00" & X"00"; wb_miso(0).dat_i <= X"00000000";
        -- hold reset state for 100 ns.
        wait for 101 ns;	
        wb_rst <= '0';
        wait for wb_clk_period*5;
        wb_miso(0).cyc <= '0'; wb_miso(0).stb <= '0'; wb_miso(0).we <= X"0"; wb_miso(0).adr <= B"00" & X"00"; wb_miso(0).dat_i <= X"00000000";
        wait for wb_clk_period*2;
        -- lettura 1
        wb_miso(0).cyc <= '1'; wb_miso(0).stb <= '1'; wb_miso(0).we <= X"0"; wb_miso(0).adr <=  B"00" & X"AA"; wb_miso(0).dat_i <= X"00000000";
        wait for wb_clk_period;
        mem_douta <= X"12345678";
        wait until wb_mosi(0).ack = '1'; wait for wb_clk_period*5;
        mem_douta <= X"00000000";
        wb_miso(0).cyc <= '0'; wb_miso(0).stb <= '0'; wb_miso(0).we <= X"0"; wb_miso(0).adr <=  B"00" & X"00"; wb_miso(0).dat_i <= X"00000000";
        wait for wb_clk_period*2;
        -- lettura 2
        wb_miso(0).cyc <= '1'; wb_miso(0).stb <= '1'; wb_miso(0).we <= X"0"; wb_miso(0).adr <=  B"00" & X"BB"; wb_miso(0).dat_i <= X"00000000";
        wait for wb_clk_period;
        mem_douta <= X"DEADBEEF";
        wait until wb_mosi(0).ack = '1'; wait for wb_clk_period;
        mem_douta <= X"00000000";
        wb_miso(0).cyc <= '0'; wb_miso(0).stb <= '0'; wb_miso(0).we <= X"0"; wb_miso(0).adr <=  B"00" & X"00"; wb_miso(0).dat_i <= X"00000000";
        wait for wb_clk_period*2;
        -- lettura 3 4 5
        wb_miso(0).cyc <= '1'; wb_miso(0).stb <= '1'; wb_miso(0).we <= X"0"; wb_miso(0).adr <=  B"00" & X"BB"; wb_miso(0).dat_i <= X"00000000";
        wait for wb_clk_period;
        mem_douta <= X"DEADBEEF";
        wait until wb_mosi(0).ack = '1'; wait for wb_clk_period;
        mem_douta <= X"AAAAAAAA"; wb_miso(0).stb <= '0';
        wait for wb_clk_period;   wb_miso(0).stb <= '1';

        wait until wb_mosi(0).ack = '1'; wait for wb_clk_period;
        mem_douta <= X"AAAAAAAA"; wb_miso(0).stb <= '0';
        wait for wb_clk_period;   wb_miso(0).stb <= '1';

        wait until wb_mosi(0).ack = '1'; wait for wb_clk_period;
        mem_douta <= X"BBBBBBBB"; wb_miso(0).stb <= '0';
        wait for wb_clk_period;

        wb_miso(0).cyc <= '0'; wb_miso(0).stb <= '0'; wb_miso(0).we <= X"0"; wb_miso(0).adr <=  B"00" & X"00"; wb_miso(0).dat_i <= X"00000000";
        wait for wb_clk_period*2;
        -- scrittura 1
        wb_miso(0).cyc <= '1'; wb_miso(0).stb <= '1'; wb_miso(0).we <= X"F"; wb_miso(0).adr <=  B"00" & X"AA"; wb_miso(0).dat_i <= X"87654321";
        wait for wb_clk_period;
        wait until wb_mosi(0).ack = '1'; wait for wb_clk_period;
        wb_miso(0).cyc <= '0'; wb_miso(0).stb <= '0'; wb_miso(0).we <= X"0"; wb_miso(0).adr <=  B"00" & X"00"; wb_miso(0).dat_i <= X"00000000";
        wait;
   end process;

END;
