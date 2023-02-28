
library ieee;
use ieee.std_logic_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.ALL;
library UNISIM;
use UNISIM.Vcomponents.ALL;



entity USB is
    Port ( 
		CLK		: in  STD_LOGIC;
		IFCLK 	: out  STD_LOGIC := '0';
      RESET 	: out  STD_LOGIC := '0';
      READY 	: in  STD_LOGIC;
      INT 		: in  STD_LOGIC;
      SLOE 		: out  STD_LOGIC := '1' ;
      FIFOADR 	: out  STD_LOGIC_VECTOR (2 downto 0);
      PKTEND 	: out  STD_LOGIC := '1';
      CS 		: out  STD_LOGIC := '0';
      FDATA 	: inout  STD_LOGIC_VECTOR (15 downto 0);
      SLRD 		: out  STD_LOGIC := '1';
      SLWR 		: out  STD_LOGIC := '1';
      FLAGA 	: in  STD_LOGIC;
      FLAGB 	: in  STD_LOGIC;
      FLAGC 	: in  STD_LOGIC;
		UCDGPO1	: in  STD_LOGIC;
		UCDGPO2	: in  STD_LOGIC;
		
      --SpyEmpty	: in  STD_LOGIC;	-- not used?

		SpyRegReady : in STD_LOGIC;
		SpyRegClear : out STD_LOGIC;
		SpyData : in STD_LOGIC_VECTOR (31 downto 0);
		
		ToHost   : in    std_logic_vector (31 downto 0); 
		Status   : in    std_logic_vector (3 downto 0); 
      FromHost : out   std_logic_vector (31 downto 0) := (others => '0');
      ALOW     : out   std_logic_vector (15 downto 0) := (others => '0');
		writeFlag: out   std_logic := '0';
      CTReg    : out   std_logic_vector (1 downto 0)  := (others => '0');
      CTFinish : in    std_logic;
		UsbPktEndCmd : in STD_LOGIC;
		
		USBConnected  : OUT std_logic;
		
		LED4     : OUT std_logic;
		LED5     : OUT std_logic
	);
end USB;


architecture Behavioral of USB is

	signal sIFCLK : std_logic := '0';
	signal TO_USB : std_logic := '0';
	signal FD_L : STD_LOGIC_VECTOR (7 downto 0) := x"00";
	signal FD_H : STD_LOGIC_VECTOR (7 downto 0) := x"00";
	signal ENUMOK : std_logic := '0';
	signal sREADY : std_logic := '0';
	signal sCTReg : std_logic_vector (1 downto 0) := "00";
	signal sFIFOADR : STD_LOGIC_VECTOR (2 downto 0) :=b"100";
	--signal cyConfigure : std_logic := '1';
	signal cyConfCount : integer range 0 to 1 := 1;  -- do not use quad buffering
	signal UsbPktEndReg : std_logic := '0';
	
	signal xSLRD : std_logic := '1';
	signal xSLWR : std_logic := '1';
	signal xPKTEND : std_logic := '1';
	
	
		type states is (idle, read1, read2, write1, write2, cmdreq1, cmdreq2, waitReady, waitonfpga, waitReadyReq, prog1, prog2, spy1, spy2);
		signal state : states := idle;
		
		type readtypes is (irq, data);
		signal readwhat : readtypes := irq;
		
		type reqtypes is (rd_setup, wr_bcnt, rd_bcnt, rd_ep0buf, wr_ep0buf, cyConf);
		signal reqwhat : reqtypes := rd_setup;
		
		type nibbles is (upper, lower);
		signal nibble : nibbles := upper;
		
		signal byteCount : integer range 0 to 7 := 0;
		signal wordCount : std_logic := '0';
		
		signal wait4data : std_logic := '0';
		signal hasdata : std_logic := '0';
		signal direction : std_logic := '0';
		signal validreq : std_logic := '1';
		signal destination : std_logic := '0';
		
		signal ToHostByte : STD_LOGIC_VECTOR (7 downto 0);
		
		signal UsbIdle : std_logic := '0';
		
begin


	UsbMachine : process(CLK, state,readwhat,reqwhat,byteCount,nibble,wait4data,hasdata,TO_USB,ENUMOK,
								FDATA,READY,sIFCLK,INT,sREADY,direction,validreq,destination,CTFinish,sCTReg,ToHost,
								wordCount,sFIFOADR,cyConfCount,FLAGA)
			variable nxt_state : states;
			variable ireadwhat : readtypes;
			variable ireqwhat : reqtypes;
			variable ibyteCount : integer range 0 to 7;
			variable iwordCount : std_logic;
			variable inibble : nibbles;
			variable iwait4data : std_logic;
			variable ihasdata : std_logic;
			variable istrobeD : STD_LOGIC_VECTOR (5 downto 0);
			variable istrobeA : STD_LOGIC_VECTOR (1 downto 0);
			variable idirection : std_logic;
			variable ivalidreq : std_logic;
			variable idestination : std_logic;
			variable istartCommand : std_logic;
			variable iFIFOADR : STD_LOGIC_VECTOR (2 downto 0);
			--variable icyConfigure : std_logic;
			variable icyConfCount : integer range 0 to 1;
			variable iUsbPktEndClr : std_logic;
			
			variable iSpyRegClear : std_logic;

			variable iTO_USB : std_logic;
			variable iSLRD : std_logic;
			variable iSLWR : std_logic;
			variable iPKTEND : std_logic;
			variable iENUMOK : std_logic;
			variable iFD_L : STD_LOGIC_VECTOR (7 downto 0);
			variable iFD_H : STD_LOGIC_VECTOR (7 downto 0);
			variable iToHostByte : STD_LOGIC_VECTOR (7 downto 0);
			
			variable iLED4 : std_logic;
			variable iLED5 : std_logic;
			
			variable dontcare : STD_LOGIC_VECTOR (2 downto 0);
			
	begin
			nxt_state := state;
			ireadwhat := readwhat;
			ireqwhat := reqwhat;
			ibyteCount := byteCount;
			iwordCount := wordCount;
			inibble := nibble;
			iwait4data := wait4data;
			ihasdata := hasdata;
			idirection := direction;
			ivalidreq := validreq;
			idestination := destination;
			iFIFOADR := sFIFOADR;
			icyConfCount := cyConfCount;
			
			iUsbPktEndClr := '0';
			iSpyRegClear := '0';
			
			istrobeD := "000000";
			istrobeA := "00";
			istartCommand := '0';
			iFD_L := "--------";
			iFD_H := "--------";
			iToHostByte := ToHostByte;

			iTO_USB := TO_USB;
			iSLRD := '1';
			iSLWR := '1';
			iPKTEND := '1';
			iENUMOK := ENUMOK;
			
			iLED4 := '0';
			iLED5 := '0';
			
			dontcare := "---";
			
			case (state) is

				when read1 =>
					iSLRD := '0';
					nxt_state := read2;

				when read2 =>
					iSLRD := '0';
					nxt_state := idle;
					iwait4data := '0';
					
					case (readwhat) is
						when irq =>
							ibyteCount := to_integer(unsigned(dontcare));
							if (FDATA(2)='1') then -- int 2: enumok
								iENUMOK := '1';
							elsif (FDATA(1)='1') then -- int 1: busactivity
								iENUMOK := '0';
							elsif (FDATA(7)='1') then -- int 7: setup
								nxt_state := cmdreq1;
								ireqwhat := rd_setup;
								ibyteCount := 7;
								ivalidreq := '1';
								--iLED5 := '1';
							elsif (FDATA(6)='1') then -- int 6: ep0buf
								ihasdata := '0';  -- clear hasdata flag
								if ( direction='0' ) then
									nxt_state := cmdreq1;
									ireqwhat := rd_bcnt;  -- out (to gandalf)
								else
									nxt_state := waitonfpga;
									ireqwhat := wr_ep0buf;  -- in (to host)
									ibyteCount := 3;
								end if;
								--iLED4 := '1';
							end if;
						
						-- byteCount is a down counter, so the first byte in the setup packet is byteCount=7
						when data =>
							case (reqwhat) is
								when rd_bcnt =>
									ibyteCount := 4; --to_integer(unsigned(FDATA(2 downto 0)));   -- only 4 byte ep0buf allowed
									ireqwhat := rd_ep0buf;
								
								when rd_setup =>
									if ( byteCount=7 ) then
										if ( FDATA(6) /= '1' ) then ivalidreq := '0'; end if;	 	--  vendor req to device
										idirection := FDATA(7);   											-- 0=out (to gandalf),   1=in (to host)
									elsif ( byteCount=6 ) then
										if ( FDATA(6) /= '1' ) then ivalidreq := '0'; end if; 	--  check request code
										idestination := FDATA(7); 											-- 0=config block,   1=protocol block
									elsif ( byteCount=5 ) then
										istrobeA(0) := '1';
									elsif ( byteCount=4 ) then
										istrobeA(1) := '1';

									elsif ( byteCount=1 ) then		-- is a data stage available? (only 4 byte ep0buf allowed)
										if ( FDATA(2 downto 0) /= "000" ) then ihasdata := '1'; else ihasdata := '0'; end if;	
									end if;
									
								
								when rd_ep0buf =>  -- rd_ep0buf
									-- data is here
									if    ( byteCount=3 ) then istrobeD(3) := '1';
									elsif ( byteCount=2 ) then istrobeD(2) := '1';
									elsif ( byteCount=1 ) then istrobeD(1) := '1';
									elsif ( byteCount=0 ) then istrobeD(0) := '1';
									end if;
									
								when others =>
									null;
									--ireqwhat := rd_ep0buf;
									
							end case; -- reqwhat

							if ( ibyteCount /= 0 ) then
								ibyteCount := ibyteCount - 1;
								nxt_state := cmdreq1;
							elsif ( reqwhat = rd_setup and hasdata = '0' ) then
								nxt_state := cmdreq1;
								ireqwhat := wr_bcnt;
								istartCommand := '1';
							elsif ( (reqwhat = rd_setup and direction = '1') or reqwhat = rd_ep0buf ) then
								istartCommand := '1';
							end if;

					end case; -- readwhat

					
				when cmdreq1 =>
					iTO_USB := '1';
					iSLWR := '0';
					nxt_state := cmdreq2;

				when cmdreq2 =>
					iSLWR := '0';
					case (reqwhat) is
						when rd_ep0buf =>
							iFD_L := "11110001";  -- read from 0x31
							nxt_state := idle;  -- go and wait for int#
							iwait4data := '1';
						when rd_setup =>
							iFD_L := "11110010";  -- read from 0x32
							nxt_state := idle;  -- go and wait for int#
							iwait4data := '1';
						when rd_bcnt =>
							iFD_L := "11110011";  -- read from 0x33
							nxt_state := idle;  -- go and wait for int#
							iwait4data := '1';
						when wr_bcnt =>
							iFD_L := "10110011";  -- write to 0x33
							nxt_state := waitReady;  -- go and wait for ready
						when wr_ep0buf =>
							iFD_L := "10110001";  -- write to 0x31
							nxt_state := waitReady;  -- go and wait for ready
						when cyConf =>
--							if ( cyConfCount=2 ) then
--								iFD_L := "10001000";  -- write to 0x08  (EP6CFG)
--							elsif ( cyConfCount=1 ) then
--								iFD_L := "10001001";  -- write to 0x09  (EP8CFG)
--							else
								iFD_L := "10000010";  -- write to 0x02  (FLAGSAB)
--							end if;
							nxt_state := waitReady;  -- go and wait for ready
					end case;
						


				when write1 =>			-- prepare the byte which is written in the next state
					iSLWR := '0';
					nxt_state := write2;
					
					case (reqwhat) is
						when wr_bcnt =>
							if ( byteCount=0 ) then
								iToHostByte := "00000000";
							else
								iToHostByte := "00000100";
							end if;
							
						when cyConf =>
--							if ( cyConfCount=2 ) then
--								iToHostByte := "11100000"; -- EP6CFG, quad buffering
--							elsif ( cyConfCount=1 ) then
--								iToHostByte := "00000000"; -- EP8CFG, off
--							else
								iToHostByte := "11101000";	-- FLAGB=EP6FF   FLAGA=EP2EF								
--							end if;

						when wr_ep0buf =>  -- wr_ep0buf
							if ( byteCount=3 ) then
								iToHostByte := ToHost(31 downto 24);
							elsif ( byteCount=2 ) then
								iToHostByte := ToHost(23 downto 16);
							elsif ( byteCount=1 ) then
								iToHostByte := ToHost(15 downto  8);
							elsif ( byteCount=0 ) then
								iToHostByte := ToHost( 7 downto  0);
							else 
								iToHostByte := "--------";
							end if;
							
						when others =>
							null;
						
					end case;


				when write2 =>			-- write the byte in two nibbles
					iSLWR := '0';
					case (nibble) is
						when upper =>
							iFD_L := "0---"& ToHostByte(7 downto 4);
							inibble := lower;
							nxt_state := waitReady;  	-- go and wait for ready
						when lower =>
							iFD_L := "0---"& ToHostByte(3 downto 0);
							inibble := upper;
							if ( reqwhat = wr_ep0buf ) then
								ibyteCount := ibyteCount - 1;  	-- (this has to be here)
								nxt_state := waitReadyReq;			-- wait until ready for next word
								if( byteCount=0 ) then 
									ireqwhat := wr_bcnt;
								end if;
							else
								nxt_state := idle;  	-- finished
							end if;
					end case;
							

				when waitonfpga =>
					if (sCTReg="00" and sIFCLK='0') then -- fpga is ready? 
						nxt_state := cmdreq1;
					end if;

				when waitReady =>
					if (READY='1' and sIFCLK='0') then -- ready is high? 
						nxt_state := write1;
					end if;

				when waitReadyReq =>
					if (READY='1' and sIFCLK='0') then -- ready is high? 
						nxt_state := cmdreq1;
					end if;

				when idle =>
					if ( sIFCLK='0' ) then
						if ( INT='0' ) then 					-- int# asserted? 
							iTO_USB := '0';
							iFIFOADR := "100";
							nxt_state := read1;
							if ( sREADY = '1' and wait4data = '1' ) then
								ireadwhat := data;    		-- data is ready on FD
							else
								ireadwhat := irq;     		-- interrupt byte is on FD
							end if;
						elsif ( UsbIdle='1' and cyConfCount/=0 ) then		-- cy7c registers not yet configured
							iTO_USB := '1';
							iFIFOADR := "100";
							nxt_state := cmdreq1;
							ireqwhat := cyConf;
							icyConfCount := cyConfCount-1;
						elsif ( UsbIdle='1' and FLAGA='1' and sCTReg="00" ) then  		-- prog fifo not empty
							iTO_USB := '0';
							iFIFOADR := "000";
							nxt_state := prog1;
							ivalidreq := '1';
						elsif ( UsbIdle='1' and FLAGB='1' and (SpyRegReady='1' or UsbPktEndReg='1') and Status(0)='1') then  -- and sCTReg="00"
							iTO_USB := '1';							-- usb-fifo!=full and (spy-word-ready or PktEndRequest) and FPGA-DONE
							iFIFOADR := "010";
							idirection := '1';  -- in (to host)
							idestination := '1';
							ivalidreq := '1';
							nxt_state := spy1;
							if(UsbPktEndReg='1') then
								iwordCount := '1';
							end if;
						end if;
					end if;
					
					
				when spy1 =>
					iSLWR := UsbPktEndReg;  -- '0' for normal write
					iPKTEND := not UsbPktEndReg;
					nxt_state := spy2;
					


				when spy2 =>
					iSLWR := UsbPktEndReg;  -- '0' for normal write
					iPKTEND := not UsbPktEndReg;
					iwordCount := not(wordCount);
					if ( wordCount = '0' ) then
						iFD_L := SpyData(31 downto 24);
						iFD_H := SpyData(23 downto 16);
						iSpyRegClear := '1';
						nxt_state := spy1;
					else
						iFD_L := SpyData(15 downto  8);
						iFD_H := SpyData( 7 downto  0);
						iUsbPktEndClr := '1';
						nxt_state := idle;
					end if;


				when prog1 =>
					iSLRD := '0';
					nxt_state := prog2;
					
				when prog2 =>
					iSLRD := '0';
					iwordCount := not(wordCount);
					if ( wordCount = '0' ) then
						nxt_state := prog1;
						istrobeD(3) := '1';
						istrobeD(5) := '1';
					else
						nxt_state := idle;
						istrobeD(1) := '1';
						istrobeD(4) := '1';
						istartCommand := '1';
					end if;


				when others =>
					nxt_state := idle;
			end case;	
			
		----------------------------------------------------------
			
			if (CLK'event and CLK = '1') then
				if (UCDGPO2 = '0') then
					state <= nxt_state;
				end if;
					readwhat <= ireadwhat;
					reqwhat <= ireqwhat;
					byteCount <= ibyteCount;
					wordCount <= iwordCount;
					nibble <= inibble;
					wait4data <= iwait4data;
					hasdata <= ihasdata;
					direction <= idirection;
					validreq <= ivalidreq;
					destination <= idestination;
					sFIFOADR <= iFIFOADR;
					cyConfCount <= icyConfCount;
					
					SpyRegClear <= iSpyRegClear;

					TO_USB <= iTO_USB;
					xSLRD <= iSLRD;
					xSLWR <= iSLWR;
					xPKTEND <= iPKTEND;
					ENUMOK <= iENUMOK;
					FD_L <= iFD_L;
					FD_H <= iFD_H;
					ToHostByte <= iToHostByte;
					
					if (ENUMOK='1' and iwait4data='0' and ihasdata='0') then
						UsbIdle <= '1';
					else
						UsbIdle <= '0';
					end if;
					

					--if( istrobeA(2)='1' ) then
					--	ALOW(15 downto 0) <= x"3" & "------------";
					--else
						if( istrobeA(1)='1' ) then
							ALOW(15 downto  8) <= FDATA(7 downto 0);
						end if;
						if( istrobeA(0)='1' ) then
							ALOW( 7 downto  0) <= FDATA(7 downto 0);
						end if;
					--end if;
					
					if( istrobeD(3)='1' ) then
						FromHost(31 downto 24) <= FDATA(7 downto 0);
					end if;
					if( istrobeD(2)='1' ) then
						FromHost(23 downto 16) <= FDATA(7 downto 0);
					elsif( istrobeD(5)='1' ) then
						FromHost(23 downto 16) <= FDATA(15 downto 8);
					end if;

					if( istrobeD(1)='1' ) then
						FromHost(15 downto  8) <= FDATA(7 downto 0);
					end if;
					if( istrobeD(0)='1' ) then
						FromHost( 7 downto  0) <= FDATA(7 downto 0);
					elsif( istrobeD(4)='1' ) then
						FromHost( 7 downto  0) <= FDATA(15 downto 8);
					end if;
					
					-- for debugging
					LED4 <= iLED4;
					LED5 <= iLED5;
			end if;


			-- create StartCommand signals for Protocol and configuration block
			if (CTFinish='1') then
				sCTReg <= "00";
			elsif (CLK'event and CLK = '1') then
				if ( istartCommand='1' and validreq='1' ) then
					sCTReg <= destination & not(destination);
				end if;
			end if;


			if (UsbPktEndCmd='1') then
				UsbPktEndReg <= '1';
			elsif (CLK'event and CLK = '1') then
				if ( iUsbPktEndClr='1' ) then
					UsbPktEndReg <= '0';
					
				end if;
			end if;

			
	end process UsbMachine;



	writeFlag <= direction;
	
	CTReg <= sCTReg;
	USBConnected <= ENUMOK;

	--FIFOADR <= sFIFOADR;
	FIFOADR <= "000" when (UCDGPO1='1' and UCDGPO2='0') -- (this is never true, but is used for delay)
				else sFIFOADR;

	SLOE <= '1' when (UCDGPO1='1' and UCDGPO2='0') -- (this is never true, but is used for delay)
				else TO_USB;
	--SLOE <= TO_USB;
	FDATA <= FD_H & FD_L when (TO_USB='1') 
			else "ZZZZZZZZZZZZZZZZ";

	CS <= '0';
	RESET <= not UCDGPO1;

	--create 20MHz USB ifclk
	ifclkdiv : process (CLK)
	begin
		if (CLK'event and CLK = '0') then
			sIFCLK <= not sIFCLK;
		end if;
	end process ifclkdiv;	
	--IFCLK <= sIFCLK;
	IFCLK <= '0' when (UCDGPO1='1' and UCDGPO2='0') -- (this is never true, but is used for delay)
				else sIFCLK;


	SLRD <= '1' when (UCDGPO1='1' and UCDGPO2='0') -- (this is never true, but is used for delay)
				else xSLRD;
	SLWR <= '1' when (UCDGPO1='1' and UCDGPO2='0') -- (this is never true, but is used for delay)
				else xSLWR;
	PKTEND <= '1' when (UCDGPO1='1' and UCDGPO2='0') -- (this is never true, but is used for delay)
				else xPKTEND;

	
	-- store ready status when int is asserted
	LatchReady : process(INT)
	begin
		if (INT'event and INT = '0') then
			sREADY <= READY;
		end if;
	end process LatchReady;	


end Behavioral;

