-------------------------------------------------------------------------------
-- Title	  : Testbench for design "gp_if"
-- Project	  : test project
-------------------------------------------------------------------------------
-- File		  : gp_if_tb.vhd
-- Author	  : Philipp	 <philipp@pcfr58.physik.uni-freiburg.de>
-- Company	  : 
-- Created	  : 2013-08-16
-- Last update: 2013-09-05
-- Platform	  : 
-- Standard	  : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2013 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date		   Version	Author	Description
-- 2013-08-16  1.0		philipp Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
--  This package defines supplemental types, subtypes, 
--  constants, and functions 
use WORK.top_level_desc.all;

-- All the project parameters here ...
-- removed all the generic from top vhdl
use WORK.G_PARAMETERS.all;

-------------------------------------------------------------------------------

entity gp_if_tb is

end entity gp_if_tb;

-------------------------------------------------------------------------------

architecture behv of gp_if_tb is

	signal clk					 : std_logic					  := '0';
	signal SCL					 : std_logic_vector(1 downto 0);
	signal SDA					 : std_logic_vector(1 downto 0)	  := (others => '0');
	signal rd_temps				 : std_logic					  := '0';
    signal rd_stats              : std_logic                      := '0';
	signal write_eeprom_to_cfmem : std_logic					  := '0';
	signal write_cfmem_to_eeprom : std_logic					  := '0';
	signal set_DACs				 : std_logic					  := '0';
    signal set_IPs               : std_logic                      := '0';
	signal INIT_GP				 : std_logic					  := '0';
	signal cfmem_wb_ack			 : std_logic					  := '0';
	signal cfmem_wb_din			 : std_logic_vector (31 downto 0) := (others => '0');

	signal cfmem_wb_cyc	 : std_logic;
	signal cfmem_wb_stb	 : std_logic;
	signal cfmem_wb_we	 : std_logic_vector ( 3 downto 0);
	signal cfmem_wb_addr : std_logic_vector ( 9 downto 0);
	signal cfmem_wb_dout : std_logic_vector (31 downto 0);

    signal cfmem_bram_wen   : std_logic_vector( 3 downto 0);
    signal cfmem_bram_addr  : std_logic_vector(15 downto 0);
    signal cfmem_bram_din   : std_logic_vector(31 downto 0);
    signal cfmem_bram_dout  : std_logic_vector(31 downto 0);

	signal startup	 : std_logic := '0';
	signal wait_done : std_logic := '0';
	signal wait_one : std_logic := '0';
	
    -- wishbone busses signals
    constant num_of_wb_bus      : integer := 1; 
    signal wb                   : wb_busses(num_of_wb_bus - 1 downto 0);
    signal wb_in                : wb_mosi(num_of_wb_bus - 1 downto 0);
    signal wb_out               : wb_miso(num_of_wb_bus - 1 downto 0);

begin  -- architecture behv

	clk <= not clk after 5 ns;
										--cfmem_wb_ack <= not cfmem_wb_ack after 10 ns;

-- cpld interface
cpld_if : entity work.cpld_if
    generic map(
        gen_accel_sim             => true
    )
    port map(
        control                   => open,
        -- this signals are directly connected to io pins
        d                         => open,                  -- data bus to/from cpld
        f_write                   => '0',                   -- flag from cpld
        f_strobe                  => '0',                   -- flag from cpld
        f_ready                   => open,                  -- flag to cpld
        f_control                 => '0',                   -- flag from cpld
        f_ublaze                  => '0',                   -- flag from cpld
        f_fifofull                => open,                  -- flag to cpld
        f_fifoempty               => open,                  -- flag to cpld
        f_reset                   => '0',                   -- reset from cpld
        clk_40mhz_vdsp            => clk,                   -- 40 mhz system clock inp
        pll_200_locked            => open,

        -- connect this signals to your logic
        clk_40mhz_out             => open,                  -- 40 mhz clock output
        nclk_40mhz_out            => open,                  -- inverted 40 mhz clock o
        clk_120mhz_out            => open,                  -- 120 mhz clock output
        clk_200mhz_out            => open,                  -- 200 mhz clock output
        slink_init_done           => '1',                   -- startup_sequence finish
        si_init_done              => '1',
        gp_init_done              => '1',
        si_flags                  => b"000000000",     
        rst_startup_1_out         => open,                  -- this reset is released 
        rst_startup_2_out         => open,                  -- this reset is released 
        rst_startup_3_out         => open,                  -- this reset is released 
        -- spyfifo        
        spy_din                   => X"00000000",
        spy_clk                   => clk,
        spy_wr                    => '0',
        spy_rst                   => '0',
        spy_full                  => open,
        spy_almost_full           => open,
        -- config memory block ram
        config_mem_bram_rst       => '0',
        config_mem_bram_clk       => clk,
        config_mem_bram_en        => '0',
        config_mem_bram_wen       => cfmem_bram_wen,
        config_mem_bram_addr      => cfmem_bram_addr,
        config_mem_bram_din       => cfmem_bram_din,
        config_mem_bram_dout      => cfmem_bram_dout,
        fastregister              => open
    );


cfmem_wb : entity work.wb_to_ram
    generic map (
        data_width          => 32,
        addr_width          => 10,
        n_port              => num_of_wb_bus)
    port map (
--      control             => contrfr_conf_siol,
        mem_clka            => open,
        mem_wea             => cfmem_bram_wen,
        mem_addra           => cfmem_bram_addr,
        mem_dina            => cfmem_bram_din,
        mem_douta           => cfmem_bram_dout,
        wb_clk              => clk,
        wb_rst              => '0',
        wb_mosi             => wb_in,
        wb_miso             => wb_out
    );

-- union of records bus
wb_concat:
for i in 0 to num_of_wb_bus - 1 generate
    -------------------------------------- MASTER IN
    wb_out(i).cyc   <= cfmem_wb_cyc; 
    wb_out(i).stb   <= cfmem_wb_stb; 
    wb_out(i).we    <= cfmem_wb_we; 
    wb_out(i).adr   <= cfmem_wb_addr; 
    wb_out(i).dat_i <= cfmem_wb_dout; 
    -------------------------------------- MASTER OUT
    cfmem_wb_ack    <= wb_in(i).ack; 
    cfmem_wb_din   <= wb_in(i).dat_o; 
end generate;

    DUT : entity work.gp_if
    generic map (
        SIM                     => true)
    port map (
        clk					    => clk,
        SCL					    => SCL,
        SDA					    => SDA,
        rd_temps			    => rd_temps,
        rd_stats                => rd_stats,
        set_DACs			    => set_DACs,
        set_IPs                 => set_IPs,
        write_eeprom_to_cfmem   => write_eeprom_to_cfmem,
        write_cfmem_to_eeprom   => write_cfmem_to_eeprom,
        INIT_GP				    => INIT_GP,
        cfmem_wb_cyc		    => cfmem_wb_cyc,
        cfmem_wb_stb		    => cfmem_wb_stb,
        cfmem_wb_we			    => cfmem_wb_we,
        cfmem_wb_ack		    => cfmem_wb_ack,
        cfmem_wb_addr		    => cfmem_wb_addr,
        cfmem_wb_din		    => cfmem_wb_din,
        cfmem_wb_dout		    => cfmem_wb_dout);


process
	begin

		if wait_done = '0' then
			wait for 8600 ns;
			wait_done <= '1';
		end if;

		wait until rising_edge(clk);

		if startup = '0' then
			startup	<= '1';
			--rd_temps              <= '1';
            rd_stats              <= '1';
			--set_DACs                <= '1';
            --set_IPs               <= '1';
			--write_cfmem_to_eeprom <= '1';
			--write_eeprom_to_cfmem <= '1';
			--INIT_GP               <= '1';
		else
			rd_temps                <= '0';
            rd_stats                <= '0';
			set_DACs                <= '0';
            set_IPs                 <= '0';
			write_cfmem_to_eeprom   <= '0';
			write_eeprom_to_cfmem   <= '0';
			INIT_GP                 <= '0';
		end if;

		-- if cfmem_wb_stb = '1' then
		-- 	cfmem_wb_ack <= '1';			
		-- else
		-- 	cfmem_wb_ack <= '0';
		-- end if;


										--wait;
	end process;

end architecture behv;
