library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.g_parameters.all;

entity si_load is
	generic (
		do_load_si 	  : std_logic_vector(2 downto 0) := "111"
	);
	port (
        control       : inout   std_logic_vector(35 downto 0);
		rst			  : in	    std_logic;
		clk			  : in	    std_logic;	
		load_si	  	  : in	    std_logic;
		done		  : out	    std_logic;
		
		stb		      : out	    std_logic;
		we		      : out	    std_logic;
		err		      : in	    std_logic;
		ack		      : in 	    std_logic;
		reg_addr      : out	    std_logic_vector(7 downto 0);
		write_data    : out	    std_logic_vector(7 downto 0);
		read_data     : in		std_logic_vector(7 downto 0);
		n_si	      : out     integer range 0 to 2;
		
		cfmem_wb_cyc  : out	    std_logic;
		cfmem_wb_stb  : out	    std_logic;
		cfmem_wb_we	  : out	    std_logic_vector(3 downto 0);
		cfmem_wb_ack  : in	    std_logic;
		cfmem_wb_addr : out	    std_logic_vector (9 downto 0);
		cfmem_wb_din  : in	    std_logic_vector (31 downto 0);
		cfmem_wb_dout : out	    std_logic_vector (31 downto 0));
end si_load;

architecture logic of si_load is


-- cfmem signals
	signal cfmem_load		  : std_logic			  := '1';
	signal cfmem_write		  : std_logic			  := '0';
	signal cfmem_busy		  : std_logic			  := '0';
	signal cfmem_read_data	  : std_logic_vector (31 downto 0);
	signal cfmem_read_data_sr : std_logic_vector (31 downto 0);
	signal cfmem_write_data	  : std_logic_vector (31 downto 0);
	signal cfmem_write_addr	  : std_logic_vector (11 downto 0);
	signal cfmem_write_cnt	  : integer range 0 to 7  := 0;
	signal cfmem_addr_helper  : unsigned (9 downto 0) := (others => '0');


-- internal ctrl signals
	signal n_si_to_prog      : integer range 0 to 2	 := 0;
	signal n_si_register	 : integer range 0 to 44 := 0;
	signal n_si_byte_in_word : integer range 0 to 3	 := 0;

	signal cfmem_was_busy     : std_logic := '0';

    signal cfmem_wb_cyc_i	  :  std_logic;                                   
    signal cfmem_wb_stb_i	  :  std_logic;                                    
    signal cfmem_wb_we_i	  :  std_logic_vector(3 downto 0);                                   
    signal cfmem_wb_addr_i	  :  std_logic_vector(9 downto 0);                                   
    signal cfmem_wb_dout_i	  :  std_logic_vector(31 downto 0);                                  

-- state_machine
	type ctrl_state_type is (
		load,
		do_load,
		next_si,
		sleep
		);
	signal ctrl_state : ctrl_state_type := sleep;

-- chipscope
    component load_si_ila
        port (
            control     : inout std_logic_vector(35 downto 0);
            clk         : in    std_logic;
            data        : in    std_logic_vector(127 downto 0);
            trig0       : in    std_logic_vector(15 downto 0)
            );
    end component;

    signal ila_data : std_logic_vector(127 downto 0);
    signal ila_trg	: std_logic_vector(15 downto 0);


-- cfmem_handle
	type   cfmem_state_type is (read_cfmem, write_cfmem, sleep);
	signal cfmem_state : cfmem_state_type := sleep;

-- si iic register addresses
	type	 si_reg_addr is array (0 to 44) of std_logic_vector(7 downto 0);
	constant si_register : si_reg_addr :=
		(x"00", x"01", x"02", x"03", x"04", x"05", x"06", x"07", x"08", x"09", x"0A",
		 x"0B", x"10", x"11", x"12", x"13", x"14", x"15", x"16", x"17", x"18", x"19",
		 x"1F", x"20", x"21", x"22", x"23", x"24", x"28", x"29", x"2A", x"2B", x"2C",
		 x"2D", x"2E", x"2F", x"30", x"37", x"83", x"84", x"8A", x"8B", x"8E", x"8F",
		 x"88");

	type si_cf_addr_type is array (0 to 2) of unsigned(9 downto 0);
	constant si_conf_mem_addr : si_cf_addr_type := (b"10" & x"80",	 --Gandalf
													b"00" & x"80",	 --MezzUp
													b"01" & x"80");	 --MezzDown							

-- attributes
	attribute safe_implementation				 : string;
	attribute safe_implementation of ctrl_state	 : signal is "yes";
	attribute safe_implementation of cfmem_state : signal is "yes";

	attribute safe_recovery_state				 : string;
	attribute safe_recovery_state of ctrl_state	 : signal is "sleep";
	attribute safe_recovery_state of cfmem_state : signal is "sleep";

	
begin		
			
    Inst_chipscope : if USE_CHIPSCOPE_ILA_6 generate

        Inst_wb_to_ram_ila : load_si_ila
              port map (
                control     => control,
                clk         => clk,
                data        => ila_data,
                trig0       => ila_trg
                );

        ila_trg(0) <= cfmem_wb_cyc_i;
        ila_trg(1) <= cfmem_wb_stb_i;
        ila_trg(2) <= cfmem_wb_ack;

        ila_trg(3) <= '1' when ctrl_state = load else '0';
        ila_trg(4) <= '1' when ctrl_state = do_load else '0';
        ila_trg(5) <= '1' when ctrl_state = next_si else '0';
        ila_trg(6) <= '1' when ctrl_state = sleep else '0';

        ila_trg(7) <= '1' when cfmem_state = sleep else '0';
        ila_trg(8) <= '1' when cfmem_state = read_cfmem else '0';
        ila_trg(9) <= '1' when cfmem_state = write_cfmem else '0';

        

        ila_data(31 downto  0) <= cfmem_wb_din;
        ila_data(63 downto 32) <= cfmem_wb_dout_i;
        ila_data(67 downto 64) <= cfmem_wb_we_i;
        ila_data(77 downto 68) <= cfmem_wb_addr_i;

        ila_data(78) <= cfmem_load;		  
        ila_data(79) <= cfmem_write;		  
        ila_data(80) <= cfmem_busy;
        ila_data(81) <= cfmem_was_busy;

        ila_data(111 downto 82) <= (others => '0');


        ila_data(127 downto 112) <= ila_trg;

    end generate;

        -- Output signals
        cfmem_wb_cyc	<= cfmem_wb_cyc_i;	 
        cfmem_wb_stb	<= cfmem_wb_stb_i;	 
        cfmem_wb_we	    <= cfmem_wb_we_i;	 
        cfmem_wb_addr	<= cfmem_wb_addr_i;	 
        cfmem_wb_dout	<= cfmem_wb_dout_i;
        
        
        cfmem_process : process(clk,rst)
	begin
		if (rst = '1') then
			cfmem_wb_cyc_i	  <= '0';
			cfmem_wb_stb_i	  <= '0';
			cfmem_wb_we_i	  <= x"0";
			cfmem_wb_addr_i	  <= (others => '0');
			cfmem_wb_dout_i	  <= (others => '0');
			cfmem_busy		  <= '0';
			cfmem_addr_helper <= (others => '0');
            cfmem_state       <= sleep;

        elsif (rising_edge(clk)) then
                -- defaults, like recomended by Xilinx
            cfmem_wb_cyc_i	  <= '0';
            cfmem_wb_stb_i	  <= '0';
            cfmem_wb_we_i	  <= x"0";
            cfmem_wb_addr_i	  <= (others => '0');
            cfmem_wb_dout_i	  <= (others => '0');
            cfmem_busy		  <= '0';
            cfmem_addr_helper <= si_conf_mem_addr(n_si_to_prog) + to_unsigned(n_si_register, 6)(5 downto 2);
            case cfmem_state is
				when sleep =>
					if (cfmem_load = '1') then
						cfmem_state <= read_cfmem;
						cfmem_busy	<= '1';
					elsif (cfmem_write = '1') then
						cfmem_state <= write_cfmem;
						cfmem_busy	<= '1';
					end if;
				when read_cfmem =>
					cfmem_busy	    <= '1';
					cfmem_wb_stb_i  <= '1';
					cfmem_wb_cyc_i  <= '1';
					cfmem_wb_addr_i <= std_logic_vector(cfmem_addr_helper);
					if (cfmem_wb_ack = '1') then
						cfmem_state		<= sleep;
						cfmem_read_data <= cfmem_wb_din;
					end if;
				when write_cfmem =>
					cfmem_busy <= '1';
					if (cfmem_wb_ack = '1') then
						cfmem_state <= sleep;
					else
						cfmem_wb_cyc_i	  <= '1';
						cfmem_wb_stb_i	  <= '1';
						cfmem_wb_we_i	  <= x"f";
						cfmem_wb_addr_i	  <= cfmem_write_addr(9 downto 0);
						cfmem_wb_dout_i	  <= cfmem_write_data;
					end if;
				when others =>
										-- TODO handle state error
					cfmem_state <= sleep;
			end case;
		end if;
	end process;

	main_process : process(clk,rst)
	begin
		if (rst = '1') then
										-- defaults
			cfmem_load	    <= '0';
			cfmem_write     <= '0';
			stb             <= '0';
			we	            <= '0';
			cfmem_was_busy  <= '0';
            done            <= '0';
            
            ctrl_state      <= sleep;

        elsif rising_edge(clk) then
										-- defaults
			cfmem_load	    <= '0';
			cfmem_write     <= '0';
			stb             <= '0';
			we	            <= '0';		
			cfmem_was_busy  <= cfmem_busy;

			case ctrl_state is
					
				when sleep =>
					reg_addr        <= (others => '0');
					write_data      <= (others => '0');
					n_si	        <= 0;
					n_si_to_prog	<= 0;
					n_si_register   <= 0;					
					if (load_si = '1') then
						done		  	<= '0';
						ctrl_state		<= load;
					else
						ctrl_state <= sleep;
					end if;
					
				when load =>
					if do_load_si(n_si_to_prog) = '1' then
						n_si 			<= n_si_to_prog;
						ctrl_state 		<= do_load;
						cfmem_load		  <= '1';
						n_si_register	  <= 0;
						n_si_byte_in_word <= 0;
					else
						ctrl_state <= next_si;
					end if;
					
				when next_si =>
					if n_si_to_prog = 2 then
						ctrl_state	<= sleep;
						done 		<= '1';
					else
						n_si_to_prog <= n_si_to_prog + 1;
						ctrl_state <= load;
					end if;
				
				when do_load =>
					reg_addr	<= si_register(n_si_register);
					write_data	<= cfmem_read_data_sr(7 downto 0);

					if cfmem_was_busy = '1' and cfmem_busy = '0' then
						cfmem_read_data_sr <= cfmem_read_data;
					elsif cfmem_busy = '0' and cfmem_load = '0' then
						if ack = '1' then
							if n_si_register = 44 then
								ctrl_state	 <= next_si;
							else
								n_si_register <= n_si_register + 1;

								if n_si_byte_in_word = 3 then
										-- read the next config word from cfmem.
									cfmem_load		  <= '1';
									n_si_byte_in_word <= 0;
								else
										-- shift the actual word by 8 bit.
									cfmem_read_data_sr <= x"00" & cfmem_read_data_sr(31 downto 8);

									n_si_byte_in_word <= n_si_byte_in_word + 1;
								end if;
							end if;
						else
							stb <= '1';
							we	<= '1';
						end if;
					end if;
					
				when others =>
										-- TODO handle state error
					ctrl_state <= sleep;
			end case;
		end if;
	end process;

end logic;
