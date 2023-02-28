----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:	   15:15:22 08/08/2013 
-- Design Name: 
-- Module Name:	   gp_iic_wrapper - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

-------------------------------------------------------------------------------

entity gp_iic_wrapper is
	port (
		clk		   : in	 std_logic;
-------------------------------------------------------------------------------
-- to gp interface
		stb		   : in	 std_logic;
		we		   : in	 std_logic;
		wr_part	   : in	 std_logic_vector(3 downto 0);
		err		   : out std_logic;
		ack		   : out std_logic;
		reg_addr   : in	 std_logic_vector(15 downto 0);
		write_data : in	 std_logic_vector(31 downto 0);
		read_data  : out std_logic_vector(31 downto 0);
		slave_addr : in	 std_logic_vector(6 downto 0);

		reg_16_bit	: in std_logic;
		data_format : in std_logic_vector(1 downto 0);
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

end entity gp_iic_wrapper;

-------------------------------------------------------------------------------

architecture behav of gp_iic_wrapper is
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
-- prescalers
-- calc with: inclk / ( 5 * iic_clk ) - 1 = (h & l); 018f = 200Mhz input,100khz iic
-- Alex: con 40Mhz di inclk e 1Mhz di iic prescale := x"0007" 
--       con 40Mhz di inclk e 400Khz di iic prescale :="0013" 
--       con 40Mhz di inclk e 100Khz di iic prescale :="004F" 
constant prescale_h : std_logic_vector(7 downto 0) := x"00"; -- era x"01";
constant prescale_l : std_logic_vector(7 downto 0) := x"13"; -- era x"8f";
------------------------------------------------------------------------------- 

-------------------------------------------------------------------------------
-- registered signals
	signal we_i			 : std_logic					 := '0';
	signal data_format_i : std_logic_vector(1 downto 0);
	signal reg_addr_i	 : std_logic_vector(15 downto 0) := (others => '0');
	signal write_data_i	 : std_logic_vector(31 downto 0) := (others => '0');
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- state machine
	type state_type is (
		startup,  						--=>
		disable_core,  					--=>
		set_scaler_h,  					--=>
		set_scaler_l,  					--=>
		enable_core,  					--=>

		sleep,							--=>() // next_state => (write_reg_addr_high  V	 write_reg_addr_low)
		slave_addr_write,				--=> 
		start_bit,						--=>wait_no_tip

		write_bit,						--=>
		wait_no_tip,					--=>
		read_ack,						--=>() V next_state 
		err_state,						--=>sleep
		
		write_reg_addr_high,  			--(=>)(=>write_bit // next_state=>write_reg_addr_low)
		write_reg_addr_low,	 			--=>write_bit // next_state=> slave_addr_read V write_data_8 V write_data_16 V write_data_32     !!!!!!!!!!R/W!!!!!!!

		write_data_32,  				--(=>)(=>write_bit // next_state =>write_data_24)
		write_data_24,  				--(=>)(=>write_bit // next_state =>write_data_16)
		write_data_16,  				--(=>)(=>write_bit // next_state =>write_data_8)
		write_data_8,  					--=> // next_state =>ack
		stop_bit_write,  				--=>wait_no_tip

		slave_addr_read,  				--=>start_bit // next_state =>(stop_bit_read V read_bit_32 V read_bit_16 )

  		read_bit_32,  					--=>wait_no_tip_read_32 // next_state=>read_bit_24
		read_bit_24,					--=>wait_no_tip_read_24 // next_state=>read_bit_16
		read_bit_16,					--=>wait_no_tip_read_16 // next_state=>stop_bit_read
		stop_bit_read,					--=>wait_no_tip_nack
	
   		wait_no_tip_read_32,  			--=>read_data_32
		wait_no_tip_read_24,  			--=>read_data_24
		wait_no_tip_read_16,  			--=>read_data_16
		wait_no_tip_nack,  				--=>read_data_8

		read_data_32,  					--=>next_state
		read_data_24,  					--=>next_state
		read_data_16,  					--=>next_state
   		read_data_8,  					--=>ack_state

		ack_state,  					--=>
		wait_one  						--=>sleep
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

        arst_i	 <= '1'; 

		case state is
-- startup
			when startup =>
                arst_i	 <= '0'; 
				state <= disable_core;

			when disable_core =>
                arst_i	 <= '1'; 
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
					state <= slave_addr_write;

										--choose between 8 and 16 bit register
					if reg_16_bit = '1' then
						next_state <= write_reg_addr_high;
					else
						next_state <= write_reg_addr_low;
					end if;

										--register the data format, data and address
					data_format_i <= data_format;
					we_i		  <= we;
					reg_addr_i	  <= reg_addr;
					case wr_part is
						when "1000" =>
							write_data_i(7 downto 0) <= write_data(31 downto 24);

						when "0100" =>
							write_data_i(7 downto 0) <= write_data(23 downto 16);

						when "0010" =>
							write_data_i(7 downto 0) <= write_data(15 downto 8);

						when "0001" =>
							write_data_i(7 downto 0) <= write_data(7 downto 0);

						when "1100" =>
							write_data_i(15 downto 0) <= write_data(31 downto 16);

						when "0011" =>
							write_data_i(15 downto 0) <= write_data(15 downto 0);

						when "1111" =>
							write_data_i <= write_data;

						when others => null;
					end case;
					
				end if;

-- common states
			when slave_addr_write =>
				if wb_ack_o = '1' then
					state <= start_bit;
				else
					wb_cyc_i <= '1';
					wb_stb_i <= '1';
					wb_adr_i <= addr_transmit;
					wb_dat_i <= slave_addr & '0';
					wb_we_i	 <= '1';
				end if;

			when slave_addr_read =>
				if wb_ack_o = '1' then
					state <= start_bit;

					case data_format_i is
						when "00" =>
							next_state <= stop_bit_read;
						when "01" =>
							next_state <= read_bit_16;
						when "10" =>
							next_state <= read_bit_32;
						when others => null;
					end case;

				else
					wb_cyc_i <= '1';
					wb_stb_i <= '1';
					wb_adr_i <= addr_transmit;
					wb_dat_i <= slave_addr & '1';
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
					wb_dat_i <= x"10";	-- WR
					wb_we_i	 <= '1';
				end if;

			when read_bit_16 =>
				if wb_ack_o = '1' then
					state	   <= wait_no_tip_read_16;
					next_state <= stop_bit_read;
				else
					wb_cyc_i <= '1';
					wb_stb_i <= '1';
					wb_adr_i <= addr_command;
					wb_dat_i <= x"20";	--RD,ACK
					wb_we_i	 <= '1';
				end if;

			when read_bit_24 =>
				if wb_ack_o = '1' then
					state	   <= wait_no_tip_read_24;
					next_state <= read_bit_16;
				else
					wb_cyc_i <= '1';
					wb_stb_i <= '1';
					wb_adr_i <= addr_command;
					wb_dat_i <= x"20";	--RD,ACK
					wb_we_i	 <= '1';
				end if;

			when read_bit_32 =>
				if wb_ack_o = '1' then
					state	   <= wait_no_tip_read_32;
					next_state <= read_bit_24;
				else
					wb_cyc_i <= '1';
					wb_stb_i <= '1';
					wb_adr_i <= addr_command;
					wb_dat_i <= x"20";	--RD,ACK
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
				
			when wait_no_tip_read_32 =>
				if wb_ack_o = '1' and wb_dat_o(1) = '0' then
					state <= read_data_32;
				else
					wb_cyc_i <= '1';
					wb_stb_i <= '1';
					wb_adr_i <= addr_status;
				end if;

			when wait_no_tip_read_24 =>
				if wb_ack_o = '1' and wb_dat_o(1) = '0' then
					state <= read_data_24;
				else
					wb_cyc_i <= '1';
					wb_stb_i <= '1';
					wb_adr_i <= addr_status;
				end if;

			when wait_no_tip_read_16 =>
				if wb_ack_o = '1' and wb_dat_o(1) = '0' then
					state <= read_data_16;
				else
					wb_cyc_i <= '1';
					wb_stb_i <= '1';
					wb_adr_i <= addr_status;
				end if;

			when wait_no_tip_nack =>
				if wb_ack_o = '1' and wb_dat_o(1) = '0' then
					state <= read_data_8;
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

			when write_reg_addr_low =>
				if wb_ack_o = '1' then
					state <= write_bit;

					if we_i = '1' then

						case data_format_i is
							when "00" =>
								next_state <= write_data_8;
							when "01" =>
								next_state <= write_data_16;
							when "10" =>
								next_state <= write_data_32;
							when others => null;
						end case;

					else
						next_state <= slave_addr_read;
					end if;
					
				else
					wb_cyc_i <= '1';
					wb_stb_i <= '1';
					wb_adr_i <= addr_transmit;
					wb_dat_i <= reg_addr_i(7 downto 0);
					wb_we_i	 <= '1';
				end if;

			when write_reg_addr_high =>
				if wb_ack_o = '1' then
					state	   <= write_bit;
					next_state <= write_reg_addr_low;
				else
					wb_cyc_i <= '1';
					wb_stb_i <= '1';
					wb_adr_i <= addr_transmit;
					wb_dat_i <= reg_addr_i(15 downto 8);
					wb_we_i	 <= '1';
				end if;

			when ack_state =>
				ack	  <= '1';
				state <= wait_one;

			when err_state =>
				ack	  <= '1';
				err	  <= '1';
				state <= wait_one;

			when wait_one =>
				state <= sleep;

-- write states

			when write_data_8 =>
				if wb_ack_o = '1' then
					state	   <= stop_bit_write;
					next_state <= ack_state;
				else
					wb_cyc_i <= '1';
					wb_stb_i <= '1';
					wb_adr_i <= addr_transmit;
					wb_dat_i <= write_data_i(7 downto 0);
					wb_we_i	 <= '1';
				end if;

			when write_data_16 =>
				if wb_ack_o = '1' then
					state	   <= write_bit;
					next_state <= write_data_8;
				else
					wb_cyc_i <= '1';
					wb_stb_i <= '1';
					wb_adr_i <= addr_transmit;
					wb_dat_i <= write_data_i(15 downto 8);
					wb_we_i	 <= '1';
				end if;

			when write_data_24 =>
				if wb_ack_o = '1' then
					state	   <= write_bit;
					next_state <= write_data_16;
				else
					wb_cyc_i <= '1';
					wb_stb_i <= '1';
					wb_adr_i <= addr_transmit;
					wb_dat_i <= write_data_i(23 downto 16);
					wb_we_i	 <= '1';
				end if;

			when write_data_32 =>
				if wb_ack_o = '1' then
					state	   <= write_bit;
					next_state <= write_data_24;
				else
					wb_cyc_i <= '1';
					wb_stb_i <= '1';
					wb_adr_i <= addr_transmit;
					wb_dat_i <= write_data_i(31 downto 24);
					wb_we_i	 <= '1';
				end if;

-- read states
			when read_data_32 =>
				if wb_ack_o = '1' then
					state					<= next_state;
					read_data(31 downto 24) <= wb_dat_o;
				else
					wb_cyc_i <= '1';
					wb_stb_i <= '1';
					wb_adr_i <= addr_receive;
				end if;

			when read_data_24 =>
				if wb_ack_o = '1' then
					state					<= next_state;
					read_data(23 downto 16) <= wb_dat_o;
				else
					wb_cyc_i <= '1';
					wb_stb_i <= '1';
					wb_adr_i <= addr_receive;
				end if;

			when read_data_16 =>
				if wb_ack_o = '1' then
					state				   <= next_state;
					read_data(15 downto 8) <= wb_dat_o;
				else
					wb_cyc_i <= '1';
					wb_stb_i <= '1';
					wb_adr_i <= addr_receive;
				end if;
				
			when read_data_8 =>
				if wb_ack_o = '1' then
					state				  <= ack_state;
					read_data(7 downto 0) <= wb_dat_o;
				else
					wb_cyc_i <= '1';
					wb_stb_i <= '1';
					wb_adr_i <= addr_receive;
				end if;
		end case;
	end process;
-------------------------------------------------------------------------------
end architecture behav;
