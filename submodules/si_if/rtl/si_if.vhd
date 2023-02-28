library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity si_if is
	generic (
		do_load_si 	  : std_logic_vector(2 downto 0) := "111";--MezzDwn(B),MezzUp(A),Gandalf 
		do_sweep_si   : std_logic_vector(2 downto 0) := "110";--MezzDwn(B),MezzUp(A),Gandalf 
		
		n_coarse_steps : integer := 50;
		n_fine_steps : integer := 2*22; -- maximum range
		n_samples : integer := 10000;
		
		-- for simu
		sim : boolean := False;
		coarse_step_size : time := 178.61225423 ps;
		fine_step_size : time := 5 ps;
		ff_delay : time := 20 ps 
	);
	port (
        control             : inout std_logic_vector(35 downto 0);
		clk				    : in    std_logic;
		cfmem_clk 		    : in    std_logic;
		spy_clk 		    : in    std_logic;
		tcs_clk  	        : in    std_logic;
		tcs_ce  	        : in    std_logic;
		tcs_rdy		        : in    std_logic;
		si_g_clk 		    : in    std_logic;
		si_a_clk 		    : in    std_logic;
		si_b_clk 		    : in    std_logic;
		rst 		        : in    std_logic;	
		done				: out   std_logic;
		si_g_oop			: out   std_logic;
		si_a_oop			: out   std_logic;
		si_b_oop			: out   std_logic;		
		fr_load_si	  		: in	std_logic;
		fr_sweep_si	  		: in	std_logic;
		fr_phase_align_si	: in	std_logic;
		
		sda			        : inout std_logic;
		scl			        : inout std_logic;

		cfmem_wb_cyc        : out	std_logic;
		cfmem_wb_stb        : out	std_logic;
		cfmem_wb_we	        : out	std_logic_vector(3 downto 0);
		cfmem_wb_ack        : in	std_logic;
		cfmem_wb_addr       : out	std_logic_vector(9 downto 0);
		cfmem_wb_din        : in	std_logic_vector(31 downto 0);
		cfmem_wb_dout       : out	std_logic_vector(31 downto 0);
		spy_wr 		        : out   std_logic;
		spy_do 		        : out   std_logic_vector(31 downto 0);
		spy_full 	        : in    std_logic
	);
end entity si_if;


architecture RTL of si_if is
	-- shiftregisters to detect edges on fastregisters	
	signal sr_load_si  		                : std_logic_vector(1 downto 0) := (others => '0');
	signal sr_sweep_si 		                : std_logic_vector(1 downto 0) := (others => '0');
	signal sr_phase_align_si                : std_logic_vector(1 downto 0) := (others => '0');

	signal load_si,load_done                : std_logic:='0';
	signal sweep_si,sweep_done              : std_logic:='0';
	signal phase_align_si,phase_align_done  : std_logic:='0';
	
	type   state_type is (idle, wait_load, wait_sweep, wait_phase_align);
	signal state : state_type := idle;
	
	-- iic signals
	signal stb		  	                    : std_logic;
	signal we		  	                    : std_logic;
	signal err		                        : std_logic;
	signal ack,ack_i		                : std_logic;
	signal reg_addr		                    : std_logic_vector(7 downto 0);
	signal write_data 	                    : std_logic_vector(7 downto 0):=(others => '0');
	signal read_data,read_data_i	        : std_logic_vector(7 downto 0);
	signal si_nr		                    : std_logic_vector(2 downto 0);
	
--	signal si_nr	  : std_logic_vector(2 downto 0);
	attribute KEEP				            : string;
	attribute KEEP of read_data	            : signal is "TRUE";
	
	signal reg_addr_load	                : std_logic_vector(7 downto 0);
	signal write_data_load 	                : std_logic_vector(7 downto 0);
	signal stb_load		  	                : std_logic;
	signal we_load		  	                : std_logic;
	signal n_si_to_prog_load                : integer range 0 to 2;

	signal reg_addr_sweep	  	            : std_logic_vector(7 downto 0);
	signal write_data_sweep 	            : std_logic_vector(7 downto 0);
	signal stb_sweep		  	            : std_logic;
	signal we_sweep		  		            : std_logic;
	signal n_si_to_prog_sweep               : integer range 0 to 2;
		
	-- si addresses (i2c)
	type	 si_addr_type is array (0 to 2) of std_logic_vector(2 downto 0);
	constant si_addr : si_addr_type := ("000", "010", "011");  --Gandalf,MezzUp,MezzDown 
	
	
	signal cfmem_wb_cyc_load,cfmem_wb_cyc_sweep : std_logic;
	signal cfmem_wb_stb_load,cfmem_wb_stb_sweep : std_logic;
	signal cfmem_wb_addr_load,cfmem_wb_addr_sweep : std_logic_vector(9 downto 0);

	
	component si_iic_top
	port (
		clk		        : in	    std_logic;
		stb		        : in	    std_logic;
		we		        : in	    std_logic;
		err		        : out       std_logic;
		ack		        : out       std_logic;
		reg_addr        : in	    std_logic_vector(7 downto 0);
		write_data      : in	    std_logic_vector(7 downto 0);
		read_data       : out       std_logic_vector(7 downto 0);
		si_nr	        : in	    std_logic_vector(2 downto 0);
		SCL		        : inout     std_logic;
		SDA		        : inout     std_logic
		);
	end component;
	
begin
	
	sim_iic: if sim generate
	begin
		ack_i <= '1' when stb = '1' else '0';
		read_data_i(7) <= '0';
	end generate;
	not_sim_iic: if not sim generate
	begin
	    read_data_i <= read_data;
		ack_i <= ack;
	end generate;
	
	-- mux the si iic signals, they will never (!!) run in parallel
	-- this is a bit ugly. One has to make sure, that all these signals are set to '0' in idle state
	stb 		        <= stb_sweep when load_done = '1' else stb_load;
    we 			        <= we_sweep when load_done = '1' else we_load;
    reg_addr 	        <= reg_addr_sweep when load_done = '1' else reg_addr_load;
    write_data 	        <= write_data_sweep when load_done = '1' else write_data_load;
    si_nr 		        <= si_addr(n_si_to_prog_sweep) when load_done = '1' else si_addr(n_si_to_prog_load);
    
    cfmem_wb_cyc        <= cfmem_wb_cyc_load or cfmem_wb_cyc_sweep;
    cfmem_wb_stb        <= cfmem_wb_stb_load or cfmem_wb_stb_sweep;
    cfmem_wb_addr       <= cfmem_wb_addr_load or cfmem_wb_addr_sweep;
        
    -- stb 		        <= stb_load;
    -- we 			        <= we_load;
    -- reg_addr 	        <= reg_addr_load;
    -- write_data 	        <= write_data_load;
    -- si_nr 		        <= si_addr(n_si_to_prog_load);
    -- 
    -- cfmem_wb_cyc        <= cfmem_wb_cyc_load;
    -- cfmem_wb_stb        <= cfmem_wb_stb_load;
    -- cfmem_wb_addr       <= cfmem_wb_addr_load;
            
            
	si_iic_top_1 : si_iic_top
	port map (
		clk		                => cfmem_clk,
		stb		                => stb,
		we		                => we,
		err		                => err,
		ack		                => ack,
		reg_addr                => reg_addr,
		write_data              => write_data,
		read_data               => read_data,
		si_nr	                => si_nr,
		SCL		                => SCL,
		SDA		                => SDA);
	
	si_load_inst : entity work.si_load
	generic map (
		do_load_si              => do_load_si
	)       
	port map( 
        control                 => control,      
		rst                     => rst,
		clk                     => cfmem_clk,
		load_si                 => load_si,
		done                    => load_done,
		stb		                => stb_load,
		we		                => we_load,
		err		                => err,
		ack		                => ack_i,
		reg_addr                => reg_addr_load,
		write_data              => write_data_load,
		read_data               => read_data_i,
		n_si  	                => n_si_to_prog_load,
		cfmem_wb_cyc            => cfmem_wb_cyc_load,
		cfmem_wb_stb            => cfmem_wb_stb_load,
		cfmem_wb_we             => cfmem_wb_we,
		cfmem_wb_ack            => cfmem_wb_ack,
		cfmem_wb_addr           => cfmem_wb_addr_load,
		cfmem_wb_din            => cfmem_wb_din,
		cfmem_wb_dout           => cfmem_wb_dout
	);
	
	
	si_sweep_inst : entity work.sweep_ctrl
	generic map(
		do_sweep_si => do_sweep_si,
		
		n_coarse_steps_default  => n_coarse_steps,
		n_fine_steps            => n_fine_steps,
		n_samples_default       => n_samples,
	
		-- for simu
		sim                     => sim,
		coarse_step_size        => coarse_step_size,
		fine_step_size          => fine_step_size,
		ff_delay                => ff_delay
	)
	port map(
		clk                     => clk,
		cfmem_clk	            => cfmem_clk,
		spy_clk		            => spy_clk,	
		tcs_clk  	            => tcs_clk,
		tcs_ce   	            => tcs_ce,
		tcs_rdy		            => tcs_rdy,
		si_g_clk	 	        => si_g_clk,
	    si_a_clk     	        => si_a_clk,
	    si_b_clk     	        => si_b_clk,			
		rst      		        => rst,
		sweep_si 		        => sweep_si,
		phase_align_si 	        => phase_align_si,
		sweep_done  	        => sweep_done,
		phase_align_done        => phase_align_done,
		si_g_oop		        => si_g_oop,
		si_a_oop		        => si_a_oop,
		si_b_oop		        => si_b_oop,
		stb		                => stb_sweep,
		we		                => we_sweep,
		err		                => err,
		ack		                => ack_i,
		reg_addr                => reg_addr_sweep,
		write_data              => write_data_sweep,
		read_data               => read_data_i,
		n_si     	            => n_si_to_prog_sweep,
		
		cfmem_stb               => cfmem_wb_stb_sweep,
		cfmem_cyc               => cfmem_wb_cyc_sweep,
		cfmem_ack               => cfmem_wb_ack,
		cfmem_din               => cfmem_wb_din,
		cfmem_addr              => cfmem_wb_addr_sweep,
	
		spy_wr                  => spy_wr,
		spy_do                  => spy_do,
		spy_full                => spy_full
		);
	

    -- Alex: probabilmente a noi non serve lo sweep_si ed il phase_align_si
    -- modificato il done <= load_done;
	done_sync : process is
	begin
		wait until rising_edge(tcs_clk);
		if tcs_ce = '1' then
			done <= load_done; -- and sweep_done and phase_align_done; -- (Alex)
		end if;
	end process;
	
	ctrl : process is
	begin
		wait until rising_edge(clk);
		
		sr_load_si	   		    <= sr_load_si(0) & fr_load_si;
		sr_sweep_si	   		    <= sr_sweep_si(0) & fr_sweep_si;
		sr_phase_align_si	    <= sr_phase_align_si(0) & fr_phase_align_si;
		
		load_si                 <= '0';
		sweep_si                <= '0';
		phase_align_si          <= '0';
		
		case state is
		when idle =>
			if sr_load_si = "01" then
				load_si <= '1';
				state <= wait_load;
			elsif sr_sweep_si = "01" then
				sweep_si <= '1';
				state <= wait_sweep;
			elsif sr_phase_align_si = "01" then
				phase_align_si <= '1';
				state <= wait_phase_align;				
			end if;
				
		when wait_load =>
			if load_si = '0' and load_done = '1' then
				-- sweep_si <= '1';
				-- state <= wait_sweep;
				state <= idle;
			end if;
		
		when wait_sweep =>
			if sweep_si = '0' and sweep_done = '1' then
				state <= idle;
			end if;
			
		when wait_phase_align =>
			if phase_align_si = '0' and phase_align_done = '1' then
				state <= idle;
			end if;
						
		end case; 		
		
	end process ctrl;
		
end architecture RTL;
