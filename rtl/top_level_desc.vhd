--  Package File Template
--
--  Purpose: This package defines supplemental types, subtypes, 
--       constants, and functions 


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


package top_level_desc is

----------------------------------------------------------------------
----- format types
----------------------------------------------------------------------

    type wb_in is record
        ack          : std_logic;
        dat_o        : std_logic_vector(31 downto 0);
    end record wb_in;
    
    type        wb_mosi          is array (integer range<>) of wb_in;

    type wb_out is record
        cyc          : std_logic;
        stb          : std_logic;
        we           : std_logic_vector(3 downto 0);
        adr          : std_logic_vector(9 downto 0);
        dat_i        : std_logic_vector(31 downto 0);
    end record wb_out;     

    type        wb_miso          is array (integer range<>) of wb_out;

    type wb_bus is 
    record
        cyc             : std_logic;
        stb             : std_logic;
        we              : std_logic_vector(3 downto 0);
        adr             : std_logic_vector(9 downto 0);
        dat_i           : std_logic_vector(31 downto 0);
        ack             : std_logic;
        dat_o           : std_logic_vector(31 downto 0);
    end record wb_bus;     

    type        wb_busses           is array (integer range<>) of wb_bus;
    
    
    subtype     ADC_delay_setting   is std_logic_vector(31 downto 0) ;
    type        ADC_delay_settings  is array (integer range<>) of ADC_delay_setting;

    subtype     ADC_port            is std_logic_vector(14 downto 0) ;  
    type        ADC_ports           is array (integer range<>) of ADC_port;

    subtype     ADC_DDRport         is std_logic_vector(23 downto 0) ;  
    type        ADC_DDRports        is array (integer range<>) of ADC_DDRport;  
    
    subtype     DMC_port            is std_logic_vector(31 downto 0) ;  
    type        DMC_ports           is array (integer range<>) of DMC_port;
    
    subtype     ADC_data_port       is std_logic_vector(13 downto 0) ;  
    type        ADC_data_ports      is array (integer range<>) of ADC_data_port;

    subtype     tc_offset_data      is std_logic_vector(11 downto 0) ;  
    type        tc_offset_datas     is array (integer range<>) of tc_offset_data;
    
    subtype     frame_data          is std_logic_vector(27 downto 0) ;  
    type        frames_data         is array (integer range<>) of frame_data;
    
    type        HS_TRG_port         is array (integer range<>) of std_logic;  
    
    subtype     data_port           is std_logic_vector(30 downto 0) ;  
    type        data_ports          is array (integer range<>) of data_port;
    
    subtype     time_c_data         is std_logic_vector(33 downto 0);
    type        time_c_datas        is array (integer range<>) of time_c_data;

    subtype     time_f_data         is std_logic_vector(33 downto 0);
    type        time_f_datas        is array (integer range<>) of time_f_data;

    subtype     amplitude           is std_logic_vector(33 downto 0);
    type        amplitudes          is array (integer range <>) of amplitude;

    subtype     integral            is std_logic_vector(33 downto 0);
    type        integrals           is array (integer range <>) of integral;

    subtype     cf_array            is signed(14 downto 0);
    type        cf_arrays           is array (integer range <>) of cf_array;

    subtype     quotient            is std_logic_vector(23 downto 0);
    type        quotients           is array (integer range <>) of quotient;

    subtype     dac_port            is std_logic_vector(15 downto 0) ;
    type        dac_ports           is array (integer range<>) of dac_port;

    subtype     latency             is std_logic_vector(15 downto 0) ;
    type        latencies           is array (integer range<>) of dac_port;

    subtype     framewidth          is std_logic_vector(15 downto 0) ;
    type        framewidths         is array (integer range<>) of dac_port;
    
    subtype     long_word           is signed(31 downto 0) ;  
    type        long_words          is array (integer range<>) of long_word;

    subtype     two_flag            is std_logic_vector(1 downto 0);
    type        two_flags           is array (integer range<>) of two_flag;
    
    type        port_flags          is array (integer range<>) of std_logic;
    
    type        dual_flags          is array (1 downto 0) of std_logic;
    
    subtype     mon_val             is std_logic_vector(9 downto 0);
    type        mon_vals            is array (integer range<>) of mon_val;
    
    subtype     temp_val            is std_logic_vector(11 downto 0);
    type        temp_vals           is array (integer range<>) of temp_val;

    subtype     rbuf_addr           is std_logic_vector(11 downto 0);
    type        rbuf_addrs          is array (integer range<>) of rbuf_addr;

    subtype     counters            is integer range 0 to 31;  
    type        cycle_counters      is array (integer range<>) of counters;
    
    subtype     date_units          is integer range 0 to 31;
    type        date                is array (0 to 2) of date_units;
    
    subtype     WEN                 is std_logic_vector(3 downto 0);
    type        WEN_array           is array (integer range <>) of WEN;

    subtype     ADDRESS             is std_logic_vector(15 downto 0);
    type        ADDRESS_array       is array (integer range <>) of ADDRESS;

    type        arr_framewidth      is array (integer range <>) of integer;                 --defines framewidth
    type        arr_latency         is array (integer range <>) of integer;                 --trigger latency
        
    subtype     analog_signal       is real ;  
    type        analog_signals      is array (integer range<>) of analog_signal;
    
end top_level_desc;
