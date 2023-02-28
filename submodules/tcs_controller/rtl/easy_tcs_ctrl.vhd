-------------------------------------------------------------------------------
-- Title    : easy tcs controller
-- Project    : test project
-------------------------------------------------------------------------------
-- File		  : easy_tcs_ctrl.vhd
-- Author	  :	  <grussy@pcfr16.physik.uni-freiburg.de>
-- Company	  : 
-- Created	  : 2013-11-06
-- Last update: 2014-05-15
-- Platform	  : 
-- Standard	  : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: easy to use tcs controller
-------------------------------------------------------------------------------
-- Copyright (c) 2013
-------------------------------------------------------------------------------
-- Revisions  :
-- Date      Version  Author  Description
-- 2013-11-06  1.0    grussy  Created
--
-- Alex added clk38en fron external signal 
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.STD_LOGIC_UNSIGNED.all;
use ieee.NUMERIC_STD.all;
library UNISIM;
use UNISIM.vcomponents.all;
library UNIMACRO;
use UNIMACRO.vcomponents.all;
-------------------------------------------------------------------------------

entity easy_tcs_ctrl is
    generic(gen_accel_sim : boolean := false);
	port (
        control             : inout std_logic_vector(35 downto 0);
		ext_trigger		    : in  std_logic;
		fr_tcs_ctrl		    : in  std_logic_vector(2 downto 0);
		fr_internal_trig    : in  std_logic_vector(4 downto 0);
		clk				    : in  std_logic;
        clk38en             : in  std_logic;   
        tcs_data            : out std_logic
    );

end entity easy_tcs_ctrl;

-------------------------------------------------------------------------------

architecture behav of easy_tcs_ctrl is

  signal flt     : std_logic := '0';
  signal bos     : std_logic := '0';
  signal eos     : std_logic := '0';
  signal bor     : std_logic := '0';
  signal eor     : std_logic := '0';
  -- signal clk38en : std_logic := '0';

  signal double_suppress : integer range 0 to 9 := 0;

  signal clk38cnt : integer range 0 to 3       := 0;
  signal flt_sr : std_logic_vector(1 downto 0) := "00";


-------------------------------------------------------------------------------
-- constants
	signal oneHertz	  : std_logic_vector(47 downto 0) := x"000002514300";
	signal twoHertz	  : std_logic_vector(47 downto 0) := x"00000128A180";
	signal fourHertz  : std_logic_vector(47 downto 0) := x"0000009450C0";
	signal eightHertz : std_logic_vector(47 downto 0) := x"0000004A2860";

-- int trigger
	signal fr_int_trg_en_sr	 : std_logic_vector(1 downto 0)	 := "00";
	signal fr_rand_trg_en_sr : std_logic_vector(1 downto 0)	 := "00";
	signal freq				 : std_logic_vector(1 downto 0)	 := "00";
	signal int_trg_en		 : std_logic					 := '0';
	signal rand_trg_en		 : std_logic					 := '0';
	signal random			 : std_logic					 := '0';
	signal int_cnt_en		 : std_logic					 := '0';
	signal load				 : std_logic					 := '0';
	signal load_r			 : std_logic					 := '0';
	signal int_trg			 : std_logic					 := '0';
	signal int_trigger		 : std_logic					 := '0';
	signal int_trig_cnt		 : integer range 0 to 38880000	 := 0;
	signal load_data		 : std_logic_vector(47 downto 0) := (others => '0');
-------------------------------------------------------------------------------
	
begin  -- architecture behav
-------------------------------------------------------------------------------
-- internal trigger generator
	process
	begin
		wait until rising_edge(clk);
		if clk38en = '1' then
			fr_int_trg_en_sr <= fr_int_trg_en_sr(0) & fr_internal_trig(0);
			if fr_int_trg_en_sr = "01" then
				int_trg_en <= '1';
			elsif fr_int_trg_en_sr = "10" then
				int_trg_en <= '0';
			end if;

--fr for random trigger
			fr_rand_trg_en_sr <= fr_rand_trg_en_sr(0) & fr_internal_trig(1);
			if fr_rand_trg_en_sr = "01" then
				rand_trg_en <= '1';
			elsif fr_rand_trg_en_sr = "10" then
				rand_trg_en <= '0';
			end if;

			int_trig_cnt <= int_trig_cnt + 1;

			if int_trg_en = '1' then
				if int_trig_cnt = 0 then
					int_trigger <= '1';
				else
					int_trigger <= '0';
				end if;
			end if;
		end if;
	end process;
------------------------------------------------------------------------------- 

-------------------------------------------------------------------------------
-- random triggers
	randomtrigger_1 : entity work.randomtrigger
		port map (
			clk	   => clk,
			ce	   => clk38en,
			bos	   => bos,
			eos	   => eos,
			freq   => fr_internal_trig(4 downto 2),
			random => random);
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- get FLTs from gandalf
	process
	begin
		wait until rising_edge(clk);
		if clk38en = '1' then
			flt_sr	 <= flt_sr(0) & (ext_trigger or int_trigger or (rand_trg_en and random));
--flts
      flt <= '0';
      if flt_sr = "01" and double_suppress = 0 then
        flt       <= '1';
        double_suppress <= 9;
      end if;
      if double_suppress > 0 then
        double_suppress <= double_suppress - 1;
      end if;
    end if;
  end process;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- mark the 38clk
--  process
--  begin
--    wait until rising_edge(clk);
--    clk38en <= '0';
--    if clk38cnt = 3 then
--      clk38cnt <= 0;
--    else
--      clk38cnt <= clk38cnt + 1;
--    end if;
--    if clk38cnt = 0 then
--      clk38en <= '1';
--    end if;
--  end process;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- tcs controller instance
    no_sim : if not gen_accel_sim generate
    tcs_ctrl : entity work.tcs_ctrl
        port map (
            CONTROL    => CONTROL,
            TRIGGER     => flt,
            TCS_CLK     => clk,
            CE          => clk38en,
            BOR         => fr_tcs_ctrl(2),
            EOR         => '0',
            BOS         => fr_tcs_ctrl(1),
            EOS         => fr_tcs_ctrl(0),
            EVENT_TYPE  => open,
            TCS_CLK_P   => open,
            TCS_CLK_N   => open,
            TCS_DATA_P  => tcs_data,
            TCS_DATA_N  => open
            );
    end generate;

    sim : if gen_accel_sim generate
    tcs_ctrl : entity work.tcs_ctrl
     generic map (
        GEN_BOS_CNT => 38
        )
     port map (
        CONTROL    => CONTROL,
        TRIGGER     => flt,
        TCS_CLK     => clk,
        CE          => clk38en,
        BOR         => fr_tcs_ctrl(2),
        EOR         => '0',
        BOS         => fr_tcs_ctrl(1),
        EOS         => fr_tcs_ctrl(0),
        EVENT_TYPE  => open,
        TCS_CLK_P   => open,
        TCS_CLK_N   => open,
        TCS_DATA_P  => tcs_data,
        TCS_DATA_N  => open
        );
    end generate;
-------------------------------------------------------------------------------

end architecture behav;

-------------------------------------------------------------------------------
