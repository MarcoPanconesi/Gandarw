
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY UNISIM;
USE UNISIM.VCOMPONENTS.ALL;


entity SelectMapConfig is
PORT (
	CLK             : in  STD_LOGIC;
	CLK_1M25        : in  STD_LOGIC; 
	CTReg           : in  STD_LOGIC;
	MAPWORD         : in  STD_LOGIC_VECTOR (31 downto 0);
	ALOW            : in  STD_LOGIC_VECTOR (15 downto 0);
	--SMBUS         : out STD_LOGIC_VECTOR(0 to 7);
	bitclk          : out STD_LOGIC;
	DCS             : out STD_LOGIC :='0';
	MCS             : out STD_LOGIC :='1';
	INIT            : in  STD_LOGIC;
	DONE            : in  STD_LOGIC;
	PROG            : out STD_LOGIC :='1';
	UsbPktEndCmd    : out STD_LOGIC :='0';
	DispUpdCmd      : out STD_LOGIC :='0';

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
	
	UCDGPO2	        : in  STD_LOGIC;
	WCOMPLETE       : out STD_LOGIC := '0'
);
end SelectMapConfig;

architecture Behavioral of SelectMapConfig is

	alias  cmd : std_logic_vector(2 downto 0) is ALOW(4 downto 2);

	constant cSM         : std_logic_vector(2 downto 0):="000"; -- X00  -
	constant cDispUpd    : std_logic_vector(2 downto 0):="001"; -- X04  -
	constant cUsbPktEnd  : std_logic_vector(2 downto 0):="010"; -- X08  -
	constant cProg       : std_logic_vector(2 downto 0):="100"; -- X10  -
	constant cMCS        : std_logic_vector(2 downto 0):="101"; -- X14  -
	constant cID         : std_logic_vector(2 downto 0):="111"; -- X1C  -- was FC
	
	signal count: std_logic_vector(1 downto 0) := "00";
	type states is (idle, waitInit1, waitInit2, SMwrite);
	signal state : states := idle;
	signal sMCS : STD_LOGIC :='1';
	signal sPRG : STD_LOGIC :='1';
	signal bclktmp : STD_LOGIC :='0';
	signal SMBUS: STD_LOGIC_VECTOR(0 to 7) := x"00";

begin


	config_proc : process(CLK, state,sMCS,sPRG,INIT,count,CTReg,cmd,CLK_1M25)
			variable nxt_state : states;
			variable iMCS : STD_LOGIC;
			variable iPRG : STD_LOGIC;
			variable iCMPL : STD_LOGIC;
			variable iUsbPktEnd : STD_LOGIC;
			variable iDispUpd : STD_LOGIC;
			
			variable icount: std_logic_vector(1 downto 0);
	begin
			nxt_state := state;
			iMCS := sMCS;
			iPRG := sPRG;
			iCMPL := '0';
			icount := "00";
			iUsbPktEnd := '0';
			iDispUpd := '0';
			
			case (state) is
				when waitInit1 =>
					if (CLK_1M25='1') then
						nxt_state := waitInit2;
					end if;

				when waitInit2 =>
					if (INIT='0' and CLK_1M25='0') then
						iPRG := '1';
						iCMPL := '1';
						nxt_state := idle;
					end if;

				when SMwrite =>
					icount := count+1;
					--if (count="01") then
					if (count="11") then
						iCMPL := '1';
						nxt_state := idle;
					end if;
					
				when idle =>
					if (CTReg='1') then
						case (cmd) is
							when cSM => 
								--icount := "01";
								nxt_state := SMwrite;
							when cProg => 
								iPRG := '0';
								iMCS := '1';
								if ( CLK_1M25='0') then
									nxt_state := waitInit1;
								end if;
							when cMCS => 
								iMCS := '0';
								iCMPL := '1';
								nxt_state := idle;
							when cUsbPktEnd => 
								iUsbPktEnd := '1';
								iCMPL := '1';
								nxt_state := idle;
							when cDispUpd => 
								iDispUpd := '1';
								iCMPL := '1';
								nxt_state := idle;

							when others =>
								iCMPL := '1';
								nxt_state := idle;
						end case;
					end if;
					
				when others =>
					iCMPL := '1';
					nxt_state := idle;
			end case;	
			
			if (CLK'event and CLK = '1') then
				if (UCDGPO2 = '0') then
					state <= nxt_state;
				end if;
				sMCS <= iMCS;
				sPRG <= iPRG;
				WCOMPLETE <= iCMPL;
				count <= icount;
				UsbPktEndCmd <= iUsbPktEnd;
				DispUpdCmd <= iDispUpd;
				
				if (icount="00") then 
					SMBUS <= MAPWORD(31 downto 24);
				elsif (icount="01") then 
					SMBUS <= MAPWORD(23 downto 16);
				elsif (icount="10") then 
					SMBUS <= MAPWORD(15 downto 8);
				else  
					SMBUS <= MAPWORD(7 downto 0);
				end if;

			end if;
	end process config_proc;
	
--	SMBUS <= MAPWORD(31 downto 24) when (count="00") else
--				MAPWORD(23 downto 16) when (count="01") else
--				MAPWORD(15 downto  8) when (count="10") else
--				MAPWORD( 7 downto  0);

	
	VA2 <= VA(2);
	VA5 <= VA(5);
	VA6 <= VA(6);

	
	VA  <=	SMBUS when (DONE='0') else
				VA0 & VA1 & '0' & VA3 & VA4 & '0' & '0' & VA7 when (INIT='0' and DONE='1') else
				VA0 & VA1 & 'Z' & VA3 & VA4 & 'Z' & 'Z' & VA7;

	QA  <=	SMBUS when (DONE='0') else
				"11111111" when (INIT='0' and DONE='1') else
				"ZZZZZZZZ";


	DCS <= not(sMCS) when (state=SMwrite) else '1';
	MCS <= sMCS when (state=SMwrite) else '1';
	PROG <= sPRG;

	bclktmp <= not(CLK) when (state=SMwrite) else '0';
	
	bitclk <= bclktmp;
	
--	cclk_proc : process(CLK,state)
--	begin
--		if (state/=SMwrite) then
--			bclktmp <= '0';
--		elsif (CLK'event) then  -- dual edge triggered
--			bclktmp <= not(bclktmp);
--		end if;
--	end process cclk_proc;
		

end Behavioral;

