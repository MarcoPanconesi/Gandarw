library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity test_bench is
end test_bench;

architecture Test of test_bench is
	
	constant CLK_PERIOD : time := 24 ns;
	constant SI_CLK_PERIOD : time := CLK_PERIOD/6;
	constant CFMEM_CLK_PERIOD : time := 25 ns;
	
	constant CLK_JITTER : time := 200 ps;
	constant SI_CLK_JITTER : time := 140 ps;
	
	signal tcs_clk, tcs_ce, si_clk, cfmem_clk: std_logic := '0';
	signal fr_sweep_si,fr_load_si,fr_phase_align_si : std_logic := '0';
	
	signal cfmem_wb_ack,cfmem_wb_stb  : std_logic;
	signal cfmem_wb_din  : std_logic_vector (31 downto 0):=(others => '0');
	
begin
			
	uut: entity work.si_if
		generic map(
			do_load_si => "100",
			do_sweep_si => "100",
			n_coarse_steps => 100,
			n_samples      => 20,
			sim => True,
			coarse_step_size => 180 ps,
			fine_step_size => 5 ps,
			ff_delay => 20 ps 
		)
		port map(
			  clk           => tcs_clk,
			  cfmem_clk		=> cfmem_clk,
			  spy_clk		=> cfmem_clk,
			  tcs_clk       => tcs_clk,
			  tcs_ce        => tcs_ce,
			  si_g_clk        => si_clk,
			  si_a_clk        => si_clk,
			  si_b_clk        => si_clk,
			  rst           => '0',
			  fr_load_si    => fr_load_si,
			  fr_sweep_si   => fr_sweep_si,
			  fr_phase_align_si   => fr_phase_align_si,
--			  done          => si_conf_done,
--			  sda           => iic_si_sda,
--			  scl           => iic_si_scl,
--			  cfmem_wb_cyc  => wb2_cyc,
			  cfmem_wb_stb  => cfmem_wb_stb,
--			  cfmem_wb_we   => wb2_we,
			  cfmem_wb_ack  => cfmem_wb_ack,
--			  cfmem_wb_addr => wb2_adr,
			  cfmem_wb_din  => cfmem_wb_din,
--			  cfmem_wb_dout => wb2_dat_i,
			  spy_wr        => open,
			  spy_do        => open,
			  spy_full      => '0'
		);
		
		
	
	cfmem_wb_ack <= '1' when cfmem_wb_stb = '1' else '0';
	
		
	clk_proc : process is
    variable seed1, seed2 : positive;
    variable r_clk,r_si_clk : real;
    variable d_clk,d_si_clk : time;
    variable cnt : integer:=0;
	begin
		
		if (tcs_ce = 'U') then
			tcs_ce <= '0';
			tcs_clk <= '0';
			si_clk <= '0';
		end if;
	
 		uniform(seed1, seed2, r_si_clk); 		
 		d_si_clk := (r_si_clk-0.5)  * SI_CLK_JITTER;
 		
 		if (cnt mod 6 = 0) then
 			uniform(seed1, seed2, r_clk); 			
  			d_clk := (r_clk-0.5)  * CLK_JITTER;
 			
 			if d_clk < d_si_clk then
 				wait for SI_CLK_PERIOD/2 + d_clk;
 				tcs_ce <= not tcs_ce;
 				tcs_clk <= not tcs_clk;
 				wait for d_si_clk-d_clk;
 				si_clk <= not si_clk;
 			else
 				wait for SI_CLK_PERIOD/2 + d_si_clk;
 				si_clk <= not si_clk;
  				wait for d_clk-d_si_clk;
 				tcs_ce <= not tcs_ce;
 				tcs_clk <= not tcs_clk;	
 			end if;
 		else
 			wait for SI_CLK_PERIOD/2 + d_si_clk;
			si_clk <= not si_clk;
			if (cnt mod 3 = 0) then
				tcs_clk <= not tcs_clk;
			end if;	
  		end if;
 		cnt := cnt + 1;
		
	end process clk_proc;
	
	
	cfmem_clk_process : process is
	begin
		wait for CFMEM_CLK_PERIOD/2;
		cfmem_clk <= '1';
		wait for CFMEM_CLK_PERIOD/2;
		cfmem_clk <= '0';
	end process cfmem_clk_process;
		
			
	stim : process is
	begin
		wait for 5*CLK_PERIOD;
		fr_load_si <= '1';
		wait for CLK_PERIOD;
		fr_load_si <= '0';
		wait;
	end process stim;
	
	
	
end architecture Test;
