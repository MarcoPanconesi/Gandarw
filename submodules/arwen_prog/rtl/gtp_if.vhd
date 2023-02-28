-------------------------------------------------------------------------------
-- Title	  : gtp interface to mem fpga
-- Project	  : test project
-------------------------------------------------------------------------------
-- File		  : gtp_if.vhd
-- Author	  :	  <grussy@pcfr16.physik.uni-freiburg.de>
-- Company	  : 
-- Created	  : 2013-03-07
-- Last update: 2013-03-26
-- Platform	  : 
-- Standard	  : VHDL'93
-------------------------------------------------------------------------------
-- Description: 
-------------------------------------------------------------------------------
-- Copyright (c) 2013 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date		   Version	Author	Description
-- 2013-03-07  1.0		grussy	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

use WORK.G_PARAMETERS.all;

-------------------------------------------------------------------------------

entity gtp_if is
	port (
        control                : inout std_logic_vector(35 downto 0);
        reset                  : in std_logic;
-------------------------------------------------------------------------------
-- binfile request and fifo out
		start_reading_in	   : in	 std_logic;
		start_addr_in		   : in	 std_logic_vector(28 downto 0);
		end_addr_in			   : in	 std_logic_vector(28 downto 0);
		binfile_fifo_rd_clk_in : in	 std_logic;
		binfile_fifo_data_out  : out std_logic_vector(33 downto 0);
		binfile_fifo_empty_out : out std_logic;
		binfile_fifo_valid_out : out std_logic;
		binfile_fifo_ren_in	   : in	 std_logic;
-------------------------------------------------------------------------------		

-------------------------------------------------------------------------------
-- tranceiver lanes
		gtp_clk_in	: in  std_logic;
		tx_data_out : out std_logic_vector(15 downto 0);
		rx_data_in	: in  std_logic_vector(15 downto 0);
		tx_isk_out	: out std_logic_vector(1 downto 0);
		rx_isk_in	: in  std_logic_vector(1 downto 0)
-------------------------------------------------------------------------------
		);

end entity gtp_if;
architecture behav of gtp_if is

-------------------------------------------------------------------------------
-- constants
	constant idle_word		: std_logic_vector(15 downto 0) := x"5c" & x"5c";
	constant comma_word		: std_logic_vector(15 downto 0) := x"bc" & x"bc";
	constant busy_word		: std_logic_vector(15 downto 0) := x"1c" & x"1c";
	constant notbusy_word	: std_logic_vector(15 downto 0) := x"f7" & x"f7";
	constant start_addr_cmd : std_logic_vector(15 downto 0) := x"fb" & x"fb";
	constant end_addr_cmd	: std_logic_vector(15 downto 0) := x"fd" & x"fd";
	constant finished_cmd	: std_logic_vector(15 downto 0) := x"fe" & x"fe";
------------------------------------------------------------------------------- 

-------------------------------------------------------------------------------
-- fifo
	component binfile_fifo
		port (
			rst	        : in  std_logic;
			wr_clk	    : in  std_logic;
			rd_clk	    : in  std_logic;
			din		    : in  std_logic_vector(16 downto 0);
			wr_en	    : in  std_logic;
			rd_en	    : in  std_logic;
			dout	    : out std_logic_vector(33 downto 0);
			full	    : out std_logic;
			prog_full   : out std_logic;
			empty	    : out std_logic;
			valid	    : out std_logic
			);
	end component;

	signal binfile_fifo_din		  : std_logic_vector(16 downto 0);
	signal binfile_fifo_wr_en	  : std_logic;
	signal binfile_fifo_prog_full : std_logic;
------------------------------------------------------------------------------- 

-------------------------------------------------------------------------------
-- sending
	signal start_reading	: std_logic					   := '0';
	signal start_reading_sr : std_logic_vector(1 downto 0) := "00";

	signal busy_sr : std_logic_vector(1 downto 0) := "00";

	signal comma_cnt : unsigned(4 downto 0) := "11111";
	signal comma_en	 : std_logic			:= '0';

	signal start_addr : std_logic_vector(28 downto 0) := (others => '0');
	signal end_addr	  : std_logic_vector(28 downto 0) := (others => '1');

	type send_state_type is (
		idle,
		send_start_addr,
		send_start_addr1,
		send_start_addr2,
		send_end_addr,
		send_end_addr1,
		send_end_addr2,
		receive
		);
	signal send_state : send_state_type := idle;
-------------------------------------------------------------------------------
-- chipscope
component gtp_if_ila
    port (
        control     : inout std_logic_vector(35 downto 0);
        clk         : in    std_logic;
        data        : in    std_logic_vector(63 downto 0);
        trig0       : in    std_logic_vector(15 downto 0)
        );
end component;

signal ila_data                 : std_logic_vector(63 downto 0);
signal ila_trg	                : std_logic_vector(15 downto 0);

signal tx_data_out_i            : std_logic_vector(15 downto 0);

signal binfile_fifo_empty_out_i : std_logic;
signal binfile_fifo_valid_out_i : std_logic;
-------------------------------------------------------------------------------



	
begin  -- architecture behav

-------------------------------------------------------------------------------
-- chipscope
Inst_chipscope : if USE_CHIPSCOPE_ILA_5 generate

    gtp_if_ila_1 : gtp_if_ila
          port map (
            control     => control,
            clk         => gtp_clk_in,
            data        => ila_data,
            trig0       => ila_trg
            );

    ila_trg(0) <= '1' when send_state = idle			    else '0';
    ila_trg(1) <= '1' when send_state = send_start_addr	    else '0';
    ila_trg(2) <= '1' when send_state = send_start_addr1	else '0';
    ila_trg(3) <= '1' when send_state = send_start_addr2	else '0';

    ila_trg(4) <= '1' when send_state = send_end_addr		else '0';
    ila_trg(5) <= '1' when send_state = send_end_addr1		else '0';
    ila_trg(6) <= '1' when send_state = send_end_addr2      else '0';
    ila_trg(7) <= '1' when send_state = receive			    else '0';

    ila_trg(8) <= '1' when  tx_data_out_i = idle_word		else '0';
    ila_trg(9) <= '1' when  tx_data_out_i = comma_word		else '0';
    ila_trg(10) <= '1' when tx_data_out_i = busy_word		else '0';
    ila_trg(11) <= '1' when tx_data_out_i = notbusy_word	else '0';
    ila_trg(12) <= '1' when tx_data_out_i = start_addr_cmd  else '0';
    ila_trg(13) <= '1' when tx_data_out_i = end_addr_cmd	else '0';
    
    ila_trg(14) <= start_reading;
    ila_trg(15) <= binfile_fifo_prog_full;


    ila_data(0) <= '1' when send_state = idle			    else '0';
    ila_data(1) <= '1' when send_state = send_start_addr	else '0';
    ila_data(2) <= '1' when send_state = send_start_addr1	else '0';
    ila_data(3) <= '1' when send_state = send_start_addr2	else '0';

    ila_data(4) <=  '1' when send_state = send_end_addr		else '0';
    ila_data(5) <=  '1' when send_state = send_end_addr1	else '0';
    ila_data(6) <=  '1' when send_state = send_end_addr2    else '0';
    ila_data(7) <=  '1' when send_state = receive			else '0';



    ila_data(23 downto 8)  <= rx_data_in(15 downto 0);
    ila_data(40 downto 24) <= binfile_fifo_din;

    ila_data(41) <= binfile_fifo_wr_en;
    ila_data(42) <= binfile_fifo_ren_in;
    ila_data(43) <= binfile_fifo_prog_full;
    ila_data(44) <= binfile_fifo_empty_out_i;
    ila_data(45) <= binfile_fifo_valid_out_i;
    ila_data(46) <= start_reading;

    ila_data(63 downto 47) <= (others => '0');

end generate;
-------------------------------------------------------------------------------
-- comma_en
	process
	begin
		wait until rising_edge(gtp_clk_in);
		if comma_cnt = 0 then
			comma_en <= '1';
		else
			comma_en <= '0';
		end if;

		comma_cnt <= comma_cnt - 1;
	end process;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- start_reading
	process
	begin
		wait until rising_edge(gtp_clk_in);
		start_reading_sr <= start_reading_sr(0) & start_reading_in;
		if start_reading_sr = "01" then
			start_reading <= '1';
			start_addr	  <= start_addr_in;
			end_addr	  <= end_addr_in;
        else
			start_reading <= '0';
		end if;
	end process;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- detect busy
	process
	begin
		wait until rising_edge(gtp_clk_in);
		busy_sr <= busy_sr(0) & binfile_fifo_prog_full;
	end process;
------------------------------------------------------------------------------- 

-------------------------------------------------------------------------------
-- redirect for ila
    tx_data_out <= tx_data_out_i;

-- send: busy, comma, addr
	process
	begin
		wait until rising_edge(gtp_clk_in);
		case send_state is
			when idle =>
				if comma_en = '1' then
					tx_data_out_i <= comma_word;
				else
					tx_data_out_i <= idle_word;
				end if;

				tx_isk_out <= "11";
				if start_reading = '1' then
					send_state <= send_start_addr;
				end if;
				
			when send_start_addr =>
				tx_data_out_i <= start_addr_cmd;
				tx_isk_out	<= "11";
				send_state	<= send_start_addr1;
				
			when send_start_addr1 =>
				tx_data_out_i <= "000" & start_addr(28 downto 16);
				tx_isk_out	<= "00";
				send_state	<= send_start_addr2;

			when send_start_addr2 =>
				tx_data_out_i <= start_addr(15 downto 0);
				tx_isk_out	<= "00";
				send_state	<= send_end_addr;

			when send_end_addr =>
				tx_data_out_i <= end_addr_cmd;
				tx_isk_out	<= "11";
				send_state	<= send_end_addr1;
				
			when send_end_addr1 =>
				tx_data_out_i <= "000" & end_addr(28 downto 16);
				tx_isk_out	<= "00";
				send_state	<= send_end_addr2;
				
			when send_end_addr2 =>
				tx_data_out_i <= end_addr(15 downto 0);
				tx_isk_out	<= "00";
				send_state	<= receive;

			when receive =>
				tx_isk_out <= "11";
				if rx_isk_in = "10" and rx_data_in = x"1c1c" then
					send_state	<= idle;
					tx_data_out_i <= notbusy_word;
				elsif busy_sr = "01" then
					tx_data_out_i <= busy_word;
				elsif busy_sr = "10" then
					tx_data_out_i <= notbusy_word;
				else
					tx_data_out_i <= idle_word;
				end if;

            when others =>
                send_state	<= idle;

		end case;
	end process;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- read
	process
	begin
		wait until rising_edge(gtp_clk_in);
		binfile_fifo_din <= rx_isk_in(1) & rx_data_in;
		if rx_isk_in /= "11" and send_state = receive then
			binfile_fifo_wr_en <= '1';
		else
			binfile_fifo_wr_en <= '0';
		end if;
	end process;
------------------------------------------------------------------------------- 

-------------------------------------------------------------------------------
-- redirect for ila
    binfile_fifo_empty_out <= binfile_fifo_empty_out_i;
    binfile_fifo_valid_out <= binfile_fifo_valid_out_i;
-- fifo
	binfile_fifo_1 : binfile_fifo
		port map (
            rst       => reset,
			wr_clk	  => gtp_clk_in,
			rd_clk	  => binfile_fifo_rd_clk_in,
			din		  => binfile_fifo_din,
			wr_en	  => binfile_fifo_wr_en,
			rd_en	  => binfile_fifo_ren_in,
			dout	  => binfile_fifo_data_out,
			full	  => open,
			prog_full => binfile_fifo_prog_full,
			empty	  => binfile_fifo_empty_out_i,
			valid	  => binfile_fifo_valid_out_i);
------------------------------------------------------------------------------- 

end architecture behav;

-------------------------------------------------------------------------------
