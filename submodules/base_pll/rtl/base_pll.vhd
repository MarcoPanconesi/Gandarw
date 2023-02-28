----------------------------------------------------------------------------------
-- Company:         INFN-LNF
-- Engineer:        alessandro.balla@lnf.infn.it
-- 
-- Create Date:     11:43:03 05/24/2021 
-- Design Name: 
-- Module Name:     base_pll - Behavioral 
-- Project Name:    GANDARW
-- Target Devices:  XC5VSX95T-2FF1136
-- Tool versions:   ISE 14.7
-- Description:     pll module 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
-- tiger trigger
-- da capire bene, se bs_gimli_type = OCX chi genera i segnali vxs_clk_div e vxs_clk_ddr ???
--
-- ATTENZIONE : da cambiare PLL_BASE ... Non sembra essere riconosciuto come primitiva ...
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.STD_LOGIC_ARITH.all;


-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.vcomponents.all;

--  This package defines supplemental types, subtypes, 
--  constants, and functions 
use WORK.top_level_desc.all;

-- All the project parameters here ...
-- removed all the generic from top vhdl
use WORK.G_PARAMETERS.all;

entity base_pll is
    port (
        si_g_clk                : in    std_logic;
        vxs_trigger_data        : in    std_logic_vector(7 downto 0);
        clk_ocx_155             : out   std_logic;
        vxs_b_p                 : out   std_logic_vector(7 downto 0);
        vxs_b_n                 : out   std_logic_vector(7 downto 0);
        vxs_clk_ddr             : out   std_logic;
        vxs_clk_div             : out   std_logic
    );

end base_pll;


architecture behavioral of base_pll is

-- signal
signal clk_pll_fb           : std_logic; 
signal vxs_clk_ddr_buf      : std_logic;
signal vxs_clk_div_buf      : std_logic; 
signal clk_ocx_155_buf      : std_logic;
------------------------------------------------------------------------
begin  --------------------------- begin --------------------------------
------------------------------------------------------------------------

inst_t_trg : if bs_t_trigger = true generate
    inst_trigger : for i in 0 to 7 generate
      obufds_inst : obufds
        generic map (
                     iostandard => "LVDS_25"
                     )
        port map (
          o  => vxs_b_p(i),
          ob => vxs_b_n(i),
          i  => vxs_trigger_data(i)
          );
    end generate;
end generate;

inst_t_trg_unused : if bs_t_trigger = false generate
    vxs_b_p(7 downto 0) <= (others => 'Z');
    vxs_b_n(7 downto 0) <= (others => 'Z');
end generate; 


check_ocx_clk: if (bs_gimli_type = "OCX") generate -- bs_gimli_type == "ocx"
begin

-- Per qualche ragione ISE non riconosce quetsa primitiva ... cambiata con PLL_ADV
    Inst_pll_base : PLL_BASE
    generic map (
        BANDWIDTH           => "HIGH",                      -- "HIGH", "LOW" OR "OPTIMIZED"
        CLKFBOUT_MULT       => 1,                           -- multiplication factor for all output clocks
        CLKFBOUT_PHASE      => 0.0,                         -- phase shift (degrees) of all output clocks
        CLKIN_PERIOD        => bs_si_period,                -- clock period (ns) of input clock on clkin
        CLKOUT0_DIVIDE      => 3,                           -- division factor for clkout0  (1 to 128)
        CLKOUT0_DUTY_CYCLE  => 0.5,                         -- duty cycle for clkout0 (0.01 to 0.99)
        CLKOUT0_PHASE       => 0.0,                         -- phase shift (degrees) for clkout0 (0.0 to 360.0)
        CLKOUT1_DIVIDE      => 1,                           -- division factor for clkout1 (1 to 128)
        CLKOUT1_DUTY_CYCLE  => 0.5,                         -- duty cycle for clkout1 (0.01 to 0.99)
        CLKOUT1_PHASE       => 0.0,                         -- phase shift (degrees) for clkout1 (0.0 to 360.0)
        CLKOUT2_DIVIDE      => 1,                           -- division factor for clkout2 (1 to 128)
        CLKOUT2_DUTY_CYCLE  => 0.5,                         -- duty cycle for clkout2 (0.01 to 0.99)
        CLKOUT2_PHASE       => 0.0,                         -- phase shift (degrees) for clkout2 (0.0 to 360.0)
        CLKOUT3_DIVIDE      => 1,                           -- division factor for clkout3 (1 to 128)
        CLKOUT3_DUTY_CYCLE  => 0.5,                         -- duty cycle for clkout3 (0.01 to 0.99)
        CLKOUT3_PHASE       => 0.0,                         -- phase shift (degrees) for clkout3 (0.0 to 360.0)
        CLKOUT4_DIVIDE      => 1,                           -- division factor for clkout4 (1 to 128)
        CLKOUT4_DUTY_CYCLE  => 0.5,                         -- duty cycle for clkout4 (0.01 to 0.99)
        CLKOUT4_PHASE       => 0.0,                         -- phase shift (degrees) for clkout4 (0.0 to 360.0)
        CLKOUT5_DIVIDE      => 1,                           -- division factor for clkout5 (1 to 128)
        CLKOUT5_DUTY_CYCLE  => 0.5,                         -- duty cycle for clkout5 (0.01 to 0.99)
        CLKOUT5_PHASE       => 0.0,                         -- phase shift (degrees) for clkout5 (0.0 to 360.0)
        COMPENSATION        => "SYSTEM_SYNCHRONOUS",        -- "SYSTEM_SYNCHRONOUS",
                                                            -- "SOURCE_SYNCHRONOUS", "INTERNAL",
                                                            -- "EXTERNAL", "DCM2PLL", "PLL2DCM"
        DIVCLK_DIVIDE       => 1,                           -- division factor for all clocks (1 to 52)
        REF_JITTER          => 0.100)                       -- input reference jitter (0.000 to 0.999 ui%)
    port map (
        CLKFBOUT            => clk_pll_fb,                  -- general output feedback signal
        CLKOUT0             => clk_ocx_155_buf,             -- one of six general clock output signals
        CLKOUT1             => open,                        -- one of six general clock output signals
        CLKOUT2             => open,                        -- one of six general clock output signals
        CLKOUT3             => open,                        -- one of six general clock output signals
        CLKOUT4             => open,                        -- one of six general clock output signals
        CLKOUT5             => open,                        -- one of six general clock output signals
        LOCKED              => open,                        -- active high pll lock signal
        CLKFBIN             => clk_pll_fb,                  -- clock feedback input
        CLKIN               => si_g_clk,                    -- clock input
        RST                 => '0'                          -- asynchronous pll reset
        );

--    PLL_ADV_inst : PLL_ADV
--    generic map (
--        BANDWIDTH               => "HIGH",                  -- "HIGH", "LOW" or "OPTIMIZED" 
--        CLKFBOUT_MULT           => 1,                       -- Multiplication factor for all output clocks
--        CLKFBOUT_PHASE          => 0.0,                     -- Phase shift (degrees) of all output clocks
--        CLKIN1_PERIOD           => bs_si_period,            -- Clock period (ns) of input clock on CLKIN1
--        CLKIN2_PERIOD           => 0.000,                   -- Clock period (ns) of input clock on CLKIN2
--        CLKOUT0_DIVIDE          => 3,                       -- Division factor for CLKOUT0  (1 to 128)
--        CLKOUT0_DUTY_CYCLE      => 0.5,                     -- Duty cycle for CLKOUT0 (0.01 to 0.99)
--        CLKOUT0_PHASE           => 0.0,                     -- Phase shift (degrees) for CLKOUT0 (0.0 to 360.0)
--        CLKOUT1_DIVIDE          => 1,                       -- Division factor for CLKOUT1 (1 to 128)
--        CLKOUT1_DUTY_CYCLE      => 0.5,                     -- Duty cycle for CLKOUT1 (0.01 to 0.99)
--        CLKOUT1_PHASE           => 0.0,                     -- Phase shift (degrees) for CLKOUT1 (0.0 to 360.0)
--        CLKOUT2_DIVIDE          => 1,                       -- Division factor for CLKOUT2 (1 to 128)
--        CLKOUT2_DUTY_CYCLE      => 0.5,                     -- Duty cycle for CLKOUT2 (0.01 to 0.99)
--        CLKOUT2_PHASE           => 0.0,                     -- Phase shift (degrees) for CLKOUT2 (0.0 to 360.0)
--        CLKOUT3_DIVIDE          => 1,                       -- Division factor for CLKOUT3 (1 to 128)
--        CLKOUT3_DUTY_CYCLE      => 0.5,                     -- Duty cycle for CLKOUT3 (0.01 to 0.99)
--        CLKOUT3_PHASE           => 0.0,                     -- Phase shift (degrees) for CLKOUT3 (0.0 to 360.0)
--        CLKOUT4_DIVIDE          => 1,                       -- Division factor for CLKOUT4 (1 to 128)
--        CLKOUT4_DUTY_CYCLE      => 0.5,                     -- Duty cycle for CLKOUT4 (0.01 to 0.99)
--        CLKOUT4_PHASE           => 0.0,                     -- Phase shift (degrees) for CLKOUT4 (0.0 to 360.0)
--        CLKOUT5_DIVIDE          => 1,                       -- Division factor for CLKOUT5 (1 to 128)
--        CLKOUT5_DUTY_CYCLE      => 0.5,                     -- Duty cycle for CLKOUT5 (0.01 to 0.99)
--        CLKOUT5_PHASE           => 0.0,                     -- Phase shift (degrees) for CLKOUT5 (0.0 to 360.0)
--        COMPENSATION            => "SYSTEM_SYNCHRONOUS",    -- "SYSTEM_SYNCHRONOUS", 
--                                                            -- "SOURCE_SYNCHRONOUS", "INTERNAL", 
--                                                            -- "EXTERNAL", "DCM2PLL", "PLL2DCM" 
--        DIVCLK_DIVIDE           => 1,                       -- Division factor for all clocks (1 to 52)
--        EN_REL                  => FALSE,                   -- Enable release (PMCD mode only)
--        PLL_PMCD_MODE           => FALSE,                   -- PMCD Mode, TRUE/FASLE
--        REF_JITTER              => 0.100,                   -- Input reference jitter (0.000 to 0.999 UI%)
--        RST_DEASSERT_CLK        => "CLKIN1")                -- In PMCD mode, clock to synchronize RST release
--    port map (
--        CLKFBDCM                => open,                    -- Output feedback signal used when PLL feeds a DCM
--        CLKFBOUT                => clk_pll_fb,              -- General output feedback signal
--        CLKOUT0                 => clk_ocx_155_buf,             -- One of six general clock output signals
--        CLKOUT1                 => open,                    -- One of six general clock output signals
--        CLKOUT2                 => open,                    -- One of six general clock output signals
--        CLKOUT3                 => open,                    -- One of six general clock output signals
--        CLKOUT4                 => open,                    -- One of six general clock output signals
--        CLKOUT5                 => open,                    -- One of six general clock output signals
--        CLKOUTDCM0              => open,                    -- One of six clock outputs to connect to the DCM
--        CLKOUTDCM1              => open,                    -- One of six clock outputs to connect to the DCM
--        CLKOUTDCM2              => open,                    -- One of six clock outputs to connect to the DCM
--        CLKOUTDCM3              => open,                    -- One of six clock outputs to connect to the DCM
--        CLKOUTDCM4              => open,                    -- One of six clock outputs to connect to the DCM
--        CLKOUTDCM5              => open,                    -- One of six clock outputs to connect to the DCM
--        DO                      => open,                    -- Dynamic reconfig data output (16-bits)
--        DRDY                    => open,                    -- Dynamic reconfig ready output
--        LOCKED                  => open,                    -- Active high PLL lock signal
--        CLKFBIN                 => clk_pll_fb,              -- Clock feedback input
--        CLKIN1                  => si_g_clk,                -- Primary clock input
--        CLKIN2                  => '0',                     -- Secondary clock input
--        CLKINSEL                => '1',                     -- Selects CLKIN1 or CLKIN2
--        DADDR                   => (others => '0'),         -- Dynamic reconfig address input (5-bits)
--        DCLK                    => '0',                     -- Dynamic reconfig clock input
--        DEN                     => '0',                     -- Dynamic reconfig enable input
--        DI                      => (others => '0'),         -- Dynamic reconfig data input (16-bits)
--        DWE                     => '0',                     -- Dynamic reconfig write enable input
--        REL                     => '0',                     -- Clock release input (PMCD mode only)
--        RST                     => '0'                      -- Asynchronous PLL reset
--        );

        inst_bufg_i : bufg
        port map (
            i => clk_ocx_155_buf,
            o => clk_ocx_155
        );

end generate; -- bs_gimli_type == "ocx"

check_no_ocx_clk: if (bs_gimli_type /= "OCX") generate -- bs_gimli_type != "ocx"
begin
-- Per qualche ragione ISE non riconosce quetsa primitiva ... cambiata con PLL_ADV
--        Inst_pll_base : PLL_BASE
--
--        generic map (
--            BANDWIDTH           => "HIGH",                      -- "HIGH", "LOW" OR "OPTIMIZED"
--            CLKFBOUT_MULT       => 1,                           -- multiplication factor for all output clocks
--            CLKFBOUT_PHASE      => 0.0,                         -- phase shift (degrees) of all output clocks
--            CLKIN_PERIOD        => bs_si_period,                -- clock period (ns) of input clock on clkin
--            CLKOUT0_DIVIDE      => 1,                           -- division factor for clkout0  (1 to 128)
--            CLKOUT0_DUTY_CYCLE  => 0.5,                         -- duty cycle for clkout0 (0.01 to 0.99)
--            CLKOUT0_PHASE       => 0.0,                         -- phase shift (degrees) for clkout0 (0.0 to 360.0)
--            CLKOUT1_DIVIDE      => 5,                           -- division factor for clkout1 (1 to 128)
--            CLKOUT1_DUTY_CYCLE  => 0.5,                         -- duty cycle for clkout1 (0.01 to 0.99)
--            CLKOUT1_PHASE       => 0.0,                         -- phase shift (degrees) for clkout1 (0.0 to 360.0)
--            CLKOUT2_DIVIDE      => 1,                           -- division factor for clkout2 (1 to 128)
--            CLKOUT2_DUTY_CYCLE  => 0.5,                         -- duty cycle for clkout2 (0.01 to 0.99)
--            CLKOUT2_PHASE       => 0.0,                         -- phase shift (degrees) for clkout2 (0.0 to 360.0)
--            CLKOUT3_DIVIDE      => 1,                           -- division factor for clkout3 (1 to 128)
--            CLKOUT3_DUTY_CYCLE  => 0.5,                         -- duty cycle for clkout3 (0.01 to 0.99)
--            CLKOUT3_PHASE       => 0.0,                         -- phase shift (degrees) for clkout3 (0.0 to 360.0)
--            CLKOUT4_DIVIDE      => 1,                           -- division factor for clkout4 (1 to 128)
--            CLKOUT4_DUTY_CYCLE  => 0.5,                         -- duty cycle for clkout4 (0.01 to 0.99)
--            CLKOUT4_PHASE       => 0.0,                         -- phase shift (degrees) for clkout4 (0.0 to 360.0)
--            CLKOUT5_DIVIDE      => 1,                           -- division factor for clkout5 (1 to 128)
--            CLKOUT5_DUTY_CYCLE  => 0.5,                         -- duty cycle for clkout5 (0.01 to 0.99)
--            CLKOUT5_PHASE       => 0.0,                         -- phase shift (degrees) for clkout5 (0.0 to 360.0)
--            COMPENSATION        => "SYSTEM_SYNCHRONOUS",        -- "SYSTEM_SYNCHRONOUS",                                                        
--                                                                -- "SOURCE_SYNCHRONOUS", "INTERNAL",                                                     
--                                                                -- "EXTERNAL", "DCM2PLL", "PLL2DCM"
--            DIVCLK_DIVIDE       => 1,                           -- division factor for all clocks (1 to 52)
--            REF_JITTER          => 0.100)                       -- input reference jitter (0.000 to 0.999 ui%)
--        port map (
--            CLKFBOUT            => clk_pll_fb,                  -- general output feedback signal
--            CLKOUT0             => vxs_clk_ddr_buf,             -- one of six general clock output signals
--            CLKOUT1             => vxs_clk_div_buf,             -- one of six general clock output signals
--            CLKOUT2             => open,                        -- one of six general clock output signals
--            CLKOUT3             => open,                        -- one of six general clock output signals
--            CLKOUT4             => open,                        -- one of six general clock output signals
--            CLKOUT5             => open,                        -- one of six general clock output signals
--            LOCKED              => open,                        -- active high pll lock signal
--            CLKFBIN             => clk_pll_fb,                  -- clock feedback input
--            CLKIN               => si_g_clk,                    -- clock input
--            RST                 => '0'                          -- asynchronous pll reset
--            );

    PLL_ADV_inst : PLL_ADV
    generic map (
        BANDWIDTH               => "HIGH",                  -- "HIGH", "LOW" or "OPTIMIZED" 
        CLKFBOUT_MULT           => 1,                       -- Multiplication factor for all output clocks
        CLKFBOUT_PHASE          => 0.0,                     -- Phase shift (degrees) of all output clocks
        CLKIN1_PERIOD           => bs_si_period,            -- Clock period (ns) of input clock on CLKIN1
        CLKIN2_PERIOD           => 0.000,                   -- Clock period (ns) of input clock on CLKIN2
        CLKOUT0_DIVIDE          => 1,                       -- Division factor for CLKOUT0  (1 to 128)
        CLKOUT0_DUTY_CYCLE      => 0.5,                     -- Duty cycle for CLKOUT0 (0.01 to 0.99)
        CLKOUT0_PHASE           => 0.0,                     -- Phase shift (degrees) for CLKOUT0 (0.0 to 360.0)
        CLKOUT1_DIVIDE          => 5,                       -- Division factor for CLKOUT1 (1 to 128)
        CLKOUT1_DUTY_CYCLE      => 0.5,                     -- Duty cycle for CLKOUT1 (0.01 to 0.99)
        CLKOUT1_PHASE           => 0.0,                     -- Phase shift (degrees) for CLKOUT1 (0.0 to 360.0)
        CLKOUT2_DIVIDE          => 1,                       -- Division factor for CLKOUT2 (1 to 128)
        CLKOUT2_DUTY_CYCLE      => 0.5,                     -- Duty cycle for CLKOUT2 (0.01 to 0.99)
        CLKOUT2_PHASE           => 0.0,                     -- Phase shift (degrees) for CLKOUT2 (0.0 to 360.0)
        CLKOUT3_DIVIDE          => 1,                       -- Division factor for CLKOUT3 (1 to 128)
        CLKOUT3_DUTY_CYCLE      => 0.5,                     -- Duty cycle for CLKOUT3 (0.01 to 0.99)
        CLKOUT3_PHASE           => 0.0,                     -- Phase shift (degrees) for CLKOUT3 (0.0 to 360.0)
        CLKOUT4_DIVIDE          => 1,                       -- Division factor for CLKOUT4 (1 to 128)
        CLKOUT4_DUTY_CYCLE      => 0.5,                     -- Duty cycle for CLKOUT4 (0.01 to 0.99)
        CLKOUT4_PHASE           => 0.0,                     -- Phase shift (degrees) for CLKOUT4 (0.0 to 360.0)
        CLKOUT5_DIVIDE          => 1,                       -- Division factor for CLKOUT5 (1 to 128)
        CLKOUT5_DUTY_CYCLE      => 0.5,                     -- Duty cycle for CLKOUT5 (0.01 to 0.99)
        CLKOUT5_PHASE           => 0.0,                     -- Phase shift (degrees) for CLKOUT5 (0.0 to 360.0)
        COMPENSATION            => "SYSTEM_SYNCHRONOUS",    -- "SYSTEM_SYNCHRONOUS", 
                                                            -- "SOURCE_SYNCHRONOUS", "INTERNAL", 
                                                            -- "EXTERNAL", "DCM2PLL", "PLL2DCM" 
        DIVCLK_DIVIDE           => 1,                       -- Division factor for all clocks (1 to 52)
        EN_REL                  => FALSE,                   -- Enable release (PMCD mode only)
        PLL_PMCD_MODE           => FALSE,                   -- PMCD Mode, TRUE/FASLE
        REF_JITTER              => 0.100,                   -- Input reference jitter (0.000 to 0.999 UI%)
        RST_DEASSERT_CLK        => "CLKIN1")                -- In PMCD mode, clock to synchronize RST release
    port map (
        CLKFBDCM                => open,                    -- Output feedback signal used when PLL feeds a DCM
        CLKFBOUT                => clk_pll_fb,              -- General output feedback signal
        CLKOUT0                 => vxs_clk_ddr_buf,         -- One of six general clock output signals
        CLKOUT1                 => vxs_clk_div_buf,         -- One of six general clock output signals
        CLKOUT2                 => open,                    -- One of six general clock output signals
        CLKOUT3                 => open,                    -- One of six general clock output signals
        CLKOUT4                 => open,                    -- One of six general clock output signals
        CLKOUT5                 => open,                    -- One of six general clock output signals
        CLKOUTDCM0              => open,                    -- One of six clock outputs to connect to the DCM
        CLKOUTDCM1              => open,                    -- One of six clock outputs to connect to the DCM
        CLKOUTDCM2              => open,                    -- One of six clock outputs to connect to the DCM
        CLKOUTDCM3              => open,                    -- One of six clock outputs to connect to the DCM
        CLKOUTDCM4              => open,                    -- One of six clock outputs to connect to the DCM
        CLKOUTDCM5              => open,                    -- One of six clock outputs to connect to the DCM
        DO                      => open,                    -- Dynamic reconfig data output (16-bits)
        DRDY                    => open,                    -- Dynamic reconfig ready output
        LOCKED                  => open,                    -- Active high PLL lock signal
        CLKFBIN                 => clk_pll_fb,              -- Clock feedback input
        CLKIN1                  => si_g_clk,                -- Primary clock input
        CLKIN2                  => '0',                     -- Secondary clock input
        CLKINSEL                => '1',                     -- Selects CLKIN1 or CLKIN2
        DADDR                   => (others => '0'),         -- Dynamic reconfig address input (5-bits)
        DCLK                    => '0',                     -- Dynamic reconfig clock input
        DEN                     => '0',                     -- Dynamic reconfig enable input
        DI                      => (others => '0'),         -- Dynamic reconfig data input (16-bits)
        DWE                     => '0',                     -- Dynamic reconfig write enable input
        REL                     => '0',                     -- Clock release input (PMCD mode only)
        RST                     => '0'                      -- Asynchronous PLL reset
        );


    inst_bufg_i : bufg
        port map (
            i => vxs_clk_ddr_buf,
            o => vxs_clk_ddr
        );
    inst_bufg_ii : bufg
        port map (
            i => vxs_clk_div_buf,
            o => vxs_clk_div
            );

end generate; -- bs_gimli_type != "ocx"

end;

