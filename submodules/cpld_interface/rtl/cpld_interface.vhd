library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;
use IEEE.NUMERIC_STD.all;
use WORK.G_PARAMETERS.all;
library UNISIM;
use UNISIM.VCOMPONENTS.all;

entity cpld_if is
    generic(
        GEN_ACCEL_SIM : boolean := FALSE
        );
    port (
        control             : inout std_logic_vector (35 downto 0);
        D                   : inout std_logic_vector (31 downto 0);  -- Data Bus to/from CPLD
        f_Write             : in    std_logic;
        f_Strobe            : in    std_logic;
        f_Ready             : out   std_logic;
        f_Control           : in    std_logic;
        f_uBlaze            : in    std_logic;
        f_FifoFull          : out   std_logic;
        f_FifoEmpty         : out   std_logic;
        f_Reset             : in    std_logic;

        CLK_40MHZ_VDSP      : in  std_logic;  -- 40 MHz from CDCE949
        CLK_40MHZ_OUT       : out std_logic;
        nCLK_40MHZ_OUT      : out std_logic;
        CLK_120MHZ_OUT      : out std_logic;
        CLK_200MHZ_OUT      : out std_logic;
        pll_200_locked      : out std_logic;

        RST_Startup_1_OUT   : out std_logic;
        RST_Startup_2_OUT   : out std_logic;
        RST_Startup_3_OUT   : out std_logic;

        SLINK_init_done     : in std_logic;
        SI_init_done        : in std_logic;
        GP_INIT_DONE        : in std_logic := '0';
        SI_FLAGS            : in std_logic_vector(8 downto 0); -- not used

        Spy_Din             : in  std_logic_vector (31 downto 0);
        Spy_CLK             : in  std_logic;
        Spy_WR              : in  std_logic;
        Spy_RST             : in  std_logic;
        Spy_Full            : out std_logic;
        Spy_Almost_Full     : out std_logic;

        config_mem_BRAM_Rst : in  std_logic;
        config_mem_BRAM_Clk : in  std_logic;
        config_mem_BRAM_EN  : in  std_logic;
        config_mem_BRAM_WEN : in  std_logic_vector(3 downto 0);
        config_mem_BRAM_Addr: in  std_logic_vector(15 downto 0);
        config_mem_BRAM_Din : in  std_logic_vector(31 downto 0);
        config_mem_BRAM_Dout: out std_logic_vector(31 downto 0);

        FastRegister        : out std_logic_vector(255 downto 0) := (others => '0')
        );
end cpld_if;

architecture Behavioral of cpld_if is

    signal D_fromCPLD : std_logic_vector (31 downto 0);
    signal D_toCPLD   : std_logic_vector (31 downto 0);
    signal D_dir      : std_logic := '1';

    signal Spy_RD       : std_logic := '0';
    signal sReady       : std_logic := '0';
    signal sStrobe      : std_logic := '0';
    signal sStrobe_temp : std_logic := '0';
    signal sSpy_Full    : std_logic := '0';
    signal Spy_Dout     : std_logic_vector (31 downto 0) := x"00000000";
    signal sSpy_Empty   : std_logic;
    signal sSpy_Afull   : std_logic;

    signal CLK_40MHZ     : std_logic;
    signal nCLK_40MHZ    : std_logic;
    signal CLK_120MHZ    : std_logic;
    signal CLK_200MHZ    : std_logic;
    signal CLK_240MHZ    : std_logic;
    signal CLK_240MHZ_90 : std_logic;
    signal PLL1_LOCKED   : std_logic := '0';

    signal RST_Startup_1 : std_logic := '1';
    signal RST_Startup_2 : std_logic := '1';
    signal RST_Startup_3 : std_logic := '1';

    signal init_done : std_logic := '0';
    
    signal PhysMemoryAddr   : std_logic_vector (15 downto 0) := "1000000000011111";
    alias MemoryAddr        : std_logic_vector (9 downto 0) is PhysMemoryAddr(14 downto 5);
    signal MemoryOut        : std_logic_vector (31 downto 0) := x"00000000";
    signal MemoryIn         : std_logic_vector (31 downto 0) := x"00000000";
    signal MemoryWE         : std_logic_vector (3 downto 0)  := x"0";

    constant SOURCE_ID      : bit_vector ( 7 downto 0) := to_bitvector(GEN_SOURCE_ID); --new
    constant TIMESTAMP_BASE : bit_vector (31 downto 0) := to_bitvector(GEN_TIMESTAMP_BASE);  --new 
    constant FRAMEWIDTH_bv  : bit_vector (15 downto 0) := to_bitvector(std_logic_vector(to_unsigned(GEN_FRAMEWIDTH,16)));   
    constant LATENCY_bv     : bit_vector (15 downto 0) := to_bitvector(std_logic_vector(to_unsigned(GEN_LATENCY,16)));      
    -- constant LATENCY_p01_bv : bit_vector (15 downto 0) := x"0000";  -- not used
    constant PRESCALER_bv   : bit_vector ( 7 downto 0) := to_bitvector(std_logic_vector(to_unsigned(GEN_PRESCALER,8)));    
    constant BASELINE_bv    : bit_vector (15 downto 0) := to_bitvector(std_logic_vector(to_unsigned(GEN_BASELINE,16)));    
    constant ZSUPP_bv       : bit_vector (15 downto 0) := x"0150";  --bit_vector(to_unsigned(GEN_LATENCY,16));
    constant RDM_bv         : bit_vector ( 3 downto 0) := to_bitvector(GEN_RDM);
    -- Ana constant fraction (G_CONF5)
    constant FRAC_bv        : bit_vector ( 7 downto 0) := to_bitvector(std_logic_vector(to_unsigned(GEN_FRACTION,8)));     
    constant DELAY_bv       : bit_vector ( 7 downto 0) := to_bitvector(std_logic_vector(to_unsigned(GEN_DELAY,8)));        
    constant THRESHOLD_bv   : bit_vector ( 7 downto 0) := to_bitvector(std_logic_vector(to_unsigned(GEN_THRESHOLD,8)));      
    constant MAX_DIST_bv    : bit_vector ( 7 downto 0) := to_bitvector(std_logic_vector(to_unsigned(GEN_MAX_DIST,8)));     
    -- Tiger constant fraction (G_CONF7)
    constant T_THRESHOLD_bv : bit_vector (15 downto 0) := to_bitvector(std_logic_vector(to_unsigned(GEN_T_THRESHOLD,16))); 
    constant T_MAX_DIST_bv  : bit_vector ( 7 downto 0) := to_bitvector(std_logic_vector(to_unsigned(GEN_T_MAX_DIST,8)));   
    -- ARWEN IP ADDRESS
    constant IP_DEST_0      : bit_vector (31 downto 0) := to_bitvector(GEN_IP_DEST_0);
    constant IP_DEST_1      : bit_vector (31 downto 0) := to_bitvector(GEN_IP_DEST_1);
    constant IP_DEST_2      : bit_vector (31 downto 0) := to_bitvector(GEN_IP_DEST_2);
    constant IP_DEST_3      : bit_vector (31 downto 0) := to_bitvector(GEN_IP_DEST_3);
    constant IP_SOURCE_0    : bit_vector (31 downto 0) := to_bitvector(GEN_IP_SOURCE_0);
    constant IP_SOURCE_1    : bit_vector (31 downto 0) := to_bitvector(GEN_IP_SOURCE_1);
    constant IP_SOURCE_2    : bit_vector (31 downto 0) := to_bitvector(GEN_IP_SOURCE_2);
    constant IP_SOURCE_3    : bit_vector (31 downto 0) := to_bitvector(GEN_IP_SOURCE_3);
    constant MAC_ADDR_0     : bit_vector (47 downto 0) := to_bitvector(GEN_MAC_ADDR_0);
    constant MAC_ADDR_1     : bit_vector (47 downto 0) := to_bitvector(GEN_MAC_ADDR_1);
    constant MAC_ADDR_2     : bit_vector (47 downto 0) := to_bitvector(GEN_MAC_ADDR_2);
    constant MAC_ADDR_3     : bit_vector (47 downto 0) := to_bitvector(GEN_MAC_ADDR_3);

    constant START_ADDR     : bit_vector (31 downto 0) := to_bitvector(GEN_START_ADDR);
    constant END_ADDR       : bit_vector (31 downto 0) := to_bitvector(GEN_END_ADDR);

    signal FastRegADDR        : std_logic_vector (7 downto 0) := x"00";
    signal FastRegCMD         : std_logic_vector (7 downto 0) := x"00";
    signal FastRegUPD         : std_logic                     := '0';
    signal FastRegUPDfinished : std_logic                     := '0';

    signal command : std_logic_vector (2 downto 0);

    signal config_mem_BRAM_Addr_i : std_logic_vector(15 downto 0);

    -- ILA Components and signals
    component spyfifo_ila
        PORT (
            CONTROL     : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
            CLK         : IN STD_LOGIC;
            DATA        : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
            TRIG0       : IN STD_LOGIC_VECTOR(7 DOWNTO 0)
            );
    
    end component;

    signal ila_trig     : std_logic_vector( 7 downto 0);
    signal ila_data     : std_logic_vector(63 downto 0);


begin
    CLK_40MHZ_OUT  <= CLK_40MHZ;
    nCLK_40MHZ_OUT <= nCLK_40MHZ;
    CLK_120MHZ_OUT <= CLK_120MHZ;

    RST_Startup_1_OUT <= RST_Startup_1;
    RST_Startup_2_OUT <= RST_Startup_2;
    RST_Startup_3_OUT <= '0';

    init_done <= SLINK_init_done and SI_init_done;  -- add internal init here

    command <= f_Write & f_uBlaze & f_Control;

    strobe_synchronizer : process(CLK_240MHZ)
    begin
        if (CLK_240MHZ'event and CLK_240MHZ = '1') then
            sStrobe_temp <= f_Strobe;
            sStrobe      <= sStrobe_temp;
                                        --sStrobe <= f_Strobe;

        end if;
    end process strobe_synchronizer;


    reset_logic : block -- macchinetta fatta a cazzo la prendiamo per buona
        type   states is (wait_for_lock, reset1, reset2, done);
        signal state  : states                  := wait_for_lock;
        signal LOOP_A : integer range 0 to 1023 := 7;
    begin
        reset_logic_proc : process(CLK_40MHZ_VDSP)
            variable nxt_state      : states;
            variable iLOOP_A        : integer range 0 to 1023;  --was 7 before, but gp_if needs longer delay
            variable iRST_Startup_1 : std_logic;
            variable iRST_Startup_2 : std_logic;
            variable iRST_Startup_3 : std_logic;
        begin
            nxt_state      := state;
            iLOOP_A        := LOOP_A;
            iRST_Startup_1 := RST_Startup_1;
            iRST_Startup_2 := RST_Startup_2;
            iRST_Startup_3 := RST_Startup_3;
            iRST_Startup_3 := '0';
            if(iLOOP_A > 0 and PLL1_LOCKED = '1') then
                iLOOP_A := iLOOP_A-1;
            else
                if GEN_ACCEL_SIM = false then  --long time between resets, this solves "header mismatch" in gandalf_status
                    iLOOP_A := 1023;
                else                    --fast resets for simulation
                    iLOOP_A := 7;
                end if;
            end if;

            case (state) is
                when wait_for_lock =>
                    if(LOOP_A = 0) then
                        iRST_Startup_1 := '0';
                        nxt_state      := reset1;
                    end if;
                when reset1 =>
                    if(LOOP_A = 0) then
                        if GP_INIT_DONE = '1' then
                            iRST_Startup_2 := '0';
                            nxt_state      := reset2;
                        end if;
                    end if;
                when reset2 =>
                        iRST_Startup_3 := '0';
                        nxt_state      := done;
                when others =>
                    null;
            end case;

            if (CLK_40MHZ_VDSP'event and CLK_40MHZ_VDSP = '1') then
                state         <= nxt_state;
                LOOP_A        <= iLOOP_A;
                RST_Startup_1 <= iRST_Startup_1;
                RST_Startup_2 <= iRST_Startup_2;
            end if;
        end process reset_logic_proc;
    end block reset_logic;

                                        -- Bus Direction
    D_dir <= (not f_Strobe) when (f_Write = '0' and f_Control = '0')  -- write on Data Bus
             else '1';                  -- read from Data Bus

                                        -- Data to CPLD
    D_toCPLD <= Spy_Dout when (f_Write = '0' and f_uBlaze = '0')
                else MemoryOut;

                                        -- FIFO full flags
    Spy_Full   <= sSpy_Full;
                                        --f_FifoFull <= InFifo_Full when (command="101")
                                        --              else sSpy_Full;
    f_FifoFull <= sSpy_Full;


                                        -- CPLD interface statemachine
    interface_statemachine : block
        type   states is (wait_for_rising_strobe, wait_state, wait_for_falling_strobe, spy_read_end);
        signal state     : states                        := wait_for_rising_strobe;
        signal tMemoryWE : std_logic_vector (3 downto 0) := x"0";
                                        --signal tInFifo_Write      : std_logic :='0';
        signal tSpy_RD   : std_logic                     := '0';
    begin
        nxt_state_decoder : process(CLK_240MHZ)
            variable nxt_state   : states;
                                        --variable iFastReg : std_logic_vector (31 downto 0);
            variable iReady      : std_logic;
                                        --variable iInFifo_Write : std_logic;
                                        --variable iFifoIn : std_logic_vector (31 downto 0);
            variable iSpy_RD     : std_logic;
            variable iMemoryAddr : std_logic_vector (9 downto 0);
            variable iMemoryIn   : std_logic_vector (31 downto 0);
            variable iMemoryWE   : std_logic_vector (3 downto 0);

            variable iFastRegADDR : std_logic_vector (7 downto 0);
            variable iFastRegCMD  : std_logic_vector (7 downto 0);
            variable iFastRegUPD  : std_logic;
            
        begin
            nxt_state   := state;
                                        --iFastReg := FastReg;
            iReady      := sReady;
--          iInFifo_Write := tInFifo_Write;
            --iInFifo_Write := '0';
            --iFifoIn := FifoIn;
            iSpy_RD     := tSpy_RD;
            iMemoryAddr := MemoryAddr;
            iMemoryIn   := MemoryIn;
--          iMemoryWE := tMemoryWE;
            iMemoryWE   := x"0";

            iFastRegADDR := FastRegADDR;
            iFastRegCMD  := FastRegCMD;
            iFastRegUPD  := FastRegUPD and (not FastRegUPDfinished);

            case (state) is
                when wait_for_rising_strobe =>
                    if (sStrobe = '1') then
                        case command is

                            when "101" =>  -- Address for FastReg
                                iFastRegADDR := D_fromCPLD(7 downto 0);
                                iReady       := '1';
                                nxt_state    := wait_for_falling_strobe;
                            when "100" =>  -- Data for FastReg
                                iFastRegCMD := D_fromCPLD(7 downto 0);
                                iFastRegUPD := '1';
                                iReady      := '1';
                                nxt_state   := wait_for_falling_strobe;
                                
                            when "111" =>  -- Address for Memory write
                                iMemoryAddr := D_fromCPLD(9 downto 0);
                                iReady      := '1';
                                nxt_state   := wait_for_falling_strobe;
                            when "110" =>  -- Data for Memory write
                                iMemoryIn := D_fromCPLD;
                                iMemoryWE := x"F";
                                iReady    := '1';
                                nxt_state := wait_state;

                            when "000" =>  -- Spy Read
                                iReady    := '1';
                                nxt_state := spy_read_end;
                            when "011" =>  -- Address for Memory read
                                iMemoryAddr := D_fromCPLD(9 downto 0);
                                iReady      := '1';
                                nxt_state   := wait_for_falling_strobe;
                            when "010" =>  -- Read Data from Memory
                                iReady    := '1';
                                nxt_state := wait_for_falling_strobe;

                            when others =>
                                null;
                        end case;
                    end if;
                    
                when wait_state =>
                    iMemoryWE := tMemoryWE;
                                        --iInFifo_Write := tInFifo_Write;
                    nxt_state := wait_for_falling_strobe;
                    
                when wait_for_falling_strobe =>
                                        --iInFifo_Write := '0';
                    iMemoryWE := x"0";

                    if (sStrobe = '0' and FastRegUPD = '0') then
                        iReady    := '0';
                        nxt_state := wait_for_rising_strobe;
                    end if;
                    
                    
                when spy_read_end =>
                    if (sStrobe = '0') then
                        iReady  := '0';
                        iSpy_RD := '1';
                    end if;
                    if (Spy_RD = '1') then
                        iSpy_RD   := '0';
                        nxt_state := wait_for_rising_strobe;
                    end if;
                    
                when others =>
                    nxt_state := wait_for_rising_strobe;

            end case;


                                        -- genregs
            if (CLK_240MHZ'event and CLK_240MHZ = '1') then
                if RST_Startup_1 = '1' then
                    state          <= wait_for_rising_strobe;
                                        --FastReg <= (others => '0');
                    sReady         <= '0';
                    f_Ready        <= '0';
                    PhysMemoryAddr <= "1000000000011111";
                    MemoryIn       <= (others => '0');
                                        --FifoIn <= (others => '0');

                    tMemoryWE <= x"0";
                                        --tInFifo_Write <= '0';
                    tSpy_RD   <= '0';

                    FastRegADDR <= (others => '0');
                    FastRegCMD  <= (others => '0');
                    FastRegUPD  <= '0';
                else
                    state      <= nxt_state;
                                        --FastReg <= iFastReg;
                    sReady     <= iReady;
                    f_Ready    <= sReady;
                    MemoryAddr <= iMemoryAddr;
                    MemoryIn   <= iMemoryIn;
                                        --FifoIn <= iFifoIn;

                    tMemoryWE <= iMemoryWE;
                                        --tInFifo_Write <= iInFifo_Write;
                    tSpy_RD   <= iSpy_RD;

                    FastRegADDR <= iFastRegADDR;
                    FastRegCMD  <= iFastRegCMD;
                    FastRegUPD  <= iFastRegUPD;
                end if;
            end if;

            if (CLK_120MHZ'event and CLK_120MHZ = '1') then
--              if RST_Startup_1 = '1' then
--                  InFifo_Write <= '0';
--                  Spy_RD <= '0';
--                  MemoryWE <= x"0";
--              else
                --InFifo_Write <= iInFifo_Write;
                Spy_RD   <= iSpy_RD;
                MemoryWE <= iMemoryWE;
--              end if;
            end if;
            
        end process nxt_state_decoder;
    end block interface_statemachine;



    fastreg_logic : block
        type   states is (idle, toggle_1, toggle_2);
        signal state : states := idle;
    begin
        fastreg_logic_proc : process(CLK_40MHZ)
            variable nxt_state     : states;
            variable signal_value  : std_logic;
            variable signal_update : std_logic;
            variable UPDfinished   : std_logic;
        begin
            nxt_state     := state;
            UPDfinished   := '0';
            signal_update := '0';
            signal_value  := '0';

            case (state) is
                when toggle_1 =>
                    nxt_state     := toggle_2;
                    signal_value  := '0';
                    signal_update := '1';
                when toggle_2 =>
                    nxt_state   := idle;
                    UPDfinished := '1';
                when idle =>
                    if (FastRegUPD = '1') then
                        if (FastRegCMD(1) = '1') then
                            nxt_state    := toggle_1;
                            signal_value := '1';
                        else
                            nxt_state    := toggle_2;
                            signal_value := FastRegCMD(0);
                        end if;
                        signal_update := '1';
                    end if;
                when others =>
                    nxt_state := idle;
            end case;

            if (CLK_40MHZ'event and CLK_40MHZ = '1') then
                state              <= nxt_state;
                FastRegUPDfinished <= UPDfinished;
                if (signal_update = '1') then
                    
                    for i in 0 to 255 loop
                        if(FastRegADDR = i) then FastRegister(i) <= signal_value; end if;
                    end loop;

                end if;
            end if;
        end process fastreg_logic_proc;
    end block fastreg_logic;

    -- era 65K x 4 byte, ridotta a 8k x 4 byte
    the_spy_fifo :  entity work.the_spy_fifo
    port map (
        wr_clk      => Spy_CLK,
        rd_clk      => CLK_120MHZ,
        din         => Spy_Din,
        rd_en       => Spy_RD,
        rst         => Spy_RST,
        wr_en       => Spy_WR,
        dout        => Spy_Dout,
        empty       => sSpy_Empty,
        full        => sSpy_Full,
        prog_full   => sSpy_Afull
    );

    f_FifoEmpty      <= sSpy_Empty;
    Spy_Almost_Full  <= sSpy_Afull;

    Inst_chipscope : if USE_CHIPSCOPE_ILA_0 generate

        the_spy_fifo_rd_ila : spyfifo_ila
        port map (
            CONTROL     => control,
            CLK         => CLK_120MHZ,
            DATA        => ila_data,
            TRIG0       => ila_trig
        );
        
        ila_trig <= Spy_RST & PLL1_LOCKED & sStrobe & '0' & Spy_RD & sSpy_Afull & sSpy_Full & sSpy_Empty;
        ila_data <= X"0000" & "00000" & command & ila_trig & Spy_Dout;

    end generate;


    Inst_clock_pll :  entity work.clock_pll port map(
        CLKIN1_IN  => CLK_40MHZ_VDSP,
        RST_IN     => '0',
        CLK_40MHZ  => CLK_40MHZ,
        CLK_120MHZ => CLK_120MHZ,
        CLK_200MHZ => CLK_200MHZ,
        CLK_240MHZ => CLK_240MHZ,
        LOCKED_OUT => PLL1_LOCKED
        );


    CLK_200MHZ_OUT <= CLK_200MHZ;
    pll_200_locked <= PLL1_LOCKED;

    DATA_PORTS :
    for i in 0 to 31 generate
    begin
        IOBUF_inst : IOBUF
            generic map (
                DRIVE      => 12,
                IOSTANDARD => "DEFAULT",
                SLEW       => "SLOW"
                )
            port map (
                O  => D_fromCPLD(i),    -- Buffer output
                IO => D(i),  -- Buffer inout port (connect directly to top-level port)
                I  => D_toCPLD(i),      -- Buffer input
                T  => D_dir  -- 3-state enable input, high=input, low=output 
                );      
    end generate;

                                        -- BRAM_TDP_MACRO: True Dual Port RAM
                                        --                 Virtex-5
                                        -- Xilinx HDL Language Template, version 11.1

    RAMB36_inst : RAMB36
        generic map (
                                        -- PORT A: FPGA side
                                        -- PORT B: CPLD side
            DOA_REG             => 0,  -- Optional output register on A port (0 or 1)
            DOB_REG             => 0,  -- Optional output register on B port (0 or 1)
            INIT_A              => X"000000000",  -- Initial values on A output port
            INIT_B              => X"000000000",  -- Initial values on B output port
            RAM_EXTENSION_A     => "NONE",  -- "UPPER", "LOWER" or "NONE" when cascaded
            RAM_EXTENSION_B     => "NONE",  -- "UPPER", "LOWER" or "NONE" when cascaded
            READ_WIDTH_A        => 36,  -- Valid values are 1, 2, 4, 9, 18, or 36
            READ_WIDTH_B        => 36,  -- Valid values are 1, 2, 4, 9, 18, or 36
            SIM_COLLISION_CHECK => "ALL",  -- Collision check enable "ALL", "WARNING_ONLY", "GENERATE_X_ONLY" or "NONE" 
            SIM_MODE            => "SAFE",  -- Simulation: "SAFE" vs "FAST", see "Synthesis and Simulation Design Guide" for details
            SRVAL_A             => X"000000000",  -- Set/Reset value for A port output
            SRVAL_B             => X"000000000",  -- Set/Reset value for B port output
            WRITE_MODE_A        => "READ_FIRST",  -- "WRITE_FIRST", "READ_FIRST" or "NO_CHANGE" 
            WRITE_MODE_B        => "READ_FIRST",  -- "WRITE_FIRST", "READ_FIRST" or "NO_CHANGE" 
            WRITE_WIDTH_A       => 36,  -- Valid values are 1, 2, 3, 4, 9, 18, 36
            WRITE_WIDTH_B       => 36,  -- Valid values are 1, 2, 3, 4, 9, 18, 36  
            -- The following INIT_xx declarations specify the initial contents of the RAM
            --AMC0       |  1C  ||  18  ||  18  ||  10  ||  0C  ||  08  ||  04  ||  00  |                                                                                      -- VME Addr
            INIT_00 => X"00000000000000000000000000000000000000003000000000000000A10C0000",             -- 0x000
            INIT_01 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x020
            INIT_02 => X"0000000000000000000000000000000000000000000000000000000001A000A0",             -- 0x040
            INIT_03 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x060
            INIT_04 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x080
            INIT_05 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x0A0
            INIT_06 => X"000000000000000000000000000000c288878886888588848883888288818880",             -- 0x0C0
            INIT_07 => X"0000000000000000000000000000000077777776777577747773777277717770",             -- 0x0E0
            --           |  1C  ||  18  ||  18  ||  10  ||  0C  ||  08  ||  04  ||  00  |
            INIT_08 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x100
            INIT_09 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x120
            INIT_0A => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x140
            INIT_0B => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x160
            INIT_0C => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x180
            INIT_0D => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x1A0
            INIT_0E => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x1C0
            INIT_0F => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x1E0
            --           |  1C  ||  18  ||  18  ||  10  ||  0C  ||  08  ||  04  ||  00  |
            INIT_10 => BS_SI_MCS_UP(255 downto 0),                                                      -- 0x200
            INIT_11 => BS_SI_MCS_UP(511 downto 256),                                                    -- 0x220                                                                                                        
            INIT_12 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x240
            INIT_13 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x260
            INIT_14 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x280
            INIT_15 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x2A0
            INIT_16 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x2C0
            INIT_17 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x2E0
            --           |  1C  ||  18  ||  18  ||  10  ||  0C  ||  08  ||  04  ||  00  |
            INIT_18 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x300
            INIT_19 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x320
            INIT_1A => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x340
            INIT_1B => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x360
            INIT_1C => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x380
            INIT_1D => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x3A0
            INIT_1E => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x3C0
            INIT_1F => X"AABBCC0000000000000000000000000000000000000000000000000000223344",             -- 0x3E0
            --OMC1       |  1C  ||  18  ||  18  ||  10  ||  0C  ||  08  ||  04  ||  00  |               -- DA RICONTROLLARE ...
            INIT_20 => X"00000000000000000000000000000000000000003000000000000000A11C2001",             -- 0x400
            INIT_21 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x420
            INIT_22 => X"0000000000000000000000000000000000000000000000000000000001A100A1",             -- 0x440
            INIT_23 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x460
            INIT_24 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x480
            INIT_25 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x4A0
            INIT_26 => X"0000" & MAC_ADDR_3 & X"0000" & MAC_ADDR_2 & 
                       X"0000" & MAC_ADDR_1 & X"0000" & MAC_ADDR_0,                                     -- 0x4C0
            INIT_27 => IP_SOURCE_3 & IP_SOURCE_2 & IP_SOURCE_1 & IP_SOURCE_0 &
                       IP_DEST_3 & IP_DEST_2 & IP_DEST_1 & IP_DEST_0,                                   -- 0x4E0
            --           |  1C  ||  18  ||  18  ||  10  ||  0C  ||  08  ||  04  ||  00  |
            INIT_28 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x500
            INIT_29 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x520
            INIT_2A => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x540
            INIT_2B => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x560
            INIT_2C => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x580
            INIT_2D => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x5A0
            INIT_2E => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x5C0
            INIT_2F => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x5E0
            --           |  1C  ||  18  ||  18  ||  10  ||  0C  ||  08  ||  04  ||  00  |
            INIT_30 => BS_SI_MCS_DN(255 downto 0),                                                      -- 0x600
            INIT_31 => BS_SI_MCS_DN(511 downto 256),                                                    -- 0x620
                                                                                                                
            INIT_32 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x640
            INIT_33 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x660
            INIT_34 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x680
            INIT_35 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x6A0
            INIT_36 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x6C0
            INIT_37 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x6E0
            --           |  1C  ||  18  ||  18  ||  10  ||  0C  ||  08  ||  04  ||  00  |
            INIT_38 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x700
            INIT_39 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x720
            INIT_3A => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x740
            INIT_3B => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x760
            INIT_3C => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x780
            INIT_3D => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x7A0
            INIT_3E => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x7C0
            INIT_3F => X"AABBCC1100000000000000000000000000000000000000000000000011223344",             -- 0x7E0

            --GANDALF    |  1C  ||  18  ||  18  ||  10  ||  0C  ||  08  ||  04  ||  00  |    
            INIT_40 => X"00000000000000010000000000000000000000005"                                     
                        & GEN_DSP_DESIGN_TYPE & X"10511000000" &  SOURCE_ID &  X"110090FF",             -- 0x800   --MODIFICATO METTENDO SOURCE ID SAV(6C) 0x804
            INIT_41 => X"000000000000000000000000000000000000000006082009"                               
                                                        & GEN_DSP_FIRMW_VERS & X"07082009",             -- 0x820 
            INIT_42 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x840             
            INIT_43 => X"0000000000000000000000000000000000000000000000000000022200000111",             -- 0x860
            INIT_44 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x880
            INIT_45 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x8A0
            INIT_46 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x8C0
            INIT_47 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x8E0
            --           |  1C  ||  18  ||  18  ||  10  ||  0C  ||  08  ||  04  ||  00  |
            INIT_48 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x900
            INIT_49 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x920
            INIT_4A => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x940
            INIT_4B => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x960
            INIT_4C => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x980
            INIT_4D => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x9A0
            INIT_4E => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x9C0
            INIT_4F => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0x9E0
            --           |  1C  ||  18  ||  18  ||  10  ||  0C  ||  08  ||  04  ||  00  |
            INIT_50 => BS_SI_G(255 downto 0),                                                           -- 0xA00
            INIT_51 => BS_SI_G(511 downto 256),                                                         -- 0xA20

            INIT_52 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xA40
            INIT_53 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xA60
            INIT_54 => X"0000000000000000000000000000000000000000"
                                                     & END_ADDR & X"00000000" & START_ADDR,             -- 0xA80
            INIT_55 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xAA0
            INIT_56 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xAC0
            INIT_57 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xAE0
            --           |  1C  ||  18  ||  18  ||  10  ||  0C  ||  08  ||  04  ||  00  |
            INIT_58 => T_THRESHOLD_bv
            & X"00" & T_MAX_DIST_bv             -- G_CONF_7
            & X"0000" & ZSUPP_bv                -- G_CONF_6
            & MAX_DIST_bv & THRESHOLD_bv 
            & DELAY_bv & FRAC_bv                -- G_CONF_5 
            & X"0000" & b"00" 
            & RDM_bv & b"00" & X"00"            -- G_CONF_4 
            & X"00000000"                       -- G_CONF_3 
            -- & PRESCALER_bv 
            -- & X"01"
            -- & BASELINE_bv                       
            & TIMESTAMP_BASE                    -- G_CONF_2 aggiornata per il MEP (è la base per il timestamp, il valore di reset)
            & X"00000000"                       -- G_CONF_1 
            & FRAMEWIDTH_bv & LATENCY_bv,       -- G_CONF_0                                             -- 0xB00
            INIT_59 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xB20
            INIT_5A => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xB40
            INIT_5B => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xB60
            INIT_5C => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xB80
            INIT_5D => BS_M1TDC_G,                                                                      -- 0xBA0 
            INIT_5E => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xBC0
            INIT_5F => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xBE0
            --           |  1C  ||  18  ||  18  ||  10  ||  0C  ||  08  ||  04  ||  00  |
            INIT_60 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xC00
            INIT_61 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xC20
            INIT_62 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xC40
            INIT_63 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xC60
            INIT_64 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xC80
            INIT_65 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xCA0
            INIT_66 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xCC0
            INIT_67 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xCE0
            --           |  1C  ||  18  ||  18  ||  10  ||  0C  ||  08  ||  04  ||  00  |
            INIT_68 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xD00
            INIT_69 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xD20
            INIT_6A => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xD40
            INIT_6B => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xD60
            INIT_6C => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xD80
            INIT_6D => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xDA0
            INIT_6E => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xDC0
            INIT_6F => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xDE0
            --           |  1C  ||  18  ||  18  ||  10  ||  0C  ||  08  ||  04  ||  00  |
            INIT_70 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xE00
            INIT_71 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xE20
            INIT_72 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xE40
            INIT_73 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xE60
            INIT_74 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xE80
            INIT_75 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xEA0
            INIT_76 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xEC0
            INIT_77 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xEE0
            --           |  1C  ||  18  ||  18  ||  10  ||  0C  ||  08  ||  04  ||  00  |
            INIT_78 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xF00
            INIT_79 => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xF20
            INIT_7A => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xF40
            INIT_7B => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xF60
            INIT_7C => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xF80
            INIT_7D => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xFA0
            INIT_7E => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xFC0
            INIT_7F => X"0000000000000000000000000000000000000000000000000000000000000000",             -- 0xFE0
            --           |  1C  ||  18  ||  18  ||  10  ||  0C  ||  08  ||  04  ||  00  |
            -- The next set of INITP_xx are for the parity bits
            INITP_00 => X"0000000000000000000000000000000000000000000000000000000000000000",
            INITP_01 => X"0000000000000000000000000000000000000000000000000000000000000000",
            INITP_02 => X"0000000000000000000000000000000000000000000000000000000000000000",
            INITP_03 => X"0000000000000000000000000000000000000000000000000000000000000000",
            INITP_04 => X"0000000000000000000000000000000000000000000000000000000000000000",
            INITP_05 => X"0000000000000000000000000000000000000000000000000000000000000000",
            INITP_06 => X"0000000000000000000000000000000000000000000000000000000000000000",
            INITP_07 => X"0000000000000000000000000000000000000000000000000000000000000000",
            INITP_08 => X"0000000000000000000000000000000000000000000000000000000000000000",
            INITP_09 => X"0000000000000000000000000000000000000000000000000000000000000000",
            INITP_0A => X"0000000000000000000000000000000000000000000000000000000000000000",
            INITP_0B => X"0000000000000000000000000000000000000000000000000000000000000000",
            INITP_0C => X"0000000000000000000000000000000000000000000000000000000000000000",
            INITP_0D => X"0000000000000000000000000000000000000000000000000000000000000000",
            INITP_0E => X"0000000000000000000000000000000000000000000000000000000000000000",
            INITP_0F => X"0000000000000000000000000000000000000000000000000000000000000000")
        port map (
                                                -- PORT A: FPGA side
            ADDRA  => config_mem_BRAM_Addr,     -- Input port-A address
            CLKA   => config_mem_BRAM_Clk,      -- Input port-A clock
            DIA    => config_mem_BRAM_Din,      -- Input port-A data
            DOA    => config_mem_BRAM_Dout,     -- Output port-A data
            ENA    => '1',                      -- Input port-A enable
            REGCEA => '1',                      -- Input port-A output register enable
            SSRA   => '0',                      -- 1-bit A port set/reset input
            WEA    => config_mem_BRAM_WEN,      -- Input port-A write enable

                                                -- PORT B: CPLD side
            ADDRB  => PhysMemoryAddr,           -- Input port-B address
            CLKB   => CLK_120MHZ,               -- Input port-B clock
            DIB    => MemoryIn,                 -- Input port-B data
            DOB    => MemoryOut,                -- Output port-B data
            ENB    => '1',                      -- Input port-B enable
            REGCEB => '1',                      -- Input port-B output register enable
            SSRB   => RST_Startup_1,            -- 1-bit B port set/reset input
            WEB    => MemoryWE,                 -- Input port-B write enable

            CASCADEINLATA  => '0',              -- 1-bit cascade A latch input
            CASCADEINLATB  => '0',              -- 1-bit cascade B latch input
            CASCADEINREGA  => '0',              -- 1-bit cascade A register input
            CASCADEINREGB  => '0',              -- 1-bit cascade B register input
            CASCADEOUTLATA => open,             -- 1-bit cascade A latch output
            CASCADEOUTLATB => open,             -- 1-bit cascade B latch output
            CASCADEOUTREGA => open,             -- 1-bit cascade A register output
            CASCADEOUTREGB => open,             -- 1-bit cascade B register output
            DOPA           => open,             -- 4-bit A port parity data output
            DOPB           => open,             -- 4-bit B port parity data output
            DIPA           => x"0",             -- 4-bit A port parity data input
            DIPB           => x"0"              -- 4-bit B port parity data input
            );


end Behavioral;

