library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity si_phase_shift is
	generic (
		mode : string := "coarse" -- 'coarse' or 'fine'
	);
	port (
		clk : in std_logic;
		rst : in std_logic;
		incr : in std_logic;
		load : in std_logic;
		value : in unsigned(7 downto 0);
		done : out std_logic;

		stb		   : out	   std_logic;
		we		   : out	   std_logic;
		err		   : in		std_logic;
		ack		   : in 	std_logic;
		reg_addr   : out	std_logic_vector(7 downto 0);
		write_data : out	std_logic_vector(7 downto 0);
		read_data  : in		std_logic_vector(7 downto 0)
	);
end entity si_phase_shift;


architecture RTL of si_phase_shift is
		
	constant coarse_step_increment : integer := 1;
	constant coarse_step_offset : unsigned(15 downto 0) := X"0000";--X"0072";
	
	-- the offset and increment depend on the setting of BWSEL !!
	constant fine_step_increment : integer := -1;
	constant fine_step_offset : unsigned(15 downto 0) := X"0016";--;X"0580"; -- this should be -22*fine_step_increment
	
begin


step_fine : if mode = "fine" generate
	type   state_type is (reset, step, do_load, write_lsb, write_msb, flat_valid, flat_not_valid, wait_read, wait_write, idle);
	signal state : state_type := idle;
	
	signal next_state : state_type;
	signal n_step,next_step : unsigned(15 downto 0):=fine_step_offset;
begin
	
	do_step : process is
	begin
		wait until rising_edge(clk);
		
		done <= '0';
		stb  <= '0';
		we 	 <= '0';
				
		case state is
		when reset =>
			next_step <= fine_step_offset; -- finesteps go from -110ps (flat val 22) to +110ps (flat val )
			state <= flat_not_valid;
			
		when step =>
			next_step <= n_step - 1;--X"40";
			state <= flat_not_valid;
			
		when do_load =>
			next_step <= fine_step_offset - value;
			state <= flat_not_valid;
				
		when flat_not_valid =>
			reg_addr		  <= x"11";	 -- flat_valid&flat_msb
			write_data		  <= '0'&std_logic_vector(n_step(14 downto 8));
			stb				  <= '1';
			we				  <= '1';
			state		  	  <= wait_write;
			next_state		  <= write_lsb;
				
		when write_lsb =>
			reg_addr		  <= x"12";	 -- flat
			write_data		  <= std_logic_vector(next_step(7 downto 0));
			stb				  <= '1';
			we				  <= '1';
			state		  	  <= wait_write;
			next_state        <= write_msb;
		
		when write_msb =>
			reg_addr		  <= x"11";	 -- flat_valid&flat_msb
			write_data		  <= '0'&std_logic_vector(next_step(14 downto 8));
			stb				  <= '1';
			we				  <= '1';
			state		  	  <= wait_write;
			next_state        <= flat_valid;			

		when flat_valid =>
			reg_addr		  <= x"11";	 -- flat_valid&flat_msb
			write_data		  <= '1'&std_logic_vector(next_step(14 downto 8));
			stb				  <= '1';
			we				  <= '1';
			state		  	  <= wait_write;
			next_state		  <= idle;
			n_step			  <= next_step;
						
		when wait_read =>
			if ack = '1' then
				state 	 <= next_state;
			else
				stb <= '1';
				we	<= '0';
			end if;			
			
		when wait_write =>
			if ack = '1' then
--				state 	   <= wait_read;
				state 	   <= next_state;
			else
				stb <= '1';
				we	<= '1';
			end if;
					
		when idle =>
			reg_addr <= (others => '0');
			write_data <= (others => '0');
			if load = '1' then
				state <= do_load;
			elsif incr = '1' then
				state <= step;
			else
				done <= '1';			
			end if;			
		end case;		
		
		-- on reset, overwrite state and done
		if rst ='1' then
			state <= reset;
			done <= '0';		
		end if;		
	end process do_step;
end generate;
	
step_coarse : if mode = "coarse" generate
	type   state_type is (reset, step, do_load, idle, write, read_incdec, wait_read, wait_read_clatdone, wait_write, block_clat, release_clat);
	signal state : state_type := idle;
	
	type state_sequence_type is array(0 to 10) of state_type;
	constant reset_state_sequence : state_sequence_type := (
		reset, 
		read_incdec, 
		wait_read,
		block_clat,
		wait_write,
		write,
		wait_write,
		wait_read_clatdone,
		release_clat,
		wait_write,
		idle
	);
	
	constant load_state_sequence : state_sequence_type := (
		do_load,
		write,
		wait_write,
		wait_read_clatdone,
		idle,
		idle,idle,idle,idle,idle,idle -- hmm.. ugly
		
	);
	
	constant step_state_sequence : state_sequence_type := (
		step,
		write,
		wait_write,
		wait_read_clatdone,
		idle,
		idle,idle,idle,idle,idle,idle -- hmm.. ugly
	);
	
	signal active_sequence : state_sequence_type;
	signal n_step : unsigned(15 downto 0):=coarse_step_offset;
	signal state_cnt : integer range 0 to 11 := 0;
	signal last_read_data,inc_dec_reg : std_logic_vector(7 downto 0);
begin
	do_step : process is
	begin
		wait until rising_edge(clk);
		
		done <= '0';
		stb  <= '0';
		we 	 <= '0';
						
		case state is
		-- reset registers, but keep current position
		when reset =>
			n_step 		<= coarse_step_offset;  -- coarsesteps go from -25ns (clat val 22) to +25ns (clat val )
			state 		<= active_sequence(state_cnt);
			state_cnt 	<= state_cnt + 1;		
		
		when read_incdec =>
			reg_addr		  <= x"15";	 -- INCDEC_PIN
			stb				  <= '1';
			state 		<= active_sequence(state_cnt);
			state_cnt 	<= state_cnt + 1;		

		when release_clat =>
			write_data 		<= '0'&inc_dec_reg(6 downto 0);
			reg_addr		<= x"15";	 -- INCDEC_PIN
			stb				<= '1';
			we 				<= '1';
			state 		<= active_sequence(state_cnt);
			state_cnt 	<= state_cnt + 1;		
					
		when block_clat =>
			inc_dec_reg	<= last_read_data;
			write_data 	<= '1'&last_read_data(6 downto 0);
			reg_addr	<= x"15";	 -- INCDEC_PIN
			stb 		<= '1';
			we 			<= '1';
			state 		<= active_sequence(state_cnt);
			state_cnt 	<= state_cnt + 1;		
			
		when step =>
			n_step <= n_step + 1;
			state 		<= active_sequence(state_cnt);
			state_cnt 	<= state_cnt + 1;		
			
		when do_load =>
			n_step <= coarse_step_offset + value;
			state 		<= active_sequence(state_cnt);
			state_cnt 	<= state_cnt + 1;		
						
		when write =>
			reg_addr		  <= x"10";	 -- clat
			write_data		  <= std_logic_vector(n_step(7 downto 0));
			stb				  <= '1';
			we				  <= '1';
			state 		<= active_sequence(state_cnt);
			state_cnt 	<= state_cnt + 1;		
			
		when wait_read_clatdone =>
			if ack = '1' then
				if (read_data(7) = '0') then	 -- clat done
					state 		<= active_sequence(state_cnt);
					state_cnt 	<= state_cnt + 1;		
				end if;
			else
				stb <= '1';
				we	<= '0';
				reg_addr   <= x"82";  -- clat_progress
			end if;		
				
		when wait_read =>
			if ack = '1' then
				state 		<= active_sequence(state_cnt);
				state_cnt 	<= state_cnt + 1;		
				last_read_data 		<= read_data;
			else
				stb <= '1';
				we	<= '0';
			end if;	
						
		when wait_write =>
			if ack = '1' then
				state 		<= active_sequence(state_cnt);
				state_cnt 	<= state_cnt + 1;		
			else
				stb <= '1';
				we	<= '1';
			end if;
		
		when idle =>
			reg_addr <= (others => '0');
			write_data <= (others => '0');
			state_cnt <= 0;
			if load = '1' then
				active_sequence <= load_state_sequence;
				state <= load_state_sequence(0);
				state_cnt <= 1;
			elsif incr = '1' then
				active_sequence <= step_state_sequence;
				state <= step_state_sequence(0);
				state_cnt <= 1;
			else
				done <= '1';			
			end if;				
		end case;		
		
		-- on reset, overwrite state and done
		if rst ='1' then
			active_sequence <= reset_state_sequence;
			state <= reset_state_sequence(0);
			state_cnt <= 1;
			done <= '0';		
		end if;		
	end process do_step;
end generate;

end architecture RTL;
