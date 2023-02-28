library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library unisim;
use unisim.vcomponents.all;
library unimacro;
use unimacro.vcomponents.all;

entity sweep_ctrl is
	generic (
		do_sweep_si 	  : std_logic_vector(2 downto 0) := "111";
		n_coarse_steps_default : integer;
		n_fine_steps : integer;
		n_samples_default : integer;
		n_bits_cnt : integer:=16;
		
		-- for simu
		sim : boolean := False;
		coarse_step_size : time;
		fine_step_size : time;
		ff_delay : time 
	);
	port (
		clk 		: in std_logic;
		cfmem_clk 		: in std_logic;
		spy_clk 		: in std_logic;
		tcs_clk  	: in std_logic;		
		tcs_ce  	: in std_logic;
		tcs_rdy		: in std_logic;
		si_g_clk 		: in std_logic;
		si_a_clk 		: in std_logic;
		si_b_clk 		: in std_logic;
		rst 		: in std_logic;
		
		n_si	    : out  integer range 0 to 2;
		sweep_si 	: in std_logic;
		phase_align_si 	: in std_logic;
		sweep_done  	: out std_logic;
		phase_align_done 	: out std_logic;
		si_g_oop			: out std_logic;
		si_a_oop			: out std_logic;
		si_b_oop			: out std_logic;
		
		stb		   : out	   std_logic;
		we		   : out	   std_logic;
		err		   : in		std_logic;
		ack		   : in 	std_logic;
		reg_addr   : out	std_logic_vector(7 downto 0);
		write_data : out	std_logic_vector(7 downto 0);
		read_data  : in		std_logic_vector(7 downto 0);
		
		cfmem_stb  : out std_logic;
		cfmem_cyc  : out std_logic;
		cfmem_ack  : in  std_logic;
		cfmem_din  : in  std_logic_vector(31 downto 0);
		cfmem_addr : out std_logic_vector(9 downto 0);
		
		spy_wr : out std_logic;
		spy_do : out std_logic_vector(31 downto 0);
		spy_full : in std_logic
	);
end entity sweep_ctrl;


architecture Behavioral of sweep_ctrl is
	
	signal rst_cnt,phase_align_done_i: std_logic;
	signal cnt_en,hit_cnt_en,hit_cnt_zero_en,hit_cnt_one_en : std_logic;
	signal cnt,hit_cnt,hit_cnt_zero,hit_cnt_one : std_logic_vector(n_bits_cnt-1 downto 0);
	signal ff_0 : std_logic:='0';
	signal ff_1 : std_logic:='0';
	signal spy_wr_i : std_logic;
	
	signal n_si_to_sweep : integer range 0 to 2;
	signal n_coarse_steps: integer range 0 to 255 := n_coarse_steps_default;
	signal n_coarse_step : integer range 0 to 255 := n_coarse_steps_default;
	signal n_fine_step : integer range 0 to n_fine_steps := n_fine_steps;
	
	signal n_samples	: unsigned(15 downto 0) := to_unsigned(n_samples_default,n_bits_cnt);
	signal dont_wait_tcs_rdy	: std_logic:='0';
	
	type   ctrl_type is (startup, init, load_cfg, wait_load_cfg, wait_init_fine_step, next_si, count, wait_count, count_done, do_coarse_step, do_fine_step, reset_fine_step, wait_reset_fine_step, wait_coarse_step, wait_fine_step, load, wait_load, next_si_load, load_fine_step, wait_load_fine_step, load_coarse_step, wait_load_coarse_step, idle);
	type   ctrl_sr_type is array (1 downto 0) of ctrl_type;
	signal ctrl_state : ctrl_type := startup;
	signal ctrl_state_sr : ctrl_sr_type;

	type   edge_count_state_type is (start_count, wait_load_count,start_monitor,wait_start_monitor,monitor, count, write_count, wait_write_count, idle);
	type   edge_count_state_sr_type is array (1 downto 0) of edge_count_state_type;
	signal edge_count_state : edge_count_state_type := idle;
	signal edge_count_state_sr : edge_count_state_sr_type;
	signal edge_count_state_spy_sr : edge_count_state_sr_type;

	type   spy_write_type is (step, count, count_zero, count_one, idle);
	type   spy_write_sr_type is array (1 downto 0) of spy_write_type;
    signal spy_write_state : spy_write_type := idle;
    signal spy_write_state_sr : spy_write_sr_type;
	
	type   load_state_type is (load_phase_cfg, wait_load_phase_cfg, load_sweep_cfg, wait_load_sweep_cfg, idle);
	signal load_ctrl_state : load_state_type := idle;

	type   monitor_state_type is (change_si, start_monitor, wait_monitor);
	type   monitor_state_sr_type is array (1 downto 0) of monitor_state_type;
	signal monitor_state : monitor_state_type := change_si;
	signal monitor_state_sr : monitor_state_sr_type;
		
	type si_cf_addr_type is array (0 to 2) of std_logic_vector(9 downto 0);
	constant si_conf_mem_addr : si_cf_addr_type := (b"10" & x"8C",	 --Gandalf
													b"00" & x"8C",	 --MezzUp
													b"01" & x"8C");	 --MezzDown	
													
			
	signal coarse_incr,fine_incr : std_logic := '0';
	signal coarse_load,fine_load : std_logic := '0';
	signal coarse_done,fine_done : std_logic := '0';
	signal coarse_rst,fine_rst : std_logic := '0';	
	signal coarse_value,fine_value : unsigned(7 downto 0);
	signal cfmem_value : std_logic_vector(31 downto 0);

	signal oop,monitored_oop,mon_val	: std_logic_vector(2 downto 0):=(others => '0');

	signal reg_addr_fine	: std_logic_vector(7 downto 0);
	signal write_data_fine 	: std_logic_vector(7 downto 0);
	signal stb_fine		  	: std_logic;
	signal we_fine		  	: std_logic;
	
	signal reg_addr_coarse	  	: std_logic_vector(7 downto 0);
	signal write_data_coarse 	: std_logic_vector(7 downto 0);
	signal stb_coarse		  	: std_logic;
	signal we_coarse		  	: std_logic;
	
	
	attribute KEEP : string;
	attribute KEEP of reg_addr_fine	 	 : signal is "TRUE";
	attribute KEEP of reg_addr_coarse	 : signal is "TRUE";
	attribute KEEP of write_data_fine	 : signal is "TRUE";
	attribute KEEP of write_data_coarse	 : signal is "TRUE";
	attribute KEEP of monitor_state_sr   : signal is "TRUE";
	attribute KEEP of edge_count_state_sr: signal is "TRUE";
	attribute KEEP of ctrl_state_sr		 : signal is "TRUE";
	
begin
	
	-- mux the si signals, they will never (!!) run in parallel
	stb 				<= stb_coarse or stb_fine;
	we 					<= we_coarse or we_fine;
	reg_addr 			<= reg_addr_coarse or reg_addr_fine;
	write_data 			<= write_data_coarse or write_data_fine;
	n_si 				<= n_si_to_sweep;
	phase_align_done 	<= phase_align_done_i;
	
	-- write oop bits synchonous to tcs_clk_38, they are used in other clk domains that are in phase with that clk
	oop_proc : process is
	begin
		wait until rising_edge(tcs_clk);
		if tcs_ce = '1' then
			si_g_oop <= oop(0) or monitored_oop(0);
			si_a_oop <= oop(1) or monitored_oop(1);
			si_b_oop <= oop(2) or monitored_oop(2);
		end if;
	end process;

	
	coarse_phase_shift : entity work.si_phase_shift
		generic map(
			mode  => "coarse"
		)
		port map(
			clk  => cfmem_clk,
			rst  => coarse_rst,
			incr => coarse_incr,
			load => coarse_load,
			value=> coarse_value,
			done => coarse_done,
			stb		   => stb_coarse,
			we		   => we_coarse,
			err		   => err,
			ack		   => ack,
			reg_addr   => reg_addr_coarse,
			write_data => write_data_coarse,
			read_data  => read_data
		);

	fine_phase_shift : entity work.si_phase_shift
		generic map(
			mode  => "fine"
		)
		port map(
			clk  => cfmem_clk,
			rst  => fine_rst,
			incr => fine_incr,
			load => fine_load,
			value=> fine_value,
			done => fine_done,
			stb		   => stb_fine,
			we		   => we_fine,
			err		   => err,
			ack		   => ack,
			reg_addr   => reg_addr_fine,
			write_data => write_data_fine,
			read_data  => read_data
		);
		
	zero_counter : COUNTER_LOAD_MACRO
		generic map (
			COUNT_BY   => X"000000000001",	-- Count by value
			DEVICE	   => "VIRTEX5",  -- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6" 
			WIDTH_DATA => n_bits_cnt)			-- Counter output bus width, 1-48
		port map (
			Q		  => hit_cnt_zero,	 -- Counter output, width determined by WIDTH_DATA generic 
			CLK		  => tcs_clk,			-- 1-bit clock input
			CE		  => hit_cnt_zero_en,			-- 1-bit clock enable input
			DIRECTION => '1',  -- 1-bit up/down count direction input, high is count up
			LOAD	  => rst_cnt,	-- 1-bit active high load input
			LOAD_DATA => std_logic_vector(to_unsigned(0,n_bits_cnt)),  -- Counter load data, width determined by WIDTH_DATA generic 
			RST		  => '0'  -- 1-bit active high synchronous reset
			);
	one_counter : COUNTER_LOAD_MACRO
		generic map (
			COUNT_BY   => X"000000000001",	-- Count by value
			DEVICE	   => "VIRTEX5",  -- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6" 
			WIDTH_DATA => n_bits_cnt)			-- Counter output bus width, 1-48
		port map (
			Q		  => hit_cnt_one,	 -- Counter output, width determined by WIDTH_DATA generic 
			CLK		  => tcs_clk,			-- 1-bit clock input
			CE		  => hit_cnt_one_en,			-- 1-bit clock enable input
			DIRECTION => '1',  -- 1-bit up/down count direction input, high is count up
			LOAD	  => rst_cnt,	-- 1-bit active high load input
			LOAD_DATA => std_logic_vector(to_unsigned(0,n_bits_cnt)),  -- Counter load data, width determined by WIDTH_DATA generic 
			RST		  => '0'  -- 1-bit active high synchronous reset
			);
	undef_counter : COUNTER_LOAD_MACRO
		generic map (
			COUNT_BY   => X"000000000001",	-- Count by value
			DEVICE	   => "VIRTEX5",  -- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6" 
			WIDTH_DATA => n_bits_cnt)		-- Counter output bus width, 1-48
		port map (
			Q		  => hit_cnt,	 -- Counter output, width determined by WIDTH_DATA generic 
			CLK		  => tcs_clk,			-- 1-bit clock input
			CE		  => hit_cnt_en,			-- 1-bit clock enable input
			DIRECTION => '1',  -- 1-bit up/down count direction input, high is count up
			LOAD	  => rst_cnt,	-- 1-bit active high load input
			LOAD_DATA => std_logic_vector(to_unsigned(0,n_bits_cnt)),  -- Counter load data, width determined by WIDTH_DATA generic 
			RST		  => '0'  -- 1-bit active high synchronous reset
			);
	counter : COUNTER_LOAD_MACRO
		generic map (
			COUNT_BY   => X"000000000001",	-- Count by value
			DEVICE	   => "VIRTEX5",  -- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6" 
			WIDTH_DATA => n_bits_cnt)			-- Counter output bus width, 1-48
		port map (
			Q		  => cnt,	 -- Counter output, width determined by WIDTH_DATA generic 
			CLK		  => tcs_clk,			-- 1-bit clock input
			CE		  => cnt_en,			-- 1-bit clock enable input
			DIRECTION => '0',  -- 1-bit up/down count direction input, high is count up
			LOAD	  => rst_cnt,	-- 1-bit active high load input
			LOAD_DATA => std_logic_vector(n_samples),  -- Counter load data, width determined by WIDTH_DATA generic 
			RST		  => '0'  -- 1-bit active high synchronous reset
			);
															
	edge_count: process is
	begin 
		wait until rising_edge(tcs_clk);
		
		rst_cnt 		<= '0';
		cnt_en 			<= '0';
		hit_cnt_en 		<= '0';
		hit_cnt_zero_en <= '0';
		hit_cnt_one_en 	<= '0';
		
		ctrl_state_sr <= ctrl_state_sr(0)&ctrl_state;
		monitor_state_sr <= monitor_state_sr(0)&monitor_state;
		spy_write_state_sr <= spy_write_state_sr(0)&spy_write_state;
		
		
		case edge_count_state is
        when start_count =>
            rst_cnt 		<= '1';
			cnt_en 			<= '1';
			hit_cnt_en 		<= '1';
			hit_cnt_zero_en <= '1';
			hit_cnt_one_en 	<= '1';
            edge_count_state <= wait_load_count;
        
        when wait_load_count =>
            rst_cnt 		<= '1';
            cnt_en 			<= '1';
            hit_cnt_en 		<= '1';
            hit_cnt_zero_en <= '1';
            hit_cnt_one_en 	<= '1';
            edge_count_state <= count;
                        
        when count =>
    	    if unsigned(cnt) = 0 then
                edge_count_state <= write_count;
            elsif tcs_ce = '1' then
	            cnt_en <= '1';
	            if ff_0 = '0' and ff_1 = '0' then
	                hit_cnt_zero_en <= '1';
	            elsif ff_0 = '1' and ff_1 = '1' then
	                hit_cnt_one_en <= '1';
	            else
	                hit_cnt_en <= '1';
	            end if;
			end if;
			
		when start_monitor =>
			if ctrl_state_sr(1) /= idle then
				edge_count_state <= idle;
			end if;			
            rst_cnt 			<= '1';
			cnt_en 				<= '1';
			edge_count_state 	<= wait_start_monitor;
			
		when wait_start_monitor =>
			if ctrl_state_sr(1) /= idle then
				edge_count_state <= idle;
			end if;	
            rst_cnt 			<= '1';
			cnt_en 				<= '1';			
			edge_count_state 	<= monitor;
			
		when monitor =>
			if unsigned(cnt) = 0 or ctrl_state_sr(1) /= idle then
				edge_count_state <= idle;
            elsif tcs_ce = '1' then
	            cnt_en <= '1';				
				if ff_0 /= mon_val(n_si_to_sweep) or ff_1 /= mon_val(n_si_to_sweep) then
					monitored_oop(n_si_to_sweep) <= '1';
				end if;
			end if;
					
		when write_count =>
			if spy_write_state_sr(1) /= idle then
				edge_count_state <= wait_write_count;
			end if;
		
		when wait_write_count =>
			if spy_write_state_sr(1) = idle then
				edge_count_state <= idle;
			end if;
			  
        when idle =>
        	if ctrl_state_sr(1) = count then
        		edge_count_state <= start_count;
        	elsif ctrl_state_sr(1) = idle and monitor_state_sr(1) = start_monitor then
        		edge_count_state <= start_monitor;
        	end if;
        	
    	end case;
    	
    	if phase_align_done_i = '0' then
    		monitored_oop	<= (others => '0');
    	end if;
    	
    	 -- on reset, overwrite state and done
    	 if rst ='1' then
    	 	monitored_oop	<= (others => '0');
            rst_cnt 		<= '1';
			cnt_en 			<= '1';
			hit_cnt_en 		<= '1';
			hit_cnt_zero_en <= '1';
			hit_cnt_one_en 	<= '1';    	 	
        	edge_count_state <= idle;	
        end if;	
        
	end process;
	
	spy_wr <= spy_wr_i;
	spy_proc : process is
	begin
		wait until rising_edge(spy_clk);
		edge_count_state_spy_sr <= edge_count_state_spy_sr(0)&edge_count_state;
		
		spy_wr_i <= '0';
    	spy_do <= (others => '0');
    	
    	if spy_full = '0' and tcs_ce='1' and spy_wr_i='0' then
	    	case spy_write_state is
	    	when idle =>
	    		if edge_count_state_spy_sr(1) = write_count then
	    			spy_write_state <= step;
	    		end if;              
	        when step =>
	            spy_wr_i <= '1';
	            spy_do(31) <= '1';
	            spy_do(30 downto 29) <= std_logic_vector(to_unsigned(n_si_to_sweep, 2));
	            spy_do(15 downto 8) <= std_logic_vector(to_unsigned(n_coarse_step,8));
	            spy_do(7 downto 0) <= std_logic_vector(to_unsigned(n_fine_step,8));
	            spy_write_state <= count;
	        when count =>
	            spy_wr_i <= '1';
	            spy_do(n_bits_cnt-1 downto 0) <= hit_cnt;
	            spy_write_state <= count_zero;
	        when count_zero =>		
	            spy_wr_i <= '1';		
	            spy_do(n_bits_cnt-1 downto 0) <= hit_cnt_zero;
	            spy_write_state <= count_one;
	        when count_one =>		
	            spy_wr_i <= '1';		
	            spy_do(n_bits_cnt-1 downto 0) <= hit_cnt_one;
	            spy_write_state <= idle;
	        end case;
	    end if;
    end process;    	
	
	load_proc : process is
	begin
		wait until rising_edge(cfmem_clk);
		
		cfmem_addr 		<= (others => '0');
		cfmem_stb  		<= '0';
		cfmem_cyc  		<= '0';
		
		case load_ctrl_state is
		when idle =>
        	if ctrl_state = load then
        		load_ctrl_state <= load_phase_cfg;
        	end if;
         	if ctrl_state = load_cfg then
        		load_ctrl_state <= load_sweep_cfg;
        	end if;
        	       	
		when load_phase_cfg =>
			cfmem_addr 		<= si_conf_mem_addr(n_si_to_sweep);
			cfmem_stb 		<= '1';
			cfmem_cyc  		<= '1';
			load_ctrl_state <= wait_load_phase_cfg;
		when wait_load_phase_cfg =>
			if cfmem_ack = '1' then
				cfmem_value 	<= cfmem_din;
				load_ctrl_state <= idle;
			else
				cfmem_addr 		<= si_conf_mem_addr(n_si_to_sweep);
				cfmem_stb 		<= '1';
				cfmem_cyc  		<= '1';
			end if;
			
		when load_sweep_cfg =>
			cfmem_addr 		<= std_logic_vector(unsigned(si_conf_mem_addr(0)) + 1);
			cfmem_stb 		<= '1';
			cfmem_cyc  		<= '1';
			load_ctrl_state <= wait_load_sweep_cfg;
		when wait_load_sweep_cfg =>
			if cfmem_ack = '1' then
				cfmem_value 	<= cfmem_din;
				load_ctrl_state <= idle;
			else
				cfmem_addr 		<= std_logic_vector(unsigned(si_conf_mem_addr(0)) + 1);
				cfmem_stb 		<= '1';
				cfmem_cyc  		<= '1';
			end if;
		end case;
	end process;
					
		
	ctrl : process is
	begin
		wait until rising_edge(clk);
        
        fine_rst <= '0';
        fine_incr <= '0';
        fine_load <= '0';
	coarse_rst <= '0';
        coarse_incr <= '0';
        coarse_load <= '0';
        
        edge_count_state_sr <= edge_count_state_sr(0)&edge_count_state;
        
        case ctrl_state is
        when load_cfg =>
        	if load_ctrl_state = load_sweep_cfg then
        		ctrl_state <= wait_load_cfg;
        	end if;        	
        when wait_load_cfg =>
        	if load_ctrl_state = idle then
        		if unsigned(cfmem_value(31 downto 16))>0 then
        			n_samples		<= unsigned(cfmem_value(31 downto 16));
        		else
        			n_samples		<= to_unsigned(n_samples_default, n_bits_cnt);        			
        		end if;
        		if unsigned(cfmem_value(15 downto 8))>0 then
        			n_coarse_steps 	<= to_integer(unsigned(cfmem_value(15 downto 8)));
        		else
        			n_coarse_steps 	<= n_coarse_steps_default;
        		end if;
        		dont_wait_tcs_rdy  	<= cfmem_value(0);
        		ctrl_state 			<= init;
        	end if;
        when init =>
        	if dont_wait_tcs_rdy = '1' or tcs_rdy = '1' then
				if do_sweep_si(n_si_to_sweep) = '1' then
		        	n_coarse_step <= n_coarse_steps;
		            n_fine_step <= n_fine_steps;
		            fine_rst <= '1';
		            if fine_rst = '1' and fine_done = '0' then
		                ctrl_state <= wait_init_fine_step;
		            end if;
				else
					ctrl_state <= next_si;
				end if;
			end if;
			
		when wait_init_fine_step =>
			if fine_done = '1' then
	            coarse_rst <= '1';
	            if coarse_rst = '1' and coarse_done = '0' then
	                ctrl_state <= wait_coarse_step;
	            end if;
	        end if;
	                        
		when next_si =>
			if n_si_to_sweep = 2 then
				ctrl_state	<= idle;
				sweep_done 	<= '1';
			else
				n_si_to_sweep <= n_si_to_sweep + 1;
				ctrl_state <= init;				
			end if;        
        
        when count =>
        	if edge_count_state_sr(1) /= idle then
        		ctrl_state <= wait_count;
        	end if;
        	
        when wait_count =>        	
	        if edge_count_state_sr(1) = idle then
	        	ctrl_state <= count_done;
	        end if;
	        	
	    when count_done =>	       	
            if n_fine_step = 0 then
                n_fine_step <= n_fine_steps;
                if n_coarse_step = 0 then
                	ctrl_state <= next_si;
                else
                    n_coarse_step <= n_coarse_step - 1;
                    ctrl_state <= reset_fine_step; -- reset the fine steps to initial value before a coarse step change
                end if;					
            else
                n_fine_step <= n_fine_step - 1;
                ctrl_state <= do_fine_step;
            end if;
	        
	    when reset_fine_step =>
            fine_rst <= '1';
            if fine_rst = '1' and fine_done = '0' then
                ctrl_state <= wait_reset_fine_step;
            end if;
                	
	    when wait_reset_fine_step =>
            if fine_done = '1' then
                ctrl_state <= do_coarse_step;
            end if;	 
                        
        when do_coarse_step =>
            coarse_incr <= '1';
            if coarse_incr = '1' and coarse_done = '0' then
                ctrl_state <= wait_coarse_step;
            end if;
        
        when wait_coarse_step =>
            if coarse_done = '1'  then
                ctrl_state <= count;
            end if;
            
        when do_fine_step =>
            fine_incr <= '1';
            if fine_incr = '1' and fine_done = '0' then
                ctrl_state <= wait_fine_step;
            end if;
        
        when wait_fine_step =>
            if fine_done = '1' then
                ctrl_state <= count;
            end if;
        
		when next_si_load =>
			if n_si_to_sweep = 2 then
				ctrl_state	<= idle;
				phase_align_done_i 	<= '1';
			else
				n_si_to_sweep <= n_si_to_sweep + 1;
				ctrl_state <= load;				
			end if;    
			
		when load =>
        	if load_ctrl_state = load_phase_cfg then
        		ctrl_state <= wait_load;
        	end if;
        
        when wait_load =>
        	if load_ctrl_state = idle then
        		if do_sweep_si(n_si_to_sweep) = '1' and cfmem_value(31) = '1' then
        			mon_val(n_si_to_sweep)	<= cfmem_value(29);
        			coarse_value 	<= to_unsigned(n_coarse_steps,8) - unsigned(cfmem_value(15 downto 8));
        			fine_value 		<= to_unsigned(n_fine_steps,8) - unsigned(cfmem_value(7 downto 0));
        			ctrl_state 		<= load_fine_step;
        		else
        			ctrl_state <= next_si_load;
        		end if;
        	end if;
        
        when load_fine_step =>
        	fine_load <= '1';
        	if fine_load = '1' and fine_done = '0' then
        		ctrl_state <= wait_load_fine_step;
        	end if;
        	
        when wait_load_fine_step =>
            if fine_done = '1' then
                ctrl_state <= load_coarse_step;
            end if;
                	
        when load_coarse_step =>
        	coarse_load <= '1';
        	if coarse_load = '1' and coarse_done = '0' then
        		ctrl_state <= wait_load_coarse_step;
        	end if;
        	
        when wait_load_coarse_step =>
        	if coarse_done = '1' then
        		oop(n_si_to_sweep) <= not cfmem_value(30);
            	ctrl_state <= next_si_load;            	
            end if;
        
        when idle =>
        	coarse_value <= (others => '0');
        	fine_value <= (others => '0');
        	
        	-- when idle, circulate through si to monitor
        	case monitor_state is
        	when change_si =>
	        	if n_si_to_sweep = 2 then
	        		n_si_to_sweep <= 0;
	        	else
	        		n_si_to_sweep <= n_si_to_sweep+1;
	        	end if;
	        	monitor_state <= start_monitor;
        	when start_monitor =>
	        	if edge_count_state_sr(1) /= idle then
	        		monitor_state <= wait_monitor;
	        	end if;
	        when wait_monitor =>
	        	if edge_count_state_sr(1) = idle then
	        		monitor_state <= change_si;
	        	end if;
	        end case;
	        	        	
        	if sweep_si = '1' then
        		n_si_to_sweep <= 0;
            	sweep_done <= '0';
            	phase_align_done_i <= '0';
                ctrl_state <= load_cfg;
                monitor_state <= change_si;
            end if;
            if phase_align_si = '1' then
            	n_si_to_sweep <= 0;
            	phase_align_done_i <= '0';
            	ctrl_state <= load;
            	monitor_state <= change_si;
            end if;
            
            
            
        when startup =>
        	sweep_done 			<= '0';
        	phase_align_done_i 	<= '0';        	
        	oop 				<= (others => '1');
        	ctrl_state 			<= idle;        	
        	
        end case;
            
            
        -- on reset, overwrite state and done
        if rst ='1' then
        	ctrl_state 			<= idle;
            sweep_done 			<= '0';
            phase_align_done_i 	<= '0';
            oop 				<= (others => '1');
        end if;		
	end process ctrl;
	
	
	actual_si: if not sim generate
		signal si_clk 		    :  std_logic;
		signal n_si_to_sweep_i  : std_logic_vector(1 downto 0);
		attribute rloc: string;
		attribute rloc of ff_0_inst : label is "X0Y0";
		attribute rloc of ff_1_inst : label is "X0Y10";
	begin
		n_si_to_sweep_i <= std_logic_vector(to_unsigned(n_si_to_sweep,2));
		with n_si_to_sweep_i select 
            si_clk <=   si_g_clk when "00",
			            si_a_clk when "01",
			            si_b_clk when "10",
			            '0' when others;
		ff_0_inst: FDE port map (
			Q => ff_0,
			D => si_clk,
			C => tcs_clk,
			CE =>tcs_ce);
		ff_1_inst: FDE port map (
			Q => ff_1,
			D => si_clk,
			C => tcs_clk,
			CE =>tcs_ce);
	end generate;
	
	sim_si: if sim generate
		signal si_clk 	  :  std_logic_vector(2 downto 0);
		signal si_clk_dly :  std_logic_vector(2 downto 0);
		signal i_fine_step : integer:=0;
		signal i_coarse_step : integer:=0;
	begin
		si_clk <= si_b_clk & si_a_clk & si_g_clk;
		i_fine_step <= n_fine_steps - n_fine_step when n_fine_step>=0 else 0;
		i_coarse_step <= n_coarse_steps - n_coarse_step when n_coarse_step>=0 else 0;
		si_clk_dly <= transport si_clk after (i_coarse_step * coarse_step_size + i_fine_step * fine_step_size); 
		ff_0 <= si_clk_dly(n_si_to_sweep);
		ff_1 <= transport si_clk_dly(n_si_to_sweep) after ff_delay;
	end generate;	
	
end architecture Behavioral;
