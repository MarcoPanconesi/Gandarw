-------------------------------------------------------------------------------
-- Title	  : wrapper for the wb_iic core when using SI5326
-- Project	  : test project
-------------------------------------------------------------------------------
-- File		  : si_iic_wrapper.vhd
-- Author	  :	  <grussy@pcfr16.physik.uni-freiburg.de>
-- Company	  : 
-- Created	  : 2013-06-20
-- Last update: 2013-08-22
-- Platform	  : 
-- Standard	  : VHDL'93
-------------------------------------------------------------------------------
-- Description: Wrapper wb_iic interface connected to the SI5326 Chips and the
-- si interface module. Use like a wishbone interface. Only one address at a
-- time. Supports read and write.
-------------------------------------------------------------------------------
-- Copyright (c) 2013 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date		   Version	Author	Description
-- 2013-06-20  1.0		grussy	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity si_iic_wrapper is
	port (
		clk		   : in	 std_logic;
-------------------------------------------------------------------------------
-- to si interface
		stb		   : in	 std_logic;
		we		   : in	 std_logic;
		err		   : out std_logic;
		ack		   : out std_logic;
		reg_addr   : in	 std_logic_vector(7 downto 0);
		write_data : in	 std_logic_vector(7 downto 0);
		read_data  : out std_logic_vector(7 downto 0);
		si_nr	   : in	 std_logic_vector(2 downto 0);
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- to wishbone iic interface
		wb_rst_i  : out std_logic := '0';
		arst_i	  : out std_logic := '0';
		wb_adr_i  : out std_logic_vector(2 downto 0);
		wb_dat_i  : out std_logic_vector(7 downto 0);
		wb_dat_o  : in	std_logic_vector(7 downto 0);
		wb_we_i	  : out std_logic;
		wb_stb_i  : out std_logic;
		wb_cyc_i  : out std_logic;
		wb_ack_o  : in	std_logic;
		wb_inta_o : in	std_logic
-------------------------------------------------------------------------------		
		);

end entity si_iic_wrapper;

-------------------------------------------------------------------------------

architecture behav of si_iic_wrapper is
-------------------------------------------------------------------------------
-- wb registers
	constant addr_clock_prescaler_low  : std_logic_vector(2 downto 0) := "000";
	constant addr_clock_prescaler_high : std_logic_vector(2 downto 0) := "001";
	constant addr_control			   : std_logic_vector(2 downto 0) := "010";
	constant addr_transmit			   : std_logic_vector(2 downto 0) := "011";
	constant addr_receive			   : std_logic_vector(2 downto 0) := "011";
	constant addr_command			   : std_logic_vector(2 downto 0) := "100";
	constant addr_status			   : std_logic_vector(2 downto 0) := "100";
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- si slave serial nr.
	constant slave_const : std_logic_vector(3 downto 0) := "1101";
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- prescalers
-- calc with: inclk / ( 5 * iic_clk ) - 1 = (h & l); 018f = 200Mhz input,100khz iic
-- Alex: con 40Mhz di inclk e 1Mhz di iic prescale := x"0007" 
--       con 40Mhz di inclk e 400Khz di iic prescale := x"0013" 
--       con 40Mhz di inclk e 100Khz di iic prescale := x"004F" 
    constant prescale_h : std_logic_vector(7 downto 0) := x"00"; -- era x"01";
	constant prescale_l : std_logic_vector(7 downto 0) := x"4F"; -- era x"8f";
------------------------------------------------------------------------------- 


-------------------------------------------------------------------------------
-- registered signals
	signal we_i : std_logic := '0';

	signal reg_addr_i	: std_logic_vector(7 downto 0) := (others => '0');
	signal write_data_i : std_logic_vector(7 downto 0) := (others => '0');
	signal si_nr_i		: std_logic_vector(2 downto 0) := (others => '0');
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- state machine
	type state_type is (
		startup,
		disable_core,
		set_scaler_h,
		set_scaler_l,
		enable_core,
		sleep,
		slave_addr_write,				--write slave addr, set rw bit to 0
		slave_addr_read,				--write slave addr, set rw bit to 1
		start_bit,
		stop_bit_write,
		stop_bit_read,
		write_bit,
		wait_no_tip,
		wait_no_tip_nack,
		read_ack,
		write_reg_addr,
		ack_state,
		err_state,
		wait_one,
		write_data_state,
		read_data_state
		);
	signal state	  : state_type := startup;
	signal next_state : state_type := sleep;
------------------------------------------------------------------------------- 

begin  -- architecture behav
-------------------------------------------------------------------------------
-- si state machine
	process
	begin
		wait until rising_edge(clk);
										--defaults
		ack <= '0';
		err <= '0';

		wb_we_i	 <= '0';
		wb_stb_i <= '0';
		wb_cyc_i <= '0';

		wb_adr_i <= (others => '0');
		wb_dat_i <= (others => '0');

		case state is
-- startup
			when startup =>
				state <= disable_core;

			when disable_core =>
				if wb_ack_o = '1' then
					state <= set_scaler_h;
				else
					wb_cyc_i <= '1';
					wb_stb_i <= '1';
					wb_adr_i <= addr_control;
					wb_dat_i <= x"00";
					wb_we_i	 <= '1';
				end if;

			when set_scaler_h =>
				if wb_ack_o = '1' then
					state <= set_scaler_l;
				else
					wb_cyc_i <= '1';
					wb_stb_i <= '1';
					wb_adr_i <= addr_clock_prescaler_high;
					wb_dat_i <= prescale_h;
					wb_we_i	 <= '1';
				end if;

			when set_scaler_l =>
				if wb_ack_o = '1' then
					state <= enable_core;
				else
					wb_cyc_i <= '1';
					wb_stb_i <= '1';
					wb_adr_i <= addr_clock_prescaler_low;
					wb_dat_i <= prescale_l;
					wb_we_i	 <= '1';
				end if;
				
			when enable_core =>
				if wb_ack_o = '1' then
					state <= sleep;
				else
					wb_cyc_i <= '1';
					wb_stb_i <= '1';
					wb_adr_i <= addr_control;
					wb_dat_i <= x"80";
					wb_we_i	 <= '1';
				end if;

-- sleep
			when sleep =>
				if stb = '1' then
					state		 <= slave_addr_write;
					next_state	 <= write_reg_addr;
										--register the data and address
					we_i		 <= we;
					reg_addr_i	 <= reg_addr;
					si_nr_i		 <= si_nr;
					write_data_i <= write_data;
				end if;

-- common states
			when slave_addr_write =>
				if wb_ack_o = '1' then
					state <= start_bit;
				else
					wb_cyc_i <= '1';
					wb_stb_i <= '1';
					wb_adr_i <= addr_transmit;
					wb_dat_i <= slave_const & si_nr_i & '0';
					wb_we_i	 <= '1';
				end if;

			when slave_addr_read =>
				if wb_ack_o = '1' then
					state	   <= start_bit;
					next_state <= stop_bit_read;
				else
					wb_cyc_i <= '1';
					wb_stb_i <= '1';
					wb_adr_i <= addr_transmit;
					wb_dat_i <= slave_const & si_nr_i & '1';
					wb_we_i	 <= '1';
				end if;
				
			when start_bit =>
				if wb_ack_o = '1' then
					state <= wait_no_tip;
				else
					wb_cyc_i <= '1';
					wb_stb_i <= '1';
					wb_adr_i <= addr_command;
					wb_dat_i <= x"90";	-- STA,WR
					wb_we_i	 <= '1';
				end if;

			when stop_bit_write =>
				if wb_ack_o = '1' then
					state <= wait_no_tip;
				else
					wb_cyc_i <= '1';
					wb_stb_i <= '1';
					wb_adr_i <= addr_command;
					wb_dat_i <= x"50";	-- STO,WR
					wb_we_i	 <= '1';
				end if;

			when stop_bit_read =>
				if wb_ack_o = '1' then
					state <= wait_no_tip_nack;
				else
					wb_cyc_i <= '1';
					wb_stb_i <= '1';
					wb_adr_i <= addr_command;
					wb_dat_i <= x"68";	-- STO,RD,NACK
					wb_we_i	 <= '1';
				end if;

			when write_bit =>
				if wb_ack_o = '1' then
					state <= wait_no_tip;
				else
					wb_cyc_i <= '1';
					wb_stb_i <= '1';
					wb_adr_i <= addr_command;
					wb_dat_i <= x"10";
					wb_we_i	 <= '1';
				end if;

			when wait_no_tip =>
				if wb_ack_o = '1' and wb_dat_o(1) = '0' then
					state <= read_ack;
				else
					wb_cyc_i <= '1';
					wb_stb_i <= '1';
					wb_adr_i <= addr_status;
				end if;

			when wait_no_tip_nack =>
				if wb_ack_o = '1' and wb_dat_o(1) = '0' then
					state <= read_data_state;
				else
					wb_cyc_i <= '1';
					wb_stb_i <= '1';
					wb_adr_i <= addr_status;
				end if;

			when read_ack =>
				if wb_ack_o = '1' then
					if wb_dat_o(7) = '0' then
										--ack received!
						state <= next_state;
					else
						state <= err_state;
					end if;
				else
					wb_cyc_i <= '1';
					wb_stb_i <= '1';
					wb_adr_i <= addr_status;
				end if;

			when write_reg_addr =>
				if wb_ack_o = '1' then
					state <= write_bit;
					if we_i = '1' then
						next_state <= write_data_state;
					else
						next_state <= slave_addr_read;
					end if;
				else
					wb_cyc_i <= '1';
					wb_stb_i <= '1';
					wb_adr_i <= addr_transmit;
					wb_dat_i <= reg_addr_i;
					wb_we_i	 <= '1';
				end if;

			when ack_state =>
				ack	  <= '1';
				state <= wait_one;

			when err_state =>
				err	  <= '1';
				ack	  <= '1';
				state <= wait_one;

			when wait_one =>
				state <= sleep;

-- write states
			when write_data_state =>
				if wb_ack_o = '1' then
					state	   <= stop_bit_write;
					next_state <= ack_state;
				else
					wb_cyc_i <= '1';
					wb_stb_i <= '1';
					wb_adr_i <= addr_transmit;
					wb_dat_i <= write_data_i;
					wb_we_i	 <= '1';
				end if;

-- read states
			when read_data_state =>
				if wb_ack_o = '1' then
					state	  <= ack_state;
					read_data <= wb_dat_o;
				else
					wb_cyc_i <= '1';
					wb_stb_i <= '1';
					wb_adr_i <= addr_receive;
				end if;
		end case;
	end process;
-------------------------------------------------------------------------------
end architecture behav;


