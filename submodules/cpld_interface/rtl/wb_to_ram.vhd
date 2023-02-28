----------------------------------------------------------------------------------
-- Company:		    VISENGI S.L. (www.visengi.com)
-- Engineer:	    Victor Lopez Lorenzo (victor.lopez (at) visengi (dot) com)
-- Modified:        Alessandro Balla ( three ports to generic n ports)
-- Create Date:	    23:44:13 22/August/2008 
-- Project Name:    N Port WISHBONE SPRAM Wrapper
-- Tool versions:   Xilinx ISE 9.2i
-- Description: 
--
-- Description: This is a wrapper for an inferred single port RAM, that converts it
--				into a N-port RAM with one WISHBONE slave interface for each port. 
--
-- Note:        The core wait for pending slave wb.cyc until it respond 
--              with an wb_ack according with the lock unlock logic
--
-- LICENSE TERMS: GNU LESSER GENERAL PUBLIC LICENSE Version 2.1
--	   That is you may use it in ANY project (commercial or not) without paying a cent.
--	   You are only required to include in the copyrights/about section of accompanying 
--	   software and manuals of use that your system contains a "3P WB SPRAM Wrapper
--	   (C) VISENGI S.L. under LGPL license"
--	   This holds also in the case where you modify the core, as the resulting core
--	   would be a derived work.
--	   Also, we would like to know if you use this core in a project of yours, just an email will do.
--
--	  Please take good note of the disclaimer section of the LPGL license, as we don't
--	  take any responsability for anything that this core does.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.all;

-- package wb_to_ram is     
--     type wb_bus is 
--         record
--             cyc             : std_logic;
--             stb             : std_logic;
--             we              : std_logic_vector(3 downto 0);
--             adr             : std_logic_vector(9 downto 0);
--             dat_o           : std_logic_vector(31 downto 0);
--             ack             : std_logic;
--             dat_i           : std_logic_vector(31 downto 0);
--         end record wb_bus;     
--
--     type        wb_busses           is array (integer range<>) of wb_bus;
--
----    type wb_in is record
--        ack          : std_logic;
--        dat_o        : std_logic_vector(31 downto 0);
--    end record wb_in;
--
--        type        wb_mosi          is array (integer range<>) of wb_in;
--
--    type wb_out is record
--        cyc          : std_logic;
--        stb          : std_logic;
--        we           : std_logic;
--        adr          : std_logic_vector(9 downto 0);
--        dat_i        : std_logic_vector(31 downto 0);
--    end record wb_out;     
--
--        type        wb_miso          is array (integer range<>) of wb_out;
--
-- end wb_to_ram;

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;

library work;
-- use work.Types.all;
use work.top_level_desc.all;
use work.g_parameters.all;

entity wb_to_ram is
	generic (data_width : integer := 32;
			 addr_width : integer := 9;
             n_port     : integer := 5);
	port (
		control	    : inout std_logic_vector(35 downto 0);
		mem_clka    : out   std_logic;
		mem_wea	    : out   std_logic_vector(3 downto 0);
		mem_addra   : out   std_logic_vector(15 downto 0);
		mem_dina    : out   std_logic_vector(data_width-1 downto 0);
		mem_douta   : in    std_logic_vector(data_width-1 downto 0);

		wb_clk      : in    std_logic;
		wb_rst      : in    std_logic;

        wb_mosi     : out   wb_mosi(n_port-1 downto 0);
        wb_miso     : in    wb_miso(n_port-1 downto 0)
		);
end wb_to_ram;

architecture Behavioral of wb_to_ram is
	
	signal we	    : std_logic_vector(3 downto 0);
	signal a	    : std_logic_vector(addr_width-1 downto 0);
	signal d, q     : std_logic_vector(data_width-1 downto 0);

	signal State						   : integer range 0 to 15;
	attribute safe_implementation		   : string;
	attribute safe_implementation of State : signal is "yes";

-------------------------------------------------------------------------------
-- we or funtion
	function we_or (din : std_logic_vector(3 downto 0))
		return std_logic is
		variable t : std_logic := '0';	-- variable mit default Zuweisung
	begin
		for i in din'range loop			-- ganze Busbreite
			t := t or din(i);
		end loop;
		return t;
	end we_or;
-------------------------------------------------------------------------------
-- chipscope
    component wb_to_ram_ila
        port (
            control     : inout std_logic_vector(35 downto 0);
            clk         : in    std_logic;
            data        : in    std_logic_vector(127 downto 0);
            trig0       : in    std_logic_vector(15 downto 0)
            );
    end component;

    signal ila_data : std_logic_vector(127 downto 0);
    signal ila_trg	: std_logic_vector(15 downto 0);

-------------------------------------------------------------------------------
-- signals
	signal ack_r    : std_logic_vector(n_port-1 downto 0) := (others => '0');
    signal ack_i    : std_logic_vector(n_port-1 downto 0);

    signal ack      : std_logic_vector(n_port - 1 downto 0);
	signal lock     : integer range 0 to n_port;

    -- signal wb_bus   : wb_busses(n_port-1 downto 0);
-------------------------------------------------------------------------------
	
begin

    Inst_chipscope : if USE_CHIPSCOPE_ILA_4 generate

        Inst_wb_to_ram_ila : wb_to_ram_ila
              port map (
                control     => control,
                clk         => wb_clk,
                data        => ila_data,
                trig0       => ila_trg
                );

        ila_data(31 downto  0) <= d;
        ila_data(63 downto 32) <= q;
        ila_data(67 downto 64) <= we;
        ila_data(83 downto 68) <= "1" & a & "11111";
        ila_data(91 downto 84) <= std_logic_vector(to_unsigned(lock,8));
        ila_data(92)           <= wb_rst;

        
        inst_cs_wb :
        for i in 0 to n_port - 1 generate -- max 8 n_port
            begin
                ila_data(104 + i)   <= wb_miso(i).cyc;
                ila_data(112 + i)   <= wb_miso(i).stb;
                ila_data(120 + i)   <= ack_i(i);
                ila_trg(i)          <= wb_miso(i).cyc;
                ila_trg(8 + i)      <= wb_miso(i).stb;
        end generate;

    end generate;

    
        
	mem_clka  <= wb_clk;
	mem_wea	  <= we;
	mem_addra <= "1" & a & "11111";
	mem_dina  <= d;
	q		  <= mem_douta;

    wb_mosi_bus: 
    process(q,ack_i)
    begin
        for i in 0 to n_port - 1 loop
            wb_mosi(i).dat_o    <= q;
            wb_mosi(i).ack      <= ack_i(i);         
        end loop;
    end process;




	WB_interconnect : process(wb_clk, wb_rst)

	begin
        if wb_rst = '1' then
            we	    <= x"0";
	    	ack_r   <= (others => '0');
	    	--ack_i   <= (others => '0');
	    	ack     <= (others => '0');
	    	a       <= (others => '0'); -- aggiunti
	    	d       <= (others => '0'); -- aggiunti
            lock    <= 0;

		elsif rising_edge(wb_clk) then

	    	--defaults (unless overriden afterwards)
	    	we	    <= x"0";
            ack     <= (others => '0');
	    	ack_r   <= ack;
            --ack_i   <= ack_i;
            d       <= d;
            a       <= a;

	        --unlockers
            for i in 0 to n_port - 1 loop
                if (lock = i + 1 and wb_miso(i).cyc = '0') then 
                    lock <= 0; 
                end if;
            end loop;

            for i in 0 to n_port - 1 loop
                if (wb_miso(i).cyc = '1' and ((lock = 0) or (lock = (i + 1)))) then	--lock request (grant if lock is available)
                    lock    <= (i + 1);
                    if (wb_miso(i).stb = '1') then -- and ack_r(i) = '0' and ack_i(i) = '0') then	 --operation request
                        we      <= wb_miso(i).we;
                        a       <= wb_miso(i).adr;
                        d       <= wb_miso(i).dat_i;
                        ack(i)  <= '1';
                    else
                        ack(i)  <= '0';	   
                    end if;
                end if;

                ack_r(i) <= ack(i) and wb_miso(i).stb;
                -- ack_i(i) <= ack_r(i) and wb_miso(i).stb;	 --to don't ack aborted operations
            end loop;
        end if;

        for i in 0 to n_port - 1 loop
            ack_i(i) <= ack_r(i) and wb_miso(i).stb;	 --to don't ack aborted operations
        end loop;

	end process WB_interconnect;
end Behavioral;

