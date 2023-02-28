----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:	   08:12:07 07/01/2009 
-- Design Name: 
-- Module Name:	   tcs_ctrl - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: Mancava tcs_clk a tutti i process ...
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

--use WORK.TOP_LEVEL_DESC.all;
use WORK.G_PARAMETERS.all;      

--use IEEE.STD_LOGIC_ARITH.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity tcs_ctrl is

	generic(
		GEN_CAL_TRG_TYPE  : std_logic_vector(4 downto 0) := "11010";
		GEN_CAL_SL_OUTPUT : boolean						 := false;	--generate SLINK output on calibration trigger
		GEN_BOR_CNT		  : integer range 0 to 255		 := 10;
		GEN_BOS_CNT		  : integer range 0 to 40000	 := 38880;
		GEN_CALIB_CNT	  : integer range 0 to 255		 := 50
		);
	port (
		CONTROL	   : inout std_logic_vector(35 downto 0);
		TRIGGER	   : in	   std_logic;
		TCS_CLK	   : in	   std_logic;
		CE		   : in	   std_logic;
		BOR		   : in	   std_logic;
		EOR		   : in	   std_logic;
		BOS		   : in	   std_logic;
		EOS		   : in	   std_logic;
		EVENT_TYPE : out   std_logic_vector(4 downto 0);
		TCS_CLK_P  : out   std_logic;
		TCS_CLK_N  : out   std_logic;
		TCS_DATA_P : out   std_logic;
		TCS_DATA_N : out   std_logic
		);

end tcs_ctrl;

architecture Behavioral of tcs_ctrl is

	signal TCS_DATA_i : std_logic := '0';
	signal CH_CLK	  : std_logic := '1';
	signal EXP_CLK	  : std_logic := '0';

	signal sel		  : integer range 0 to 3   := 0;
	signal bos_sel	  : integer range 0 to 7   := 0;
	signal bos_status : integer range 0 to 7   := 0;
	signal BC_count	  : integer range 0 to 63  := 0;
	signal flt_cnt	  : integer range 0 to 255 := 0;

	signal bor_cnt	 : integer range 0 to 255	:= GEN_BOR_CNT;
	signal bos_cnt	 : integer range 0 to 40000 := GEN_BOS_CNT;
	signal calib_cnt : integer range 0 to 255	:= GEN_CALIB_CNT;

	signal shiftReg : std_logic_vector(31 downto 0) := (others => '0');

	signal EVENT_NUMBER : unsigned(19 downto 0)		   := (others => '0');
	signal SPILL_NUMBER : unsigned(10 downto 0)		   := "000" & X"00";  --(others => '0'); 
	signal EVENT_TYPE_i : std_logic_vector(4 downto 0) := "11010";
	signal ON_SPILL		: std_logic					   := '0';
	signal INIT_SPILL	: std_logic					   := '0';

	signal SERLYZER_DONE : std_logic := '0';
	signal EMPTY_REG	 : std_logic := '0';
	signal MEM_FLT		 : std_logic := '0';
	signal MEM_BOS		 : std_logic := '0';
	signal MEM_EOS		 : std_logic := '0';
	signal EOS_i		 : std_logic := '0';
	signal RUN			 : std_logic := '0';
	signal CALIB_BUSY	 : std_logic := '0';
	signal trigger_i	 : std_logic := '0';
	
	type tcs_state is (st_sleep,
					   st_offspill,
					   st_calibration,
					   st_accept_trigger,
					   st_serlyzer_busy);

	signal state : tcs_state := st_sleep;

---------------------------------------------------------------------------
--chipscope 
---------------------------------------------------------------------------
	component tcs_ctrl_ila
		port (
			CONTROL     : inout std_logic_vector(35 downto 0);
			CLK		    : in	std_logic;
			DATA	    : in	std_logic_vector(63 downto 0);
			TRIG0	    : in	std_logic_vector(7 downto 0));
	end component;

      
	signal ila_trg	    : std_logic_vector(7 downto 0);
	signal ila_data	    : std_logic_vector(63 downto 0) := (others => '0');
	signal chipstate    : std_logic_vector(2 downto 0);

-------------------------------------------------------------------------------	 

begin

-------------------------------------------------------------------------------
-- chipscope
-------------------------------------------------------------------------------
Inst_chipscope : if USE_CHIPSCOPE_ILA_1 generate

	chipstate <= "000" when state = st_sleep else
				 "001" when state = st_offspill		  else
				 "010" when state = st_calibration	  else
				 "011" when state = st_accept_trigger else
				 "100" when state = st_serlyzer_busy;
	
	
	ila_trg	 <= TRIGGER & MEM_FLT & MEM_BOS & MEM_EOS & trigger_i & BOR & BOS & EOS;
	ila_data <= TRIGGER & MEM_FLT & MEM_BOS & MEM_EOS & trigger_i & BOR & BOS & TCS_DATA_i & EVENT_TYPE_i & ON_SPILL & INIT_SPILL & std_logic_vector(EVENT_NUMBER) & std_logic_vector(SPILL_NUMBER) & chipstate & std_logic_vector(to_unsigned(bos_sel, 4)) & std_logic_vector(to_unsigned(bos_status, 4)) & SERLYZER_DONE & RUN & "0" & x"0";


	ila_inst : tcs_ctrl_ila
		port map (
			CONTROL => control,
			CLK		=> tcs_clk,
			DATA	=> ila_data,
			TRIG0	=> ila_trg
		);

end generate;


------------------------------------------------------------------------------- 

-- inst_tcs_trg : if BS_GIMLI_TYPE = "TCS" or BS_GIMLI_TYPE = "VXS" generate   
	TCS_DATA_P <= TCS_DATA_i;
	TCS_DATA_N <= not(TCS_DATA_i);
-- end generate;                                                               

-- inst_self_tcs : if BS_GIMLI_TYPE = "OCX" generate	                       
--      removed due to we
--		use this modul not for simmulation but for generation of tcs signals
-- 	TCS_DATA_P <= not(TRIGGER);                                                
--     TCS_DATA_N <= TRIGGER;                                                  
-- end generate;                                                               


	EVENT_TYPE <= EVENT_TYPE_i;

	TCS_clk_p  <= TCS_clk;
	TCS_clk_n  <= not TCS_clk;
     
	--create_CH_CLK : process (TCS_CLK)
	--begin
	--	if (TCS_CLK = '1' and TCS_CLK'event) then
	--	  CH_CLK <= not
	--	end if;
	--end 
	--create_EXP_CLK : process (CH_CLK)
	--begin
	--	if (CH_CLK = '0' and CH_CLK'event) then
	--	  EXP_CLK <= not 
	--	end if;
	--end process;


	create_TCSdata_B_ch : process(tcs_clk)
	begin
		if rising_edge(TCS_CLK) then
		    if CE = '1' then
		        --Serializer
		    	shiftReg <= shiftReg(30 downto 0) & '0';

		    	if BC_count > 0 then
		    		BC_count <= BC_count-1;
		    	end if;

		    	if MEM_FLT = '1' then
		    		shiftReg(31 downto 0) <= b"0001" & b"0110" & std_logic_vector(EVENT_NUMBER(7 downto 0)) & b"000" & EVENT_TYPE_i & b"01010101";	--BC2_1
		    		if to_integer(EVENT_NUMBER(7 downto 0)) = 255 then
		    			BC_count <= 63;
		    		else
		    			BC_count <= 31;
		    		end if;
                
		    	end if;

		    	if BC_count = 32 then
		    		shiftReg(31 downto 0) <= b"0001" & b"0111" & "0000" & std_logic_vector(EVENT_NUMBER(19 downto 8) + 1) & b"01010101";  --BC2_2
		    	end if;

		    	if MEM_EOS = '1' then
		    		shiftReg(31 downto 0) <= b"0001" & b"00010" & b"10" & b"00" & std_logic_vector(SPILL_NUMBER) & b"01010101";	 --BC1
		    		BC_count			  <= 31;
		    	end if;

		    	if MEM_BOS = '1' then
		    		shiftReg(31 downto 0) <= b"0001" & b"00010" & b"01" & b"00" & std_logic_vector(SPILL_NUMBER) & b"01010101";	 --BC1
		    		BC_count			  <= 31;
		    	end if;

		    	if EMPTY_REG = '1' then
		    		shiftReg(31 downto 0) <= (others => '0');
		    		BC_count			  <= 31;
		    	end if;
                
			end if;
		end if;
		
	end process;


										--merge A B channels

	merge_AB_channels : process(tcs_clk)
	begin
		if rising_edge(TCS_CLK) then
		    case sel is
		    	when 0 | 2 =>
		    		TCS_DATA_i <= not TCS_DATA_i;
		    		sel		   <= sel + 1;
		    	when 1 =>
		    		TCS_DATA_i <= TCS_DATA_i xnor trigger_i;
		    		sel		   <= sel + 1;
		    	when 3 =>
		    		TCS_DATA_i <= TCS_DATA_i xnor shiftReg(31);
		    		sel		   <= 0;
		    end case;
        end if;
	end process;


	TCS_control : process(tcs_clk)
	begin
		if rising_edge(TCS_CLK) then
		    if CE = '1' then
            
		    	if BC_count = 1 then
		    		SERLYZER_DONE <= '1';
                
		    	else
		    		SERLYZER_DONE <= '0';
                
		    	end if;

		    	if EOR = '1' then
		    		RUN <= '0';
		    	end if;

		    	EMPTY_REG <= '0';
		    	MEM_FLT	  <= '0';
		    	MEM_BOS	  <= '0';
		    	MEM_EOS	  <= '0';
		    	trigger_i <= '0';

		    	case (state) is
		    		when st_sleep =>
		    			if BOR = '1' then
		    				RUN			 <= '1';
		    				SPILL_NUMBER <= (others => '0');
                        
                        
		    			elsif RUN = '1' then
		    				if bor_cnt = 0 then
		    					bor_cnt	   <= GEN_BOR_CNT;
		    					state	   <= st_offspill;
		    					bos_sel	   <= 0;
		    					bos_status <= 0;
                            
		    				else
		    					bor_cnt <= bor_cnt - 1;
                            
		    				end if;
                        
		    			end if;
                    
		    		when st_calibration =>
                    
		    			CALIB_BUSY <= '1';

		    			if calib_cnt = 0 then
		    				calib_cnt	 <= GEN_CALIB_CNT;
		    				MEM_FLT		 <= '1';
		    				trigger_i	 <= '1';
		    				EVENT_NUMBER <= EVENT_NUMBER + 1;
		    				EVENT_TYPE_i <= GEN_CAL_TRG_TYPE;  --CAL_TRIGGER
		    				state		 <= st_serlyzer_busy;
                        
		    			else
		    				calib_cnt <= calib_cnt - 1;
                        
		    			end if;
                    
		    		when st_offspill =>
		    			case (bos_sel) is
		    				when 0 =>
		    					bos_status <= 0;
		    					if BOS = '1' then
		    						bos_sel <= 1;
		    					elsif RUN = '0' then
		    						state <= st_sleep;
		    					end if;
                            
                            
		    				when 1 =>
		    					if bos_cnt = 0 then
		    						bos_cnt	   <= GEN_BOS_CNT;
		    						bos_status <= bos_sel + 1;
		    						bos_sel	   <= 4;
		    						if RUN = '0' then
		    							EVENT_TYPE_i <= "11101";  --LEOR
		    							MEM_FLT		 <= '1';
		    							trigger_i	 <= '1';
		    							EVENT_NUMBER <= EVENT_NUMBER + 1;
                                    
		    						elsif to_integer(SPILL_NUMBER(10 downto 0)) > 0 then
		    							EVENT_TYPE_i <= "11111";  --LEOS
		    							MEM_FLT		 <= '1';
		    							trigger_i	 <= '1';
		    							EVENT_NUMBER <= EVENT_NUMBER + 1;
                                    
		    						else
		    							EMPTY_REG <= '1';
                                    
		    						end if;
                                
		    					else
		    						bos_cnt <= bos_cnt - 1;
		    					end if;
                            
		    				when 2 =>
		    					if bos_cnt = 0 then
		    						bos_cnt		 <= GEN_BOS_CNT;
		    						bos_status	 <= bos_sel + 1;
		    						bos_sel		 <= 4;
		    						MEM_BOS		 <= '1';
		    						SPILL_NUMBER <= SPILL_NUMBER + 1;
                                
		    					else
		    						bos_cnt <= bos_cnt - 1;
                                
		    					end if;
                            
		    				when 3 =>
		    					if bos_cnt = 0 then
		    						bos_cnt	 <= GEN_BOS_CNT;
		    						bos_sel	 <= 0;
		    						ON_SPILL <= '1';
		    						if to_integer(SPILL_NUMBER(10 downto 0)) = 1 then
		    							EVENT_TYPE_i <= "11100";  --FEOR
                                    
		    						else
		    							EVENT_TYPE_i <= "11110";  --FEOS												
                                    
		    						end if;
		    						MEM_FLT		 <= '1';
		    						trigger_i	 <= '1';
		    						EVENT_NUMBER <= b"00000000000000000001";
		    						state		 <= st_serlyzer_busy;
                                
		    					else
		    						bos_cnt <= bos_cnt - 1;
                                
		    					end if;
                            
		    				when 4 =>
		    					if SERLYZER_DONE = '1' then
		    						if RUN = '0' then
		    							state <= st_sleep;
                                    
		    						else
		    							bos_sel <= bos_status;
                                    
		    						end if;
                                
		    					end if;
                            
		    				when others =>
		    					bos_sel <= 0;
                            
		    			end case;
                    
                    
		    		when st_accept_trigger =>
		    			if EOS = '1' then
		    				MEM_EOS	 <= '1';
		    				ON_SPILL <= '0';
		    				state	 <= st_serlyzer_busy;
                        
		    			elsif TRIGGER = '1' then
		    				trigger_i	 <= '1';
		    				MEM_FLT		 <= '1';
		    				EVENT_NUMBER <= EVENT_NUMBER + 1;
		    				EVENT_TYPE_i <= "00000";  --TRIGGER
		    				state		 <= st_serlyzer_busy;
		    			end if;
                    
		    		when st_serlyzer_busy =>
		    			if EOS = '1' then
		    				EOS_i <= '1';
		    			end if;

		    			if TRIGGER = '1' and EOS_i = '0' and ON_SPILL = '1' then
		    				trigger_i <= '1';
		    				flt_cnt	  <= flt_cnt + 1;
		    			end if;

		    			if SERLYZER_DONE = '1' then
		    				if ON_SPILL = '0' then
		    					if CALIB_BUSY = '0' then
		    						state <= st_calibration;
		    					else
		    						state	   <= st_offspill;
		    						CALIB_BUSY <= '0';
		    					end if;
                            
		    				elsif flt_cnt > 0 and (TRIGGER = '0' or EOS_i = '1') then
		    					MEM_FLT		 <= '1';
		    					EVENT_NUMBER <= EVENT_NUMBER + 1;
		    					EVENT_TYPE_i <= "00000";  --TRIGGER
		    					flt_cnt		 <= flt_cnt - 1;
                            
		    				elsif (flt_cnt = 0 nand TRIGGER = '0') and EOS_i = '0' then
		    					MEM_FLT		 <= '1';
		    					EVENT_NUMBER <= EVENT_NUMBER + 1;
		    					EVENT_TYPE_i <= "00000";  --TRIGGER
		    					flt_cnt		 <= flt_cnt;
                            
		    				elsif EOS_i = '1' or EOS = '1' then
		    					MEM_EOS	 <= '1';
		    					EOS_i	 <= '0';
		    					ON_SPILL <= '0';

		    								--missing one if for flt_cnt > 0 and TRIGGER = '1'
		    				else
		    					state <= st_accept_trigger;
		    				end if;
                        
		    			end if;
                    
		    		when others =>
		    			RUN		 <= '0';
		    			ON_SPILL <= '0';
		    			state	 <= st_sleep;
                    
		    	end case;
            
		    end if;
		end if;
	end process;
	
	
end Behavioral;
