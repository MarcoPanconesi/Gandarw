-------------------------------------------------------------------------------
-- Title	  : gp_if
-- Project	  : test project
-------------------------------------------------------------------------------
-- File		  : gp_if.vhd
-- Author	  : Philipp	 <philipp@pcfr58.physik.uni-freiburg.de>
-- Company	  : 
-- Created	  : 2013-08-14
-- Last update: 2013-11-14
-- Platform	  : 
-- Standard	  : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: gp_if
-------------------------------------------------------------------------------
-- Copyright (c) 2013 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date		   Version	Author	Description
-- 2013-08-14  1.0		philipp Created
-------------------------------------------------------------------------------
-- Note       : Added set_IPs , write ip address from cf_mem to arwen fpga 
--              using i2c bus, modified arwen board to add i2c bus, to be tested
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use WORK.G_PARAMETERS.all;
--------------------------------------------------------------------------------------------------------------------------------------------------------------

entity gp_if is
	generic(
		SIM : boolean := false
		);
	port (
		clk					  : in	  std_logic;
		SCL					  : inout std_logic_vector(1 downto 0);
		SDA					  : inout std_logic_vector(1 downto 0);
		rd_temps			  : in	  std_logic;
		rd_stats			  : in	  std_logic;
		set_DACs			  : in	  std_logic;
		set_IPs			      : in	  std_logic;
		write_eeprom_to_cfmem : in	  std_logic;
		write_cfmem_to_eeprom : in	  std_logic;
		INIT_GP				  : in	  std_logic;
		cfmem_wb_cyc		  : out	  std_logic;
		cfmem_wb_stb		  : out	  std_logic;
		cfmem_wb_we			  : out	  std_logic_vector(3 downto 0);
		cfmem_wb_ack		  : in	  std_logic;
		cfmem_wb_addr		  : out	  std_logic_vector (9 downto 0);
		cfmem_wb_din		  : in	  std_logic_vector (31 downto 0);
		cfmem_wb_dout		  : out	  std_logic_vector (31 downto 0)
		);

end entity gp_if;

--------------------------------------------------------------------------------------------------------------------------------------------------------------

architecture behav of gp_if is

--------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- wrapper_wrapper control signals

	signal stb			: std_logic					   := '0';
	signal we			: std_logic;
	signal wr_part		: std_logic_vector(3 downto 0) := "0011";
	signal err			: std_logic;
	signal ack			: std_logic;
	signal reg_addr		: std_logic_vector(15 downto 0);
	signal write_data	: std_logic_vector(31 downto 0);
	signal read_data	: std_logic_vector(31 downto 0);
	signal slave_addr	: std_logic_vector(6 downto 0);
	signal reg_16_bit	: std_logic;
	signal data_format	: std_logic_vector(1 downto 0);
	signal upper_iic_on : std_logic;
--------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- internal logic signals and constants

	type state_type is (
		sleep,
		startup_dac,					--=>startup_temp
		startup_temp,					--=>write_eeprom_to_cf_mem
		write_eeprom_to_cf_mem,			--=>sleep
		write_cf_mem_to_eeprom,			--=>sleep
		write_tmp_to_cf_mem,			--=>sleep
		write_arw_stats_to_cf_mem,	    --=>sleep
		set_dac_vals,				    --=>sleep
		set_arw_vals					--=>sleep
		);
	signal state : state_type := sleep;

    type shift_regs is array (0 to 6) of std_logic_vector(1 downto 0);
    signal shift_reg			   : shift_regs := (b"00", b"00", b"00", b"00", b"00",b"00",b"00");

	signal rd_temps_i			   : std_logic	:= '0';
	signal rd_stats_i			   : std_logic	:= '0';
	signal set_DACs_i			   : std_logic	:= '0';
	signal write_eeprom_to_cfmem_i : std_logic	:= '0';
	signal write_cfmem_to_eeprom_i : std_logic	:= '0';
	signal INIT_GP_i			   : std_logic	:= '0';
	signal set_IPs_i			   : std_logic	:= '0';

	signal read_part		   : std_logic;
	signal read_data_i		   : std_logic_vector(31 downto 0);
	signal counter			   : integer				:= 0;
	signal reg_counter		   : integer range 0 to 255 := 0;
	signal ack_polling_counter : integer range 0 to 127;

	constant UP						   : std_logic		  := '1';
	constant DOWN					   : std_logic		  := '0';
	constant C_31_downto_16			   : std_logic_vector := "1100";
	constant C_15_downto_0			   : std_logic_vector := "0011";
	constant ack_polling_counter_const : integer		  := 127;  -- see datasheet of shitty eeprom!!!

    constant FORMAT_32                 : std_logic_vector := "10"; -- I2C read/write data lenght      
    constant FORMAT_16                 : std_logic_vector := "01"; -- I2C read/write data lenght      
    constant FORMAT_08                 : std_logic_vector := "00"; -- I2C read/write data lenght      
--------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- this part maps the temp values of the different temp sensors to the config
	-- mem (state: write_tmp_to_cf_mem)

	type tmp_slave_addrs is array (0 to 3) of std_logic_vector(7 downto 0);	 --the highest bit selects the card
	type tmp_cf_mem_addrs is array (0 to 3) of std_logic_vector(9 downto 0);
	type tmp_cf_mem_wes is array (0 to 3) of std_logic_vector(3 downto 0);

	constant AMC_0_TEMP_OFFSET : std_logic_vector(9 downto 0) := std_logic_vector(AMC0_addr_offset+temp_addr_offset);
	constant AMC_1_TEMP_OFFSET : std_logic_vector(9 downto 0) := std_logic_vector(AMC1_addr_offset+temp_addr_offset);
	constant temp_slave_const  : std_logic_vector(5 downto 0) := "100100";

	constant tmp_slave_addr	 : tmp_slave_addrs				 := (DOWN & temp_slave_const & b"1", DOWN & temp_slave_const & b"0", UP & temp_slave_const & b"1", UP & temp_slave_const & b"0");
	constant tmp_rd_reg		 : std_logic_vector(15 downto 0) := x"0000";
	constant tmp_cf_mem_addr : tmp_cf_mem_addrs				 := (AMC_1_TEMP_OFFSET, AMC_1_TEMP_OFFSET, AMC_0_TEMP_OFFSET, AMC_0_TEMP_OFFSET);
	constant tmp_cf_mem_we	 : tmp_cf_mem_wes				 := (C_31_downto_16, C_15_downto_0, C_31_downto_16, C_15_downto_0);
-------------------------------------------------------------------------------------------------------------------------------------------------------------- 
	-- this part maps the values saved in the eeproms to the config mem

	type eeprom_cf_mem_start_addrs is array (0 to 1) of std_logic_vector(9 downto 0);
	type eeprom_slave_addrs is array (0 to 1) of std_logic_vector(7 downto 0);


--use
	constant eeprom_addr_counter_const : integer					 := 127;
    --only half the Mezzanine card confmem range (0x000 to 0x07f) or (0x100 to 0x17f) value was 255 for the whole range

	constant eeprom_cf_mem_start_addr  : eeprom_cf_mem_start_addrs := (std_logic_vector(AMC0_addr_offset), std_logic_vector(AMC1_addr_offset));
	constant eeprom_slave_addr		  : eeprom_slave_addrs		 := (UP & b"1010100", DOWN & b"1010100");

--------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- this part maps the dac values to the config mem (state: set_dac_vals)
    -- Modified for AMC_0 only ...
    -- (0 to 7) was (0 to 15)
	type dac_slave_addrs is array (0 to 7) of std_logic_vector(7 downto 0);  --the highest bit selects the card
	type dac_reg_addrs is array (0 to 7) of std_logic_vector(15 downto 0);
	type dac_cf_mem_addrs is array (0 to 7) of std_logic_vector(9 downto 0);
	type dac_wes is array (0 to 7) of std_logic_vector(3 downto 0);

	constant AMC_0_DAC_OFFSET : std_logic_vector(9 downto 0)  := std_logic_vector(AMC0_addr_offset+dac_val_addr_offset);
	constant AMC_1_DAC_OFFSET : std_logic_vector(9 downto 0)  := std_logic_vector(AMC1_addr_offset+dac_val_addr_offset);
	constant dac_slave_const  : std_logic_vector(5 downto 0)  := b"000111";
	constant dac_wr_reg_const : std_logic_vector(12 downto 0) := x"00" & b"00" & b"010";

	constant dac_slave_addr : dac_slave_addrs := (UP & dac_slave_const & b"0", UP & dac_slave_const & b"0", UP & dac_slave_const & b"0", UP & dac_slave_const & b"0",
												  UP & dac_slave_const & b"1", UP & dac_slave_const & b"1", UP & dac_slave_const & b"1", UP & dac_slave_const & b"1"); --,
												  -- DOWN & dac_slave_const & b"0", DOWN & dac_slave_const & b"0", DOWN & dac_slave_const & b"0", DOWN & dac_slave_const & b"0",
												  -- DOWN & dac_slave_const & b"1", DOWN & dac_slave_const & b"1", DOWN & dac_slave_const & b"1", DOWN & dac_slave_const & b"1");
	constant dac_wr_reg : dac_reg_addrs := (dac_wr_reg_const & b"000", dac_wr_reg_const & b"001", dac_wr_reg_const & b"010", dac_wr_reg_const & b"011",
											dac_wr_reg_const & b"000", dac_wr_reg_const & b"001", dac_wr_reg_const & b"010", dac_wr_reg_const & b"011"); --,
											-- dac_wr_reg_const & b"000", dac_wr_reg_const & b"001", dac_wr_reg_const & b"010", dac_wr_reg_const & b"011",
											-- dac_wr_reg_const & b"000", dac_wr_reg_const & b"001", dac_wr_reg_const & b"010", dac_wr_reg_const & b"011");
	constant dac_cf_mem_addr : dac_cf_mem_addrs := (AMC_0_DAC_OFFSET+"00", AMC_0_DAC_OFFSET+"00", AMC_0_DAC_OFFSET+"01", AMC_0_DAC_OFFSET+"01",
													AMC_0_DAC_OFFSET+"10", AMC_0_DAC_OFFSET+"10", AMC_0_DAC_OFFSET+"11", AMC_0_DAC_OFFSET+"11"); --,
													-- AMC_1_DAC_OFFSET+"00", AMC_1_DAC_OFFSET+"00", AMC_1_DAC_OFFSET+"01", AMC_1_DAC_OFFSET+"01",
													-- AMC_1_DAC_OFFSET+"10", AMC_1_DAC_OFFSET+"10", AMC_1_DAC_OFFSET+"11", AMC_1_DAC_OFFSET+"11");
	constant dac_we : dac_wes := (C_15_downto_0, C_31_downto_16, C_15_downto_0, C_31_downto_16,
								  C_15_downto_0, C_31_downto_16, C_15_downto_0, C_31_downto_16); --,
								  -- C_15_downto_0, C_31_downto_16, C_15_downto_0, C_31_downto_16,
								  -- C_15_downto_0, C_31_downto_16, C_15_downto_0, C_31_downto_16);
--------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- this part manages the dac startup
    -- Modified for AMC_0 only ...
    -- (0 to 1) was (0 to 3)

	type dac_startup_slave_addrs is array (0 to 1) of std_logic_vector(7 downto 0);	--the highest bit selects the card

    constant dac_startup_reg	    : std_logic_vector(15 downto 0) := x"0038";
	constant dac_startup_data	    : std_logic_vector(31 downto 0) := x"0000" & x"0001";
	constant dac_startup_slave_addr : dac_startup_slave_addrs	   := ( UP & b"0001110", UP & b"0001111"); --, 
                                                                        -- DOWN & b"0001110", DOWN & b"0001111");

--------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- this part manages the Arwen MAC and IP addr setup

    type arw_cf_mem_addrs is array (0 to 15) of std_logic_vector(9 downto 0);
    type arw_slave_addrs  is array (0 to 15) of std_logic_vector(7 downto 0);

    constant OMC1_CONF_OFFSET   : std_logic_vector(9 downto 0)  := std_logic_vector(AMC1_addr_offset+ip_conf_offset);
    
    constant arw_i2c_addr       : std_logic_vector(6 downto 0)  := b"0001110";

	constant arw_slave_addr     : arw_slave_addrs  := (others =>  DOWN & arw_i2c_addr);                                        
    
    constant arw_cf_mem_addr    : arw_cf_mem_addrs := ( OMC1_CONF_OFFSET + X"0",OMC1_CONF_OFFSET + X"1",OMC1_CONF_OFFSET + X"2",OMC1_CONF_OFFSET + X"3",
                                                        OMC1_CONF_OFFSET + X"4",OMC1_CONF_OFFSET + X"5",OMC1_CONF_OFFSET + X"6",OMC1_CONF_OFFSET + X"7",
                                                        OMC1_CONF_OFFSET + X"8",OMC1_CONF_OFFSET + X"9",OMC1_CONF_OFFSET + X"A",OMC1_CONF_OFFSET + X"B",
                                                        OMC1_CONF_OFFSET + X"C",OMC1_CONF_OFFSET + X"D",OMC1_CONF_OFFSET + X"E",OMC1_CONF_OFFSET + X"F");

    constant arw_addr_reg       : std_logic_vector(15 downto 0) := x"0000";

--------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- this part maps the Arwen status0 and status1 values to the config
	-- mem (state: write_arw_stats_to_cf_mem)

	type arwstat_slave_addrs is array (0 to 1) of std_logic_vector(7 downto 0);	 --the highest bit selects the card
	type arwstat_cf_mem_addrs is array (0 to 1) of std_logic_vector(9 downto 0);
	type arwstat_cf_mem_wes is array (0 to 1) of std_logic_vector(3 downto 0);

	constant OMC1_STATUS_OFFSET : std_logic_vector(9 downto 0) := std_logic_vector(AMC1_addr_offset+status_addr_offset);


	constant arwstat_slave_addr	 : arwstat_slave_addrs		        := (others =>  DOWN & arw_i2c_addr);
	constant arwstat_rd_reg		 : std_logic_vector(15 downto 0)    := x"0008";
	constant arwstat_cf_mem_addr : arwstat_cf_mem_addrs		        := (OMC1_STATUS_OFFSET+"0",OMC1_STATUS_OFFSET+"1");

    --------------------------------------------------------------------------------------------------------------------------------------------------------------
	-- this part manages the temp startup

	type temp_startup_slave_addrs is array (0 to 3) of std_logic_vector(7 downto 0);	 --the highest bit selects the card

	constant temp_startup_reg		    : std_logic_vector(15 downto 0) := x"0001";
	constant temp_startup_data		    : std_logic_vector(31 downto 0) := x"0000" & x"0060";
	constant temp_startup_slave_addr    : temp_startup_slave_addrs		:= (UP & b"1001000", UP & b"1001001", DOWN & b"1001000", DOWN & b"1001001");

--------------------------------------------------------------------------------------------------------------------------------------------------------------
	--this part defines the location of status flags
    -- not used!!!
	type stat_MEZ_map is array (0 to 1) of integer;	 

	constant startup_dac_state			  : integer		 := 20;
	constant startup_dac_stat			  : stat_MEZ_map := (0, 1);
	constant startup_temp_state			  : integer		 := 21;
	constant startup_temp_stat			  : stat_MEZ_map := (2, 3);
	constant write_eeprom_to_cf_mem_state : integer		 := 22;
	constant write_eeprom_to_cf_mem_stat  : stat_MEZ_map := (4, 5);
	constant write_cf_mem_to_eeprom_state : integer		 := 23;
	constant write_cf_mem_to_eeprom_stat  : stat_MEZ_map := (6, 7);
	constant write_tmp_to_cf_mem_state	  : integer		 := 24;
	constant write_tmp_to_cf_mem_stat	  : stat_MEZ_map := (8, 9);
	constant set_dac_vals_state			  : integer		 := 25;
	constant set_dac_vals_stat			  : stat_MEZ_map := (10, 11);
	constant sleep_state				  : integer		 := 26;
--------------------------------------------------------------------------------------------------------------------------------------------------------------

begin  --architecture behav
	process
	begin
		wait until rising_edge(clk);
-------------------------------------------------------------------------------shift in fast_registers
		shift_reg(0) <= shift_reg(0)(0) & rd_temps;
		shift_reg(1) <= shift_reg(1)(0) & set_DACs;
		shift_reg(2) <= shift_reg(2)(0) & write_eeprom_to_cfmem;
		shift_reg(3) <= shift_reg(3)(0) & write_cfmem_to_eeprom;
		shift_reg(4) <= shift_reg(4)(0) & INIT_GP;
		shift_reg(5) <= shift_reg(5)(0) & set_IPs;
        shift_reg(6) <= shift_reg(6)(0) & rd_stats;
		if shift_reg(0) = "01" then
			rd_temps_i <= '1';
		end if;
		if shift_reg(1) = "01" then
			set_DACs_i <= '1';
		end if;
		if shift_reg(2) = "01" then
			write_eeprom_to_cfmem_i <= '1';
		end if;
		if shift_reg(3) = "01" then
			write_cfmem_to_eeprom_i <= '1';
		end if;
		if shift_reg(4) = "01" then
			INIT_GP_i <= '1';
        end if;            
        if shift_reg(5) = "01" then
            set_IPs_i <= '1';
        end if;
        if shift_reg(6) = "01" then
            rd_stats_i <= '1';
        end if;

-------------------------------------------------------------------------------defaults
		stb			 <= '0';
		cfmem_wb_stb <= '0';
		cfmem_wb_cyc <= '0';
--------------------------------------------------------------------------------------------------------------------------------------------------------------
		case state is					-- gp state machine
--------------------------------------------------------------------------------------------------------------------------------------------------------------
			when sleep =>

				read_part			<= '1';
				reg_counter			<= eeprom_addr_counter_const;
				ack_polling_counter <= ack_polling_counter_const;
				if rd_temps_i = '1' then
					state	<= write_tmp_to_cf_mem;
					counter <= tmp_slave_addr'length - 1;
				elsif set_DACs_i = '1' then
					state	<= set_dac_vals;
					counter <= dac_slave_addr'length - 1;
				elsif write_eeprom_to_cfmem_i = '1' then
					state	<= write_eeprom_to_cf_mem;
					counter <= eeprom_slave_addr'length - 1;
				elsif write_cfmem_to_eeprom_i = '1' then
					state	<= write_cf_mem_to_eeprom;
					counter <= eeprom_slave_addr'length - 1;
				elsif INIT_GP_i = '1' then
					state	<= startup_dac;
					counter <= dac_startup_slave_addr'length - 1;
				elsif set_IPs_i = '1' then
					state	<= set_arw_vals;
					counter <= arw_slave_addr'length - 1;
                elsif rd_stats_i = '1' then
                    state	<= write_arw_stats_to_cf_mem;
					counter <= arwstat_slave_addr'length - 1;
				else
					state <= sleep;
				end if;
--------------------------------------------------------------------------------------------------------------------------------------------------------------				
-------------------------------------------------------------------------------read
            when write_tmp_to_cf_mem =>
                        
                if read_part = '1' then
                    if ack = '1' then
                        if err = '0' then
                            read_part	<= '0';
                            read_data_i <= read_data;
                        else
                            rd_temps_i <= '0';
                            state	   <= sleep;
                        end if;
                    else  -------------------------------------------------------
                        stb			 <= '1';
                        we			 <= '0';
                        reg_16_bit	 <= '0';
                        data_format	 <= FORMAT_16;
                        slave_addr	 <= tmp_slave_addr(counter)(6 downto 0);
                        upper_iic_on <= tmp_slave_addr(counter)(7);
                        reg_addr	 <= x"0000";
                    end if;
                -------------------------------------------------------------------------------write
                else
                    if cfmem_wb_ack = '1' then
                        read_part <= '1';
                        if counter = 0 then
                            rd_temps_i <= '0';
                            state	   <= sleep;
                        else
                            counter <= counter - 1;
                        end if;
                    else  -------------------------------------------------------
                        cfmem_wb_dout <= read_data_i(15 downto 0) & read_data_i(15 downto 0);
                        cfmem_wb_addr <= tmp_cf_mem_addr(counter);
                        cfmem_wb_we	  <= tmp_cf_mem_we(counter);
                        cfmem_wb_stb  <= '1';
                        cfmem_wb_cyc  <= '1';
                    end if;
                end if;
-------------------------------------------------------------------------------read
            when write_arw_stats_to_cf_mem =>

                if read_part = '1' then
                    if ack = '1' then
                        if err = '0' then
                            read_part	<= '0';
                            read_data_i <= read_data;
                        else
                            rd_stats_i <= '0';
                            state	   <= sleep;
                        end if;
                    else  -------------------------------------------------------
                        stb			 <= '1';
                        we			 <= '0';
                        reg_16_bit	 <= '0';
                        data_format	 <= FORMAT_32;
                        slave_addr	 <= arwstat_slave_addr(counter)(6 downto 0);
                        upper_iic_on <= arwstat_slave_addr(counter)(7);
                        reg_addr	 <= arwstat_rd_reg + std_logic_vector(to_unsigned(counter,8));
                    end if;
                -------------------------------------------------------------------------------write
                else
                    if cfmem_wb_ack = '1' then
                        read_part <= '1';
                        if counter = 0 then
                            rd_stats_i <= '0';
                            state	   <= sleep;
                        else
                            counter <= counter - 1;
                        end if;
                    else  -------------------------------------------------------
                        cfmem_wb_dout <= read_data_i;
                        cfmem_wb_addr <= arwstat_cf_mem_addr(counter);
                        cfmem_wb_we	  <= "1111";
                        cfmem_wb_stb  <= '1';
                        cfmem_wb_cyc  <= '1';
                    end if;
                end if;
--------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------read
            when set_arw_vals =>

            if read_part = '1' then
                if cfmem_wb_ack = '1' then
                    read_part	<= '0';
                    read_data_i <= cfmem_wb_din;
                else  -------------------------------------------------------
                    cfmem_wb_addr <= arw_cf_mem_addr(counter);
                    cfmem_wb_we	  <= b"0000";
                    cfmem_wb_stb  <= '1';
                    cfmem_wb_cyc  <= '1';
                end if;
            -------------------------------------------------------------------------------write
            else
                if ack = '1' then
                    if err = '0' then
                        read_part <= '1';
                        if counter = 0 then
                            set_IPs_i <= '0';
                            state	   <= sleep;
                        else
                            counter <= counter - 1;
                        end if;
                    else
                        set_IPs_i <= '0';
                        state	   <= sleep;
                    end if;
                else  -------------------------------------------------------
                    stb			 <= '1';
                    we			 <= '1';
                    reg_16_bit	 <= '0';
                    data_format	 <= FORMAT_32;
                    slave_addr	 <= arw_slave_addr(counter)(6 downto 0);
                    upper_iic_on <= arw_slave_addr(counter)(7);
                    reg_addr	 <= arw_addr_reg + (std_logic_vector(to_unsigned(counter,8)) & "00");
                    wr_part		 <= "1111";
                    write_data	 <= read_data_i;
                end if;
            end if;
            --------------------------------------------------------------------------------------------------------------------------------------------------------------
            -------------------------------------------------------------------------------read
            when set_dac_vals =>

                if read_part = '1' then
                    if cfmem_wb_ack = '1' then
                        read_part	<= '0';
                        read_data_i <= cfmem_wb_din;
                    else  -------------------------------------------------------
                        cfmem_wb_addr <= dac_cf_mem_addr(counter);
                        cfmem_wb_we	  <= b"0000";
                        cfmem_wb_stb  <= '1';
                        cfmem_wb_cyc  <= '1';
                    end if;
                -------------------------------------------------------------------------------write
                else
                    if ack = '1' then
                        if err = '0' then
                            read_part <= '1';
                            if counter = 0 then
                                set_DACs_i <= '0';
                                state	   <= sleep;
                            else
                                counter <= counter - 1;
                            end if;
                        else
                            set_DACs_i <= '0';
                            state	   <= sleep;
                        end if;
                    else  -------------------------------------------------------
                        stb			 <= '1';
                        we			 <= '1';
                        reg_16_bit	 <= '0';
                        data_format	 <= FORMAT_16;
                        slave_addr	 <= dac_slave_addr(counter)(6 downto 0);
                        upper_iic_on <= dac_slave_addr(counter)(7);
                        reg_addr	 <= dac_wr_reg(counter);
                        wr_part		 <= dac_we(counter);
                        write_data	 <= read_data_i;
                    end if;
                end if;
--------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------read
			when write_cf_mem_to_eeprom =>

				if read_part = '1' then
					if cfmem_wb_ack = '1' then
						read_part	<= '0';
						read_data_i <= cfmem_wb_din;
					else
						cfmem_wb_cyc  <= '1';
						cfmem_wb_stb  <= '1';
						cfmem_wb_we	  <= "0000";
						cfmem_wb_addr <= eeprom_cf_mem_start_addr(counter)+std_logic_vector(to_unsigned(reg_counter, 8));
					end if;
-------------------------------------------------------------------------------write
				else
					if ack = '1' then
						if err = '0' then
							read_part			<= '1';
							ack_polling_counter <= ack_polling_counter_const;
							if reg_counter = 0 then
								if counter = 0 then
									state					<= sleep;
									write_cfmem_to_eeprom_i <= '0';
								else
									counter		<= counter - 1;
									reg_counter <= eeprom_addr_counter_const;
								end if;
							else
								reg_counter <= reg_counter - 1;
							end if;
						else
							if ack_polling_counter = 0 then
								ack_polling_counter <= ack_polling_counter_const;
								if counter = 0 then
									state					<= sleep;
									write_cfmem_to_eeprom_i <= '0';
								else
									counter <= counter -1;
								end if;
							else
								ack_polling_counter <= ack_polling_counter - 1;
							end if;
						end if;
					else  -------------------------------------------------------
						stb			 <= '1';
						we			 <= '1';
						reg_16_bit	 <= '1';
						data_format	 <= FORMAT_32;
						reg_addr	 <= x"0" & b"00" & std_logic_vector(to_unsigned(reg_counter, 8)) & b"00";
						wr_part		 <= b"1111";
						write_data	 <= read_data_i;
						slave_addr	 <= eeprom_slave_addr(counter)(6 downto 0);
						upper_iic_on <= eeprom_slave_addr(counter)(7);
					end if;
				end if;
--------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------read
			when write_eeprom_to_cf_mem =>

				if read_part = '1' then
					if ack = '1' then
						if err = '0' then
							read_part	<= '0';
							read_data_i <= read_data;
						else
							write_eeprom_to_cfmem_i <= '0';
							state					<= sleep;
						end if;
					else  -------------------------------------------------------
						stb			 <= '1';
						we			 <= '0';
						reg_16_bit	 <= '1';
						data_format	 <= FORMAT_32;
						reg_addr	 <= x"0" & b"00" & std_logic_vector(to_unsigned(reg_counter, 8)) & b"00";
						wr_part		 <= b"0000";
						slave_addr	 <= eeprom_slave_addr(counter)(6 downto 0);
						upper_iic_on <= eeprom_slave_addr(counter)(7);
					end if;
-------------------------------------------------------------------------------write
				else
					if cfmem_wb_ack = '1' then
						read_part <= '1';
						if reg_counter = 0 then
							if counter = 0 then
								write_eeprom_to_cfmem_i <= '0';
								INIT_GP_i				<= '0';
								state					<= sleep;
							else
								counter		<= counter - 1;
								reg_counter <= eeprom_addr_counter_const;
							end if;
						else
							reg_counter <= reg_counter - 1;
						end if;
					else  -------------------------------------------------------
						cfmem_wb_cyc  <= '1';
						cfmem_wb_stb  <= '1';
						cfmem_wb_we	  <= "1111";
						cfmem_wb_addr <= eeprom_cf_mem_start_addr(counter)+std_logic_vector(to_unsigned(reg_counter, 8));
						cfmem_wb_dout <= read_data_i;
					end if;
				end if;
--------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------write
			when startup_dac =>

				if ack = '1' then
					if err = '0' then
						if counter = 0 then
							state	<= startup_temp;
							counter <= temp_startup_slave_addr'length -1;
						else
							counter <= counter -1;
						end if;
					else
						state	<= startup_temp;
						counter <= temp_startup_slave_addr'length -1;
					end if;
				else  -----------------------------------------------------------
					stb			 <= '1';
					we			 <= '1';
					reg_16_bit	 <= '0';
					data_format	 <= FORMAT_16;
					reg_addr	 <= dac_startup_reg;
					wr_part		 <= b"0011";
					write_data	 <= dac_startup_data;
					slave_addr	 <= dac_startup_slave_addr(counter)(6 downto 0);
					upper_iic_on <= dac_startup_slave_addr(counter)(7);
				end if;
--------------------------------------------------------------------------------------------------------------------------------------------------------------			
-------------------------------------------------------------------------------write
			when startup_temp =>

				if ack = '1' then
					if err = '0' then
						if counter = 0 then
							INIT_GP_i <= '0';
							state	  <= sleep;
						else
							counter <= counter -1;
						end if;
					else
						INIT_GP_i <= '0';
						state	  <= sleep;
					end if;
				else  -----------------------------------------------------------
					stb			 <= '1';
					we			 <= '1';
					reg_16_bit	 <= '0';
					data_format	 <= FORMAT_08;
					reg_addr	 <= temp_startup_reg;
					wr_part		 <= b"0001";
					write_data	 <= temp_startup_data;
					slave_addr	 <= temp_startup_slave_addr(counter)(6 downto 0);
					upper_iic_on <= temp_startup_slave_addr(counter)(7);
				end if;
--------------------------------------------------------------------------------------------------------------------------------------------------------------
			when others => null;
		end case;
	end process;


	gp_iic_wrapper_wrapper_1 : entity work.gp_iic_wrapper_wrapper
		generic map (
			SIM => SIM)
		port map (
			clk			 => clk,
			stb			 => stb,
			we			 => we,
			wr_part		 => wr_part,
			err			 => err,
			ack			 => ack,
			reg_addr	 => reg_addr,
			write_data	 => write_data,
			read_data	 => read_data,
			slave_addr	 => slave_addr,
			reg_16_bit	 => reg_16_bit,
			data_format	 => data_format,
			upper_iic_on => upper_iic_on,
			SCL			 => SCL,
			SDA			 => SDA);



end architecture behav;

--------------------------------------------------------------------------------------------------------------------------------------------------------------
