-------------------------------------------------------------------------------
-- Title    : gimli interface
-- Project    : test project
-------------------------------------------------------------------------------
-- File     : gimli_if.vhd
-- Author   :   <grussy@pcfr16.physik.uni-freiburg.de>
-- Company    :
-- Created    : 2013-10-18
-- Last update: 2013-11-07
-- Platform   :
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: has the connections to the gimli card
-------------------------------------------------------------------------------
-- Copyright (c) 2013
-------------------------------------------------------------------------------
-- Revisions  :
-- Date      Version  Author  Description
-- 2013-10-18  1.0    grussy  Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
library UNISIM;
use UNISIM.vcomponents.all;
-------------------------------------------------------------------------------

entity gimli_if is
    generic (
        gimli_type                  : string := "VXS";
        ocx_clock_input             : string := "internal"
        );
    port (
-------------------------------------------------------------------------------
-- toplevel
        TMC_LOCK                    : in  std_logic := '0';
        TMC_RATE                    : out std_logic;

        TCS_CLK_P                   : in  std_logic;
        TCS_CLK_N                   : in  std_logic;

        TCS_DATA_P                  : inout std_logic;
        TCS_DATA_N                  : inout std_logic;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- internal
        vxs_tcs_clk_p               : in  std_logic;
        vxs_tcs_clk_n               : in  std_logic;
        vxs_tcs_data_p              : in  std_logic;
        vxs_tcs_data_n              : in  std_logic;
        vxs_request_tcs_from_tiger  : out std_logic;

        si_has_lock_and_signal      : in std_logic;

        gimli_tcs_clk               : out std_logic;
        gimli_tcs_data              : out std_logic
-------------------------------------------------------------------------------
    );

end entity gimli_if;

-------------------------------------------------------------------------------

architecture behav of gimli_if is

  signal vxs_tcs_clk            : std_logic;
  signal vxs_tcs_clk_to_bufr    : std_logic;
  signal vxs_tcs_data           : std_logic;

  signal tcs_clk                : std_logic;
  signal tcs_data               : std_logic;

  signal gimli_tcs_clk_i        : std_logic;
  signal gimli_tcs_clk_bufg     : std_logic;
begin  -- architecture behav

-------------------------------------------------------------------------------
-- All cases (vxs, tcs, ocx)
  vxs_tcs_clk_ibuf : IBUFDS
    generic map (
        IOSTANDARD => "LVDS_25",
        DIFF_TERM  => true)
    port map (
        I  => vxs_tcs_clk_p,
        IB => vxs_tcs_clk_n,
--      O  => vxs_tcs_clk_to_bufr
        O  => vxs_tcs_clk
      );
  vxs_tcs_data_ibuf : IBUFDS
    generic map (
        IOSTANDARD => "LVDS_25",
        DIFF_TERM  => true)
    port map (
        I  => vxs_tcs_data_p,
        IB => vxs_tcs_data_n,
        O  => vxs_tcs_data
        );
  inst_term_clk : IBUFDS  --terminates TCS clock wheter it is used or not
    generic map (
        IOSTANDARD => "LVDS_25",
        DIFF_TERM  => true)
    port map (
        I  => TCS_CLK_P,
        IB => TCS_CLK_N,
        O  => tcs_clk
        );
--   vxs_regional_clock : bufr
--    port map (
--      O => vxs_tcs_clk,
--      I => vxs_tcs_clk_to_bufr,
--      CE => '1',
--      CLR => '0'
--      );

  BUFG_inst : BUFG
    port map (
      O => gimli_tcs_clk_bufg,
      I => gimli_tcs_clk_i
      );
  gimli_tcs_clk <= gimli_tcs_clk_bufg;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- vxs
  vxs_gimli : if gimli_type = "VXS" generate                -- dal BUS
--    redirects clock over the vxs gimli to the si5326
    inst_clk_feedback : OBUFDS
      port map (
        O  => TCS_DATA_P,
        OB => TCS_DATA_N,
        I  => gimli_tcs_clk_bufg
        );
--    LED on when si has the signal
    TMC_RATE           <= si_has_lock_and_signal;
    vxs_request_tcs_from_tiger <= '1';

    gimli_tcs_clk_i <= vxs_tcs_clk;
    gimli_tcs_data  <= vxs_tcs_data;
  end generate vxs_gimli;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- tcs
  tcs_gimli : if gimli_type = "TCS" generate            -- dalla FIBRA
    tcs_data_ibuf : IBUFDS
      generic map (
        IOSTANDARD => "LVDS_25",
        DIFF_TERM  => true)
      port map (
        I  => TCS_DATA_P,
        IB => TCS_DATA_N,
        O  => tcs_data
        );
    TMC_RATE           <= '0';
    vxs_request_tcs_from_tiger <= '0';

    gimli_tcs_clk_i <= tcs_clk;
    gimli_tcs_data  <= tcs_data;
  end generate tcs_gimli;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- ocx
  ocx_gimli : if gimli_type = "OCX" generate            -- dal RAME
    ocx_tcs_data_ibuf : IBUFDS
      generic map (
        IOSTANDARD => "LVDS_25",
        DIFF_TERM  => true)
      port map (
        I  => TCS_DATA_P,
        IB => TCS_DATA_N,
        O  => tcs_data
        );
    clkselect_int : if ocx_clock_input = "internal" generate
      TMC_RATE <= '1';
    end generate clkselect_int;

    clkselect_ext : if ocx_clock_input = "external" generate
      TMC_RATE <= '0';
    end generate clkselect_ext;

    vxs_request_tcs_from_tiger <= '0';

    gimli_tcs_clk_i <= tcs_clk;
    gimli_tcs_data  <= not tcs_data;  -- tcs_data in case of OCX is the trigger copper input. signal from gimli is inverted
  end generate ocx_gimli;
-------------------------------------------------------------------------------
end architecture behav;

-------------------------------------------------------------------------------
