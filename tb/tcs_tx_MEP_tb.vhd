--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   14:29:06 02/01/2023
-- Design Name:   
-- Module Name:   C:/Users/fragb/OneDrive - Istituto Nazionale di Fisica Nucleare/Xil_14.7/GandArw/par/tcs_tx_MEP_tb.vhd
-- Project Name:  gandarw
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: tcs_tx_mep
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY tcs_tx_MEP_tb IS
END tcs_tx_MEP_tb;
 
ARCHITECTURE behavior OF tcs_tx_MEP_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT tcs_tx_mep
    GENERIC(
        BS_GIMLI_TYPE   : string
        );
    PORT(
         RESET          : in  std_logic;
         TRIGGER        : in  std_logic;
         TCS_CLK        : in  std_logic;
         EVENT_TYPE     : in  std_logic_vector(7 downto 0);
         WR_TYPE        : in  std_logic;
         TCS_CLK_P      : out std_logic;
         TCS_CLK_N      : out std_logic;
         TCS_DATA_P     : out std_logic;
         TCS_DATA_N     : out std_logic
        );
    END COMPONENT;
    

    --Inputs
    signal RESET         : std_logic := '1';
    signal TRIGGER       : std_logic := '0';
    signal TCS_CLK       : std_logic := '0';
    signal EV_TYPE_IN    : std_logic_vector(7 downto 0) := (others => '0');
    signal WR_TYPE       : std_logic := '0';

    --Outputs
    signal TCS_CLK_P     : std_logic;
    signal TCS_CLK_N     : std_logic;
    signal TCS_DATA_P    : std_logic;
    signal TCS_DATA_N    : std_logic;
    
    -- Clock period definitions
    constant CLK_155MHz_period   : time := 6.238 ns;     -- NA62 clock = 160.312 MHz
    constant CLK_40MHz_period    : time := 24.952 ns;
    constant CLK_period          : time := 10 ns;        -- generic clock
    
    -- Alias
    constant Idle_Type      : std_logic_vector(7 downto 0) := b"000000_00";
    constant Ptrg_Type      : std_logic_vector(7 downto 0) := b"010000_00";
    constant Sync_Type      : std_logic_vector(7 downto 0) := b"100000_00";
    constant Reserv_Type    : std_logic_vector(7 downto 0) := b"100001_01";
    constant SoB_Type       : std_logic_vector(7 downto 0) := b"100010_11";
    constant EoB_Type       : std_logic_vector(7 downto 0) := b"100011_10";
    constant Con_Type       : std_logic_vector(7 downto 0) := b"100100_00";
    constant Coff_Type      : std_logic_vector(7 downto 0) := b"100101_00";
    constant Eon_Type       : std_logic_vector(7 downto 0) := b"100110_00";
    constant Eoff_Type      : std_logic_vector(7 downto 0) := b"100111_00";
    constant Mon_Type       : std_logic_vector(7 downto 0) := b"101000_00";
    constant Rnd_Type       : std_logic_vector(7 downto 0) := b"101100_00";
    constant Cal_Type       : std_logic_vector(7 downto 0) := b"110000_00";
    
    constant EcRst_Type     : std_logic_vector(7 downto 0) := b"000000_10";
    constant BcRst_Type     : std_logic_vector(7 downto 0) := b"000000_01";

    COMPONENT tcs_if_MEP
    PORT(
        TCS_CLK         : in  std_logic;
        TCS_DATA        : in  std_logic;
        FR_BOS          : in  std_logic;
        FR_EOS          : in  std_logic;
        FR_TRG          : in  std_logic;
        readout_rdy     : in  std_logic;
        FIFO_RDCLK      : in  std_logic;
        FIFO_RDEN       : in  std_logic;
        TIMESTAMP_RDEN  : in  std_logic;          
        SYNCED          : out std_logic;
        CLK38EN         : out std_logic;
        BOS             : out std_logic;
        EOS             : out std_logic;
        FLT             : out std_logic;
        EVENT_NO        : out std_logic_vector(23 downto 0);
        SPILL_NO        : out std_logic_vector(10 downto 0);
        EVENT_TYPE      : out std_logic_vector(7 downto 0);
        FIFO_EMPTY      : out std_logic;
        FIFO_FULL       : out std_logic;
        TIMESTAMP       : out std_logic_vector(31 downto 0)
        );
    END COMPONENT;

   --Inputs
   signal FIFO_RDCLK        : std_logic := '0';
   signal FIFO_RDEN         : std_logic := '0';
   signal TIMESTAMP_RDEN    : std_logic := '0';

   --Outputs
   signal SYNCED            : std_logic;
   signal CLK38EN           : std_logic;
   signal BOS               : std_logic;
   signal EOS               : std_logic;
   signal FLT               : std_logic;
   signal EVENT_NO          : std_logic_vector(23 downto 0);
   -- signal SPILL_NO          : std_logic_vector(10 downto 0);
   signal EVENT_TYPE        : std_logic_vector(7 downto 0); 
   signal FIFO_EMPTY        : std_logic;                    
   signal FIFO_FULL         : std_logic;                    
   signal TIMESTAMP         : std_logic_vector(31 downto 0); 
   
                                                                          
BEGIN
 

    Inst_tcs_tx_MEP : tcs_tx_mep 
    GENERIC MAP(
        BS_GIMLI_TYPE => "TCS"
        )
    PORT MAP (
        RESET           => RESET,
        TRIGGER         => TRIGGER,
        TCS_CLK         => TCS_CLK,
        EVENT_TYPE      => EV_TYPE_IN,
        WR_TYPE         => WR_TYPE,
        TCS_CLK_P       => TCS_CLK_P,
        TCS_CLK_N       => TCS_CLK_N,
        TCS_DATA_P      => TCS_DATA_P,
        TCS_DATA_N      => TCS_DATA_N
        );

    -- Clock process definitions
    TCS_CLK_process :process
    begin
        TCS_CLK <= '0';
        wait for CLK_155MHz_period/2;
        TCS_CLK <= '1';
        wait for CLK_155MHz_period/2;
    end process;
    
    FIFO_CLK_process :process
    begin
        FIFO_RDCLK <= '0';
        wait for CLK_period/2;
        FIFO_RDCLK <= '1';
        wait for CLK_period/2;
    end process;
 
    Inst_tcs_if_MEP: tcs_if_MEP PORT MAP(
        TCS_CLK         => TCS_CLK_P,
        TCS_DATA        => TCS_DATA_P,
        FR_BOS          => '0',
        FR_EOS          => '0',
        FR_TRG          => '0',
        readout_rdy     => '1',
        FIFO_RDCLK      => FIFO_RDCLK,
        FIFO_RDEN       => FIFO_RDEN,
        TIMESTAMP_RDEN  => TIMESTAMP_RDEN,
        SYNCED          => SYNCED,
        CLK38EN         => CLK38EN,
        BOS             => BOS,
        EOS             => EOS,
        FLT             => FLT,
        EVENT_NO        => EVENT_NO,
        SPILL_NO        => open,
        EVENT_TYPE      => EVENT_TYPE,
        FIFO_EMPTY      => FIFO_EMPTY,
        FIFO_FULL       => FIFO_FULL,
        TIMESTAMP       => TIMESTAMP     
    );
    
   FIFO_RDEN <= not FIFO_EMPTY;
   TIMESTAMP_RDEN <= not FIFO_EMPTY;

   -- Stimulus process
    stim_proc: process
    begin        
    -- hold reset state for 100 ns.
    wait for 100 ns; 
    RESET <= '0';
    -- Start sim ...    
    --EV_TYPE_IN <= Idle_Type;  TRIGGER <= '0'; wait for CLK_155MHz_period * 20; 
    wait until SYNCED = '1';
    wait for 1 ns;
    EV_TYPE_IN <= SoB_Type;   TRIGGER <= '1'; WR_TYPE <= '1'; wait for CLK_155MHz_period; WR_TYPE <= '0'; wait for CLK_40MHz_period * 20; -- Start of Burst
    EV_TYPE_IN <= EoB_Type;   TRIGGER <= '1'; WR_TYPE <= '1'; wait for CLK_155MHz_period; WR_TYPE <= '0'; wait for CLK_40MHz_period * 20; -- End of Burst
    -- wait;
    EV_TYPE_IN <= Ptrg_Type;  TRIGGER <= '1'; WR_TYPE <= '1'; wait for CLK_155MHz_period; WR_TYPE <= '0'; wait for CLK_40MHz_period * 12; -- Physics Trigger 1 ...
    EV_TYPE_IN <= Ptrg_Type;  TRIGGER <= '1'; WR_TYPE <= '1'; wait for CLK_155MHz_period; WR_TYPE <= '0'; wait for CLK_40MHz_period * 20; -- Physics Trigger 2 after 75 ns 
    EV_TYPE_IN <= Sync_Type;  TRIGGER <= '1'; WR_TYPE <= '1'; wait for CLK_155MHz_period; WR_TYPE <= '0'; wait for CLK_40MHz_period * 20; -- Synchronization Trigger  
    EV_TYPE_IN <= Sync_Type;  TRIGGER <= '1'; WR_TYPE <= '1'; wait for CLK_155MHz_period; WR_TYPE <= '0'; wait for CLK_40MHz_period * 20;
    -- wait;
    EV_TYPE_IN <= BcRst_Type; TRIGGER <= '0'; WR_TYPE <= '1'; wait for CLK_155MHz_period; WR_TYPE <= '0'; wait for CLK_40MHz_period * 20; -- Send BCRST only
    EV_TYPE_IN <= EcRst_Type; TRIGGER <= '0'; WR_TYPE <= '1'; wait for CLK_155MHz_period; WR_TYPE <= '0'; wait for CLK_40MHz_period * 20; -- Send ECRST only

      wait;
   end process;

END;
