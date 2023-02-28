----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:02:56 06/24/2012 
-- Design Name: 
-- Module Name:    ana_tiger - Behavioral 
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
use IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values


USE WORK.TOP_LEVEL_DESC.ALL;
use WORK.G_PARAMETERS.ALL;


Library UNIMACRO;
use UNIMACRO.vcomponents.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity ana_tiger is
	port (
		clk : in std_logic;
		data_r: in ADC_DDRport;
		data_l: in ADC_DDRport;
		begin_of_spill: in std_logic;

		T_baseline		: in STD_LOGIC_VECTOR(12 downto 0); 
		T_fraction		: in STD_LOGIC_VECTOR (5 downto 0);
		T_delay			: in STD_LOGIC_VECTOR (4 downto 0);
		T_threshold		: in STD_LOGIC_VECTOR(12 downto 0); 
		T_cf_max_dist	: in STD_LOGIC_VECTOR (2 downto 0);
		
		self_trig : out std_logic;

		FIFO_data_out : out STD_LOGIC_VECTOR(29 downto 0);
		FIFO_empty: out std_logic;
		FIFO_rden: in std_logic;
		FIFO_rdclk: in std_logic;
		FIFO_reset: in std_logic
	);

end ana_tiger;

architecture Behavioral of ana_tiger is

	COMPONENT divisor
	PORT(
		DATA_0_i : IN std_logic_vector(11 downto 0);
		DATA_1_i : IN std_logic_vector(11 downto 0);
		clk : IN std_logic;          
		RESULT : OUT std_logic_vector(9 downto 0)
		);
	END COMPONENT;

	signal data_i_r: ADC_DDRport;
    signal data_i_l: ADC_DDRport;

	subtype 	del_word 			is	 STD_LOGIC_VECTOR(12 downto 0) ;   
	type 		del_words 			is	 array (INTEGER range<>) of del_word;
	signal 	del_data 			: 	 del_words(0 to 43):=(others => (others => '0'));

	signal 	cal_baseline		:	 signed(12 downto 0) ;
	signal 	zero 					:	 STD_LOGIC_VECTOR ( 5 downto 0):=(others => '0');

	signal 	baseline				:	 STD_LOGIC_VECTOR(12 downto 0):=b"00000" & x"c8"; 
	signal 	fraction				:	 Integer range 0 to 5 :=3;
	signal 	delay					:	 Integer range 0 to 16 :=12;
	signal 	threshold			:	 STD_LOGIC_VECTOR(12 downto 0):=b"00000" & x"0A"; 
	signal 	cf_max_dist			:	 Integer range 0 to 8 :=3;


	subtype 	cf_word 				is	 signed(12 downto 0) ;   
	type 		cf_words 			is	 array (INTEGER range<>) of cf_word;
	signal 	cf_data 				: 	 cf_words(0 to 17):=(others => (others => '0'));
	signal 	pre_cf 				:	 cf_words(0 to 4):=(others => (others => '0'));
	signal 	pre_cf1 				:	 cf_words(0 to 4):=(others => (others => '0'));
	signal 	pre_cf_del 			:	 cf_words(0 to 4):=(others => (others => '0'));
	signal 	pre_cf_del_del 	:	 cf_words(0 to 4):=(others => (others => '0'));
	signal 	cf_crit 				:	 cf_words(1 to 4):=(others => (others => '0'));
	signal 	cf_crit_del 		:	 cf_words(1 to 4):=(others => (others => '0'));

	signal 	cf_hit 	     		:	 STD_LOGIC_VECTOR ( 4 downto 1):=(others => '0');  
	signal 	post_cf_hit 	   :	 STD_LOGIC_VECTOR ( 4 downto 1):=(others => '0'); 
	signal 	hit_del          	:	 STD_LOGIC_VECTOR ( 3 downto 0):=(others => '0');  
	signal 	hit_out          	:	 STD_LOGIC :='0';

 	signal 	last_pos 			:	 STD_LOGIC_VECTOR (11 downto 0):=(others => '0');
	signal 	first_neg 			:	 STD_LOGIC_VECTOR (11 downto 0):=(others => '0');
	signal	h_time 				:	 STD_LOGIC_VECTOR (9 downto 0);

	signal 	coarse_counter		:	 Integer range 0 to 255 :=0;
	signal 	coarse_time			:	 STD_LOGIC_VECTOR(9 downto 0):=(others => '0');
	signal 	dist_count 			:	 STD_LOGIC_VECTOR(3 downto 0):=(others => '0');
	
	subtype 	del_coarse_word 	is	 STD_LOGIC_VECTOR(9 downto 0) ;   
	type 		del_coarse_words 	is	 array (INTEGER range<>) of del_coarse_word ;
	signal 	del_coarse 			:	 del_coarse_words(0 to 5):=(others => (others => '0'));
	signal 	coarse_out			:	 STD_LOGIC_VECTOR(9 downto 0):=(others => '0');

	subtype 	Amp_word 			is  STD_LOGIC_VECTOR(11 downto 0) ;   
	type 		Amp_words 			is  array (INTEGER range<>) of Amp_word ;
	signal	Amp 					:	 Amp_words(0 to 3):=(others => (others => '0'));
	signal	preAmp				:	 Amp_words(0 to 1):=(others => (others => '0'));
	signal   preAmp_set  		:   std_logic:='0';  

	signal	MaxAmp 				:   STD_LOGIC_VECTOR (11 downto 0):=(others => '0');
	signal 	Amp_buffer 			:	 Amp_words(0 to 10):=(others => (others => '0'));
	signal 	del_MaxAmp 			:	 Amp_words(0 to 3):=(others => (others => '0'));
	signal	MaxAmp_out 			:   STD_LOGIC_VECTOR (11 downto 0):=(others => '0');

	signal FIFO_emp 				:	 std_logic:='0';
	signal FIFO_was_a_full	 	:	 std_logic:='0';
	signal FIFO_WREN 				:	 std_logic:='0';
	signal data_to_FIFO 			:	 STD_LOGIC_VECTOR(29 downto 0);
	signal FIFO_wcnt				:	 STD_LOGIC_VECTOR(9 downto 0);
	signal FIFO_rcnt				:	 STD_LOGIC_VECTOR(9 downto 0);
	signal FIFO_afull 			:	 std_logic:='0';
	signal FIFO_reset_tmp 		:	 std_logic:='0';


	subtype 	cf_1_word 			is	 signed(12 downto 0) ;   
	type 		cf_1_words 			is	 array (INTEGER range<>) of cf_1_word;
	signal 	cf_1_data 			: 	 cf_1_words(0 to 4):=(others => (others => '0'));
	signal 	pre_cf_1 			: 	 cf_1_words(0 to 4):=(others => (others => '0'));
	signal 	pre_cf_1_del 		:	 cf_1_words(0 to 4):=(others => (others => '0'));
	signal 	cf_1_crit 			:	 cf_1_words(0 to 4):=(others => (others => '0'));

	signal 	cf_1_hit 	     	:   STD_LOGIC_VECTOR ( 3 downto 0):=(others => '0'); 

	signal 	caveat_shift 	     		:	 STD_LOGIC_VECTOR ( 5 downto 0):=(others => '0'); 

	signal before_ZC				:	 Integer range 0 to 5 :=1;
	signal after_ZC				:	 Integer range 0 to 5 :=5;

begin

baseline		<=    T_baseline;
fraction		<=		to_integer(unsigned(T_fraction));	
delay			<=		to_integer(unsigned(T_delay));	
threshold	<=		T_threshold;
cf_max_dist	<=		to_integer(unsigned(T_cf_max_dist));	


--------------------------------------------------------------------------------------------------------------------------
-------------------------------CFD ALGORITHM------------------------------------------------------------------------------

cf : process (clk)															---- finds zero crossing: 
																			---- => coarse time, 
variable pre_baseline: STD_LOGIC_VECTOR(12 downto 0) ;					    ---- => input for the divisor (=>highres_time)
variable post_calc1: unsigned (12 downto 0);								---- => the place to guess for the MaxAmp
variable post_calc2: unsigned (12 downto 0);

begin
 
if (clk'event and clk = '1') then

    -- pipe for timing
    data_i_l <= data_l;
    data_i_r <= data_r;

---count coarse time with 4 ns precision ---------------------------------------------------------------------------------

		if(begin_of_spill='1') then
			coarse_counter<=0;													--	reset with begin of spill signal
		else
			if(coarse_counter=255) then
				coarse_counter<=0;												--	count up to #254..
			else																--	250 MHz cycles
				coarse_counter<= coarse_counter +1;
			end if;
		end if;


--(ns precision is achieved once the zero crossing has been found - see later)
--------------------------------------------------------------------------------------------------------------------------	

------------------------delay the incoming data stream--------------------------------------------------------------------

		del_data(0) <= ('0' & data_i_l(23 downto 12));						    --	fourth sample in time
		del_data(1) <= ('0' & data_i_r(23 downto 12));						    --	third sample in time
		del_data(2) <= ('0' & data_i_l(11 downto 0));						    --	second sample in time
		del_data(3) <= ('0' & data_i_r(11 downto 0));						    --	first sample in time

		for i in 0 to 9 loop 									
		
			del_data(i*4+4)		<= del_data(i*4);
			del_data(i*4+5)		<= del_data(i*4+1);							    --	delay up to del_data(31)
			del_data(i*4+6)		<= del_data(i*4+2);
			del_data(i*4+7)		<= del_data(i*4+3);						
		
		end loop;	

--------------------------------------------------------------------------------------------------------------------------

------------------------cfd calculation-----------------------------------------------------------------------------------

		pre_baseline := '0' & zero(fraction downto 0) 					    --	fraction factor is applied to baseline
							 & baseline(10 downto fraction);
		cal_baseline <= signed(baseline)-signed(pre_baseline);              --	difference of baseline and fractioned baseline..
																			--	(it s a calculation thing - cal_baseline ..
																			--  can be substracted in the last calc. step !once!)

		for i in 0 to 3 loop 											    --	loop over the 4 samples within one cycle

			pre_cf(i) <= signed( zero(fraction downto 0) ) 					--	apply fraction factor to sample(i)
							 & signed(del_data(i)(11 downto fraction)); 
			pre_cf1(i) <= signed(del_data(delay+i));						--	get the delayed sample (delay is variable)
			pre_cf_del(i)<=pre_cf(i)-pre_cf1(i);							--	substract fractioned sample from delayed one
			cf_data(i)<=pre_cf_del(i)+ cal_baseline;					    --	add cal_baseline (other way would have been to substract baseline !twice! before)
			--cf_data(i)<=pre_cf_del_del(i);								--  delay one cycle (necesarry because of cf_crit)

		end loop;


		for i in 0 to 13 loop
		cf_data(i+4)<=cf_data(i);
		end loop;
		

--		cf_crit(1)<=cf_data(6+before_ZC); --
--		cf_crit(2)<=cf_data(7+before_ZC); -- 
--		cf_crit(3)<=cf_data(8+before_ZC); -- 
--		cf_crit(4)<=cf_data(9+before_ZC); --before_ZC steps before
		

--		cf_crit(1)<=cf_data(5-after_ZC); --
--		cf_crit(2)<=cf_data(6-after_ZC); -- 
--		cf_crit(3)<=cf_data(7-after_ZC); -- 
--		cf_crit(4)<=cf_data(8-after_ZC); --after_ZC steps after

		cf_crit(1)<=cf_data(6+before_ZC) - cf_data(5-after_ZC); 
		cf_crit(2)<=cf_data(7+before_ZC) - cf_data(6-after_ZC);  
		cf_crit(3)<=cf_data(8+before_ZC) - cf_data(7-after_ZC); 
		cf_crit(4)<=cf_data(9+before_ZC) - cf_data(8-after_ZC); --diff



		cf_crit_del(1)<=cf_crit(1)-signed(threshold);
		cf_crit_del(2)<=cf_crit(2)-signed(threshold);
		cf_crit_del(3)<=cf_crit(3)-signed(threshold);
		cf_crit_del(4)<=cf_crit(4)-signed(threshold);
		
		
		
--		set default for self trigger
		self_trig <= '0';

--------------------------------------------------------------------------------------------------------------------------

------------------------check for zero crossing---------------------------------------------------------------------------

			if ((cf_data(14) >= ("0000000000000")) 							--	sample earlier in time (cf_data(i+1)) must be > 0
				and (cf_data(13) < ("0000000000000"))) 							--	sample later in time (cf_data(i)) must be < 0
				and cf_crit_del(1)>0 then										--	threshold criterium
																							
				cf_hit(1) <='1';													--	remember between which samples the hit has happened
				post_calc1 :=unsigned(abs(cf_data(14)));
				post_calc2 :=unsigned(abs(cf_data(13)));
				last_pos <= std_logic_vector(post_calc1(11 downto 0));	--last_pos / (last_pos + first_neg)..
				first_neg <=std_logic_vector(post_calc2(11 downto 0));	--is calculated in the divisor => highres_time
				coarse_time<=std_logic_vector(to_unsigned(coarse_counter,8)) & "11";
				
				self_trig <= '1';
			
			elsif ((cf_data(15) >= ("0000000000000")) 							--	sample earlier in time (cf_data(i+1)) must be > 0
				and (cf_data(14) < ("0000000000000"))) 							--	sample later in time (cf_data(i)) must be < 0
				and cf_crit_del(2)>0 then										--	threshold criterium
																							
				cf_hit(2) <='1';													--	remember between which samples the hit has happened
				post_calc1 :=unsigned(abs(cf_data(15)));
				post_calc2 :=unsigned(abs(cf_data(14)));
				last_pos <= std_logic_vector(post_calc1(11 downto 0));	--last_pos / (last_pos + first_neg)..
				first_neg <=std_logic_vector(post_calc2(11 downto 0));	--is calculated in the divisor => highres_time
				coarse_time<=std_logic_vector(to_unsigned(coarse_counter,8)) & "10";
				
				self_trig <= '1';
				
			elsif ((cf_data(16) >= ("0000000000000")) 							--	sample earlier in time (cf_data(i+1)) must be > 0
				and (cf_data(15) < ("0000000000000"))) 							--	sample later in time (cf_data(i)) must be < 0
				and cf_crit_del(3)>0 then										--	threshold criterium
																							
				cf_hit(3) <='1';													--	remember between which samples the hit has happened
				post_calc1 :=unsigned(abs(cf_data(16)));
				post_calc2 :=unsigned(abs(cf_data(15)));
				last_pos <= std_logic_vector(post_calc1(11 downto 0));	--last_pos / (last_pos + first_neg)..
				first_neg <=std_logic_vector(post_calc2(11 downto 0));	--is calculated in the divisor => highres_time
				coarse_time<=std_logic_vector(to_unsigned(coarse_counter,8)) & "01";

				self_trig <= '1';

			elsif ((cf_data(17) >= ("0000000000000")) 							--	sample earlier in time (cf_data(i+1)) must be > 0
				and (cf_data(16) < ("0000000000000"))) 							--	sample later in time (cf_data(i)) must be < 0
				and cf_crit_del(4)>0 then										--	threshold criterium
																							
				cf_hit(4) <='1';													--	remember between which samples the hit has happened
				post_calc1 :=unsigned(abs(cf_data(17)));
				post_calc2 :=unsigned(abs(cf_data(16)));
				last_pos <= std_logic_vector(post_calc1(11 downto 0));	--last_pos / (last_pos + first_neg)..
				first_neg <=std_logic_vector(post_calc2(11 downto 0));	--is calculated in the divisor => highres_time
				coarse_time<=std_logic_vector(to_unsigned(coarse_counter,8)) & "00";					
				
				self_trig <= '1';
			
			else
			cf_hit<="0000";
			end if;

		
		if cf_hit(1)='1' then
		dist_count<="0001";
		elsif cf_hit(2)='1' then
		dist_count<="0010";
		elsif cf_hit(3)='1' then
		dist_count<="0011";
		elsif cf_hit(4)='1' then
		dist_count<="0100";
		else
			if dist_count>"1011"  then
			dist_count<="1111";
			else
			dist_count<=dist_count+"100";
			end if;
		end if;

		
		if cf_hit(1)='1' then
			if dist_count <"0011" then --dist_count+3 <"0110"
			caveat_shift<=caveat_shift(5 downto 1) & '1';
			end if;
		elsif cf_hit(2)='1' then
			if dist_count <"0100" then --dist_count+2 <"0110"
			caveat_shift<=caveat_shift(5 downto 1) & '1';
			end if;
		elsif cf_hit(3)='1' then
			if dist_count <"0111" then  --dist_count+1 <"0110"
			caveat_shift<=caveat_shift(5 downto 1) & '1';
			end if;
		elsif cf_hit(4)='1' then
			if dist_count <"0110" then --dist_count <"0110"
			caveat_shift<=caveat_shift(5 downto 1) & '1';
			end if;
			--caveat_shift<=caveat_shift(5 downto 1) & '1';--debug
		else
			caveat_shift<=caveat_shift(4 downto 0) & '0';
		end if;


--------------------------------------------------------------------------------------------------------------------------

end if;
		
end process;

--------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------------------------
-----------------------DIVISOR--------------------------------------------------------------------------------------------

inst_divisor: divisor   															---- calculates last_pos / (last_pos + first_neg)
	PORT MAP( 																			---- => h-time (ps precision - no correction yet)
	DATA_0_i => last_pos,
	DATA_1_i => first_neg,
	clk => clk,
	RESULT => h_time
	);

--------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------------------------
---------------------PRE-AMPLIUTDE(4 possibilities) PROCESS---------------------------------------------------------------

getpreAmp : process (clk)																---- chooses 4 candidates for the MaxAmp

begin

if (clk'event and clk = '1') then

		for i in 0 to 10 loop 															--	buffer the right del_data
																								--	up to del_data( 12(max. delay) +20 -1(max. dist) )
			Amp_buffer(i)<=del_data(delay+20+i-cf_max_dist)(11 downto 0);	--	20 choosen because of: (5 cycles until cf_data(4) )
																								--	*4 samples per cycle => 20
		end loop;


		if (cf_hit(1)='1' ) then	
		
			for i in 0 to 3 loop 
				if Amp_buffer(2*i) > Amp_buffer(2*i+1) then
					Amp(i)<=Amp_buffer(2*i);
				else
					Amp(i)<=Amp_buffer(2*i+1);
				end if;
			end loop;

			post_cf_hit(1)<='1';
		
		else
			post_cf_hit(1)<='0';
		end if;

		if (cf_hit(2)='1' ) then	
		
			for i in 0 to 3 loop 
				if Amp_buffer(2*i+1) > Amp_buffer(2*i+1+1) then
					Amp(i)<=Amp_buffer(2*i+1);
				else
					Amp(i)<=Amp_buffer(2*i+1+1);
				end if;
			end loop;

			post_cf_hit(2)<='1';
		
		else
			post_cf_hit(2)<='0';
		end if;

		if (cf_hit(3)='1' ) then	
		
			for i in 0 to 3 loop 
				if Amp_buffer(2*i+2) > Amp_buffer(2*i+1+2) then
					Amp(i)<=Amp_buffer(2*i+2);
				else
					Amp(i)<=Amp_buffer(2*i+1+2);
				end if;
			end loop;

			post_cf_hit(3)<='1';
		
		else
			post_cf_hit(3)<='0';
		end if;

		if (cf_hit(4)='1' ) then	
		
			for i in 0 to 3 loop 
				if Amp_buffer(2*i+3) > Amp_buffer(2*i+1+3) then
					Amp(i)<=Amp_buffer(2*i+3);
				else
					Amp(i)<=Amp_buffer(2*i+1+3);
				end if;
			end loop;

			post_cf_hit(4)<='1';
		
		else
			post_cf_hit(4)<='0';
		end if;

end if;

end process;

--------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------------------------
-----------------------MAX-AMPLIUTDE PROCESS------------------------------------------------------------------------------

getAmp : process (clk)																	---- chooses MaxAmp

begin

if (clk'event and clk = '1') then

	if (post_cf_hit(4)='1' or post_cf_hit(3)='1' or post_cf_hit(2)='1' or post_cf_hit(1)='1') then
	

		for i in 0 to 1 loop 
		
			if (Amp(2*i)>Amp(2*i+1)) then 										
				
				preAmp(i)<=Amp(2*i);														-- find biggest value of Amp(0) and Amp(1) => preAmp(0)
																								-- as well as Amp(2) and Amp(3) => preAmp(1)
			else
				
				preAmp(i)<=Amp(2*i+1);													
				
			end if;

		end loop;

		preAmp_set<='1';																	-- remember that preAmp was found			

	else
		
		preAmp_set<='0';
		
	end if;


	if(preAmp_set='1') then
		
		if (preAmp(0)>preAmp(1)) then 												-- choose biggest value of preAmp(0) and preAmp(1)
																								-- => MaxAmp without baseline
			MaxAmp<=preAmp(0);
		
		else
		
			MaxAmp<=preAmp(1);
		
		end if;
		
	end if;


end if;

end process;

--------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------------------------
------------------OUTPUT TIMING PROCESS-----------------------------------------------------------------------------------

prep_output : process (clk)															---- delays MaxAmp, coarse time, and the hit information 
																								---- to the point where highres is finished
begin

	if (clk'event and clk = '1') then

		del_coarse(0)<=coarse_time;													-- delay coarse time for 7 cycles
		for i in 0 to 4 loop
			del_coarse(i+1)<=del_coarse(i);
		end loop;
		coarse_out<=del_coarse(5);


		del_MaxAmp(0)<=MaxAmp;															-- delay MaxAmp for 4 cycles													
		for i in 0 to 1 loop
			del_MaxAmp(i+1)<=del_MaxAmp(i);											
		end loop;
		MaxAmp_out<=del_MaxAmp(2)-baseline(11 downto 0);						-- and substract baseline


		hit_del(0)<=preAmp_set;															-- delay hit Information 
		for i in 0 to 1 loop																-- ZC->cf_hit->post_cf_hit->preAmp_set->(4cycles)->hit_out
			hit_del(i+1)<=hit_del(i);
		end loop;
		hit_out<=hit_del(2);																-- hit_out gives write enable to FIFO

	end if;

end process;

--------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------------------------
-------------FIFO WRITE ROUTINE-------------------------------------------------------------------------------------------

write_FIFO : process (clk)																---- manages write enable for FIFO

begin

    if (clk'event and clk = '1') then


--		if (FIFO_afull='1') then														-- once the FIFO is almost full
--
--			fifo_was_a_full<='1';														-- remember almost_full
--
--		end if;
--
--		if (FIFO_emp='1') then															-- once the FIFO is empty again
--
--			fifo_was_a_full<='0';														-- forget what you rememberd
--
--		end if;


--		if ( FIFO_reset = '1') then													-- once the vxs link sets the FIFO_reset..

--			FIFO_reset_tmp <='1';														-- FIFO is reseted..
--			FIFO_WREN <= '0';																-- and write_enable is blocked
		
--		else																					-- if there is no reset signal from the VXS link..

--			FIFO_reset_tmp <='0';														-- FIFO is not reseted..

--			if (FIFO_afull='0' and fifo_was_a_full='0') then					-- and if FIFO is/was not almost full..

				if caveat_shift(4 downto 0)="00000" and del_MaxAmp(2)>x"0C8" then
				FIFO_WREN<=hit_out;														-- data is written to the FIFO (if there was a hit)
				else
				FIFO_WREN<='0';
				end if;

--			else

--				FIFO_WREN<='0';															-- no data is written to the FIFO (if there was no hit)

--		end if;

--    end if;


    end if;

end process;

--------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------------------------
--------------------------DATA FORMAT TO TIGER----------------------------------------------------------------------------

	data_to_FIFO(3 downto 0)	<=	"0000";											-- empty bits										--	4 bits
	data_to_FIFO(9 downto 4)	<=	h_time(9 downto 4);							-- highres_time with ca. 16 ns precision	-- 6 bits
	data_to_FIFO(19 downto 10)	<=	coarse_out(9 downto 0);						-- coarse_time up to 1024 ns					-- 10 bits
	data_to_FIFO(28 downto 20)	<=	MaxAmp_out(11 downto 3);					-- Max_Amp without baseline 					-- 9 bits
	data_to_FIFO(29)          	<=	'0';												-- empty bit										-- 1 bit

--------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------------------------
-----------------------FIFO - CONNECTION TO VXS LINK----------------------------------------------------------------------

	FIFO_DUALCLOCK_MACRO_inst : FIFO_DUALCLOCK_MACRO
		generic map (
			DEVICE => "VIRTEX5",           		-- Target Device: "VIRTEX5", "VIRTEX6" 
			ALMOST_FULL_OFFSET => X"03FA",  		-- Sets almost full threshold
			ALMOST_EMPTY_OFFSET => X"0080", 		-- Sets the almost empty threshold
			DATA_WIDTH => 30,   				  		-- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
			FIFO_SIZE => "36Kb",            		-- Target BRAM, "18Kb" or "36Kb" 
			FIRST_WORD_FALL_THROUGH => FALSE, 	-- Sets the FIFO FWFT to TRUE or FALSE
			SIM_MODE => "SAFE") 						-- Simulation "SAFE" vs "FAST", 
															-- see "Synthesis and Simulation Design Guide" for details
		port map (
			ALMOSTEMPTY =>open,   					-- Output almost empty 
			ALMOSTFULL => FIFO_afull,    			-- Output almost full
			DO => FIFO_data_out,                -- Output data
			EMPTY => FIFO_emp,               	-- Output empty
			FULL => open,                 		-- Output full
			RDCOUNT => FIFO_rcnt,           		-- Output read count
			RDERR => open,               			-- Output read error
			WRCOUNT => FIFO_wcnt,           		-- Output write count
			WRERR => open,               			-- Output write error
			DI => data_to_FIFO,          			-- Input data
			RDCLK => FIFO_rdclk,               	-- Input read clock
			RDEN => FIFO_rden,                 	-- Input read enable
			RST => FIFO_reset,              -- Input reset
			WRCLK => clk,               			-- Input write clock
			WREN => FIFO_WREN             		-- Input write enable
		);

	FIFO_empty	<=FIFO_emp;

--------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------


cf_1 : process (clk)

begin

if (clk'event and clk = '1') then

	
		pre_cf_1(0) <= signed(del_data(0))- signed(del_data(1));
		pre_cf_1(1) <= signed(del_data(1))- signed(del_data(1+1));
		pre_cf_1(2) <= signed(del_data(2))- signed(del_data(1+2));
		pre_cf_1(3) <= signed(del_data(3))- signed(del_data(1+3));
		pre_cf_1(4) <= pre_cf_1(0);

		pre_cf_1_del(0) <= pre_cf_1(0);
		pre_cf_1_del(1) <= pre_cf_1(1);
		pre_cf_1_del(2) <= pre_cf_1(2);
		pre_cf_1_del(3) <= pre_cf_1(3);
		pre_cf_1_del(4) <= pre_cf_1(4);

		cf_1_data(0) <= pre_cf_1_del(0);
		cf_1_data(1) <= pre_cf_1_del(1);
		cf_1_data(2) <= pre_cf_1_del(2);
		cf_1_data(3) <= pre_cf_1_del(3);
		cf_1_data(4) <= pre_cf_1_del(4);

		cf_1_crit(3) <=cf_1_data(2) -  pre_cf_1_del(1); 
		cf_1_crit(2) <=cf_1_data(1) - pre_cf_1_del(0); 
		cf_1_crit(1) <=cf_1_data(0) - pre_cf_1(3);  
		cf_1_crit(0) <=pre_cf_1_del(3) - pre_cf_1(2);  
	

		if ((cf_1_data(3) > ("0000000000000")) and (cf_1_data(2) < ("0000000000000")) and cf_1_crit(0)> signed(threshold)  )  then
	
			cf_1_hit(3)<='1';

		else
		
			cf_1_hit(3)<='0';
	
		end if;
	
		if ((cf_1_data(2) > ("0000000000000")) and (cf_1_data(1) < ("0000000000000")) and cf_1_crit(1)> signed(threshold) )  then

			cf_1_hit(2)<='1';

		else
		
			cf_1_hit(2)<='0';

		end if;
	
		if ((cf_1_data(1) > ("0000000000000")) and (cf_1_data(0) < ("0000000000000")) and cf_1_crit(2)> signed(threshold) )  then		

			cf_1_hit(1)<='1';

		else
		
			cf_1_hit(1)<='0';

		end if;

		if ((cf_1_data(4) > ("0000000000000")) and (cf_1_data(3) < ("0000000000000")) and cf_1_crit(3)> signed(threshold) )   then

			cf_1_hit(0)<='1';

		else
		
			cf_1_hit(0)<='0';

		end if;


end if;



end process;


end Behavioral;

