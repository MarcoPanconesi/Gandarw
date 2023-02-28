----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:     15:05:38 04/27/2012 
-- Design Name:     
-- Module Name:     amc_if_simple - Behavioral 
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
--                  Modificato ingresso con singola DDR e IODELAY eliminata logica bit_err
--
----------------------------------------------------------------------------------

library ieee;
library unisim;
library unimacro;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use unisim.vcomponents.all;
use unimacro.vcomponents.all;
use work.top_level_desc.all;
use work.g_parameters.all;
use work.ddr_interface_pkg.all;

entity amc_if_simple is
    generic(sim : integer := 0);
    port (
        port_p                   : in  adc_ports(adc_channels - 1 downto 0);
        port_n                   : in  adc_ports(adc_channels - 1 downto 0);
        adc_readout_clk          : out std_logic;
        bits                     : out std_logic_vector (511 downto 0);
        slink_data               : out std_logic_vector (32 downto 0);
        slink_wen                : out std_logic;
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
        event_no                 : in  std_logic_vector (19 downto 0);
        spill_no                 : in  std_logic_vector (10 downto 0);
        event_type               : in  std_logic_vector (4 downto 0);
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
end amc_if_simple;

architecture behavioral of amc_if_simple is
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
    signal data_out             : adc_ddrports(adc_channels - 1 downto 0);            --2*12bit
    signal fifo_empty           : std_logic_vector(adc_channels  - 1 downto 0);       -- era 15
    signal frame_data           : adc_ddrports(adc_channels - 1 downto 0);
    signal frame_pl1            : adc_ddrports(adc_channels - 1 downto 0);
    signal read_fifo            : std_logic_vector(adc_channels - 1 downto 0);                         -- era 15
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
    signal fbos_i      : std_logic                                                  := '0';
    signal bos_i       : std_logic                                                  := '0';
    signal set_bos     : std_logic                                                  := '0';
    signal biterr_flag : std_logic                                                  := '0';
    signal trg_done    : std_logic                                                  := '0';
    signal fbos_done   : std_logic                                                  := '0';
    signal bos_done    : std_logic                                                  := '0';
    signal bos_count   : std_logic_vector (7 downto 0)                              := (others => '0');
--  signal  flt_count          : std_logic_vector (19 downto 0)                     := (others => '0');
    signal reset_i     : std_logic                                                  := '1';
    signal del_count   : integer range 0 to 1023;                               
    signal ready_dly   : std_logic                                                  := '0';
    signal first_ev_of_spill : std_logic                                            := '0';
    signal begin_end_trig : std_logic                                               := '0';
    
    type rdout_state_typ is (
        st_armed,
        st_wr_frame,
        st_swap_fbus,
        st_wr_coarse_t
        );
-- new bos sync signals
    signal bos_sr                   : std_logic_vector(1 downto 0)                  := "00";
    signal res_ct_bos_sr            : std_logic_vector(1 downto 0)                  := "00";
    signal bos_edge_detected        : std_logic                                     := '0';
    signal res_ct_bos_edge_detected : std_logic                                     := '0';

    signal rdout_state : rdout_state_typ := st_armed;
    type bos_logic_typ is (
        st_wait,
        st_armed,
        st_send_bos
        );

    signal   bos_logic             : bos_logic_typ                                  := st_wait;
    signal   framewidth            : integer range 0 to 4096                        := 128;
    signal   framewidth_slv        : std_logic_vector (10 downto 0)                 := "00010000000";
    signal   is_normal_mode        : integer range 0 to 255                         := 255;
    signal   prescaler_base        : std_logic_vector(7 downto 0)                   := "00000010";
    signal   sec_alg_is_on         : std_logic                                      := '0';
    signal   fr_counter            : integer range 0 to 4096;
    signal   ch_counter            : integer range 0 to adc_channels - 1;                     -- era 15;
    signal   coarse_t              : std_logic_vector (37 downto 0)                 := (others => '0');
    signal   coarse_cnt            : std_logic_vector (36 downto 0)                 := (others => '0');
    constant zero_ct               : std_logic_vector (36 downto 0)                 := (others => '0');
    signal   write_ring            : std_logic                                      := '0';
    signal   wea_ring              : std_logic_vector(3 downto 0);
    signal   write_fifo            : std_logic                                      := '0';
    -- signal   wr_fifo_pl1           : std_logic                                      := '0';
    signal   read_ram              : std_logic                                      := '0';
    signal   write_lsb             : std_logic                                      := '0';

    -- ring buffer signals    
    signal   write_address         : std_logic_vector(10 downto 0);
    signal   read_address          : std_logic_vector(10 downto 0);

    -- replicate the addresses for better timing
    type     addresses_t is array (adc_channels-1 downto 0) of std_logic_vector(10 downto 0);
    signal   write_addresses       : addresses_t;
    signal   read_addresses        : addresses_t;
    
    signal   latency               : std_logic_vector(15 downto 0)                  := x"000d";  --!! write adress is 10 downto 0!!
    signal   baseline              : std_logic_vector (10 downto 0)                 := b"000" & x"c8";  --must be below the real baseline, because of substraction
    signal   delay                 : std_logic_vector (4 downto 0)                  := '0' & x"a";
    signal   frac                  : std_logic_vector (5 downto 0)                  := b"000010";
    signal   threshold             : std_logic_vector (7 downto 0)                  := x"1e";
    signal   cf_max_dist           : std_logic_vector (2 downto 0)                  := b"011";
    signal   before_zc             : std_logic_vector(2 downto 0)                   := "001";
    signal   after_zc              : std_logic_vector(2 downto 0)                   := "101";
    signal   t_baseline            : std_logic_vector(12 downto 0)                  := b"00000" & x"c8";
    signal   t_fraction            : std_logic_vector (5 downto 0)                  := b"000011";
    signal   t_delay               : std_logic_vector (4 downto 0)                  := b"0" & x"c";
    signal   t_threshold           : std_logic_vector(12 downto 0)                  := b"00000" & x"0a";
    signal   t_cf_max_dist         : std_logic_vector (2 downto 0)                  := b"011";
    subtype  fifo_cnt is std_logic_vector(9 downto 0);
    type     fifo_cnts is array (integer range<>) of fifo_cnt;
    signal   rd_fifo_cnt           : fifo_cnts(adc_channels-1 downto 0);
    signal   wr_fifo_cnt           : fifo_cnts(adc_channels-1 downto 0);
    signal   frame_fifos_full      : std_logic_vector(adc_channels - 1 downto 0); -- era 15
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
    signal  src_id           : std_logic_vector(9 downto 0)                         := b"00" & x"00";
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
        st_t_max_dist,
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
    sec_alg_is_on                 <= fr_sec_alg_on;
    dbgframe_ff_empty             <= fifo_empty;
    dbgevt_ff_empty(adc_channels/2 - 1 downto 0)   <= rd_frame_ff(adc_channels/2 - 1 downto 0);
    dbgevt_ff_empty(11 downto 8)  <= dbg_state_ana_ilm(3 downto 0);
    dbgevt_ff_empty(15 downto 12) <= write_lsb & trigger_i & read_ram & write_fifo;
    dbgevt_ff_empty(19 downto 16) <= bos_i & reset_i & trg_done & write_ring;
    dbgevt_ff_empty(23 downto 20) <= dbg_state_amc_if;
                                        -- big readout

------------------------------------------------------------------------
-- bits non e' usato ... 
bits <= (others => '0');
--    bits <= data_i_ddr(0) & x"00" & data_i_ddr(1) & x"00" & data_i_ddr(2) & x"00" & data_i_ddr(3) & x"00"
--            & data_i_ddr(4) & x"00" & data_i_ddr(5) & x"00" & data_i_ddr(6) & x"00" & data_i_ddr(7) & x"00"
--            & data_i_ddr(8) & x"00" & data_i_ddr(9) & x"00" & data_i_ddr(10) & x"00" & data_i_ddr(11) & x"00"
--            & data_i_ddr(12) & x"00" & data_i_ddr(13) & x"00" & data_i_ddr(14) & x"00" & data_i_ddr(15) & x"00";
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

            si_a_clock : ibufgds                            
                generic map (
                    diff_term       => true,  -- differential termination (virtex-4/5, spartan-3e/3a
                    iostandard      => "LVDS_25")
                port map (
                    i               => port_p(amc_ch)(14),        
                    ib              => port_n(amc_ch)(14),        
                    o               => si_a_clk(amc_ch)         -- si_a_clk_to_dly(amc_ch)
                );

            -- inst_si_a_clk_dly : iodelay                      
            --     generic map (
            --         DELAY_SRC               => "I",         -- Specify which input port to be used
            --                                                 -- "I"=IDATAIN, "O"=ODATAIN, "DATAIN"=DATAIN, "IO"=Bi-directional
            --         HIGH_PERFORMANCE_MODE   => TRUE,        -- TRUE specifies lower jitter
            --                                                 -- at expense of more power
            --         IDELAY_TYPE             => "FIXED",     -- "FIXED" or "VARIABLE" 
            --         IDELAY_VALUE            => 1,           -- 50 was good, put 38 for the data window for the adc bits to 
            --                                                 -- be at the next period (delay matrix has not to be modified); 
            --                                                 -- 0 to 63 tap valuesclk_ocx_155
            --         ODELAY_VALUE            => 0,           -- 0 to 63 tap values
            --         REFCLK_FREQUENCY        => 200.0,       -- Frequency used for IDELAYCTRL
            --                                                 -- 175.0 to 225.0
            --         SIGNAL_PATTERN          => "CLOCK")     -- Input signal type, "CLOCK" or "DATA" 
            --     port map (
            --         DATAOUT => si_a_clk_to_buf(amc_ch),     -- 1-bit delayed data output
            --         C       => '0',                         -- 1-bit clock input
            --         CE      => '0',                         -- 1-bit clock enable input
            --         DATAIN  => '0',                         -- 1-bit internal data input
            --         IDATAIN => si_a_clk_to_dly(amc_ch),     -- 1-bit input data input (connect to port)
            --         INC     => '0',                         -- 1-bit increment/decrement input
            --         ODATAIN => '0',                         -- 1-bit output data input
            --         RST     => '0',                         -- 1-bit active high, synch reset input
            --         T       => '1'                          -- 1-bit 3-state control input
            --     );
            --     
            -- si_a_clock_buf: bufg -- Alex: (from this pin can go only to a bufg ...)
            --     port map (
            --         O => si_a_clk(amc_ch),                -- Clock buffer output
            --         I => si_a_clk_to_buf(amc_ch)          -- Clock buffer input
            --     );

            -- Elimino il buf
            -- si_a_clk(amc_ch) <= si_a_clk_to_buf(amc_ch);


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

                -- ddr_consist_iodelay : iodelay
                --     generic map(
                --         delay_src             => "DATAIN",  --"i", --auch hier aendern...
                --         idelay_type           => "VARIABLE",  --"variable" geht nur mit aktiven inc, ce, c
                --         high_performance_mode => true,
                --         idelay_value          => add_adc_delay + gen_idel_int(amc_ch)(adc_bits), -- +1
                --         odelay_value          => 0,
                --         signal_pattern        => "DATA"  -- input signal type, "clock" or "data" (consider more jitter for data in tc)
                --         )
                --     port map(
                --         dataout => data_consist_i(amc_ch)(adc_bits),
                --         c       => clk_200mhz_in,
                --         ce      => del_ce(amc_ch)(adc_bits),
                --         datain  => data_del(amc_ch)(adc_bits),
                --         idatain => '0',
                --         inc     => del_inc(amc_ch)(adc_bits),
                --         odatain => '0',
                --         rst     => reset_sync,
                --         t       => '1'
                --         );

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

                -- ddrconsistdatainput : iddr                  
                --     generic map (                   
                --         ddr_clk_edge => "SAME_EDGE_PIPELINED",                                  -- "opposite_edge", "same_edge"
                --                                                                                 -- or "same_edge_pipelined"
                --         init_q1      => '0',                                                    -- initial value of q1: '0' or '1'
                --         init_q2      => '0',                                                    -- initial value of q2: '0' or '1'
                --         srtype       => "ASYNC")                                                -- set/reset type: "sync" or "async"
                --     port map (                  
                --         q1 => data_consist_i_ddr(amc_ch)(adc_bits),                             -- 1-bit output for positive edge of clock
                --         q2 => data_consist_i_ddr(amc_ch)(adc_bits+12),                          -- 1-bit output for negative edge of clock
                --         c  => si_a_clk(amc_ch),                                                 -- 1-bit clock input
                --         ce => '1',                                                              -- 1-bit clock enable input
                --         d  => data_consist_i(amc_ch)(adc_bits),                                 -- 1-bit ddr data input
                --         r  => reset_sync,                                                       -- 1-bit reset
                --         s  => '0'                                                               -- 1-bit set
                --         );
                --
                -- all logic needed to auto-calibrate all adc's delays
                -- and eliminate all biterrors forever. (but one needs to loc all above)
                -- fdre_latch_edge_rstpot : lut4
                --     generic map (
                --         init => x"6ff6")
                --     port map (
                --         o  => data_latch_i(amc_ch)(adc_bits),                                   -- lut general output
                --         i0 => data_i_ddr(amc_ch)(adc_bits),
                --         i1 => data_consist_i_ddr(amc_ch)(adc_bits),
                --         i2 => data_i_ddr(amc_ch)(adc_bits+12),
                --         i3 => data_consist_i_ddr(amc_ch)(adc_bits+12)
                --         );
                --                                                                                 -- latch the info if there has been a "01" or "10"
                -- fdre_latch_edge : fdre                  
                --     generic map (                   
                --         init => '0')                                                            -- initial value of register ('0' or '1')
                --     port map (                  
                --         q  => data_latch(amc_ch)(adc_bits),                                     -- data output
                --         c  => si_a_clk(amc_ch),                                                 -- clock input
                --         ce => data_latch_i(amc_ch)(adc_bits),                                   -- clock enable input
                --         r  => data_latch_rst(amc_ch)(adc_bits),                                 -- synchronous reset input
                --         d  => '1'                                                               -- data input
                --         );

                ---lsb data convention hf---
                data_ddr_inv(amc_ch)(adc_bits)    <= not(data_i_ddr(amc_ch)(adc_bits));
                data_ddr_inv(amc_ch)(adc_bits+12) <= not(data_i_ddr(amc_ch)(adc_bits+12));
            end generate;
            data_i_debug1(amc_ch) <= data_i_pl1(amc_ch)(23 downto 12) & data_i_pl1(amc_ch)(11 downto 4) & "0010";
            -- instanzia due ring buffer per canale
            inst_ring_buf : for buf_no in 0 to 1 generate
                rbuf_din(amc_ch)(buf_no) <= data_i_pl1(amc_ch)(11+buf_no*12 downto 0+buf_no*12);
                inst_single_buf : BRAM_SDP_MACRO
                    generic map (
                        bram_size           => "36Kb",                                          -- target bram, "18kb" or "36kb"
                        device              => "VIRTEX5",                                       -- target device: "virtex5", "virtex6", "spartan6"
                        write_width         => 12,                                              -- valid values are 1-72 (37-72 only valid when bram_size="36kb")
                        read_width          => 12,                                              -- valid values are 1-72 (37-72 only valid when bram_size="36kb")
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
                        do     => frame_data(amc_ch)(11+buf_no*12 downto 0+buf_no*12),          -- output read data port
                                -- di => data_i_pl1(amc_ch)(11+buf_no*12 downto 0+buf_no*12),   -- input write data port
                        di     => rbuf_din(amc_ch)(buf_no),                                     -- input write data port
                        rdaddr => read_addresses(amc_ch),                                       -- input read address
                        rdclk  => adc_clk,                                             -- input read clock
                        rden   => read_ram,                                                     -- input read port enable
                        regce  => read_ram,                                                     -- input read output register enable
                        rst    => reset,                                                        -- input reset
                        we     => wea_ring(1 downto 0),                                         -- input write enable
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
                    fifo_size               => "36Kb",                                          -- target bram, "18kb" or "36kb"
                    first_word_fall_through => true,                                            -- sets the fifo fwft to true or false
                    sim_mode                => "FAST")                                          -- simulation "safe" vs "fast",
                                                                                                -- see "synthesis and simulation design guide" for details
                port map (                      
                    almostempty => open,                                                        -- output almost empty
                    almostfull  => open,                                                        -- output almost full
                    do          => data_out(amc_ch),                                            -- output data
                    empty       => fifo_empty(amc_ch),                                          -- output empty
                    full        => frame_fifos_full(amc_ch),                                    -- output full
                    rdcount     => rd_fifo_cnt(amc_ch),                                         -- output read count
                    rderr       => open,                                                        -- output read error
                    wrcount     => wr_fifo_cnt(amc_ch),                                         -- output write count
                    wrerr       => open,                                                        -- output write error
                    di          => frame_pl1(amc_ch),                                           -- input data
                    rdclk       => data_clk,                                                    -- input read clock
                    rden        => read_fifo(amc_ch),                                           -- input read enable
                    rst         => reset,                                                       -- input reset
                    wrclk       => adc_clk,                                            -- input write clock
                    wren        => wr_fifo_pl1(amc_ch)                                          -- input write enable
                    );

            write_ct : process(adc_clk)
            begin
                if rising_edge(adc_clk) then    
                    if rdout_state = st_wr_coarse_t then
                        if write_lsb = '1' then
                            frame_pl1(amc_ch) <= "---" & coarse_t(20 downto 0);  --x"dddddd";--
                        else
                            frame_pl1(amc_ch) <= "-------" & coarse_t(37 downto 21);  -- x"eeeeee";--
                        end if;
                    else
                        frame_pl1(amc_ch) <= frame_data(amc_ch);
                    end if;
                
                end if;
            end process;

            -- read buffer logic with common clock
            ring_buffer_rd_logic : process(adc_clk)
            begin
                if rising_edge(adc_clk) then
                    -- pipeline registers for timing
                    wr_fifo_pl1(amc_ch)     <= write_fifo;  
                    if reset_i = '1' then
                        read_addresses(amc_ch)  <= (others => '0');
                    else
                        if bos_i = '1' then
                            read_addresses(amc_ch)  <= (others => '0');
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
                        write_addresses(amc_ch) <= latency(10 downto 0);
                    else
                        if bos_i = '1' then
                            write_addresses(amc_ch) <= latency(10 downto 0);
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
    

    adc_common_clk : bufg
    port map (
        O => adc_clk,               -- Clock buffer output
        I => si_a_clk(0)            -- Clock buffer input
    );

    -- adc_clk <= si_a_clk(0);
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
-- adress logic: reseting of ringbuffer upon bos, reseting coarsetime on sync bos

    adress_logic : process
    begin
        wait until rising_edge(adc_clk);
        -- latch reset with dry
        if reset = '1' then
            reset_i <= '1';
        else
            reset_i <= '0';
        end if;

        if reset_i = '1' then
            coarse_cnt    <= zero_ct - latency;
            bos_count     <= (others => '0');
        else
            if bos_i = '1' then
                bos_count     <= bos_count + 1;
            end if;

            if fbos_i = '1' then
                coarse_cnt <= zero_ct - latency;
                bos_count  <= x"00";
            else
                coarse_cnt <= coarse_cnt+1;
            end if;
        end if;
    end process;
------------------------------------------------------------------------------- 

-------------------------------------------------------------------------------
-- BOS detection, replaced old code in 9/15
    trigger_logic : process
    begin
        wait until rising_edge(adc_clk);
-- clock in the bos signal!
        bos_sr <= bos_sr(0) & bos;
        if bos_sr = "01" then
            bos_edge_detected <= '1';
        else
            bos_edge_detected <= '0';
        end if;

-- clock in the reset coarse time fastregister signal!
        res_ct_bos_sr <= res_ct_bos_sr(0) & res_ct_bos;
        if res_ct_bos_sr = "01" then
            res_ct_bos_edge_detected <= '1';
        else
            res_ct_bos_edge_detected <= '0';
        end if;

-- state machine w defaults
        fbos_i <= '0';
        bos_i  <= '0';
        case bos_logic is
            when st_wait =>             -- default "sleep" state
                if res_ct_bos_edge_detected = '1' then
                    bos_logic <= st_armed;
                elsif bos_edge_detected = '1' then
                    bos_logic <= st_send_bos;
                end if;

            when st_armed =>  -- state to synchronize gandalfs first bos
                if bos_edge_detected = '1' then
                    bos_logic <= st_send_bos;
                    fbos_i    <= '1';
                end if;

            when st_send_bos =>         -- now generate bos
                bos_i     <= '1';
                bos_logic <= st_wait;
        end case;
    end process;
------------------------------------------------------------------------------- 

    -- legge il ring buffer e scrive la frame fifo
    readout_logic : process(adc_clk)
    begin
        if rising_edge(adc_clk) then        
                
            flt_sr <= flt_sr(0) & trg;
            
            -- stop all adc operation in case we receive an FLT during the 
            -- processing of a prior FLT. This can NEVER happen (however, it does happen...)!
            if rdout_state/=st_armed and flt_sr = "01" then
                flt_err <= '1';
            elsif ready = '0' then
                flt_err <= '0';
            end if;
            
            case rdout_state is

                when st_armed =>        --wait for trigger
                    dbg_state_amc_if <= x"1";
                    dbg_state_amc_if <= x"2";
                    write_ring       <= '1';
                    wea_ring         <= x"f";
                    write_fifo       <= '0';
                                        -- flt clock domain change
                    if flt_sr = "01" and flt_err = '0' and ev_num_err = '0' then
                        trigger_i <= '1';
                    else
                        trigger_i <= '0';
                    end if;

                    if trigger_i = '1' then
                        rdout_state <= st_wr_frame;
                                        --frame_pl1 <= frame_data;
                        if gen_rdm(3) = '0' then                                --normal sampling mode 
                            fr_counter <= framewidth - 1;
                                                                                --stesso discorso di sotto ...
                                                                                --coarse_t <= (latency+coarse_cnt) & '0';
                            coarse_t <= coarse_cnt & '0';
                        elsif gen_rdm(3) = '1' then                             --interleaved mode
                            fr_counter <= (framewidth/2)-1;

                                                                                --change to start negative by latency with coarse_t
                                                                                --coarse_t <= (latency+coarse_cnt(35 downto 0)) & "00";
                            coarse_t <= coarse_cnt(35 downto 0) & "00";         -- read: coarse_cnt*4

                        end if;
                        read_ram <= '1';
                    end if;


                when st_wr_frame =>                                             --write one frame into the frame fifo
                    dbg_state_amc_if <= x"3";

                    if fr_counter /= 0 then
                        fr_counter <= fr_counter-1;
                        write_fifo <= '1';
                    else
                        rdout_state <= st_swap_fbus;
                        --write_lsb <= '1';
                        read_ram    <= '0';
                    end if;

                when st_swap_fbus =>                                            --prepare the input data bus of the fifo to accept the coarse time
                    dbg_state_amc_if <= x"4";

                    rdout_state <= st_wr_coarse_t;
                    write_lsb   <= '1';

                when st_wr_coarse_t =>                                          --write the coarse time of the trigger into the fifo, later add frame time
                    dbg_state_amc_if <= x"5";

                    if write_lsb = '1' then  --write lsb coarse_t
                        --frame_pl1(16 downto 0) <= coarse_t(37 downto 21);
                        write_lsb <= '0';
                    else                     --write msb coarse_t
                        rdout_state <= st_armed;
                        write_fifo  <= '0';
                    end if;

                when others =>
                    dbg_state_amc_if <= x"7";

                    rdout_state <= st_armed;

            end case;
        end if;


    end process;

    -- Instanza del normal sampling analyzer ...
    inst_ana_nrm : if gen_rdm(3) = '0' generate  --normal sampling mode                 
    begin

        inst_rd_ch : for rd_ch in 0 to adc_channels - 1 generate -- era 15
        begin

            read_fifo(rd_ch) <= rd_frame_ff(rd_ch);

            inst_ana_nrm : entity work.ana_nrm

            generic map (ch_no => rd_ch)

            port map (

                clk            => data_clk,
                frame_in       => data_out(rd_ch),
                frame_ff_empty => fifo_empty(rd_ch), 
                bos            => bos,

                baseline      => baseline,
                delay         => delay,
                frac          => frac,
                threshold     => threshold,
                cf_max_dist_i => cf_max_dist,
                sec_alg_is_on => sec_alg_is_on,
                before_zc_i   => before_zc,
                after_zc_i    => after_zc,

                prescaler_base => prescaler_base,
                framewidth     => framewidth_slv,  --framewidth,

                rd_frame_ff     => rd_frame_ff(rd_ch),                       
                event_data_out  => event_fifo_data(rd_ch),
                event_ff_empty  => event_fifo_empty(rd_ch),
                event_ff_full   => event_fifos_full(rd_ch),
                frame_fifo_full => buffer_fifos_full(rd_ch),
                rd_event_ff     => event_fifo_rden(rd_ch),
                event_ff_clk    => data_clk,

                reset         => reset_i,
                                    ---
                dbg_state_out => dbg_state_ana_ilm(rd_ch*4+3 downto rd_ch*4)

                );

        end generate;
    end generate;


    inst_ana_ilm : if gen_rdm(3) = '1' generate  --interleaved sampling mode

        signal bosync            : std_logic            := '0';
        signal fifo_data         : fifo_data_array_type := (others => (others => '0'));
        signal fifo_ctrl_empty   : fifo_ctrl_type       := (others => '0');
        signal fifo_ctrl_read_en : fifo_ctrl_type       := (others => '0');
        signal fifo_ctrl_rst     : fifo_ctrl_type       := (others => '0');

    begin

        inst_rd_ch : for rd_ch in 0 to adc_channels/2 - 1 generate -- era 7
        begin

            read_fifo(2*rd_ch)   <= rd_frame_ff(rd_ch);
            read_fifo(2*rd_ch+1) <= rd_frame_ff(rd_ch);

            inst_ana_ilm : entity work.ana_ilm

                generic map (ch_no => rd_ch)

                port map (

                    clk            => data_clk,
                    frame_in_r     => data_out(2*rd_ch),
                    frame_in_f     => data_out(2*rd_ch+1),
                    frame_ff_empty => fifo_empty(2*rd_ch),  ---!!! only one of two
                    bos            => bos,

                    baseline      => baseline,
                    delay         => delay,
                    frac          => frac,
                    threshold     => threshold,
                    cf_max_dist_i => cf_max_dist,
                    sec_alg_is_on => sec_alg_is_on,
                    before_zc_i   => before_zc,
                    after_zc_i    => after_zc,

                    prescaler_base => prescaler_base,
                    framewidth     => framewidth_slv,  --framewidth,

                    rd_frame_ff     => rd_frame_ff(rd_ch),
                    event_data_out  => event_fifo_data(rd_ch),
                    event_ff_empty  => event_fifo_empty(rd_ch),
                    event_ff_full   => event_fifos_full(rd_ch),
                    frame_fifo_full => buffer_fifos_full(rd_ch),
                    rd_event_ff     => event_fifo_rden(rd_ch),
                    event_ff_clk    => data_clk,

                    reset         => reset_i,
                                        ---
                    dbg_state_out => dbg_state_ana_ilm(rd_ch*4+3 downto rd_ch*4)

                    );

            inst_t_ana : if bs_t_trigger = true generate

                ana_tiger_inst : entity work.ana_tiger

                    port map (
                        clk             => adc_clk,
                        data_r          => data_i_pl1(2*rd_ch),
                        data_l          => data_i_pl1(2*rd_ch+1),
                        begin_of_spill  => bos_i,

                        t_baseline      => t_baseline,
                        t_fraction      => t_fraction,
                        t_delay         => t_delay,
                        t_threshold     => t_threshold,
                        t_cf_max_dist   => t_cf_max_dist,

                        self_trig       => self_trig_vec(rd_ch),

                        fifo_empty      => fifo_ctrl_empty(rd_ch),
                        fifo_rden       => fifo_ctrl_read_en(rd_ch),
                        fifo_rdclk      => vxs_clk_div,
                        fifo_data_out   => fifo_data(rd_ch),
                        fifo_reset      => fifo_ctrl_rst(rd_ch)
                        );

            end generate;

            --or between all self triggers                                      -- Alex & Pablo: non va da nessuna parte ...
            with self_trig_vec select
                any_self_trig <= '0' when "00000000",
                '1'                  when others;
        end generate;

        inst_t_if : if bs_t_trigger = true generate                             -- Alex & Pablo: non lo usiamo ... FALSE

            inst_vxs_link : entity work.vxs_link_trans

                generic map (
                    bos_period => -1
                    )

                port map (
                    vxs_clk_ddr_in => vxs_clk_ddr,
                    vxs_clk_div_in => vxs_clk_div,
                    bos_in         => bos,
                    vxs_data_q     => vxs_trigger_data,
                    bosync_q       => bosync,
                    start_cal_in   => vxs_fr_start_cal,
                    fifo_rst_q     => fifo_ctrl_rst,
                    fifo_empty_in  => fifo_ctrl_empty,
                    fifo_rd_en_q   => fifo_ctrl_read_en,
                    fifo_data_in   => fifo_data
                    );

        end generate;

    end generate;


    config_mem_bram_addr <= config_mem_bram_addr_i;

-- Da sistemare in funzione di active_channels ...
--
--with event_fifos_full(active_channels - 1 downto 0) select
--    some_event_fifo_full <= '0' when (others => '0'),
--    '1'                         when others;
--with buffer_fifos_full(active_channels - 1 downto 0) select
--    some_buffer_fifo_full <= '0' when (others => '0'),
--    '1'                          when others;
--with frame_fifos_full select
--    some_frame_fifo_full <= '0' when "00000000",
--    '1'                         when others;

some_event_fifo_full  <= '0' when event_fifos_full = zero_ct(active_channels - 1 downto 0) else '1';
some_buffer_fifo_full <= '0' when buffer_fifos_full = zero_ct(active_channels - 1 downto 0) else '1';
some_frame_fifo_full  <= '0' when frame_fifos_full = zero_ct(adc_channels - 1 downto 0) else '1';

any_fifo_full <= some_event_fifo_full or some_frame_fifo_full or some_buffer_fifo_full;

    ----------------------------------------------------------------------------------------------
    -- Legge le event fifo e scrive il dataout fifo 
    dataout_logic : process(data_clk)
        variable ch_no          : integer range 0 to 15;
        variable size           : unsigned(15 downto 0);
        variable event_size     : std_logic_vector(15 downto 0);
        variable dmode          : std_logic_vector(1 downto 0);
        variable fer            : std_logic;
        variable format         : std_logic_vector(7 downto 0);

        variable tmp_i          : integer range 0 to 8;
        variable channel_size   : std_logic_vector(14 downto 0);

    begin
        if rising_edge(data_clk) then
            slink_data <= (others => '0');
            slink_wen  <= '0';
            sysmon_i    <= sysmon;
            
            tcs_fifo_rden <= '0';

            if ready = '0' then
                ev_num_err <= '0';
            end if;
            
            if reset_i = '1' then
                ev_num_err    <= '0';
                sl_frame      <= 0;
                ch_counter    <= 0;
                ch_no         := ch_counter;

            elsif lff = '0' then                                                                        -- dataout fifo not full

                                        
                if bos = '1' then
                    first_ev_of_spill <= '1';
                end if;
                

                case sl_frame is
                    when 0 =>           -- sleep state, w8 for data in evt_f

                        if tcs_fifo_empty = '0' and flt_err = '0' and ev_num_err = '0' then
                            tcs_fifo_rden <= '1';
                            sl_frame <= 1;
                        end if;
                        size_calc_cnt <= 4;

                    when 1 =>  -- sm in sm, with size_calc_cnt being state var
                               --~ TODO case size_calc_cnt
                        if to_integer(unsigned(event_fifo_empty)) = 0 then  -- if all fifos had data    -- Paolo: quando tutte le EVENT FIFO hanno dati vengono lette in parallelo
                            if size_calc_cnt = 4 then  -- enable event fifo readenable (TODO check if state is obsolete)  
                                event_fifo_rden <= (others => '1');
                                size_calc_cnt <= 3;
                            end if;
                        end if;
                        if size_calc_cnt = 3 then                                                
                            for i in 0 to active_channels - 1 loop                                      -- Alex: aggiunta variabile per il numero di canali da leggere
                            -- for i in 0 to adc_channels/2 - 1 loop                                    -- Paolo: per ogni canale si controlla la size e si decide se ha hit
                                event_fifo_rden(i) <= '0';
                                if event_fifo_data(i)(11 downto 0) /= x"000" then
                                    channel_has_hits(i) <= '1';
                                else
                                    channel_has_hits(i) <= '0';
                                end if;
                                ch_sz(i) <= event_fifo_data(i)(11 downto 0);                            -- Paolo: si carica lib ch_sz la dimensione dei dati presenti nella EVENT FIFO
                            end loop;

                            for i in 0 to  active_channels/2 - 1 loop                                   -- Paolo: si somma la size di due canali
                                two_ch_sz(i) <= event_fifo_data(i)(12 downto 0) + event_fifo_data(i+active_channels/2)(12 downto 0);
                            end loop;

                            if event_fifo_data(0)(30) = '0' then  -- frame or debug?
                                is_normal_mode <= 1;              -- frame
                            else
                                is_normal_mode <= 0;              --debug
                            end if;

                            size_calc_cnt    <= 2;

                        end if;

                        if size_calc_cnt = 2 then

                            channel_int <= (others => 0);
                            tmp_i       := 0;
                            for i in 0 to active_channels - 1 loop                          -- Paolo: si crea un vettore che contiene il numero dei canali che hanno hit
                                if channel_has_hits(i) = '1' then
                                    channel_int(tmp_i) <= i;                                -- contains ordered numbers of non-empty channels
                                    tmp_i              := tmp_i+1;
                                end if;
                            end loop;
                            
                            -- keep in mind addition is expensive inside FPGA               -- Modificata somma brutale Alex 
                            channel_size := (others => '0'); 
                            for i in 0 to  active_channels/2 - 1 loop                       -- Paolo: si somma la size di due "doppi" canali 
                                channel_size := channel_size + ("00" & two_ch_sz(i));
                            end loop;
                                    
                            all_ch_size <= channel_size;

                            slink_data <= b"1" & x"00000000";  -- start word                -- Paolo: prima parola su slink_data
                            slink_wen  <= '1';
                            sl_frame   <= 2;
                        end if;

                    when 2 =>           --sl header i


                        -- Alex & Paolo: Non serve piu' guardare gen_rdm(3) ...                                            
                        --if gen_rdm(3) = '0' then        --normal sampling mode        
                        --    event_size(15 downto 0) := std_logic_vector(to_unsigned((framewidth+2)*adc_channels + 3, 16));        -- sbagliato da indicizzare (adc_channels)...

                        -- elsif gen_rdm(3) = '1' then     --interleaved mode                   
                            if is_normal_mode = 0 then  -- debug frame                                                          
                                event_size(15 downto 0) := std_logic_vector(to_unsigned(2 * active_channels + 3, 16)) + ('0' & all_ch_size);    -- 3 parole di header, (1 debug heather + 1 debug trailer) x canale + 
                                dmode                   := b"10";  -- TODO change to signal or remove
                            else
                                event_size(15 downto 0) := std_logic_vector(to_unsigned(3, 16)) + ('0' & all_ch_size);          -- Alex & Paolo: OK
                                dmode                   := b"00";
                            end if;
                        -- end if;
                        
                        -- in case of triggers that are generated at begin/end of spill/run,
                        -- we only put a header event on the slink
                        case event_type is

                            when "11100" | "11101" | "11110" | "11111" => 
                                begin_end_trig <= '1';
                                event_size := std_logic_vector(to_unsigned(3, 16));

                            when others => begin_end_trig <= '0';

                        end case;


                        slink_data <= "0" & tcs_error_flag & event_type & src_id & event_size;          -- Paolo: seconda  parola su slink_data
                        slink_wen  <= '1';
                        sl_frame   <= 3;

                        if event_type = b"11100" then
                            fer := '1';  -- first event of run, TODO rename
                        else
                            fer := '0';
                        end if;

                    when 3 =>           --sl header ii
                        slink_data <= b"0" & "0" & spill_no & event_no;                                 -- Paolo: terza  parola su slink_data
                        slink_wen  <= '1';
                        sl_frame   <= 4;
                        if first_ev_of_spill = '1' then
                            first_ev_of_spill <= '0';
                            if event_no /= std_logic_vector(to_unsigned(1, 20)) then                    --Paolo: sembra generare errore se l'event_no è diverso da 1???????
                                ev_num_err <= '1';                                                      --speriamo sia giusto ...
                            else
                                ev_num_err <= '0';
                            end if;
                        end if;


                    when 4 =>           --sl header iii
                        format     := fer & b"001" & gen_rdm(3) & dmode & b"0";         --first evt run & g_adc & nml/ilm & nml/debug data & adc readout
                        slink_data <= '0' & format & x"00" & x"08" & tcs_status;        --format & errorwords & tcs_error & status TODO maybe change hardcoded stuff here 
                                                                                        -- Paolo: quarta  parola su slink_data
                        slink_wen  <= '1';
                        if is_normal_mode = 0 then  --debug mode
                            sl_frame <= 5;
                        else            --proc mode

                            if all_ch_size /= 0 then                                    -- Paolo: legge la prima EVENT FIFO con dati
                                event_fifo_rden(channel_int(ch_counter)) <= '1';
                                sl_frame                                 <= 6;
                            else
                                sl_frame <= 8;
                            end if;

                        end if;

                    when 5 =>           --header words if debug mode

                        if active_channels = 4 then
                            ch_no      := ch_counter * 2;
                        else
                            ch_no      := ch_counter;
                        end if;
                                                                                                    -- Paolo: quinta  parola su slink_data se in debug
                        slink_data <= b"000" & event_no(5 downto 0)                                 --decode header & event no   
                                      & std_logic_vector(to_unsigned(ch_no, 4)) & sysmon_i          --ch & sys mon
                                      & std_logic_vector(to_unsigned(framewidth, 11)) & gen_rdm;    --framewidth & readout mode
                        slink_wen <= '1' and not begin_end_trig;

                        
                        event_fifo_rden(ch_counter) <= '1';                                         -- Paolo: in debug sembra leggere tutti i canali anche quelli che non hanno hit                                    
                        sl_frame <= 6;

                    when 6 =>                               --data words in debug & proc mode

                        if is_normal_mode = 0 then                                              -- paolo: debug mode
                            event_fifo_rden(ch_counter) <= '1';  ---!!!!!!!!!!!!!!!!!!
                            slink_data                  <= b"01" & event_fifo_data(ch_counter);  --decode data & event_fifo_data from ana_ilm.vhd
                            slink_wen                   <= '1' and not begin_end_trig;
                            if ch_sz(ch_counter) /= 1 then                                      -- paolo:  legge tutta la EVENT FIFO del canale "ch_counter"
                                ch_sz(ch_counter) <= ch_sz(ch_counter)-1;
                            else
                                event_fifo_rden(ch_counter) <= '0';
                                sl_frame                    <= 7;  --add trailer for debug data mode
                            end if;
                        else        -- GO ON HERE in proc mode
                            event_fifo_rden(channel_int(ch_counter)) <= '1';  --!!!!!!!!!!!!!!!!!!!!!!!!
                            slink_data                               <= b"01" & event_fifo_data(channel_int(ch_counter));  --decode data & event_fifo_data from ana_ilm.vhd
                            slink_wen                                <= '1' and not begin_end_trig;
                            if ch_sz(channel_int(ch_counter)) /= 1 and ch_sz(channel_int(ch_counter)) /= 0 then     -- paolo: legge tutta la EVENT FIFO del canale con dati
                                ch_sz(channel_int(ch_counter)) <= ch_sz(channel_int(ch_counter))-1;
                            else
                                if ch_counter < active_channels - 1 then                                                   -- paolo:   scorre tutte i canali che hanno dati, aggiornando
                                    if channel_int(ch_counter+1) /= 0 then                                          --          il ch_counter 
                                        ch_counter                                 <= ch_counter+1;                 --          il 7 va indicizzato 
                                        event_fifo_rden(channel_int(ch_counter))   <= '0';
                                        event_fifo_rden(channel_int(ch_counter+1)) <= '1';
                                    else
                                        event_fifo_rden(channel_int(ch_counter)) <= '0';
                                        sl_frame                                 <= 8;
                                        ch_counter                               <= 0;
                                    end if;
                                else
                                    event_fifo_rden(channel_int(ch_counter)) <= '0';
                                    sl_frame                                 <= 8;
                                    ch_counter                               <= 0;
                                end if;
                            end if;
                        end if;

                    when 7 =>           --trailer word if debug mode
                        
                        if ch_counter /= (active_channels - 1) then  --go to header write next channel ... era 15 ...  
                            ch_counter <= ch_counter + 1;
                            sl_frame   <= 5;
                        else        --debug readout finished for this event
                            ch_counter <= 0;
                            sl_frame   <= 8;
                        end if;

                        slink_data <= b"001" & event_no(5 downto 0)                                 --decode trailer & event no
                                      & std_logic_vector(to_unsigned(ch_no, 4)) & sysmon_i          --ch & sys mon
                                      & std_logic_vector(to_unsigned(framewidth, 11)) & gen_rdm;    --framewidth & readout mode
                        slink_wen <= '1' and not begin_end_trig;

                    when 8 =>           --finish event
                        sl_frame   <= 0;
                        slink_data <= b"1" & x"cfed1200";  -- end word
                        slink_wen  <= '1';
                        sl_frame   <= 0;

                    when 9 =>
                        sl_frame      <= 0;

                    when others =>
                        sl_frame <= 0;
                end case;
            else
                event_fifo_rden <= (others => '0');
                
            end if;
        end if;
    end process;
    
    
    -- Alex: corretto in funzione di adc_channels
    -- biterr_concat : if True generate        
    --     signal biterr_ch_i  : std_logic_vector(adc_channels - 1 downto 0); -- era 15
    -- begin       
    --     biterr_concat_loop : for chan in 0 to adc_channels - 1 generate -- era 15
    --         biterr_ch_i(chan) <= '1' when data_latch(chan)(11 downto 2) /= ("0000000000") else '0';
    --     end generate;
    --     biterr_flag <= '1' when biterr_ch_i /= zero_ct(adc_channels - 1 downto 0) else '0';  -- era x"0000"
    -- end generate;
    
    
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
                    cfmem_wb_addr  <= std_logic_vector(gndlf_addr_offset+gandalf_configuration);
                    if cfmem_wb_ack = '1' then
                        cfmem_logic <= st_baseline;
                    else
                        cfmem_wb_cyc <= '1';
                        cfmem_wb_stb <= '1';
                    end if;
                when st_baseline =>
                    baseline       <= cfmem_wb_din(10 downto 0);
                    prescaler_base <= cfmem_wb_din(19 downto 12);
                    cfmem_wb_addr  <= std_logic_vector(gndlf_addr_offset+basl_val_addr_offset);
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
                    cfmem_wb_addr <= std_logic_vector(gndlf_addr_offset+gandalf_configuration)+b"101";
                    if cfmem_wb_ack = '1' then
                        cfmem_logic <= st_t_cfd;
                    else
                        cfmem_wb_cyc <= '1';
                        cfmem_wb_stb <= '1';
                    end if;
                when st_t_cfd =>
                    t_threshold   <= cfmem_wb_din(28 downto 16);
                    cfmem_wb_addr <= std_logic_vector(gndlf_addr_offset+tiger_ana_configuration);
                    if cfmem_wb_ack = '1' then
                        cfmem_logic <= st_t_max_dist;
                    else
                        cfmem_wb_cyc <= '1';
                        cfmem_wb_stb <= '1';
                    end if;
                when st_t_max_dist =>
                    t_cf_max_dist <= cfmem_wb_din(2 downto 0);
                    cf_max_dist   <= cfmem_wb_din(6 downto 4);
                    cfmem_wb_addr <= std_logic_vector(gndlf_addr_offset+tiger_ana_configuration + "01");
                    if cfmem_wb_ack = '1' then
                        cfmem_logic <= st_wait;
                    else
                        cfmem_wb_cyc <= '1';
                        cfmem_wb_stb <= '1';
                    end if;
                                        --~ when st_write_bos_flt =>
                                        --~ if cfmem_wb_ack = '1' then
                                        --~ cfmem_logic <= st_wait;
                                        --~ else
                                        --~ cfmem_wb_we   <= x"f";
                                        --~ cfmem_wb_cyc  <= '1';
                                        --~ cfmem_wb_stb  <= '1';
                                                 --~ cfmem_wb_dout <= bos_count & b"0000" & flt_count;
                                                 --~ end if;
                when st_changedelays =>
                    if (del_load_cnt = 13) then -- Alex era 16 ...
                        cfmem_logic <= st_wait;
                        del_action  <= '1';
                    end if;
                    if cfmem_wb_ack = '1' then
                        del_load_cnt               <= del_load_cnt + 1;
                        del_settings(del_load_cnt) <= cfmem_wb_din(31 downto 0);
                    else
                        cfmem_wb_we   <= x"0";
                        cfmem_wb_addr <= std_logic_vector(amc_del_set_offset + to_unsigned(del_load_cnt, 5));
                        cfmem_wb_cyc  <= '1';
                        cfmem_wb_stb  <= '1';
                    end if;
                when st_writeedges =>
                    if (del_load_cnt = 13) then -- Alex era 16 ...
                        cfmem_logic <= st_wait;
                    end if;
                    if cfmem_wb_ack = '1' then
                        del_load_cnt <= del_load_cnt + 1;
                    else
                        cfmem_wb_we                <= x"f";
                        cfmem_wb_addr              <= std_logic_vector(amc_del_edge_offset + to_unsigned(del_load_cnt, 5));
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
