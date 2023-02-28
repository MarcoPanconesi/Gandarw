----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:     15:05:38 04/27/2012 
-- Design Name:     
-- Module Name:     amc_if_8ch - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description:     Front end adc if
--
-- Dependencies:   
--
-- Revision: 
-- Revision 0.01    File Created
-- More Comments:   Modificata 18/11/2021 da Alex e Pablo per normal sampling mode
--                  Modificata 21/12/2021 da Alex per clock separati per ogni canale
--                  Modificata 14/01/2022 da Alex, clock separati fino al ring buffer
--
----------------------------------------------------------------------------------

library ieee;
library unisim;
library unimacro;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.std_logic_unsigned.all;
USE unisim.vcomponents.all;
USE unimacro.vcomponents.all;
USE work.top_level_desc.all;
USE work.g_parameters.all;
USE work.ddr_interface_pkg.all;

entity amc_if_8ch_MEP is
    generic(sim : integer := 0);
    port (
        port_p                   : in  adc_ports(adc_channels - 1 downto 0);
        port_n                   : in  adc_ports(adc_channels - 1 downto 0);
        adc_readout_clk          : out std_logic;
        bits                     : out std_logic_vector (511 downto 0);
        MEP_data               : out std_logic_vector (32 downto 0);
        MEP_wen                : out std_logic;
        header_wen             : out std_logic;
        ready                    : in  std_logic;
        lff                      : in  std_logic;
        data_clk                 : in  std_logic;
        trg                      : in  std_logic;
        bos                      : in  std_logic;
        res_ct_bos               : in  std_logic;
        vxs_trigger_data         : out std_logic_vector(7 downto 0);
        vxs_clk_div              : in  std_logic;
        vxs_clk_ddr              : in  std_logic;
        vxs_fr_start_cal         : in  std_logic;
        --clk_120mhz_in          : in  std_logic;
        clk_200mhz_in            : in  std_logic;
        clk_cfmem                : in  std_logic;
        event_no                 : in  std_logic_vector (23 downto 0);
        spill_no                 : in  std_logic_vector (10 downto 0);
        event_type               : in  std_logic_vector (7 downto 0);  --è L0 trigger word --aggiornato alla documentazione: prima era 5 bit   -Marco
        timestamp                : in std_logic_vector (31 downto 0);
        timestamp_bv             : out std_logic_vector (31 downto 0); --ATTENZIONE: è timestamp_base
        tcs_fifo_empty           : in  std_logic;
        tcs_fifo_rden            : out std_logic;
        load_conf_data           : in  std_logic;
        readback_data            : in  std_logic;
        readback_edges           : in  std_logic;
        del_change_fr            : in  std_logic;
        reset                    : in  std_logic;
-------------------------------------------------------------------------------     
--debug
        dbgframe_ff_empty        : out std_logic_vector (adc_channels - 1 downto 0);
        dbgevt_ff_empty          : out std_logic_vector (23 downto 0) := (others => '0');
-------------------------------------------------------------------------------
        stat_flags               : in  std_logic_vector(15 downto 0);
        err_flags                : out std_logic_vector(2 downto 0);
        config_mem_bram_en       : out std_logic                     := '0';
        config_mem_bram_wen      : out std_logic_vector(3 downto 0)  := (others => '0');
        config_mem_bram_addr     : out std_logic_vector(15 downto 0) := (others => '0');
        config_mem_bram_data_out : out std_logic_vector(31 downto 0) := (others => 'Z');
        config_mem_bram_data_in  : in  std_logic_vector(31 downto 0) := (others => 'Z');
        cfmem_wb_cyc             : out std_logic;
        cfmem_wb_stb             : out std_logic;
        cfmem_wb_we              : out std_logic_vector(3 downto 0);
        cfmem_wb_ack             : in  std_logic;
        cfmem_wb_addr            : out std_logic_vector (9 downto 0);
        cfmem_wb_din             : in  std_logic_vector (31 downto 0);
        cfmem_wb_dout            : out std_logic_vector (31 downto 0);
        fr_sec_alg_on            : in  std_logic;
        del_latch_reset_fr       : in  std_logic;
        any_fifo_full            : out std_logic;
        any_self_trig            : out std_logic
        );
end amc_if_8ch_MEP;

architecture behavioral of amc_if_8ch_MEP is
---amc input signals---
    signal data_del             : adc_ports(adc_channels - 1 downto 0);
    signal data_i               : adc_ports(adc_channels - 1 downto 0);
    signal data_consist_i       : adc_ports(adc_channels - 1 downto 0)                := (others => (others => '0'));
    signal data_i_ddr           : adc_ddrports(adc_channels - 1 downto 0);    
    signal data_i_ddr_fifo      : adc_ddrports(adc_channels - 1 downto 0);    
    signal data_consist_i_ddr   : adc_ddrports(adc_channels - 1 downto 0)             := (others => (others => '0'));
    signal data_latch_i         : adc_ports(adc_channels - 1 downto 0)                := (others => (others => '0'));
    signal data_latch           : adc_ports(adc_channels - 1 downto 0)                := (others => (others => '0'));
    signal data_latch_rst       : adc_ports(adc_channels - 1 downto 0)                := (others => (others => '0'));
    signal data_latch_rst_cnt   : integer range 0 to 4095                             := 0;
    signal data_ddr_inv         : adc_ddrports(adc_channels - 1 downto 0);
    signal data_i_pl1           : adc_ddrports(adc_channels - 1 downto 0);
    signal frame_fifo_data             : adc_ddrports(adc_channels - 1 downto 0);            --2*12bit
    signal frame_fifo_empty           : std_logic_vector(adc_channels  - 1 downto 0);       -- era 15
    signal frame_data           : adc_ddrports(adc_channels - 1 downto 0);
    signal frame_pl1            : adc_ddrports(adc_channels - 1 downto 0);
    signal frame_fifo_rden            : std_logic_vector(adc_channels - 1 downto 0);                         -- era 15
    signal self_trig_vec        : std_logic_vector(7 downto 0);

    subtype buf_data is std_logic_vector(11 downto 0);
    type    buf_fifo is array (0 to 1) of buf_data;
    
    type    buf_din is array (integer range<>) of buf_fifo;
    signal  rbuf_din : buf_din(adc_channels - 1 downto 0);

-- signal added for 8ch version ...
    signal adc_clk              : std_logic;
    signal si_a_clk_to_dly      : std_logic_vector(adc_channels - 1 downto 0);
    signal si_a_clk_to_buf      : std_logic_vector(adc_channels - 1 downto 0);
    signal si_a_clk             : std_logic_vector(adc_channels - 1 downto 0);
    signal wr_fifo_pl1          : std_logic_vector(adc_channels - 1 downto 0)            :=  (others => '0');

-- ana_ilm or ana_nrm signals
    -- in funzione di active_channels ...
    signal rd_frame_ff              : std_logic_vector(active_channels - 1 downto 0)  := (others => '0');
    signal event_fifo_data          : data_ports(active_channels - 1 downto 0);                               -- 31 bit
    signal event_fifo_empty         : std_logic_vector(active_channels - 1 downto 0)  := (others => '0');
    signal event_fifos_full         : std_logic_vector(active_channels - 1 downto 0);
    signal buffer_fifos_full        : std_logic_vector(active_channels - 1 downto 0);
    signal event_fifo_rden          : std_logic_vector(active_channels - 1 downto 0)  := (others => '0');

    signal buffer_fifo_data          : data_ports(active_channels - 1 downto 0);                               -- 31 bit
    signal buffer_fifo_empty         : std_logic_vector(active_channels - 1 downto 0)  := (others => '0');
    signal buffer_fifo_rden          : std_logic_vector(active_channels - 1 downto 0)  := (others => '0');


-- variable delay needs this:
    signal del_ce                   : adc_ports(adc_channels - 1 downto 0)                := (others => (others => '0'));
    signal del_inc                  : adc_ports(adc_channels - 1 downto 0)                := (others => (others => '0'));
    signal del_settings             : adc_delay_settings(13 downto 0)                     := (others => (others => '0'));
    signal del_load_cnt             : integer range 0 to 31                               := 0;
    signal del_action               : std_logic                                           := '0';
    signal del_action_sr            : std_logic_vector(1 downto 0)                        := (others => '0');
    signal del_latch_reset_sr       : std_logic_vector(1 downto 0)                        := (others => '0');

---readout logic---
    signal flt_sr      : std_logic_vector(1 downto 0)                               := (others => '0');
    signal flt_err     : std_logic                                                  := '0';
    signal ev_num_err  : std_logic                                                  := '0';
    signal trigger_i   : std_logic                                                  := '0';
    --signal fbos_i      : std_logic                                                  := '0';
    signal bos_i       : std_logic                                                  := '0';
    signal set_bos     : std_logic                                                  := '0';
    signal biterr_flag : std_logic                                                  := '0';
    signal trg_done    : std_logic                                                  := '0';
    signal fbos_done   : std_logic                                                  := '0';
    signal bos_done    : std_logic                                                  := '0';
    signal reset_i     : std_logic                                                  := '1';
    signal del_count   : integer range 0 to 1023;                               
    signal ready_dly   : std_logic                                                  := '0';
    signal first_ev_of_spill : std_logic                                            := '0';
    signal begin_end_trig : std_logic                                               := '0';
    
    
-- new bos sync signals
    signal bos_sr                   : std_logic_vector(1 downto 0)                  := "00";
    signal res_ct_bos_sr            : std_logic_vector(1 downto 0)                  := "00";
    signal bos_edge_detected        : std_logic                                     := '0';
    signal res_ct_bos_edge_detected : std_logic                                     := '0';
    
    type rdout_state_typ is (
        st_idle,
        st_read_addr_fifo,
        st_load_address,
        st_wait_ram,
        st_wr_frame
        );
    signal rdout_state : rdout_state_typ := st_idle;


    type bos_logic_typ is (
        st_wait,
        st_armed,
        st_send_bos
        );
    signal   bos_logic             : bos_logic_typ                                  := st_wait;

    signal   is_normal_mode        : integer range 0 to 255                         := 255;
    signal   sec_alg_is_on         : std_logic                                      := '0';
    signal   fr_counter            : integer range 0 to 4096;
    signal   ch_counter            : integer range 0 to adc_channels - 1;                     -- era 15;
    signal   coarse_t              : std_logic_vector (37 downto 0)                 := (others => '0');
    constant zero_ct               : std_logic_vector (36 downto 0)                 := (others => '0');
    signal   write_ring            : std_logic                                      := '0';
    signal   wea_ring              : std_logic_vector(3 downto 0);
    signal   write_fifo            : std_logic                                      := '0';
    -- signal   wr_fifo_pl1           : std_logic                                      := '0';
    signal   read_ram              : std_logic                                      := '0';
    signal   write_lsb             : std_logic                                      := '0';

 

-- ring buffer signals 
-- BRAM_SDP_MACRO configuration Table 
--------------------------------------------------------------------------
--  DATA_WIDTH  | BRAM_SIZE |  READ Depth   | RDADDR Width  |           --
--              |           | WRITE Depth   | WRADDR Width  |  WE Width --
-- =============|===========|===============|===============|===========--
-- 37-72        | "36Kb"    | 512           | 9-bit         |   8-bit   --
-- 19-36        | "36Kb"    | 1024          | 10-bit        |   4-bit   --
-- 19-36        | "18Kb"    | 512           | 9-bit         |   4-bit   --
-- 10-18        | "36Kb"    | 2048          | 11-bit        |   2-bit   --
-- 10-18        | "18Kb"    | 1024          | 10-bit        |   2-bit   --
-- 5-9          | "36Kb"    | 4096          | 12-bit        |   1-bit   --
-- 5-9          | "18Kb"    | 2048          | 11-bit        |   1-bit   --
-- 3-4          | "36Kb"    | 8192          | 13-bit        |   1-bit   --
-- 3-4          | "18Kb"    | 4096          | 12-bit        |   1-bit   --
-- 2            | "36Kb"    | 16384         | 14-bit        |   1-bit   --
-- 2            | "18Kb"    | 8192          | 13-bit        |   1-bit   --
-- 1            | "36Kb"    | 32768         | 15-bit        |   1-bit   --
-- 1            | "18Kb"    | 16384         | 14-bit        |   1-bit   --
--------------------------------------------------------------------------

-- our ring_buf is 36Kb ...
-- see BRAM_SDP_MACRO configuration Table for correct value
    constant ring_buf_width        : integer := 1; -- 2;                                   
    constant ring_buf_addr         : integer := 15; -- 14; 
    -- replicate the addresses for better timing
    --address fifo
    signal load_i                  : std_logic;
    signal rd_address_ff           : std_logic;
    type     addresses_t is array (adc_channels - 1 downto 0) of std_logic_vector(ring_buf_addr - 1 downto 0); -- era 10
    signal   write_addresses       : addresses_t;
    signal   read_addresses        : addresses_t;

    signal fifo_address            : std_logic_vector(ring_buf_addr -1 downto 0);
    signal read_address            : std_logic_vector(ring_buf_addr -1 downto 0);
    signal empty_address_ff        : std_logic;

    signal rdcount_address_ff      : std_logic_vector (9 downto 0); --messo a 10
    signal wrcount_address_ff      : std_logic_vector (9 downto 0);
    --
    --
    --
    --
    -- These value are now stored in the config memory
    signal   timestamp_base        : std_logic_vector (31 downto 0)                 := GEN_TIMESTAMP_BASE;
    signal   src_id                : std_logic_vector (9 downto 0)                  := b"00" & GEN_SOURCE_ID;
    signal   latency               : std_logic_vector (15 downto 0)                 := std_logic_vector(to_unsigned(GEN_LATENCY,16));     -- x"000d";  -- !! write adress is 10 downto 0!!
    signal   framewidth_slv        : std_logic_vector (10 downto 0)                 := std_logic_vector(to_unsigned(GEN_FRAMEWIDTH,11));  -- "00010000000";  --Marco: NO, ora è 12
    signal   baseline              : std_logic_vector (10 downto 0)                 := std_logic_vector(to_unsigned(GEN_BASELINE,11));    -- b"000" & x"c8";      -- must be below the real baseline, because of substraction
    signal   prescaler_base        : std_logic_vector (7 downto 0)                  := std_logic_vector(to_unsigned(GEN_PRESCALER,8));    --"00000000";          -- "00000010";
    signal   frac                  : std_logic_vector (5 downto 0)                  := std_logic_vector(to_unsigned(GEN_FRACTION,6));     -- b"000010";
    signal   delay                 : std_logic_vector (4 downto 0)                  := std_logic_vector(to_unsigned(GEN_DELAY,5));        -- '0' & x"a";
    signal   threshold             : std_logic_vector (7 downto 0)                  := std_logic_vector(to_unsigned(GEN_THRESHOLD,8));    -- x"1e";
    signal   cf_max_dist           : std_logic_vector (2 downto 0)                  := std_logic_vector(to_unsigned(GEN_MAX_DIST,3));     -- b"011";
    signal   t_threshold           : std_logic_vector (12 downto 0)                 := std_logic_vector(to_unsigned(GEN_T_THRESHOLD,13)); -- b"00000" & x"0a";
    signal   t_cf_max_dist         : std_logic_vector (2 downto 0)                  := std_logic_vector(to_unsigned(GEN_T_MAX_DIST,3));   -- b"011";

    -- also these should be stored in the config memory
    signal   t_baseline            : std_logic_vector(12 downto 0)                  := b"00000" & x"c8";
    signal   t_fraction            : std_logic_vector (5 downto 0)                  := b"000011";
    signal   t_delay               : std_logic_vector (4 downto 0)                  := b"0" & x"c";
    -- until here ...

    signal   framewidth            : integer range 0 to 4096                        := GEN_FRAMEWIDTH; 
    signal   before_zc             : std_logic_vector(2 downto 0)                   := "001";
    signal   after_zc              : std_logic_vector(2 downto 0)                   := "101";

    -- 
    subtype  fifo_cnt is std_logic_vector(8 downto 0); -- era 9 
    type     fifo_cnts is array (integer range<>) of fifo_cnt;
    signal   rd_fifo_cnt           : fifo_cnts(adc_channels-1 downto 0);
    signal   wr_fifo_cnt           : fifo_cnts(adc_channels-1 downto 0);

    signal   frame_fifo_full      : std_logic_vector(adc_channels - 1 downto 0); -- era 15
    signal   some_event_fifo_full  : std_logic                                      := '0';
    signal   some_buffer_fifo_full : std_logic                                      := '0';
    signal   some_frame_fifo_full  : std_logic                                      := '0';
---slink logic ---  

    signal  sl_frame         : integer range 0 to 9                                 := 0;
    signal  size_calc_cnt    : integer range 0 to 4                                 := 0;
    subtype ch_sz_word is std_logic_vector(11 downto 0);    
    type    ch_sz_words is array (integer range<>) of ch_sz_word;   
    signal  ch_sz            : ch_sz_words(0 to active_channels - 1)                := (others => (others => '0'));
    subtype two_ch_sz_word is std_logic_vector(12 downto 0);        
    type    two_ch_sz_words is array (integer range<>) of two_ch_sz_word;       
    signal  two_ch_sz        : two_ch_sz_words(0 to  active_channels/2 - 1)         := (others => (others => '0'));
    signal  all_ch_size      : std_logic_vector(14 downto 0)                        := (others => '0');
    signal  channel_has_hits : std_logic_vector(active_channels - 1 downto 0);    
    subtype channel_int_word is integer range 0 to 7;   
    type    channel_int_words is array (integer range<>) of channel_int_word;   
    signal  channel_int      : channel_int_words(0 to active_channels - 1)          := (others => 0);
    signal  sysmon           : std_logic_vector (4 downto 0)                        := '0' & x"0";
    signal  sysmon_i         : std_logic_vector (4 downto 0)                        := '0' & x"0";
    signal  load_src_id      : std_logic                                            := '0';
    signal  load_lat         : std_logic                                            := '0';
    signal  load_cfd         : std_logic                                            := '0';
    signal  load_basel       : std_logic                                            := '0';
    signal  load_t_cfd       : std_logic                                            := '0';
    signal  load_t_cfd_2     : std_logic                                            := '0';
    signal  wait_bram        : std_logic                                            := '0';
    signal  bram_dir         : std_logic                                            := '0';

---cf_mem---
    signal config_mem_bram_addr_i : std_logic_vector(15 downto 0)                   := "1000000000011111";
    alias memoryaddr              : std_logic_vector (9 downto 0) is config_mem_bram_addr_i(14 downto 5);
    type cf_mem_logic_typ is (
        st_wait,
        st_srcid,
        st_latency,
        st_baseline,
        st_cfd,
        st_t_cfd,
        -- st_t_max_dist,
-- st_write_bos_flt,
        st_changedelays,
        st_writeedges
        );

    signal cfmem_logic       : cf_mem_logic_typ                                     := st_wait;
    signal cf_enable         : integer range 0 to 4;
---debug
    signal data_i_debug1     : adc_ddrports(adc_channels-1 downto 0);
    signal data_i_debug2     : adc_ddrports(adc_channels-1 downto 0);
    signal dbg_state_ana_ilm : std_logic_vector(31 downto 0)                        := (others => '0');
    signal dbg_state_amc_if  : std_logic_vector(3 downto 0)                         := (others => '0');
    signal tcs_status        : std_logic_vector(7 downto 0)                         := (others => '0');
    signal tcs_error_flag    : std_logic                                            := '0';

   
------------------------------------------------------------------------
begin  --------------------------- begin --------------------------------
------------------------------------------------------------------------
    timestamp_bv <= timestamp_base; --static connection per inviare il timestamp(valore di reset) verso il tcs_if_MEP
    sec_alg_is_on                 <= fr_sec_alg_on;
    dbgframe_ff_empty             <= frame_fifo_empty;
    dbgevt_ff_empty(adc_channels/2 - 1 downto 0)   <= rd_frame_ff(adc_channels/2 - 1 downto 0);
    dbgevt_ff_empty(11 downto 8)  <= dbg_state_ana_ilm(3 downto 0);
    dbgevt_ff_empty(15 downto 12) <= write_lsb & trigger_i & read_ram & write_fifo;
    dbgevt_ff_empty(19 downto 16) <= bos_i & reset_i & trg_done & write_ring;
    dbgevt_ff_empty(23 downto 20) <= dbg_state_amc_if;
                                        -- big readout

------------------------------------------------------------------------
-- bits non e' usato ... 
bits <= (others => '0');
------------------------------------------------------------------------


-- inserito nel package G_PARAMETERS
-- active_channels <= 4 when gen_rdm(3) = '1' else 8;
    
    inst_amc_ports : for amc_ch in 0 to adc_channels - 1 generate --era 15 generate
     
    signal reset_sync : std_logic := '1';
    begin

        process
        begin
            wait until rising_edge(clk_200mhz_in);
            reset_sync <= '0';
            if reset /= '0' then
                reset_sync <= '1';
            end if;
        end process;
    
        inst_mcs : if (bs_mcs_up = "AMC" and amc_ch <= 7) or (bs_mcs_dn = "AMC" and amc_ch >= 8) generate
        begin

            si_a_clock : ibufds -- ibufgds                            
                generic map (
                    diff_term       => true,  -- differential termination (virtex-4/5, spartan-3e/3a
                    iostandard      => "LVDS_25")
                port map (
                    i               => port_p(amc_ch)(14),        
                    ib              => port_n(amc_ch)(14),        
                    o               => si_a_clk(amc_ch)     -- si_a_clk_to_dly(amc_ch)
                );
          

            adc_unused_bits : for adc_bits in 12 to 13 generate -- era to 13 ...
            begin
                diffdataport_input : ibufds
                    generic map (
                        diff_term  => true,  -- differential termination (virtex-4/5, spartan-3e/3a)
                        iostandard => "LVDS_25")
                    port map (
                        i  => port_p(amc_ch)(adc_bits),
                        ib => port_n(amc_ch)(adc_bits),
                        o  => data_del(amc_ch)(adc_bits)  --(adc_bits)
                        );
            end generate;

            adc_bits_ddrin : for adc_bits in 0 to 11 generate
            begin
                diffdataport_input : ibufds
                    generic map (
                        diff_term  => true,  -- differential termination (virtex-4/5, spartan-3e/3a)
                        iostandard => "LVDS_25")
                    port map (
                        i  => port_p(amc_ch)(adc_bits),
                        ib => port_n(amc_ch)(adc_bits),
                        o  => data_del(amc_ch)(adc_bits)  --(adc_bits)
                        );
                ddr_iodelay : iodelay
                    generic map(
                        delay_src             => "DATAIN",  --"i", --auch hier aendern...
                        idelay_type           => "VARIABLE",  --"variable" geht nur mit aktiven inc, ce, c
                        high_performance_mode => true,
                        idelay_value          => add_adc_delay + gen_idel_int(amc_ch)(adc_bits),  --port delay
                        odelay_value          => 0,
                        signal_pattern        => "DATA"
                        )
                    port map(
                        dataout => data_i(amc_ch)(adc_bits),
                        c       => clk_200mhz_in,
                        ce      => del_ce(amc_ch)(adc_bits),
                        datain  => data_del(amc_ch)(adc_bits),
                        idatain => '0',
                        inc     => del_inc(amc_ch)(adc_bits),
                        odatain => '0',
                        rst     => reset_sync,
                        t       => '1'
                        );
                ddr_consist_iodelay : iodelay
                    generic map(
                        delay_src             => "DATAIN",  --"i", --auch hier aendern...
                        idelay_type           => "VARIABLE",  --"variable" geht nur mit aktiven inc, ce, c
                        high_performance_mode => true,
                        idelay_value          => add_adc_delay + gen_idel_int(amc_ch)(adc_bits), -- +1
                        odelay_value          => 0,
                        signal_pattern        => "DATA"  -- input signal type, "clock" or "data" (consider more jitter for data in tc)
                        )
                    port map(
                        dataout => data_consist_i(amc_ch)(adc_bits),
                        c       => clk_200mhz_in,
                        ce      => del_ce(amc_ch)(adc_bits),
                        datain  => data_del(amc_ch)(adc_bits),
                        idatain => '0',
                        inc     => del_inc(amc_ch)(adc_bits),
                        odatain => '0',
                        rst     => reset_sync,
                        t       => '1'
                        );
                ddrdatainput : iddr
                    generic map (
                        ddr_clk_edge => "SAME_EDGE_PIPELINED",                                  -- "opposite_edge", "same_edge"
                                                                                                -- or "same_edge_pipelined"
                        init_q1      => '0',                                                    -- initial value of q1: '0' or '1'
                        init_q2      => '0',                                                    -- initial value of q2: '0' or '1'
                        srtype       => "SYNC")                                                 -- set/reset type: "sync" or "async"
                    port map (                  
                        q1 => data_i_ddr(amc_ch)(adc_bits),                                     -- 1-bit output for positive edge of clock
                        q2 => data_i_ddr(amc_ch)(adc_bits+12),                                  -- 1-bit output for negative edge of clock
                        c  => si_a_clk(amc_ch),                                                 -- 1-bit clock input
                        ce => '1',                                                              -- 1-bit clock enable input
                        d  => data_i(amc_ch)(adc_bits),                                         -- 1-bit ddr data input
                        r  => reset_sync,                                                       -- 1-bit reset
                        s  => '0'                                                               -- 1-bit set
                        );                  
                ddrconsistdatainput : iddr                  
                    generic map (                   
                        ddr_clk_edge => "SAME_EDGE_PIPELINED",                                  -- "opposite_edge", "same_edge"
                                                                                                -- or "same_edge_pipelined"
                        init_q1      => '0',                                                    -- initial value of q1: '0' or '1'
                        init_q2      => '0',                                                    -- initial value of q2: '0' or '1'
                        srtype       => "ASYNC")                                                -- set/reset type: "sync" or "async"
                    port map (                  
                        q1 => data_consist_i_ddr(amc_ch)(adc_bits),                             -- 1-bit output for positive edge of clock
                        q2 => data_consist_i_ddr(amc_ch)(adc_bits+12),                          -- 1-bit output for negative edge of clock
                        c  => si_a_clk(amc_ch),                                                 -- 1-bit clock input
                        ce => '1',                                                              -- 1-bit clock enable input
                        d  => data_consist_i(amc_ch)(adc_bits),                                 -- 1-bit ddr data input
                        r  => reset_sync,                                                       -- 1-bit reset
                        s  => '0'                                                               -- 1-bit set
                        );

                -- all logic needed to auto-calibrate all adc's delays
                -- and eliminate all biterrors forever. (but one needs to loc all above)
                fdre_latch_edge_rstpot : lut4
                    generic map (
                        init => x"6ff6")
                    port map (
                        o  => data_latch_i(amc_ch)(adc_bits),                                   -- lut general output
                        i0 => data_i_ddr(amc_ch)(adc_bits),
                        i1 => data_consist_i_ddr(amc_ch)(adc_bits),
                        i2 => data_i_ddr(amc_ch)(adc_bits+12),
                        i3 => data_consist_i_ddr(amc_ch)(adc_bits+12)
                        );
                                                                                                -- latch the info if there has been a "01" or "10"
                fdre_latch_edge : fdre                  
                    generic map (                   
                        init => '0')                                                            -- initial value of register ('0' or '1')
                    port map (                  
                        q  => data_latch(amc_ch)(adc_bits),                                     -- data output
                        c  => si_a_clk(amc_ch),                                                 -- clock input
                        ce => data_latch_i(amc_ch)(adc_bits),                                   -- clock enable input
                        r  => data_latch_rst(amc_ch)(adc_bits),                                 -- synchronous reset input
                        d  => '1'                                                               -- data input
                        );

                ---lsb data convention hf---
                data_ddr_inv(amc_ch)(adc_bits)    <= not(data_i_ddr(amc_ch)(adc_bits));
                data_ddr_inv(amc_ch)(adc_bits+12) <= not(data_i_ddr(amc_ch)(adc_bits+12));
            end generate;
            data_i_debug1(amc_ch) <= data_i_pl1(amc_ch)(23 downto 12) & data_i_pl1(amc_ch)(11 downto 4) & "0010";
--           

            -- instanzia la block ram ... per 2^15 addr, circa 280 us latency a 233Mhz
            inst_ring_buf : for buf_no in 0 to 24/ring_buf_width - 1 generate
                inst_single_buf : BRAM_SDP_MACRO
                    generic map (
                        bram_size           => "36Kb",                                          -- target bram, "18kb" or "36kb"
                        device              => "VIRTEX5",                                       -- target device: "virtex5", "virtex6", "spartan6"
                        write_width         => ring_buf_width,                                  -- valid values are 1-72 (37-72 only valid when bram_size="36kb")
                        read_width          => ring_buf_width,                                  -- valid values are 1-72 (37-72 only valid when bram_size="36kb")
                        do_reg              => 0,                                               -- optional output register (0 or 1)
                        init_file           => "NONE",                                  
                        sim_collision_check => "ALL",                                           -- collision check enable "all", "warning_only",
                                                                                                -- "generate_x_only" or "none"
                        sim_mode            => "FAST",                                          -- simulation: "safe" vs "fast",
                                                                                                -- see "synthesis and simulation design guide" for details
                        srval               => x"000000000000000000",                           --  set/reset value for port output
                        init                => x"000000000000000000"                            --  initial values on output port
                        )
                    port map (
                        do     => frame_data(amc_ch)(ring_buf_width * buf_no + ring_buf_width - 1 downto ring_buf_width * buf_no),  -- output read data port
                        di     => data_i_pl1(amc_ch)(ring_buf_width * buf_no + ring_buf_width - 1 downto ring_buf_width * buf_no),  -- input write data port
                        rdaddr => read_addresses(amc_ch),                                       -- input read address
                        rdclk  => adc_clk,                                                      -- input read clock
                        rden   => read_ram,                                                     -- input read port enable
                        regce  => read_ram,                                                     -- input read output register enable
                        rst    => reset,                                                        -- input reset
                        we     => wea_ring(0 downto 0),                                         -- input write enable
                        wraddr => write_addresses(amc_ch),                                      -- input write address
                        wrclk  => si_a_clk(amc_ch),                                             -- input write clock
                        wren   => write_ring                                                    -- input write port enable
                        );
            end generate;

            -- instanzia una Frame fifo per canale
            inst_frame_ff : FIFO_DUALCLOCK_MACRO 
                generic map (
                    device                  => "VIRTEX5",                                       -- target device: "virtex5", "virtex6"
                    almost_full_offset      => x"0080",                                         -- sets almost full threshold
                    almost_empty_offset     => x"0080",                                         -- sets the almost empty threshold
                    data_width              => 24,                                              -- valid values are 1-72 (37-72 only valid when fifo_size="36kb")
                    fifo_size               => "18Kb",                                          -- target bram, "18kb" or "36kb"  -- era 36Kb
                    first_word_fall_through => true,                                            -- sets the fifo fwft to true or false
                    sim_mode                => "FAST")                                          -- simulation "safe" vs "fast",
                                                                                                -- see "synthesis and simulation design guide" for details
                port map (                      
                    almostempty => open,                                                        -- output almost empty
                    almostfull  => open,                                                        -- output almost full
                    do          => frame_fifo_data(amc_ch),                                            -- output data
                    empty       => frame_fifo_empty(amc_ch),                                          -- output empty
                    full        => frame_fifo_full(amc_ch),                                    -- output full
                    rdcount     => rd_fifo_cnt(amc_ch),                                         -- output read count
                    rderr       => open,                                                        -- output read error
                    wrcount     => wr_fifo_cnt(amc_ch),                                         -- output write count
                    wrerr       => open,                                                        -- output write error
                    di          => frame_pl1(amc_ch),                                           -- input data
                    rdclk       => data_clk,                                                    -- input read clock
                    rden        => frame_fifo_rden(amc_ch),                                           -- input read enable
                    rst         => reset,                                                       -- input reset
                    wrclk       => adc_clk,                                                     -- input write clock
                    wren        => wr_fifo_pl1(amc_ch)                                          -- input write enable
                    );

          
            
            -- read buffer logic with common clock
            ring_buffer_rd_logic : process(adc_clk)
            begin
                if rising_edge(adc_clk) then
                    -- pipeline registers for timing
                    wr_fifo_pl1(amc_ch)     <= write_fifo;
                    frame_pl1(amc_ch) <= frame_data(amc_ch);
                    if reset_i = '1' then
                        read_addresses(amc_ch)  <= (others => '0');
                    else
                        if bos_i = '1' then
                            read_addresses(amc_ch)  <= (others => '0');
                        elsif load_i = '1' then
                                read_addresses(amc_ch)  <= read_address;        -- out from address_ff
                                
                        else
                            read_addresses(amc_ch)  <= read_addresses(amc_ch) + 1;
                        end if;
                    end if;
                end if;
            end process;
        
            -- write buffer logic with separate clock
            ring_buffer_wr_logic : process(si_a_clk(amc_ch))
            begin
                if rising_edge(si_a_clk(amc_ch)) then
                -- pipeline registers for timing
                data_i_pl1(amc_ch)  <= data_ddr_inv(amc_ch);
                
                    if reset_i = '1' then
                        write_addresses(amc_ch) <= latency(ring_buf_addr - 1  downto 0); -- era 10
                    else
                        if bos_i = '1' then
                            write_addresses(amc_ch) <= latency(ring_buf_addr - 1 downto 0); -- era 10
                        else
                            write_addresses(amc_ch) <= write_addresses(amc_ch) + 1;
                        end if;
                    end if;
                end if;
            end process;
        end generate;
    end generate;
    -------------------------------------------------------------------------------
                     -- Here end (adc_channel - 1) generate ...
    -------------------------------------------------------------------------------
    
    -- Common Fifo address
    -- Memorizza l'indirizzo a cui arriva il trigger ... (MARCO)
    inst_address_ff : FIFO_DUALCLOCK_MACRO
    generic map (
        device                  => "VIRTEX5",                                       -- target device: "virtex5", "virtex6"
        almost_full_offset      => x"0080",                                         -- sets almost full threshold
        almost_empty_offset     => x"0080",                                         -- sets the almost empty threshold
        data_width              => ring_buf_addr,                                   -- valid values are 1-72 (37-72 only va
        fifo_size               => "18Kb",                                          -- target bram, "18kb" or "36kb"  -- er
        first_word_fall_through => true,                                            -- sets the fifo fwft to true or false
        sim_mode                => "FAST")                                          -- simulation "safe" vs "fast",
                                                                                    -- see "synthesis and simulation design
    port map (                      
        almostempty => open,                                                        -- output almost empty
        almostfull  => open,                                                        -- output almost full
        do          => read_address,                                                -- output data
        empty       => empty_address_ff,                                            -- output empty
        full        => open,                                                        -- output full
        rdcount     => rdcount_address_ff,                                                        -- output read count
        rderr       => open,                                                        -- output read error
        wrcount     => wrcount_address_ff,                                                        -- output write count
        wrerr       => open,                                                        -- output write error
        di          => fifo_address,                                                -- input data
        rdclk       => adc_clk,                                                     -- input read clock
        rden        => rd_address_ff,                                               -- input read enable
        rst         => reset,                                                       -- input reset
        wrclk       => adc_clk,                                                     -- input write clock
        wren        => trigger_i                                                    -- input write enable
        );        
    
        -- Common fifo address logic (MARCO)
        fifo_address_logic  : process(adc_clk)
        begin
            if rising_edge(adc_clk) then
                if reset_i = '1' then
                    fifo_address            <= (others => '0'); 
                else
                    if bos_i = '1' then
                        fifo_address            <= (others => '0');
                    else
                        fifo_address            <= fifo_address + 1; 
                    end if;
                end if;
            end if;
        end process;

    adc_clk <= si_a_clk(0);
    adc_readout_clk <= adc_clk;    


---map sys mon info
    err_flags <= biterr_flag & flt_err & ev_num_err;                    -- aggiunti in uscita

    -- stat_flags(11) <= lff;                                           -- spostati in gbase_top.vhd
    -- stat_flags(12) <= not ready;                                     
    -- stat_flags(13) <= ev_num_err;
    -- stat_flags(14) <= flt_err;                                       -- flt within ~400ns or first ev num of spill != 1 !!!
    -- stat_flags(15) <= biterr_flag;                                   -- biterr flag to the outside world

    sysmon(4)  <= biterr_flag;                                          -- board temp/voltage status
    sysmon(3)  <= stat_flags(12) or stat_flags(11) or stat_flags(10);   -- slink/readout status
    sysmon(2)  <= stat_flags(9);                                        -- tcs status (lol)
    sysmon(1)  <= stat_flags(8) or stat_flags(7) or stat_flags(6) or stat_flags(5) or stat_flags(4) or stat_flags(3);  --si mezz status
    sysmon(0)  <= stat_flags(2) or stat_flags(1) or stat_flags(0);  --si g status
--  tcs_status <= stat_flags(2) & stat_flags(1) & stat_flags(8) & stat_flags(7) & stat_flags(5) & stat_flags(4) & stat_flags(9) & biterr_flag;
    tcs_status <= stat_flags(1) & stat_flags(0) & stat_flags(8) & stat_flags(7) & stat_flags(5) & stat_flags(4) & stat_flags(9) & biterr_flag;


    with tcs_status select
        tcs_error_flag <= '0' when x"00",
        '1'                   when others;
        
        

-------------------------------------------------------------------------------
-- rd address logic: reseting of ringbuffer upon bos, reseting coarsetime on sync bos
--probabilmente non serve più -Alex

   reset_logic : process
    begin
        wait until rising_edge(adc_clk);
        -- latch reset with dry
        if reset = '1' then
            reset_i <= '1';
        else
            reset_i <= '0';
        end if;
     end process;
------------------------------------------------------------------------------- 

-------------------------------------------------------------------------------
-- BOS detection, replaced old code in 9/15
--probabilmente non serve più -Alex
    trigger_logic : process
    begin
        wait until rising_edge(adc_clk);
-- clock in the bos signal!
        bos_sr <= bos_sr(0) & bos;
        if bos_sr = "01" then
            bos_i <= '1';
        else
            bos_i <= '0';
        end if;
    end process;
------------------------------------------------------------------------------- 

    -- legge il ring buffer e scrive la frame fifo
    --da modificare, non c'è più il coarse time  ed è da spostare nella data_out_logic-Alex
    readout_logic : process(adc_clk)
    begin
        if rising_edge(adc_clk) then        
                
            flt_sr <= flt_sr(0) & trg;
            
            if flt_sr = "01" and flt_err = '0' and ev_num_err = '0' then
                trigger_i <= '1';
            else
                trigger_i <= '0';
            end if;

            case rdout_state is

                when st_idle =>        --wait for trigger
                    dbg_state_amc_if <= x"1";
                    read_ram         <= '0';
                    write_ring       <= '1'; --continuo a scrivere il ring buffer
                    wea_ring         <= x"f";
                    write_fifo       <= '0'; --attendo a scrivere le frame_fifo che arrivi il trigger
                    load_i <= '0';
                                        -- flt clock domain change
                
                    if (empty_address_ff = '0') then
                        rdout_state <= st_read_addr_fifo;
                        fr_counter <= framewidth - 1;
                                                                                --stesso discorso di sotto ...
                                                                                --coarse_t <= (latency+coarse_cnt) & '0';
                        --coarse_t <= coarse_cnt & '0';
                                                              
                        
                    end if;
                when st_read_addr_fifo =>
                     dbg_state_amc_if <= x"2";
                     rd_address_ff <= '1'; --leggo address FIFO
                     --trigger_i <= '0';
                     rdout_state <= st_load_address;

                when st_load_address =>
                    dbg_state_amc_if <= x"3";
                    rdout_state <= st_wait_ram;
                    rd_address_ff <= '0';
                    read_ram <= '0'; --tanto scrivo solo nelle frame fifo quando attivo il loro write enable
                    load_i <= '1';

                when st_wait_ram => --attendo 1 colpo di clock
                    read_ram <= '1'; --tanto scrivo solo nelle frame fifo quando attivo il loro write enable
                    load_i <= '0';
                    rdout_state <= st_wr_frame;
                    dbg_state_amc_if <= x"4";
                when st_wr_frame => 
                    load_i <= '0';                                          --write one frame into the frame fifo
                    dbg_state_amc_if <= x"5";
                    read_ram <= '1';
                    if fr_counter /= 0 then
                        fr_counter <= fr_counter-1;
                        write_fifo <= '1';
                    else
                        rdout_state <= st_idle;
                        --write_lsb <= '1';
                        read_ram    <= '0';
                    end if;


                when others =>
                    dbg_state_amc_if <= x"6";

                    rdout_state <= st_idle;
                    

            end case;
        end if;


    end process;

    

    config_mem_bram_addr <= config_mem_bram_addr_i;






------------------------------------CASO MEP-------------------------------------------------------------
some_buffer_fifo_full <= '0' when buffer_fifos_full = zero_ct(active_channels - 1 downto 0) else '1';
some_frame_fifo_full  <= '0' when frame_fifo_full = zero_ct(adc_channels - 1 downto 0) else '1';
any_fifo_full <= some_frame_fifo_full or some_buffer_fifo_full;
---------------------------------------------------------------------------------------------------------


---------------------------------CASO MEP-------------------------------------------------------------
-- Aggiungere segnali load_i, rd_address_ff e read_ram (MARCO)
-- per gestire il read_addresses() ... 
-- leggo la fifo_address, carico il valore nel read_adresses(), leggo il circular buffer per n volte 
-- e scrivo la frame fifo di ogni canale ...
-- a questo punto non ci servono altre fifo intermedie (buffer fifo e event fifo di ana_nmr o ana_ilm)
-- Serve solo comporre il MEP qui dentro modificando opportunamente il tutto 

inst_data_out_logic_MEP : entity work.data_out_logic_MEPv2 
port map (
              
    MEP_data           =>    MEP_data,
    MEP_wen            =>    MEP_wen,
    --header_data        =>    header_data,
    header_wen         =>    header_wen,
    ready                =>    ready,
    lff                  =>    lff,
    data_clk             =>    data_clk,
    trg                  =>    trg, --X
    --bos                  =>    bos,
    event_no             =>    event_no,
    spill_no             =>    spill_no,
    event_type           =>    event_type,
    timestamp            =>    timestamp,
    tcs_fifo_empty       =>    tcs_fifo_empty,
    tcs_fifo_rden        =>    tcs_fifo_rden,
    stat_flags           =>    stat_flags,   
    --------------------------------------------------------------------------------------------------------------
    -- segnali interni di amc_if_8ch diventati porte:
    --------------------------------------------------------------------------------------------------------------
    rd_frame_ff          =>    rd_frame_ff,--X 
    frame_fifo_data      =>    frame_fifo_data,                              -- 31 bit
    frame_fifo_empty     =>    frame_fifo_empty, 
    frame_fifo_full     =>     frame_fifo_full,--X
    frame_fifo_rden      =>    frame_fifo_rden, 

-- variable delay needs this:                        
---readout logic---
    flt_sr               =>    flt_sr,--X
    flt_err              =>    flt_err, -- X
    
    ev_num_err           =>    ev_num_err,                                               
 
    reset_i             =>     reset_i,
    del_count           =>     del_count,--X                               
    ready_dly           =>     ready_dly, --X    
    src_id               =>       src_id,   
    framewidth           =>         framewidth, -- 128;   
    sysmon            =>            sysmon,   
    tcs_status        =>          tcs_status,
    tcs_error_flag    =>          tcs_error_flag

    );

   ---------------------------------------------------------------------------------------------------------------         
    
    
    -- Alex: corretto in funzione di adc_channels
    biterr_concat : if True generate        
        signal biterr_ch_i  : std_logic_vector(adc_channels - 1 downto 0); -- era 15
    begin       
        biterr_concat_loop : for chan in 0 to adc_channels - 1 generate -- era 15
            biterr_ch_i(chan) <= '1' when data_latch(chan)(11 downto 2) /= ("0000000000") else '0';
        end generate;
        biterr_flag <= '1' when biterr_ch_i /= zero_ct(adc_channels - 1 downto 0) else '0';  -- era x"0000"
    end generate;
    
    
        -- Alex: sembra giusto
    handle_var_delays : process(clk_200mhz_in)
    begin
        if rising_edge(clk_200mhz_in) then
            del_action_sr      <= del_action_sr(0) & del_action;
            del_latch_reset_sr <= del_latch_reset_sr(0) & del_latch_reset_fr;
            data_latch_rst     <= (others => (others => '0'));
            del_ce             <= (others => (others => '0'));
            del_inc            <= (others => (others => '0'));
            if (del_action_sr = "01") then  -- rising edge of del_action (clock domain change!!)
                for i in 0 to 13 loop
                    for j in 0 to adc_channels - 1 loop -- era 15
                        del_ce(j)(i)  <= del_settings(i)(16+j);
                        del_inc(j)(i) <= del_settings(i)(j);
                    end loop;
                end loop;
                data_latch_rst_cnt <= 4095;
            end if;
            if (del_latch_reset_sr = "01") then  -- rising edge
                data_latch_rst_cnt <= 4095;
            end if;
            if (data_latch_rst_cnt > 0) then
                data_latch_rst_cnt <= data_latch_rst_cnt - 1;
                data_latch_rst     <= (others => (others => '1'));
            end if;
        end if;
    end process;

    cfmem_handle : process(clk_cfmem)
    begin
        if rising_edge(clk_cfmem) then
            cfmem_wb_stb <= '0';
            cfmem_wb_cyc <= '0';
            cfmem_wb_we  <= x"0";
            del_action   <= '0';
            case cfmem_logic is
                when st_wait =>
                    if load_conf_data = '1' then
                        cfmem_logic <= st_srcid;
                        bram_dir    <= '1';      --read from cf_mem
                    end if;
                    if del_change_fr = '1' then  --in this case we just read the delay instructions and execute them
                        cfmem_logic  <= st_changedelays;
                        del_load_cnt <= 0;
                    end if;
                    if readback_edges = '1' then  --in this case we write the adc edge info into cfmem
                        cfmem_logic  <= st_writeedges;
                        del_load_cnt <= 0;
                    end if;
                when st_srcid =>
                    src_id        <= cfmem_wb_din(9 downto 0);
                    cfmem_wb_addr <= std_logic_vector(gndlf_addr_offset+ident_addr_offset)+'1';
                    if cfmem_wb_ack = '1' then
                        cfmem_logic <= st_latency;
                    else
                        cfmem_wb_cyc <= '1';
                        cfmem_wb_stb <= '1';
                    end if;
                when st_latency =>
                    latency        <= cfmem_wb_din(15 downto 0);
                    framewidth     <= to_integer(unsigned(cfmem_wb_din(26 downto 16))); -- Alex & Pablo: era fino a 31 ...
                    framewidth_slv <= cfmem_wb_din(26 downto 16);
                    cfmem_wb_addr  <= std_logic_vector(gndlf_addr_offset+gandalf_configuration);  -- VME ADDR 0xB00 (G_conf0)
                    if cfmem_wb_ack = '1' then
                        cfmem_logic <= st_baseline;
                    else
                        cfmem_wb_cyc <= '1';
                        cfmem_wb_stb <= '1';
                    end if;
                when st_baseline =>
                    timestamp_base <= cfmem_wb_din (31 downto 0);
                    -- baseline       <= cfmem_wb_din(10 downto 0);
                    -- prescaler_base <= cfmem_wb_din(31 downto 24);
                    cfmem_wb_addr  <= std_logic_vector(gndlf_addr_offset+gandalf_configuration)+b"010"; -- VME ADDR 0xB08 (G_conf2)
                    if cfmem_wb_ack = '1' then
                        cfmem_logic <= st_cfd;
                    else
                        cfmem_wb_cyc <= '1';
                        cfmem_wb_stb <= '1';
                    end if;
                when st_cfd =>
                    frac          <= cfmem_wb_din(5 downto 0);
                    delay         <= cfmem_wb_din(12 downto 8);
                    threshold     <= cfmem_wb_din(23 downto 16);
                    cf_max_dist   <= cfmem_wb_din(26 downto 24); -- added here ...
                    cfmem_wb_addr <= std_logic_vector(gndlf_addr_offset+gandalf_configuration)+b"101"; -- VME ADDR 0xB14 (G_conf5)
                    if cfmem_wb_ack = '1' then
                        cfmem_logic <= st_t_cfd;
                    else
                        cfmem_wb_cyc <= '1';
                        cfmem_wb_stb <= '1';
                    end if;

                when st_t_cfd =>
                    t_threshold   <= cfmem_wb_din(28 downto 16);
                    t_cf_max_dist <= cfmem_wb_din(2 downto 0);
                    cfmem_wb_addr <= std_logic_vector(gndlf_addr_offset+gandalf_configuration)+b"111"; -- VME ADDR 0xB1C (G_conf7)
                    if cfmem_wb_ack = '1' then
                        cfmem_logic <= st_wait;
                    else
                        cfmem_wb_cyc <= '1';
                        cfmem_wb_stb <= '1';
                    end if;
                
                when st_changedelays =>
                    if (del_load_cnt = adc_channels) then -- Alex era 16 ...
                        cfmem_logic <= st_wait;
                        del_action  <= '1';
                    end if;
                    if cfmem_wb_ack = '1' then
                        del_load_cnt               <= del_load_cnt + 1;
                        del_settings(del_load_cnt) <= cfmem_wb_din(31 downto 0);
                    else
                        cfmem_wb_we   <= x"0";
                        cfmem_wb_addr <= std_logic_vector(amc_del_set_offset + to_unsigned(del_load_cnt, 5)); -- VME ADDR 0x300 to 0x320 ()
                        cfmem_wb_cyc  <= '1';
                        cfmem_wb_stb  <= '1';
                    end if;
                when st_writeedges =>
                    if (del_load_cnt = adc_channels) then -- Alex era 16 ...
                        cfmem_logic <= st_wait;
                    end if;
                    if cfmem_wb_ack = '1' then
                        del_load_cnt <= del_load_cnt + 1;
                    else
                        cfmem_wb_we                <= x"f";
                        cfmem_wb_addr              <= std_logic_vector(amc_del_edge_offset + to_unsigned(del_load_cnt, 5)); -- VME ADDR 0x990 to 0x9B0 (Edge)
                        cfmem_wb_cyc               <= '1';
                        cfmem_wb_stb               <= '1';
                        cfmem_wb_dout(14 downto 0) <= data_latch(del_load_cnt);
                    end if;
                when others =>
                    cfmem_logic <= st_wait;
            end case;
        end if;
    end process;
end behavioral;
