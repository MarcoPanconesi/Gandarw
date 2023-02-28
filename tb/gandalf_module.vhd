-- vsg_off
----------------------------------------------------------------------------------
-- Company:         INFN-LNF
-- Engineer:        alessandro.balla@lnf.infn.it
-- 
-- Create Date:     11:43:03 16/07/2021 
-- Design Name: 
-- Module Name:     gandalf_module.vhd - TestBench 
-- Project Name:    GANDARW
-- Target Devices:  XC5VSX95T-2FF1136
-- Tool versions:   ISE 14.7, QUESTASIM 10.7
-- Description:     Mix of Gandalf (amc) and Arwen\gbase_arwen 
--
-- Dependencies:    CPLD, DDR
--
-- Revision:        Revision 0.01 - File Created
--
-- Additional Comments: 
--
-- TestBench :      \Xil_14.7\GandArw\rtl\tb\testbench.vhd
-- Package :        \Xil_14.7\GandArw\rtl\tb\tb_pkg.vhd
-- Simulation :     Remove -novopt option to QuestaSim compxlib.cfg
--                  to compile library without error.
--                  Add VLOG command line option "-suppress 2902"
--                  to avoid verilog error.
--                  Set ignore simulator/compiled library version check in 
--                  simulation properties      
----------------------------------------------------------------------------------

LIBRARY UNISIM;
USE UNISIM.VCOMPONENTS.ALL;
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

--USE WORK.SI5326.ALL;
USE WORK.TOP_LEVEL_DESC.ALL;
USE work.G_PARAMETERS.ALL;
--USE WORK.CPLD_INTERFACE_PKG.ALL;
USE WORK.TB_PKG.ALL;
--USE WORK.STATUS_LED.ALL;
--USE WORK.TXT_UTIL.ALL;

USE WORK.VME_PKG.ALL;

LIBRARY MEM;
USE MEM.ALL;

library SIMPRIM;
use SIMPRIM.VPACKAGE.ALL;


-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity GANDALF_module is
  Generic(
    GEN_ACCEL_SIM   : boolean;     
    DIP             : std_logic_vector(7 downto 0);
    GA              : std_logic_vector(4 downto 0);
    SN              : std_logic_vector(9 downto 0)
  );
  Port(
    --CPLD interface --
    -------------------
      CA            : inout std_logic_vector (31 downto 0);
      CD            : inout std_logic_vector (31 downto 0);
      CAM           : in    std_logic_vector (5 downto 0);
      CAS           : in    std_logic;
      CDS0          : in    std_logic;
      CDS1          : in    std_logic;
      CWRITE        : in    std_logic;
      CDTACK        : out   std_logic;
      CBERR         : out   std_logic;

    --DMC input/output--
    --------------------
      CONN_P        : inout DMC_ports(3 downto 0);  --DMC LVDS differentials inputs 4cables with 32 inputs
      CONN_N        : inout DMC_ports(3 downto 0);

      NIM_IN_UP     : in    std_logic;
      NIM_OUT1_UP   : out   std_logic;
      NIM_OUT2_UP   : out   std_logic;
      NIM_IN_DN     : in    std_logic;
      NIM_OUT1_DN   : out   std_logic;          --special internal feature: this output is connected to NIM_OUT1_UP
      NIM_OUT2_DN   : out   std_logic;

    --AMC inputs---------
    ---------------------
       analog_in    : in    analog_signals(ADC_CHANNELS-1 downto 0);  --ADC data inputs including dry

    -- GMLI ------------------
    ---------------------------
      TCS_CLK_P     : in    std_logic;
      TCS_CLK_N     : in    std_logic;
      TCS_DATA_P    : in    std_logic;
      TCS_DATA_N    : in    std_logic;

    --VXS TIGER interface----
    -------------------------

      --SLINK MUX output and TCS input
      VXS_A_P       : inout std_logic_vector(7 downto 0):= (others => '0');
      VXS_A_N       : inout std_logic_vector(7 downto 0):= (others => '0');

      --Trigger data to tiger
      VXS_B_P       : out   std_logic_vector(7 downto 0):= (others => '0');
      VXS_B_N       : out   std_logic_vector(7 downto 0):= (others => '0');


      VXS_SCL       : out   std_logic;
      VXS_SDA       : in    std_logic;


    --SLINK transition card----
    ---------------------------
      gp_pin_o : out std_logic_vector(4 downto 0);
      dataout : out std_logic_vector(31 downto 0)
    );
end GANDALF_module;

architecture Behavioral of GANDALF_module is
    -- memory controller parameters
    constant    C0_DDR2_BANK_WIDTH      : integer := 3;
    constant    C0_DDR2_DQ_WIDTH        : integer := 8;
    constant    C0_DDR2_ROW_WIDTH       : integer := 14;
    
    constant    C1_DDR2_BANK_WIDTH      : integer := 3;
    constant    C1_DDR2_DQ_WIDTH        : integer := 8;
    constant    C1_DDR2_ROW_WIDTH       : integer := 14;

    constant    C0_DDR2_DEVICE_WIDTH    : integer := 8;     -- Memory device data width for controller0
    constant    C1_DDR2_DEVICE_WIDTH    : integer := 8;     -- Memory device data width for controller1

--    constant    C0_QDRII_ADDR_WIDTH     : integer := 19;    -- # of memory component address bits.
--    constant    C0_QDRII_BURST_LENGTH   : integer := 4;     -- # = 2 -> Burst Length 2 memory part,
--                                                            -- # = 4 -> Burst Length 4 memory part.
--    constant    C0_QDRII_BW_WIDTH       : integer := 4;     -- # of Byte Write Control bits.
--    constant    C0_QDRII_CLK_WIDTH      : integer := 1;     -- # of memory clock outputs. Represents the
--                                                            --   number of K, K_n, C, and C_n clocks.
--    constant    C0_QDRII_CQ_WIDTH       : integer := 1;     -- # of CQ bits.
--    constant    C0_QDRII_DATA_WIDTH     : integer := 36;    -- Design Data Width.
--
--    constant    C0_QDRII_MEMORY_WIDTH   : integer := 36;    -- # of memory part's data width   
--    constant    C1_QDRII_ADDR_WIDTH     : integer := 19;    -- # of memory component address bits.
--    constant    C1_QDRII_BURST_LENGTH   : integer := 4;     -- # = 2 -> Burst Length 2 memory part,
--                                                            -- # = 4 -> Burst Length 4 memory part.
--    constant    C1_QDRII_BW_WIDTH       : integer := 4;     -- # of Byte Write Control bits.
--    constant    C1_QDRII_CLK_WIDTH      : integer := 1;     -- # of memory clock outputs. Represents the
--                                                            -- number of K, K_n, C, and C_n clocks.
--    constant    C1_QDRII_CQ_WIDTH       : integer := 1;     -- # of CQ bits.
--    constant    C1_QDRII_DATA_WIDTH     : integer := 36;    -- Design Data Width.



    constant F0_DDR2_CLK_PERIOD_NS      : real := 5000.0 / 1000.0;
    constant F0_TCYC_SYS                : real := F0_DDR2_CLK_PERIOD_NS/2.0;
    constant F0_TCYC_SYS_0              : time := F0_DDR2_CLK_PERIOD_NS * 1 ns;
    constant F0_TCYC_SYS_DIV2           : time := F0_TCYC_SYS * 1 ns;

    constant TEMP2                      : real := 5.0/2.0;
    constant TCYC_200                   : time := TEMP2 * 1 ns;
    constant TPROP_DQS                  : time := 0.00 ns;  -- Delay for DQS signal during Write Operation
    constant TPROP_DQS_RD               : time := 0.00 ns;  -- Delay for DQS signal during Read Operation
    constant TPROP_PCB_CTRL             : time := 0.00 ns;  -- Delay for Address and Ctrl signals
    constant TPROP_PCB_DATA             : time := 0.00 ns;  -- Delay for data signal during Write operation
    constant TPROP_PCB_DATA_RD          : time := 0.00 ns;  -- Delay for data signal during Read operation

  -- CPLD
COMPONENT vmetop
    PORT(
        BSYSRES         : in    std_logic;
        CA              : inout std_logic_vector(31 downto 0);
        CAM             : in    std_logic_vector(5 downto 0);
        CAS             : in    std_logic;
        CDS0            : in    std_logic;
        CDS1            : in    std_logic;
        CIACK           : in    std_logic;
        CLK_CPLD        : in    std_logic;
        CLK_80MHZ       : in    std_logic;
      -- CLWORD         : in    std_logic;
        CWRITE          : in    std_logic;                     
        DIP             : in    std_logic_vector(7 downto 0);  
        DONE            : in    std_logic;                     
        GA              : in    std_logic_vector(4 downto 0);  
        INIT_B          : in    std_logic;                     
        SN              : in    std_logic_vector(9 downto 0);  
        UCDGPO1         : in    std_logic;                     
        UCDGPO2         : in    std_logic;                     
        CCLK            : out   std_logic;                     
        CDIR0           : out   std_logic;                     
        CDIR1           : out   std_logic;                     
        CDTACK          : out   std_logic;                     
        CBERR           : out   std_logic;                     
        CSRESET         : out   std_logic;                     
        DCS             : out   std_logic;                     
        DISPCLK         : out   std_logic;                     
        DISPDATA        : out   std_logic;                     
        DISPLOAD        : out   std_logic;                     
      -- LED4           : out   std_logic;                     
        LED6            : out   std_logic;                     
        LED7            : out   std_logic;                     
        MCS             : out   std_logic;                     
        M0              : out   std_logic;                     
        M1              : out   std_logic;                     
        M2              : out   std_logic;                     
        OBUF_EN         : out   std_logic;                     
        PROGRAM_B       : out   std_logic;                     
        QA              : inout std_logic_vector(0 to 7);      
        RDWR_B          : out   std_logic;                     
        SYSACERES       : out   std_logic;                     
        USBRESET        : out   std_logic;                     
        USBIFCLK        : out   std_logic;                     
        USBSLOE         : out   std_logic;                     
        USBPKTEND       : out   std_logic;                     
        USBFLAGD        : out   std_logic;                     
        USBSLWR         : out   std_logic;                     
        USBSLRD         : out   std_logic;                     
        USBFIFOADR      : out   std_logic_vector(2 downto 0); 
        USB_FD          : inout std_logic_vector(15 downto 0);
        USBINT          : in    std_logic;                     
        USBREADY        : in    std_logic;                     
        USBFLAGC        : in    std_logic;                     
        USBFLAGB        : in    std_logic;                     
        USBFLAGA        : in    std_logic;                     
        CD              : inout std_logic_vector(31 downto 0); 
        VA              : inout std_logic_vector(0 to 7);      
        VD              : inout std_logic_vector(31 downto 0)  
    );
END COMPONENT;


  --> FPGA designs declaration here ----------------------------------------------------------------------------

component gandalf_mem_top is
    generic (
        sim : INTEGER
    );
    port (
    -- Clocks
        GTPD0_P                 : in  std_logic;
        GTPD0_N                 : in  std_logic;
        CLK_40MHZ_VQDR          : in  std_logic;
    -- V5 I/O
        RXP                     : in  std_logic;
        RXN                     : in  std_logic;
        TXP                     : out std_logic;
        TXN                     : out std_logic;
    -- DDR PORTS
        c0_ddr2_dq              : inout std_logic_vector(7 downto 0);
        c0_ddr2_a               : out   std_logic_vector(13 downto 0);
        c0_ddr2_ba              : out   std_logic_vector(2 downto 0);
        c0_ddr2_ras_n           : out   std_logic;
        c0_ddr2_cas_n           : out   std_logic;
        c0_ddr2_we_n            : out   std_logic;
        c0_ddr2_cs_n            : out   std_logic_vector(1 downto 0);
        c0_ddr2_odt             : out   std_logic;
        c0_ddr2_cke             : out   std_logic;
        c0_ddr2_dqs             : inout std_logic_vector(0 downto 0);
        c0_ddr2_dqs_n           : inout std_logic_vector(0 downto 0);
        c0_ddr2_ck              : out   std_logic;
        c0_ddr2_ck_n            : out   std_logic;
        c1_ddr2_dq              : inout std_logic_vector(7 downto 0);
        c1_ddr2_ras_n           : out   std_logic;
        c1_ddr2_cas_n           : out   std_logic;
        c1_ddr2_we_n            : out   std_logic;
        c1_ddr2_cs_n            : out   std_logic_vector(1 downto 0);
        c1_ddr2_odt             : out   std_logic;
        c1_ddr2_cke             : out   std_logic;
        c1_ddr2_dqs             : inout std_logic_vector(0 downto 0);
        c1_ddr2_dqs_n           : inout std_logic_vector(0 downto 0);
        c1_ddr2_ck              : out   std_logic;
        c1_ddr2_ck_n            : out   std_logic;
    -- QA/DQA PORTS 
        QA                      :  in   std_logic_vector (7 downto 0);
        DQA                     :  in   std_logic_vector (7 downto 0)
    );
end component;

-- QDR components
-- component cy7c1515bv18_c0 is
--     port (
--         D           : in    std_logic_vector(35 downto 0);
--         Q           : out   std_logic_vector(35 downto 0);
--         A           : in    std_logic_vector(18 downto 0);
--         RPS_n       : in    std_logic;
--         WPS_n       : in    std_logic;
--         BW_n        : in    std_logic_vector(3 downto 0);
--         K           : in    std_logic;
--         K_n         : in    std_logic;
--         C           : in    std_logic;
--         C_n         : in    std_logic;
--         CQ          : out   std_logic;
--         CQ_N        : out   std_logic
--     );
-- end component;
-- 
component adc is
 port (
     analog      : in    real;
     clk         : in    std_logic;
     dry_p       : out   std_logic;
     dry_n       : out   std_logic;
     data_p      : out   std_logic_vector(13 downto 0);
     data_n      : out   std_logic_vector(13 downto 0)
 );
end component;

-- DDR2 components
-- component HYx18T1G800C2x_c0 is
--     port (
--         CK          : in    std_logic;
--         bCK         : in    std_logic;
--         CKE         : in    std_logic;
--         bCS         : in    std_logic;
--         bRAS        : in    std_logic;
--         bCAS        : in    std_logic;
--         bWE         : in    std_logic;
--         BA          : in    std_logic_vector(2 downto 0);
--         Addr        : in    std_logic_vector(13 downto 0);
--         DQ          : inout std_logic_vector(7 downto 0);
--         DQS         : inout std_logic;
--         bDQS        : inout std_logic;
--         DM_RDQS     : inout std_logic;
--         bRDQS       : inout std_logic;
--         ODT         : in    std_logic;
--         term        : out   std_logic_vector(1 downto 0)
--     );
-- end component;

component ddr2_model_c0 is
    port (
        ck          : in    std_logic;
        ck_n        : in    std_logic;
        cke         : in    std_logic;
        cs_n        : in    std_logic;
        ras_n       : in    std_logic;
        cas_n       : in    std_logic;
        we_n        : in    std_logic;
        dm_rdqs     : inout std_logic_vector(0 downto 0);
        ba          : in    std_logic_vector(2 downto 0);
        addr        : in    std_logic_vector(13 downto 0);
        dq          : inout std_logic_vector(7 downto 0);
        dqs         : inout std_logic_vector(0 downto 0);
        dqs_n       : inout std_logic_vector(0 downto 0);
        rdqs_n      : out   std_logic_vector(0 downto 0);
        odt         : in    std_logic
    );
end component;

component WireDelay
    generic (
        Delay_g     : time;
        Delay_rd    : time
    );
    port (
        A           : inout std_logic;
        B           : inout std_logic;
     reset          : in    std_logic
    );
end component;
------------------------------------------------------------------




--*************************Parameter Declarations**************************
    constant  CLOCKPERIOD_1     : time := 12.86 ns; -- era 6.43 ns; -- era 13.33 ns;
    constant  CLOCKPERIOD_2     : time := 13.33 ns;
    constant  CLOCKPERIOD_3     : time := 25 ns;

    constant CLK_CPLD_period    : time := 25 ns;
    constant CLK_80MHZ_period   : time := 16 ns;
    constant CLK_SI_period      : time := 2.143347 ns;  
    constant CLK_ADC_period     : time := 4.286694 ns;  --2.143347 ns
    constant CLK_ARW_period     : time := 2.143347 ns; 

    constant  DLY               : time := 1 ns;

    constant LANE_SKEW0         : time := 0 ns;


--********************************Signal Declarations**********************************

--Freerunning Clock
    signal reference_clk_1_n_r      : std_logic;
    signal reference_clk_2_n_r      : std_logic;
    signal reference_clk_1_p_r      : std_logic;
    signal reference_clk_2_p_r      : std_logic;

    signal CLK_CPLD                 : std_logic := '0';
    signal CLK_80MHZ                : std_logic := '0';

    signal si_b_clk_p               : std_logic;
    signal si_b_clk_n               : std_logic;

--Reset
    signal reset_i                  : std_logic;
    signal gt_reset_i               : std_logic;

--Dut1


    --V5 DSP Serial I/O
    signal   rxp_1_i                :  std_logic;
    signal   rxn_1_i                :  std_logic;

    signal   txp_1_i                :  std_logic;
    signal   txn_1_i                :  std_logic;

    --V5 MEM Serial I/O 
    signal   rxp_2_i                :  std_logic;
    signal   rxn_2_i                :  std_logic;

    signal   txp_2_i                :  std_logic;
    signal   txn_2_i                :  std_logic;


    signal udata1,udata2            : std_logic_vector(31 downto 0);
    signal URESET1,URESET2          : std_logic;
    signal UTEST1,UTEST2            : std_logic;
    signal UDW1,UDW2                : std_logic_vector(1 downto 0);
    signal UCTRL1,UCTRL2            : std_logic;
    signal UWEN1,UWEN2              : std_logic;
    signal UCLK1,UCLK2              : std_logic;
    
    signal VLD1,VLD2,LFF            : std_logic;
    signal CLK_40MHZ_VDSP           : std_logic;
    signal si_g_clk_n,si_g_clk_p          : std_logic;
    signal CLK_ADC                  : std_logic_vector(ADC_channels-1 downto 0);
    signal CLK_ADC_src              : std_logic;
    
    --CPLD input
    signal UCDGPO1                  :   std_logic := '1';
    signal UCDGPO2                  :   std_logic := '1';

    --CPLD <--> FPGA
    signal VA                       :   std_logic_vector(0 to 7) := (others => 'Z');
    signal VD                       :   std_logic_vector(31 downto 0);
    signal CSRESET                  :   std_logic;


-- QDR signals
--    signal c0_qdr_w_n_sram          : std_logic;
--    signal c0_qdr_w_n_fpga          : std_logic;
--    signal c0_qdr_r_n_sram          : std_logic;
--    signal c0_qdr_r_n_fpga          : std_logic;
--    signal c0_qdr_dll_off_n_sram    : std_logic;
--    signal c0_qdr_dll_off_n_fpga    : std_logic;
--    signal c0_qdr_k_sram            : std_logic_vector((C0_QDRII_CLK_WIDTH - 1) downto 0);
--    signal c0_qdr_k_fpga            : std_logic_vector((C0_QDRII_CLK_WIDTH - 1) downto 0);
--    signal c0_qdr_k_n_sram          : std_logic_vector((C0_QDRII_CLK_WIDTH - 1) downto 0);
--    signal c0_qdr_k_n_fpga          : std_logic_vector((C0_QDRII_CLK_WIDTH - 1) downto 0);
--    signal c0_qdr_c                 : std_logic_vector((C0_QDRII_CLK_WIDTH - 1) downto 0);
--    signal c0_qdr_c_n               : std_logic_vector((C0_QDRII_CLK_WIDTH - 1) downto 0);
--    signal c0_qdr_sa_sram           : std_logic_vector((C0_QDRII_ADDR_WIDTH - 1) downto 0);
--    signal c0_qdr_sa_fpga           : std_logic_vector((C0_QDRII_ADDR_WIDTH - 1) downto 0);
--    signal c0_qdr_bw_n_sram         : std_logic_vector((C0_QDRII_BW_WIDTH - 1) downto 0);
--    signal c0_qdr_bw_n_fpga         : std_logic_vector((C0_QDRII_BW_WIDTH - 1) downto 0);
--    signal c0_qdr_d_sram            : std_logic_vector((C0_QDRII_DATA_WIDTH - 1) downto 0);
--    signal c0_qdr_d_fpga            : std_logic_vector((C0_QDRII_DATA_WIDTH - 1) downto 0);
--    signal c0_qdr_q_fpga            : std_logic_vector((C0_QDRII_DATA_WIDTH - 1) downto 0);
--    signal c0_qdr_q_sram            : std_logic_vector((C0_QDRII_DATA_WIDTH - 1) downto 0);
--    signal c0_qdr_cq_fpga           : std_logic_vector((C0_QDRII_CQ_WIDTH - 1) downto 0);
--    signal c0_qdr_cq_sram           : std_logic_vector((C0_QDRII_CQ_WIDTH - 1) downto 0);
--    signal c0_qdr_cq_n_fpga         : std_logic_vector((C0_QDRII_CQ_WIDTH - 1) downto 0);
--    signal c0_qdr_cq_n_sram         : std_logic_vector((C0_QDRII_CQ_WIDTH - 1) downto 0); 
--    signal c1_qdr_w_n_sram          : std_logic;
--    signal c1_qdr_w_n_fpga          : std_logic;
--    signal c1_qdr_r_n_sram          : std_logic;
--    signal c1_qdr_r_n_fpga          : std_logic;
--    signal c1_qdr_dll_off_n_sram    : std_logic;
--    signal c1_qdr_dll_off_n_fpga    : std_logic;
--    signal c1_qdr_k_sram            : std_logic_vector((C1_QDRII_CLK_WIDTH - 1) downto 0);
--    signal c1_qdr_k_fpga            : std_logic_vector((C1_QDRII_CLK_WIDTH - 1) downto 0);
--    signal c1_qdr_k_n_sram          : std_logic_vector((C1_QDRII_CLK_WIDTH - 1) downto 0);
--    signal c1_qdr_k_n_fpga          : std_logic_vector((C1_QDRII_CLK_WIDTH - 1) downto 0);
--    signal c1_qdr_c                 : std_logic_vector((C1_QDRII_CLK_WIDTH - 1) downto 0);
--    signal c1_qdr_c_n               : std_logic_vector((C1_QDRII_CLK_WIDTH - 1) downto 0);
--    signal c1_qdr_sa_sram           : std_logic_vector((C1_QDRII_ADDR_WIDTH - 1) downto 0);
--    signal c1_qdr_sa_fpga           : std_logic_vector((C1_QDRII_ADDR_WIDTH - 1) downto 0);
--    signal c1_qdr_bw_n_sram         : std_logic_vector((C1_QDRII_BW_WIDTH - 1) downto 0);
--    signal c1_qdr_bw_n_fpga         : std_logic_vector((C1_QDRII_BW_WIDTH - 1) downto 0);
--    signal c1_qdr_d_sram            : std_logic_vector((C1_QDRII_DATA_WIDTH - 1) downto 0);
--    signal c1_qdr_d_fpga            : std_logic_vector((C1_QDRII_DATA_WIDTH - 1) downto 0);
--    signal c1_qdr_q_fpga            : std_logic_vector((C1_QDRII_DATA_WIDTH - 1) downto 0);
--    signal c1_qdr_q_sram            : std_logic_vector((C1_QDRII_DATA_WIDTH - 1) downto 0);
--    signal c1_qdr_cq_fpga           : std_logic_vector((C1_QDRII_CQ_WIDTH - 1) downto 0);
--    signal c1_qdr_cq_sram           : std_logic_vector((C1_QDRII_CQ_WIDTH - 1) downto 0);
--    signal c1_qdr_cq_n_fpga         : std_logic_vector((C1_QDRII_CQ_WIDTH - 1) downto 0);
--    signal c1_qdr_cq_n_sram         : std_logic_vector((C1_QDRII_CQ_WIDTH - 1) downto 0);
--

-- DAQ QA signals
    signal dqa_i,dqa_ii,qa_i,qa_ii  :std_logic_vector(7 downto 0):= (others => '0');

-- DDR signals
    signal c0_ddr2_dq_sdram         : std_logic_vector(7 downto 0);
    signal c0_ddr2_dq_fpga          : std_logic_vector(7 downto 0);
    signal c0_ddr2_dqs_sdram        : std_logic_vector(0 downto 0);
    signal c0_ddr2_dqs_fpga         : std_logic_vector(0 downto 0);
    signal c0_ddr2_dqs_n_sdram      : std_logic_vector(0 downto 0);
    signal c0_ddr2_dqs_n_fpga       : std_logic_vector(0 downto 0);
    signal c0_ddr2_dm_sdram         : std_logic_vector(0 downto 0);
    signal c0_ddr2_dm_fpga          : std_logic;
    signal c0_ddr2_clk_sdram        : std_logic;
    signal c0_ddr2_clk_fpga         : std_logic;
    signal c0_ddr2_clk_n_sdram      : std_logic;
    signal c0_ddr2_clk_n_fpga       : std_logic;
    signal c0_ddr2_address_sdram    : std_logic_vector((C0_DDR2_ROW_WIDTH - 1) downto 0);
    signal c0_ddr2_address_fpga     : std_logic_vector((C0_DDR2_ROW_WIDTH - 1) downto 0);
    signal c0_ddr2_ba_sdram         : std_logic_vector((C0_DDR2_BANK_WIDTH - 1) downto 0);
    signal c0_ddr2_ba_fpga          : std_logic_vector((C0_DDR2_BANK_WIDTH - 1) downto 0);
    signal c0_ddr2_ras_n_sdram      : std_logic;
    signal c0_ddr2_ras_n_fpga       : std_logic;
    signal c0_ddr2_cas_n_sdram      : std_logic;
    signal c0_ddr2_cas_n_fpga       : std_logic;
    signal c0_ddr2_we_n_sdram       : std_logic;
    signal c0_ddr2_we_n_fpga        : std_logic;
    signal c0_ddr2_cs_n_sdram       : std_logic_vector(1 downto 0);
    signal c0_ddr2_cs_n_fpga        : std_logic_vector(1 downto 0);
    signal c0_ddr2_cke_sdram        : std_logic;
    signal c0_ddr2_cke_fpga         : std_logic;
    signal c0_ddr2_odt_sdram        : std_logic;
    signal c0_ddr2_odt_fpga         : std_logic;

    signal c1_ddr2_dq_sdram         : std_logic_vector(7 downto 0);
    signal c1_ddr2_dq_fpga          : std_logic_vector(7 downto 0);
    
    signal c1_ddr2_dqs_sdram        : std_logic_vector(0 downto 0);
    signal c1_ddr2_dqs_fpga         : std_logic_vector(0 downto 0);
    signal c1_ddr2_dqs_n_sdram      : std_logic_vector(0 downto 0);
    signal c1_ddr2_dqs_n_fpga       : std_logic_vector(0 downto 0);
    signal c1_ddr2_dm_sdram         : std_logic_vector(0 downto 0);
    signal c1_ddr2_dm_fpga          : std_logic;
    signal c1_ddr2_clk_sdram        : std_logic;
    signal c1_ddr2_clk_fpga         : std_logic;
    signal c1_ddr2_clk_n_sdram      : std_logic;
    signal c1_ddr2_clk_n_fpga       : std_logic;
    signal c1_ddr2_address_sdram    : std_logic_vector((C1_DDR2_ROW_WIDTH - 1) downto 0);
    signal c1_ddr2_address_fpga     : std_logic_vector((C1_DDR2_ROW_WIDTH - 1) downto 0);
    signal c1_ddr2_ba_sdram         : std_logic_vector((C1_DDR2_BANK_WIDTH - 1) downto 0);
    signal c1_ddr2_ba_fpga          : std_logic_vector((C1_DDR2_BANK_WIDTH - 1) downto 0);
    signal c1_ddr2_ras_n_sdram      : std_logic;
    signal c1_ddr2_ras_n_fpga       : std_logic;
    signal c1_ddr2_cas_n_sdram      : std_logic;
    signal c1_ddr2_cas_n_fpga       : std_logic;
    signal c1_ddr2_we_n_sdram       : std_logic;
    signal c1_ddr2_we_n_fpga        : std_logic;
    signal c1_ddr2_cs_n_sdram       : std_logic_vector(1 downto 0);
    signal c1_ddr2_cs_n_fpga        : std_logic_vector(1 downto 0);
    signal c1_ddr2_cke_sdram        : std_logic;
    signal c1_ddr2_cke_fpga         : std_logic;
    signal c1_ddr2_odt_sdram        : std_logic;
    signal c1_ddr2_odt_fpga         : std_logic;
    
    signal sys_rst_n                : std_logic;
    
    signal TCS_CLK_P_i              : std_logic;
    signal TCS_CLK_N_i              : std_logic;
    signal TCS_DATA_P_i             : std_logic;
    signal TCS_DATA_N_i             : std_logic;

    signal tcs_rate                 : std_logic;

    -- signal in std_logic_vector2 for simulation post Behavioral
    -- type std_logic_vector2 is array (integer range <>, integer range <>) of std_logic;

    signal PORT_P_delT2             : std_logic_vector2(ADC_CHANNELS-1 downto 0,14 downto 0); 
    signal PORT_N_delT2             : std_logic_vector2(ADC_CHANNELS-1 downto 0,14 downto 0); 


    signal VXS_A_P_i                : std_logic_vector(7 downto 0):= (others => '0');
    signal VXS_A_N_i                : std_logic_vector(7 downto 0):= (others => '0');

    signal PORT_P                   : ADC_ports(ADC_CHANNELS-1 downto 0); --All 16 Ports pos @ADCs
    signal PORT_N                   : ADC_ports(ADC_CHANNELS-1 downto 0); --All 16 Ports neg @ADCs
    
    signal PORT_P_delT              : ADC_ports(ADC_CHANNELS-1 downto 0); --All 16 Ports pos @with propagation delay
    signal PORT_N_delT              : ADC_ports(ADC_CHANNELS-1 downto 0); --All 16 Ports neg @with propagation delay

    SIGNAL ADC_DATA_P               : ADC_ports(ADC_CHANNELS-1 downto 0); --ADC Ports 0 to 15 pos.
    SIGNAL ADC_DATA_N               : ADC_ports(ADC_CHANNELS-1 downto 0); --ADC Ports 0 to 15 neg.-

    signal NIM_IN_UPi               : std_logic;
    signal NIM_OUT1_UPi             : std_logic;
    signal NIM_OUT2_UPi             : std_logic;
    signal NIM_IN_DNi               : std_logic;
    signal NIM_OUT2_DNi             : std_logic;
    
    signal SI_SCLi                  : std_logic;
    signal SI_SDAi                  : std_logic;
    signal GP_SCLi                  : std_logic_vector(1 downto 0);
    signal GP_SDAi                  : std_logic_vector(1 downto 0);
    
    signal DONE                     : std_logic := '0';
    -- ARWEN PROG SIGNALS
    signal arwen_prog_out_p         : std_logic;         
    signal arwen_prog_out_n         : std_logic;
    signal arwen_init_in_p          : std_logic:='0';
    signal arwen_init_in_n          : std_logic:='1';
    signal arwen_done_in_p          : std_logic:='1';
    signal arwen_done_in_n          : std_logic:='0';
    signal arwen_d0_p               : std_logic;
    signal arwen_d0_n               : std_logic;
    signal arwen_cclk_out_p         : std_logic;
    signal arwen_cclk_out_n         : std_logic;
    -- ARWEN DATA SIGNALS    
    signal arwen_data_clk_p         : std_logic;
    signal arwen_data_clk_n         : std_logic;
    signal arwen_data_a_p           : std_logic_vector(15 downto 0):=(others=>'0');
    signal arwen_data_a_n           : std_logic_vector(15 downto 0):=(others=>'1');
    signal arwen_data_c_p           : std_logic_vector(15 downto 0):=(others=>'0');
    signal arwen_data_c_n           : std_logic_vector(15 downto 0):=(others=>'1');
    signal arwen_data_b_p           : std_logic_vector(31 downto 0);
    signal arwen_data_b_n           : std_logic_vector(31 downto 0);
    signal arwen_cs                 : std_logic_vector(3 downto 0);
    alias arwen_clk                 : std_logic is arwen_data_clk_p;
    alias arwen_data                : std_logic_vector(31 downto 0) is arwen_data_b_p;
    alias arwen_wen                 : std_logic is arwen_data_c_p(0);
    alias arwen_ff                  : std_logic_vector(3 downto 0) is arwen_data_a_p(3 downto 0);
    alias arwen_add                 : std_logic_vector(3 downto 0) is arwen_data_c_p(4 downto 1);
    alias arwen_rdy                 : std_logic is arwen_data_a_p(8);
    alias arwen_rst                 : std_logic is arwen_data_c_p(15);
    -- GPIO SIGNALS
    -- added to gandalf_module
    -- signal gp_pin_o              : std_logic_vector(4 downto 0);
begin


  -- inst GIMLI CARD, signal type (OCX or TCS) is done in tcs_controller
  
  inst_VXS_GIMLI: if  BS_GIMLI_TYPE = "VXS" generate
    TCS_CLK_P_i <= TCS_DATA_P_i;
    TCS_CLK_N_i <= TCS_DATA_N_i;
  end generate;

  inst_other_GIMLI: if  BS_GIMLI_TYPE /= "VXS" generate

    TCS_CLK_P_i <= TCS_CLK_P;
    TCS_CLK_N_i <= TCS_CLK_N;

    TCS_DATA_P_i <= TCS_DATA_P;
    TCS_DATA_N_i <= TCS_DATA_N;

  end generate;

  -- dataout <= udata1 or udata2;
  -- dataout <= udata2;
  dataout <= arwen_data_b_p;

  -- Instantiation  of the CPLD
  inst_cpld:  vmetop
  PORT MAP (
        BSYSRES         => '1',
        CA              => CA,
        CAM             => CAM,
        CAS             => CAS,
        CDS0            => CDS0,
        CDS1            => CDS1,
        CIACK           => '1',
        CLK_CPLD        => CLK_CPLD,
        CLK_80MHZ       => CLK_80MHZ,
        --CLWORD        => CA(0),
        CWRITE          => CWRITE,
        DIP             => DIP,
        DONE            => DONE,
        GA              => GA,
        INIT_B          => '1',
        SN              => SN,
        UCDGPO1         => UCDGPO1,
        UCDGPO2         => UCDGPO2,
        CCLK            => open,
        CDIR0           => open,
        CDIR1           => open,
        CDTACK          => CDTACK,
        CBERR           => CBERR,
        CSRESET         => CSRESET,
        DCS             => open,
        DISPCLK         => open,
        DISPDATA        => open,
        DISPLOAD        => open,
        --LED4           => open,
        LED6            => open,
        LED7            => open,
        MCS             => open,
        M0              => open,
        M1              => open,
        M2              => open,
        OBUF_EN         => open,
        PROGRAM_B       => open,
        QA              => qa_i, --for memory FPGA
        RDWR_B          => open,
        SYSACERES       => open,
        USBRESET        => open,
        USBIFCLK        => open,
        USBSLOE         => open,
        USBPKTEND       => open,
        USBFLAGD        => open,
        USBSLWR         => open,
        USBSLRD         => open,
        USBFIFOADR      => open,
        USB_FD          => open,
        USBINT          => '1',
        USBREADY        => '1',
        USBFLAGC        => '0',
        USBFLAGB        => '0',
        USBFLAGA        => '0',
        CD              => CD,
        VA              => VA,
        VD              => VD
    );

  --> instantiate FPGA designs here ---------------------------------------------------------

    inst_dsp_fpga : entity work.gbase_top
    GENERIC MAP(
      GEN_ACCEL_SIM      =>  GEN_ACCEL_SIM              -- Behavioral simulation = GEN_SIMULATION; other simulation commented these line;
    )
    PORT MAP(
    -- CLOCK
        CLK_40MHZ_VDSP      =>  CLK_40MHZ_VDSP,
        CLK_SI_VDSPn        =>  si_g_clk_n,
        CLK_SI_VDSPp        =>  si_g_clk_p,                        
    -- CPLD IF           
        VD                  => VD,
        VA_Write            => VA(0), --VA_Write
        VA_Strobe           => VA(1), --VA_Strobe
        VA_Ready            => VA(2), --VA_Ready
        VA_Control          => VA(3), --VA_Control
        VA_uBlaze           => VA(4), --VA_uBlaze
        VA_FifoFull         => VA(5), --VA_FifoFull
        VA_FifoEmpty        => VA(6), --VA_FifoEmpty
        VA_SpyRead          => VA(7), --VA_Reset                        
    -- SI CTRL           
        SI_A_LOS            => '0',
        SI_A_LOL            => '0',
        SI_A_RST            => open,
        SI_B_LOS            => '0',
        SI_B_LOL            => '0',
        SI_B_RST            => open,
        SI_G_LOS            => '0',
        SI_G_LOL            => '0',
        SI_G_RST            => open,                            
    -- IIC IF           
        iic_si_scl          => SI_SCLi,
        iic_si_sda          => SI_SDAi,
        iic_gp_scl          => GP_SCLi,
        iic_gp_sda          => GP_SDAi,                            
    -- aurora ports     
        GTPD0_P             => reference_clk_1_p_r,
        GTPD0_N             => reference_clk_1_n_r,
        RXP                 => rxp_1_i,
        RXN                 => rxn_1_i,
        TXP                 => txp_1_i,
        TXN                 => txn_1_i,
    -- slink ports
        VUD                 => udata2,
        VLFF                => LFF,
        VURESET             => URESET2,
        VUTEST              => UTEST2,
        VUDW                => UDW2,
        VUCTRL              => UCTRL2,
        VUWEN               => UWEN2,
        VUCLK               => UCLK2,
        VLDOWN              => VLD2,
    -- daq ports
        DQA                 => dqa_ii,
    -- AMC inputs
        amc_port_p          => PORT_P_delT,    -- Behavioral simulation = PORT_P_delT; other simulation = PORT_P_delT2;
        amc_port_n          => PORT_N_delT,    -- Behavioral simulation = PORT_N_delT; other simulation = PORT_N_delT2;
      
    -- ARWEN 1 program ports                            ADDED  
        arwen_prog_out_p    => arwen_prog_out_p,  
        arwen_prog_out_n    => arwen_prog_out_n,  
        arwen_init_in_p     => arwen_init_in_p,   
        arwen_init_in_n     => arwen_init_in_n,   
        arwen_done_in_p     => arwen_done_in_p,   
        arwen_done_in_n     => arwen_done_in_n,   
        arwen_d0_p          => arwen_d0_p,        
        arwen_d0_n          => arwen_d0_n,        
        arwen_cclk_out_p    => arwen_cclk_out_p,  
        arwen_cclk_out_n    => arwen_cclk_out_n,  
    -- ARWEN 1 data ports                              ADDED
        arwen_data_a_p      => arwen_data_a_p,     
        arwen_data_a_n      => arwen_data_a_n,     
        arwen_data_c_p      => arwen_data_c_p,     
        arwen_data_c_n      => arwen_data_c_n,     
        arwen_data_b_p      => arwen_data_b_p,     
        arwen_data_b_n      => arwen_data_b_n,     
        arwen_data_clk_p    => arwen_data_clk_p,   
        arwen_data_clk_n    => arwen_data_clk_n,   
    -- si_b_clk from ARWEN                              ADDED
        MEZZ_B_DR_P         => si_b_clk_p,
        MEZZ_B_DR_N         => si_b_clk_n,
                              
    --vxs tiger ports
        VXS_A_P             => VXS_A_P_i,
        VXS_A_N             => VXS_A_N_i,
        VXS_B_P             => VXS_B_P,
        VXS_B_N             => VXS_B_N,
        VXS_SCL             => VXS_SCL,
        VXS_SDA             => VXS_SDA,

    -- trigger front panel led
        trg_led             => open,                    -- ADDED 2bit
    -- gimli ports
        tcs_lock            => '1',
        tcs_rate            => tcs_rate,                -- ADDED 1bit

        tcs_clk_p           => TCS_CLK_P_i,
        tcs_clk_n           => TCS_CLK_N_i,
        tcs_data_p          => TCS_DATA_P_i,
        tcs_data_n          => TCS_DATA_N_i,
        
    -- general purpose pins
        gp                  => gp_pin_o                 -- ADDED 5bit
    );

    arwen_init_in_p <= not arwen_prog_out_p; 
    arwen_init_in_n <= not arwen_prog_out_n;

      inst_tcs: for i in 6 to 7 generate
          VXS_A_P_i(i)<=VXS_A_P(i);
          VXS_A_N_i(i)<=VXS_A_N(i);
      end generate;

      inst_sl: for i in 0 to 5 generate
          VXS_A_P(i)<=VXS_A_P_i(i);
          VXS_A_N(i)<=VXS_A_N_i(i);
      end generate;

    NIM_IN_UPi          <=  NIM_IN_UP;
    NIM_OUT1_UP         <=  NIM_OUT1_UPi;
    NIM_OUT2_UP         <=  NIM_OUT2_UPi;
    NIM_IN_DNi          <=  NIM_IN_DN;
    NIM_OUT1_DN         <=  NIM_OUT1_UPi; --special internal feature: this output is connected to NIM_OUT1_UP
    NIM_OUT2_DN         <=  NIM_OUT2_DNi;


  --terminate IIC buses
    SI_SCLi             <='H';
    SI_SDAi             <='H';
    GP_SCLi             <="HH";
    GP_SDAi             <="HH";

-- ARWEN FPGA
inst_Arwen_fpga :
    with arwen_add select
    arwen_cs <= ("000" & arwen_wen)         when "0000",
                ("00" & arwen_wen & '0')    when "0001",
                ("0" & arwen_wen & "00")    when "0010",
                (arwen_wen & "000")         when "0011",
                "0000"                      when others;
    -- The Arwen fifo's
    inst_Arwen_fifos: for i in 0 to 3 generate 
        inst_Arwen_fifo :  entity work.the_spy_fifo
            port map (
                wr_clk => arwen_clk,
                rd_clk => arwen_clk,
                din => arwen_data,
                rd_en => '1',
                rst => arwen_rst,
                wr_en => arwen_cs(i),
                dout => open,
                empty => open,
                full => arwen_ff(i),
                prog_full => open
            );
    end generate;
-- inst_Arwen_fpga : FIFO36
--     generic map (
--         ALMOST_FULL_OFFSET      => X"0080",         -- Sets almost full threshold
--         ALMOST_EMPTY_OFFSET     => X"0080",         -- Sets the almost empty threshold
--         DATA_WIDTH              => 36,              -- Sets data width to 4, 9, 18, or 36
--         DO_REG                  => 1,               -- Enable output register ( 0 or 1)
--                                                     -- Must be 1 if the EN_SYN = FALSE
--         EN_SYN                  => FALSE,           -- Specified FIFO as Asynchronous (FALSE) or 
--                                                     -- Synchronous (TRUE)
--         FIRST_WORD_FALL_THROUGH => TRUE,            -- Sets the FIFO FWFT to TRUE or FALSE
--         SIM_MODE                => "FAST")          -- Simulation: "SAFE" vs "FAST", see "Synthesis and Simulation 
--                                                     -- Design Guide" for details
--     port map (
--         ALMOSTEMPTY => open,                        -- 1-bit almost empty output flag
--         ALMOSTFULL  => open,                        -- 1-bit almost full output flag
--         DO          => open,                        -- 32-bit data output
--         DOP         => open,                        -- 4-bit parity data output
--         EMPTY       => open,                        -- 1-bit empty output flag
--         FULL        => arwen_ff,             -- 1-bit full output flag
--         RDCOUNT     => open,                        -- 13-bit read count output
--         RDERR       => open,                        -- 1-bit read error output
--         WRCOUNT     => open,                        -- 13-bit write count output
--         WRERR       => open,                        -- 1-bit write error
--         DI          => arwen_data_b_p,              -- 32-bit data input
--         DIP         => (others => '0'),             -- 4-bit parity input
--         RDCLK       => arwen_data_clk_p,            -- 1-bit read clock input
--         RDEN        => '1',                         -- 1-bit read enable input
--         RST         => reset_i,                     -- 1-bit reset input
--         WRCLK       => arwen_data_clk_p,            -- 1-bit write clock input
--         WREN        => arwen_wen             -- 1-bit write enable input
--         );

-- Instantiate ADCs
inst_amc: if BS_MCS_UP = "AMC" OR BS_MCS_DN = "AMC" generate
    inst_adcs : for ADCs_i in 0 to (ADC_CHANNELS-1) generate
        inst_adc: adc
        PORT MAP (
            analog          => analog_in(ADCs_i),               --Analog signal
            clk             => CLK_ADC(ADCs_i),                 --sampling clock
            DRY_p           => PORT_P(ADCs_i)(14),              -- si_a_clk_p
            DRY_n           => PORT_N(ADCs_i)(14),              -- si_a_clk_n
            data_p          => PORT_P(ADCs_i)(13 downto 0),     --sampled Data in DDR
            data_n          => PORT_N(ADCs_i)(13 downto 0)
        );
    end generate;
end generate;

inst_mem_fpga : gandalf_mem_top
    generic map (
        sim => 1
    )
    port map (
    -- Clock Signals
        GTPD0_P                 => reference_clk_1_p_r,
        GTPD0_N                 => reference_clk_1_n_r,
        CLK_40MHZ_VQDR          => CLK_40MHZ_VDSP,
    -- V5 I/O
        RXP                     => rxp_2_i,
        RXN                     => rxn_2_i,
        TXP                     => txp_2_i,
        TXN                     => txn_2_i,
    -- DDR PORT
        c0_ddr2_dq              => c0_ddr2_dq_fpga,
        c0_ddr2_a               => c0_ddr2_address_fpga,
        c0_ddr2_ba              => c0_ddr2_ba_fpga,
        c0_ddr2_ras_n           => c0_ddr2_ras_n_fpga,
        c0_ddr2_cas_n           => c0_ddr2_cas_n_fpga,
        c0_ddr2_we_n            => c0_ddr2_we_n_fpga,
        c0_ddr2_cs_n            => c0_ddr2_cs_n_fpga,
        c0_ddr2_odt             => c0_ddr2_odt_fpga,
        c0_ddr2_cke             => c0_ddr2_cke_fpga,
        c0_ddr2_dqs             => c0_ddr2_dqs_fpga,
        c0_ddr2_dqs_n           => c0_ddr2_dqs_n_fpga,
        c0_ddr2_ck              => c0_ddr2_clk_fpga,
        c0_ddr2_ck_n            => c0_ddr2_clk_n_fpga,
    
        c1_ddr2_dq              => c1_ddr2_dq_fpga,
        c1_ddr2_ras_n           => c1_ddr2_ras_n_fpga,
        c1_ddr2_cas_n           => c1_ddr2_cas_n_fpga,
        c1_ddr2_we_n            => c1_ddr2_we_n_fpga,
        c1_ddr2_cs_n            => c1_ddr2_cs_n_fpga,
        c1_ddr2_odt             => c1_ddr2_odt_fpga,
        c1_ddr2_cke             => c1_ddr2_cke_fpga,
        c1_ddr2_dqs             => c1_ddr2_dqs_fpga,
        c1_ddr2_dqs_n           => c1_ddr2_dqs_n_fpga,
        c1_ddr2_ck              => c1_ddr2_clk_fpga,
        c1_ddr2_ck_n            => c1_ddr2_clk_n_fpga,
    
        DQA                     => dqa_i,
        QA                      => qa_ii
    );

-- QDR not used ...
--    QDRII_MEM_C0: cy7c1515bv18_c0
--        port map (
--        D          => c0_qdr_d_sram,
--        Q          => c0_qdr_q_sram,
--        A          => c0_qdr_sa_sram,
--        RPS_n      => c0_qdr_r_n_sram,
--        WPS_n      => c0_qdr_w_n_sram,
--        BW_n       => c0_qdr_bw_n_sram,
--        K          => c0_qdr_k_sram(0),
--        K_n        => c0_qdr_k_n_sram(0),
--        C          => c0_qdr_c(0),
--        C_n        => c0_qdr_c_n(0),
--        CQ         => c0_qdr_cq_sram(0),
--        CQ_n       => c0_qdr_cq_n_sram(0)
--        );
--
--    QDRII_MEM_C1: cy7c1515bv18_c0
--        port map (
--        D          => c1_qdr_d_sram,
--        Q          => c1_qdr_q_sram,
--        A          => c1_qdr_sa_sram,
--        RPS_n      => c1_qdr_r_n_sram,
--        WPS_n      => c1_qdr_w_n_sram,
--        BW_n       => c1_qdr_bw_n_sram,
--        K          => c1_qdr_k_sram(0),
--        K_n        => c1_qdr_k_n_sram(0),
--        C          => c1_qdr_c(0),
--        C_n        => c1_qdr_c_n(0),
--        CQ         => c1_qdr_cq_sram(0),
--        CQ_n       => c1_qdr_cq_n_sram(0)
--        );
--
--    c0_qdr_w_n_sram            <= TRANSPORT c0_qdr_w_n_fpga            after TPROP_PCB_CTRL;
--    c0_qdr_r_n_sram            <= TRANSPORT c0_qdr_r_n_fpga            after TPROP_PCB_CTRL;
--    --c0_qdr_dll_off_n_sram      <= TRANSPORT c0_qdr_dll_off_n_fpga      after TPROP_PCB_CTRL;
--    c0_qdr_k_sram              <= TRANSPORT c0_qdr_k_fpga              after TPROP_PCB_CTRL;
--    c0_qdr_k_n_sram            <= TRANSPORT c0_qdr_k_n_fpga            after TPROP_PCB_CTRL;
--    c0_qdr_sa_sram             <= TRANSPORT c0_qdr_sa_fpga             after TPROP_PCB_CTRL;
--    c0_qdr_bw_n_sram           <= TRANSPORT c0_qdr_bw_n_fpga           after TPROP_PCB_CTRL;
--    c0_qdr_d_sram              <= TRANSPORT c0_qdr_d_fpga              after TPROP_PCB_CTRL;
--    c0_qdr_q_fpga              <= TRANSPORT c0_qdr_q_sram              after TPROP_PCB_CTRL;
--    c0_qdr_cq_fpga             <= TRANSPORT c0_qdr_cq_sram             after TPROP_PCB_CTRL;
--    c0_qdr_cq_n_fpga           <= TRANSPORT c0_qdr_cq_n_sram           after TPROP_PCB_CTRL;
--    c1_qdr_w_n_sram            <= TRANSPORT c1_qdr_w_n_fpga            after TPROP_PCB_CTRL;
--    c1_qdr_r_n_sram            <= TRANSPORT c1_qdr_r_n_fpga            after TPROP_PCB_CTRL;
--    --c1_qdr_dll_off_n_sram      <= TRANSPORT c1_qdr_dll_off_n_fpga      after TPROP_PCB_CTRL;
--    c1_qdr_k_sram              <= TRANSPORT c1_qdr_k_fpga              after TPROP_PCB_CTRL;
--    c1_qdr_k_n_sram            <= TRANSPORT c1_qdr_k_n_fpga            after TPROP_PCB_CTRL;
--    c1_qdr_sa_sram             <= TRANSPORT c1_qdr_sa_fpga             after TPROP_PCB_CTRL;
--    c1_qdr_bw_n_sram           <= TRANSPORT c1_qdr_bw_n_fpga           after TPROP_PCB_CTRL;
--    c1_qdr_d_sram              <= TRANSPORT c1_qdr_d_fpga              after TPROP_PCB_CTRL;
--    c1_qdr_q_fpga              <= TRANSPORT c1_qdr_q_sram              after TPROP_PCB_CTRL;
--    c1_qdr_cq_fpga             <= TRANSPORT c1_qdr_cq_sram             after TPROP_PCB_CTRL;
--    c1_qdr_cq_n_fpga           <= TRANSPORT c1_qdr_cq_n_sram           after TPROP_PCB_CTRL;



--***************************************************************************
-- Memory model instances
--***************************************************************************


--  -- These modules are broken !
--
--    DDR2_MEM_C0: HYx18T1G800C2x_c0
--        port map (
--            CK         => c0_ddr2_clk_sdram,
--            bCK        => c0_ddr2_clk_n_sdram,
--            CKE        => c0_ddr2_cke_sdram,
--            bCS        => '0',--c0_ddr2_cs_n_sdram(0),
--            bRAS       => c0_ddr2_ras_n_sdram,
--            bCAS       => c0_ddr2_cas_n_sdram,
--            bWE        => c0_ddr2_we_n_sdram,
--            BA         => c0_ddr2_ba_sdram,
--            Addr       => c0_ddr2_address_sdram,
--            DQ         => c0_ddr2_dq_sdram,
--            DQS        => c0_ddr2_dqs_sdram(0),
--            bDQS       => c0_ddr2_dqs_n_sdram(0),
--            DM_RDQS    => c0_ddr2_dm_sdram(0),
--            bRDQS      => open,
--            ODT        => c0_ddr2_odt_sdram,
--            term       => open
--        );
--  
--    DDR2_MEM_C1: HYx18T1G800C2x_c0
--        port map (
--            CK         => c1_ddr2_clk_sdram,
--            bCK        => c1_ddr2_clk_n_sdram,
--            CKE        => c1_ddr2_cke_sdram,
--            bCS        => '0',--c1_ddr2_cs_n_sdram(0),
--            bRAS       => c1_ddr2_ras_n_sdram,
--            bCAS       => c1_ddr2_cas_n_sdram,
--            bWE        => c1_ddr2_we_n_sdram,
--            BA         => c1_ddr2_ba_sdram,
--            Addr       => c1_ddr2_address_sdram,
--            DQ         => c1_ddr2_dq_sdram,
--            DQS        => c1_ddr2_dqs_sdram(0),
--            bDQS       => c1_ddr2_dqs_n_sdram(0),
--            DM_RDQS    => c1_ddr2_dm_sdram(0),
--            bRDQS      => open,
--            ODT        => c1_ddr2_odt_sdram,
--            term       => open
--        );
--
-- DDR used ... non funge ...

    DDR2_MEM_C0: ddr2_model_c0
       port map (
               ck         => c0_ddr2_clk_sdram,
                ck_n       => c0_ddr2_clk_n_sdram,
                cke        => c0_ddr2_cke_sdram,
                cs_n       => c0_ddr2_cs_n_sdram(0),
                ras_n      => c0_ddr2_ras_n_sdram,
                cas_n      => c0_ddr2_cas_n_sdram,
                we_n       => c0_ddr2_we_n_sdram,
                dm_rdqs    => c0_ddr2_dm_sdram,
                ba         => c0_ddr2_ba_sdram,
                addr       => c0_ddr2_address_sdram,
                dq         => c0_ddr2_dq_sdram,
                dqs        => c0_ddr2_dqs_sdram,
                dqs_n      => c0_ddr2_dqs_n_sdram,
                rdqs_n     => open,
                odt        => c0_ddr2_odt_sdram
        );

    DDR2_MEM_C1: ddr2_model_c0
       port map (
               ck         => c1_ddr2_clk_sdram,
                ck_n       => c1_ddr2_clk_n_sdram,
                cke        => c1_ddr2_cke_sdram,
                cs_n       => c1_ddr2_cs_n_sdram(0),
                ras_n      => c1_ddr2_ras_n_sdram,
                cas_n      => c1_ddr2_cas_n_sdram,
                we_n       => c1_ddr2_we_n_sdram,
                dm_rdqs    => c1_ddr2_dm_sdram,
                ba         => c1_ddr2_ba_sdram,
                addr       => c1_ddr2_address_sdram,
                dq         => c1_ddr2_dq_sdram,
                dqs        => c1_ddr2_dqs_sdram,
                dqs_n      => c1_ddr2_dqs_n_sdram,
                rdqs_n     => open,
                odt        => c1_ddr2_odt_sdram
        );


  --***************************************************************************
  -- Delay insertion modules for each signal
  --***************************************************************************
  -- Use standard non-inertial (transport) delay mechanism for unidirectional
  -- signals from FPGA to SDRAM

    c0_ddr2_clk_sdram          <= TRANSPORT c0_ddr2_clk_fpga           after TPROP_PCB_CTRL;
    c0_ddr2_clk_n_sdram        <= TRANSPORT c0_ddr2_clk_n_fpga         after TPROP_PCB_CTRL;
    c0_ddr2_address_sdram      <= TRANSPORT c0_ddr2_address_fpga       after TPROP_PCB_CTRL;
    c0_ddr2_ba_sdram           <= TRANSPORT c0_ddr2_ba_fpga            after TPROP_PCB_CTRL;
    c0_ddr2_ras_n_sdram        <= TRANSPORT c0_ddr2_ras_n_fpga         after TPROP_PCB_CTRL;
    c0_ddr2_cas_n_sdram        <= TRANSPORT c0_ddr2_cas_n_fpga         after TPROP_PCB_CTRL;
    c0_ddr2_we_n_sdram         <= TRANSPORT c0_ddr2_we_n_fpga          after TPROP_PCB_CTRL;
    c0_ddr2_cs_n_sdram         <= TRANSPORT c0_ddr2_cs_n_fpga          after TPROP_PCB_CTRL;
    c0_ddr2_cke_sdram          <= TRANSPORT c0_ddr2_cke_fpga           after TPROP_PCB_CTRL;
    c0_ddr2_odt_sdram          <= TRANSPORT c0_ddr2_odt_fpga           after TPROP_PCB_CTRL;

    c1_ddr2_clk_sdram          <= TRANSPORT c1_ddr2_clk_fpga           after TPROP_PCB_CTRL;
    c1_ddr2_clk_n_sdram        <= TRANSPORT c1_ddr2_clk_n_fpga         after TPROP_PCB_CTRL;

    c1_ddr2_address_sdram      <= TRANSPORT c0_ddr2_address_fpga       after TPROP_PCB_CTRL;
    c1_ddr2_ba_sdram           <= TRANSPORT c0_ddr2_ba_fpga            after TPROP_PCB_CTRL;

    c1_ddr2_ras_n_sdram        <= TRANSPORT c1_ddr2_ras_n_fpga         after TPROP_PCB_CTRL;
    c1_ddr2_cas_n_sdram        <= TRANSPORT c1_ddr2_cas_n_fpga         after TPROP_PCB_CTRL;
    c1_ddr2_we_n_sdram         <= TRANSPORT c1_ddr2_we_n_fpga          after TPROP_PCB_CTRL;
    c1_ddr2_cs_n_sdram         <= TRANSPORT c1_ddr2_cs_n_fpga          after TPROP_PCB_CTRL;
    c1_ddr2_cke_sdram          <= TRANSPORT c1_ddr2_cke_fpga           after TPROP_PCB_CTRL;
    c1_ddr2_odt_sdram          <= TRANSPORT c1_ddr2_odt_fpga           after TPROP_PCB_CTRL;


dq_delay0: for i0 in 0 to C0_DDR2_DQ_WIDTH - 1 generate
u_delay_dq0: WireDelay
    generic map (
        Delay_g     => TPROP_PCB_DATA,
        Delay_rd    => TPROP_PCB_DATA_RD
    )
    port map(
        A           => c0_ddr2_dq_fpga(i0),
        B           => c0_ddr2_dq_sdram(i0),
        reset       => sys_rst_n
    );
end generate;

u_delay_dqs0: WireDelay
    generic map (
        Delay_g     => TPROP_DQS,
        Delay_rd    => TPROP_DQS_RD
    )
    port map(
        A           => c0_ddr2_dqs_fpga(0),
        B           => c0_ddr2_dqs_sdram(0),
        reset       => sys_rst_n);

u_delay_dqs0_n: WireDelay
    generic map (
        Delay_g     => TPROP_DQS,
        Delay_rd    => TPROP_DQS_RD
    )
    port map(
        A           => c0_ddr2_dqs_n_fpga(0),
        B           => c0_ddr2_dqs_n_sdram(0),
        reset       => sys_rst_n
    );


dq_delay1: for i1 in 0 to C1_DDR2_DQ_WIDTH - 1 generate
u_delay_dq1: WireDelay
    generic map (
        Delay_g     => TPROP_PCB_DATA,
        Delay_rd    => TPROP_PCB_DATA_RD
    )
    port map(
        A           => c1_ddr2_dq_fpga(i1),
        B           => c1_ddr2_dq_sdram(i1),
        reset       => sys_rst_n
    );
end generate;

u_delay_dqs1: WireDelay
    generic map (
        Delay_g     => TPROP_DQS,
        Delay_rd    => TPROP_DQS_RD
        )
    port map (
        A           => c1_ddr2_dqs_fpga(0),
        B           => c1_ddr2_dqs_sdram(0),
        reset       => sys_rst_n
    );

u_delay_dqs1_n: WireDelay
    generic map (
        Delay_g     => TPROP_DQS,
        Delay_rd    => TPROP_DQS_RD
        )
    port map(
        A           => c1_ddr2_dqs_n_fpga(0),
        B           => c1_ddr2_dqs_n_sdram(0),
        reset   => sys_rst_n
        );


c0_ddr2_dm_sdram <= (others => '0');
c1_ddr2_dm_sdram <= (others => '0');

------------------------------------------------------------------------------------

    --_________________________DQA Connections______________________
    dqa_i(0)        <=  TRANSPORT dqa_ii(0);
    dqa_i(1)        <=  TRANSPORT dqa_ii(1);
    dqa_i(2)        <=  TRANSPORT dqa_ii(2);
    dqa_i(3)        <=  TRANSPORT dqa_ii(3);
    dqa_i(4)        <=  TRANSPORT dqa_ii(4);
    dqa_i(5)        <=  TRANSPORT dqa_ii(5);
    dqa_i(6)        <=  TRANSPORT dqa_ii(6);
    dqa_i(7)        <=  TRANSPORT dqa_ii(7);

    --_________________________QA Connections______________________
    qa_i(0)         <=  TRANSPORT qa_ii(0);
    qa_i(1)         <=  TRANSPORT qa_ii(1);
    qa_i(2)         <=  TRANSPORT qa_ii(2);
    qa_i(3)         <=  TRANSPORT qa_ii(3);
    qa_i(4)         <=  TRANSPORT qa_ii(4);
    qa_i(5)         <=  TRANSPORT qa_ii(5);
    qa_i(6)         <=  TRANSPORT qa_ii(6);
    qa_i(7)         <=  TRANSPORT qa_ii(7);

    --_________________________V5 Serial Connections________________

    rxn_1_i      <=  TRANSPORT txn_2_i after LANE_SKEW0;
    rxp_1_i      <=  TRANSPORT txp_2_i after LANE_SKEW0;

    rxn_2_i      <=  TRANSPORT txn_1_i after LANE_SKEW0;
    rxp_2_i      <=  TRANSPORT txp_1_i after LANE_SKEW0;
    
                                                    
  --  startup
    startup_process :process
    begin
        wait for 1.0 us;
        UCDGPO1 <= '0';
        UCDGPO2 <= '0';
        wait for CLK_CPLD_period/2;
    end process;

    fpga_done :process
    begin
        wait for 100 ns;
        DONE <= '1';
        wait;
    end process;

--____________________________Clocks____________________________
    CLK_CPLD_process :process
    begin
        CLK_CPLD <= '0';
        wait for CLK_CPLD_period/2;
        CLK_CPLD <= '1';
        wait for CLK_CPLD_period/2;
    end process;

--Si located on GANDALF Board
    CLK_SI_process :process
    begin
        si_g_clk_p <= '0';
        wait for CLK_SI_period/2;
        si_g_clk_p <= '1';
        wait for CLK_SI_period/2;
    end process;
    si_g_clk_n <= not si_g_clk_p;

--Si located on ARWEN Board
    CLK_ARW_process :process
    begin
        si_b_clk_p <= '0';
        wait for CLK_ARW_period/2;
        si_b_clk_p <= '1';
        wait for CLK_ARW_period/2;
    end process;
    si_b_clk_n <= not si_b_clk_p;

    inst_amc_clk: if BS_MCS_UP = "AMC" OR BS_MCS_DN = "AMC" generate
        --Si clocks on AMCs
        CLK_ADC_process :process
        begin
            CLK_ADC_src <= '0';
            wait for CLK_ADC_period/2;
            CLK_ADC_src <= '1';
            wait for CLK_ADC_period/2;
        end process;

        -- select sampling mode  --RDM(3): 0 normal, 1 ilm
        normal_mode : if GEN_RDM(3) = '0' generate
        begin
            inst_nml_clk : for ADCs_i in 0 to (ADC_CHANNELS-1) GENERATE
                CLK_ADC(ADCs_i)<=CLK_ADC_src;
                -- added by Alex
                PORT_P_delT(ADCs_i)   <=  TRANSPORT PORT_P(ADCs_i) AFTER 0 ns;
                PORT_N_delT(ADCs_i)   <=  TRANSPORT PORT_N(ADCs_i) AFTER 0 ns;
                inst_port_bits: for port_bits in 0 to 14 generate
                    PORT_P_delT2(ADCs_i,port_bits)   <=  TRANSPORT PORT_P(ADCs_i)(port_bits) AFTER 0 ns;
                    PORT_N_delT2(ADCs_i,port_bits)   <=  TRANSPORT PORT_N(ADCs_i)(port_bits) AFTER 0 ns;
                end generate;
                PORT_P_delT(ADCs_i)   <=  TRANSPORT PORT_P(ADCs_i) AFTER 0 ns;
                PORT_N_delT(ADCs_i)   <=  TRANSPORT PORT_N(ADCs_i) AFTER 0 ns;
            end generate;
        end generate;

        interleaved_mode : if GEN_RDM(3) = '1' generate
        begin
            inst_ilm_clk : for ADCs_i in 0 to ((ADC_CHANNELS-1)/2) GENERATE
                CLK_ADC(2*ADCs_i)  <= CLK_ADC_src;
                CLK_ADC(2*ADCs_i+1)<= NOT(CLK_ADC_src);

                PORT_P_delT(2*ADCs_i)   <=  TRANSPORT PORT_P(2*ADCs_i) AFTER 2 ns;
                PORT_N_delT(2*ADCs_i)   <=  TRANSPORT PORT_N(2*ADCs_i) AFTER 2 ns;
                PORT_P_delT(2*ADCs_i+1) <=  TRANSPORT PORT_P(2*ADCs_i+1) AFTER 0 ns;
                PORT_N_delT(2*ADCs_i+1) <=  TRANSPORT PORT_N(2*ADCs_i+1) AFTER 0 ns;
                inst_port_bits: for port_bits in 0 to 14 generate
                    PORT_P_delT2(2*ADCs_i,port_bits)   <=  TRANSPORT PORT_P(ADCs_i)(port_bits) AFTER 2 ns;
                    PORT_N_delT2(2*ADCs_i,port_bits)   <=  TRANSPORT PORT_N(ADCs_i)(port_bits) AFTER 2 ns;
                    PORT_P_delT2(2*ADCs_i+1,port_bits)   <=  TRANSPORT PORT_P(2*ADCs_i+1)(port_bits) AFTER 0 ns;
                    PORT_N_delT2(2*ADCs_i+1,port_bits)   <=  TRANSPORT PORT_N(2*ADCs_i+1)(port_bits) AFTER 0 ns;
                end generate;
            end generate;
        end generate;
    end generate;



   CLK_80MHZ_process :process
   begin
        CLK_80MHZ <= '0';
        wait for CLK_80MHZ_period/2;
        CLK_80MHZ <= '1';
        wait for CLK_80MHZ_period/2;
   end process;
    process
    begin
        reference_clk_1_p_r <= '0';
        wait for CLOCKPERIOD_1 / 2;
        reference_clk_1_p_r <= '1';
        wait for CLOCKPERIOD_1 / 2;
    end process;

    reference_clk_1_n_r <= not reference_clk_1_p_r;

    process
    begin
        reference_clk_2_p_r <= '0';
        wait for CLOCKPERIOD_2 / 2;
        reference_clk_2_p_r <= '1';
        wait for CLOCKPERIOD_2 / 2;
    end process;

    reference_clk_2_n_r <= not reference_clk_2_p_r;

    process
    begin
        CLK_40MHZ_VDSP <= '0';
        wait for CLOCKPERIOD_3 / 2;
        CLK_40MHZ_VDSP <= '1';
        wait for CLOCKPERIOD_3 / 2;
    end process;

    --____________________________Resets____________________________

    process
    begin
        reset_i     <= '1';
        sys_rst_n   <= '0';
        wait for 200 ns;
        reset_i     <= '0';
        sys_rst_n   <= '1';
        wait;
    end process;

    --____________________________Reseting PMA____________________________

    process
    begin
        gt_reset_i <= '1';
        wait for 16*CLOCKPERIOD_1;
        gt_reset_i <= '0';
        wait;
    end process;

   LFF <= '1';
   VLD1 <= '1';
   VLD2 <= '1';


end Behavioral;

