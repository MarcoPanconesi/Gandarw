----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:     13:02:38 12/17/2022 
-- Design Name:     
-- Module Name:     ana_nrm_MEP - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description:     Front end adc in normal sampling mode adapted to the MEP
--
-- Dependencies:   
--
-- Revision: 
-- Revision 0.01    File Created - Marco Panconesi
-- More Comments:   --NEW: significa che sono novità rispetto a ana_nrm.
--                  
--
--
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

library UNISIM;
use UNISIM.VComponents.all;

Library UNIMACRO;
use UNIMACRO.vcomponents.all;

USE WORK.TOP_LEVEL_DESC.ALL;
use WORK.G_PARAMETERS.ALL;


entity ana_nrm_MEP is
	Generic(
			ch_no 			: integer 
			);
    Port ( 	
    		clk 			: in  STD_LOGIC;
			frame_in 		: in  STD_LOGIC_VECTOR (23 downto 0);
			frame_ff_empty 	: in  STD_LOGIC;
			BOS				: in  STD_LOGIC;
			--baseline 		: in  STD_LOGIC_VECTOR (10 downto 0);
			--delay 			: in  STD_LOGIC_VECTOR (4 downto 0);
			--frac 			: in  STD_LOGIC_VECTOR (5 downto 0);
			--threshold		: in  STD_LOGIC_VECTOR (7 downto 0);
			--cf_max_dist_i	: in  STD_LOGIC_VECTOR (2 downto 0);
			-- sec_alg_is_on	: in  STD_LOGIC;
			--before_ZC_i		: in  STD_LOGIC_VECTOR (2 downto 0);
			--after_ZC_i		: in  STD_LOGIC_VECTOR (2 downto 0);
			prescaler_base  : in  STD_LOGIC_VECTOR (7 downto 0);
			framewidth 		: in  STD_LOGIC_VECTOR (10 downto 0); --128 (vedi amc_if_8ch)
			rd_frame_ff 	: out STD_LOGIC;
			----------------------------------------NEW:
			buffer_dout 	: out STD_LOGIC_VECTOR (30 downto 0);
			buffer_emp 		: out STD_LOGIC;
			frame_fifo_full : out STD_LOGIC;            
			rd_buffer_ff    : in STD_LOGIC;
			--non c'è un equivalente del clock perchè la buffer FIFO lavora con clk della porta in ingresso.

			--event_data_out	: out STD_LOGIC_VECTOR (30 downto 0);
			--event_ff_empty	: out STD_LOGIC;
			--event_ff_full	: out STD_LOGIC;			
			--frame_fifo_full : out STD_LOGIC;
			--rd_event_ff		: in  STD_LOGIC;
			--event_ff_clk	: in  STD_LOGIC;			
			reset 			: in  STD_LOGIC
			;
		dbg_state_out  :out STD_LOGIC_VECTOR (3 downto 0)
		);
end ana_nrm_MEP;

architecture Behavioral of ana_nrm_MEP is

	COMPONENT divisor
	PORT(
		DATA_0_i : IN std_logic_vector(11 downto 0);
		DATA_1_i : IN std_logic_vector(11 downto 0);
		clk : IN std_logic;          
		RESULT : OUT std_logic_vector(9 downto 0)
		);
	END COMPONENT;

	COMPONENT divisor_15
	PORT(
		DATA_0_i : IN std_logic_vector(14 downto 0);
		DATA_1_i : IN std_logic_vector(14 downto 0);
		clk : IN std_logic;          
		RESULT : OUT std_logic_vector(9 downto 0)
		);
	END COMPONENT;


type state_type is (
						st_reset,					-- reset the whole statemachine
						st_sleep, 					-- sleep, only check statistics all the time
						st_read_frame,
						st_rd_coarse_t,
						st_wait_ana,
						st_write_ana
						);

type state_type_1 is (
						
						sleep,
						no_frame_event,
						unbuffer,
						frame_event,
						no_hit_no_frame_event
						);

signal ana_state 					: state_type :=st_sleep;
signal buffer_state 				: state_type_1 :=sleep;


signal wr_event_ff 				    : std_logic:='0';
signal rd_frame_ffi 				: STD_LOGIC:='0';

--counters

signal fr_counter 				    : STD_LOGIC_VECTOR (10 downto 0);
signal prsc_cnt					    : Integer range 0 to 255:= 255;
signal wd_counter				    : Integer range 0 to 4;
signal count_a 					    : integer range 0 to 20:=5;
signal hit_wr_cnt 				    : STD_LOGIC_VECTOR ( 3 downto 0):=(others => '0');
signal hit_wr_cnt_1 			    : STD_LOGIC_VECTOR ( 3 downto 0):=(others => '0');
signal Max_Amp_cnt 				    : STD_LOGIC_VECTOR ( 3 downto 0):=(others => '0');
signal Max_Amp_1_cnt 			    : STD_LOGIC_VECTOR ( 3 downto 0):=(others => '0');
signal h_res_cnt				    : STD_LOGIC_VECTOR ( 3 downto 0):=(others => '0');
signal h_res_1_cnt				    : STD_LOGIC_VECTOR ( 3 downto 0):=(others => '0');
signal frame_in_i 				    :  STD_LOGIC_VECTOR (23 downto 0);
signal frame_data 				    : STD_LOGIC_VECTOR (23 downto 0):=(others => '0');

subtype 	del_word 			    is std_logic_vector(12 downto 0) ;   
type 		del_words			    is array (INTEGER range<>) of del_word;
signal del_data 				    : del_words(0 to 31):=(others => (others => '0'));

subtype 	cf_word 				is signed(12 downto 0) ;  
type 		cf_words 				is array (INTEGER range<>) of cf_word;

subtype 	Amp_word 				is  STD_LOGIC_VECTOR(11 downto 0) ;   
type 		Amp_words 				is  array (INTEGER range<>) of Amp_word ;

signal cf_data						: cf_words(0 to 12):=(others => (others => '0'));

signal pre_cf_0 					: cf_words(0 to 1):=(others => (others => '0'));
signal pre_cf_1 					: cf_words(0 to 1):=(others => (others => '0'));
signal pre_cf_del					: cf_words(0 to 1):=(others => (others => '0'));
signal pre_cf_del_del			    : cf_words(0 to 1):=(others => (others => '0'));
signal cf_crit						: cf_words(1 to 2):=(others => (others => '0'));
signal last_pos 					: STD_LOGIC_VECTOR (14 downto 0):=(others => '1');
signal first_neg 					: STD_LOGIC_VECTOR (14 downto 0):=(others => '1');
signal frame_t 					    : STD_LOGIC_VECTOR (11 downto 0):=x"000";
signal hit_cnt 					    : STD_LOGIC_VECTOR ( 3 downto 0):=(others => '0');
signal cf_hit 						: STD_LOGIC_VECTOR ( 2 downto 1):=(others => '0');

signal 	Amp_buffer 				    : Amp_words(0 to 8):=(others => (others => '0'));
signal	Amp 						: Amp_words(0 to 3):=(others => (others => '0'));
signal 	post_cf_hit 			    : STD_LOGIC_VECTOR ( 2 downto 1):=(others => '0');
signal 	cf_max_dist				    : Integer range 0 to 8 :=3;

signal	preAmp					    : Amp_words(0 to 1):=(others => (others => '0'));
signal 	preAmp_set        	        : std_logic:='0';
signal 	MaxAmp_set        	        : std_logic:='0';
signal	MaxAmp 					    : STD_LOGIC_VECTOR (11 downto 0);

signal cf_1_data					: cf_words(0 to 2):=(others => (others => '0'));
signal pre_cf_1_0 				    : cf_words(0 to 1):=(others => (others => '0'));
signal pre_cf_1_1 				    : cf_words(0 to 1):=(others => (others => '0'));
signal pre_cf_1_del				    : cf_words(0 to 1):=(others => (others => '0'));
signal pre_cf_1_del_del			    : cf_words(0 to 1):=(others => (others => '0'));
signal cf_1_crit					: cf_words(1 to 2):=(others => (others => '0'));
signal cf_1_crit_del				: cf_words(1 to 2):=(others => (others => '0'));
signal last_pos_1 				    : STD_LOGIC_VECTOR (11 downto 0):=(others => '1');
signal first_neg_1 				    : STD_LOGIC_VECTOR (11 downto 0):=(others => '1');
signal frame_t_1 					: STD_LOGIC_VECTOR (11 downto 0):=x"000";
signal hit_cnt_1 					: STD_LOGIC_VECTOR ( 3 downto 0):=(others => '0');
signal cf_1_hit 					: STD_LOGIC_VECTOR ( 2 downto 1):=(others => '0');

signal 	Amp_1_buffer 			    : Amp_words(0 to 6):=(others => (others => '0'));
signal	Amp_1 					    : Amp_words(0 to 3):=(others => (others => '0'));
signal 	post_cf_1_hit 			    : STD_LOGIC_VECTOR ( 2 downto 1):=(others => '0');
signal 	cf_max_dist_1				: Integer range 0 to 4 :=1;

signal	preAmp_1					: Amp_words(0 to 1):=(others => (others => '0'));
signal 	preAmp_1_set        	    : std_logic:='0';
signal 	MaxAmp_1_set        	    : std_logic:='0';
signal	MaxAmp_1 					: STD_LOGIC_VECTOR (11 downto 0);


signal event_data 				: STD_LOGIC_VECTOR (30 downto 0):=(others => '0');

signal presum 						: STD_LOGIC_VECTOR (11 downto 0):=(others => '0'); 
signal integral					: STD_LOGIC_VECTOR (15 downto 0):=(others => '0');
signal wr_integral				: STD_LOGIC_VECTOR (15 downto 0):=(others => '0');
signal wr_integral_1				: STD_LOGIC_VECTOR (15 downto 0):=(others => '0');

signal preamp0						: STD_LOGIC_VECTOR (11 downto 0):=(others => '0');
signal preamp1						: STD_LOGIC_VECTOR (11 downto 0):=(others => '0');
signal amplitude					: STD_LOGIC_VECTOR (11 downto 0):=(others => '0');

signal basel						: STD_LOGIC_VECTOR (12 downto 0):="00000" & x"C8"; 

signal start_int 					: std_logic:='0';

signal pre_coarse_t 				: STD_LOGIC_VECTOR (37 downto 0):=(others => '0');
signal coarse_t 					: STD_LOGIC_VECTOR (37 downto 0):=(others => '0');
signal read_lsb					: std_logic:='0';
signal h_res_t 					: STD_LOGIC_VECTOR (9 downto 0):=(others => '0');
signal h_res_t_1 					: STD_LOGIC_VECTOR (9 downto 0):=(others => '0');

signal delay_i						: Integer range 0 to 31;
signal fraction					: Integer range 0 to 5;
signal zero 						: STD_LOGIC_VECTOR ( 5 downto 0):=(others => '0');

signal cal_basel					: signed(12 downto 0) ;
signal del_cnt 					: STD_LOGIC_VECTOR ( 5 downto 0):=(others => '0');
signal cf_active					: std_logic:='0';



signal 	h_res_ready 			:	 STD_LOGIC_VECTOR ( 5 downto 0):=(others => '0');
signal 	h_res_1_ready 			:	 STD_LOGIC_VECTOR ( 3 downto 0):=(others => '0');

signal 	buffer_MaxAmp 			:	 Amp_words(0 to 15):=(others => (others => '0'));
signal 	buffer_MaxAmp_1 			:	 Amp_words(0 to 15):=(others => (others => '0'));

subtype 	buffer_frame_t_word 	is	 STD_LOGIC_VECTOR(11 downto 0)  ;   
type 		buffer_frame_t_words is	 array (INTEGER range<>) of buffer_frame_t_word ;
subtype 	buffer_h_time_word 	is	 STD_LOGIC_VECTOR(9 downto 0)  ;   
type 		buffer_h_time_words 	is	 array (INTEGER range<>) of buffer_h_time_word ;

signal 	buffer_frame_t 		:	 buffer_frame_t_words(0 to 15):=(others => (others => '0'));
signal 	buffer_frame_t_1 		:	 buffer_frame_t_words(0 to 15):=(others => (others => '0'));

signal 	buffer_h_time 			:	 buffer_h_time_words(0 to 15):=(others => (others => '0'));
signal 	buffer_h_time_1 			:	 buffer_h_time_words(0 to 15):=(others => (others => '0'));



signal 	buffer_din 				: STD_LOGIC_VECTOR (30 downto 0):=(others => '0');
--signal 	buffer_dout 			: STD_LOGIC_VECTOR (30 downto 0):=(others => '0'); 				--NEW: non serve più
signal 	wr_buffer_ff 			: std_logic:='0';
--signal 	rd_buffer_ff 			: std_logic:='0';   											--NEW: non serve più

-- questi in realta' non servono ma non possono essere open ???
signal 	rd_buffer_fifo_cnt	    : STD_LOGIC_VECTOR (8 downto 0); -- era 9
signal 	wr_buffer_fifo_cnt	    : STD_LOGIC_VECTOR (8 downto 0); -- era 9
signal  rd_fifo_cnt			    : STD_LOGIC_VECTOR (8 downto 0); -- era 9
signal  wr_fifo_cnt			    : STD_LOGIC_VECTOR (8 downto 0); -- era 9


signal 	buffer_counter 		: integer range 0 to 4095;
signal  	to_event_fifo			: std_logic:='0';


--signal 	buffer_emp 				: std_logic:='0';												--NEW: non serve più

signal 	cf_is_written 				: std_logic:='0';
signal wait_cf_calc					: integer range 0 to 20;

signal before_ZC						: integer range 0 to 5:=1;
signal after_ZC						: integer range 0 to 5:=5;

signal cf_counter						:STD_LOGIC_VECTOR (10 downto 0):="00000000000";

subtype 	pre_keep_prec_word 				is std_logic_vector(4 downto 0) ;   
type 		pre_keep_prec_words			 	is array (INTEGER range<>) of pre_keep_prec_word;
signal pre_keep_prec 					: pre_keep_prec_words(0 to 1):=(others => (others => '0'));

subtype 	pre_keep_prec_del_word 				is std_logic_vector(2 downto 0) ;   
type 		pre_keep_prec_del_words			 	is array (INTEGER range<>) of pre_keep_prec_del_word;
signal pre_keep_prec_del 					: pre_keep_prec_del_words(0 to 31):=(others => (others => '0'));

subtype 	keep_prec_word 				is std_logic_vector(2 downto 0) ;   
type 		keep_prec_words			 	is array (INTEGER range<>) of keep_prec_word;
signal 	keep_prec 					: keep_prec_words(0 to 9):=(others => (others => '0'));

subtype 	pre_calc_basel_word 				is std_logic_vector(15 downto 0) ;   
type 		pre_calc_basel_words			 	is array (INTEGER range<>) of pre_calc_basel_word;
signal 	pre_calc_basel 					: pre_calc_basel_words(0 to 1):=(others => (others => '0'));

signal 	calc_basel							: STD_LOGIC_VECTOR (11 downto 0);
signal 	wait_calc_basel					: integer range 0 to 20:=20;
signal bos_i:std_logic := '0';
---debug
signal dbg_state					: STD_LOGIC_VECTOR ( 3 downto 0):=(others => '0');

begin -------------------------------------------------------------------------------------------------------------------------------------BEGIN-------

--basel<="00"& baseline;

--before_ZC<=		to_integer(unsigned(before_ZC_i));  --non gli arriva niente dalla porta non usiamo Zero Crossing
--after_ZC<=		to_integer(unsigned(after_ZC_i));

--cf_max_dist	<=		to_integer(unsigned(cf_max_dist_i));

rd_frame_ff <= rd_frame_ffi;

dbg_state_out<= dbg_state;

frame_in_i<=frame_in;


read_frame : PROCESS(clk) 

BEGIN
	
	if (clk'event AND clk='1') then 
	
		if BOS = '1' then --salvo che sono al Begin of burst (inizio)
			bos_i <= '1';
		end if;
		
		case(ana_state) is
		
			when st_reset =>
	
				if RESET = '0' then
					prsc_cnt <=to_integer( unsigned(prescaler_base)); --GEN_PRESCALER;		--DA NOI SEMPRE =0    reset frame event prescaler (prsc_cnt=0 means write debug event) 

					ana_state <= st_sleep;													--CHANGE STATE--

				else 
					dbg_state <= x"7";				
					wr_event_ff	<= '0';																
					wr_buffer_ff<= '0';
					
					ana_state	<=st_reset;													--CHANGE STATE--						
				
				end if;
				
			when st_sleep =>
                -------------------------------------------------------------|
				if bos_i='1' then --begin of spill                           |
					bos_i <= '0'; --                                         | INUTILE, inviamo solo debug frame noi, prsc_cnt sempre a 0
					prsc_cnt 	<= to_integer( unsigned(prescaler_base));--  |
				end if; --                                                   |
                -------------------------------------------------------------|

				dbg_state <= x"1";	
				rd_frame_ffi	<= '0';	
				wr_buffer_ff   <= '0';
	
				if reset ='1' then  
					fr_counter	<= framewidth-1;											--conta il numero di campioni da scrivere nella BUFFER_FIFO
					--NEW prsc_cnt 	<= to_integer( unsigned(prescaler_base));--GEN_PRESCALER		-- !!TODO: was wenn frame_ff_empty='0' und reset auf 1!!

					ana_state	<= st_reset;												--CHANGE STATE--
				else 

					ana_state	<= st_sleep;												--CHANGE STATE--

				end if;
				
				if frame_ff_empty = '0' then 	--se FRAME_FIFO non è vuota											(--there is frame data, read it from frame fifo for analysis)
					rd_frame_ffi    <= '1'; 	--abilito lettura FRAME_FIFO
					frame_data      <= frame_in_i; --assegno i dati di frame_in_i  a frame_data (frame_in_i sono dati in uscita dalla FRAME_FIFO)
					fr_counter		<= framewidth - 1;										--first two samples were read
					
					ana_state       <= st_read_frame;										--CHANGE STATE--

				else 

					ana_state	<=st_sleep;	--se FRAME_FIFO è vuota resta in sleep												--CHANGE STATE--

				end if;
					
			when st_read_frame =>	--leggo FRAME FIFO														(--read the frame from frame fifo for analysis, in any 128th event write the frame also to buffer fifo)
				dbg_state <= x"2";			
				buffer_din <= b"000" & frame_data(23 downto 12) & x"0" & frame_data(11 downto 0); --INSERISCE DATI in buffer_din quindi nella BUFFER_FIFO 
				--in frame_data ci sono i dati in uscita dalla FRAME FIFO (sopra avevo messo frame_in_i dentro frame_data)

                rd_frame_ffi	<= '0';                    			
                if frame_ff_empty = '0' then    --se non è vuota la fifo                                            --aggiunto controllo sul fifo empty
                    if fr_counter /= 0 then	 --se ci sono ancora campioni da scrivere nella BUFFER_FIFO, si ripete ad ogni clock finchè non si azzera il contatore
					    fr_counter		<= fr_counter - 1;	--decremento perchè sto per leggere					            (--Modifica di ana_ilm)
                        rd_frame_ffi	<= '1';	        --abilito lettura                                    --legge la fifo del canale ad ogni clk
                        frame_data      <= frame_in_i;   --butto quello che arriva dalla frame fifo dinuovo in frame_data                                   --per fr_counter - 1 times --- 		
						--frame_data viene usato nei calcoli pre estrarre le informazioni (in BUFFER_FIFO viene scritto altro ovvero i risultati di quei conti)	
        
					    if prsc_cnt = 0 then --DA NOI SEMPRE =0												--write frame to buffer fifo for every 128th event
					    	wr_buffer_ff		<= '1'; -- ABILITO SCRITTURA NELLA BUFFER_FIFO quindi i dati in buffer_din li faccio entrare
					    else
					    	wr_buffer_ff		<= '0'; --NON abilito, tutti finchè prsc_cnt è diverso da 0 (normal mode) salto la scrittura di questi dati
					    end if;
				    else --quando finsce il contatore
				    	rd_frame_ffi	<= '1';	--setto ancora a 1 perchè leggerò nell'altro stato st_rd_coarse_time il coarse time					(--this is to read coarse time from frame FIFO)
				    	read_lsb 		<= '1';										        --PREPARE NEXT STATE

				    	ana_state <= st_rd_coarse_t;								        --CHANGE STATE--
                    end if;
			    end if;	
			----NEW: coarse_time lo leggo comunque ovviamente, per svuotare la frame fifo	
			when st_rd_coarse_t =>	--legge (COARSE_TIME) che verrà messo a fine frame (!!!!!!!)   (--the coarse time is written at the end of any frame)
			
				dbg_state <= x"3";			
				wr_buffer_ff		<= '0';		--disabilito scrittura BUFFER_FIFO						
								
				if read_lsb = '1' then 		--leggo nuovamente la FRAME_FIFO che ora mi avrà passato il COARSE_TIME	(entro sempre prima qui nell'IF)				--read lsb coarse_t
					pre_coarse_t(20 downto 0) <= frame_in_i(20 downto 0); --leggo 21 bit dalla FRAME_FIFO e li metto in pre_coarse_t (sono i suoi LSB)
					read_lsb <= '0'; --mi preparo a leggere gli MSB
				else 																		--read msb coarse_t
					pre_coarse_t(37 downto 21) <= frame_in_i(16 downto 0); --leggo 17 bit dalla FRAME_FIFO e li metto in pre_coarse_t (sono i suoi MSB)
					
					--NEW:ana_state <= st_wait_ana;	--posso passare allo stato successivo, ho raccolto tutti i dati											--CHANGE STATE--
					ana_state <= st_sleep;						
					
				end if;

				--NEW: non serve più count_a <= 20;	--serve nello stato successivo per attendere				--PREPARE NEXT STATE (defines time to wait for last analysis result -- highres time of last hit in frame)





			--NEW: rimuovo questo stato, non devo più attendere l'analyzer	--------------------------------
			
			
			-- when st_wait_ana =>																--wait until the pulse analysis process is finished (IN PARALLELO QUALCUNO ELABORA I DATI SLAVATI PRIMA)
                
				

			-- 	dbg_state <= x"4";	
			-- 	rd_frame_ffi		<= '0';													--!!muss wahrsch eins frher auf null!!

            --     ----NEW
            --     count_a <= count_a-1;
				
			-- 	if count_a = 2 then		--ASPETTA 18 COLPI DI CLOCK per far fare al resto del codice delle analisi (ad ogni colpo di clock riparte rimanendo all'interno di questo stato e decrementando count_a)	
					
			-- 		cf_is_written<='0'; --cf=Constant Fraction disabilito la sua scrittura

			-- 		if hit_cnt = "0000"  then		--NO hit								
			-- 			wr_integral <= x"FFEE";		--come informazione wr_integral	scrivi un valore fittizio (FFEE)									
			-- 			hit_wr_cnt<="0000";			--segnati che non c'è stata l'hit
                        
			-- 		else							--hit
			-- 			wr_integral <= integral;	--inserisci in wr_integral il valore vero dell'integrale calcolato in un'altra parte del codice (carica dell'impulso)
			-- 			hit_wr_cnt<="0001";			--segnati che c'è stata l'hit 
            --                                                                                     --  how many hits were written to buffer fifo						
			-- 		end if;
			-- 		--stessa cosa per questo hit_cnt_1 (che non ho capito) (è tipo un secondo algoritmo che toglieremo)
			-- 		if hit_cnt_1 = "0000"  then
			-- 			wr_integral_1 <= x"FFEE";						
			-- 			hit_wr_cnt_1<="0000";
			-- 		else
			-- 			wr_integral_1 <= integral;
			-- 			hit_wr_cnt_1<="0001";
			-- 		end if;

			-- 	end if;
                 
		
			-- 	if count_a = 1 then														        --CHANGE STATE--	

			-- 		if buffer_state=sleep then --non sto scrivendo la EVENT_FIFO al momento
			-- 		--se non è in sleep, salta all'assegnamento count_a<=2 -> nuovo clk: riparte da capo lo stato, count_a viene decrementato e passa a 1
			-- 		--se sono in stato sleep tutto ok, se non sono in sleep o sono in unbuffered e al successivo clock sarò in sleep oppure sono in altri due stati che entrambi al clock succ. vanno in unbuffered
			-- 		--(impiegano 2 clock ad arrivare in sleep)

			-- 			if prsc_cnt /= 0 then --PER NOI è UGUALE A ZERO PERCHè DOBBIAMO SCRIVERE TUTTI I DATI (TUTTI DEBUG FRAME [FRAME DI DATI GREZZI])
			-- 								  						--|
			-- 				if hit_cnt= "0000"  then				--|
			-- 					buffer_state<=no_hit_no_frame_event;--|							
			-- 					ana_state<=st_sleep;				--|
			-- 					prsc_cnt <= prsc_cnt-1;				--|   NON CI ENTRA QUI
			-- 				else									--|
			-- 			--NEW:ana_state <= st_write_ana;			--|
			-- 				end if;									--|
			-- 	 													--|
			-- 			else --ENTRA SEMPRE QUI
			-- 				--NEW: ana_state <= st_write_ana;	--mi preparo per st_write_ana = scrivere dati raffinati finalmente sulla BUFFER_FIFO	
                            									        
            --                 ana_state <= st_sleep;										
			-- 			end if;

			-- 			--NEW:buffer_counter<=0; --inizializzo per dopo
				
			-- 		----NEW else
						
			-- 			----NEW count_a<=2; --CORREZIONE--  era 1 ... (Marco)
						
			-- 		end if;
				
			-- 	end if;
						
				
				--NEW:wd_counter <= 3;																--PREPARE NEXT STATE






            --NEW: ELIMINO SCRITTURA DATI RAFFINATI------------------------------------------------------------------------------------------------------


                             
			-- when st_write_ana => 	--stato di scrittura nella BUFFER_FIFO
			-- --questo stato lo ripeto hit_cnt volte per il 1 algoritmo (scrivo tutte le hit)
			-- --poi lo ripeto altre hit_cnt_1 volte per il 2 algoritmo (scrivo tutte le hit) [TOGLIEREMO il secondo algoritmo]

			-- 	dbg_state <= x"5";			
			-- 	wr_buffer_ff		<= '1';	--abilito scrittura BUFFER_FIFO												    --WRITE ENABLE to buffer fifo

			-- 	if wd_counter = 3 then 		--PRIMA PAROLA (vengo dallo stato st_wait_ana)	

			-- 		buffer_counter<=buffer_counter+1; --era a 0: mi segno che scrivo una riga
			-- 		if cf_is_written='0' then --Constant fraction non è stato scritto
			-- 			buffer_din <= std_logic_vector(to_unsigned    --scrivo nella BUFFER_FIFO le pulse features calcolate
			-- 						 ( ch_no, 4 ) ) & calc_basel(10 downto 0) &  wr_integral;	--first pulse-feature Slink word -- era (ch_no * 2) CORRETTO
			-- 			coarse_t 	<= pre_coarse_t 
			-- 						    + buffer_frame_t(to_integer(unsigned(hit_wr_cnt)));	    --prepare next word
			-- 							--in questo buffer_frame_t viene messo all'indice hit_cnt (numero di hit totali) (??circa quanti confronti ha fatto nello studio dello zero crossing??) la 
			-- 							--dimensione del frame
			-- 							--QUINDI in coarse_t viene messo il tempo alla quale arriva il segnale + durata segnale = tempo finale (sembra)
			-- 		else --stessa cosa per l'altro constant fraction (cf1) [TOGLIERE non abbiamo 2 algo]
			-- 			buffer_din <= std_logic_vector(to_unsigned
			-- 						 ( ch_no, 4 ) ) & calc_basel(10 downto 0) & wr_integral_1;	--first pulse-feature Slink word -- era (ch_no * 2) CORRETTO
			-- 			coarse_t 	<= pre_coarse_t 
			-- 							+ buffer_frame_t_1(to_integer(unsigned(hit_wr_cnt_1)));	--prepare next word
			-- 		end if;


			-- 		wd_counter <= 2; --ho scritto una parola

			-- 	end if;
					
			-- 	if wd_counter = 2 then  --SECONDA PAROLA
			-- 		buffer_counter<=buffer_counter+1; --scrivo un'altra parola/riga
			-- 		if cf_is_written='0' then	--se CF non è stato scritto prendo i suoi dati altrimenti quelli di cf1 (l'altro constant fraction)												--setabel cf

			-- 			buffer_din <= coarse_t(37 downto 21) & b"00"  --scrivo coarse_time (MSB) e ampiezza massima impulso
			-- 							  & buffer_MaxAmp( to_integer    --AMPLITUDE MASSIMA IMPULSO
			-- 							  ( unsigned(hit_wr_cnt) ) );							--second pulse-feature Slink word
			-- 		else																		--fixed del 1 ff 1 cf
			-- 			buffer_din <= coarse_t(37 downto 21) & b"01" 					        --mark cf del 1 ff 1
			-- 							  & buffer_MaxAmp_1( to_integer
			-- 						     ( unsigned(hit_wr_cnt_1) ) );						    --second pulse-feature Slink word
			-- 		end if; 


			-- 		wd_counter <= 1;

			-- 	end if;
					
			-- 	if wd_counter = 1 then 				
			-- 		buffer_counter<=buffer_counter+1;
			-- 		if cf_is_written='0' then	
			-- 		buffer_din <= coarse_t(20 downto 0)  --scrivo coarse_time (LSB) e buffer_h_time(?)
			-- 						  & buffer_h_time( to_integer --HIGH RESOLUTION TIME
			-- 						  ( unsigned(hit_wr_cnt) ) );							    --third pulse-feature Slink word
			-- 		else --salta, è il 2 algoritmo
			-- 		buffer_din <= coarse_t(20 downto 0) 
			-- 						  & buffer_h_time_1( to_integer
			-- 						  ( unsigned(hit_wr_cnt_1) ) );						        --third pulse-feature Slink word				

			-- 		end if;

			-- 		if prsc_cnt /= 0 then								--|					    			--if it is NO FRAME EVENT
			-- 															--|
			-- 			if cf_is_written='0' then						--|									--se è impostato che non tutte le hit del 1 algoritmo sono state scritte
			-- 				if hit_wr_cnt=hit_cnt then					--|									--ma le hit scritte dopo aver aggiunto l'ultima sono uguali al numero di hit da scrivere
			-- 															--|
			-- 					if sec_alg_is_on='1' then				--|									--e se il secondo algoritmo è pronto a partire
			-- 					    cf_is_written<='1';					--|									--allora il 1 algoritmo ha scritto tutto e lo segno
			-- 					    wd_counter<=3;						--|									--riassegno wd_counter per ripetere tutto questo Stato (st_write_ana) per il 2 algoritmo
			-- 					else									--|
			-- 					    prsc_cnt <= prsc_cnt-1;	  			--|									--update frame-event-prescaler
			-- 					    buffer_state<=no_frame_event;		--|									--START SECOND STATEMACHINE--		
			-- 					    ana_state <= st_sleep;				--|									--CHANGE STATE--	
			-- 					end if;									--| NO, prsc_cnt SEMPRE =0
			-- 				else										--|									--if this is not the last hit of first algo
			-- 					hit_wr_cnt<=hit_wr_cnt+1;				--|
			-- 					cf_is_written<='0';						--|									--first algo is not completely written yet
			-- 					wd_counter<=3;							--|									--write next hit of first algo
			-- 				end if;										--|
			-- 			else											--|									--se TUTTE le hit del 1 algoritmo scritte
			-- 															--|									-----------SECONDO ALGORITMO--------------
			-- 				if hit_wr_cnt_1=hit_cnt_1 then				--|					    			--se TUTTE le hit del 2 algoritmo scritte
			-- 					prsc_cnt <= prsc_cnt-1;	  				--|									--update frame-event-prescaler (da noi 0)
			-- 					buffer_state<=no_frame_event;			--|									--START SECOND STATEMACHINE-- ho finito di scrivere tutte le hit, mi segno la dimensione complessiva (dei dati
			-- 															--|										nella BUFFER_FIFO) e la scrivo nella EVENT_FIFO		
			-- 					ana_state <= st_sleep;					--|									--CHANGE STATE--	
			-- 				else										--|
			-- 					hit_wr_cnt_1<=hit_wr_cnt_1+1;			--|
			-- 					wd_counter<=3;							--|
			-- 				end if;										--|
			-- 			end if;											--|
			-- 		else	--entro qui															        --if it is a FRAME EVENT									

			-- 			wd_counter <= 0;											            --go to "write parameter, frame time" 
							
			-- 		end if;

			-- 	end if;


			-- 	if wd_counter = 0 then 		--AGGIUNGE ALTRE PULSE FEATURES NELLA BUFFER_FIFO			
			-- 		buffer_counter<=buffer_counter+1;
			-- 		if cf_is_written='0' then 														--verifico che il cf non stia scrivendo
			-- 																						--aggiungo pulse features come threshold, frac (frac= dati della configuration memory, arrivano dall'esterno) ecc..
			-- 			buffer_din <= threshold & frac & delay 						                --fourth pulse-feature Slink word (only for frame events)
			-- 							  & buffer_frame_t(to_integer( unsigned(hit_wr_cnt) ) ); --in buffer_frame_t butto dentro constant fraction counter

			-- 			if hit_wr_cnt=hit_cnt then													--le hit scritte dopo aver aggiunto l'ultima sono uguali al numero di hit da scrivere

			-- 				if sec_alg_is_on='1' then		--[DA TOGLIERE 2 algoritmo]				--c'è un fast_register che va ad attivare questo algoritmo
			-- 					cf_is_written<='1';												    --tutte le hits del 1 algoritmo sono state scritte
			-- 					wd_counter<=3;														--Riparto a scrivere col 2 algoritmo
			-- 				else
			-- 					prsc_cnt <= to_integer( unsigned(prescaler_base));--GEN_PRESCALER	--update frame-event-prescaler (da noi è resettata a 0,sempre a 0)
			-- 					buffer_state<=frame_event;									        --START SECOND STATEMACHINE--	--in frame_event scrivo la dimensione dell'evento nella EVENT_FIFO	
			-- 					ana_state <= st_sleep;											    --CHANGE STATE--	
			-- 				end if;

			-- 			else
			-- 				hit_wr_cnt<=hit_wr_cnt+1;												--aggiorno che ho scritto un'altra hit (con tutte le sue pulse features)
			-- 				cf_is_written<='0';														-- quindi non ha ancora finito il 1 algoritmo
			-- 				wd_counter<=3;	    													--scrivo la prossima hit del 1 algoritmo	
			-- 			end if;

			-- 		else --SECONDO ALGORITMO 
			-- 			--nel secondo algoritmo come pulse features aggiungo questo:
			-- 			buffer_din <= "00000000" & "000000" & "00000" 				                --fourth pulse-feature Slink word (only for frame events)
			-- 							  & buffer_frame_t_1(to_integer(unsigned(hit_wr_cnt_1)));   --mi dice quanti blocchi (righe della FIFO) restano da leggere se hit_wr_cnt_1 = hit_cnt_1 altrimenti mi dà zero 


					   
			-- 			if hit_wr_cnt_1=hit_cnt_1 then										        --se TUTTE le hit del secondo algoritmo sono state scritte
			-- 				prsc_cnt <=to_integer( unsigned(prescaler_base));--GEN_PRESCALER;	    --reset prescaler, già a 0 da noi
			-- 				buffer_state<=frame_event;											    --START SECOND STATEMACHINE--	vai a scrivere nella EVENT_FIFO la dimensione dell'evento	
			-- 				ana_state <= st_sleep;												    --CHANGE STATE--	
			-- 			else
			-- 				hit_wr_cnt_1<=hit_wr_cnt_1+1;											--hai scritto un'altra hit
			-- 				wd_counter<=3;															--preparazione a scrivere la prossima hit
			-- 			end if;

			-- 		end if;
					

			-- 	end if;
                
				
			when others =>
				dbg_state <= x"6";
				ana_state <= st_sleep;													--CHANGE STATE--


			end case;



		--NEW: non serve più utilizzare le EVENT_FIFO



		
		-- case(buffer_state) is --VISTA LA PARTE SOPRA EVITATA, ENTRO SEMPRE E SOLO IN FRAME_EVENT

		-- 	when no_hit_no_frame_event => --MAI

		-- 		event_data<= std_logic_vector(to_unsigned(0,31));                                   --write size of event to event FIFO
		-- 		wr_event_ff		<= '1';
		-- 		buffer_state <=sleep;

	
		-- 	when no_frame_event => --MAI
				
		-- 		if (buffer_emp = '0') then														    --if buffer FIFO is not empty ... PERCHE'????
		-- 		    wr_event_ff		<= '1';				    
        --             rd_buffer_ff    <= '1';
		-- 		    event_data      <= '0' & std_logic_vector(to_unsigned(buffer_counter,30));      --write size of event to event FIFO


		-- 		    buffer_state    <=unbuffer;												        --CHANGE STATE--

		-- 		end if;

				
		-- 	when frame_event => --SEMPRE

		-- 		--NEW:buffer_counter <= buffer_counter + to_integer(unsigned(framewidth)); --mi segno quanto ho scritto complessivamente
		-- 		if (buffer_emp = '0') then	--se BUFFER_FIFO non è vuota (ha dati pronti da essere letti)	   --if buffer FIFO is not empty ... PERCHE'????
		-- 		    wr_event_ff		<= '1';
		-- 		    rd_buffer_ff    <= '1';
		-- 		    event_data      <= '1' & std_logic_vector(to_unsigned(buffer_counter 
        --                             + to_integer(unsigned(framewidth)),30));                        --write size of event to event FIFO
		-- 			--perchè sommo nuovamente framewidth? Perchè essendo buffer_counter un segnale IN UN PROCESSO CON CLOCK, si aggiorna al clock successivo, quindi in realtà 6 righe sopra non ha ancora aggiornato il segnale

		-- 		    buffer_state    <=unbuffer;														--CHANGE STATE--

		-- 		end if;


		-- 	when unbuffer => --SEMPRE MA DOPO frame_event
		-- 		--SCRIVO LA EVENT_FIFO CON I DATI RACCOLTI NELLA BUFFER_FIFO (riga sotto)
		-- 		event_data<=buffer_dout;	--scrive 1 RIGA (blocco) nella EVENT_FIFO												(--write SLINK conform event data from buffer FIFO to event FIFO)												
		-- 		if buffer_counter = 1 then															--non ci sono altre righe da scrivere mi fermo
		-- 		    buffer_state    <=sleep;												--CHANGE STATE--
		-- 		    rd_buffer_ff    <='0';
		-- 		else 																				--se ci sono altre righe da scrivere ripeto
		-- 		    buffer_counter<=buffer_counter-1;
		-- 		end if;

		-- 	when sleep => --SEMPRE MA DOPO unbuffer
	
		-- 		wr_event_ff<='0';
			
		-- 	end case;

	end if;
		
end process;

 
--NEW:fraction 	<= to_integer(unsigned(frac));
--NEW: delay_i		<= to_integer(unsigned(delay));

--NEW: Non serve più il constant fraction perchè non calcolo più le pulse features (fino a riga 1375)

-- ana_cf : PROCESS(clk)

-- 	variable post_calc1: unsigned (12 downto 0);
-- 	variable post_calc2: unsigned (12 downto 0);
-- 	variable pre_baseline: STD_LOGIC_VECTOR(12 downto 0) ;

-- 	BEGIN
	
-- 		if (clk'event AND clk='1') then
			
-- 			if ana_state = st_sleep then													--do two word per cycle
-- 				del_cnt	<= "00" & (delay(4 downto 1)+delay(0) )+"01010";		--wait   +10		

-- 				pre_baseline :='0' & zero(fraction downto 0) & basel(10 downto fraction);
-- 				cal_basel <= signed(basel) - signed(pre_baseline);

-- 				hit_cnt <= "0000";
				
-- 				del_data(0)<= basel;
-- 				del_data(0)<= basel;
-- 				for i in 0 to 14 loop
-- 				    del_data(i)		<= basel;
-- 				end loop;
-- 				pre_cf_0(0) <= signed(zero(fraction downto 0)) & signed(basel(11 downto fraction));
-- 				pre_cf_1(0) <= signed(basel);
-- 				pre_cf_0(1) <= signed(zero(fraction downto 0)) & signed(basel(11 downto fraction));
-- 				pre_cf_1(1) <= signed(basel);
-- 				pre_cf_del(0)<=signed(zero(fraction downto 0)) & signed(basel(11 downto fraction))-signed(basel);						
-- 				pre_cf_del(1)<=signed(zero(fraction downto 0)) & signed(basel(11 downto fraction))-signed(basel);
-- 				cf_data(0)<=(others =>'0');					
-- 				cf_data(1)<=(others =>'0');	
-- 				for i in 0 to 8 loop
-- 				    cf_data(i+2)<=(others =>'0');
-- 				    cf_data(i+3)<=(others =>'0');
-- 				end loop;
-- 				cf_data(12)<=(others =>'0');

-- 				frame_t<=x"000";
-- 				cf_counter<="00000000000";

-- 				wait_calc_basel<=8;
-- 				pre_calc_basel(0)<="0000000000000000";
-- 				pre_calc_basel(1)<="0000000000000000";
				
-- 			end if;
			
-- 			if ana_state = st_read_frame  then
				
-- 				if del_cnt /= 0 then	--wait for valid delay data
-- 					del_cnt <= del_cnt-1;
-- 				else --quando uguale a 0
-- 					cf_active	<= '1'; --attivi cf
-- 				end if;
				
-- 				del_data(0)				<=('0' & frame_data(11 downto 0));-- '1' & x"000";  --un canale perchè veniva separato il segnale a 12bit (DDR) in 24 bit (SDR) (frame_data) 2 parole ad invio in frame_data
-- 				del_data(1)				<=('0' & frame_data(23 downto 12));--'1' & x"000";  -- 	
-- 				--del_data(0)				<='1' & x"000"; 	
-- 				--del_data(1)				<='1' & x"000";	

-- 				wait_cf_calc<=9;		--wait 11 -2 safety
				

-- 				--Lavora con 8 campioni alla votla ma è giusto così perchè questa rappresenta la finestra di lavoro in cui 8 rappresenta la dimensione ottimale.
-- 				if wait_calc_basel/=0 then                                                                              -- Calcolo della baseline su 8 campionamenti
--                                                                                                                         -- media degli 8 campioni ilm (8 + 8)/8
-- 					wait_calc_basel<=wait_calc_basel-1;
					
-- 					if wait_calc_basel=8 then
-- 					    pre_calc_basel(0)<="0000"&frame_data(11 downto 0);                                              -- carica primo campione ch 0
-- 					    pre_calc_basel(1)<="0000"&frame_data(23 downto 12);                                             -- carica primo campione ch 1
-- 					else
-- 					    pre_calc_basel(0)<=pre_calc_basel(0)+frame_data(11 downto 0);                                   -- somma campioni ch 0
-- 					    pre_calc_basel(1)<=pre_calc_basel(1)+frame_data(23 downto 12);                                  -- somma campioni ch 1
-- 					end if;
				
-- 				else
-- 					calc_basel<=('0' & pre_calc_basel(0)(14 downto 4))+('0' & pre_calc_basel(1)(14 downto 4));          -- somma i 16 campioni e li divide per 16 
-- 				end if;
				


-- 			else
-- 				if wait_cf_calc /=0 then
-- 				wait_cf_calc<=wait_cf_calc-1;
-- 				else
-- 				cf_active	<= '0';
-- 				end if;

-- 			end if;

-- 			for i in 0 to 14 loop --delay 16 words deep --shift register 
-- 				del_data(i*2+2)		<= del_data(i*2); --Sposto in una volta sola tutti i dati facendoli scorrere
-- 				del_data(i*2+3)		<= del_data(i*2+1);						
-- 			end loop;	


-- 			if ana_state /= st_sleep then

-- 			    pre_cf_0(0) <= signed(zero(fraction downto 0)) & signed(del_data(0)(11 downto fraction));
-- 			    pre_cf_1(0) <= signed(del_data(delay_i));
-- 			    pre_cf_0(1) <= signed(zero(fraction downto 0)) & signed(del_data(1)(11 downto fraction));
-- 			    pre_cf_1(1) <= signed(del_data(delay_i+1));
-- 			    pre_keep_prec(0) <= del_data(0)(fraction downto 0) & zero(3-fraction downto 0);
-- 			    pre_keep_prec(1) <= del_data(1)(fraction downto 0) & zero(3-fraction downto 0);

-- 			    pre_cf_del(0)<=pre_cf_0(0)-pre_cf_1(0);						
-- 			    pre_cf_del(1)<=pre_cf_0(1)-pre_cf_1(1);
-- 			    --pre_cf_del(0)<=pre_cf_1(0);							
-- 			    --pre_cf_del(1)<=pre_cf_1(1);
-- 			    pre_keep_prec_del(0) <= pre_keep_prec(0)(3 downto 1);
-- 			    pre_keep_prec_del(1) <= pre_keep_prec(1)(3 downto 1);		
                
-- 			    cf_data(0)<=pre_cf_del(0)+ cal_basel;			--baseline + differenza tra i due dati a 12bit dei due canali (più o meno)		
-- 			    cf_data(1)<=pre_cf_del(1)+ cal_basel;	
-- 			    keep_prec(0) <= pre_keep_prec_del(0);
-- 			    keep_prec(1) <= pre_keep_prec_del(1);

-- 			    for i in 0 to 7 loop
-- 			        keep_prec(i+2)<=keep_prec(i);
-- 			    end loop;
			
-- 			    for i in 0 to 9 loop
-- 			        cf_data(i+2)<=cf_data(i);
-- 			    end loop;
-- 			    cf_data(12)<=cf_data(11);
                
                
                
-- 			    --cf_crit(1)<=cf_data(8);
-- 			    --cf_crit(2)<=cf_data(9);	
-- 			    --cf_crit(1)<=cf_data(0);
-- 			    --cf_crit(2)<=cf_data(1);	
-- 			    cf_crit(1)<=cf_data(6+before_ZC)-cf_data(5-after_ZC);
-- 			    cf_crit(2)<=cf_data(7+before_ZC)-cf_data(6-after_ZC);	

			
			
-- 			end if;


-- 			if cf_active = '1' then --check only in valid cf data for zero crossing

-- 				cf_counter<=cf_counter+'1'; --1
				
-- 				if ((cf_data(8) >= 0) and (cf_data(7) < 0) and cf_crit(1)>signed(threshold))  then --verifico di aver oltrepassato lo zero tra il bit 8 e il 7
-- 					frame_t 	<= (cf_counter  & '0') + "01";  --2
-- 					post_calc1 :=unsigned(abs(cf_data(8)));
-- 					post_calc2 :=unsigned(abs(cf_data(7)));
-- 					last_pos 	<= std_logic_vector(post_calc1(11 downto 0)) & keep_prec(8);
-- 					first_neg 	<= std_logic_vector(post_calc2(11 downto 0)) & keep_prec(7);
				
-- 					cf_hit(1)<='1';	

-- 					if frame_t > ((cf_counter  & '0') - "101") then --segno l'hit solo quando frame_t è minore di cf_counter x 2 - 5
-- 						hit_cnt <= hit_cnt;
-- 					else
-- 						hit_cnt <= hit_cnt+1;
-- 					end if;
				
-- 				else
-- 					cf_hit(1)<='0';	
-- 				end if;
				
-- 				if ((cf_data(9) >= 0) and (cf_data(8) < 0 ) and cf_crit(2)>signed(threshold))    then   --verifico di aver oltrepassato lo zero tra il bit 9 e il 8
-- 					frame_t 	<= ( cf_counter & '0') + "00";	
-- 					post_calc1 :=unsigned(abs(cf_data(9)));
-- 					post_calc2 :=unsigned(abs(cf_data(8)));		
-- 					last_pos 	<= std_logic_vector(post_calc1(11 downto 0))& keep_prec(9);
-- 					first_neg 	<= std_logic_vector(post_calc2(11 downto 0))& keep_prec(8);
-- 					cf_hit(2)<='1';	
				
-- 					if frame_t > ( (cf_counter  & '0') - "110") then --stessa cosa di sopra... solo che non somma +1 sopra in frame_t ma sottrae 1 in più da cf_counter
-- 						hit_cnt <= hit_cnt;
-- 					else
-- 						hit_cnt <= hit_cnt+1;
-- 					end if;
				
-- 				else
-- 					cf_hit(2)<='0';	
-- 				end if;
-- 			end if;
-- 				--last_pos<="000000000000000";
-- 				--first_neg<=first_neg+'1';
		
		
-- 		end if;	
-- end process;

-- getpreAmp : process (clk)																---- chooses 4 candidates for the MaxAmp

-- begin

-- if (clk'event and clk = '1') then

-- 		for i in 0 to 8 loop 															--	buffer the right del_data
-- 																								--	
-- 			Amp_buffer(i)<=del_data(delay_i+10+i-cf_max_dist)(11 downto 0);	--	
-- 																								--	
-- 		end loop;


-- 		if (cf_hit(1)='1' ) then	
		
-- 			if Amp_buffer(0) > Amp_buffer(1) then
-- 				Amp(0)<=Amp_buffer(0);
-- 			else
-- 				Amp(0)<=Amp_buffer(1);
-- 			end if;

-- 			if Amp_buffer(2) > Amp_buffer(3) then
-- 				Amp(1)<=Amp_buffer(2);
-- 			else
-- 				Amp(1)<=Amp_buffer(3);
-- 			end if;			
	
-- 			if Amp_buffer(4) > Amp_buffer(5) then
-- 				Amp(2)<=Amp_buffer(4);
-- 			else
-- 				Amp(2)<=Amp_buffer(5);
-- 			end if;
	
-- 			if Amp_buffer(6) > Amp_buffer(7) then
-- 				Amp(3)<=Amp_buffer(6);
-- 			else
-- 				Amp(3)<=Amp_buffer(7);
-- 			end if;
			
-- 			post_cf_hit(1)<='1';
		
-- 		else
-- 			post_cf_hit(1)<='0';
-- 		end if;

-- 		if (cf_hit(2)='1' ) then	
	
-- 			if Amp_buffer(1) > Amp_buffer(2) then
-- 				Amp(0)<=Amp_buffer(1);
-- 			else
-- 				Amp(0)<=Amp_buffer(2);
-- 			end if;

-- 			if Amp_buffer(3) > Amp_buffer(4) then
-- 				Amp(1)<=Amp_buffer(3);
-- 			else
-- 				Amp(1)<=Amp_buffer(4);
-- 			end if;			
	
-- 			if Amp_buffer(5) > Amp_buffer(6) then
-- 				Amp(2)<=Amp_buffer(5);
-- 			else
-- 				Amp(2)<=Amp_buffer(6);
-- 			end if;
	
-- 			if Amp_buffer(7) > Amp_buffer(8) then
-- 				Amp(3)<=Amp_buffer(7);
-- 			else
-- 				Amp(3)<=Amp_buffer(8);
-- 			end if;
	
-- 			post_cf_hit(2)<='1';
	
-- 		else
-- 			post_cf_hit(2)<='0';
-- 		end if;


-- end if;

-- end process;


-- getAmp : process (clk)																	---- chooses MaxAmp

-- begin

-- if (clk'event and clk = '1') then

-- 	if (post_cf_hit(2)='1' or post_cf_hit(1)='1') then
	

-- 		for i in 0 to 1 loop 
		
-- 			if (Amp(2*i)>Amp(2*i+1)) then 										
				
-- 				preAmp(i)<=Amp(2*i);														-- find biggest value of Amp(0) and Amp(1) => preAmp(0)
-- 																								-- as well as Amp(2) and Amp(3) => preAmp(1)
-- 			else
				
-- 				preAmp(i)<=Amp(2*i+1);													
				
-- 			end if;

-- 		end loop;

-- 		preAmp_set<='1';																	-- remember that preAmp was found			

-- 	else
		
-- 		preAmp_set<='0';
		
-- 	end if;


-- 	if(preAmp_set='1') then
		
-- 		MaxAmp_set  <= '1';    
		
-- 		if (preAmp(0)>preAmp(1)) then 												-- choose biggest value of preAmp(0) and preAmp(1)
-- 																								-- => MaxAmp with baseline
-- 			MaxAmp<=preAmp(0);
		
-- 		else
		
-- 			MaxAmp<=preAmp(1);
		
-- 		end if;
	
-- 	else
		
-- 		MaxAmp_set  <= '0';  
	
-- 	end if;


-- end if;

-- end process;

-- --------


-- ana_cf_1 : PROCESS(clk)

-- 	variable post_calc1: unsigned (12 downto 0);
-- 	variable post_calc2: unsigned (12 downto 0);
-- 	variable pre_baseline: STD_LOGIC_VECTOR(12 downto 0) ;

-- 	BEGIN
	
-- 		if (clk'event AND clk='1') then


-- 			if ana_state = st_sleep then
-- 			hit_cnt_1<="0000";
-- 			end if;
			

-- 			if ana_state = st_read_frame  then
				

-- 				pre_cf_1_0(0) <= signed(del_data(0));
-- 				pre_cf_1_1(0) <= signed(del_data(1));
-- 				pre_cf_1_0(1) <= signed(del_data(1));
-- 				pre_cf_1_1(1) <= signed(del_data(2));
	
				
-- 			end if;
		
		
-- 			if cf_active = '1' then --check only in valid cf data for zero crossing

-- 				pre_cf_1_del(0)<=pre_cf_1_0(0)-pre_cf_1_1(0);								
-- 				pre_cf_1_del(1)<=pre_cf_1_0(1)-pre_cf_1_1(1);
	
-- 				pre_cf_1_del_del(0)<=pre_cf_1_del(0);					
-- 				pre_cf_1_del_del(1)<=pre_cf_1_del(1);	

-- 				cf_1_data(0)<=pre_cf_1_del_del(0);										
-- 				cf_1_data(1)<=pre_cf_1_del_del(1);

-- 				cf_1_crit(1)<=pre_cf_1_del(1)-pre_cf_1_del(0);					
-- 				cf_1_crit(2)<=pre_cf_1_del_del(0)-signed(threshold);	
				
-- 				cf_1_crit_del(1)<=cf_1_crit(1)-signed(threshold);
-- 				cf_1_crit_del(2)<=cf_1_crit(2)-pre_cf_1_del_del(1);	
				
-- 				cf_1_data(2)	<= cf_1_data(0);	
								
					
-- 				if ((cf_1_data(1) > ("0000000000000")) and (cf_1_data(0) < ("0000000000000"))) and cf_1_crit_del(1)>0  then 
-- 				--frame_t_1 blocchi restanti da leggere??
-- 				frame_t_1 	<= ((framewidth - fr_counter ) & '0') + "01";  	--framewidth=128, numero blocchi da leggere dalla FRAME_FIFO, fr_counter è il numero di blocchi attualmente letti.
-- 				post_calc1 :=unsigned(abs(cf_data(1)));
-- 				post_calc2 :=unsigned(abs(cf_data(0)));
-- 				last_pos_1 	<= std_logic_vector(post_calc1(11 downto 0));
-- 				first_neg_1 	<= std_logic_vector(post_calc2(11 downto 0)) ;
-- 				hit_cnt_1 <= hit_cnt_1+1;
-- 				cf_1_hit(1)<='1';	
				
-- 				else
-- 				cf_1_hit(1)<='0';	
-- 				end if;
				
-- 				if ((cf_1_data(2) > ("0000000000000")) and (cf_1_data(1) < "0000000000000" )) and cf_1_crit_del(2)>0   then   
-- 				frame_t_1 	<= ((framewidth - fr_counter ) & '0') + "00";	
-- 				post_calc1 :=unsigned(abs(cf_data(2)));
-- 				post_calc2 :=unsigned(abs(cf_data(1)));		
-- 				last_pos_1 	<= std_logic_vector(post_calc1(11 downto 0));
-- 				first_neg_1 	<= std_logic_vector(post_calc2(11 downto 0));
-- 				hit_cnt_1 <= hit_cnt_1+1;
-- 				cf_1_hit(2)<='1';	
				
-- 				else
-- 				cf_1_hit(2)<='0';	
-- 				end if;


-- 			end if;
-- 		end if;	
-- end process;

-- getpreAmp_1 : process (clk)																---- chooses 4 candidates for the MaxAmp

-- begin

-- if (clk'event and clk = '1') then

-- 		for i in 0 to 6 loop 															--	buffer the right del_data
-- 																								--	up to del_data( 12(max. delay) +10 -1(max. dist) )
-- 			Amp_1_buffer(i)<=del_data(1+4+i-cf_max_dist_1)(11 downto 0);	--	10 choosen because of: (5 cycles until cf_data(2) )
-- 																								--	*2 samples per cycle => 10
-- 		end loop;


-- 		for i in 2 to 3 loop 															-- loop over all possible hits within one cycle														

-- 			if (cf_1_hit(i-1)='1' ) then													

-- 				for j in 0 to 3 loop 

-- 					Amp_1(j)<=Amp_1_buffer(j+i);											-- save 4 Amp canidates
-- 																								--hit eralier => i bigger => more buffer needed
-- 				end loop;

-- 				post_cf_1_hit(i-1)<='1';													-- delay the hit					
		
-- 			else

-- 				post_cf_1_hit(i-1)<='0';													-- delay the hit

-- 			end if;

-- 		end loop;


-- end if;

-- end process;

-- getAmp_1 : process (clk)																	---- chooses MaxAmp

-- begin

-- if (clk'event and clk = '1') then

-- 	if (post_cf_1_hit(2)='1' or post_cf_1_hit(1)='1') then
	

-- 		for i in 0 to 1 loop 
		
-- 			if (Amp_1(2*i)>Amp_1(2*i+1)) then 										
				
-- 				preAmp_1(i)<=Amp_1(2*i);														-- find biggest value of Amp(0) and Amp(1) => preAmp(0)
-- 																								-- as well as Amp(2) and Amp(3) => preAmp(1)
-- 			else
				
-- 				preAmp_1(i)<=Amp_1(2*i+1);													
				
-- 			end if;

-- 		end loop;

-- 		preAmp_1_set<='1';																	-- remember that preAmp was found			

-- 	else
		
-- 		preAmp_1_set<='0';
		
-- 	end if;


-- 	if(preAmp_1_set='1') then
		
-- 		MaxAmp_1_set  <= '1';    
		
-- 		if (preAmp(0)>preAmp(1)) then 												-- choose biggest value of preAmp(0) and preAmp(1)
-- 																								-- => MaxAmp with baseline
-- 			MaxAmp_1<=preAmp_1(0);
		
-- 		else
		
-- 			MaxAmp_1<=preAmp_1(1);
		
-- 		end if;
	
-- 	else
		
-- 		MaxAmp_1_set  <= '0';  
	
-- 	end if;


-- end if;

-- end process;


-- prep_output : process (clk)															

-- variable cnt : integer range 0 to 15;
-- variable cnt_1 : integer range 0 to 15;

-- begin

-- 	if (clk'event and clk = '1') then


-- 		cnt:=to_integer(unsigned(hit_cnt)); 		--hit_cnt mi indica il numero di hit totali nel 1 algoritmo
-- 		buffer_frame_t(cnt)<=frame_t; 				--in buffer_frame_t all'indice pari al "numeri di hit totali" salvo frame_t
-- 													--frame_t:



		
-- 		cnt_1:=to_integer(unsigned(hit_cnt_1));--hit_cnt_1 mi indica quante hit totali ci sono nel secondo algoritmo
-- 		buffer_frame_t_1(cnt_1)<=frame_t_1; --in buffer... (la prima volta=) alla posizione finale di buffer... (pari al numero di hit totali) salvo quanti blocchi restano da leggere dalla FRAME_FIFO


-- 		h_res_ready(0)<=MaxAmp_set;
-- 		for i in 0 to 4 loop
-- 			h_res_ready(i+1)<=h_res_ready(i);											
-- 		end loop;

-- 		h_res_1_ready(0)<=MaxAmp_1_set;
-- 		for i in 0 to 2 loop
-- 			h_res_1_ready(i+1)<=h_res_1_ready(i);											
-- 		end loop;


-- 		if ana_state=st_sleep then

-- 			h_res_cnt <="0000";
-- 			Max_Amp_cnt<="0000";
			
-- 			h_res_1_cnt <="0000";
-- 			Max_Amp_1_cnt<="0000";

-- 		elsif cf_active='1' or ana_state=st_rd_coarse_t or ana_state=st_wait_ana then

-- 			if h_res_ready(5)='1' then
				
-- 				if h_res_cnt/=hit_cnt then
-- 				h_res_cnt<=h_res_cnt+1;
-- 				buffer_h_time(to_integer(unsigned(h_res_cnt+1)))<=h_res_t;			
-- 				else
-- 				buffer_h_time(to_integer(unsigned(h_res_cnt)))<=h_res_t;
-- 				end if;
			
-- 			end if;

-- 			if MaxAmp_set='1' then
				
-- 				if Max_Amp_cnt/=hit_cnt then
-- 				Max_Amp_cnt<=Max_Amp_cnt+1;
-- 				buffer_MaxAmp(to_integer(unsigned(Max_Amp_cnt+1)))<=MaxAmp-basel(10 downto 0) ;	
-- 				else
-- 				buffer_MaxAmp(to_integer(unsigned(Max_Amp_cnt)))<=MaxAmp-basel(10 downto 0) ;		
-- 				end if;
			
-- 			end if;

-- 			if h_res_1_ready(3)='1' then
-- 				h_res_1_cnt<=h_res_1_cnt+1;
-- 				buffer_h_time_1(to_integer(unsigned(h_res_1_cnt+1)))<=h_res_t_1;
-- 			end if;

-- 			if MaxAmp_1_set='1' then
-- 				Max_Amp_1_cnt<=Max_Amp_1_cnt+1;
-- 				buffer_MaxAmp_1(to_integer(unsigned(Max_Amp_1_cnt+1)))<=MaxAmp_1-basel(10 downto 0);	
-- 			end if;



-- 		end if;


-- 	end if;

-- end process;


-- --	inst_divisor_1: divisor PORT MAP(  --calculates highres time & adds correction factor by Philipp Joerg
-- --		DATA_0_i => last_pos_1,
-- --		DATA_1_i => first_neg_1,
-- --		clk => clk,
-- --		RESULT => h_res_t_1
-- --	);

-- -- disabilito i divider per recuperare BRAM BLOCK
-- h_res_t_1 <= (others => '1');
-- ----------


-- --	inst_divisor: divisor_15 PORT MAP(  --calculates highres time & adds correction factor by Philipp Joerg
-- --		DATA_0_i => last_pos,
-- --		DATA_1_i => first_neg,
-- --		clk => clk,
-- --		RESULT => h_res_t
-- --	);

-- -- disabilito i divider per recuperare BRAM BLOCK
-- h_res_t <= (others => '1');

	
 
-- ana_int : PROCESS(clk)
-- 	variable basel_sub : std_logic_vector(10 downto 0);
-- 	BEGIN
	
-- 		if (clk'event AND clk='1') then
			
-- 			if ana_state = st_sleep then
-- 				presum		<= (others => '0');
-- 				integral 	<= (others => '0');
-- 				preamp0		<= (others => '0');
-- 				preamp1		<= (others => '0');
-- 				amplitude	<= (others => '0');
-- 			end if;
			
-- 			if ana_state = st_read_frame then
			
-- 				start_int <='1';
-- 				--pre integral
-- 				basel_sub	:= (basel(10 downto 0) - threshold);
-- 				presum 		<= frame_data(23 downto 12) +  frame_data(11 downto 0) - (basel_sub(9 downto 0) & '0'); --two frame words, substract two baselines  --ERRORE! RISCHIO OVERFLOW! presum serve 1 bit in più
-- 				--i frame_data li leggo tutti senza problemi perchè se st_read_frame carica nuovi frame_data, al colpi di clock successivo lui li scrive e
-- 				--questa parte li legge per elaborarli. Solo all'iterazione ancora dopo cambia stato e qui non entra più come giusto che sia.

-- 				--max amplitude
-- 				if frame_data(11 downto 0) > preamp0 then
-- 				 preamp0 <= frame_data(11 downto 0);
-- 				end if;
-- 				if frame_data(23 downto 12) > preamp1 then
-- 				 preamp1 <= frame_data(23 downto 12);
-- 				end if;
								
-- 			else
-- 				start_int <='0';
-- 				presum		<= (others => '0');		
-- 			end if;	
			
-- 			if start_int = '1' then
-- 				integral 	<= integral + presum;	
				
-- 				if preamp0 <= preamp1 then
-- 				amplitude<=	preamp1 - basel(10 downto 0);
-- 				else
-- 				amplitude<=	preamp0 - basel(10 downto 0);
-- 				end if;
					
-- 			end if;
		 
		
-- 		end if;
		
-- 	end process;
		
		--NEW: non serve più

	--    event_fifo_inst : FIFO_DUALCLOCK_MACRO
	-- 	   generic map (
	-- 	      DEVICE => "VIRTEX5",            -- Target Device: "VIRTEX5", "VIRTEX6" 
	-- 	      ALMOST_FULL_OFFSET => X"0080",  -- Sets almost full threshold
	-- 	      ALMOST_EMPTY_OFFSET => X"0080", -- Sets the almost empty threshold
	-- 	      DATA_WIDTH => 31,   -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
	-- 	      FIFO_SIZE => "18Kb",            -- Target BRAM, "18Kb" or "36Kb" -- era 36Kb
	-- 	      FIRST_WORD_FALL_THROUGH => TRUE, -- Sets the FIFO FWFT to TRUE or FALSE
	-- 	      SIM_MODE => "FAST") -- Simulation "SAFE" vs "FAST",                               -- era SAFE
	-- 	                          -- see "Synthesis and Simulation Design Guide" for details
	-- 	   port map (
	-- 	      ALMOSTEMPTY => open,   		-- Output almost empty 
	-- 	      ALMOSTFULL => open,     		-- Output almost full
	-- 	      DO => event_data_out,       -- Output data
	-- 	      EMPTY => event_ff_empty,  -- Output empty
	-- 	      FULL => event_ff_full,                 -- Output full
	-- 	      RDCOUNT => rd_fifo_cnt, 			-- Output read count
	-- 	      RDERR => open,      			-- Output read error
	-- 	      WRCOUNT => wr_fifo_cnt,         -- Output write count
	-- 	      WRERR => open,               	-- Output write error
	-- 	      DI => event_data,      -- Input data
	-- 	      RDCLK => event_ff_clk,            -- Input read clock
	-- 	      RDEN => rd_event_ff,    -- Input read enable
	-- 	      RST => RESET,                 -- Input reset
	-- 	      WRCLK => clk,               	-- Input write clock
	-- 	      WREN => wr_event_ff           -- Input write enable
	-- 	   );

	   frame_buffer_fifo_inst : FIFO_DUALCLOCK_MACRO
		   generic map (
		      DEVICE => "VIRTEX5",            -- Target Device: "VIRTEX5", "VIRTEX6" 
		      ALMOST_FULL_OFFSET => X"0080",  -- Sets almost full threshold
		      ALMOST_EMPTY_OFFSET => X"0080", -- Sets the almost empty threshold
		      DATA_WIDTH => 31,   -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
		      FIFO_SIZE => "18Kb",            -- Target BRAM, "18Kb" or "36Kb" -- era 36Kb 
		      FIRST_WORD_FALL_THROUGH => TRUE, -- Sets the FIFO FWFT to TRUE or FALSE
		      SIM_MODE => "FAST") -- Simulation "SAFE" vs "FAST",                                -- era SAFE
		                          -- see "Synthesis and Simulation Design Guide" for details
		   port map (
		      ALMOSTEMPTY => open,   		-- Output almost empty 
		      ALMOSTFULL => open,     		-- Output almost full
		      DO => buffer_dout,       -- Output data
		      EMPTY => buffer_emp,  -- Output empty
		      FULL => frame_fifo_full,                 -- Output full
		      RDCOUNT => rd_buffer_fifo_cnt, 			-- Output read count
		      RDERR => open,      			-- Output read error
		      WRCOUNT => wr_buffer_fifo_cnt,         -- Output write count
		      WRERR => open,               	-- Output write error
		      DI => buffer_din,      -- Input data
		      RDCLK => clk,            -- Input read clock
		      RDEN => rd_buffer_ff,    -- Input read enable
		      RST => RESET,                 -- Input reset
		      WRCLK => clk,               	-- Input write clock
		      WREN => wr_buffer_ff           -- Input write enable
		   );
		   			



end Behavioral;