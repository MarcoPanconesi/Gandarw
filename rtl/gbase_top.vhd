-- vsg_off
----------------------------------------------------------------------------------
-- Company:         INFN-LNF
-- Engineer:        alessandro.balla@lnf.infn.it
-- 
-- Create Date:     11:43:03 05/24/2021 
-- Design Name: 
-- Module Name:     gbase_top - Behavioral 
-- Project Name:    GANDARW
-- Target Devices:  XC5VSX95T-2FF1136
-- Tool versions:   ISE 14.7
-- Description:     Mix of Gandalf (amc) and Arwen\gbase_arwen 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
-- Nel file G_PARAMETERS:VHD si dovrebbero trovare tutti i parametri da settare ...
-- sfortunatamente il progetto Arwen\gbase_arwen non e' fatto cosi ...
-- Puo' essere un riferimento il progetto Arwen\Gandalf_tcs ma e' imcompleto
-- Riga 634: MEP update
-- Warning : set the bus delimiter = "[]" in the Synthesis option 
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.STD_LOGIC_ARITH.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

-- use WORK.SI5326.all;                 -- usato in (ARWEN) forse non serve ...
-- use WORK.cpld_interface_pkg.all;     -- usato in (ARWEN) forse non serve ...

--  This package defines supplemental types, subtypes, 
--  constants, and functions 
use WORK.top_level_desc.all;

-- All the project parameters here ...
-- removed all the generic from top vhdl
use WORK.G_PARAMETERS.all;

entity gbase_top is
    generic(
        GEN_ACCEL_SIM           : boolean := FALSE
    );
    port (
        clk_40mhz_vdsp          : in    std_logic;
        clk_si_vdspn            : in    std_logic;
        clk_si_vdspp            : in    std_logic;
        --cpld if       
        vd                      : inout std_logic_vector (31 downto 0);
        va_write                : in    std_logic;
        va_strobe               : in    std_logic;
        va_ready                : out   std_logic;
        va_control              : in    std_logic;
        va_ublaze               : in    std_logic;
        va_fifofull             : out   std_logic;
        va_fifoempty            : out   std_logic;
        va_spyread              : in    std_logic;
        --si ctrl       
        si_a_los                : in    std_logic;
        si_a_lol                : in    std_logic;
        si_a_rst                : out   std_logic;  --active low reset
        si_b_los                : in    std_logic;
        si_b_lol                : in    std_logic;
        si_b_rst                : out   std_logic;  --active low reset
        si_g_los                : in    std_logic;
        si_g_lol                : in    std_logic;
        si_g_rst                : out   std_logic;  --active low reset
        --iic if        
        iic_si_scl              : inout std_logic;
        iic_si_sda              : inout std_logic;
        iic_gp_scl              : inout std_logic_vector(1 downto 0);
        iic_gp_sda              : inout std_logic_vector(1 downto 0);
        -- aurora ports -- (basta una sola per la programmazione  dell'arwen)    
        -- (gbase_prog.ucf)
        gtpd0_n                 : in    std_logic;
        gtpd0_p                 : in    std_logic;
        rxp                     : in    std_logic;  
        rxn                     : in    std_logic;  
        txp                     : out   std_logic;  
        txn                     : out   std_logic;  
        -- slink ports      
        vud                     : out   std_logic_vector (31 downto 0);
        vlff                    : in    std_logic;
        vureset                 : out   std_logic;
        vsreset                 : out   std_logic := '1';                   
        vutest                  : out   std_logic;
        vudw                    : out   std_logic_vector (1 downto 0);
        vuctrl                  : out   std_logic;
        vuwen                   : out   std_logic;
        vuclk                   : out   std_logic;
        vldown                  : in    std_logic;
        -- dqa ports    
        dqa                     : out   std_logic_vector (7 downto 0);  -- ARWEN solo dqa(0) usata ...
        -- mezzanine ports (amc 0 only)
        amc_port_p              : in    adc_ports(adc_channels-1 downto 0);
        amc_port_n              : in    adc_ports(adc_channels-1 downto 0);
    -- arwen 1 program ports
        -- (gbase_prog.ucf)
        arwen_prog_out_p        : out   std_logic;
        arwen_prog_out_n        : out   std_logic;
        arwen_init_in_p         : in    std_logic;
        arwen_init_in_n         : in    std_logic;
        arwen_done_in_p         : in    std_logic;
        arwen_done_in_n         : in    std_logic;
        arwen_d0_p              : out   std_logic;
        arwen_d0_n              : out   std_logic;
        arwen_cclk_out_p        : out   std_logic;
        arwen_cclk_out_n        : out   std_logic;
        -- arwen 1 data ports 
        -- (omc1.ucf)
        arwen_data_a_p          : in    std_logic_vector(15 downto 0); -- il bus a e' stato splittato in due 
        arwen_data_a_n          : in    std_logic_vector(15 downto 0);    
        arwen_data_c_p          : out   std_logic_vector(15 downto 0); -- il bus a e' stato splittato in due 
        arwen_data_c_n          : out   std_logic_vector(15 downto 0);    
        arwen_data_b_p          : out   std_logic_vector(31 downto 0);    -- per ora solo il bus_b ...
        arwen_data_b_n          : out   std_logic_vector(31 downto 0);
        arwen_data_clk_p        : out   std_logic;
        arwen_data_clk_n        : out   std_logic;
        -- si_b_clk from ARWEN
        mezz_b_dr_p             : in    std_logic;
        mezz_b_dr_n             : in    std_logic;
        -- da capire ...
        -- clk_38_mezzb            : out std_logic;
        --vxs tiger ports
        vxs_a_p                 : inout std_logic_vector(7 downto 0);  --slink mux output and tcs input
        vxs_a_n                 : inout std_logic_vector(7 downto 0);
        vxs_b_p                 : out   std_logic_vector(7 downto 0);  --trigger output
        vxs_b_n                 : out   std_logic_vector(7 downto 0);
        vxs_scl                 : out   std_logic;
        vxs_sda                 : in    std_logic;
        -- trigger front panel led
        trg_led                 : out   std_logic_vector(1 downto 0);
        -- gimli ports
        tcs_lock                : in    std_logic;
        tcs_rate                : inout std_logic;
        -- tcs ports
        tcs_clk_p               : in    std_logic; --155MHz ? -Marco
        tcs_clk_n               : in    std_logic;
        tcs_data_p              : inout std_logic;
        tcs_data_n              : inout std_logic;
        -- general purpose pins
        gp                      : out   std_logic_vector(4 downto 0)  -- GANDALF solo gp(0) e gp(1) usate ...
    );

end gbase_top;



--FINE ENTITY----------------------------




architecture Behavioral of gbase_top is
---DEFINISCO TUTTI I SEGNALI E COMPONENTI
-- chipscope conponent and signals
    component gbase_top_icon
        port (
          control0 : inout std_logic_vector(35 downto 0);
          control1 : inout std_logic_vector(35 downto 0);
          control2 : inout std_logic_vector(35 downto 0);
          control3 : inout std_logic_vector(35 downto 0);
          control4 : inout std_logic_vector(35 downto 0);
          control5 : inout std_logic_vector(35 downto 0);
          control6 : inout std_logic_vector(35 downto 0);
          control7 : inout std_logic_vector(35 downto 0));
    end component;
      
    signal control0 : std_logic_vector(35 DOWNTO 0);
    signal control1 : std_logic_vector(35 DOWNTO 0);
    signal control2 : std_logic_vector(35 DOWNTO 0);
    signal control3 : std_logic_vector(35 DOWNTO 0);
    signal control4 : std_logic_vector(35 DOWNTO 0);
    signal control5 : std_logic_vector(35 DOWNTO 0);
    signal control6 : std_logic_vector(35 DOWNTO 0);
    signal control7 : std_logic_vector(35 DOWNTO 0);

    component ila_top
        port (
          control   : inout std_logic_vector(35 downto 0);
          clk       : in std_logic;
          trig0     : in std_logic_vector(15 downto 0));
      
    end component;

    signal ila_trg              : std_logic_vector(15 downto 0);
      
-- clock signals
    signal clk_40mhz_regional   : std_logic;
    signal clk_40mhz_global     : std_logic;
    signal si_g_clk             : std_logic;
    signal si_a_clk             : std_logic;
    signal si_b_clk             : std_logic;
    signal unused               : std_logic_vector(adc_channels - 1 downto 1);
--    signal readout_clk          : std_logic; -- tcs_clk 
--    signal adc_readout_clk      : std_logic; -- si_a_clk 
    signal si_a_clk_to_delay    : std_logic;
    signal si_a_clk_to_buf      : std_logic;

    signal tcs_clk              : std_logic;
--configmem signals
    signal config_mem_bram_en   : std_logic                      := '0';
    signal config_mem_bram_wen  : std_logic_vector(3 downto 0)   := x"0";
    signal config_mem_bram_addr : std_logic_vector(15 downto 0)  := (others => '0');
    signal config_mem_bram_din  : std_logic_vector(31 downto 0)  := (others => '0');
    signal config_mem_bram_dout : std_logic_vector(31 downto 0)  := (others => '0');
-- wishbone busses signals
    constant num_of_wb_bus      : integer := 5; 
    signal wb                   : wb_busses(num_of_wb_bus - 1 downto 0);
    signal wb_mosi              : wb_mosi(num_of_wb_bus - 1 downto 0);
    signal wb_miso              : wb_miso(num_of_wb_bus - 1 downto 0);
--fastregister signals ( ALL Fastregister stuff is done HERE and only HERE )
    signal fastregister_i       : std_logic_vector(255 downto 0)    := (others => '0');
    signal fr_tcs_ctrl          : std_logic_vector (2 downto 0)     := (others => '0');
    signal fr_or_self_trig      : std_logic := '0';

    alias fr_update_temps       : std_logic is fastregister_i(4);
    alias fr_do_operation       : std_logic is fastregister_i(5);
    alias fr_read_eeprom        : std_logic is fastregister_i(8);
    alias fr_write_eeprom       : std_logic is fastregister_i(9);    
    alias fr_load_si            : std_logic is fastregister_i(10);
    alias fr_set_dacs           : std_logic is fastregister_i(11);
    alias fr_set_ips            : std_logic is fastregister_i(12);  --added for arwen ips set
    alias fr_read_gta_conf      : std_logic is fastregister_i(13);
    alias fr_spy_rst            : std_logic is fastregister_i(14);  --added for spy fifo reset 
    alias fr_self_triggered     : std_logic is fastregister_i(15);
    alias fr_bor                : std_logic is fastregister_i(16);
    alias fr_bos                : std_logic is fastregister_i(17);
    alias fr_eos                : std_logic is fastregister_i(18);
    alias fr_trg                : std_logic is fastregister_i(19);
    alias fr_smux_reset         : std_logic is fastregister_i(21);  --reset for smux card (dedicated pin on transition card)
    alias fr_write_status       : std_logic is fastregister_i(22);
    alias fr_ct_bos_reset       : std_logic is fastregister_i(23);  --reset coarse time of all boards on dedicated bos
    alias fr_clear_biterr_flag  : std_logic is fastregister_i(31);

    alias fr_readouttigerready  : std_logic is fastregister_i(41);
    alias fr_triggertigerready  : std_logic is fastregister_i(42);
    alias fr_startvxslinkcal    : std_logic is fastregister_i(43);
    alias fr_init_gp            : std_logic is fastregister_i(44);
    alias fr_sec_alg_on         : std_logic is fastregister_i(45);

    alias fr_write_gta_conf     : std_logic is fastregister_i(50);  -- ex 50 moved to 46 
    alias fr_read_gta_delay     : std_logic is fastregister_i(51);  -- ex 51 moved to 47
    alias fr_read_adc_edge_info : std_logic is fastregister_i(52);  -- ex 52 moved to 48
    -- Arwen program fastregs 
    alias fr_arwen_prog          : std_logic is fastregister_i(53);  -- data_valid

    alias fr_sweep_si           : std_logic is fastregister_i(60);
    alias fr_phase_align_si     : std_logic is fastregister_i(61);
    alias fr_capture_frame      : std_logic is fastregister_i(68);
    alias fr_out_manager        : std_logic_vector(2 downto 0) is fastregister_i(72 downto 70);

    alias reset_mem             : std_logic is fastregister_i(132);          
-- status signals
    signal stat_flags           : std_logic_vector(15 downto 0) := (others => '0');
    signal err_flags            : std_logic_vector( 2 downto 0) := (others => '0');
    -- alias si_flags              : std_logic_vector(8 downto 0) is stat_flags(8 downto 0);
    -- alias tcs_lol               : std_logic is stat_flags(9);        -- not used
    -- alias tcs_rdy               : std_logic is stat_flags(10);       -- ridefinito      
    -- alias data_manager_lff      : std_logic is stat_flags(11);       -- not used    
    -- alias data_manager_not_ready: std_logic is stat_flags(12);       -- not used
    -- reset signals
    alias ev_num_err            : std_logic is stat_flags(13);          -- al dataout manager
    alias flt_err               : std_logic is stat_flags(14);          -- al dataout manager
    alias biterr                : std_logic is stat_flags(15);          -- not used
    --  alias tmc_lock          : std_logic is stat_flags(13);
    --  alias tmc_rate          : std_logic is stat_flags(14);
-- idelay out signals
    signal delay_ctrl_ready     : std_logic;

--amc_if out signals  
    signal MEP_wen         : std_logic;
    signal MEP_data        : std_logic_vector(32 downto 0); 
    signal header_data     : std_logic_vector (32 downto 0);
    signal header_wen      : std_logic;
    signal tcs_fifo_rden        : std_logic;
    signal vxs_trigger_data     : std_logic_vector(7 downto 0);
    signal any_self_trig        : std_logic;
    signal timestamp_bv         : std_logic_vector(31 downto 0);
--tcs_if signals
    signal bos                  : std_logic;                        -- begin of spill
    signal eos                  : std_logic;                        -- end of spill
    signal flt                  : std_logic;                        -- first level trigger
    signal tcs_ce               : std_logic;
    signal tcs_rdy              : std_logic;                        -- tcs decode done choosing the channels
    signal spill_no             : std_logic_vector(10 downto 0);
    signal event_no             : std_logic_vector(23 downto 0);
    signal event_type           : std_logic_vector(7 downto 0); --NEW: aggiornato a VEN. prima era (4 downto 0)
    signal tcs_fifo_full        : std_logic;
    signal tcs_fifo_empty       : std_logic;
    signal TIMESTAMP            : std_logic_vector(31 downto 0);
    
--tcs_ctrl out signals
    signal tcs_data             : std_logic;
--base_pll out signals
    signal clk_ocx_155          : std_logic;       
    signal vxs_clk_ddr          : std_logic;
    signal vxs_clk_div          : std_logic;
--gimli_if out signals
    signal vxs_request_tcs_from_tiger : std_logic;
    signal gimli_tcs_clk        : std_logic;
    signal gimli_tcs_data       : std_logic;
--si_if signals
    signal si_conf_done         : std_logic;
    signal si_not_ready         : std_logic;
    signal si_g_oop             : std_logic;             
    signal si_a_oop             : std_logic;
    signal si_b_oop             : std_logic;
    signal spy_wen_si_if        : std_logic;
    signal spy_din_si_if        : std_logic_vector(31 downto 0);
--spy fifo  
    signal spy_wen              : std_logic;
    signal spy_din              : std_logic_vector(31 downto 0);
    signal spy_rst              : std_logic;
  --stat_if signals
--arwen_prog out signals
    signal binfile_fifo_ren     : std_logic;
    signal start_reading        : std_logic;
    signal start_addr           : std_logic_vector(28 downto 0); -- := (others => '0');
    signal end_addr             : std_logic_vector(28 downto 0); -- := '0' & x"0000FFF";
    signal reset_prog           : std_logic;
--gtp_if out signals
    signal binfile_fifo_data    : std_logic_vector(33 downto 0);
    signal binfile_fifo_empty   : std_logic;
    signal binfile_fifo_valid   : std_logic;
    signal gtp_tx_data          : std_logic_vector(15 downto 0);
    signal gtp_tx_isk           : std_logic_vector(1 downto 0);
--tranceiver_main out signals
    signal gtp_reset            : std_logic := '0';
    signal gtp_clk              : std_logic;
    signal gtp_rx_data          : std_logic_vector(15 downto 0);
    signal gtp_rx_isk           : std_logic_vector(1 downto 0);
--cpld_if signals
    signal clk_120mhz           : std_logic;
    signal clk_200mhz           : std_logic;
    signal clk_40mhz            : std_logic; -- alias cfmem_clk
    signal rst_1_out            : std_logic;
    signal spy_full             : std_logic;
    signal pll_200_locked       : std_logic;
    signal idelayctl_rst        : std_logic;
--vxs signals
    signal vxs_tcs_clk_p        : std_logic;
    signal vxs_tcs_clk_n        : std_logic;
    signal vxs_tcs_data_p       : std_logic;
    signal vxs_tcs_data_n       : std_logic;
--data_out signals
    signal data_out_fifo_ready  : std_logic;
    signal data_out_fifo_full   : std_logic;
    signal spy_din_dom          : std_logic_vector(31 downto 0);
    signal spy_wen_dom          : std_logic;
    signal spy_clk              : std_logic;
    signal arwen_clk            : std_logic;
    signal arwen_wen            : std_logic;    
    signal arwen_ff             : std_logic_vector( 3 downto 0);    
    signal arwen_data           : std_logic_vector(31 downto 0);
    signal arwen_add            : std_logic_vector( 3 downto 0);
    signal arwen_rdy            : std_logic;
    signal arwen_rst            : std_logic;
    signal sdr_link_data_in     : std_logic_vector(32 downto 0);
    signal sdr_link_data_valid  : std_logic;
    signal sdr_link_data_clk    : std_logic;
--  signal sdr_link_link_clk    : std_logic; -- non usato, forse utile ...
    signal sdr_link_rst         : std_logic;
    signal sdr_link_lff         : std_logic;
    signal slink_ud             : std_logic_vector (31 downto 0);
    signal slink_ureset         : std_logic;
    signal slink_utest          : std_logic;
    signal slink_udw            : std_logic_vector (1 downto 0);
    signal slink_uctl           : std_logic;
    signal slink_uwen           : std_logic;
    signal slink_uclk           : std_logic;
--slink out signals
    signal slink_lff            : std_logic;
    signal slink_ldown          : std_logic;
-- other signals
    signal si_has_lock_and_signal : std_logic;
    signal si_rst               : std_logic;


---------------------------------------------------------------------------begin architecture
begin

---------------------------------------------------------------------------------------------------------
-- Chipscope icon
--se USE_CHIPSCOPE_ICON = 1 allora genero un componente gbase_top_icon
Inst_chipscope_icon : if USE_CHIPSCOPE_ICON generate
    Inst_icon : gbase_top_icon
	 --MAPPING TRA I SEGNALI DI CONTROLLO
    port map (
        control0    => control0,        -- to spy_fifo_rd_ila
        control1    => control1,        -- to tcs_ctrl_ila
        control2    => control2,        -- to tranceiver_ila
        control3    => control3,        -- to arwen_s_prog
        control4    => control4,        -- to wb_to_ram
        control5    => control5,        -- to gtp_if
        control6    => control6,        -- to si_load
        control7    => control7         -- on used fastregister
    );
    end generate;

Inst_chipscope_ila : if USE_CHIPSCOPE_ILA_TOP generate

    inst_ila : ila_top
    port map (
        control     => control7,
        clk         => clk_40mhz,
        trig0       => ila_trg
    );

        ila_trg(0)   <= fastregister_i(132); -- res_mem_fpga     
        ila_trg(1)   <= fastregister_i(133); -- en_prog_arwen
        ila_trg(2)   <= fr_arwen_prog;      
        ila_trg(3)   <= fr_load_si;           
        ila_trg(4)   <= fr_set_dacs;          
        ila_trg(5)   <= fr_set_ips;           
        ila_trg(6)   <= fr_read_gta_conf;     
        ila_trg(7)   <= fr_spy_rst;           
        ila_trg(8)   <= fr_write_status;    
        ila_trg(9)   <= fr_bor;               
        ila_trg(10)  <= fr_bos;               
        ila_trg(11)  <= fr_eos;               
        ila_trg(12)  <= fr_trg;               
        ila_trg(13)  <= fr_out_manager(0);        
        ila_trg(14)  <= fr_out_manager(1);      
        ila_trg(15)  <= fr_out_manager(2);

end generate;


---------------------------------------------------------------------------------------------------------
-- clock buffer
si_g_clock : ibufds -- Alex: era ibufds
    generic map (
        diff_term       => true,  -- differential termination (virtex-4/5, spartan-3e/3a)
        iostandard      => "LVDS_25")
    port map (
        i               => clk_si_vdspp,
        ib              => clk_si_vdspn,
        o               => si_g_clk
    );

    --
    -- si_a_clock spostato in amc_if
    --
    
si_b_clock : ibufgds
    generic map (
        diff_term       => true,  -- differential termination (virtex-4/5, spartan-3e/3a
        iostandard      => "LVDS_25")
    port map (
        i               => mezz_b_dr_p,        
        ib              => mezz_b_dr_n,        
        o               => si_b_clk
    );

    -- since the connected pin is no global clock input    
clk_40mhz_bufr_inst : bufr       
    generic map (
        bufr_divide => "BYPASS",
        sim_device  => "VIRTEX5")
    port map (
        o   => clk_40mhz_regional,        -- Clock buffer output
        ce  => '1',                       -- Clock enable input
        clr => '0',                       -- Clock buffer reset input
        i   => clk_40mhz_vdsp             -- Clock buffer input
    );

clk_40mhz_bufg_inst : bufg
    port map (
        O => clk_40mhz_global,            -- Clock buffer output
        I => clk_40mhz_regional           -- Clock buffer input
    );
---------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------
-- Arwen differential out buffer da vedere con Matteo ...

arwen_data_out : for x in 0 to 31 generate

    data_out_buffer : OBUFDS
    generic map (
        IOSTANDARD => "LVDS_25"
        )
    port map
    (
        I  => arwen_data(x),
        O  => arwen_data_b_p(x),
        OB => arwen_data_b_n(x)
    );

end generate arwen_data_out;

data_wen_buffer : OBUFDS
    generic map (
        IOSTANDARD => "LVDS_25"
        )
    port map
    (
        I  => arwen_wen,
        O  => arwen_data_c_p(0),
        OB => arwen_data_c_n(0)
    );

data_clk_buffer : OBUFDS
    generic map (
        IOSTANDARD      => "LVDS_25"
        )
    port map
    (
        I               => arwen_clk,
        O               => arwen_data_clk_p,
        OB              => arwen_data_clk_n
    );

arwen_fifo_full : for x in 0 to 3 generate 
    data_ff_buffer : IBUFDS
        generic map (
            DIFF_TERM   => true,  -- differential termination (virtex-4/5, spartan-3e/3a
            IOSTANDARD  => "LVDS_25")
        port map (
            I           => arwen_data_a_p(x),        
            IB          => arwen_data_a_n(x),        
            O           => arwen_ff(x)
        );
end generate;

arwen_address : for x in 0 to 3 generate 
    arwen_add_buffer : OBUFDS
        generic map (
            IOSTANDARD      => "LVDS_25"
            )
        port map (
            I  => arwen_add(x),
            O  => arwen_data_c_p(1 + x),        
            OB => arwen_data_c_n(1 + x)        
        );
end generate arwen_address;
    
data_ff_buffer : IBUFDS
    generic map (
        DIFF_TERM       => true,  -- differential termination (virtex-4/5, spartan-3e/3a
        IOSTANDARD      => "LVDS_25")
    port map (
        I               => arwen_data_a_p(8),        
        IB              => arwen_data_a_n(8),        
        O               => arwen_rdy
    );

arwen_rst_buffer : OBUFDS
    generic map (
        IOSTANDARD      => "LVDS_25"
        )
    port map (
        I  => arwen_rst,
        O  => arwen_data_c_p(15),        
        OB => arwen_data_c_n(15)        
    );

---------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------
-- idelay

idelayctl_rst <= not pll_200_locked;

idelctl : IDELAYCTRL
    port map (
        RDY    => delay_ctrl_ready,
        REFCLK => clk_200mhz,
        RST    => idelayctl_rst
    );
---------------------------------------------------------------------------------------------------------
              
---------------------------------------------------------------------------------------------------------
-- stat interface
stat_if_1 : entity work.stat_if
    port map (
        clk           => clk_40mhz,
        stat_flags    => stat_flags,
        wr_stats      => fr_write_status,
        wr_sys_mon    => fr_update_temps,
        cfmem_wb_cyc  => wb(3).cyc,
        cfmem_wb_stb  => wb(3).stb,
        cfmem_wb_we   => wb(3).we,
        cfmem_wb_ack  => wb(3).ack,
        cfmem_wb_addr => wb(3).adr,
        cfmem_wb_din  => wb(3).dat_o,
        cfmem_wb_dout => wb(3).dat_i
    );
---------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------
-- gp interface
gp_if : entity work.gp_if
    generic map (
        sim => false)
    port map (
        clk                   => clk_40mhz,
        scl                   => iic_gp_scl,
        sda                   => iic_gp_sda,
        rd_temps              => fr_update_temps,
        rd_stats              => fr_write_status,
        set_dacs              => fr_set_dacs,
        set_IPs               => fr_set_ips,
        write_eeprom_to_cfmem => fr_read_eeprom,
        write_cfmem_to_eeprom => fr_write_eeprom,
        init_gp               => fr_init_gp,
        cfmem_wb_cyc          => wb(2).cyc,
        cfmem_wb_stb          => wb(2).stb,
        cfmem_wb_we           => wb(2).we,
        cfmem_wb_ack          => wb(2).ack,
        cfmem_wb_addr         => wb(2).adr,
        cfmem_wb_din          => wb(2).dat_o,
        cfmem_wb_dout         => wb(2).dat_i
    );
---------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------
-- AMC interface
-- Questo dovrebbe instanziare solo la scheda up ed eliminare automaticamente gli input non
-- utilizzati ...


inst_mcs_amcs : if bs_mcs_up = "AMC" or bs_mcs_dn = "AMC" generate
begin
-- only write data to the fifo if it is not full and when we have an endpoint for the data
    data_out_fifo_ready <= '1' when (fr_out_manager/="000")  else '0'; --fr_out_manager fissa il tipo di link in uscita (VXS,ARWEN, ecc)
    inst_amc_if_MEP : entity work.amc_if_8ch_MEP                                            --HO CONNESSO l'amc per il MEP                              
    port map(
        port_p                          => amc_port_p,
        port_n                          => amc_port_n,
        adc_readout_clk                 => si_a_clk,
        MEP_data                        => MEP_data,
        MEP_wen                         => MEP_wen,
        --header_data                     => header_data,
        header_wen                      => header_wen,
        bits                            => open,
        ready                           => data_out_fifo_ready,
        lff                             => data_out_fifo_full,
        data_clk                        => tcs_clk,
        vxs_trigger_data                => vxs_trigger_data,
        vxs_clk_div                     => vxs_clk_div,
        vxs_clk_ddr                     => vxs_clk_ddr,
        vxs_fr_start_cal                => fr_startvxslinkcal,
        clk_cfmem                       => clk_40mhz,
        clk_200mhz_in                   => clk_200mhz,
        trg                             => flt,
        bos                             => bos,
        res_ct_bos                      => fr_ct_bos_reset,
        event_no                        => event_no,
        spill_no                        => spill_no,
        event_type                      => event_type,
        timestamp                       => timestamp,
        timestamp_bv                    => timestamp_bv,                            
        tcs_fifo_empty                  => tcs_fifo_empty,      -- era evt_f_empty
        tcs_fifo_rden                   => tcs_fifo_rden,       -- era evt_f_rden
        load_conf_data                  => fr_read_gta_conf,
        readback_data                   => fr_write_gta_conf,
        readback_edges                  => fr_read_adc_edge_info,
        del_change_fr                   => fr_read_gta_delay,
        reset                           => si_not_ready,
        dbgframe_ff_empty               => open,
        dbgevt_ff_empty                 => open,
        stat_flags                      => stat_flags,
        err_flags                       => err_flags,
        config_mem_bram_en              => open,
        config_mem_bram_wen             => open,
        config_mem_bram_addr            => open,
        config_mem_bram_data_out        => open,
        config_mem_bram_data_in         => (others => '0'),
        cfmem_wb_stb                    => wb(0).stb,
        cfmem_wb_addr                   => wb(0).adr,
        cfmem_wb_dout                   => wb(0).dat_i,
        cfmem_wb_din                    => wb(0).dat_o,
        cfmem_wb_ack                    => wb(0).ack,
        cfmem_wb_cyc                    => wb(0).cyc,
        fr_sec_alg_on                   => fr_sec_alg_on,
        del_latch_reset_fr              => fr_clear_biterr_flag,
        any_self_trig                   => any_self_trig,
        any_fifo_full                   => open                     -- non usato

    );
end generate;
---------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------
-- tiger trigger
--
inst_t_trg : entity work.base_pll
    port map (
        si_g_clk                => si_g_clk,        
        vxs_trigger_data        => vxs_trigger_data,
        clk_ocx_155             => clk_ocx_155,     
        vxs_b_p                 => vxs_b_p,         
        vxs_b_n                 => vxs_b_n,         
        vxs_clk_ddr             => vxs_clk_ddr,     
        vxs_clk_div             => vxs_clk_div     
    );


gp(4 downto 0) <= (0 => '0', 1 => flt, 2 => si_rst, others => 'Z');

-- vanno verso la MEM FPGA ...
-- Per programmare l'ARWEN via SelectMap e' utilizzato il FastRegister(133) : dqa(1)
-- Per resettare la MEM e tutta la parte di programmazione dell'ARWEN e' utilizzato 
-- il FastRegister(132) : dqa(0)
-- Gli altri daq non sono utilizzati per ora ...
dqa <= FastRegister_i(139 downto 132);


-- Keep Si Clocks running, active low reset
si_a_rst <= '1';
si_b_rst <= '1';
si_g_rst <= '1';

-- status flags 
stat_flags(8 downto 0) <= si_a_oop & si_a_los & si_a_lol & si_b_oop & si_b_los & si_b_lol & si_g_oop & si_g_los & si_g_lol;
stat_flags(9)  <= not tcs_lock; --da mettere nel MEP
stat_flags(10) <= tcs_rdy;
stat_flags(11) <= data_out_fifo_full;   -- spostato da amc_if.vhd
stat_flags(12) <= data_out_fifo_ready;  -- spostato da amc_if.vhd
stat_flags(15 downto 13) <= err_flags;  -- aggiunti su amc_is.vhd
---------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------
-- data out manager
data_out_manager : entity work.data_out_manager_MEP
    port map (
        fr_out_manager              => fr_out_manager,
        flt_err                     => flt_err,
        ev_num_err                  => ev_num_err,
        slink_clk                   => clk_40mhz,
        data_clk                    => tcs_clk,
        data_in                     => MEP_data,
        data_wen                    => MEP_wen,
        --header_fifo_din             => MEP_data,
        header_fifo_wr_en           => header_wen,
        fifo_prog_full              => data_out_fifo_full,
        spy_data                    => spy_din_dom,
        spy_wen                     => spy_wen_dom,
        spy_clk                     => spy_clk,
        spy_full                    => spy_full,
        arwen_data                  => arwen_data,   
        arwen_wen                   => arwen_wen,    
        arwen_ff                    => arwen_ff,    
        arwen_clk                   => arwen_clk, 
        arwen_add                   => arwen_add,
        arwen_rdy                   => arwen_rdy,
        arwen_rst                   => arwen_rst,
        vxs_data                    => sdr_link_data_in,
        vxs_data_valid              => sdr_link_data_valid,
        vxs_data_clk                => sdr_link_data_clk,
        vxs_rst                     => sdr_link_rst,
        vxs_lff                     => sdr_link_lff,
        UD                          => slink_ud,
        LFF                         => slink_lff,
        URESET                      => slink_ureset,
        UTEST                       => slink_utest,
        UDW                         => slink_udw,
        UCTRL                       => slink_uctl,
        UWEN                        => slink_uwen,
        UCLK                        => slink_uclk,
        LDOWN                       => slink_ldown
    );           
---------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------
-- vxs interface
vxs_if : entity work.vxs_interface
    port map (
        vxs_a_p                    => vxs_a_p,
        vxs_a_n                    => vxs_a_n,
        vxs_scl                    => vxs_scl,
        vxs_sda                    => vxs_sda,
        vxs_tcs_clk_p              => vxs_tcs_clk_p,
        vxs_tcs_clk_n              => vxs_tcs_clk_n,
        vxs_tcs_data_p             => vxs_tcs_data_p,
        vxs_tcs_data_n             => vxs_tcs_data_n,
        vxs_request_tcs_from_tiger => vxs_request_tcs_from_tiger,
        sdr_link_data_in           => sdr_link_data_in,
        sdr_link_data_valid        => sdr_link_data_valid,
        sdr_link_data_clk          => sdr_link_data_clk,
        sdr_link_link_clk          => gimli_tcs_clk,
        sdr_link_rst               => sdr_link_rst,
        sdr_link_lff               => sdr_link_lff
    );
---------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------
-- slink interface
slink_if : entity work.slink_if
    port map (
        VUD                         => VUD,
        VLFF                        => VLFF,
        VURESET                     => VURESET,
        VSRESET                     => VSRESET,
        VUTEST                      => VUTEST,
        VUDW                        => VUDW,
        VUCTRL                      => VUCTRL,
        VUWEN                       => VUWEN,
        VUCLK                       => VUCLK,
        VLDOWN                      => VLDOWN,
        UD                          => slink_ud,
        LFF                         => slink_lff,
        URESET                      => slink_ureset,
        UTEST                       => slink_utest,
        UDW                         => slink_udw,
        UCTRL                       => slink_uctl,
        UWEN                        => slink_uwen,
        UCLK                        => slink_uclk,
        LDOWN                       => slink_ldown
    );
---------------------------------------------------------------------------------------------------------
            
---------------------------------------------------------------------------------------------------------
-- cpld interface
cpld_if : entity work.cpld_if
    generic map(
        gen_accel_sim             => GEN_ACCEL_SIM
    )
    port map(
        --control                   => control0,
        -- this signals are directly connected to io pins
        d                         => vd,                  -- data bus to/from cpld
        f_write                   => va_write,            -- flag from cpld
        f_strobe                  => va_strobe,           -- flag from cpld
        --f_ready                 => va_ready,            -- flag to cpld
        f_ready                   => va_ready,            -- flag to cpld
        f_control                 => va_control,          -- flag from cpld
        f_ublaze                  => va_ublaze,           -- flag from cpld
        f_fifofull                => va_fifofull,         -- flag to cpld
        f_fifoempty               => va_fifoempty,        -- flag to cpld
        f_reset                   => '0',                 -- reset from cpld
        clk_40mhz_vdsp            => clk_40mhz_global,    -- 40 mhz system clock input (input pin)
        pll_200_locked            => pll_200_locked,

        -- connect this signals to your logic
        clk_40mhz_out             => clk_40mhz,           -- 40 mhz clock output
        nclk_40mhz_out            => open,                -- inverted 40 mhz clock output
        clk_120mhz_out            => clk_120mhz,          -- 120 mhz clock output
        clk_200mhz_out            => clk_200mhz,          -- 200 mhz clock output
        slink_init_done           => '1',                 -- startup_sequence finished input
        si_init_done              => si_conf_done,
        gp_init_done              => '1',
        si_flags                  => stat_flags(8 downto 0),     
        rst_startup_1_out         => rst_1_out,           -- this reset is released 8 cycles after pll lock -- era spy_rst
        rst_startup_2_out         => open,                -- this reset is released 8 cycles after rst_startup_1
        rst_startup_3_out         => open,                -- this reset is released when slink_init_done && si_init_done
        -- spyfifo        
        spy_din                   => spy_din,
        spy_clk                   => spy_clk,
        spy_wr                    => spy_wen,
        spy_rst                   => spy_rst,
        spy_full                  => open,
        spy_almost_full           => spy_full,
        -- config memory block ram
        config_mem_bram_rst       => '0',
        config_mem_bram_clk       => clk_40mhz,
        config_mem_bram_en        => config_mem_bram_en,
        config_mem_bram_wen       => config_mem_bram_wen,
        config_mem_bram_addr      => config_mem_bram_addr,
        config_mem_bram_din       => config_mem_bram_din,
        config_mem_bram_dout      => config_mem_bram_dout,
        fastregister              => fastregister_i
    );

spy_din <= spy_din_si_if when spy_wen_si_if = '1' else spy_din_dom;
spy_wen <= spy_wen_si_if or spy_wen_dom;
spy_rst <= rst_1_out or fr_spy_rst;        
        
---------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------
-- tcs gimli interface
si_has_lock_and_signal <= not (si_g_los or si_g_lol);

yessim: if GEN_ACCEL_SIM generate
    si_not_ready <= '0';
end generate;


notsim: if not GEN_ACCEL_SIM generate
    si_not_ready <= not si_conf_done;
end generate;


si_rst <= not delay_ctrl_ready or rst_1_out; -- era spy_rst

gimli_if : entity work.gimli_if
    generic map (
        gimli_type                  => bs_gimli_type)
    port map (
        tmc_lock                    => tcs_lock,
        tmc_rate                    => tcs_rate,
        tcs_clk_p                   => tcs_clk_p,
        tcs_clk_n                   => tcs_clk_n,
        tcs_data_p                  => tcs_data_p,
        tcs_data_n                  => tcs_data_n,
        vxs_tcs_clk_p               => vxs_tcs_clk_p,
        vxs_tcs_clk_n               => vxs_tcs_clk_n,
        vxs_tcs_data_p              => vxs_tcs_data_p,
        vxs_tcs_data_n              => vxs_tcs_data_n,
        vxs_request_tcs_from_tiger  => vxs_request_tcs_from_tiger,
        si_has_lock_and_signal      => si_has_lock_and_signal,
        gimli_tcs_clk               => gimli_tcs_clk,
        gimli_tcs_data              => gimli_tcs_data
    );

-- tcs controller if we have a ocx gimli
check_ocx : if (bs_gimli_type = "OCX") generate     -- bs_gimli_type = "OCX"
    tcs_clk         <= clk_ocx_155;
    -- si_to_sweep     <= "110";                    -- non usato
    fr_tcs_ctrl     <= fr_bor & fr_bos & fr_eos;
    fr_or_self_trig <= (any_self_trig and fr_self_triggered) or fr_trg or gimli_tcs_data;

    --easy_tcs_ctrl : entity work.easy_tcs_ctrl --Codificava il trigger, serve solo in simulazione
        --generic map (
           -- gen_accel_sim           => GEN_ACCEL_SIM
          --  ) 
       -- port map (
            --control                 => control1,      
           -- ext_trigger             => fr_or_self_trig,
          --  fr_tcs_ctrl             => fr_tcs_ctrl,
           -- clk                     => clk_ocx_155,
           -- tcs_data                => tcs_data,
           -- clk38en                 => tcs_ce,   
           -- fr_internal_trig        => "00000");
end generate; -- bs_gimli_type = "OCX"
  
check_no_ocx: if (bs_gimli_type /= "OCX") generate  -- bs_gimli_type != "OCX"
    tcs_clk     <= gimli_tcs_clk;
    tcs_data    <= gimli_tcs_data;
    -- si_to_sweep <= "111";                        -- non usato
end generate; -- bs_gimli_type != "OCX"
---------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------
--tcs interface (MEP)
tcs_if : entity work.tcs_if_MEP
    port map (
        tcs_clk             => tcs_clk,
        tcs_data            => tcs_data,
        fr_bos              => fr_bos,
        fr_eos              => fr_eos,
        fr_trg              => fr_trg,
        readout_rdy         => data_out_fifo_ready,
        synced              => tcs_rdy,
        clk38en             => tcs_ce,
        bos                 => bos,
        eos                 => eos,
        flt                 => flt,
        event_no            => event_no,
        spill_no            => spill_no,
        event_type          => event_type,
        fifo_empty          => tcs_fifo_empty, -- era evt_f_empty
        fifo_full           => tcs_fifo_full,  -- era evt_f_full
        fifo_rdclk          => tcs_clk,
        fifo_rden           => tcs_fifo_rden,
        timestamp           => timestamp,
        timestamp_bv        => timestamp_bv,
		timestamp_rden      => tcs_fifo_rden
    );
---------------------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------------------
-- tcs led control
inst_trigger_led : entity work.trigger_led 
    port map(
        clk         => clk_40mhz,
        green       => flt,
        orange      => bos,
        red         => eos,
        trigger_led => trg_led
    );
---------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------
-- SI interface
inst_si_if : entity work.si_if
    generic map(
        sim                 => GEN_ACCEL_SIM)
    port map ( 
        --control             => control6,   
        clk                 => clk_40mhz,      
        cfmem_clk           => clk_40mhz,      
        spy_clk             => spy_clk,      
        tcs_clk             => tcs_clk,
        tcs_ce              => tcs_ce,
        tcs_rdy             => tcs_rdy,
        si_g_clk            => si_g_clk,
        si_a_clk            => si_a_clk,
        si_b_clk            => si_b_clk,
        rst                 => si_rst,
        fr_load_si          => fr_load_si,
        fr_sweep_si         => fr_sweep_si,
        fr_phase_align_si   => fr_phase_align_si,
        done                => si_conf_done,
        si_g_oop            => si_g_oop,
        si_a_oop            => si_a_oop,
        si_b_oop            => si_b_oop,
        sda                 => iic_si_sda,
        scl                 => iic_si_scl,
        cfmem_wb_cyc        => wb(1).cyc,
        cfmem_wb_stb        => wb(1).stb,
        cfmem_wb_we         => wb(1).we,
        cfmem_wb_ack        => wb(1).ack,
        cfmem_wb_addr       => wb(1).adr,
        cfmem_wb_din        => wb(1).dat_o,
        cfmem_wb_dout       => wb(1).dat_i,
        spy_wr              => spy_wen_si_if,
        spy_do              => spy_din_si_if,
        spy_full            => spy_full
    );
---------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------
-- wb config mem if
cfmem_wb : entity work.wb_to_ram
    generic map (
        data_width          => 32,
        addr_width          => 10,
        n_port              => num_of_wb_bus)
    port map (
        control             => control4,
        mem_clka            => open,
        mem_wea             => config_mem_bram_wen,
        mem_addra           => config_mem_bram_addr,
        mem_dina            => config_mem_bram_din,
        mem_douta           => config_mem_bram_dout,
        wb_clk              => clk_40mhz,
        wb_rst              => rst_1_out,
        wb_mosi             => wb_mosi,
        wb_miso             => wb_miso
    );

-- union of records bus
wb_concat:
for i in 0 to num_of_wb_bus - 1 generate
    wb_miso(i).cyc      <= wb(i).cyc; 
    wb_miso(i).stb      <= wb(i).stb; 
    wb_miso(i).we       <= wb(i).we; 
    wb_miso(i).adr      <= wb(i).adr; 
    wb_miso(i).dat_i    <= wb(i).dat_i; 
    wb(i).ack           <= wb_mosi(i).ack; 
    wb(i).dat_o         <= wb_mosi(i).dat_o; 
end generate;
---------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------
-- gtp_if
gtp_if_1 : entity work.gtp_if
    port map (
        control                => control5,
        reset                  => reset_prog,
        start_reading_in       => start_reading,
        start_addr_in          => start_addr,
        end_addr_in            => end_addr,
        binfile_fifo_rd_clk_in => tcs_clk,
        binfile_fifo_data_out  => binfile_fifo_data,
        binfile_fifo_empty_out => binfile_fifo_empty,
        binfile_fifo_valid_out => binfile_fifo_valid,
        binfile_fifo_ren_in    => binfile_fifo_ren,
        gtp_clk_in             => gtp_clk,
        tx_data_out            => gtp_tx_data,
        rx_data_in             => gtp_rx_data,
        tx_isk_out             => gtp_tx_isk,
        rx_isk_in              => gtp_rx_isk
    );
---------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------
-- arwen_prog      

reset_prog <= rst_1_out or reset_mem;

arwen_prog_1 : entity work.arwen_s_prog
    port map (
        control             => control3,
        clk                 => tcs_clk,
        rst                 => reset_prog,
    --  fastreg_card_select => fastreg_card_select,
        fastreg_prog        => fr_arwen_prog,
        start_reading       => start_reading,
        start_addr          => start_addr,
        end_addr            => end_addr,
        binfile_fifo_data   => binfile_fifo_data,
        binfile_fifo_empty  => binfile_fifo_empty,
        binfile_fifo_valid  => binfile_fifo_valid,
        binfile_fifo_ren    => binfile_fifo_ren,
        wb_cyc              => wb(4).cyc,
        wb_stb              => wb(4).stb,
        wb_we               => wb(4).we,
        wb_adr              => wb(4).adr,
        wb_dat_o            => wb(4).dat_i,
        wb_dat_i            => wb(4).dat_o,
        wb_ack              => wb(4).ack,
        ARWEN_PROG_P        => arwen_prog_out_p,
        ARWEN_PROG_N        => arwen_prog_out_n,
        ARWEN_INIT_P        => arwen_init_in_p,
        ARWEN_INIT_N        => arwen_init_in_n,
        ARWEN_DONE_P        => arwen_done_in_p,
        ARWEN_DONE_N        => arwen_done_in_n,
        ARWEN_D0_P          => arwen_d0_p,      
        ARWEN_D0_N          => arwen_d0_n,      
        ARWEN_CCLK_P        => arwen_cclk_out_p,
        ARWEN_CCLK_N        => arwen_cclk_out_n
    );
---------------------------------------------------------------------------------------------------------

---------------------------------------------------------------------------------------------------------
-- tranceiver
tranceiver_main_1 : entity work.tranceiver_main
    port map (
        -- control             => control2,
        reset_in            => gtp_reset,
        clk40_in            => clk_40mhz,
        gtp_clk_out         => gtp_clk,
        tx_data_in          => gtp_tx_data,
        rx_data_out         => gtp_rx_data,
        tx_isk_in           => gtp_tx_isk,
        rx_isk_out          => gtp_rx_isk,
        REFCLK_P            => gtpd0_p,
        REFCLK_N            => gtpd0_n,
        RXN                 => rxn,
        RXP                 => rxp,
        TXN                 => txn,
        TXP                 => txp
    );
---------------------------------------------------------------------------------------------------------

end Behavioral;

