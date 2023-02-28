library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
Library unisim;
use unisim.vcomponents.all;
use work.ddr_interface_pkg.all;

entity ddr_transmitter is

    generic(
      TRAINING_PATTERN : data_type := USER_TRAINING_PATTERN;
      ACTIVE_EDGE      : std_logic := '0';
      USE_SYNC_STATE   : std_logic := '0'
    );

    port(
        clk_div_in         : in  std_logic;
        clk_ddr_in         : in  std_logic;
        rst_in             : in  std_logic;
        data_in            : in  trans_data_type;
        data_q             : out vxs_data_type;
        operation_mode_in  : in  status_type;          -- 000 - default / none
                                                       -- 001 - sending training sequence
                                                       -- 100 - data transfer mode
                                                       -- 111 - freeze
        operation_status_q : out status_type           -- 000 - default
                                                       -- 001 - sending training sequence done
                                                       -- 100 - data transfer mode
                                                       -- 111 - busy or freeze
    );
end entity ddr_transmitter;

architecture RTL of ddr_transmitter is

    -- data types for statemachines
    type mode_type is ( mode_sending,
                        mode_training_sequence,
                        mode_freeze
                      );
    type training_sequence_type is (
        TNG_INIT,
        TNG_WORD_ALIGNMENT,
        TNG_WORD_SYNC,
        TNG_FINISH
    );                  
    type freeze_type is (freeze_init, freeze_count);

    signal mode       : mode_type := mode_freeze;
    signal trans_data : trans_data_type := (others => (others => '0'));
    
    signal sending_status : status_type := "000";
    
    -- signals/constants mode_training_sequence
    signal training_state : training_sequence_type := TNG_INIT;
    
    -- signals/constants mode_freeze
    signal freeze_state   : freeze_type     := freeze_init;
    signal freeze_status  : status_type     := (others => '0');
    signal freeze_counter : freeze_ctr_type := (others => '0');
        
		  
 
		  
begin

    -- process for synchronously choosing operation mode
    mode_setting_proc: process(clk_div_in)
    begin
    
        if (clk_div_in'event and clk_div_in = ACTIVE_EDGE) then
            
            case operation_mode_in is
                when "001" => mode <= mode_training_sequence;
                when "100" => mode <= mode_sending;
                when "111" => mode <= mode_freeze;
                when others => null;
            end case;
            
        end if;
    
    end process;
    
    mode_sending_proc: process(clk_div_in)
        
        constant NUM_TNG_PATTERN     : integer := NUM_TRAINING_PATTERN;
        variable pattern_counter     : integer range 0 to NUM_TNG_PATTERN := 0;
        
        constant NUM_SYNC_PATTERN    : integer := 1023;
        variable synchronize_counter : integer range 0 to NUM_SYNC_PATTERN := 0;
    
    begin
    
        if (clk_div_in'event and clk_div_in = ACTIVE_EDGE) then
        
            if (mode = mode_sending) then
            
                trans_data <= data_in;
                sending_status <= "100";
                
                training_state <= TNG_INIT;
            
            elsif (mode = mode_training_sequence) then
            
                case training_state is
                    when TNG_INIT =>
                    
                        trans_data <= (others => TRAINING_PATTERN);
                        
                        pattern_counter := 0;
                        
                        sending_status <= "111";
                        training_state <= TNG_WORD_ALIGNMENT;
                    
                    when TNG_WORD_ALIGNMENT =>
                    
                        if (pattern_counter = NUM_TNG_PATTERN) then
                        
                            pattern_counter     := 0;
                        
                            if (USE_SYNC_STATE = '1') then
                                synchronize_counter := 0;                        
                                training_state <= TNG_WORD_SYNC;
                            else
                                training_state <= TNG_FINISH;
                            end if;
                            
                        else
                            pattern_counter := pattern_counter + 1;
                        end if;
                    
                    when TNG_WORD_SYNC =>
                    
                        trans_data <= (others => std_logic_vector(to_unsigned(synchronize_counter, NUM_PARALLEL_OUTPUTS)));
                        
                        if (synchronize_counter = NUM_SYNC_PATTERN) then
                            synchronize_counter := 0;
                            training_state <= TNG_FINISH;
                        else
                            synchronize_counter := synchronize_counter + 1;
                        end if;
                    
                    when TNG_FINISH => sending_status <= "001";
                    
                end case;
            
            else
                trans_data <= (others => DEFAULT_DATA);
                pattern_counter := 0;
                synchronize_counter := 0;
                training_state <= TNG_INIT;
                sending_status <= "000";
            end if;
        
        end if;
    
    end process;
    
    mode_freeze_proc: process(clk_div_in)
    begin
    
        if (clk_div_in'event and clk_div_in = ACTIVE_EDGE) then
        
            if (mode = mode_freeze) then
            
                case freeze_state is
                    when freeze_init =>
                        freeze_counter <= (others => '0');
                        
                        freeze_status <= "111";
                        freeze_state <= freeze_count;
                    when freeze_count =>
                        freeze_counter <= std_logic_vector(unsigned(freeze_counter) + 1);  
                end case;
            
            else
                freeze_state <= freeze_init;
                freeze_status <= "000";
            end if;
        
        end if;
    
    end process;

    OSERDES_inst: for i in 0 to VXS_BUS_WIDTH-1 generate    
        signal shift1, shift2 : std_logic := '0';
    begin

        OSERDES_MASTER : OSERDES
            generic map (
                DATA_RATE_OQ    => "DDR",         -- Specify data rate to "DDR" or "SDR" 
                DATA_RATE_TQ    => "DDR",         -- Specify data rate to "DDR", "SDR", or "BUF" 
                DATA_WIDTH      => 10,            -- Specify data width - For DDR: 4,6,8, or 10 
                                                  -- For SDR or BUF: 2,3,4,5,6,7, or 8 
                INIT_OQ         => '0',           -- INIT for Q1 register - '1' or '0' 
                INIT_TQ         => '0',           -- INIT for Q2 register - '1' or '0' 
                SERDES_MODE     => "MASTER",      -- Set SERDES mode to "MASTER" or "SLAVE" 
                SRVAL_OQ        => '0',           -- Define Q1 output value upon SR assertion - '1' or '0' 
                SRVAL_TQ        => '0',           -- Define Q1 output value upon SR assertion - '1' or '0' 
                TRISTATE_WIDTH  => 1              -- Specify parallel to serial converter width 
            )                                     -- When DATA_RATE_TQ = DDR: 2 or 4 
                                                  -- When DATA_RATE_TQ = SDR or BUF: 1 " 
            port map (                            
                OQ          => data_q(i),         -- 1-bit output
                SHIFTOUT1   => open,              -- 1-bit data expansion output
                SHIFTOUT2   => open,              -- 1-bit data expansion output
                TQ          => open,              -- 1-bit 3-state control output
                CLK         => clk_ddr_in,        -- 1-bit clock input
                CLKDIV      => clk_div_in,        -- 1-bit divided clock input
                D1          => trans_data(i)(0),  -- 1-bit parallel data input
                D2          => trans_data(i)(1),  -- 1-bit parallel data input
                D3          => trans_data(i)(2),  -- 1-bit parallel data input
                D4          => trans_data(i)(3),  -- 1-bit parallel data input
                D5          => trans_data(i)(4),  -- 1-bit parallel data input
                D6          => trans_data(i)(5),  -- 1-bit parallel data input
                OCE         => '1',               -- 1-bit clcok enable input
                REV         => '0',               -- Must be tied to logic zero
                SHIFTIN1    => shift1,            -- 1-bit data expansion input
                SHIFTIN2    => shift2,            -- 1-bit data expansion input
                SR          => rst_in,            -- 1-bit set/reset input
                T1          => '0',               -- 1-bit parallel 3-state input
                T2          => '0',               -- 1-bit parallel 3-state input
                T3          => '0',               -- 1-bit parallel 3-state input
                T4          => '0',               -- 1-bit parallel 3-state input
                TCE         => '0'                -- 1-bit 3-state signal clock enable input
            );
				            
        OSERDES_SLAVE : OSERDES
            generic map (
                DATA_RATE_OQ    => "DDR",         -- Specify data rate to "DDR" or "SDR" 
                DATA_RATE_TQ    => "DDR",         -- Specify data rate to "DDR", "SDR", or "BUF" 
                DATA_WIDTH      => 10,            -- Specify data width - For DDR: 4,6,8, or 10 
                                                  -- For SDR or BUF: 2,3,4,5,6,7, or 8 
                INIT_OQ         => '0',           -- INIT for Q1 register - '1' or '0' 
                INIT_TQ         => '0',           -- INIT for Q2 register - '1' or '0' 
                SERDES_MODE     => "SLAVE",       -- Set SERDES mode to "MASTER" or "SLAVE" 
                SRVAL_OQ        => '0',           -- Define Q1 output value upon SR assertion - '1' or '0' 
                SRVAL_TQ        => '0',           -- Define Q1 output value upon SR assertion - '1' or '0' 
                TRISTATE_WIDTH  => 1              -- Specify parallel to serial converter width 
            )                                     -- When DATA_RATE_TQ = DDR: 2 or 4 
                                                  -- When DATA_RATE_TQ = SDR or BUF: 1 " 
            port map (                            
                OQ          => open,              -- 1-bit output
                SHIFTOUT1   => shift1,            -- 1-bit data expansion output
                SHIFTOUT2   => shift2,            -- 1-bit data expansion output
                TQ          => open,              -- 1-bit 3-state control output
                CLK         => clk_ddr_in,        -- 1-bit clock input
                CLKDIV      => clk_div_in,        -- 1-bit divided clock input
                D1          => '0',               -- 1-bit parallel data input
                D2          => '0',               -- 1-bit parallel data input
                D3          => trans_data(i)(6),  -- 1-bit parallel data input
                D4          => trans_data(i)(7),  -- 1-bit parallel data input
                D5          => trans_data(i)(8),  -- 1-bit parallel data input
                D6          => trans_data(i)(9),  -- 1-bit parallel data input
                OCE         => '1',               -- 1-bit clcok enable input
                REV         => '0',               -- Must be tied to logic zero
                SHIFTIN1    => '0',               -- 1-bit data expansion input
                SHIFTIN2    => '0',               -- 1-bit data expansion input
                SR          => rst_in,            -- 1-bit set/reset input
                T1          => '0',               -- 1-bit parallel 3-state input
                T2          => '0',               -- 1-bit parallel 3-state input
                T3          => '0',               -- 1-bit parallel 3-state input
                T4          => '0',               -- 1-bit parallel 3-state input
                TCE         => '0'                -- 1-bit 3-state signal clock enable input
            );
    
    end generate;
    
    -- prepare operation_status
    operation_status_q <= sending_status or freeze_status;

end architecture RTL;
