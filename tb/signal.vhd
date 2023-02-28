----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:54:54 02/08/2008 
-- Design Name: 
-- Module Name:    sensor - Behavioral 
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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.MATH_REAL.ALL;
USE WORK.TOP_LEVEL_DESC.ALL;
use WORK.G_PARAMETERS.ALL;


---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

ENTITY analog_signal IS
	GENERIC(
		SIMULATION_MODE 	: STRING := "5MHz_p";
									--"DAC_CALIB" --for dac calibration
									--"RPD_Readout" --for data rate stress, random trigger and pulses
									--"REG_PULSES" --for timing resolution measurement
									-- "5MHz_p" -- bho
		GEN_TRIGGER_MASK_1	: real := 4.0; 	--in us
		GEN_TRIGGER_MASK_3	: real := 40.0; 	--in us
		GEN_TRIGGER_MASK_10	: real := 250.0; 	--in us
		TRIGGER_RATE		: real := 100.0; --in KHz  
 		MAX_EVENTS 			: integer := 10
   );
    Port ( 	
		BOS 					: IN  std_logic := '0';
		EOS 					: IN  std_logic := '0';
		ONSPILL 				: IN  std_logic := '0';
		TRIGGER_OUT 			: OUT std_logic;
		analog_out 				: out analog_signals(ADC_CHANNELS-1 downto 0)
	);
END analog_signal;


ARCHITECTURE Behavioral OF analog_signal IS

--Constanst
constant t100M				: real	:= 10.0;
constant t23M				: real	:= 1000.0/23.00;
--constant t400k			: real 	:= 2500.0;
--constant t20M			: real 	:= 50.0;
--constant t200k			: real 	:= 5000.0;
--constant Sine_Amp		: real 	:=	1.98; 		--Sinus Amplitude
--constant NOISE_Amp		: real 	:=	0.01; 		--Noise Amplitude
constant A					: real 	:=1.0;	--Moyal Amp
constant B					: real 	:=3.0;	--Moyal Width
constant C					: real 	:=0.005;	--Moyal Noise
signal m_offset			: real 	:=4.75;	--Moyal Offset

constant t_off 			: real 	:= -520.0; --in ns
											--time offset between pulse and trigger
											--											 T
											--		<-- (+)   pulse  (-) -->
											
constant trg_time			: real 	:=32.0; 			--trigger active for xxns
constant Pulse_Dist		: real	:= 10.0**6.0/(TRIGGER_RATE * 20.0); --in ns  
signal Pulse_Dist_rand	: real:=Pulse_Dist;
--Singals
signal t						: real	:= 0.0;
signal t_rand				: real 	:=2.0;  --random offset time added to regular trigger-time: "REG_PULSES" or random trigger-time: "RPD_Readout"
signal t_MASK_1			: real	:= 0.0;
signal t_MASK_3			: real	:= 0.0;
signal t_MASK_10			: real	:= 0.0;
signal deadtime			: STD_LOGIC :='0';
signal deadtime_1			: STD_LOGIC :='0';
signal deadtime_3			: STD_LOGIC :='0';
signal deadtime_10 		: STD_LOGIC :='0';
signal trg_cnt_3			: integer range 0 to 3 :=3;
signal trg_cnt_10			: integer range 0 to 10:=10;


signal DAC_offset : real	:=-0.0410;	-- -0.05;
													-- -0.0410; --sets max_histo to FD0

signal ON_SPILL	    : STD_LOGIC :='0';
signal IN_SPILL	    : STD_LOGIC;

signal trigger		: STD_LOGIC :='0';

signal seed_int		: integer:=1;
signal srandom1		: real:=0.5;
signal srandom2		: real:=0.5;
signal gauss_noise	: real;

signal analog		:real;


begin

    IN_SPILL <= ON_SPILL or ONSPILL;

    inst_signals : for ADCs_i in 0 to (ADC_CHANNELS-1) GENERATE
        analog_out(ADCs_i)<=analog;
    end generate;
  

pulseGenerator : process


		-- Seed values for random generator
		variable seed1: positive :=1; 
		variable seed2: positive :=2;
		
		
		-- Random real-number value in range 0 to 1.0
		variable shift_rand 	: real :=0.0;
		
		-- Random real-number value in range 0 to 1.0
		variable rand			: real :=0.0;
		variable rand1			: real :=0.0;
		variable rand2			: real :=0.0;

		

		
begin


if SIMULATION_MODE = "RPD_Readout" then

	if t = 0.0 then
		if trg_cnt_3 /= 1 then
		    trg_cnt_3<=trg_cnt_3-1;
		else
		    trg_cnt_3<=3;
		end if;
	
		if trg_cnt_10 /= 1 then
		    trg_cnt_10<=trg_cnt_10-1;
		else
		    trg_cnt_10<=10;
		end if;
	end if;
	if t_MASK_1 <= GEN_TRIGGER_MASK_1*10.0**3.0 then
		deadtime_1<='1';
	else
		t_MASK_1 <=0.0;
		deadtime_1<='0';
	end if;
	if t_MASK_3 <= GEN_TRIGGER_MASK_3*10.0**3.0 then
		if trg_cnt_3 = 1 then
		    deadtime_3<='1';
		else
		    deadtime_3<='0';
		end if;			
	else
		t_MASK_3<=0.0;
		deadtime_3<='0';
	end if;
	
	if t_MASK_10 <= GEN_TRIGGER_MASK_10*10.0**3.0 then
		if trg_cnt_10 = 1 then
		    deadtime_10<='1';
		else
		    deadtime_10<='0';
		end if;
	else
		t_MASK_10<=0.0;
		deadtime_10<='0';
	end if;
	
	deadtime <= deadtime_1 OR deadtime_3 OR deadtime_10;
    
	if t >= Pulse_Dist_rand-0.01 and deadtime = '0' then
	    t <=0.0;
	    seed1:= seed1 + 1;
	    seed2:= seed2 + 2;
	    UNIFORM(seed1,seed2, shift_rand);
		t_rand <= 0.001*round(1000.0*shift_rand); -- oder shift_rand addieren
		Pulse_Dist_rand<=Pulse_Dist*shift_rand;
		
		if seed1 >= 16000 then
		    seed1 := 1;
		end if;
		
        if seed2 >= 16000 then
		    seed2 := 2;
		end if;
	
	else
	    UNIFORM(seed1,seed2, rand1);
	    UNIFORM(seed2,seed1, rand2);
	    seed1:= seed1 + 1;
	    seed2:= seed2 + 2;
	    seed_int<= seed_int +2;
	    if seed_int >=2**8 then
        
	        seed1:= 1;
	        seed2:= 1;
	        seed_int<=1;
        
	    end if;
	
	    if RAND1 = 0.0 OR RAND1 = 1.0 then
	        srandom1<=0.5;
	    else
	        srandom1 <= RAND1;
	        srandom2 <= RAND2-0.00001;
	    end if;
	    gauss_noise<=SQRT(-2.0*LOG(srandom1))*COS(2.0*MATH_PI*srandom2);
	    if IN_SPILL = '1' then
	        analog <=  (m_offset * ( DAC_offset - shift_rand*A * 1.6 * ( exp( -0.5 * ( (t+t_rand+t_off)/B + exp(-(t+t_rand+t_off)/B) ) ) ) ))+ C * gauss_noise; --with C noise
	    else	
	        analog <= DAC_offset + 0.0015*gauss_noise;
	    end if;
	
	    t <= t + 0.01;
	    t_MASK_1 <= t_MASK_1 + 0.01;
	    t_MASK_3 <= t_MASK_3 + 0.01;
	    t_MASK_10 <= t_MASK_10 + 0.01;
	
		if t >= 900.0  AND t <=925.0 then
			trigger <= '1'; 				
        --	elsif t >= 1200.0 AND t<=1225.0 then 			
        --		trigger <= '1';				
		else
			trigger <='0';
		end if;
		
	end if;
		
	wait for 0.01 ns;


elsif SIMULATION_MODE = "REG_PULSES" then

--
--		if t = 0.0 then
--			if trg_cnt_3 /= 1 then
--			trg_cnt_3<=trg_cnt_3-1;
--			else
--			trg_cnt_3<=3;
--			end if;
--		
--			if trg_cnt_10 /= 1 then
--			trg_cnt_10<=trg_cnt_10-1;
--			else
--			trg_cnt_10<=10;
--			end if;
--		end if;
--
--		if t_MASK_1 <= GEN_TRIGGER_MASK_1*10.0**3.0 then
--			deadtime_1<='1';
--		else
--			t_MASK_1 <=0.0;
--			deadtime_1<='0';
--		end if;
--
--		if t_MASK_3 <= GEN_TRIGGER_MASK_3*10.0**3.0 then
--			if trg_cnt_3 = 1 then
--			deadtime_3<='1';
--			else
--			deadtime_3<='0';
--			end if;			
--		else
--			t_MASK_3<=0.0;
--			deadtime_3<='0';
--		end if;
--		
--		if t_MASK_10 <= GEN_TRIGGER_MASK_10*10.0**3.0 then
--			if trg_cnt_10 = 1 then
--			deadtime_10<='1';
--			else
--			deadtime_10<='0';
--			end if;
--		else
--			t_MASK_10<=0.0;
--			deadtime_10<='0';
--		end if;
--		
--		deadtime <= deadtime_1 OR deadtime_3 OR deadtime_10;

    if t >= Pulse_Dist-0.01 then
        t <=0.0;
        seed1:= seed1 + 1;
        seed2:= seed2 + 2;
        
        UNIFORM(seed1,seed2, shift_rand);
        t_rand <= 0.1;--0.001*round(1000.0*shift_rand); -- oder shift_rand addieren
        Pulse_Dist_rand<=Pulse_Dist*shift_rand;
    
        if seed1 >= 16000 then
            seed1 := 1;
        end if;

        if seed2 >= 16000 then
            seed2 := 2;
        end if;
    
    
    else
        UNIFORM(seed1,seed2, rand1);
        UNIFORM(seed2,seed1, rand2);
        
        seed1:= seed1 + 1;
        seed2:= seed2 + 2;
        seed_int<= seed_int +2;
        
        if seed_int >=2**8 then
            seed1:= 1;
            seed2:= 1;
            seed_int<=1;
        end if;


        if RAND1 = 0.0 OR RAND1 = 1.0 then
            srandom1<=0.5;
        else
            srandom1 <= RAND1;
            srandom2 <= RAND2-0.00001;
        end if;

        gauss_noise<=SQRT(-2.0*LOG(srandom1))*COS(2.0*MATH_PI*srandom2);

        if IN_SPILL = '1' then
            analog <=  (m_offset * ( DAC_offset - A * 1.6 * ( exp( -0.5 * ( (t+t_rand+t_off)/B + exp(-(t+t_rand+t_off)/B) ) ) ) ))+ C ; --with C noise
        else	
            analog <= DAC_offset + 0.0015*gauss_noise;
        end if;

        t <= t + 0.01;
        t_MASK_1 <= t_MASK_1 + 0.01;
        t_MASK_3 <= t_MASK_3 + 0.01;
        t_MASK_10 <= t_MASK_10 + 0.01;

        if t >= 900.0  AND t <=925.0 then
            trigger <= '1'; 				
            -- elsif t >= 1200.0 AND t<=1225.0 then 			
            --   trigger <= '1';				
        else
            trigger <='0';
        end if;
    
    end if;

    wait for 0.01 ns;		
		
		
elsif SIMULATION_MODE = "MAX_AMP_TEST" then

	if t >= Pulse_Dist-0.01 then
	    t <=0.0;
        
	    UNIFORM(seed1,seed2, shift_rand);
		t_rand <= 0.1;--0.001*round(1000.0*shift_rand); -- oder shift_rand addieren
		Pulse_Dist_rand<=Pulse_Dist*shift_rand;
		
		if seed1 >= 16000 then
		    seed1 := 1;
		end if;

		if seed2 >= 16000 then
		    seed2 := 2;
		end if;
		
	end if;
	
	
	if RAND1 = 0.0 OR RAND1 = 1.0 then
	    srandom1<=0.5;
	else
	    srandom1 <= RAND1;
	    srandom2 <= RAND2-0.00001;
	end if;

	gauss_noise<=SQRT(-2.0*LOG(srandom1))*COS(2.0*MATH_PI*srandom2);
	analog<= DAC_offset + 0.0015*gauss_noise+t;


elsif SIMULATION_MODE = "DAC_CALIB" then


	if t >= Pulse_Dist-0.01 then
	    t <=0.0;
		
        --	if DAC_offset <= 4.04 then
        --	    DAC_offset <= 4.08;
        --	else 
        --	    DAC_offset <= DAC_offset - 0.01;
        --	end if;

        --	UNIFORM(seed1,seed2, shift_rand);
        --  if t_off <=1.99 then
        --		t_off <= 0.002*round(1000.0*shift_rand); -- oder shift_rand addieren
        --      t_off <= 0.0; --no t offset to pulse
        --  else 
        --      t_off <= 0.0;
        --  end if;
	else

		UNIFORM(seed1,seed2, rand1);
		UNIFORM(seed2,seed1, rand2);

		seed1:= seed1 + 1;
		seed2:= seed2 + 2;
		seed_int<= seed_int +2;

		if seed_int >=2**8 then
		    seed1:= 1;
		    seed2:= 1;
		    seed_int<=1;		
		end if;
		
		if RAND1 = 0.0 OR RAND1 = 1.0 then
		    srandom1<=0.5;
		else
		    srandom1 <= RAND1;
		    srandom2 <= RAND2-0.00001;
		end if;

		gauss_noise<=SQRT(-2.0*LOG(srandom1))*COS(2.0*MATH_PI*srandom2);
		analog <= DAC_offset + 0.0015*gauss_noise;
		
		t <= t + 0.01;
		
		if t >= 500.0 AND t <=525.0 then
			trigger <= '1'; 
		
		else 
			trigger <='0';
		end if;
			
	end if;
		
	wait for 0.01 ns;


elsif SIMULATION_MODE = "5MHz_p" then

	
	if t >= Pulse_Dist_rand-0.01 then
		t <=0.0;
		--seed1:= seed1 + 1;
		--seed2:= seed2 + 2;

		UNIFORM(seed1,seed2, shift_rand);
			t_rand <= 0.001*round(1000.0*shift_rand); -- oder shift_rand addieren
			Pulse_Dist_rand<=3.0*(2.0/(5.0))*Pulse_Dist*TRIGGER_RATE/((10.0**3))*shift_rand;
			
        --	if seed1 >= 16000 then
        --	    seed1 := 1;
        --	end if;
        --	if seed2 >= 16000 then
        --	    seed2 := 2;
        --	end if;
		

	else
	    UNIFORM(seed1,seed2, rand1);
	    UNIFORM(seed2,seed1, rand2);
	    --seed1:= seed1 + 1;
	    --seed2:= seed2 + 2;
	    --seed_int<= seed_int +2;
	    --if seed_int >=2**8 then
        
	    --seed1:= 1;
	    --seed2:= 1;
	    --seed_int<=1;
        
	    --end if;
	    if RAND1 = 0.0 OR RAND1 = 1.0 then
	        srandom1<=0.5;
	    else
	        srandom1 <= RAND1;
	        srandom2 <= RAND2-0.00001;
	    end if;
	    gauss_noise<=SQRT(-2.0*LOG(srandom1))*COS(2.0*MATH_PI*srandom2);
	    if IN_SPILL = '1'   then
	        analog <=  ( - shift_rand*A*3.0 * ( exp( -0.5 * ( (t+t_rand-5.0)/(B*0.691) + exp(-(t+t_rand-5.0)/(B*0.691))-1.0 ) ) ) )+ C * 0.0-0.2 ; --with C noise 
	    else 	
	        analog <= C*0.0 -0.2;
	    end if;
	
	    t <= t + 0.01;
		
	end if;
		
	wait for 0.01 ns;
		
end if;
		
end process;


--DAC_TEST : process
--
--begin
--	
--		wait for 300 us; --has to be extended for SLINK Readout!!!
--		
--		m_offset<=4.048;
--				
--
--end process;

pseudo_spill : process

begin
	
	loop
		wait until rising_edge (BOS);
		
		ON_SPILL <= '1';
		
		wait until rising_edge (EOS);
	
		ON_SPILL <= '0';
		
	end loop;	

end process;

trigger_out<=trigger;



end Behavioral;

