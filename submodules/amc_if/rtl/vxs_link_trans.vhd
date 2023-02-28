library ieee;
use ieee.std_logic_1164.all;
use work.ddr_interface_pkg.all;

entity vxs_link_trans is
    generic (
        BOS_PERIOD : integer := 10      -- BOS period in seconds
    );
    
    port (
                
        vxs_clk_div_in : in  std_logic;
        vxs_clk_ddr_in : in  std_logic;
        
        bos_in     : in  std_logic;
        vxs_data_q : out vxs_data_type;        
        bosync_q   : out std_logic;
		start_cal_in : in std_logic;
        
        fifo_rst_q    : out fifo_ctrl_type;
        fifo_empty_in : in  fifo_ctrl_type;
        fifo_rd_en_q  : out fifo_ctrl_type;
        fifo_data_in  : in  fifo_data_array_type
                
    );
end entity vxs_link_trans;

architecture RTL of vxs_link_trans is

    component ddr_transmitter is
    
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
    end component ddr_transmitter;
    
    signal bosync : std_logic := '0';
    
    type session_type is (SEND_SESSION, TRAINING_SESSION);
    signal session : session_type := SEND_SESSION;
    
    signal vxs_fifo_data : trans_data_type := (others => (others => '0'));
    signal vxs_data      : trans_data_type := (others => (others => '0'));
    
    signal vxs_operation_mode   : status_type := "100";
    signal vxs_operation_status : status_type := "000";
    
begin

    fifos_readout_proc: for i in 0 to VXS_BUS_WIDTH-1 generate

        readout_proc: process(vxs_clk_div_in)
        
            type fifo_readout_type is (WAIT_FOR_DATA, SEND_WORD1, SEND_WORD2, SEND_WORD3);
            
            variable fifo_readout_state : fifo_readout_type := WAIT_FOR_DATA;        
            variable fifo_data          : fifo_data_type    := (others => '0');
            
            variable parity1, parity2 : std_logic := '0';    
        
        begin
        
            if (vxs_clk_div_in'event and vxs_clk_div_in = '0') then
            
                case fifo_readout_state is
                
                    when WAIT_FOR_DATA =>
                    
                        vxs_fifo_data(i) <= (others => '0');
                    
                        if (fifo_empty_in(i) = '0') then                                       
                            fifo_rd_en_q(i) <= '1';                        
                            fifo_readout_state := SEND_WORD1;                        
                        else
                            fifo_rd_en_q(i) <= '0';                        
                        end if;
                    
                    when SEND_WORD1 =>   
                                 
                        fifo_rd_en_q(i) <= '0';
                        fifo_data := fifo_data_in(i);
                        
                        -- send marker bit and first 9 bits of word
                        vxs_fifo_data(i) <= '1' & fifo_data(28 downto 20);
                                            
                        fifo_readout_state := SEND_WORD2;
                                        
                    when SEND_WORD2 =>
                    
                        vxs_fifo_data(i) <= fifo_data(19 downto 10);
                                        
                        fifo_readout_state := SEND_WORD3;                
                    
                    when SEND_WORD3 =>
                        
                        parity1 := calcParity9Bit(fifo_data(28 downto 20));
                        parity2 := calcParity16Bit(fifo_data(19 downto 4));
                                       
                        vxs_fifo_data(i) <= fifo_data(9 downto 2) & parity1 & parity2;                
    
                        if (fifo_empty_in(i) = '0') then                                       
                            fifo_rd_en_q(i) <= '1';                        
                            fifo_readout_state := SEND_WORD1;                        
                        else
                            fifo_readout_state := WAIT_FOR_DATA;                        
                        end if;
                    
                end case;
            
            end if;
        
        end process;
    
    end generate;
    
    session_ctrl_proc: process(vxs_clk_div_in)
    
        type session_state_type is (WAIT_BOS, START_TNG, WAIT_TNG_FINISHED);
        variable session_state : session_state_type := WAIT_BOS;
        
        constant SESSION_MARKER_LENGTH : integer := 4;
        variable session_ctr : integer range 0 to SESSION_MARKER_LENGTH := 0;
    
    begin
    
        if (vxs_clk_div_in'event and vxs_clk_div_in = '1') then
        
            case session_state is
            
                when WAIT_BOS =>
                
                    if (start_cal_in = '1') then
                        bosync_q <= '1';
                        session <= TRAINING_SESSION;
                        session_state := START_TNG;
                    else
                    
                        bosync_q <= '0';
                    
                        session <= SEND_SESSION;
                    
                        if (vxs_operation_status = "100") then
                            vxs_operation_mode <= "000";
                            fifo_rst_q <= (others => '0');
                        else
                            vxs_operation_mode <= "100";
                        end if;
                                                
                    end if;
                
                when START_TNG =>
                
                    bosync_q <= '0';
                
                    if (session_ctr = SESSION_MARKER_LENGTH) then
                        session_ctr := 0;
                        vxs_operation_mode <= "001";
                        session_state := WAIT_TNG_FINISHED;
                    else
                        session_ctr := session_ctr + 1;
                    end if;
                
                when WAIT_TNG_FINISHED =>
                
                    if (vxs_operation_status = "111") then
                        vxs_operation_mode <= "000";
                        fifo_rst_q <= (others => '1');
                    elsif (vxs_operation_status = "001") then                        
                        session_state := WAIT_BOS;
                    end if;
                
            end case;
        
        end if;
    
    end process;
    
    bosync_tcs_inst: if (BOS_PERIOD = 0) generate
        process(vxs_clk_div_in)
            
            type bos_prepare_state_type is (PREPARE_WAIT_BOS, PREPARE_HOLD);
            variable bos_prepare_state : bos_prepare_state_type := PREPARE_WAIT_BOS;
            
            constant PREPARE_HOLD_LEN : integer := 15;
            variable prepare_hold_ctr : integer range 0 to PREPARE_HOLD_LEN := 0; 
            
        begin

			if (vxs_clk_div_in'event and vxs_clk_div_in = '1') then
        
				case bos_prepare_state is
				
					when PREPARE_WAIT_BOS =>
					
						if (bos_in = '1') then
							bosync <= '1';
							bos_prepare_state := PREPARE_HOLD;
						end if;
					
					when PREPARE_HOLD =>
					
						bosync <= '0';
					
						if (prepare_hold_ctr = PREPARE_HOLD_LEN) then
							prepare_hold_ctr := 0;
							bos_prepare_state := PREPARE_WAIT_BOS;
						else
							prepare_hold_ctr := prepare_hold_ctr + 1;
						end if;
					
				end case;

			end if; 
 
        end process;
    end generate;
    
    bosync_generated_inst: if (BOS_PERIOD > 0) generate
    
        bos_generate_proc: process(vxs_clk_div_in)
        
            constant BOS_CTR_LEN : integer := BOS_PERIOD * CLK_DIV_FREQ;
            variable bos_ctr     : integer range 0 to BOS_CTR_LEN := 0;
            
        begin
        
            if (vxs_clk_div_in'event and vxs_clk_div_in = '1') then
        
                if (bos_ctr = BOS_CTR_LEN) then
                    bos_ctr := 0;
                    bosync <= '1';           
                else
                    bos_ctr := bos_ctr + 1;
                    bosync <= '0';
                end if;
            
            end if;
        
        end process;

    end generate;
    
    inst_ddr_trans: ddr_transmitter
    
        generic map (
            USE_SYNC_STATE => '0'
        )
    
        port map (
            
            clk_div_in         => vxs_clk_div_in,
            clk_ddr_in         => vxs_clk_ddr_in,
            rst_in             => '0',
            data_in            => vxs_data,
            data_q             => vxs_data_q,
            operation_mode_in  => vxs_operation_mode,
            operation_status_q => vxs_operation_status
                
        );

    vxs_data <= vxs_fifo_data when session = SEND_SESSION else (others => (others => '1'));

end architecture RTL;
