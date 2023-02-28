
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE IEEE.NUMERIC_STD.ALL;

LIBRARY UNISIM;
USE UNISIM.VCOMPONENTS.ALL;


entity prot is
    Port ( 
        TVDATA          : out STD_LOGIC_VECTOR (31 downto 0);
	    FVDATA          : in  STD_LOGIC_VECTOR (31 downto 0);

		FSTART          : in  STD_LOGIC_VECTOR (13 downto 0);
		writeFlag       : in  STD_LOGIC;                      -- writeFlag=0 is "write to gandalf"
        FASTSTART       : in  STD_LOGIC;
		FRDY            : out STD_LOGIC;
		Error           : out STD_LOGIC;
		RESET           : in  STD_LOGIC;
		CLK             : in  STD_LOGIC;
			  
		UCDGPO2	        : in  STD_LOGIC;

		SpyRegReady     : out STD_LOGIC;
		SpyRegClear     : in  STD_LOGIC;
		SpyData         : out STD_LOGIC_VECTOR (31 downto 0);
		Status          : in  STD_LOGIC_VECTOR ( 3 downto 0);

		-- FPGA side
		VD              : inout STD_LOGIC_VECTOR(31 downto 0);
		FWRITE          : out STD_LOGIC;    -- VA0
		FSTROBE         : out STD_LOGIC;
		FREADY          : in  STD_LOGIC;
		FCONTROL        : out STD_LOGIC;
		FUBLAZE         : out STD_LOGIC;
		FFF             : in  STD_LOGIC;
		FFE             : in  STD_LOGIC;
		FRESET          : out STD_LOGIC     -- VA7
		);
end prot;

architecture Behavioral of prot is

begin

	FRESET <= '0';
	

	prot_block : block
		type states is (idle, addr, data, spyread, idle0, reading);
		signal state        : states := idle;
		signal FDIR         : STD_LOGIC :='0';
		signal sFWRITE      : STD_LOGIC :='0';
		signal sFSTROBE     : STD_LOGIC :='0';
		signal sFCONTROL    : STD_LOGIC :='0';
		signal sFUBLAZE     : STD_LOGIC :='0';
		signal sFREADY      : STD_LOGIC :='0';
		signal sFFE         : STD_LOGIC :='0';
        
		signal sError       : STD_LOGIC :='0';
		signal timeout      : INTEGER range 0 to 63 := 63;
		
		signal sSpyRegReady : STD_LOGIC :='0';
		

	begin
		prot : process(CLK, state,FDIR,sFWRITE,sFSTROBE,sFCONTROL,sFUBLAZE,FREADY,FSTART,FASTSTART,sError,timeout)
			variable nxt_state  : states;
			variable iFRDY      : STD_LOGIC;
			variable iFDIR      : STD_LOGIC;
            variable iFWRITE    : STD_LOGIC;
			variable iFSTROBE   : STD_LOGIC;
			variable iFCONTROL  : STD_LOGIC;
			variable iFUBLAZE   : STD_LOGIC;
			variable iError     : STD_LOGIC;
			variable iSpyRegSet : STD_LOGIC;
			
		begin
			nxt_state   := state;
			iFRDY       := '0';
			iFDIR       := FDIR;
			iFWRITE     := sFWRITE;
			iFSTROBE    := sFSTROBE;
			iFCONTROL   := sFCONTROL;
			iFUBLAZE    := sFUBLAZE;
			iError      := sError;
			iSpyRegSet  := '0';
			
			if(timeout=2) then
				iError := '1';
			end if;
			
			case (state) is
				when spyread =>
					if (sFREADY='1' or sError='1') then
						iSpyRegSet  := '1';
						iFSTROBE    := '0';
						nxt_state   := idle0;
					end if;
					
				when addr =>
					if (sFREADY='1' or sError='1') then
						iFDIR       := not writeFlag;
						iFSTROBE    := '0';
						nxt_state   := data;
					end if;

				when data =>
					if (sFREADY='0' or sError='1') then
						iFSTROBE    := '1';
						iFCONTROL   := '0';
						nxt_state   := reading;
					end if;

				when reading =>
					if (sFREADY='1' or sError='1') then
						iFRDY       := '1';
						iFSTROBE    := '0';
						nxt_state   := idle0;
					end if;

				when idle0 =>
					nxt_state   := idle;

				when idle =>
					iError      := '0';
					if (FASTSTART='1') then
--						if (FSTART(10)='1' and writeFlag='1') then
--							nxt_state := spyread;  -- spy fifo readout
--							iFWRITE := '0';
--							iFCONTROL := '0';
--							iFUBLAZE := '0';
--							iFDIR := '0';
--							if ( FFE='0' ) then
--								iFSTROBE := '1';
--								iError := '0';
--							else
--								iFSTROBE := '0';
--								iError := '1';
--							end if;
--						else
							nxt_state := addr;  -- protocol transaction
							iFWRITE := not writeFlag;
							iFSTROBE := '1';
							iFCONTROL := '1';
							iFUBLAZE := not FSTART(10);
							iFDIR := '1';
--						end if;

					elsif (sFFE='0' and sSpyRegReady='0' and Status(0)='1') then
						nxt_state := spyread;  -- spy fifo readout
						iFWRITE := '0';
						iFCONTROL := '0';
						iFUBLAZE := '0';
						iFDIR := '0';
						iFSTROBE := '1';
						iError := '0';
--					else
--						nxt_state := idle;
--						iFWRITE := '0';
--						iFCONTROL := '0';
--						iFUBLAZE := '0';
--						iFDIR := '0';
--						iFSTROBE := '0';
--						iError := '0';
--						iFRDY := '0';
--						iSpyRegSet := '0'; 
					end if;
					
				when others =>
					nxt_state   := idle0;
					iFRDY       := '1';
			end case;
			
			if (SpyRegClear='1') then
					sSpyRegReady <= '0';
			elsif(CLK'event and CLK = '1') then
				if (iSpyRegSet='1') then
					sSpyRegReady <= '1';
				end if;
			end if;
			
			
			if (CLK'event and CLK = '1') then
				if (UCDGPO2 = '0') then
					state   <= nxt_state;
				end if;
				FRDY        <= iFRDY;
				FDIR        <= iFDIR;
				sFWRITE     <= iFWRITE;
				sFSTROBE    <= iFSTROBE;
				sFCONTROL   <= iFCONTROL;
				sFUBLAZE    <= iFUBLAZE;
				sError      <= iError;
				--sFREADY <= FREADY;
				sFFE        <= FFE;
				
				
				if (iSpyRegSet='1') then
					SpyData <= VD;
				end if;
				
				if (iFRDY='1') then
					TVDATA <= VD;
				end if;
				
				if ( state=idle ) then
					timeout <= 63;
				else
					timeout <= timeout - 1;
				end if;

			end if;
		end process prot;

		sFREADY     <= FREADY;
		
		FWRITE      <= sFWRITE;
		FSTROBE     <= sFSTROBE;
		FCONTROL    <= sFCONTROL;
		FUBLAZE     <= sFUBLAZE;
		Error       <= sError;
		SpyRegReady <= sSpyRegReady;

		VD <= FVDATA when (FDIR='1' and sFCONTROL='0') 
				else ("000000000000000000000"&FSTART(10 downto 0)) when (FDIR='1' and sFCONTROL='1')
				else "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";

	
	end block prot_block;




end Behavioral;

