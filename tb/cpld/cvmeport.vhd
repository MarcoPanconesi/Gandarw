

library ieee;
use ieee.std_logic_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.ALL;
library UNISIM;
use UNISIM.Vcomponents.ALL;

entity VmeInterface is
   port ( -- VME side
          CD        : inout std_logic_vector (31 downto 0);
			 CA        : inout std_logic_vector (31 downto 0);
          CAM       : in    std_logic_vector (5 downto 0); 
          CAS       : in    std_logic; 
          CDS0      : in    std_logic; 
          CDS1      : in    std_logic; 
          CIACK     : in    std_logic; 
          CWRITE    : in    std_logic; 
			 
			 CDIR0     : out   std_logic := '0';
			 CDIR1     : out   std_logic := '0';
			 CDTACK    : out   std_logic := '1';
			 CBERR     : out   std_logic := '1';

			 -- SN stuff
          DIP       : in    std_logic_vector (7 downto 0); 
          GA        : in    std_logic_vector (4 downto 0); 
          SN        : in    std_logic_vector (9 downto 0); 

			 UCDGPO2	  : in  STD_LOGIC;

			 -- Gandalf side
          CLK       : in    std_logic;
			 writeFlag : out   std_logic;
			 BUSWR     : in    std_logic_vector (31 downto 0); 
			 Status    : in    std_logic_vector (3 downto 0); 
          BUSRD     : out   std_logic_vector (31 downto 0) := (others => '0');
          ALOW      : out   std_logic_vector (15 downto 0) := (others => '0');
          CTReg     : out   std_logic_vector (1 downto 0)  := (others => '0');
          CTFinish  : in    std_logic;
			 protError : in    std_logic;
			 SpyEmpty  : in  STD_LOGIC;
			 
			 SpyRegReady : in STD_LOGIC;
			 SpyRegClear : out STD_LOGIC;
			 SpyReq : out STD_LOGIC;
		
			 USBConnected : in  STD_LOGIC;
          BLTRANS   : out   std_logic := '0'
			 );
end VmeInterface;

architecture BEHAVIORAL of VmeInterface is

	alias  transtype : std_logic_vector(2 downto 0) is CA(14 downto 12);

	signal AS  : std_logic := '1';
	signal DS0 : std_logic := '1';
	signal DS1 : std_logic := '1';

	signal AMvalid     : std_logic;
	signal BoardSel    : std_logic;
	signal BoardSelID  : std_logic;
	signal BroadcastSel: std_logic;
	signal BoardSelect : std_logic;
	signal TO_VME      : std_logic := '0';

	signal sCTReg      : std_logic_vector (1 downto 0) := (others => '0');
	signal sCDTACK     : std_logic :='1';
	signal sCBERR      : std_logic :='1';
	signal sDataSource : std_logic :='0';  --  1 = read from protocol block  /  0 = read id 
   
	signal sSpyReq     : std_logic :='0';  -- vme read request to 0x3000
	
begin

	strobe_synchronizer: process(CLK)
	begin
		if (CLK'event and CLK = '1') then
			AS  <= CAS;
			DS0 <= CDS0;
			DS1 <= CDS1;
		end if;
	end process strobe_synchronizer;


	AMvalid <= '1' when CAM(5 downto 3)&CAM(0) = "0011" else '0';
	BoardSel <= '1' when CA(31 downto 16) = X"E0" & (not DIP) else '0';
	BroadcastSel <= '1' when CA(31 downto 24)&CA(15) = X"E0"&'1' else '0';
	BoardSelect <= AMvalid and (BoardSel or BroadcastSel) and CIACK and not CA(0) and not CA(1) and not USBConnected;
	BLTRANS <= CAM(1) and not AS;

	
	LatchAddr : process(AS)
	begin
		if (AS'event and AS = '0') then
			if(BoardSelect = '1') then
				ALOW <= CA(15 downto 0);
				writeFlag <= CWRITE;   --  writeFlag=0 is "write to gandalf"
				BoardSelID <= BoardSel;
			end if;
		end if;
	end process LatchAddr;
	
	CDIR0 <= TO_VME;
	
	CA <= "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
	CD <= BUSWR when (TO_VME='1')
			else "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
		
	LatchData : process(DS0)
	begin
		if (DS0'event and DS0 = '0') then
			if(CWRITE = '0' and BoardSelect = '1') then
				BUSRD <= CD;
			end if;
		end if;
	end process LatchData;	
	
	


	StartCommand : process(CTFinish,DS0, transtype)
		variable cregister : std_logic_vector (2 downto 0);
	begin
		case (transtype) is
			when "000" =>
				cregister := "001"; -- config block      CTReg(0)='1'
			when "011" =>
				cregister := "101"; -- spy read
			when others =>
				cregister := "010"; -- protocol block    CTReg(1)='1'
		end case;
		
		if (CTFinish='1') then
			sCTReg <= "00";
			sSpyReq <= '0';
		elsif (DS0'event and DS0 = '0') then
			if(BoardSelect = '1') then
				sCTReg <= cregister(1 downto 0);
				sSpyReq <= cregister(2);
			end if;
        else                        -- Aggiunto else per evitare 
			sCTReg <= "00";         -- le ripartenze in spyread2
			sSpyReq <= '0';         -- ora dovrebbe funzionare bene ... (Alex)       
		end if;
	end process StartCommand;
	
	
	CTReg <= sCTReg;
	CDTACK <= sCDTACK;
	CBERR <= sCBERR;
	
	SpyReq <= sSpyReq;

	
	VmeMachine_block : block
		type states is (idle, write1, write2, read1, read2, spyread2);
		signal state : states := idle;
	begin
		VmeMachine : process(CLK, state,sCDTACK,sDataSource,DS0,sCTReg,CWRITE,sCBERR,protError)
			variable nxt_state : states;
			variable iCDTACK : std_logic;
			variable iCBERR : std_logic;
			variable iDataSource : std_logic;
			variable iTO_VME : std_logic;
			variable iSpyRegClear : std_logic;
			
		begin
			nxt_state := state;
			iCDTACK := sCDTACK;
			iCBERR := sCBERR;
			iDataSource := sDataSource;
			iTO_VME := '0';
			iSpyRegClear := '0';
			
			case (state) is
				when write1 =>
					if (sCTReg="00") then
						nxt_state := write2;
						if(BoardSelID = '1') then  -- only acknowledge when this board is selected by ID (not broadcast)
							iCDTACK := protError;  -- if no protocol error: dtack goes low
							iCBERR := not(protError); -- if protocol error: berr goes low
						end if;
					end if;
					
				when write2 =>
					if (DS0='1') then
						nxt_state := idle;
						iCDTACK := '1';
						iCBERR := '1';
					end if;

				when read1 =>
					iTO_VME := '1';
					if (sCTReg="00") then
						iCDTACK := protError;  -- if no protocol error: dtack goes low
						iCBERR := not(protError); -- if protocol error: berr goes low
						nxt_state := read2;
					end if;

				when read2 =>
					iTO_VME := '1';
					if (DS0='1') then
						iTO_VME := '0';
						iCDTACK := '1';
						iCBERR := '1';
						nxt_state := idle;
					end if;

				when spyread2 =>
					iTO_VME := '1';
					if (DS0='1') then
						iTO_VME := '0';
						iCDTACK := '1';
						iCBERR := '1';
						iSpyRegClear := '1';
						nxt_state := idle;
					end if;
					
				when idle =>
					if(sSpyReq='1' and CWRITE='1') then
						iTO_VME := '1';
						iCDTACK := not(SpyRegReady);    -- if SpyRegReady: dtack goes low
						iCBERR := SpyRegReady;          -- if spy empty: berr goes low
						nxt_state := spyread2;          -- spy read
					elsif (sCTReg/="00") then
						if (CWRITE='1') then
							nxt_state := read1;         -- vme read
							iDataSource := sCTReg(1);   --  1 = read from protocol block  /  0 = read id 
						else
							nxt_state := write1;        -- vme write
							--iCDTACK := '0';
						end if;
					end if;
					
				when others =>
					nxt_state := idle;
			end case;	
			
			if (CLK'event and CLK = '1') then
				if (UCDGPO2 = '0') then
					state <= nxt_state;
				end if;
				sCDTACK <= iCDTACK;
				sCBERR <= iCBERR;
				sDataSource <= iDataSource;
				TO_VME <= iTO_VME;
				SpyRegClear <= iSpyRegClear;
			end if;
		end process VmeMachine;
	end block VmeMachine_block;
	



end BEHAVIORAL;

