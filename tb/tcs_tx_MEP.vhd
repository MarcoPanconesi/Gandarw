----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:     08:12:07 01/02/2023
-- Design Name:
-- Module Name:     tcs_tx_mep - Behavioral
-- Project Name:
-- Target Devices:
-- Tool versions:
-- Description:     NA62 Broadcast command trigger type   
--
-- Dependencies:
--
-- Revision:        0.01 - File Created
--  
-- Comments:        The structure of the Broadcast Command (BC) frame
--      
--                  | START | FMT | CMD/DATA | CHCK  | STOP |
--                  |       |     |   7:0    |  4:0  |      |
--                  |   0   |  0  | dddddddd | eeeee |   1  |
--
-- Encoder Output waveform : TTCvx user manual 21/05/1999 pag. 13 
--           _______      ____    ______        __    __    ______
-- DATA :           |    |    |  |      |      |  |  |  |  |
--                  |____|    |__|      |______|  |__|  |__|
--
--                  |  A |  B |  A |  B |  A |  B |  A  |  B  |      
--           _______      ____      ____      ____       _____
-- CLOCK :          |    |    |    |    |    |    |     |     |
--                  |____|    |____|    |____|    |_____|     |____
--                                                                                                          
--                   A=0  B=0  A=1  B=0  A=0  B=1   A=1   B=1  
--
--
--           _______       __    _____    __       __    _____    __
-- DATA             |     |  |  |     |  |  |     |  |  |     |  |
-- IDLE             |_____|  |__|     |__|  |_____|  |__|     |__|
--
--                    A=0   B=1   A=0   B=1   A=0   B=1   A=0   B=1  
--
-- NOTE :   To send a TRIGGER set the right Trigger type :
--          (See Gandalf NA62 DataFormats.pdf)
----------------------------------------------------------------------------------
-- L0 Trig      Type Trigger        Sub-detector action

-- 0b0xxxxx     Physics trigger     Send data frame
-- 0b100000     Synchronization     Send special frame 
-- 0b100001     Reserve 
-- 0b100010     Start of burst      Enable data-taking, send special frame
-- 0b100011     End of burst        Disable data-taking, sesend end of burst data
-- 0b100100     Choke on            Send special frame 
-- 0b100101     Choke off           Send special frame 
-- 0b100110     Error on            Send special frame 
-- 0b100111     Error off           Send special frame 
-- 0b101000     Monitoring          Send monitoring data frame
-- 0b101001     Reserve 
-- 0b10101x     Reserve 
-- 0b10110x     Random              Send data frame
-- 0b10111x     Reserve 
-- 0b11xxxx     Calibration         Send data frame 
----------------------------------------------------------------------------------
--  WARNING !!!
--  To send only ECRST or BCRST signal set EVENT_TYPE(7 downto 2) to all zero
--  and the EVENT_TYPE(1) = ECRST and EVENT_TYPE(0) = BCRST 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.TOP_LEVEL_DESC.ALL;
USE WORK.G_PARAMETERS.ALL;

--use IEEE.STD_LOGIC_ARITH.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

ENTITY tcs_tx_mep IS
  GENERIC(
    BS_GIMLI_TYPE   : string := "TCS"
    );
  PORT (
    RESET           : in  std_logic;                   
    TRIGGER         : in  std_logic;                     
    TCS_CLK         : in  std_logic;                   
    EVENT_TYPE      : in  std_logic_vector(7 downto 0);
    WR_TYPE         : in  std_logic;
    TCS_CLK_P       : out std_logic;                   
    TCS_CLK_N       : out std_logic;                   
    TCS_DATA_P      : out std_logic;                   
    TCS_DATA_N      : out std_logic                    
    );

END tcs_tx_mep;

architecture Behavioral of tcs_tx_mep is

  signal  TCS_DATA_i    : std_logic :='1';
  signal  CH_CLK        : std_logic :='1';
  signal  EXP_CLK       : std_logic :='0';
        
  signal  sel           : integer range 0 to 3   :=0;
  signal  BC_count      : integer range 0 to 15  :=0;
        
  signal  shiftReg      : std_logic_vector(15 downto 0) :=(others =>'1');
        
  signal  EVENT_TYPE_i  : std_logic_vector(7 downto 0)  :=(others =>'0');
  signal  SERLYZER_DONE : std_logic;
  signal  EMPTY_i       : std_logic;
  signal  RD_TYPE       : std_logic;

  signal  trigger_i     : std_logic :='0';
  signal  tmp           : std_logic :='0';

  type    tcs_state   is (  st_sleep,
                            st_read,
                            st_wait
                          );

  signal  state       : tcs_state := st_sleep;



begin

inst_tcs_trg: if BS_GIMLI_TYPE = "TCS" OR BS_GIMLI_TYPE = "VXS" generate
  TCS_DATA_P <= TCS_DATA_i;
  TCS_DATA_N <= NOT(TCS_DATA_i);
end generate;

inst_self_tcs: if BS_GIMLI_TYPE = "OCX" generate
  TCS_DATA_P <= NOT(TRIGGER);
  TCS_DATA_N <= TRIGGER;
end generate;

  TCS_CLK_P  <= TCS_CLK;
  TCS_CLK_N  <=  not TCS_CLK;

  inst_fifo: entity work.fifo3
       Generic Map ( 
        deep        => 4,        
        width       => 8
        )
    Port Map (      
        datain      => EVENT_TYPE,
        wrclk       => TCS_CLK,
        rdclk       => EXP_CLK,
        res         => RESET,
        oe          => RD_TYPE,
        wr_en       => WR_TYPE,
        rd_en       => RD_TYPE,
        empty       => EMPTY_i,
        full        => open,
        count_dat   => open,
        dataout     => EVENT_TYPE_i
        );


    create_CH_CLK: process (TCS_CLK)
    begin
      if (TCS_CLK='1' and TCS_CLK'event ) then
        CH_CLK <= NOT CH_CLK; -- 1/2 TCS_CLK (80.16 Mhz)
      end if;
    end process;

  create_EXP_CLK: process (CH_CLK)
    begin
      if (CH_CLK='0' and CH_CLK'event ) then
        EXP_CLK <= NOT EXP_CLK; -- 1/4 TCS_CLK (40.08 Mhz)
      end if;
    end process;


  create_TCSdata_B_ch: process (EXP_CLK)
    begin
      if (EXP_CLK='1' and EXP_CLK'event ) then
        --Serializer
        shiftReg <= shiftReg(14 downto 0) & '1';

        if BC_count > 0 then
          BC_count <= BC_count - 1;
        end if;

        if RD_TYPE = '1' then
          shiftReg(15 downto 0)<= b"00" & EVENT_TYPE_i & b"000001";
          BC_count <= 15;
        end if;
      end if;

    end process;


  --merge A B channels

  merge_AB_channels: process(TCS_CLK)
    begin
      if TCS_CLK='1' and TCS_CLK'event then

        -- Transmit always IDLE Character A=0,B=1.
        -- 0 0 1 0 or 1 1 0 1 ... Cambiato in XOR !!!
        case sel is
          when 0 | 2 =>
            TCS_DATA_i <= not TCS_DATA_i; 
            sel <= sel + 1;
          when 1 =>
            TCS_DATA_i <= TCS_DATA_i xor trigger_i; -- XNOR = 1 when equals; XOR = 0 when equals
            sel <= sel + 1;
          when 3 =>
            TCS_DATA_i <= TCS_DATA_i xor shiftReg(15);
            sel <= 0;
        end case;
      end if;

  end process;
  
  TRIG_control : process (TCS_CLK)
    begin
    if rising_edge(TCS_CLK) then
        if (((TRIGGER and WR_TYPE) or tmp) and not trigger_i ) = '1' then   -- genera il segnale trigger_i di durata EXP_CLK
            tmp <= '1';                                                     -- risincronizzando TCS_CLK con EXP_CLK
        else
            tmp <= '0';
        end if;
    end if;
    end process;


  TCS_control : process (EXP_CLK)
    BEGIN
      if EXP_CLK'event AND EXP_CLK = '1' then  --CLK 40 MHz

        if BC_count = 0 then                                -- potrei anche antipipare ad uno ...
          SERLYZER_DONE <= '1';                             -- ho letto tutto l'ultimo trigger e sono disponibile
        else
          SERLYZER_DONE <= '0';
        end if;

        RD_TYPE     <= '0';
        trigger_i   <= tmp;

        case (state) is
          when st_sleep =>
          
            RD_TYPE     <= '0';
            state       <= st_sleep;

            if EMPTY_i = '0' and SERLYZER_DONE = '1' then   -- quando ho un trigger nella fifo passo in st_read
              state     <= st_read;
            end if;

          when st_read =>

            RD_TYPE     <= '1';
            state       <= st_wait;

          when st_wait =>

            RD_TYPE     <= '0';
            state       <= st_wait;
            if SERLYZER_DONE = '0' then --sempre direi
              state     <= st_sleep;
            end if;
            

          when others =>
          
            RD_TYPE     <= '0';
            state       <= st_sleep;


        end case;

      end if;


  end process;


end Behavioral;
