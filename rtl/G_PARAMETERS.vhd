--
--  Package File Template
--
--  Purpose: This package defines supplemental types, subtypes, 
--       constants, and functions 
--
--   To use any of the example code shown below, uncomment the lines and modify as necessary
--

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

package G_PARAMETERS is

    ----------------------------------------------------------------------
    ----- GANDALF board setup
    ----------------------------------------------------------------------

    ---Hardware section> add/remove corresponding ucf file!---------------
    
    constant BS_MCS_UP      : string := "AMC";  --mounted mezzanine to card slot up,            use /ucf/dsp/amc0 or dmc0 or omc0.ucf
                                                --options: "AMC","DMC","OMC"                    use the corresponding .ucf file!
    constant BS_MCS_DN      : string := "OMC";  --mounted mezzanine to card slot down,          use /ucf/dsp/amc1 or dmc1 or omc1.ucf
                                                --options: "AMC","DMC","OMC"                    use the corresponding .ucf file!

    constant BS_SLINK_DSP  : boolean := FALSE;  --defines FPGA for SLINK readout                use /ucf/dsp/slink.ucf
    constant BS_SLINK_MEM  : boolean := FALSE;  --defines FPGA for SLINK readout                use /ucf/mem/slink.ucf
    constant BS_SLINK_VXS  : boolean := FALSE;  --defines TIGER for SLINK readout   
    constant BS_USE_AURORA : boolean := FALSE;  --set to TRUE if BS_SLINK_MEM = TRUE            use /ucf/dsp/aurora.ucf and /ucf/mem/aurora.ucf 
    constant BS_USE_QDR    : boolean := FALSE;  --enables QDR memory                            use /ucf/mem/qdr.ucf
    constant BS_USE_DDR    : boolean := FALSE;  --enables DDR memory                            use /ucf/mem/ddr.ucf
        
    constant BS_GIMLI_TYPE  : string := "TCS";  --mounted GIMLI card                            use /ucf/dsp/tcs.ucf   for "TCS" and "VXS",
                                                --options: "TCS" (FIBER),                       use /ucf/dsp/OCXO.ucf  for "OCX"
                                                --         "OCX" (COPPER),
                                                --         "VXS" (FROM BUS)      
                                                --check also SI default config in software section for SI frequency

    constant BS_G_RATE      : std_logic := '0'; 
            --select in case of TCS '0' for 38.88MHz(COMPASS)  or  '1' for 40.08MHz (LHC)       use /ucf/dsp/tcs.ucf
            --select in case of OCXO '0' for ext clk or '1' for 20MHz OCXO                      use /ucf/dsp/OCXO.ucf
    
    constant ADD_ADC_DELAY      : integer := 8;     -- options: "0" for TCS, "8" for OCX 
            -- (GANDALF)
    constant BS_FPGA_TYPE       : string := "XC5VSX95T";
            -- (GANDALF)
    constant BS_T_TRIGGER       : boolean := FALSE;  -- defines usage of vxs_b for tiger trigger 
            -- (GANDALF) 

    -- constant BS_T_TRIGGER       : BOOLEAN := FALSE; -- defines usage of VXS_B for Tiger trigger  
            -- (ARWEN)
        
    constant GEN_GANDALF_REV    : string := "V1";

    ---------------------------------------------------------------------
    ---Software section -------------------------------------------------
    ---------------------------------------------------------------------
    constant GEN_DSP_FIRMW_VERS : BIT_VECTOR(31 downto 0) := x"20012022";  -- (cpld_if) da cambiare --- gg/mm/aaaa ???
    
    constant GEN_DSP_DESIGN_TYPE : BIT_VECTOR(7 downto 0) := x"05";
            -- (GANDALF)
    
    -- constant GEN_DSP_DESIGN_TYPE : BIT_VECTOR(7 downto 0) := x"00";
            -- (ARWEN)
            
    --SLINK & USB readout options
    constant BS_GEN_SPY_FIFO            : boolean := FALSE;  --this is still done in cplf_if...
    constant BS_USE_USB_FALLBACK        : boolean := FALSE;
    constant BS_USE_USB_READOUT         : boolean := FALSE;

            -- (GANDALF)
    
    -- constant BS_USE_USB_READOUT : boolean := TRUE;
            -- (ARWEN)
    -- constant SEND_SL_HEADER             : boolean := TRUE;
            -- (ARWEN)

    --chipscope options
    constant USE_CHIPSCOPE_ICON         : boolean := TRUE;                  -- Set to true to use Chipscope ICON on TOP
    constant USE_CHIPSCOPE_VIO_TOP      : boolean := FALSE;                 -- Set to true to use Chipscope VIO not used

    constant USE_CHIPSCOPE_ILA_0        : boolean := FALSE;                 -- Set to true to use Chipscope ILA in cpld_if         
    constant USE_CHIPSCOPE_ILA_1        : boolean := FALSE;                 -- Set to true to use Chipscope ILA in tcs_ctrl         
    constant USE_CHIPSCOPE_ILA_2        : boolean := FALSE;                 -- Set to true to use Chipscope ILA in tranceiver         
    constant USE_CHIPSCOPE_ILA_3        : boolean := TRUE;                 -- Set to true to use Chipscope ILA in arwen_s_prog         
    constant USE_CHIPSCOPE_ILA_4        : boolean := TRUE;                  -- Set to true to use Chipscope ILA in wb_to_ram         
    constant USE_CHIPSCOPE_ILA_5        : boolean := TRUE;                 -- Set to true to use Chipscope ILA in gtp_if         
    constant USE_CHIPSCOPE_ILA_6        : boolean := FALSE;                  -- Set to true to use Chipscope ILA si_load         
    constant USE_CHIPSCOPE_ILA_TOP      : boolean := FALSE;                 -- Set to true to use Chipscope ILA fastregister         
    -- Use Chipscope debug option (Alex)


    ---------------------------------------------------------------------
    --                     SI configurations (GANDALF)
    -- per NA62 bisognera' merttere i numeri giusti in funzione della frequenza di ingresso a 160.3158
    -- e mettere la generazione dei clock in fase (normal sampling mode)
    ---------------------------------------------------------------------
    constant BS_SI_PERIOD : real := 2.14335; -- 466.56 Mhz = 12 * 38.88 Mhz -- era 2.14335

    constant BS_SI_G                  : bit_vector (511 downto 0)
    --:=X"00000000000000000000000000000000000000400000FF0F021F007C00007C00002F0FA0010000010000403F1FDF7E3E2C0080004200C0002A3FED921572E014"; -- 20 to 466.56 
    --    |  F   ||   E  ||  D   ||   C  ||   B  ||  A   ||   9  ||  8   ||  7   ||  6   ||  5   ||   4  ||   3  ||  2   ||   1  ||   0  |
    --:=X"00000000000000000000000000000000000000400000FF0F021F007C00007C0000C71640050000010000403F1FDFFF3E2C0080004200C0002A3FED921572E434"; -- 20 to 466.56 & 155.52
      :=X"00000000000000000000000000000000000000400000FF0F021F007C00007C00002F0FA00B0000010000403F1FDFFF3E2C0080004200C0002A3FED921572E414"; -- 20 to 466.56 & 77.76
    --:=X"00000000000000000000000000000000000000400000FF0F021F007C00007C0000C71640050000030000403F1FDFFF3E2C0080004200C0002A3FED921572E414"; -- 20 to 233.28 
    --:=X"00000000000000000000000000000000000000400100FF0F021F034D00004D00003701A0010000010000403F1FDF7E3E2C0080004200C0002A3FED9215A2E414"; -- 155.52 to 466.56 ilm
    --:=X"00000000000000000000000000000000000000400100FF0F021F034D00004D00003701A0030000030000403F1FDF7E3E2C0080004200C0002A3FED9215A2E414"; -- 155.52 to 233.28 ilm
    --                                          
    constant BS_SI_MCS_UP             : bit_vector (511 downto 0)
    --:=X"00000000000000000000000000000000000000400000FF0F021F007C00007C00002F0FA0010000010000403F1FDF7E3E2C0080004200C0002A3FED921572E014"; -- 20 to 466.56 nlm
      :=X"00000000000000000000000000000000000000400000FF0F021F007C00007C00002F0FA0050000050000003F1FDFFF3E2C0080004200C0002A3FED921572E414"; -- 20 to 233.28 nlm
    
    --:=X"00000000000000000000000000000000000000400100FF0F021F007C00007C00002F0FA0010000010000403F1FDF7E3E2C0080004200C0002A3FED921572E014"; -- 20 to 466.56 ilm
    --:=X"00000000000000000000000000000000000000400100FF0F021F034D00004D00003701A0010000010000403F1FDF7E3E2C0080004200C0002A3FED9215A2E414"; -- 155.52 to 466.56 ilm
    
    constant BS_SI_MCS_DN             : bit_vector (511 downto 0)
      :=X"00000000000000000000000000000000000000400000FF0F021F00090000090000F30120090000070000203F1FDFFF3E2C0080004200C0002A3FED9215A2E414"; -- 20 to 125.00 clkA & 100.00 clkB 
    -- := BS_SI_G;
    --:=BS_SI_MCS_UP;
    -- END (GANDALF)

    ---------------------------------------------------------------------
    --                  SI configurations (ARWEN)
    ---------------------------------------------------------------------
--  constant BS_SI_G        : bit_vector (511 downto 0)
--  --default 155to505: used with 155MHz TCS
--  --:=X"00000000000000000000000000000000000000400000ff0f021f004d00004f0000ff00c009000003000080601fdf7e3e2c0080004200c0002a3f2d1205a2e415"; --Gbase
--  --:=X"00000000000000000000000000000000000000400000ff0f021f004d00000a0000f900e0070000000000c0601fdf7e3e2c0080004200c0002a3f2d1205a2e415"; --si_configurator
--    :=X"00000000000000000000000000000000000000400000ff0f021f004d00004d0000210220090000010000603f1fdf7e3e2c0080004200c0002a3f2d1205a2e415"; -- just for debug: worked with sweep
--  --default 20to500: used with 20MHz OCXO
--  --:=X"00000000000000000000000000000000000000400000ff0f021f004d00000a0000f900e0070000000000c0601fdf7e3e2c0080004200c0002a3f2d1205a2e415";
--            
    --constant BS_SI_MCS_DN   : bit_vector (511 downto 0) -- era BS_SI_MCS_UP
    --default 155to505 nml
    --:=X"00000000000000000000000000000000000000400000FF0F021F005700005700000301E0010000010000203F1FDF7E3E2C0080004200C0002A3F2D1205A2E414";
    --default 155to505 ilm to test!!
    --  :=X"00000000000000000000000000000000000000400100ff0f021f004d00004f00000301c001000001000020601fdf7e3e2c0080004200c0002a3f2d1205a2e414";--combined 2 .51
            
    --20to500 nml
    --:=X"00000000000000000000000000000000000000400100ff0f021f00570000090000f900c0000000000000c0201fdf7e3e2c0080004200c0002a3f2d1205a2e414";
    --20to500 ilm
    --:=X"00000000000000000000000000000000000000400100ff0f021f00090000090000f900c001000001000020c01fdf7e3e2c0080004200c0002a3f2d1205a2e414";
            
--  constant BS_SI_MCS_DN   : bit_vector (511 downto 0)
--  :=BS_SI_MCS_UP;
    -- END (ARWEN)

    
--SI phase sweep parameters
    constant GS_MAX_CRIT_MULTI          : integer := 15;                            -- find max criterium: (MULTI/DIV) * max > l_max, r_max
    constant GS_MAX_CRIT_DIV            : integer := 16;                            -- find max criterium: (MULTI/DIV) * max > l_max, r_max
    constant GS_DELAY_VAL_A             : integer := 4;                             -- number delay line taps on Sweep Mezz A (78ps per tap)
    constant GS_DELAY_VAL_B             : integer := 4;                             -- number delay line taps on Sweep Mezz B (78ps per tap)
    constant GS_DELAY_VAL_G             : integer := 4;                             -- number delay line taps on Sweep Gandalf SI (78ps per tap)
    constant GS_LOL_LOS_TIMEOUT         : integer := 10;                            -- timeout in 100 millisecs to wait for LOL/LOS go down after loading SIs (oszi showed 1 sec)
    constant IDELAYCTRL_NUM             : integer := 1;                             -- defines the number of needed IDELAYCTRL: 1 for Base, 2 for GTA

    constant GS_N_SWEEP_STATS           : integer := 65000;                         -- number of cycles to do statistics for each step
        --(GANDALF)
    
    --M1-TDC config_mem parameters
--  constant BS_M1TDC_G                 : bit_vector (255 downto 0)
--  :=X"0000000000000000000000000000000000000000000000000000000100500184";
        -- (ARWEN) 
    constant BS_M1TDC_G                 : bit_vector (255 downto 0)
    :=X"0000000000000000000000000000000000000000000000000000000101840050";
        -- (GANDALF)
      
    --GTA design
    constant GEN_RDM                    : std_logic_vector(3 downto 0):="0010";     -- 4bits: (3): 0 normal, 1 ilm,  (2 downto 0): 000: processed, 001 frame, 010: debug                                            
    constant GEN_ADC_TYPE               : integer := 12;                            -- BIT  
    constant ADC_CHANNELS               : integer := 8;                             -- number of ADCs for readout (era 16 ...) 
    
    function c_active_channel                                                       -- Function to find active channel ...
            (input : in std_logic;                                                  -- ACTIVE_CHANNELS = ADC_CHANNELS/2 when GEN_RDM(3) = 1;  
            channel : in integer)                                                   -- ACTIVE_CHANNELS = ADC_CHANNELS   when GEN_RDM(3) = 0;
             return integer;

    Constant ACTIVE_CHANNELS            : integer := ADC_CHANNELS;                  -- Deferred constant not supported in ISE ... 
                                                                                    -- set the rigth value (es. := ADC_CHANNELS/2) and comment the package body
                                                                                    
                                        
                                                                                                                                                                     
    -- GANDARW Value into cpld_if :
    constant GEN_SOURCE_ID              : std_logic_vector(7 downto 0)  := x"6C";   --Source ID SAV 
    constant GEN_TIMESTAMP_BASE              : std_logic_vector(31 downto 0) := x"00000000"; -- Valore da mettere nel contatore BC counter (tcs_if_mep), quando viene resettato 
    constant GEN_LATENCY                : integer                       := 100;   -- # of ADC words  at 8.582 ns per bit (=200us) -- (cpld_if) --da rimettere 23305
    constant GEN_FRAMEWIDTH             : integer                       := 12;      -- # of ADC sample/2 at 4.291 ns per bit (=100ns) -- (cpld_if)  --MODIFICATO (Marco)
    constant GEN_BASELINE               : integer                       := 200;     -- not used                                     -- (cpld_if)
    constant GEN_PRESCALER              : integer                       := 0;       -- # of Debug frame (0 = always)                -- (cpld_if)
    -- Value for costant fraction                                                                           
    constant GEN_FRACTION               : integer                       := 2;       -- constant fraction divider                    -- (cpld_if)
    constant GEN_DELAY                  : integer                       := 10;      -- constant fraction delay                      -- (cpld_if)
    constant GEN_THRESHOLD              : integer                       := 30;      -- constant fraction threshold                  -- (cpld_if)
    constant GEN_MAX_DIST               : integer                       := 3;       -- constant fraction value                      -- (cpld_if)
    -- Value for tiger costant fraction                                                                             
    constant GEN_T_THRESHOLD            : integer                       := 10;      -- Tiger trigger threshold                      -- (cpld_if)
    constant GEN_T_MAX_DIST             : integer                       := 3;       -- Tiger trigger value                          -- (cpld_if)

    -- Value for ARWEN IP
    constant GEN_IP_SOURCE_0            : std_logic_vector(31 downto 0) := X"C0A80100";
    constant GEN_IP_SOURCE_1            : std_logic_vector(31 downto 0) := X"C0A80101";
    constant GEN_IP_SOURCE_2            : std_logic_vector(31 downto 0) := X"C0A80102";
    constant GEN_IP_SOURCE_3            : std_logic_vector(31 downto 0) := X"C0A80103";
    constant GEN_IP_DEST_0              : std_logic_vector(31 downto 0) := X"C0A8DE00";
    constant GEN_IP_DEST_1              : std_logic_vector(31 downto 0) := X"C0A8DE01";
    constant GEN_IP_DEST_2              : std_logic_vector(31 downto 0) := X"C0A8DE02";
    constant GEN_IP_DEST_3              : std_logic_vector(31 downto 0) := X"C0A8DE03";

    constant GEN_MAC_ADDR_0             : std_logic_vector(47 downto 0) := X"000A35001000";
    constant GEN_MAC_ADDR_1             : std_logic_vector(47 downto 0) := X"000A35001001";
    constant GEN_MAC_ADDR_2             : std_logic_vector(47 downto 0) := X"000A35001002";
    constant GEN_MAC_ADDR_3             : std_logic_vector(47 downto 0) := X"000A35001003";

    constant GEN_START_ADDR             : std_logic_vector(31 downto 0) := X"00000001";
    constant GEN_END_ADDR               : std_logic_vector(31 downto 0) := X"0005C000";

    type idel_vector        is array (0 to 11) of integer range 0 to 63;
    type idel_int_array     is array (integer range <>) of idel_vector;


-- (ARWEN) probabilmente non servono ...    
--    constant GEN_IDEL_INT   : idel_int_array(0 to 15):= (
--                                                        (others => 13), (others =>  0), (others =>  4), (others =>  0), (others => 13), (others =>  0), (others => 11), (others =>  1),  --amc up
--                                                        (others => 26), (others =>  0), (others => 14), (others => 15), (others =>  1), (others =>  1), (others =>  0), (others =>  2)    --amc dn
--                                                        );      
--            

    --idelvalues for the adc readout in interleaved mode 
    -- (GANDALF) probabilmente servono solo i primi otto,
    -- commentati i secondi otto ...  Alex
    -- constant GEN_IDEL_INT   : idel_int_array(0 to 15):= (
    -- (29, 30, 28, 29, 29, 30, 30, 30, 29, 31, 27, 27), (13, 17, 17, 14, 17, 17, 18, 18, 18, 14, 11, 11),
    -- (29, 30, 29, 29, 29, 30, 30, 30, 29, 28, 26, 26), (17, 17, 17, 17, 17, 17, 17, 20, 18, 18, 17, 15),
    -- (31, 31, 31, 30, 31, 31, 32, 33, 31, 31, 31, 29), (15, 17, 17, 16, 17, 17, 18, 19, 18, 18, 15, 15),
    -- (34, 34, 34, 34, 34, 34, 34, 34, 34, 33, 33, 31), (21, 21, 22, 22, 22, 22, 24, 24, 24, 24, 21, 19),
    -- (47, 48, 48, 48, 48, 48, 50, 50, 50, 48, 48, 46), (33, 32, 33, 33, 33, 34, 33, 35, 36, 34, 32, 33),
    -- (43, 44, 46, 45, 44, 44, 45, 46, 45, 44, 42, 41), (29, 28, 29, 29, 30, 30, 30, 32, 31, 29, 28, 27),
    -- (39, 38, 39, 40, 40, 40, 40, 42, 41, 40, 41, 40), (28, 29, 28, 29, 28, 29, 29, 29, 29, 28, 25, 26),
    -- (41, 40, 42, 41, 40, 41, 42, 42, 41, 40, 38, 38), (30, 31, 31, 31, 31, 28, 29, 29, 29, 32, 30, 29)
    -- );
    
    -- (GANDALF) azzerati per simulazione ... Alex
    constant GEN_IDEL_INT   : idel_int_array(0 to 7):= (others => (others=> 0));

    --idelvalues for the adc readout in normal sampling mode (aumentati di 14 tap i ch dispari)
    -- constant GEN_IDEL_INT   : idel_int_array(0 to 7):= (
    --     (29, 30, 28, 29, 29, 30, 30, 30, 29, 31, 27, 27), (27, 31, 31, 28, 31, 31, 32, 32, 32, 28, 25, 25),
    --     (29, 30, 29, 29, 29, 30, 30, 30, 29, 28, 26, 26), (31, 31, 31, 31, 31, 31, 31, 34, 32, 32, 31, 29),
    --     (31, 31, 31, 30, 31, 31, 32, 33, 31, 31, 31, 29), (29, 31, 31, 30, 31, 31, 32, 33, 32, 32, 29, 29),
    --     (34, 34, 34, 34, 34, 34, 34, 34, 34, 33, 33, 31), (35, 35, 36, 36, 36, 36, 38, 38, 38, 38, 35, 33)
    -- );

    --idelvalues for the adc readout in normal sampling mode (diminuiti di 14 tap i ch pari)
    -- constant GEN_IDEL_INT   : idel_int_array(0 to 7):= (
    -- (15, 16, 14, 15, 15, 16, 16, 16, 15, 17, 13, 13), (13, 17, 17, 14, 17, 17, 18, 18, 18, 14, 11, 11),
    -- (15, 16, 15, 15, 15, 16, 16, 16, 15, 14, 12, 12), (17, 17, 17, 17, 17, 17, 17, 20, 18, 18, 17, 15),
    -- (17, 17, 17, 16, 17, 17, 18, 19, 17, 17, 17, 15), (15, 17, 17, 16, 17, 17, 18, 19, 18, 18, 15, 15),
    -- (20, 20, 20, 20, 20, 20, 20, 20, 20, 19, 19, 17), (21, 21, 22, 22, 22, 22, 24, 24, 24, 24, 21, 19)
    -- );

    --DMC design
    constant DMC_direction  : STD_LOGIC := '1';                                     -- 3-state enable input, high=input, low=output
    --------------------------------------------------------------------

    --------------------------------------------------------------------
    ----- testbench simulation parameters
    --------------------------------------------------------------------
    
    constant BS_DIP : std_logic_vector(7 downto 0) := not X"1F";                    --HexID of the simulated GANDALF
    constant BS_GA  : std_logic_vector(4 downto 0) := not "00100";                  --Crate Slot of the simulated GANDALF
    constant BS_SN  : std_logic_vector(9 downto 0) := not "0000101000";             --Serial Number of the simulated GANDALF

    
    constant SIMULATION_MODE    : string := "REG_PULSES";                           --"DAC_CALIB"           --for dac calibration
                                                                                    --"RPD_READOUT"         --for data rate stress, random trigger and pulses
                                                                                    --"REG_PULSES"          --for timing resolution measurement
                                                                                    --"REG_DOUBLE_PULSES"   --for timing resolution measurement of double pulses                                    
                                                                                    --"MASTER_TIME"

    constant GEN_T_OFFSET_CYCLES    : integer   :=2000;
    constant GEN_T_OFFSET_TIME      : real      :=0.000;                -- in ns
    constant GEN_NOISE              : real      :=0.001;                -- in Volt              0.0015
    constant GEN_MAXAMP             : real      :=3.002;                -- in Volt              4.0
    constant GEN_TRIGGER_MASK_1     : real      := 15.0;                -- one   in xx us   1.0
    constant GEN_TRIGGER_MASK_3     : real      := 30.0;                -- three in xx us   5.0
    constant GEN_TRIGGER_MASK_10    : real      := 250.0;               -- ten   in xx us   50.0
    constant TRIGGER_RATE           : real      := 100.0;               -- in KHz
    constant MAX_EVENTS             : integer   := 10;
    constant SIGNAL_CH_NO           : integer   := 0;



    --------------------------------------------------------------------
    ----- CONSTANTS 
    --------------------------------------------------------------------

    constant IIC_WRITE      : std_logic                     := '0';
    constant IIC_READ       : std_logic                     := '1';
    constant IIC_1BYTE      : integer range 0 to 3          := 0;
    constant IIC_2BYTE      : integer range 0 to 3          := 1;
    constant IIC_3BYTE      : integer range 0 to 3          := 2;
    constant IIC_4BYTE      : integer range 0 to 3          := 3;
    
    --------------------------------------------------------------------
    ----- cf_mem_addr_offsets 
    --------------------------------------------------------------------

    constant AMC0_ADDR_OFFSET           : unsigned  :=b"00" & x"00";
    constant AMC1_ADDR_OFFSET           : unsigned  :=b"01" & x"00";
    constant GNDLF_ADDR_OFFSET          : unsigned  :=b"10" & x"00";

    constant AMC_DEL_EDGE_OFFSET        : unsigned  :=b"10" & x"64"; --6 words  = 264, 990 via vme (GANDALF)
    constant AMC_DEL_SET_OFFSET         : unsigned  :=b"00" & x"c0"; --14 words                    (GANDALF)

    constant IDENT_ADDR_OFFSET          : unsigned  :=b"00" & x"00"; --2 words
    constant STATUS_ADDR_OFFSET         : unsigned  :=b"00" & x"02"; --2 words
    constant DATA_STAT_ADDR_OFFSET      : unsigned  :=b"00" & x"06"; --1 word
    constant FIRMW_ADDR_OFFSET          : unsigned  :=b"00" & x"08"; --4 word
    constant TEMP_ADDR_OFFSET           : unsigned  :=b"00" & x"10"; --3 words
    constant VOLTAGE_ADDR_OFFSET        : unsigned  :=b"00" & x"18"; --10 words
    constant DAC_VAL_ADDR_OFFSET        : unsigned  :=b"00" & x"30"; --4 words
    constant BASL_VAL_ADDR_OFFSET       : unsigned  :=b"00" & x"34"; --4 words
    
    constant GANDALF_CONFIGURATION      : unsigned  :=b"00" & x"C0"; --8 words
    constant FRAME_LATENCY_VALS         : unsigned  :=b"00" & x"C8"; --16 words
    constant THRES_VAL_ADDR_OFFSET      : unsigned  :=b"00" & x"38"; --8 words
    constant SI_CONF_OFFSET             : unsigned  :=b"00" & x"80"; --8 words
    constant SCALER_LATENCY             : std_logic_vector (9 downto 0) :=b"10" & x"d8"; --1 word 
    constant TIGER_ANA_CONFIGURATION    : unsigned  :=b"01" & x"40"; 

    constant IP_CONF_OFFSET             : unsigned  :=b"00" & x"30"; --16 words: 4x2 mac + 8 ip
    
    --------------------------------------------------------------------
    ----- sysmon alarm tresholds
    --------------------------------------------------------------------
    
    constant TEMP_UP                    : bit_vector(15 downto 0) :=X"BB2F"; -- Alarm limit temp upper   (95C)
    constant INT_UP                     : bit_vector(15 downto 0) :=X"5DDD"; -- Alarm limit VCCINT upper (1,1V)
    constant AUX_UP                     : bit_vector(15 downto 0) :=X"E000"; -- Alarm limit VCCAUX upper (2,625V)   
    constant TEMP_LW                    : bit_vector(15 downto 0) :=X"0000"; -- Alarm limit temp lower   (-273C)
    constant INT_LW                     : bit_vector(15 downto 0) :=X"4444"; -- Alarm limit VCCINT lower (0,8V)
    constant AUX_LW                     : bit_vector(15 downto 0) :=X"CAAA"; -- Alarm limit VCCAUX lower (2,375V)
                        
end G_PARAMETERS;  

package body G_PARAMETERS is
    function c_active_channel(input : in std_logic; channel : in integer) return integer is
    begin
        if input = '1' then
            return channel/2; 
        else
            return channel;
        end if;
    end;

    -- synthesis translate_off
    -- Constant ACTIVE_CHANNELS            : integer := c_active_channel(GEN_RDM(3),ADC_CHANNELS);
    -- synthesis translate_on

end G_PARAMETERS; 