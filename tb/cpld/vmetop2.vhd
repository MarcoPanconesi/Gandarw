---------------------------
--  GANDALF CPLD DESIGN  --
---------------------------

-- 
--
--


-- TO DO:
	-- ENCPLD
	-- ucd hochfahren (timergesteuert nach GA)
	-- ucd ausschalten
	-- Display neu machen
	-- USB LED auf LED4, wenn in-the-box (GA???)
	
	



LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
LIBRARY UNISIM;
USE UNISIM.VCOMPONENTS.ALL;


------------------------
--  TOP LEVEL ENTITY  --
------------------------

entity vmetop is
    port ( 
        BSYSRES         : in    STD_LOGIC; 
        CA              : inout STD_LOGIC_vector (31 downto 0); 
        CAM             : in    STD_LOGIC_vector (5 downto 0); 
        CAS             : in    STD_LOGIC; 
        CDS0            : in    STD_LOGIC; 
        CDS1            : in    STD_LOGIC; 
        CIACK           : in    STD_LOGIC; 
        CLK_CPLD        : in    STD_LOGIC; -- 40 mhz
		CLK_80MHZ       : in    STD_LOGIC;
        --CLWORD        : in    STD_LOGIC; -- replaced by CA(0)
        CWRITE          : in    STD_LOGIC; 
        DIP             : in    STD_LOGIC_vector (7 downto 0); 
        DONE            : in    STD_LOGIC; 
        GA              : in    STD_LOGIC_vector (4 downto 0); 
        INIT_B          : in    STD_LOGIC; 
        SN              : in    STD_LOGIC_vector (9 downto 0); 
        UCDGPO1         : in    STD_LOGIC; 
        UCDGPO2         : in    STD_LOGIC; 
        CCLK            : out   STD_LOGIC; 
        CDIR0           : out   STD_LOGIC; 
        CDIR1           : out   STD_LOGIC; 
        CDTACK          : out   STD_LOGIC; 
		CBERR           : out   STD_LOGIC; 
        CSRESET         : out   STD_LOGIC; 
        DCS             : out   STD_LOGIC; 
        DISPCLK         : out   STD_LOGIC; 
        DISPDATA        : out   STD_LOGIC; 
        DISPLOAD        : out   STD_LOGIC; 
        --LED4          : out   STD_LOGIC; 
        --LED5          : out   STD_LOGIC; 
        LED6            : out   STD_LOGIC; 
        LED7            : out   STD_LOGIC; 
        MCS             : out   STD_LOGIC; 
        M0              : out   STD_LOGIC; 
        M1              : out   STD_LOGIC; 
        M2              : out   STD_LOGIC;
		OBUF_EN         : out   STD_LOGIC;
        PROGRAM_B       : out   STD_LOGIC; 
        RDWR_B          : out   STD_LOGIC; 
        SYSACERES       : out   STD_LOGIC; 
        USBRESET        : out	STD_LOGIC; 
		USBIFCLK        : out	STD_LOGIC; 
        USBSLOE         : out	STD_LOGIC; 
        USBPKTEND       : out	STD_LOGIC; 
        USBFLAGD        : out	STD_LOGIC; 
        USBSLWR         : out	STD_LOGIC; 
        USBSLRD         : out	STD_LOGIC; 
        USBFIFOADR      : out	STD_LOGIC_VECTOR (2 DOWNTO 0); 
        USB_FD          : inout	STD_LOGIC_VECTOR (15 DOWNTO 0); 
        USBINT          : in	STD_LOGIC; 
        USBREADY        : in	STD_LOGIC; 
        USBFLAGC        : in	STD_LOGIC; 
        USBFLAGB        : in	STD_LOGIC; 
        USBFLAGA        : in	STD_LOGIC; 
        CD              : inout STD_LOGIC_vector (31 downto 0);   --TEST
        QA              : inout STD_LOGIC_vector (0 to 7); 
        VA              : inout STD_LOGIC_vector (0 to 7); 
        VD              : inout STD_LOGIC_vector (31 downto 0)
    );
end vmetop;


architecture BEHAVIORAL of vmetop is

	------------------------------
	--  COMPONENT DECLARATIONS  --
	------------------------------


    component VmeInterface
        port ( 
            CD          : inout STD_LOGIC_VECTOR (31 downto 0);
			CA          : inout STD_LOGIC_VECTOR (31 downto 0);
            CAM         : in    STD_LOGIC_VECTOR (5 downto 0); 
            CAS         : in    STD_LOGiC; 
            CDS0        : in    STD_LOGiC; 
            CDS1        : in    STD_LOGiC; 
            CIACK       : in    STD_LOGiC; 
            CWRITE      : in    STD_LOGiC; 
			CDIR0       : out   STD_LOGiC;
			CDIR1       : out   STD_LOGiC;
			CDTACK      : out   STD_LOGiC;
			CBERR       : out   STD_LOGiC;			 
            DIP         : in    STD_LOGIC_VECTOR (7 downto 0); 
            GA          : in    STD_LOGIC_VECTOR (4 downto 0); 
            SN          : in    STD_LOGIC_VECTOR (9 downto 0); 
            CLK         : in    STD_LOGiC; 
			UCDGPO2     : in    STD_LOGiC;
            Status      : in    STD_LOGIC_VECTOR (3 downto 0); 
			BUSWR       : in    STD_LOGIC_VECTOR (31 downto 0); 
            BUSRD       : out   STD_LOGIC_VECTOR (31 downto 0);
            ALOW        : out   STD_LOGIC_VECTOR (15 downto 0);
			writeFlag   : out   STD_LOGiC;
            CTReg       : out   STD_LOGIC_VECTOR (1 downto 0);
            CTFinish    : in    STD_LOGiC; 
			protError   : in    STD_LOGiC;
			SpyEmpty    : in    STD_LOGIC;
			SpyRegReady : in    STD_LOGIC;
			SpyRegClear : out   STD_LOGIC;
			SpyReq      : out   STD_LOGIC;
			USBConnected: in    STD_LOGIC;
            BLTRANS     : out   STD_LOGIC := '0'
        );
	end component;
   
    component SelectMapConfig
        port ( 
            --SMBUS         : out   std_logic_vector (0 to 7); 
			VA0             : in  STD_LOGIC;
			VA1             : in  STD_LOGIC;
			VA2             : out STD_LOGIC;
			VA3             : in  STD_LOGIC;
			VA4             : in  STD_LOGIC;
			VA5             : out STD_LOGIC;
			VA6             : out STD_LOGIC;
			VA7             : in  STD_LOGIC;
			VA              : inout  STD_LOGIC_VECTOR (0 to 7);
			QA              : inout  STD_LOGIC_VECTOR (0 to 7);	
			bitclk          : out STD_LOGIC; 
			DCS             : out STD_LOGIC;
			MCS             : out STD_LOGIC;
            INIT            : in  STD_LOGIC;
            DONE            : in  STD_LOGIC;
            PROG            : out STD_LOGIC;
            CLK             : in  STD_LOGIC; 
			CLK_1M25        : in  STD_LOGIC; 
			UCDGPO2         : in  STD_LOGIC;
            CTReg           : in  STD_LOGIC; 
            WCOMPLETE       : out STD_LOGIC; 
			UsbPktEndCmd    : out STD_LOGIC;
			DispUpdCmd      : out STD_LOGIC;
			ALOW            : in  STD_LOGIC_VECTOR (15 downto 0);
            MAPWORD         : in  STD_LOGIC_VECTOR (31 downto 0)
        );
    end component;
   
    component DISPLAY
        port ( 
            CLK_40MHz       : in  STD_LOGIC; 
			DisplayData     : in  STD_LOGIC_VECTOR (31 downto 0);
            UPDATE          : in  STD_LOGIC; 
            --DIP           : in  STD_LOGIC_VECTOR (7 downto 0); 
            --SN            : in  STD_LOGIC_VECTOR (9 downto 0); 
            DISPDATA        : out STD_LOGIC; 
            DISPLOAD        : out STD_LOGIC; 
            DISPCLK         : out STD_LOGIC; 
            STARTUP         : in  STD_LOGIC
        );
    end component;
   
    component prot
        port ( 
            FASTSTART       : in    STD_LOGIC; 
            RESET           : in    STD_LOGIC; 
            CLK             : in    STD_LOGIC; 
			UCDGPO2         : in    STD_LOGIC;
            FREADY          : in    STD_LOGIC; 
            VD              : inout STD_LOGIC_VECTOR(31 downto 0);
            FFF             : in    STD_LOGIC; 
            FFE             : in    STD_LOGIC; 
            FVDATA          : in    STD_LOGIC_VECTOR (31 downto 0); 
            FSTART          : in    STD_LOGIC_VECTOR (13 downto 0);
			writeFlag       : in    STD_LOGIC;
            FRDY            : out   STD_LOGIC; 
			Error           : out   STD_LOGIC;
            FRESET          : out   STD_LOGIC; 
            FWRITE          : out   STD_LOGIC; 
            FSTROBE         : out   STD_LOGIC; 
            FCONTROL        : out   STD_LOGIC; 
            FUBLAZE         : out   STD_LOGIC; 
			SpyRegReady     : out   STD_LOGIC;
			SpyRegClear     : in    STD_LOGIC;
			SpyData         : out   STD_LOGIC_VECTOR (31 downto 0);
			Status          : in    STD_LOGIC_VECTOR (3 downto 0);
            TVDATA          : out   STD_LOGIC_VECTOR (31 downto 0)
        );
    end component;


	component USB
	    port(
		    CLK             : in    STD_LOGIC;
		    READY           : in    STD_LOGIC;
		    INT             : in    STD_LOGIC;
            FLAGA           : in    STD_LOGIC;
            FLAGB           : in    STD_LOGIC;
            FLAGC           : in    STD_LOGIC;
		    UCDGPO1         : in    STD_LOGIC;          
		    UCDGPO2         : in    STD_LOGIC;          
		    IFCLK           : out   STD_LOGIC;
		    RESET           : out   STD_LOGIC;
		    SLOE            : out   STD_LOGIC;
		    FIFOADR         : out   STD_LOGIC_VECTOR(2 downto 0);
		    PKTEND          : out   STD_LOGIC;
		    UsbPktEndCmd    : in    STD_LOGIC;
		    CS              : out   STD_LOGIC;
		    FDATA           : inout STD_LOGIC_VECTOR(15 downto 0);
		    SLRD            : out   STD_LOGIC;
		    SLWR            : out   STD_LOGIC;
		    ToHost          : in    STD_LOGIC_VECTOR (31 downto 0);
		    Status          : in    STD_LOGIC_VECTOR (3 downto 0);
            FromHost        : out   STD_LOGIC_VECTOR (31 downto 0);
            ALOW            : out   STD_LOGIC_VECTOR (15 downto 0);
		    writeFlag       : out   STD_LOGIC;
            CTReg           : out   STD_LOGIC_VECTOR (1 downto 0);
            CTFinish        : in    STD_LOGIC;
		    USBConnected    : out   STD_LOGIC;
		    --SpyEmpty	    : in    STD_LOGIC;
		    SpyRegReady     : in    STD_LOGIC;
		    SpyRegClear     : out   STD_LOGIC;
		    SpyData         : in    STD_LOGIC_VECTOR (31 downto 0);
		
		    LED4            : out   STD_LOGIC;
		    LED5            : out   STD_LOGIC
		);
	end component;


	-------------------------
	--  TOP LEVEL SIGNALS  --
	-------------------------

	signal BoardSelect : std_logic;
	signal RESREG : std_logic;
	signal BLTRANS : std_logic;
    signal CONTROL : std_logic_vector (3 downto 0);
    signal ALOW : std_logic_vector (15 downto 0);
    signal AlowUSB : std_logic_vector (15 downto 0);
    signal AlowVME : std_logic_vector (15 downto 0);
	signal writeFlag : std_logic;
	signal USBwriteFlag : std_logic;
	signal VMEwriteFlag : std_logic;
    signal FFDATA : std_logic_vector (31 downto 0);
	signal FRDY : std_logic;
    signal FromHost : std_logic_vector (31 downto 0);
    signal FromVME : std_logic_vector (31 downto 0);
    signal FromUSB : std_logic_vector (31 downto 0);
	signal WCOMPLETE : std_logic;
	signal FASTSTART : std_logic;
	signal PROGCLK : std_logic;
	signal PROGRS : std_logic;
	signal UCD_READY : std_logic;
    signal SDATA : std_logic_vector (31 downto 0);
    signal TFDATA : std_logic_vector (31 downto 0);
    signal TVME : std_logic_vector (31 downto 0);
    signal TVMEprot : std_logic_vector (31 downto 0);
    signal nDIP : std_logic_vector (7 downto 0);
    --signal SMBUS : std_logic_vector (0 to 7);
	
	signal USBConnected : std_logic;
	signal idread : std_logic;
	
	signal CLK_5MHZ : std_logic;
    signal clkdiv : std_logic_vector (15 downto 0) :=x"0000";	
	signal sLED4 : std_logic;
	signal sLED5 : std_logic;
    signal cntLED4 : integer range 0 to 3 :=0;	
    signal cntLED5 : integer range 0 to 3 :=0;	

    -- Protocol Flags
	signal FCONTROL                : std_logic;
    signal FFE                     : std_logic;
    signal FFF                     : std_logic;
    signal FREADY                  : std_logic;
    signal FRESET                  : std_logic;
    signal FSTROBE                 : std_logic;
    signal FUBLAZE                 : std_logic;
    signal FWRITE                  : std_logic;
	
    -- FSM Control Flags
	signal CTReg      : std_logic_vector (1 downto 0);
	signal CTRegUSB   : std_logic_vector (1 downto 0);
	signal CTRegVME   : std_logic_vector (1 downto 0);
    signal CTFinish   : std_logic;
    signal CTFinish0  : std_logic;
    signal CTFinish1  : std_logic;
	signal Status     : std_logic_vector (3 downto 0);
	signal protError  : std_logic;
	signal UsbPktEndCmd  : std_logic;
	signal DispUpdCmd  : std_logic;
	signal tDispChanged : std_logic := '0';
	signal DispChanged : std_logic;
	
	signal DisplayData : std_logic_vector (31 downto 0);
	
	--spy
	signal SpyRegReady : STD_LOGIC;
	signal SpyRegClear : STD_LOGIC;
	signal SpyRegClearUSB : STD_LOGIC;
	signal SpyRegClearVME : STD_LOGIC;
	signal SpyReq : STD_LOGIC;
	signal SpyData     : STD_LOGIC_VECTOR (31 downto 0);

---
   
   

begin

	-- POWER UP/DOWN
	OBUF_EN <= UCDGPO1;
	UCD_READY <= not UCDGPO1;


	-- DONE LED (inverted)
   LED6 <= DONE;
   LED7 <= not DONE;


	SYSACERES <= '0';
	M0 <= '0';
	M1 <= '1';
	M2 <= '1';
	RDWR_B <= '0';
	CSRESET <= '1';
	
	
	Status <= "11" & INIT_B & DONE;
	CTFinish <= CTFinish0 or CTFinish1;

	-- select between usb and vme
	writeFlag   <= USBwriteFlag when USBConnected='1' else VMEwriteFlag;
	ALOW        <= AlowUSB when USBConnected='1' else AlowVME;
	CTReg       <= CTRegUSB when USBConnected='1' else CTRegVME;
	FromHost    <= FromUSB when USBConnected='1' else FromVME;
	SpyRegClear <= SpyRegClearUSB when USBConnected='1' else SpyRegClearVME;


	idreadproc: PROCESS (CLK_CPLD)
		BEGIN
			if (CTReg(1)='1') then
				idread <= '0';
			elsif (CLK_CPLD'event AND CLK_CPLD ='1') then
				if(CTReg(0)='1') then 
                    idread <= '1'; 
                end if;
			end if;
	END PROCESS;

	TVME <=  SpyData when (SpyReq='1')
				else (Status&not(DIP)&"000"&not(GA)&"00"&not(SN)) when (idread='1')
				else TVMEprot;
	

	dispupd: PROCESS (CLK_CPLD)
		BEGIN
			if (UCD_READY /= '1') then
				DisplayData <= X"0012" & X"0" & not(DIP(7 downto 4)) & X"0" & not(DIP(3 downto 0));
			elsif (CLK_CPLD'event AND CLK_CPLD ='1') then
				if(DispUpdCmd='1') then 
					DisplayData <= FromHost;
					tDispChanged <= not tDispChanged;
				end if;
			end if;
	END PROCESS;

	DispChanged <= tDispChanged xor DONE;
	
	
	
---

	
    VmeInterface_inst : VmeInterface
        port map (
            CD              => CD,
			CA              => CA,
			CAM             => CAM,
			CAS             => CAS,
			CDS0            => CDS0,
			CDS1            => CDS1,
			CIACK           => CIACK,
			CWRITE          => CWRITE,
			CDIR0           => CDIR0,
			CDIR1           => CDIR1,
			CDTACK          => CDTACK,
			CBERR           => CBERR,
			DIP             => DIP,
			GA              => GA,
			SN              => SN,
			CLK             => CLK_CPLD,
			UCDGPO2         => UCDGPO2,
			Status          => Status,
			BUSWR           => TVME,
			BUSRD           => FromVME,
			ALOW            => AlowVME,
			writeFlag       => VMEwriteFlag,
			CTReg           => CTRegVME,
			CTFinish        => CTFinish,
			protError       => protError,
			SpyEmpty        => FFE,
			SpyRegReady     => SpyRegReady,
			SpyRegClear     => SpyRegClearVME,
			SpyReq          => SpyReq,
			USBConnected    => USBConnected,
			BLTRANS         => BLTRANS
		);
					 
	USB_inst : USB
		port map (
			CLK             => CLK_CPLD, --CLK_80MHZ,
			IFCLK           => USBIFCLK,
			RESET           => USBRESET,
			READY           => USBREADY,
			INT             => USBINT,
			SLOE            => USBSLOE,
			FIFOADR         => USBFIFOADR,
			PKTEND          => USBPKTEND,
			UsbPktEndCmd    => UsbPktEndCmd,
			CS              => USBFLAGD,
			FDATA           => USB_FD,
			SLRD            => USBSLRD,
			SLWR            => USBSLWR,
			FLAGA           => USBFLAGA,
			FLAGB           => USBFLAGB,
			FLAGC           => USBFLAGC,
			UCDGPO1         => UCDGPO1,
			UCDGPO2         => UCDGPO2,
			--SpyEmpty      => FFE,
			SpyRegReady     => SpyRegReady,
			SpyRegClear     => SpyRegClearUSB,
			SpyData         => SpyData,
			ToHost          => TVME,
			Status          => Status,
			FromHost        => FromUSB,
			ALOW            => AlowUSB,
			writeFlag       => USBwriteFlag,
			CTReg           => CTRegUSB,
			CTFinish        => CTFinish,
			USBConnected    => USBConnected,

			LED4            => sLED4,
			LED5            => sLED5
	);

    display_inst : DISPLAY
        port map (
            CLK_40MHz       => clkdiv(0),
            --DIP           => DIP,
            --SN            => SN,
			DisplayData     => DisplayData,
            STARTUP         => UCD_READY,
            UPDATE          => DispChanged,
            DISPCLK         => DISPCLK,
            DISPDATA        => DISPDATA,
            DISPLOAD        => DISPLOAD
        );

--	DISPCLK  <= '0';
--	DISPDATA <= '0';
--	DISPLOAD <= '0';

    prot_inst : prot
        port map (
            CLK             => CLK_CPLD,
			UCDGPO2         => UCDGPO2,
			FSTART          => ALOW(15 downto 2),
			writeFlag       => writeFlag,
            RESET           => BSYSRES,
            FASTSTART       => CTReg(1),
            FRDY            => CTFinish1,
			Error           => protError,
			VD              => VD,
            FWRITE          => FWRITE,
            FSTROBE         => FSTROBE,
            FREADY          => FREADY,
            FCONTROL        => FCONTROL,
            FUBLAZE         => FUBLAZE,
            FFF             => FFF,
            FFE             => FFE,
            FRESET          => FRESET,

			SpyRegReady     => SpyRegReady,
			SpyRegClear     => SpyRegClear,
			SpyData         => SpyData,
			Status          => Status,
					 
            FVDATA          => FromHost,
            TVDATA          => TVMEprot
        );



   SelectMapConfig_inst : SelectMapConfig
        port map (
            CLK             => CLK_CPLD,
			CLK_1M25        => clkdiv(1),
            CTReg           => CTReg(0),
			ALOW            => ALOW,
            MAPWORD         => FromHost,
            bitclk          => CCLK,
            VA0             => FWRITE,
            VA1             => FSTROBE,
            VA2             => FREADY,
            VA3             => FCONTROL,
            VA4             => FUBLAZE,
            VA5             => FFF,
            VA6             => FFE,
            VA7             => FRESET,
            VA              => VA,
			QA              => QA,
            --SMBUS         => SMBUS,
            DCS             => DCS,
            MCS             => MCS,
            PROG            => PROGRAM_B,
            INIT            => INIT_B,
            DONE            => DONE,
			UsbPktEndCmd    => UsbPktEndCmd,
			DispUpdCmd      => DispUpdCmd,
			UCDGPO2         => UCDGPO2,
            WCOMPLETE       => CTFinish0
        );


   


	
	
	CLK_DIV16_inst : CLK_DIV16
		port map (
			CLKDV => CLK_5MHZ, -- Divided clock output
			CLKIN => CLK_80MHZ -- Clock input
	);
	
	clkdivproc: PROCESS (CLK_5MHZ)
		BEGIN
			if (CLK_5MHZ'event AND CLK_5MHZ ='1') then
				clkdiv <= clkdiv + 1;
			end if;
	END PROCESS;
	

--	ledproc4: PROCESS (clkdiv(15), sLED4)
--		BEGIN
--			if (sLED4 = '1') then
--				cntLED4 <= 3;
--			elsif (clkdiv(15)'event AND clkdiv(15) ='1') then
--				if ( cntLED4 = 0 ) then
--					LED4 <= '0';
--				else 
--					cntLED4 <= cntLED4 - 1;
--					LED4 <= '1';
--				end if;
--			end if;
--	END PROCESS;	
--LED4 <= FFE;


--	ledproc5: PROCESS (clkdiv(15), sLED5)
--		BEGIN
--			if (sLED5 = '1') then
--				cntLED5 <= 3;
--			elsif (clkdiv(15)'event AND clkdiv(15) ='1') then
--				if ( cntLED5 = 0 ) then
--					LED5 <= '0';
--				else 
--					cntLED5 <= cntLED5 - 1;
--					LED5 <= '1';
--				end if;
--			end if;
--	END PROCESS;	
	
	--LED5 <= USBFLAGB;

   
end BEHAVIORAL;

