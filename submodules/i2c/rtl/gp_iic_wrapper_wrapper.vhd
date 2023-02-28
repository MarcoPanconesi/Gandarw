----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:	   12:22:29 08/13/2013 
-- Design Name: 
-- Module Name:	   gp_iic_wrapper_wrapper - Behavioral 
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
library IEEE;
use IEEE.STD_LOGIC_1164.all;

use IEEE.NUMERIC_STD.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

--library UNISIM;
--use UNISIM.VCOMPONENTS.all;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity gp_iic_wrapper_wrapper is
	generic(
		SIM : boolean := false
		);
	port (
		clk			 : in  std_logic;
		stb			 : in  std_logic;
		we			 : in  std_logic;
		wr_part		 : in  std_logic_vector(3 downto 0);
		err			 : out std_logic;
		ack			 : out std_logic;
		reg_addr	 : in  std_logic_vector(15 downto 0);
		write_data	 : in  std_logic_vector(31 downto 0);
		read_data	 : out std_logic_vector(31 downto 0);
		slave_addr	 : in  std_logic_vector(6 downto 0);
		reg_16_bit	 : in  std_logic;
		data_format	 : in  std_logic_vector(1 downto 0);
		upper_iic_on : in  std_logic;

		SCL : inout std_logic_vector(1 downto 0);
		SDA : inout std_logic_vector(1 downto 0)
		);

end entity gp_iic_wrapper_wrapper;



architecture Behavioral of gp_iic_wrapper_wrapper is

	signal wb_rst_i : std_logic_vector(1 downto 0) := (others => '0');
	signal arst_i	: std_logic_vector(1 downto 0) := (others => '0');

--		signal wb_adr_i	  : std_logic_vector(2 downto 0);
--		signal wb_dat_i	  : std_logic_vector(7 downto 0);
--		signal wb_dat_o	  : std_logic_vector(7 downto 0);

	subtype wb_adr is std_logic_vector(2 downto 0);
	type	wb_adrs is array (integer range<>) of wb_adr;
	signal	wb_adrs_i : wb_adrs(0 to 1) := (others => (others => '0'));

	subtype wb_dat is std_logic_vector(7 downto 0);
	type	wb_dats is array (integer range<>) of wb_dat;
	signal	wb_dats_i : wb_dats(0 to 1) := (others => (others => '0'));
	signal	wb_dats_o : wb_dats(0 to 1) := (others => (others => '0'));

	signal wb_we_i	 : std_logic_vector(1 downto 0);
	signal wb_stb_i	 : std_logic_vector(1 downto 0);
	signal wb_cyc_i	 : std_logic_vector(1 downto 0);
	signal wb_ack_o	 : std_logic_vector(1 downto 0);
	signal wb_inta_o : std_logic_vector(1 downto 0);

	signal scl_pad_i	: std_logic_vector(1 downto 0);
	signal scl_pad_o	: std_logic_vector(1 downto 0);
	signal scl_padoen_o : std_logic_vector(1 downto 0);
	signal sda_pad_i	: std_logic_vector(1 downto 0);
	signal sda_pad_o	: std_logic_vector(1 downto 0);
	signal sda_padoen_o : std_logic_vector(1 downto 0);


	signal stb_i : std_logic_vector(1 downto 0);
	signal ack_i : std_logic_vector(1 downto 0);
	signal err_i : std_logic_vector(1 downto 0);


	subtype st_read_data is std_logic_vector(31 downto 0);
	type	t_read_data is array (integer range<>) of st_read_data;
	signal	read_data_i : t_read_data(0 to 1) := (others => (others => '0'));


begin

	with ack_i select
		read_data <=
		read_data_i(0) when "01",
		read_data_i(1) when "10",
		x"00000000"	   when others;

	stb_i(0) <= stb when (upper_iic_on = '1') else '0';
	stb_i(1) <= stb when (upper_iic_on = '0') else '0';
	ack		 <= ack_i(0) or ack_i(1);
	err		 <= err_i(0) or err_i(1);

	inst_iic_ports : for iic_port in 0 to 1 generate
	begin

		gp_iic_wrapper : entity work.gp_iic_wrapper
			port map (
				clk			=> clk,
				stb			=> stb_i(iic_port),
				we			=> we,
				wr_part		=> wr_part,
				err			=> err_i(iic_port),
				ack			=> ack_i(iic_port),
				reg_addr	=> reg_addr,
				write_data	=> write_data,
				read_data	=> read_data_i(iic_port),
				slave_addr	=> slave_addr,
				reg_16_bit	=> reg_16_bit,
				data_format => data_format,

				wb_rst_i  => wb_rst_i(iic_port),
				arst_i	  => arst_i(iic_port),
				wb_adr_i  => wb_adrs_i(iic_port),
				wb_dat_i  => wb_dats_i(iic_port),
				wb_dat_o  => wb_dats_o(iic_port),
				wb_we_i	  => wb_we_i(iic_port),
				wb_stb_i  => wb_stb_i(iic_port),
				wb_cyc_i  => wb_cyc_i(iic_port),
				wb_ack_o  => wb_ack_o(iic_port),
				wb_inta_o => wb_inta_o(iic_port));

		i2c_master_top : entity work.i2c_master_top
			generic map (
				ARST_LVL  => '0')
			port map (
				wb_clk_i  => clk,
				wb_rst_i  => '0',
				arst_i	  => arst_i(iic_port),

				wb_adr_i  => wb_adrs_i(iic_port),
				wb_dat_i  => wb_dats_i(iic_port),
				wb_dat_o  => wb_dats_o(iic_port),
				wb_we_i	  => wb_we_i(iic_port),
				wb_stb_i  => wb_stb_i(iic_port),
				wb_cyc_i  => wb_cyc_i(iic_port),
				wb_ack_o  => wb_ack_o(iic_port),
				wb_inta_o => wb_inta_o(iic_port),

				scl_pad_i	 => scl_pad_i(iic_port),
				scl_pad_o	 => scl_pad_o(iic_port),
				scl_padoen_o => scl_padoen_o(iic_port),
				sda_pad_i	 => sda_pad_i(iic_port),
				sda_pad_o	 => sda_pad_o(iic_port),
				sda_padoen_o => sda_padoen_o(iic_port));

		SCL(iic_port) <= scl_pad_o(iic_port) when (scl_padoen_o(iic_port) = '0') else 'Z';
		SDA(iic_port) <= sda_pad_o(iic_port) when (sda_padoen_o(iic_port) = '0') else 'Z';

		scl_pad_i(iic_port) <= 'Z' when SIM = true else SCL(iic_port);
		sda_pad_i(iic_port) <= '0' when SIM = true else SDA(iic_port);

	end generate;

end Behavioral;

