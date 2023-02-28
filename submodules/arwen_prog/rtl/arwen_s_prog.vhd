-------------------------------------------------------------------------------
-- Company:         INFN-LNF
-- Engineer:        alessandro.balla@lnf.infn.it
-- 
-- Create Date:     11:43:03 05/24/2021 
-- Design Name: 
-- Module Name:     arwen_s_prog 
-- Project Name:    GANDARW
-- Target Devices:  XC5VSX95T-2FF1136
-- Tool versions:   ISE 14.7
-- Description:     arwen programming module 
--                  new version (getting the data over mem fpga)
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 -  File Created
-- More Comments:   Modified version of arwen_prog.vhd  
--                  of <grussy@pcfr16.physik.uni-freiburg.de>
--                  but for one board only
------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
library UNISIM;
use UNISIM.vcomponents.all;
library UNIMACRO;
use UNIMACRO.vcomponents.all;

use WORK.G_PARAMETERS.all;
-------------------------------------------------------------------------------

entity arwen_s_prog is
	port (
        control             : inout std_logic_vector(35 downto 0);
		clk					: in	std_logic;
		rst					: in	std_logic;
--		fastreg_card_select : in	std_logic_vector(1 downto 0);
		fastreg_prog		: in	std_logic;

-------------------------------------------------------------------------------
-- binfile request and fifo out
		start_reading	   : out std_logic;
		start_addr		   : out std_logic_vector(28 downto 0);
		end_addr		   : out std_logic_vector(28 downto 0);
		binfile_fifo_data  : in	 std_logic_vector(33 downto 0);
		binfile_fifo_empty : in	 std_logic;
		binfile_fifo_valid : in	 std_logic;
		binfile_fifo_ren   : out std_logic;
-------------------------------------------------------------------------------			

-------------------------------------------------------------------------------
-- wb to configmem
		wb_cyc	 : out std_logic;
		wb_stb	 : out std_logic;
		wb_we	 : out std_logic_vector(3 downto 0);
		wb_adr	 : out std_logic_vector(9 downto 0);
		wb_dat_o : out std_logic_vector(31 downto 0);
		wb_dat_i : in  std_logic_vector(31 downto 0);
		wb_ack	 : in  std_logic;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- Programming lanes from toplevel
-- single : da trasformare in std_logic
		ARWEN_PROG_P : out std_logic;
		ARWEN_PROG_N : out std_logic;
		ARWEN_INIT_P : in  std_logic;
		ARWEN_INIT_N : in  std_logic;
		ARWEN_DONE_P : in  std_logic;
		ARWEN_DONE_N : in  std_logic;

		ARWEN_D0_P : out std_logic;
		ARWEN_D0_N : out std_logic;

		ARWEN_CCLK_P : out std_logic;
		ARWEN_CCLK_N : out std_logic
-------------------------------------------------------------------------------		
		);
end entity arwen_s_prog;
architecture behav of arwen_s_prog is

-------------------------------------------------------------------------------
-- constants
	constant cf_initdone_addr : std_logic_vector(9 downto 0) := b"10" & x"a1";
	constant cf_start_addr	  : std_logic_vector(9 downto 0) := b"10" & x"a0";
	constant cf_end_addr	  : std_logic_vector(9 downto 0) := b"10" & x"a2";

	attribute safe_recovery_state : string;
	attribute safe_implementation : string;
------------------------------------------------------------------------------- 

-------------------------------------------------------------------------------
-- arwen lanes
-- single : da trasformare in std_logic
    signal arwen_prog : std_logic;
	signal arwen_init : std_logic;
	signal arwen_done : std_logic;
	signal arwen_cclk : std_logic;
	signal arwen_d0	  : std_logic;
-------------------------------------------------------------------------------
-- chipscope
    component prog_ila
        port (
            control     : inout std_logic_vector(35 downto 0);
            clk         : in    std_logic;
            data        : in    std_logic_vector(63 downto 0);
            trig0       : in    std_logic_vector(17 downto 0)
            );
    end component;

    signal ila_data : std_logic_vector(63 downto 0);
	signal ila_trg	: std_logic_vector(17 downto 0);
 
-------------------------------------------------------------------------------
-- state machine
	type state_type is (
		sleep,
		init,
		wait_for_init_high,
		read_start_addr,
        wait_zero_ack,
		read_end_addr,
		programming,
		wait_one_cycle,
		read_next_word,
		write_init_done
		);
	signal state : state_type := sleep;

	attribute safe_implementation of state : signal is "yes";
	attribute safe_recovery_state of state : signal is "sleep";
------------------------------------------------------------------------------- 

-------------------------------------------------------------------------------
-- counters
	signal cnt_tc  : std_logic;
	signal cnt_rst : std_logic;

	signal counter		: std_logic_vector(8 downto 0);
	signal counter_tc	: std_logic;
	signal counter_en	: std_logic;
	signal counter_rst	: std_logic;
	signal counter_load : std_logic;
------------------------------------------------------------------------------- 

-------------------------------------------------------------------------------
-- programming
	signal prog_data_sr : std_logic_vector(31 downto 0) := (others => '0');
	signal prog			: std_logic						:= '0';

-- single : da eliminare
    -- signal card_select	: std_logic_vector(1 downto 0)	:= "00";

	signal fastreg_prog_sr : std_logic_vector(1 downto 0) := "00";

	signal start_reading_i	: std_logic					   := '0';
	signal start_reading_sr : std_logic_vector(7 downto 0) := (others => '0');

------------------------------------------------------------------------------- 

begin  -- architecture behav

-------------------------------------------------------------------------------
-- static
	start_reading <= start_reading_i; -- or start_reading_sr(7) or start_reading_sr(6) or start_reading_sr(5) or start_reading_sr(4)
                                      -- or start_reading_sr(3) or start_reading_sr(2) or start_reading_sr(1) or start_reading_sr(0);
------------------------------------------------------------------------------- 

-- ila
Inst_chipscope : if USE_CHIPSCOPE_ILA_3 generate

    prog_ila_1 : prog_ila
          port map (
            control     => control,
            clk         => clk,
            data        => ila_data,
            trig0       => ila_trg
            );

        ila_trg(0)  <= fastreg_prog;
        ila_trg(1)  <= arwen_prog;
        ila_trg(2)  <= arwen_init;
        ila_trg(3)  <= arwen_done;
        ila_trg(4)  <= arwen_cclk;
        ila_trg(5)  <= arwen_d0;	
        ila_trg(6)  <= binfile_fifo_data(33);	
        ila_trg(7)  <= binfile_fifo_valid;	
        ila_trg(8)  <= '1' when state = sleep else '0';
        ila_trg(9)  <= '1' when state = init else '0';
        ila_trg(10) <= '1' when state = wait_for_init_high else '0';
        ila_trg(11) <= '1' when state = read_start_addr else '0';
        ila_trg(12) <= '1' when state = wait_zero_ack else '0';
        ila_trg(13) <= '1' when state = read_end_addr else '0';
        ila_trg(14) <= '1' when state = programming else '0';
        ila_trg(15) <= '1' when state = wait_one_cycle else '0';
        ila_trg(16) <= '1' when state = read_next_word else '0';
        ila_trg(17) <= '1' when state = write_init_done else '0';

        ila_data(33 downto 0) <= binfile_fifo_data; 
        ila_data(34) <= binfile_fifo_empty;
        ila_data(35) <= binfile_fifo_valid;
        ila_data(36) <= '0'; -- binfile_fifo_ren;

        ila_data(37) <= '1' when state = sleep else '0';
        ila_data(38) <= '1' when state = init else '0';
        ila_data(39) <= '1' when state = wait_for_init_high else '0';
        ila_data(40) <= '1' when state = read_start_addr else '0';
        ila_data(41) <= '1' when state = wait_zero_ack else '0';
        ila_data(42) <= '1' when state = read_end_addr else '0';
        ila_data(43) <= '1' when state = programming else '0';
        ila_data(44) <= '1' when state = wait_one_cycle else '0';
        ila_data(45) <= '1' when state = read_next_word else '0';
        ila_data(46) <= '1' when state = write_init_done else '0';
        

        ila_data(50) <= fastreg_prog;
        ila_data(51) <= arwen_prog;
        ila_data(52) <= arwen_init;
        ila_data(53) <= arwen_done;
        ila_data(54) <= arwen_cclk;
        ila_data(55) <= arwen_d0;	

    end generate;
    
    
-------------------------------------------------------------------------------
-- clock in the fastregs 
    process
    begin
    	wait until rising_edge(clk);
    	fastreg_prog_sr <= fastreg_prog_sr(0) & fastreg_prog;
    	if fastreg_prog_sr = "01" then
            prog        <= '1';
        else
    		prog        <= '0';
    	end if;
    end process;
------------------------------------------------------------------------------- 

-------------------------------------------------------------------------------
-- state machine
	process(clk,rst)
	begin
		if rst = '1' then
            cnt_rst			        <= '1';
            arwen_prog		        <= '1'; -- era "11"
            wb_cyc			        <= '0';
            wb_stb			        <= '0';
            wb_we			        <= x"0";
            wb_adr			        <= (others => '0');
            wb_dat_o		        <= (others => '0');
            counter_en		        <= '0';
            counter_rst		        <= '0';
            counter_load	        <= '0';
            start_reading_i	        <= '0';
            binfile_fifo_ren        <= '0';
            state                   <= sleep;

        elsif rising_edge(clk) then
		    cnt_rst			        <= '1';
		    arwen_prog		        <= '1'; -- era "11"
		    wb_cyc			        <= '0';
		    wb_stb			        <= '0';
		    wb_we			        <= x"0";
		    wb_adr			        <= (others => '0');
		    wb_dat_o		        <= (others => '0');
		    counter_en		        <= '0';
		    counter_rst		        <= '0';
		    counter_load	        <= '0';
		    start_reading_i	        <= start_reading_i; -- era '0'
		    binfile_fifo_ren        <= '0';
            
            case state is

		        when sleep =>
		        	arwen_cclk      <= '0';
		        	arwen_d0        <= '0';
                    start_reading_i <= '0';

		        	if prog = '1' then
		        		state <= init;
		        	end if;

		        when init =>
		        	cnt_rst	   <= '0';
		        	arwen_prog <= '0'; -- era arwen_prog <= not card_select;
		        	if cnt_tc = '1' then
		        		state <= wait_for_init_high;
		        	end if;

		        when wait_for_init_high =>
                if arwen_init = '1' then -- era : if arwen_init = card_select or arwen_init = "11" then 
		        		state		 <= read_start_addr;
		        		counter_load <= '1';
		        		counter_en	 <= '1';
		        	end if;

		        when read_start_addr =>
		        	if wb_ack = '1' then
                        wb_cyc      <= '0';
                        wb_stb      <= '0';
		        		start_addr  <= wb_dat_i(28 downto 0);
		        		state	    <= wait_zero_ack;
		        		counter_en  <= '1';
		        	else
                        wb_cyc <= '1';
                        wb_stb <= '1';
		        		wb_adr <= cf_start_addr;
		        	end if;

                when wait_zero_ack =>
                    wb_cyc <= '0';
                    wb_stb <= '0';
                    if wb_ack = '0' then
                        state	   <= read_end_addr;
                    end if;

		        when read_end_addr =>
		        	if wb_ack = '1' then
                        wb_cyc          <= '0';
                        wb_stb          <= '0';
		        		state			<= programming;
		        		end_addr		<= wb_dat_i(28 downto 0);
		        		start_reading_i <= '1';
		        	else
		        		wb_cyc <= '1';
		        		wb_stb <= '1';
		        		wb_adr <= cf_end_addr;
		        	end if;

		        when programming =>
		        	if counter(7) = '0' then
		        		counter_en <= '1';
		        		if counter(1 downto 0) = "01" then
		        			arwen_d0	 <= prog_data_sr(31);
		        			prog_data_sr <= prog_data_sr(30 downto 0) & '1';
		        			arwen_cclk	 <= '0';
		        		elsif counter(1 downto 0) = "11" then
		        			arwen_cclk <= '1';
		        		end if;
		        	else
		        		state			 <= wait_one_cycle;
		        		binfile_fifo_ren <= '1';
		        	end if;

		        when wait_one_cycle =>
		        	state <= read_next_word;
                
		        when read_next_word =>
		        	if binfile_fifo_valid = '1' and binfile_fifo_data(33) = '0' then
		        		prog_data_sr <= binfile_fifo_data(32 downto 17) & binfile_fifo_data(15 downto 0);
		        		counter_rst	 <= '1';
		        	elsif binfile_fifo_valid = '1' and binfile_fifo_data(33) = '1' then
		        		state <= write_init_done;
		        	else
		        							-- were reading on empty fifo
		        		state <= programming;
		        	end if;

		        when write_init_done =>
		        	if wb_ack = '1' then
                        wb_cyc          <= '0';
                        wb_stb          <= '0';
		        		state           <= sleep;
		        	else
		        		wb_cyc				 <= '1';
		        		wb_stb				 <= '1';
		        		wb_we				 <= x"F";
		        		wb_adr				 <= cf_initdone_addr;
		        		wb_dat_o(3 downto 0) <= "11" & arwen_init & arwen_done; -- era (3 downto 0)
		        	end if; 

                when others =>
                    state <= sleep;

		    end case;
        end if;
	end process;
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- counter
	init_counter : COUNTER_TC_MACRO
		generic map (
			COUNT_BY	  => X"000000000001",       -- Count by value
			DEVICE		  => "VIRTEX5",	            -- Target Device: "VIRTEX5", "VIRTEX6" 
			DIRECTION	  => "UP",		            -- Counter direction "UP" or "DOWN" 
			RESET_UPON_TC => "FALSE",               -- Reset counter upon terminal count, "TRUE" or "FALSE" 
			TC_VALUE	  => X"000000000064",       -- Terminal count value
			WIDTH_DATA	  => 8)			            -- Counter output bus width, 1-48
		port map (
			Q	=> open,                            -- Counter output, width determined by WIDTH_DATA generic 
			TC	=> cnt_tc,	                        -- 1-bit terminal count output, high = terminal count is reached
			CLK => clk,					            -- 1-bit clock input
			CE	=> '1',					            -- 1-bit clock enable input
			RST => cnt_rst				            -- 1-bit active high synchronous reset
			);

	prog_counter : COUNTER_LOAD_MACRO
		generic map (
			COUNT_BY   => X"000000000001",	        -- Count by value
			DEVICE	   => "VIRTEX5",                -- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6" 
			WIDTH_DATA => 9)			            -- Counter output bus width, 1-48
		port map (
			Q		  => counter,                   -- Counter output, width determined by WIDTH_DATA generic 
			CLK		  => clk,			            -- 1-bit clock input
			CE		  => counter_en,	            -- 1-bit clock enable input
			DIRECTION => '1',                       -- 1-bit up/down count direction input, high is count up
			LOAD	  => counter_load,	            -- 1-bit active high load input
			LOAD_DATA => '0' & x"ff",               -- Counter load data, width determined by WIDTH_DATA generic 
			RST		  => counter_rst	            -- 1-bit active high synchronous reset
			);	
------------------------------------------------------------------------------- 

-------------------------------------------------------------------------------
-- io bufers
-- single : da trasformare in std_logic
	arwen_iobufs_1 : entity work.arwen_s_iobufs
		port map (
			arwen_prog	 => arwen_prog,
			arwen_init	 => arwen_init,
			arwen_done	 => arwen_done,
			arwen_cclk	 => arwen_cclk,
			arwen_d0	 => arwen_d0,
			ARWEN_PROG_P => ARWEN_PROG_P,
			ARWEN_PROG_N => ARWEN_PROG_N,
			ARWEN_INIT_P => ARWEN_INIT_P,
			ARWEN_INIT_N => ARWEN_INIT_N,
			ARWEN_DONE_P => ARWEN_DONE_P,
			ARWEN_DONE_N => ARWEN_DONE_N,
			ARWEN_D0_P	 => ARWEN_D0_P,
			ARWEN_D0_N	 => ARWEN_D0_N,
			ARWEN_CCLK_P => ARWEN_CCLK_P,
			ARWEN_CCLK_N => ARWEN_CCLK_N);
-------------------------------------------------------------------------------

end architecture behav;


