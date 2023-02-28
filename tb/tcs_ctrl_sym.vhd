----------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:    08:12:07 07/01/2009
-- Design Name:
-- Module Name:    tcs_ctrl_sym - Behavioral
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
USE IEEE.NUMERIC_STD.ALL;
USE WORK.TOP_LEVEL_DESC.ALL;
USE WORK.G_PARAMETERS.ALL;

--use IEEE.STD_LOGIC_ARITH.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

ENTITY tcs_ctrl_sym IS

  GENERIC(
    GEN_CAL_TRG_TYPE  : STD_LOGIC_VECTOR(4 downto 0):="11010";
    GEN_CAL_SL_OUTPUT :   boolean := FALSE; --generate SLINK output on calibration trigger
    GEN_BOR_CNT     : integer range 0 to 255 :=10;
    GEN_BOS_CNT     :   integer range 0 to 255 :=50;
    GEN_CALIB_CNT   :   integer range 0 to 255 :=50
    );
  PORT (
    TRIGGER     : IN  STD_LOGIC;
    TCS_CLK     : IN  STD_LOGIC;
    BOR         : IN  STD_LOGIC;
    EOR         : IN  STD_LOGIC;
    BOS         : IN  STD_LOGIC;
    EOS         : IN  STD_LOGIC;
    EVENT_TYPE  : OUT STD_LOGIC_VECTOR(4 downto 0);
    TCS_CLK_P   : OUT STD_LOGIC;
    TCS_CLK_N   : OUT STD_LOGIC;
    TCS_DATA_P  : OUT STD_LOGIC;
    TCS_DATA_N  : OUT STD_LOGIC
    );

END tcs_ctrl_sym;

architecture Behavioral of tcs_ctrl_sym is

  SIGNAL  TCS_DATA_i    : STD_LOGIC:='0';
  SIGNAL  CH_CLK      :   STD_LOGIC := '1';
  SIGNAL  EXP_CLK       : STD_LOGIC:='0';

  SIGNAL  sel         : integer range 0 to 3   :=0;
  SIGNAL  bos_sel       : integer range 0 to 7   :=0;
  SIGNAL  bos_status    : integer range 0 to 7   :=0;
  SIGNAL  BC_count    : integer range 0 to 63  :=0;
  signal  flt_cnt     :   integer range 0 to 255 :=0;

  signal  bor_cnt     :   integer range 0 to 255 :=GEN_BOR_CNT;
  signal  bos_cnt     :   integer range 0 to 255 :=GEN_BOS_CNT;
  signal  calib_cnt   :   integer range 0 to 255 :=GEN_CALIB_CNT;

  SIGNAL  shiftReg      : STD_LOGIC_VECTOR(31 downto 0) :=(others =>'0');

  SIGNAL  EVENT_NUMBER  :   UNSIGNED(19 downto 0):= (others => '0');
  SIGNAL  SPILL_NUMBER  :   UNSIGNED(10 downto 0):= "000" & X"00"; --(others => '0');
  SIGNAL  EVENT_TYPE_i  : STD_LOGIC_VECTOR(4 downto 0):= "11010";
  SIGNAL  ON_SPILL      : STD_LOGIC:='0';
  SIGNAL   INIT_SPILL   :   STD_LOGIC:='0';

  signal  SERLYZER_DONE : STD_LOGIC :='0';
  signal  EMPTY_REG   :   STD_LOGIC :='0';
  signal  MEM_FLT     : STD_LOGIC :='0';
  signal  MEM_BOS     :   STD_LOGIC :='0';
  signal  MEM_EOS     :   STD_LOGIC :='0';
  signal  EOS_i       :   STD_LOGIC :='0';
  signal  RUN       :   STD_LOGIC :='0';
  signal  CALIB_BUSY    :   STD_LOGIC :='0';
  signal  trigger_i   :   STD_LOGIC :='0';

  type    tcs_state   is (  st_sleep,
                      st_offspill,
                      st_calibration,
                      st_accept_trigger,
                      st_serlyzer_busy );

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


  EVENT_TYPE  <=  EVENT_TYPE_i;
  TCS_clk_p <= TCS_clk;
  TCS_clk_n   <=  not TCS_clk;

  create_CH_CLK: process (TCS_CLK)
    begin
      if (TCS_CLK='1' and TCS_CLK'event ) then
        CH_CLK <=NOT CH_CLK;

      end if;
    end process;


  create_EXP_CLK: process (CH_CLK)
    begin
      if (CH_CLK='0' and CH_CLK'event ) then
        EXP_CLK <=NOT EXP_CLK;

      end if;
    end process;


  create_TCSdata_B_ch: process (EXP_CLK)
    begin
      if (EXP_CLK='1' and EXP_CLK'event ) then
        --Serializer
        shiftReg<=shiftReg(30 downto 0) & '0';

        if BC_count>0 then
          BC_count<=BC_count-1;
        end if;

        if MEM_FLT = '1' then
          shiftReg(31 downto 0)<= b"0001" & b"0110" & std_logic_vector(EVENT_NUMBER(7 downto 0)) & b"000" & EVENT_TYPE_i & b"00000000"; --BC2_1
          if to_integer(EVENT_NUMBER(7 downto 0)) = 0 then
            BC_count<=63;
          else
            BC_count<=31;
          end if;

        end if;

        if BC_count = 32 then
          shiftReg(31 downto 0)<= b"0001" & b"0111" & "0000" & std_logic_vector(EVENT_NUMBER(19 downto 8)) & b"00000000"; --BC2_2
        end if;

        if MEM_EOS = '1' then
          shiftReg(31 downto 0) <= b"0001" & b"00010" & b"10" & b"00" & std_logic_vector(SPILL_NUMBER) & b"00000000"; --BC1
          BC_count<=31;
        end if;

        if MEM_BOS = '1' then
          shiftReg(31 downto 0)<= b"0001" & b"00010" & b"01" & b"00" & std_logic_vector(SPILL_NUMBER) & b"00000000"; --BC1
          BC_count<=31;
        end if;

        if EMPTY_REG = '1' then
          shiftReg(31 downto 0)<= (others => '0');
          BC_count<=31;
        end if;

      end if;

    end process;


  --merge A B channels

  merge_AB_channels: process(TCS_CLK)
    begin
      if TCS_CLK='1' and TCS_CLK'event then

        case sel is
          when 0 | 2 =>
            TCS_DATA_i <= not TCS_DATA_i;
            sel <= sel + 1;
          when 1 =>
            TCS_DATA_i <= TCS_DATA_i xnor trigger_i;
            sel <= sel + 1;
          when 3 =>
            TCS_DATA_i <= TCS_DATA_i xnor shiftReg(31);
            sel <= 0;
        end case;

      end if;

  end process;


  TCS_control : process (EXP_CLK)
    BEGIN
      if EXP_CLK'event AND EXP_CLK = '1' then

        if BC_count = 1 then
          SERLYZER_DONE <= '1';

        else
          SERLYZER_DONE <= '0';

        end if;

        if EOR = '1' then
          RUN <= '0';
        end if;

        EMPTY_REG <= '0';
        MEM_FLT <= '0';
        MEM_BOS <= '0';
        MEM_EOS <= '0';
        trigger_i <= '0';

        case (state) is
          when st_sleep =>
            if BOR = '1' then
              RUN <= '1';
              SPILL_NUMBER <= (others => '0');

            elsif RUN = '1' then
              if bor_cnt = 0 then
                bor_cnt <= GEN_BOR_CNT;
                state <= st_offspill;

              else
                bor_cnt <= bor_cnt - 1;

              end if;

            end if;

          when st_calibration =>

            CALIB_BUSY <= '1';

            if calib_cnt = 0 then
              calib_cnt <= GEN_CALIB_CNT;
              MEM_FLT <= '1';
              trigger_i <= '1';
              EVENT_NUMBER <= EVENT_NUMBER + 1;
              EVENT_TYPE_i <= GEN_CAL_TRG_TYPE; --CAL_TRIGGER
              state <= st_serlyzer_busy;

            else
              calib_cnt <= calib_cnt - 1;

            end if;

          when st_offspill =>
               case (bos_sel) is
                when 0 =>
                  bos_status <= 0;
                  if BOS = '1' then
                    bos_sel <= 1;
                  end if;

                when 1 =>
                  if bos_cnt = 0 then
                    bos_cnt <=  GEN_BOS_CNT;
                    bos_status <= bos_sel + 1;
                    bos_sel <= 4;
                    if RUN = '0' then
                      EVENT_TYPE_i <= "11101"; --LEOR
                      MEM_FLT <= '1';
                      trigger_i <= '1';
                      EVENT_NUMBER <= EVENT_NUMBER + 1;

                    elsif to_integer(SPILL_NUMBER(10 downto 0)) > 0 then
                      EVENT_TYPE_i <= "11111"; --LEOS
                      MEM_FLT <= '1';
                      trigger_i <= '1';
                      EVENT_NUMBER <= EVENT_NUMBER + 1;

                    else
                      EMPTY_REG <= '1';

                    end if;

                  else
                    bos_cnt <= bos_cnt - 1;
                  end if;

                when 2 =>
                  if bos_cnt = 0 then
                    bos_cnt <=  GEN_BOS_CNT;
                    bos_status <= bos_sel + 1;
                    bos_sel <= 4;
                    MEM_BOS <= '1';
                    SPILL_NUMBER <= SPILL_NUMBER + 1;

                  else
                    bos_cnt <= bos_cnt - 1;

                  end if;

                when 3 =>
                  if bos_cnt = 0 then
                    bos_cnt <=  GEN_BOS_CNT;
                    bos_sel <= 0;
                    ON_SPILL <= '1';
                    if to_integer(SPILL_NUMBER(10 downto 0)) = 1 then
                      EVENT_TYPE_i <="11100"; --FEOR

                    else
                      EVENT_TYPE_i <="11110"; --FEOS

                    end if;
                    MEM_FLT <= '1';
                    trigger_i <= '1';
                    EVENT_NUMBER <= b"00000000000000000001";
                    state <= st_serlyzer_busy;

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
              MEM_EOS <= '1';
              ON_SPILL <= '0';
              state <= st_serlyzer_busy;

            elsif TRIGGER = '1' then
              trigger_i <= '1';
              MEM_FLT<='1';
              EVENT_NUMBER <= EVENT_NUMBER + 1;
              EVENT_TYPE_i <= "00000"; --TRIGGER
              state <= st_serlyzer_busy;
            end if;

          when st_serlyzer_busy =>
            if EOS = '1' then
              EOS_i <= '1';
            end if;

            if TRIGGER = '1' and EOS_i = '0' and  ON_SPILL = '1' then
              trigger_i <= '1';
              flt_cnt <= flt_cnt + 1;
            end if;

            if SERLYZER_DONE = '1' then
              if ON_SPILL = '0' then
                if CALIB_BUSY = '0' then
                  state <= st_calibration;
                else
                  state <= st_offspill;
                  CALIB_BUSY <= '0';
                end if;

              elsif flt_cnt > 0 and (TRIGGER = '0' or EOS_i = '1') then
                MEM_FLT <= '1';
                EVENT_NUMBER <= EVENT_NUMBER + 1;
                EVENT_TYPE_i <= "00000"; --TRIGGER
                flt_cnt <= flt_cnt - 1;

              elsif (flt_cnt = 0 nand TRIGGER = '0') and EOS_i = '0' then
                MEM_FLT <= '1';
                EVENT_NUMBER <= EVENT_NUMBER + 1;
                EVENT_TYPE_i <= "00000"; --TRIGGER
                flt_cnt <= flt_cnt;

              elsif EOS_i = '1' or EOS = '1' then
                MEM_EOS <= '1';
                EOS_i <= '0';
                ON_SPILL <= '0';

              else
                state <= st_accept_trigger;
              end if;

            end if;

          when others =>
            RUN <= '0';
            ON_SPILL <= '0';
            state <= st_sleep;

        end case;

      end if;


  end process;


end Behavioral;
