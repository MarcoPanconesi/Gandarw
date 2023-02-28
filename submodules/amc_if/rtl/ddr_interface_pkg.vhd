library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

package ddr_interface_pkg is

    -- constants which defines the device (don't change them!)
    constant NUM_PARALLEL_OUTPUTS  : integer := 10;                      -- 1 to 10 SERDES
    constant MAX_BITSLIP_OPS       : integer := NUM_PARALLEL_OUTPUTS-1;  -- max number of possible bitslips
    constant PAUSE_AFTER_BITSLIP   : integer := 3;                       -- pause cycles after bitslips (see UG361)
    constant NUM_HISTORY_ENTRIES   : integer := 1;                       -- number of entries in config history
    constant VXS_BUS_WIDTH         : integer := 8;                       -- GANDALF uses 8 LVDS pairs for trigger
    constant VXS_BUS_WIDTH_SLINK   : integer := 8;                       -- GANDALF uses 4 LVDS pairs for SLink
    constant NUM_GANDALFS          : integer := 18;                      -- Number of GANDALFs per crate
    constant MAX_DELAY_GATE_CYCLES : integer := 3;
    constant CLK_DIV_FREQ          : integer := 100000000;                    -- DIV clock frequency in Hertz
    
    -- standard types used for entire design
    subtype data_type              is std_logic_vector(NUM_PARALLEL_OUTPUTS-1 downto 0);
    subtype delay_tap_type         is std_logic_vector(4 downto 0);
    subtype bitslip_type           is std_logic_vector(3 downto 0);
    subtype status_type            is std_logic_vector(2 downto 0);
    subtype freeze_ctr_type        is std_logic_vector(63 downto 0);
    subtype delay_gate_cycles_type is integer range 0 to MAX_DELAY_GATE_CYCLES;    
    
    -- user constants
    constant DATA_LINK_WIDTH       : integer   := VXS_BUS_WIDTH;
    constant USER_TRAINING_PATTERN : data_type := "1110010001";
    constant NUM_TRAINING_PATTERN  : integer := 4095;
    constant NUM_SYNC_PATTERN      : integer := 1023;
    constant DEFAULT_DATA          : data_type := (others => '0');
    constant TRIGGER_TEST_PATTERN  : std_logic_vector(39 downto 0) := "1111011111" & -- high density pattern
                                                                      "0000100000" & -- low density pattern
                                                                      "1010101010" & -- alternating pattern
                                                                      "0101010101";    -- alternating pattern
    
    -- types for data protocol
    subtype data_ser_buffer_type is std_logic_vector(0 to DATA_LINK_WIDTH-1);
    subtype link_integer_type    is integer range 0 to DATA_LINK_WIDTH-1;
    subtype adc_type             is std_logic_vector(11 downto 0);
    subtype cfd_type             is std_logic_vector( 9 downto 0);
    subtype vxs_data_type        is std_logic_vector(0 to VXS_BUS_WIDTH-1);
    
    type    vxs_ds_pair_type is record
        p : std_logic;
        n : std_logic;
    end record;
    
    type vxs_ds_data_type     is array (0 to VXS_BUS_WIDTH-1) of vxs_ds_pair_type;
    type data_buffer_type     is array (0 to DATA_LINK_WIDTH-1) of data_type;
    type trans_data_type      is array (0 to VXS_BUS_WIDTH-1) of data_type;
    
    -- types for serdes_delay_controller
    subtype cont_type      is std_logic_vector(0 to DATA_LINK_WIDTH-1);   
    type cont_delay_type   is array (0 to DATA_LINK_WIDTH-1) of delay_tap_type;
    type cont_bitslip_type is array (0 to DATA_LINK_WIDTH-1) of bitslip_type;
    constant CONT_TYPE_HIGH : cont_type := (others => '1');
    constant CONT_TYPE_LOW  : cont_type := (others => '0');
    
    -- types for delay_gate
    type delay_gate_data_type is array (1 to MAX_DELAY_GATE_CYCLES) of data_type;
    type delay_gate_link_type is array (0 to DATA_LINK_WIDTH-1) of delay_gate_cycles_type;
    
    -- types for slink data
    subtype slink_word_type is std_logic_vector(31 downto 0);
    subtype slink_data_link is std_logic_vector(NUM_GANDALFS-1 downto 0);
    
    type slink_data_type is record
        data_rdy : std_logic;
        misc     : std_logic_vector(6 downto 0);
        word     : slink_word_type;
    end record;
    
    type slink_interface_type is array (0 to NUM_GANDALFS-1) of slink_data_type;     
    
    -- complex types
    type history_entry is record
        taps     : delay_tap_type;
        bitslips : bitslip_type;
    end record;
    
    type delay_gate_config_type is record
        link   : integer range 0 to DATA_LINK_WIDTH-1;
        cycles : delay_gate_cycles_type;
    end record;
    
    type history_type     is array (0 to DATA_LINK_WIDTH-1, 0 to NUM_HISTORY_ENTRIES-1) of history_entry;
    
    type history_pointer_type is record
        link  : link_integer_type;
        entry : integer range 0 to NUM_HISTORY_ENTRIES-1;        
    end record;
    
    -- types and functions for vxs trigger data
    
    constant FIFO_DATA_LENGTH : integer := 30;
    subtype fifo_data_type is std_logic_vector(FIFO_DATA_LENGTH-1 downto 0);
    type    fifo_data_array_type is array (0 to DATA_LINK_WIDTH-1) of fifo_data_type;
    subtype fifo_ctrl_type is std_logic_vector(0 to DATA_LINK_WIDTH-1);
    
    constant PARITY_ODD_VALUE : std_logic := '0';
    function calcParity9Bit(data : std_logic_vector(8 downto 0)) return std_logic;
    function calcParity16Bit(data : std_logic_vector(15 downto 0)) return std_logic;
    
    -- types and functions for lcd display on ML605
    subtype lcd_data_type is std_logic_vector(7 downto 0);
    subtype hex_type      is std_logic_vector(3 downto 0);
    
    function lcd_hex_char(hex : hex_type) return lcd_data_type;
    function lcd_int_char(int : link_integer_type) return lcd_data_type;
    
    -- functions for preparing test data
    function next_pseudo_random(data : data_type) return data_type;
    
    
    
end package ddr_interface_pkg;

package body ddr_interface_pkg is

    function calcParity9Bit(data : std_logic_vector(8 downto 0)) return std_logic is
        variable parity : std_logic := '0';
    begin
        
        parity := data(0) xor data(1) xor data(2) xor data(3) xor
                  data(4) xor data(5) xor data(6) xor data(7) xor
                  data(8);
                  
        if (parity = '1') then
            return not PARITY_ODD_VALUE;
        else
            return PARITY_ODD_VALUE;
        end if;
                  
    end function;

    function calcParity16Bit(data : std_logic_vector(15 downto 0)) return std_logic is
        variable parity : std_logic := '0';
    begin
        
        parity := data(0) xor data(1) xor data(2) xor data(3) xor
                  data(4) xor data(5) xor data(6) xor data(7) xor
                  data(8) xor data(9) xor data(10) xor data(11) xor
                  data(12) xor data(13) xor data(14) xor data(15);
                  
        if (parity = '1') then
            return not PARITY_ODD_VALUE;
        else
            return PARITY_ODD_VALUE;
        end if;
                  
    end function;

    function next_pseudo_random(data : data_type) return data_type is
        variable lsb    : std_logic := '0';
        variable random : data_type := (others => '0');
    begin
    
        lsb := data(9) xor data(6);
        random := data(8 downto 0) & lsb;        
        
        return random;
    
    end function;
    
    function lcd_hex_char(hex : hex_type) return lcd_data_type is
    begin
    
        case hex is
            when "0000" => return "00110000";   -- 0
            when "0001" => return "00110001";   -- 1   
            when "0010" => return "00110010";   -- 2
            when "0011" => return "00110011";   -- 3
            when "0100" => return "00110100";   -- 4
            when "0101" => return "00110101";   -- 5
            when "0110" => return "00110110";   -- 6
            when "0111" => return "00110111";   -- 7
            when "1000" => return "00111000";   -- 8
            when "1001" => return "00111001";   -- 9
            when "1010" => return "01000001";   -- A
            when "1011" => return "01000010";   -- B
            when "1100" => return "01000011";   -- C
            when "1101" => return "01000100";   -- D
            when "1110" => return "01000101";   -- E
            when "1111" => return "01000110";   -- F
            when others => return "00110000";   -- 0
        end case;
    
    end function;
    
    function lcd_int_char(int : link_integer_type) return lcd_data_type is
    begin
    
        case int is
            when 0 => return "00110000";   -- 0
            when 1 => return "00110001";   -- 1   
            when 2 => return "00110010";   -- 2
            when 3 => return "00110011";   -- 3
            when 4 => return "00110100";   -- 4
            when 5 => return "00110101";   -- 5
            when 6 => return "00110110";   -- 6
            when 7 => return "00110111";   -- 7
            --when 8 => return "00111000";   -- 8
            --when 9 => return "00111001";   -- 9
            when others => return "00110000"; 
        end case;
    
    end function;
    
end package body ddr_interface_pkg;
