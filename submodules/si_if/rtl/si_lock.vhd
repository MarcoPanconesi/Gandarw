--   __| _ _|   __| \ \    / __|  __|  _ \
-- \__ \   |  \__ \  \ \ \  /  _|   _|   __/
-- ____/ ___| ____/ \_/\_/  ___| ___| _|
-- Locks the Phase of SI Chips to TCS Clock.
-- Engineer: Paul Kremser

library UNISIM;
use UNISIM.VComponents.all;

library UNIMACRO;
use UNIMACRO.vcomponents.all;

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use work.g_parameters.all;


entity si_lock is
  generic (GEN_N_STATS        : integer := 1000;
           GEN_DEVICE         : string  := "VIRTEX5";
           GEN_MAX_CRIT_MULTI : integer := 15;
           GEN_MAX_CRIT_DIV   : integer := 4);
  port (
    RESET_i   : in std_logic;           -- active High RESET
    CLK_TCS_i : in std_logic;  -- TCS Clock. This is the Clock we lock phase to
    CE_TCS_i  : in std_logic;           --  Clock Enable for TCS Clock
    CLK_SI_i  : in std_logic;           --  SI Clock, to be phase locked
    SWEEP_i   : in std_logic;           -- Start Phase Lock Process

    REQ_STEP_o : out std_logic_vector(1 downto 0);  -- Request a SI
    -- step, rotary encoded!
    ACK_STEP_i : in  std_logic;         -- Acknowlege Finished SI step

    BUSY_o      : out std_logic;        -- sweep done
    OOP_o       : out std_logic;        -- out of phase
    LOCK_DATA_o : out std_logic_vector(18 downto 0);  -- n_sweep_steps, n_hits for cfmem
    LOCK_PEAK_o : out std_logic_vector(29 downto 0)
    );
end si_lock;

architecture Behavioral of si_lock is

  type   state_type is (reset, sleep, w8_stats, test_gauss, w8_sweep, w8_multi, w8_calc, final_align);
  signal state : state_type := reset;

  --   __| _ _| __|   \ |  \    |    __|
  -- \__ \   |   (_ |  .  | _ \   |    \__ \
  -- ____/ ___| \___| _|\_| _/  _\ ____| ____/

  signal ack_i : std_logic := '0';

  signal CE   : std_logic := '0';       -- the divided clock
  signal busy : std_logic := '0';       -- the internal busy signal


  signal SI_CLK_D, SI_CLK_UD          : std_logic := '0';  -- delay lines
  signal LOCK_SIGNAL_A, LOCK_SIGNAL_B : std_logic := '0';  -- the lock signals

  signal start_sweep          : std_logic := '0';  -- internal start signal
  signal new_stats            : std_logic := '0';  -- signals new Statistics
  signal gauss_check_multiply : std_logic := '0';

  signal n_hits : unsigned(13 downto 0) := (others => '0');  -- the actual statistics

  type   stats_sr_type is array (2 downto 0) of unsigned(9 downto 0);
  signal stats_sr      : stats_sr_type        := (others => (others => '0'));
  signal n_sweep_steps : unsigned(7 downto 0) := (others => '0');  -- 256 steps possiple

  signal r_max_saved     : unsigned(9 downto 0)          := (others => '0');
  signal reduced_maximum : std_logic_vector(17 downto 0) := (others => '0');

  signal step         : integer range 0 to 3 := 0;
  signal ack_step_old : std_logic            := '0';
  signal state_o      : std_logic_vector(2 downto 0);
  signal r_max        : signed(10 downto 0)  := (others => '0');
  signal l_diff       : signed(10 downto 0)  := (others => '0');
  signal r_diff       : signed(10 downto 0)  := (others => '0');

begin
--  _ )  __|   __| _ _|   \ |
--  _ \  _|   (_ |   |   .  |
-- ___/ ___| \___| ___| _|\_|

  BUSY_o <= busy;

  state_machine : process(CLK_TCS_i)
  begin
    if (rising_edge(CLK_TCS_i) and (CE = '1')) then

      case step is
        when 0 =>
          REQ_STEP_o <= "00";
        when 1 =>
          REQ_STEP_o <= "01";
        when 2 =>
          REQ_STEP_o <= "11";
        when 3 =>
          REQ_STEP_o <= "10";
      end case;

      ack_i <= ACK_STEP_i;

      busy                 <= '1';
      gauss_check_multiply <= '0';

      case state is
        --  _ \  __|   __|  __| __ __|
        --    /  _|  \__ \  _|     |
        -- _|_\ ___| ____/ ___|   _|
        when reset =>                   --> sleep
          OOP_o         <= '1';
--          REQ_STEP_o    <= '0';
          busy          <= '0';
          LOCK_DATA_o   <= (others => '0');
          LOCK_PEAK_o   <= (others => '0');
          n_sweep_steps <= (others => '0');
          if RESET_i = '0' then
            state <= sleep;
          end if;
          --   __|  |   __|  __|  _ \
          -- \__ \  |   _|   _|   __/
          -- ____/____|___| ___| _|
        when sleep =>                   --> w8_stats
          busy <= '0';
          if SWEEP_i = '1' then
            state <= w8_stats;
          end if;
          if (new_stats = '1') then
            -- here the actual hits are divided by 16 in LOCK_DATA
            LOCK_DATA_o(9 downto 0) <= std_logic_vector(n_hits(13 downto 4));
          end if;
          if (n_hits = 0) then
            OOP_o <= '1';
          else
            OOP_o <= '0';
          end if;
          -- \ \    / _ )   __| __ __|  \ __ __| __|
          --  \ \ \  /  _ \ \__ \  |   _ \   | \__ \
          --   \_/\_/ \___/ ____/ _| _/  _\ _| ____/
        when w8_stats =>                --> test_gauss
          if (new_stats = '1') then
            stats_sr(2)          <= stats_sr(1);
            stats_sr(1)          <= stats_sr(0);
            -- here the actual hits are divided by 16 in stats_sr
            stats_sr(0)          <= n_hits(13 downto 4);
            gauss_check_multiply <= '1';
            state                <= w8_multi;
          end if;
        when w8_multi =>
          r_max       <= signed('0' & reduced_maximum(13 downto 4));
          r_max_saved <= unsigned('0' & reduced_maximum(12 downto 4));  -- for write to cfmem
          state       <= w8_calc;
        when w8_calc =>
          l_diff <= signed('0' & stats_sr(2)) - r_max;
          r_diff <= signed('0' & stats_sr(0)) - r_max;
          state  <= test_gauss;
          -- __ __| __| __| __ __|     __|    \    |  |   __| __|
          --    |   _|  \__ \    |    (_ |   _ \   |  | \__ \ \__ \
          --   _|  ___| ____/   _|   \___| _/  _\ \__/  ____/ ____/
        when test_gauss =>              --> final_align || w8_sweep
          if (((r_diff < 0) and (l_diff < 0) and (n_sweep_steps > 5)) or (n_sweep_steps = 127)) then
            -- we are done           --> final_align
            step  <= step - 1;
            state <= final_align;
          else
            -- we have to search more    --> w8_sweep
            step  <= step + 1;
            state <= w8_sweep;
          end if;
--\ \      / _ )    __|\ \      /__|  __|  _ \
-- \ \ \  /  _ \  \__ \ \ \    / _|   _|   __/
--  \_/\_/ \___/  ____/  \_/\_/ ___| ___| _|
        when w8_sweep =>                --> w8_stats
          if ack_i /= ack_step_old then
            ack_step_old  <= ack_i;
            n_sweep_steps <= n_sweep_steps + "1";
            state         <= w8_stats;
          end if;
          --  __|_ _|  \ |   \   |     \   |   _ _|  __|  \ |
          --  _|   |  .  |  _ \  |    _ \  |   |  (_ | .  |
          -- _|  ___|_|\_|_/  _\____| _/  _\____|___|\___|_|\_|
        when final_align =>             --> sleep
          if ack_i /= ack_step_old then
            ack_step_old  <= ack_i;
            n_sweep_steps <= n_sweep_steps - "1"; 
            state         <= sleep;
          end if;
          LOCK_PEAK_o <= (std_logic_vector(stats_sr(2))) &
                         (std_logic_vector(stats_sr(1))) &
                         (std_logic_vector(stats_sr(0)));
          LOCK_DATA_o(17 downto 10) <= std_logic_vector(n_sweep_steps - 1);
        when others =>                  --> reset
          state <= reset;
      end case;
    end if;
  end process;

  CE <= CE_TCS_i;
-- _ _|   \ | __| __ __|  \   \ | __|  __|   __|
--   |   .  | \__ \    |   _ \   .  |  (   _|  \__ \
-- ___| _|\_| ____/   _| _/  _\ _|\_| \___| ___| ____/

  inst_si_sweep_stats : entity work.si_sweep_stats
    generic map (
      GEN_N_STATS => gs_n_sweep_stats ,
      GEN_DEVICE  => "VIRTEX5")
    port map (
      CLK_i => CLK_TCS_i,
      CE_i  => CE,
      LSA_i => LOCK_SIGNAL_A,
      LSB_i => LOCK_SIGNAL_B,
      ACK_o => new_stats,
      CNT_o => n_hits
      );

  inst_gauss_check_multiplier : MULT_MACRO
    generic map (
      DEVICE  => GEN_DEVICE,  -- Target Device: "VIRTEX5", "VIRTEX6", "SPARTAN6"
      LATENCY => 0,                     -- Desired clock cycle latency, 0-4
      WIDTH_A => 10,                    -- Multiplier A-input bus width, 1-25
      WIDTH_B => 8)                     -- Multiplier B-input bus width, 1-18
    port map (
      P   => reduced_maximum,  -- Multiplier output bus, width determined by WIDTH_P generic
      A   => std_logic_vector(stats_sr(1)),  -- Multiplier input A bus, width determined by WIDTH_A generic
      B   => std_logic_vector(to_unsigned(GEN_MAX_CRIT_MULTI, 8)),  -- Multiplier input B bus, width determined by WIDTH_B generic
      CE  => gauss_check_multiply,      -- 1-bit active high input clock enable
      CLK => CLK_TCS_i,                 -- 1-bit positive edge clock input
      RST => RESET_i                    -- 1-bit input active high reset
      );
-- End of MULT_MACRO_inst instantiation

  undelayed_ff : FDRE
    generic map (
      INIT => '0')          -- Initial value of register ('0' or '1')
    port map (
      Q  => LOCK_SIGNAL_A,              -- Data output
      C  => CLK_TCS_i,                  -- Clock input
      CE => CE,                         -- Clock enable input
      R  => RESET_i,                    -- Synchronous reset input
      D  => SI_CLK_UD                   -- Data input
      );

  delayed_ff : FDRE
    generic map (
      INIT => '0')          -- Initial value of register ('0' or '1')
    port map (
      Q  => LOCK_SIGNAL_B,              -- Data output
      C  => CLK_TCS_i,                  -- Clock input
      CE => CE,                         -- Clock enable input
      R  => RESET_i,                    -- Synchronous reset input
      D  => SI_CLK_D                    -- Data input
      );

  undelayed_delay : IODELAY
    generic map (
      DELAY_SRC             => "DATAIN",  -- Specify which input port to be used:
      -- "I"=IDATAIN, "O"=ODATAIN, "DATAIN"=DATAIN, "IO"=Bi-directional
      HIGH_PERFORMANCE_MODE => true,  -- TRUE specifies lower jitter at expense of more power
      IDELAY_TYPE           => "FIXED",  -- "FIXED" or "VARIABLE"
      IDELAY_VALUE          => 2,       -- 0 to 63 tap values (78 ps per tap)
      ODELAY_VALUE          => 0,       -- 0 to 63 tap values
      REFCLK_FREQUENCY      => 200.0,  -- Frequency[Mhz] used for IDELAYCTRL from 175.0 to 225.0
      SIGNAL_PATTERN        => "CLOCK")  -- Input signal type, "CLOCK" or "DATA" (consider more jitter for data in tc)
    port map (
      DATAOUT => SI_CLK_D,              -- 1-bit delayed data output
      C       => '0',                   -- 1-bit clock input
      CE      => '0',                   -- 1-bit clock enable input
      DATAIN  => CLK_SI_i,              -- 1-bit internal data input
      IDATAIN => '0',  -- 1-bit input data input (connect to port)
      INC     => '0',                   -- 1-bit increment/decrement input
      ODATAIN => '0',                   -- 1-bit output data input
      RST     => RESET_i,               -- 1-bit active high, synch reset input
      T       => '1'                    -- 1-bit 3-state control input
      );

  delayed_delay : IODELAY
    generic map (
      DELAY_SRC             => "DATAIN",  -- Specify which input port to be used:
      -- "I"=IDATAIN, "O"=ODATAIN, "DATAIN"=DATAIN, "IO"=Bi-directional
      HIGH_PERFORMANCE_MODE => true,  -- TRUE specifies lower jitter at expense of more power
      IDELAY_TYPE           => "FIXED",  -- "FIXED" or "VARIABLE"
      IDELAY_VALUE          => 0,       -- 0 to 63 tap values
      ODELAY_VALUE          => 0,       -- 0 to 63 tap values
      REFCLK_FREQUENCY      => 200.0,  -- Frequency[Mhz] used for IDELAYCTRL from 175.0 to 225.0
      SIGNAL_PATTERN        => "CLOCK")  -- Input signal type, "CLOCK" or "DATA" (consider more jitter for data in tc)
    port map (
      DATAOUT => SI_CLK_UD,             -- 1-bit delayed data output
      C       => '0',                   -- 1-bit clock input
      CE      => '0',                   -- 1-bit clock enable input
      DATAIN  => CLK_SI_i,              -- 1-bit internal data input
      IDATAIN => '0',  -- 1-bit input data input (connect to port)
      INC     => '0',                   -- 1-bit increment/decrement input
      ODATAIN => '0',                   -- 1-bit output data input
      RST     => RESET_i,               -- 1-bit active high, synch reset input
      T       => '1'                    -- 1-bit 3-state control input
      );
end Behavioral;
