-- vsg_off
--------------------------------------------------------------------------------
-- Company:
-- Engineer:
--
-- Create Date:   16:40:27 09/07/2010
-- Design Name:
-- Module Name:   I:/xilinxProjects/12.2/PatternGenerator/rtl/PatGen_TDC_tb.vhd
-- Project Name:  PatternGenerator
-- Target Device:
-- Tool versions:
-- Description:
--
-- VHDL Test Bench Created by ISE for module: g_patterngen
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Other Comments:
--
-- Notes:
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY UNISIM;
USE UNISIM.VCOMPONENTS.ALL;

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

-- LIBRARY GANDALF;
-- USE GANDALF.TOP_LEVEL_DESC.ALL;
-- use GANDALF.G_PARAMETERS.ALL;
-- use GANDALF.TB_PKG.all;

LIBRARY WORK;
USE WORK.TOP_LEVEL_DESC.ALL;
use WORK.G_PARAMETERS.ALL;
use WORK.TB_PKG.all;
use WORK.VME_PKG.all;
use WORK.FAST_REGISTER_PKG.all;

--------------------------------------------------------------------------------

ENTITY GANDALF_env IS
END GANDALF_env;

ARCHITECTURE behavior OF GANDALF_env IS

-------------------------------------------------------------------------------
--Records 
    signal vme_o                : r_vme_out := r_vme_out_default;   
    signal vme_i                : r_vme_in;    

-------------------------------------------------------------------------------
-- Components creates analog signal
    COMPONENT analog_signal IS
      GENERIC (
        SIMULATION_MODE         : string := "5MHz_p";
        GEN_TRIGGER_MASK_1      : real := 4.0;      --in us
        GEN_TRIGGER_MASK_3      : real := 40.0;     --in us
        GEN_TRIGGER_MASK_10     : real := 250.0;    --in us
        TRIGGER_RATE            : real := 100.0;    --in KHz
        MAX_EVENTS              : integer := 10
        );
      PORT (
        BOS                     : IN  std_logic;
        EOS                     : IN  std_logic;
        ONSPILL                 : IN  std_logic;
        TRIGGER_OUT             : OUT std_logic;
        ANALOG_out              : OUT analog_signals(ADC_CHANNELS-1 downto 0)
      );
    END COMPONENT;

  COMPONENT ROB
    GENERIC(
        SIMULATION_MODE         : string := "RPD_Readout";
                                --"DAC_CALIB" --for dac calibration
                                --"RPD_Readout" --for data rate stress, random trigger and pulses
                                --"REG_PULSES" --for timing resolution measurement

        GEN_RDM                 : std_logic_vector(3 downto 0);
        GEN_FEOR_SIZE           : integer := 35;
        GEN_FEOS_SIZE           : integer := 29;
        GEN_LEOR_SIZE           : integer := 7;
        GEN_LEOS_SIZE           : integer := 7;
        GEN_CE_SIZE             : integer := 7;
        GEN_CAL_TRG_TYPE        : std_logic_vector(4 downto 0):="11010";
        MAX_CAL_EVTS            : integer := 10;
        MAX_SPILLS              : integer := 2;
        MAX_RUNS                : integer := 1;
        MAX_EVENTS              : integer :=20;
        GEN_NOISE               : real  :=0.0015; --in Volt
        GEN_MAXAMP              : real  :=4.0;    --in Volt
        RUN_PAUSE               : real := 0.001;  --in ms
        SPILL_DURATION          : real := 0.1;  --in ms
        SPILL_PAUSE             : real := 0.005;  --in ms
        TRIGGER_RATE            : real := 50.0;   --in KHz
        GEN_ROB_DATA_LOC        : string  := "c:\data";
        GEN_FRAMEWIDTH          : integer :=100   --in # of ADC words
      );    
    PORT(   
        UD                      : in std_logic_vector (31 downto 0);
        LFF                     : in std_logic;
        URESET                  : in std_logic;
        UDW                     : in std_logic_vector (1 downto 0);
        UCTRL                   : in std_logic;
        UWEN                    : in std_logic;
        UCLK                    : in std_logic;
        LDOWN                   : in std_logic;
        UTEST                   : in std_logic;
        BOR                     : in std_logic;
        EOR                     : in std_logic;
        EOSHIFT                 : in std_logic:='0';
        EVENT_TYPE              : in std_logic_vector(4 downto 0)
      );
  END COMPONENT;

-- Modified for OCX Gimli ...
-- TCS_clock period definitions (155.52 MHz)
constant CLK_155MHz_period : time := 6.238 ns;  --NA62: clock = 160.312 MHz
constant CLK_40MHz_period    : time := 24.952 ns;
-- TCS_clock period definitions (20 MHz)
constant CLK_20MHz_period : time := 50 ns;

--BiDirs CPLD
    signal CA                   : std_logic_vector(31 downto 0) := (others => '0');
    signal CD                   : std_logic_vector(31 downto 0) := (others => 'Z');

--inputs CPLD       
    signal CAM                  : std_logic_vector(5 downto 0) := (others => '0');
    signal CAS                  : std_logic := '1';
    signal CDS0                 : std_logic := '1';
    signal CDS1                 : std_logic := '1';
    signal CWRITE               : std_logic := '0';

--outputs CPLD
    signal CDTACK               : std_logic;
    signal CBERR                : std_logic;


--GANDALF outputs
--(not used)
-- signal CONN_P_i             : DMC_ports(3 downto 0);
-- signal CONN_N_i             : DMC_ports(3 downto 0);
-- signal DMCinput_single      : DMC_ports(3 downto 0);
-- signal DMCoutput_single     : DMC_ports(3 downto 0);

--VXS data bus for a GANDALF
signal VXS_A_P_i            : std_logic_vector(7 downto 0):= (others => '0');
signal VXS_A_N_i            : std_logic_vector(7 downto 0):= (others => '0');

signal VXS_B_P_i            : std_logic_vector(7 downto 0):= (others => '0');
signal VXS_B_N_i            : std_logic_vector(7 downto 0):= (others => '0');

--16ch analog signal
signal analog_sig           : analog_signals(ADC_CHANNELS-1 downto 0);

------
signal count                : integer := 10;
constant cnt_rst            : integer := 10;

signal gp_pin_o             : std_logic_vector(4 downto 0);
signal dataout              : std_logic_vector(31 downto 0);

-- signal rst                  : std_logic; -- non usato !!! questi so' scemi ...

signal ONSPILL              : std_logic:= '0';

signal trg_cnt              : integer range 0 to 5:= 3;

--tcs signals
signal TB_CLK               : std_logic := '0';

--inputs
signal TCS_CLK              : std_logic := '0';
signal TRIGGER              : std_logic := '0';
signal BOR                  : std_logic := '0';
signal EOR                  : std_logic := '0';
signal BOS                  : std_logic := '0';
signal EOS                  : std_logic := '0';

    --outputs
signal  TCS_CLK_P_i,TCS_CLK_N_i,TCS_DATA_P_i,TCS_DATA_N_i : std_logic;
signal  EVENT_TYPE          : std_logic_vector(4 downto 0);
signal  clk5g               : std_logic := '0';
signal  clk5u               : std_logic := '1';
-- signal  clk180_sig : std_logic := '0';

constant clk5g_period       : time := 5 ns;
constant clk5u_period       : time := 6 ns;
--  constant clk180_period : time := 5555 ps;

--tipi di trigger
--constant Idle_Type      : std_logic_vector(7 downto 0) := b"000000_00";
constant Ptrg_Type      : std_logic_vector(7 downto 0) := b"010000_00";
constant Sync_Type      : std_logic_vector(7 downto 0) := b"100000_00";
constant Reserv_Type    : std_logic_vector(7 downto 0) := b"100001_00";
constant SoB_Type       : std_logic_vector(7 downto 0) := b"100010_00";
constant EoB_Type       : std_logic_vector(7 downto 0) := b"100011_00";
constant Con_Type       : std_logic_vector(7 downto 0) := b"100100_00";
constant Coff_Type      : std_logic_vector(7 downto 0) := b"100101_00";
constant Eon_Type       : std_logic_vector(7 downto 0) := b"100110_00";
constant Eoff_Type      : std_logic_vector(7 downto 0) := b"100111_00";
constant Mon_Type       : std_logic_vector(7 downto 0) := b"101000_00";
constant Rnd_Type       : std_logic_vector(7 downto 0) := b"101100_00";
constant Cal_Type       : std_logic_vector(7 downto 0) := b"110000_00";

constant EOB_HW     : std_logic_vector(7 downto 0) := b"000000_10";
constant BcRst_Type     : std_logic_vector(7 downto 0) := b"000000_01";
constant SOB_HW         : std_logic_vector(7 downto 0) := b"000000_11";


signal TRG_TYPE_IN       : std_logic_vector (7 downto 0);
signal WR_TYPE       : std_logic := '0';

BEGIN

    -- VME BUS SIGNAL for simulation 
    CA              <= vme_o.CA;    
    CD              <= vme_o.CD;        
    CAM             <= vme_o.CAM;   
    CAS             <= vme_o.CAS;   
    CDS0            <= vme_o.CDS0;  
    CDS1            <= vme_o.CDS1;  
    CWRITE          <= vme_o.CWRITE;

    vme_i.CDTACK    <= CDTACK;
    vme_i.CBERR     <= CBERR;    
    vme_i.CD        <= CD;


   clk5g_process :process
   begin
    clk5g <= '0';
    wait for clk5g_period/2;
    clk5g <= '1';
    wait for clk5g_period/2;
   end process;

   clk5u_process :process
   begin
    clk5u <= '0';
    wait for clk5u_period/2;
    clk5u <= '1';
    wait for clk5u_period/2;
   end process;


--    -- inst_tcs_ctrl: entity gandalf.tcs_ctrl_sym
--    inst_tcs_ctrl: entity work.tcs_ctrl_sym
--    PORT MAP (
--         TRIGGER         => TRIGGER,
--         TCS_CLK         => TCS_CLK,
--         BOR             => BOR,
--         EOR             => EOR,
--         BOS             => BOS,
--         EOS             => EOS,
--         EVENT_TYPE      => EVENT_TYPE,
--         TCS_CLK_P       => TCS_CLK_P_i,
--         TCS_CLK_N       => TCS_CLK_N_i,
--         TCS_DATA_P      => TCS_DATA_P_i,
--         TCS_DATA_N      => TCS_DATA_N_i
--   );

Inst_tcs_tx_MEP : entity work.tcs_tx_mep 
    GENERIC MAP(
        BS_GIMLI_TYPE => "TCS"
        )
    PORT MAP (
        RESET           => '0',
        TRIGGER         => TRIGGER,
        TCS_CLK         => TCS_CLK,
        EVENT_TYPE      => TRG_TYPE_IN,
        WR_TYPE         => WR_TYPE,
        TCS_CLK_P       => TCS_CLK_P_i,
        TCS_CLK_N       => TCS_CLK_N_i,
        TCS_DATA_P      => TCS_DATA_P_i,
        TCS_DATA_N      => TCS_DATA_N_i
        );

inst_tcs_trg: if BS_GIMLI_TYPE = "TCS" OR BS_GIMLI_TYPE = "VXS" generate
    CLK_tcs_process : process
    begin
        TCS_CLK <= '0';
        wait for CLK_155MHz_period/2;
        TCS_CLK <= '1';
        wait for CLK_155MHz_period/2;
    end process;
end generate;

inst_self_tcs: if BS_GIMLI_TYPE = "OCX" generate
    CLK_tcs_process : process
    begin
        TCS_CLK <= '0';
        wait for CLK_20MHz_period/2;
        TCS_CLK <= '1';
        wait for CLK_20MHz_period/2;
    end process;
end generate;

  CLK_TB_process : process
  begin
   TB_CLK <= '0';
   wait for CLK_155MHz_period/2;
   TB_CLK <= '1';
   wait for CLK_155MHz_period/2;
  end process;



  -- Instantiate the analog signal source
  inst_a_source: if BS_MCS_UP = "AMC" OR BS_MCS_DN = "AMC" generate
    inst_signal: analog_signal
    GENERIC MAP (
        SIMULATION_MODE => "5MHz_p" -- "5MHz_p"
    )
    PORT MAP (
        BOS             => BOS,
        EOS             => EOS,
        ONSPILL         => ONSPILL,
        trigger_out     => open,
        analog_out      => analog_sig
  );

  end generate;

---signal example connected to DMCs
-- (not used)
--  inst_DMC_conn: for DMC_conn in 0 to 3 generate
--  begin
--  inst_dmc_in: if (BS_MCS_UP = "DMC" AND DMC_conn <= 1) OR (BS_MCS_DN = "DMC" AND DMC_conn >= 2) generate
--
--      inst_DMC_ch: for DMC_ch in 0 to 31 generate
--      begin
--        DMCinput_single(DMC_conn)(DMC_ch)<= 'Z';
--      end generate;
--
--    end generate;
--
--  end generate;


--connect them to the DMCs
-- (not used)
--  inst_DMCout_conn: for DMC_conn in 0 to 3 generate
--  begin
--    inst_DMC_ch: for DMC_ch in 0 to 31 generate
--    begin
--        IOBUFDS_inst : IOBUFDS
--        generic map (
--          IOSTANDARD => "BLVDS_25")
--        port map (
--          O     => DMCoutput_single(DMC_conn)(DMC_ch),
--          IO    => CONN_P_i(DMC_conn)(DMC_ch),
--          IOB   => CONN_N_i(DMC_conn)(DMC_ch),
--          I     => DMCinput_single(DMC_conn)(DMC_ch),
--          T     => '0'                      -- 3-state enable input, high=input, low=output
--        );
--      end generate;
--  end generate;


  -- Instantiate the Unit Under Test (UUT)

  -- inst_G_module: entity gandalf.GANDALF_module
  inst_G_module: entity work.GANDALF_module
    Generic Map(
        GEN_ACCEL_SIM   =>  TRUE,
        DIP             =>  BS_DIP,               -- in G_PARAMETERS.vhd   := not X"1F";       
        GA              =>  BS_GA,                -- in G_PARAMETERS.vhd   := not "00100";     
        SN              =>  BS_SN                 -- in G_PARAMETERS.vhd   := not "0000101000";
        )
    Port Map(

		--VME Backplane
		CA 			    => CA, 	
		CD 			    => CD, 	
		CAM 		    => CAM, 	
		CAS 		    => CAS, 	
		CDS0 		    => CDS0, 	
		CDS1 		    => CDS1, 	
		CWRITE 		    => CWRITE, 
		CDTACK 		    => CDTACK, 
		CBERR 		    => CBERR, 
		
		--GIMLI
		TCS_CLK_P       => TCS_CLK_P_i,
		TCS_CLK_N       => TCS_CLK_N_i,
		TCS_DATA_P      => TCS_DATA_P_i,
		TCS_DATA_N      => TCS_DATA_N_i,
		
		--DMC input/output 
		CONN_P 	        => open, -- CONN_P_i,
		CONN_N 	        => open, -- CONN_N_i,
		
		NIM_IN_UP		=> '0',
		NIM_OUT1_UP		=> open,
		NIM_OUT2_UP		=> open,
		NIM_IN_DN		=> '0',
		NIM_OUT1_DN		=> open,				--special internal feature: this output is connected to NIM_OUT1_UP  
		NIM_OUT2_DN		=> open,

		--analog signal
		analog_in       => analog_sig,

		--VXS interface
		--SLINK MUX output and TCS input
		VXS_A_P         => VXS_A_P_i,
		VXS_A_N         => VXS_A_N_i,
		--Trigger data to TIGER
		VXS_B_P         => open, 
		VXS_B_N         => open, 
		vxs_sda         => '0',
		
		--SLINK transition card data bus
        gp_pin_o        => gp_pin_o,
		dataout		    => dataout
	);


    -- TRIGGER_process    :process
    -- begin

    --     wait for 5000 ns;
    --     if (trg_cnt) /=0  then
    --         wait for 5000 ns;
    --         trg_cnt<=trg_cnt-1;
    --     else
    --         wait for 5000 ns;
    --         trg_cnt<=3;
    --     end if;

    --     wait until rising_edge(TCS_CLK);
    --     -- i trigger sono generati software ...
    --     if BS_GIMLI_TYPE /= "OCX" then 
    --         if(ONSPILL = '1') then
    --             Trigger <= '1';
    --         else
    --             Trigger <= '0';
    --         end if;
    --         wait for CLK_155MHz_period * 4;
    --     end if;
    --     Trigger <= '0';
    -- end process;

    RUN_process :process
    begin

    ONSPILL <= '0';
    
    -- VME SETUP ...
    wait until gp_pin_o(2) = '0';
    x_fr_vme_reset0(vme_i => vme_i, vme_o => vme_o);
    --wait for 200 us; DA RIMETTERE
    wait for 20 us;
    -- tempi geologici se carico gli SI ...
    -- assumiamo che questa parte funziona ...
    -- Load the SI clock sythesizers via I2C
    x_fr_load_si(vme_i => vme_i, vme_o => vme_o);
    wait for 20 us;
    -- Reset the MEM Fpga
    x_fr_res_mem_fpga(vme_i => vme_i, vme_o => vme_o);
    wait for 1 us;
    -- set MEM to allow program the DDR memory via select map
    -- with the arwen bit file
    --x_fr_en_prog_arwen(vme_i => vme_i, vme_o => vme_o);
    --wait for 1 us;
    -- Read board status
    x_fr_wr_status(vme_i => vme_i, vme_o => vme_o);
    wait for 1 us;
    -- Enable dataout manager to Arwen
    x_fr_out_arw_en(vme_i => vme_i, vme_o => vme_o);
    wait for 1 us;
    -- Enable the spy fifo
    x_fr_out_spy_en(vme_i => vme_i, vme_o => vme_o);
    wait for 1 us;
    x_fr_load_dacs(vme_i => vme_i, vme_o => vme_o);
    wait for 1 us;
    --Carica source ID
    x_fr_read_gta_conf(vme_i => vme_i, vme_o => vme_o);
    wait for 1 us;

    -- start program Arwen
    --x_fr_data_valid(vme_i => vme_i, vme_o => vme_o);
    --wait for 1 us;
    --wait;

    -- Increment the IODelay as specified in configuration register 'AMC delay setting'
    -- x_fr_read_gta_delay(vme_i => vme_i, vme_o => vme_o);
    -- wait for 1 us;
-- Queste due procedure a noi non dovrebbero servire ... (Alex) 
--      -- Starts sweep process of the SI clock sythesizers for phase offset alignment
--      x_fr_sweep_si(vme_i => vme_i, vme_o => vme_o);
--      wait for 1 us;
--      -- Start phase align process of the SI clock sythesizers
--      x_fr_phase_align_si(vme_i => vme_i, vme_o => vme_o);

    --wait for 5000 ns;  DA RIMETTERE
    ONSPILL <= '1';
    wait for 1 us;
    --ATTENZIONE! da quanto mandi il SOB, ci mette un po di tempo (circa 400ns) la logica a capire che è uno Start of Burst (decodifica CH.B) per cui il reset del read_address da dare al
    --ring buffer avviene in ritardo.

    --1 MEP
    TRG_TYPE_IN <= SoB_HW;   TRIGGER <= '0'; WR_TYPE <='1'; wait for CLK_155MHz_period; WR_TYPE <= '0'; wait for CLK_40MHz_period * 80; -- Start of Burst Hardware
    --resetto tutti i contatori
    TRG_TYPE_IN <= SoB_Type;   TRIGGER <= '1'; WR_TYPE <='1'; wait for CLK_155MHz_period; WR_TYPE <= '0'; wait for CLK_40MHz_period * 20; -- Start of Burst    
    TRG_TYPE_IN <= Ptrg_Type;  TRIGGER <= '1'; WR_TYPE <='1'; wait for CLK_155MHz_period; WR_TYPE <= '0'; wait for 75 ns; -- Physics Trigger 1 ...
    TRG_TYPE_IN <= Ptrg_Type;  TRIGGER <= '1'; WR_TYPE <='1'; wait for CLK_155MHz_period; WR_TYPE <= '0'; wait for CLK_40MHz_period * 20; -- Physics Trigger 2 after 75 ns 
    TRG_TYPE_IN <= EoB_Type;   TRIGGER <= '1'; WR_TYPE <='1'; wait for CLK_155MHz_period; WR_TYPE <= '0'; wait for CLK_40MHz_period * 20; -- End of Burst Trigger  

    --2 MEP
    TRG_TYPE_IN <= Ptrg_Type;  TRIGGER <= '1'; WR_TYPE <='1'; wait for CLK_155MHz_period; WR_TYPE <= '0'; wait for 75 ns; -- Physics Trigger 1 ...
    TRG_TYPE_IN <= Ptrg_Type;  TRIGGER <= '1'; WR_TYPE <='1'; wait for CLK_155MHz_period; WR_TYPE <= '0'; wait for CLK_40MHz_period * 20; -- Physics Trigger 
    TRG_TYPE_IN <= Ptrg_Type;  TRIGGER <= '1'; WR_TYPE <='1'; wait for CLK_155MHz_period; WR_TYPE <= '0'; wait for CLK_40MHz_period * 20; -- Physics Trigger  
    TRG_TYPE_IN <= Ptrg_Type;  TRIGGER <= '1'; WR_TYPE <='1'; wait for CLK_155MHz_period; WR_TYPE <= '0'; wait for CLK_40MHz_period * 20; -- Physics Trigger 
    TRG_TYPE_IN <= Ptrg_Type;  TRIGGER <= '1'; WR_TYPE <='1'; wait for CLK_155MHz_period; WR_TYPE <= '0'; wait for CLK_40MHz_period * 20; -- Physics Trigger 
    TRG_TYPE_IN <= EoB_Type;   TRIGGER <= '1'; WR_TYPE <='1'; wait for CLK_155MHz_period; WR_TYPE <= '0'; wait for CLK_40MHz_period * 20; -- End of Burst Trigger  
     --wait for 10 us;
     
     
    -- MEP SUCCESSIVI
    TRG_TYPE_IN <= SoB_Type;   TRIGGER <= '1'; WR_TYPE <='1'; wait for CLK_155MHz_period; WR_TYPE <= '0'; wait for CLK_40MHz_period * 80; -- Start of Burst    
    
    for i in 0 to 20 loop
        TRG_TYPE_IN <= Ptrg_Type;  TRIGGER <= '1'; WR_TYPE <='1'; wait for CLK_155MHz_period; WR_TYPE <= '0'; wait for CLK_40MHz_period * 20;
    end loop;

    TRG_TYPE_IN <= EoB_Type;   TRIGGER <= '1'; WR_TYPE <='1'; wait for CLK_155MHz_period; WR_TYPE <= '0'; wait for CLK_40MHz_period * 20; -- End of Burst Trigger 
    
    wait for 1 us;
    
    TRG_TYPE_IN <= SoB_Type;   TRIGGER <= '1'; WR_TYPE <='1'; wait for CLK_155MHz_period; WR_TYPE <= '0'; wait for CLK_40MHz_period * 20; -- Start of Burst  
    TRG_TYPE_IN <= Reserv_Type;   TRIGGER <= '1'; WR_TYPE <='1'; wait for CLK_155MHz_period; WR_TYPE <= '0'; wait for CLK_40MHz_period * 20; -- Reserved Trigger 
    TRG_TYPE_IN <= Reserv_Type;   TRIGGER <= '1'; WR_TYPE <='1'; wait for CLK_155MHz_period; WR_TYPE <= '0'; wait for CLK_40MHz_period * 20; -- Reserved Trigger
    TRG_TYPE_IN <= Reserv_Type;   TRIGGER <= '1'; WR_TYPE <='1'; wait for CLK_155MHz_period; WR_TYPE <= '0'; wait for CLK_40MHz_period * 20; -- Reserved Trigger
    TRG_TYPE_IN <= Reserv_Type;   TRIGGER <= '1'; WR_TYPE <='1'; wait for CLK_155MHz_period; WR_TYPE <= '0'; wait for CLK_40MHz_period * 20; -- Reserved Trigger
    TRG_TYPE_IN <= Reserv_Type;   TRIGGER <= '1'; WR_TYPE <='1'; wait for CLK_155MHz_period; WR_TYPE <= '0'; wait for CLK_40MHz_period * 20; -- Reserved Trigger
    TRG_TYPE_IN <= EoB_Type;   TRIGGER <= '1'; WR_TYPE <='1'; wait for CLK_155MHz_period; WR_TYPE <= '0'; wait for CLK_40MHz_period * 20; -- End of Burst Trigger 

    
    
    wait;
    
    


    end process;

    

END;
