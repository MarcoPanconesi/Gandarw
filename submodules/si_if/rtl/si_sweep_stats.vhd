--	 __| \ \	  / __|	 __|  _ \	  __| __ __|  \ __ __| __| 
-- \__ \  \ \ \	 /	_|	 _|	  __/	\__ \	 |	 _ \   | \__ \ 
-- ____/   \_/\_/  ___| ___| _|		____/	_| _/  _\ _| ____/ 
-- Calculates Statistics for SI Sweep.
-- Engineer: Paul Kremser
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library UNISIM;
use UNISIM.vcomponents.all;

library UNIMACRO;
use UNIMACRO.vcomponents.all;

entity si_sweep_stats is
	generic (GEN_N_STATS : integer := 50000;
			 GEN_DEVICE	 : string  := "VIRTEX5");
	port (CLK_i : in  std_logic;
		  CE_i	: in  std_logic;
		  LSA_i : in  std_logic;
		  LSB_i : in  std_logic;
		  ACK_o : out std_logic;
		  CNT_o : out unsigned (13 downto 0));
end si_sweep_stats;

architecture Behavioral of si_sweep_stats is
--	 __| _ _|	__|	  \ |	 \	  |		 __| 
-- \__ \   |   (_ |	 .	|	_ \	  |	   \__ \ 
-- ____/ ___| \___| _|\_| _/  _\ ____| ____/
	signal nstat		  : std_logic_vector(13 downto 0);
	signal cnt_stats_load : std_logic := '0';
	signal nhits		  : std_logic_vector(13 downto 0);
	signal cnt_hits_load  : std_logic := '0';
	signal cnt_hits_ce	  : std_logic := '0';

	type   state_type is (count, restart);
	signal state : state_type := restart;
begin
--	_ )	 __|   __| _ _|	  \ | 
--	_ \	 _|	  (_ |	 |	 .	| 
-- ___/ ___| \___| ___| _|\_| 

	state_machine : process(CLK_i)
	begin
		if rising_edge(CLK_i) then
			if (CE_i = '1') then
				case state is
					when count =>
						cnt_stats_load <= '0';
						cnt_hits_load  <= '0';
						if unsigned(nstat) = 0 then
							ACK_o <= '1';
							CNT_o <= unsigned(nhits);
							state <= restart;
						end if;
						if (LSA_i = '1') and (LSB_i = '0') then
							cnt_hits_ce <= '1';
						else
							cnt_hits_ce <= '0';
						end if;
					when restart =>
						ACK_o		   <= '0';
						cnt_stats_load <= '1';
						cnt_hits_load  <= '1';
						cnt_hits_ce	   <= '1';	-- otherwise reset is ignored
						state		   <= count;
				end case;
			else
				cnt_hits_ce <= '0';
			end if;
		end if;
	end process;

	inst_stats_counter : COUNTER_LOAD_MACRO
		generic map (
			COUNT_BY   => X"000000000001",	-- Count by value
			DEVICE	   => GEN_DEVICE,  -- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6" 
			WIDTH_DATA => 14)			-- Counter output bus width, 1-48
		port map (
			Q		  => nstat,	 -- Counter output, width determined by WIDTH_DATA generic 
			CLK		  => CLK_i,			-- 1-bit clock input
			CE		  => CE_i,			-- 1-bit clock enable input
			DIRECTION => '0',  -- 1-bit up/down count direction input, high is count up
			LOAD	  => cnt_stats_load,	-- 1-bit active high load input
			LOAD_DATA => std_logic_vector(to_unsigned(GEN_N_STATS, 14)),  -- Counter load data, width determined by WIDTH_DATA generic 
			RST		  => '0'  -- 1-bit active high synchronous reset
			);

	inst_hits_counter : COUNTER_LOAD_MACRO
		generic map (
			COUNT_BY   => X"000000000001",	-- Count by value
			DEVICE	   => GEN_DEVICE,  -- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6" 
			WIDTH_DATA => 14)			-- Counter output bus width, 1-48
		port map (
			Q		  => nhits,	 -- Counter output, width determined by WIDTH_DATA generic 
			CLK		  => CLK_i,			-- 1-bit clock input
			CE		  => cnt_hits_ce,	-- 1-bit clock enable input
			DIRECTION => '1',  -- 1-bit up/down count direction input, high is count up
			LOAD	  => cnt_hits_load,		-- 1-bit active high load input
			LOAD_DATA => "00000000000000",	-- Counter load data, width determined by WIDTH_DATA generic 
			RST		  => '0'  -- 1-bit active high synchronous reset
			);

end Behavioral;
