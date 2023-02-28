-------------------------------------------------------------------------------
-- Title      : FIFO 2 clock 1 read 1 write
-- Project    : 
-------------------------------------------------------------------------------
-- File        : fifo3.vhd
-- Author      : Alessandro BALLA, Paolo CIAMBRONE 
--              (alessandro.balla@lnf.infn.it paolo.ciambrone@lnf.infn.it)
-- Organization:
-- Created     : 29/09/2014
-- Last update : 
-- Platform    : Foundation ISE
-- Simulators  : Modelsim
-- Synthesizers: Foundation XST
-- Targets     : Xilinx 
-- Dependency  : IEEE std_logic_1164
-------------------------------------------------------------------------------
-- Description : generic fifo with 2 clk domain
-------------------------------------------------------------------------------
-- Copyright (c) notice
--  
--      
-------------------------------------------------------------------------------
-- Revisions       :    1.0
-- Revision Number :
-- Version         :
-- Date              :
-- Modifier        : 
-- Description     :    
--
------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity fifo3 is

     Generic ( 
        deep        : integer := 4;
        width       : integer := 8); 
    Port ( 
        datain      : in  std_logic_vector(width - 1  downto 0);
        wrclk       : in  std_logic;
        rdclk       : in  std_logic;
        res         : in  std_logic;
        oe          : in  std_logic;
        wr_en       : in  std_logic;
        rd_en       : in  std_logic;
        empty       : out std_logic;
        full        : out std_logic;
        count_dat   : out std_logic_vector(deep - 1 downto 0);
        dataout     : out std_logic_vector(width - 1 downto 0)
              );
end fifo3;

architecture Behavioral of fifo3 is

 
    signal do_ram       : std_logic_vector(width - 1 downto 0);
    signal count_wr     : std_logic_vector(deep - 1 downto 0) := (others =>'0');
    signal count_rd     : std_logic_vector(deep - 1 downto 0) := (others =>'0');
    signal wr_allow     : std_logic;
    signal rd_allow     : std_logic;

    signal empty_int    : std_logic := '1';
    signal full_int     : std_logic := '0';


    type ram_type is array ((2 ** deep) - 1 downto 0) of std_logic_vector (width - 1 downto 0); 
    signal RAM : ram_type; 
    

begin

 
  full  <= full_int;
  empty <= empty_int;

  rd_allow <= '1' when rd_en = '1' and empty_int = '0' else '0';
  wr_allow <= '1' when wr_en = '1' and full_int  = '0' else '0';

  dataout <= do_ram when oe = '1' else (others => 'Z');

  ----------------------------------------------
  --    process count_dat 
  ----------------------------------------------   
  process (rdclk, res)
  begin
    if res = '1' then
      count_dat <= (others =>'0');
    elsif rising_edge(rdclk) then
      count_dat <= count_wr - count_rd;
    end if;
  end process;

  ----------------------------------------------
  --    process count_rd 
  ----------------------------------------------   
  process (rdclk, res)
  begin
    if res = '1' then
      count_rd <= (others =>'0');
    elsif rising_edge(rdclk) then
      if rd_allow = '1' then
            count_rd <= count_rd + 1;
        end if;
        do_ram <= RAM(conv_integer(count_rd));
    end if;
  end process;
    
  ----------------------------------------------
  -- process count_wr 
  ----------------------------------------------
  process (wrclk, res)
  begin
    if res = '1' then
      count_wr <= (others =>'0');
    elsif rising_edge(wrclk) then
      if wr_allow = '1' then
        RAM(conv_integer(count_wr)) <= datain;
            count_wr <= count_wr + 1;
      end if;
    end if;
  end process;


  ----------------------------------------------
  -- process empty_int
  ----------------------------------------------
  process (rdclk, res)
  begin
    if res = '1' then
      empty_int <= '1';
    elsif rising_edge(rdclk) then
      if ((count_rd = count_wr - 1) and rd_allow = '1') then 
            empty_int <= '1';
      elsif (count_rd /= count_wr) then
            empty_int <= '0';
      end if;
    end if;
  end process;


  ----------------------------------------------
  -- process full_int
  ----------------------------------------------
  process (wrclk, res)
  begin
    if res = '1' then
      full_int <= '0';
    elsif rising_edge(wrclk) then
      if ((count_wr = count_rd - 1) and wr_allow = '1') then
            full_int <= '1';
      elsif (count_wr /=  count_rd) then
            full_int <= '0';
      end if;
    end if;
  end process;

end Behavioral;

