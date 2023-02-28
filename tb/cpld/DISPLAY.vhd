----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:07:17 01/22/2009 
-- Design Name: 
-- Module Name:    DISPLAY - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

---- Uncomment the following library declaration if instantiating
---- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

ENTITY DISPLAY IS
    PORT ( --DIP 			: in  STD_LOGIC_VECTOR (7 downto 0);
           --SN 			: in  STD_LOGIC_VECTOR (9 downto 0);
			  DisplayData  : in  STD_LOGIC_VECTOR (31 downto 0);
			  CLK_40MHz		: in 	STD_LOGIC;
			  STARTUP		: in 	STD_LOGIC;
			  UPDATE			: in 	STD_LOGIC;
           DISPDATA 		: out  STD_LOGIC :='0';
           DISPLOAD 		: out  STD_LOGIC;
           DISPCLK 		: out  STD_LOGIC
			  );
END DISPLAY;

ARCHITECTURE Behavioral OF DISPLAY IS

	signal clk : std_logic;
	signal load : std_logic;
	signal upd : std_logic;

	type states is (idle, send, waiting);
	signal state : states := idle;
	
	signal charCnt : integer range 0 to 3;
	signal rowCnt  : integer range 0 to 5;
	signal bitCnt  : integer range 0 to 7;

	signal shiftReg : STD_LOGIC_VECTOR(7 downto 0);
	signal rowData : STD_LOGIC_VECTOR(4 downto 0);
	
	TYPE 		charData 		 is ARRAY (0 to 4) of INTEGER range 0 to 31; -- war SUBTYPE
	TYPE 		charData_vector is ARRAY (0 to 18) of charData;
	
	signal digit : integer range 0 to 18;
	signal char : charData;

	CONSTANT CHAR_0	: charData := (14,25,21,19,14); 	--		Example for a 2:
	CONSTANT CHAR_1	: charData := ( 0,18,31,16, 0); 	--		18:	* 0 0 0 *
	CONSTANT CHAR_2	: charData := (18,25,21,21,18);	--		25:	* * 0 0 *
	CONSTANT CHAR_3	: charData := (17,21,21,21,10);	--		21:	* 0 * 0 *
	CONSTANT CHAR_4	: charData := (12,10, 9,31, 8);	--		21:	* 0 * 0 *
	CONSTANT CHAR_5	: charData := (23,21,21,21, 9);	--		18:	* 0 0 * 0
	CONSTANT CHAR_6	: charData := (14,21,21,21, 8);
	CONSTANT CHAR_7	: charData := ( 1,25, 5, 3, 1);
	CONSTANT CHAR_8	: charData := (10,21,21,21,10);
	CONSTANT CHAR_9	: charData := ( 2,21,21,21,14);
	CONSTANT CHAR_A	: charData := (28,10, 9,10,28);
	CONSTANT CHAR_B	: charData := (17,31,21,21,10);
	CONSTANT CHAR_C	: charData := (14,17,17,17,17);
	CONSTANT CHAR_D	: charData := (17,31,17,17,14);
	CONSTANT CHAR_E	: charData := (31,21,21,21,17);
	CONSTANT CHAR_F	: charData := (31, 5, 5, 5, 1);
	CONSTANT CHAR_G	: charData := (14,17,17,21,13);
	CONSTANT CHAR_S	: charData := (18,21,21,21, 9);
	CONSTANT CHAR_X	: charData := (18,12,12,18, 0);  --  (18,12,12,18, 0)  (17,10, 4,10,17)


	CONSTANT LED_Data : charData_vector := (	CHAR_0,
															CHAR_1,
															CHAR_2,
															CHAR_3,
															CHAR_4,
															CHAR_5,
															CHAR_6,
															CHAR_7,
															CHAR_8,
															CHAR_9,
															CHAR_A,
															CHAR_B,
															CHAR_C,
															CHAR_D,
															CHAR_E,
															CHAR_F,
															CHAR_G,
															CHAR_S,
															CHAR_X
															);

BEGIN

	clk <= CLK_40MHz;  -- 5mhz
	
	digit <= CONV_INTEGER(DisplayData(28 downto 24)) when charCnt = 3
			else CONV_INTEGER(DisplayData(20 downto 16)) when charCnt = 2
			else CONV_INTEGER(DisplayData(12 downto 8)) when charCnt = 1
			else CONV_INTEGER(DisplayData(4 downto 0));
			
	char <= LED_Data(digit);
	
	
	rowData <= "000" & CONV_STD_LOGIC_VECTOR(charCnt, 2) when rowCnt = 5
			--else CONV_STD_LOGIC_VECTOR(rowCnt, 3) & CONV_STD_LOGIC_VECTOR(charCnt, 2);
			else CONV_STD_LOGIC_VECTOR(char(rowCnt),5);
	

	proc : process(clk, STARTUP)
		variable nxt_state : states;
		variable iload : std_logic;
		variable iupd : std_logic;
		variable icharCnt : integer range 0 to 3;
		variable irowCnt  : integer range 0 to 5;
		variable ibitCnt  : integer range 0 to 7;
		variable ishiftReg : STD_LOGIC_VECTOR(7 downto 0);
	begin

		nxt_state := state;
		iload := '1';
		iupd := upd;
		ibitCnt := (bitCnt - 1) mod 8;
		irowCnt := rowCnt;
		icharCnt := charCnt;
		ishiftReg := CONV_STD_LOGIC_VECTOR(rowCnt, 3) & rowData;
		
		case (state) is
				when send =>
					iload := '0';
					if (bitCnt = 0) then
						nxt_state := waiting;
					end if;
		
				when waiting =>
					if (bitCnt = 0) then
						
						if (rowCnt = 0) then
							irowCnt := 5;
							if (charCnt = 3) then
								icharCnt := 0;
								nxt_state := idle;
							else
								icharCnt := charCnt + 1;
								nxt_state := send;
							end if;
						else
							irowCnt := rowCnt - 1;
							nxt_state := send;
						end if;
						
						
					end if;

				when idle =>
					ibitCnt := 7;
					if (upd /= UPDATE) then
						iupd := not upd; 
						nxt_state := send;
					end if;
		end case;	
		
		
		
		
		if (STARTUP='0') then
			state <= idle;
			load <= '1';
			upd <= '1';
			charCnt <= 0;
			rowCnt <= 5;
			bitCnt <= 7;
		elsif (clk'event and clk = '0') then
			state <= nxt_state;
			load <= iload;
			upd <= iupd;
			charCnt <= icharCnt;
			rowCnt <= irowCnt;
			bitCnt <= ibitCnt;
			if (load = '0') then
				shiftReg(7 downto 0) <= shiftReg(0) & shiftReg(7 downto 1);
			else
				shiftReg <= ishiftReg;
			end if;
			
		end if;
	end process proc;
	
	
	

	DISPLOAD <= load;
	DISPDATA <= shiftReg(0);
	DISPCLK  <= clk AND not load;

END BEHAVIORAL;

