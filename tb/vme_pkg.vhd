----------------------------------------------------------------------------------
-- Company:         INFN-LNF
-- Engineer:        alessandro.balla@lnf.infn.it
-- 
-- Create Date:     11:43:03 15/07/2021 
-- Design Name: 
-- Module Name:     vme_pkg.vhd - TestBench 
-- Project Name:    GANDARW
-- Target Devices:  XC5VSX95T-2FF1136
-- Tool versions:   ISE 14.7, QUESTASIM 10.7
-- Description:     Mix of Gandalf (amc) and Arwen\gbase_arwen 
--
-- Dependencies:    CPLD, DDR
--
-- Revision:        Revision 0.01 - File Created
--
-- Other Comments: 
--
-- TestBench :      \Xil_14.7\GandArw\rtl\tb\testbench.vhd
-- Package :        \Xil_14.7\GandArw\rtl\tb\vme_pkg.vhd
-- Simulation :     
--                  
--                  
--                  
----------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

LIBRARY STD;
USE STD.STANDARD.ALL;
USE STD.TEXTIO.ALL;

package VME_PKG is

    type r_vme_out is
    record
        CA                   : std_logic_vector(31 downto 0);
        CD                   : std_logic_vector(31 downto 0);
        CAM                  : std_logic_vector( 5 downto 0);
        CAS                  : std_logic;
        CDS0                 : std_logic;
        CDS1                 : std_logic;
        CWRITE               : std_logic;
    end record;

    constant r_vme_out_default : r_vme_out :=(
            CA               => (others => '1'),
            CD               => (others => 'Z'),
            CAM              => (others => '1'),
            CAS              => '1',
            CDS0             => '1',
            CDS1             => '1',
            CWRITE           => '1'
        );
    
    type r_vme_in is
    record
        CD                   : std_logic_vector(31 downto 0);
        CDTACK               : std_logic;
        CBERR                : std_logic;
    end record;

-- Procedure body
    procedure vme_read (c_addr : in std_logic_vector(31 downto 0);c_data : out std_logic_vector(31 downto 0); signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);
    procedure vme_write(c_addr : in std_logic_vector(31 downto 0);c_data : in  std_logic_vector(31 downto 0); signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);

-- AM table. 
    -- References:
    -- Table 2-3 "Address Modifier Codes" pages 21/22 VME64std ANSI/VITA 1-1994
    -- Table 2.4 "Extended Address Modifier Code" page 12 2eSST ANSI/VITA 1.5-2003(R2009)
    constant c_A24_S_sup         : std_logic_vector(5 downto 0) := "111101";    -- hex code 0x3d
    constant c_A24_S             : std_logic_vector(5 downto 0) := "111001";    -- hex code 0x39
    constant c_A24_BLT           : std_logic_vector(5 downto 0) := "111011";    -- hex code 0x3b
    constant c_A24_BLT_sup       : std_logic_vector(5 downto 0) := "111111";    -- hex code 0x3f
    constant c_A24_MBLT          : std_logic_vector(5 downto 0) := "111000";    -- hex code 0x38
    constant c_A24_MBLT_sup      : std_logic_vector(5 downto 0) := "111100";    -- hex code 0x3c
    constant c_A24_LCK           : std_logic_vector(5 downto 0) := "110010";    -- hex code 0x32
    constant c_CR_CSR            : std_logic_vector(5 downto 0) := "101111";    -- hex code 0x2f
    constant c_A16               : std_logic_vector(5 downto 0) := "101001";    -- hex code 0x29
    constant c_A16_sup           : std_logic_vector(5 downto 0) := "101101";    -- hex code 0x2d
    constant c_A16_LCK           : std_logic_vector(5 downto 0) := "101100";    -- hex code 0x2c
    constant c_A32               : std_logic_vector(5 downto 0) := "001001";    -- hex code 0x09
    constant c_A32_sup           : std_logic_vector(5 downto 0) := "001101";    -- hex code 0x0d
    constant c_A32_BLT           : std_logic_vector(5 downto 0) := "001011";    -- hex code 0x0b  
    constant c_A32_BLT_sup       : std_logic_vector(5 downto 0) := "001111";    -- hex code 0x0f
    constant c_A32_MBLT          : std_logic_vector(5 downto 0) := "001000";    -- hex code 0x08
    constant c_A32_MBLT_sup      : std_logic_vector(5 downto 0) := "001100";    -- hex code 0x0c
    constant c_A32_LCK           : std_logic_vector(5 downto 0) := "000101";    -- hex code 0x05
    constant c_A64               : std_logic_vector(5 downto 0) := "000001";    -- hex code 0x01
    constant c_A64_BLT           : std_logic_vector(5 downto 0) := "000011";    -- hex code 0x03
    constant c_A64_MBLT          : std_logic_vector(5 downto 0) := "000000";    -- hex code 0x00
    constant c_A64_LCK           : std_logic_vector(5 downto 0) := "000100";    -- hex code 0x04
    constant c_TWOedge           : std_logic_vector(5 downto 0) := "100000";    -- hex code 0x20
    constant c_A32_2eVME         : std_logic_vector(7 downto 0) := "00000001";  -- hex code 0x21
    constant c_A64_2eVME         : std_logic_vector(7 downto 0) := "00000010";  -- hex code 0x22
    constant c_A32_2eSST         : std_logic_vector(7 downto 0) := "00010001";  -- hex code 0x11
    constant c_A64_2eSST         : std_logic_vector(7 downto 0) := "00010010";  -- hex code 0x12    

end;

package body VME_PKG is

-------------------------------------------------------------------------------
-- VME SINGLE READ AND WRITE 
    procedure vme_read (c_addr : in std_logic_vector(31 downto 0);c_data : out std_logic_vector(31 downto 0); signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    -- vme_read @ c_addr, c_data
    -- cvmeport.vhd
    -- AMvalid      <= '1' when CAM(5 downto 3)&CAM(0) = "0011" else '0'; AM = ("09","0D","0B","0F") 
    -- BoardSel     <= '1' when CA(31 downto 16) = X"E0" & (not DIP) else '0';   
    -- BroadcastSel <= '1' when CA(31 downto 24)&CA(15) = X"E0"&'1' else '0';
    -- BoardSelect  <= AMvalid and (BoardSel or BroadcastSel) and CIACK and not CA(0) and not CA(1) and not USBConnected;
    variable ti : time;
    begin
        ti := now;
        if vme_i.CDTACK = '0' or vme_i.CBERR = '0' then
            wait until vme_i.CDTACK = '1' and vme_i.CBERR = '1';
        end if;
        -- default
        vme_o.CD        <= (others => 'Z');
		vme_o.CA        <= (others => '1');
		vme_o.CAM       <= (others => '1');
		vme_o.CWRITE    <= '1';
        vme_o.CAS       <= '1'; 
        vme_o.CDS0      <= '1'; 
        vme_o.CDS1      <= '1';
	    wait for 10 ns; 
		vme_o.CA        <= c_addr;
		vme_o.CAM       <= c_A32_sup;
		vme_o.CWRITE    <= '1';
	    wait for 10 ns; -- check the min time here...for master is 35 ns and for slave 10 ns.
        vme_o.CAS       <= '0'; 
        vme_o.CDS0      <= '0'; 
        vme_o.CDS1      <= '0'; 
        wait until vme_i.CDTACK = '0' or vme_i.CBERR = '0' or (now > ti + 4 us); -- 
        if vme_i.CBERR = '0' or (now > ti + 4 us) then
            report "SLAVE TIMEOUT OR BERR LINE ASSERTED " severity error;
        end if;
        c_data          := vme_i.CD;     
        vme_o.CAS       <= '1'; 
        wait for 5 ns; 
        vme_o.CDS0      <= '1'; 
        vme_o.CDS1      <= '1';
		vme_o.CA        <= (others => '1');
		vme_o.CAM       <= (others => '1');
		vme_o.CWRITE    <= '1';
    end procedure;

    procedure vme_write (c_addr : in std_logic_vector(31 downto 0);c_data : in std_logic_vector(31 downto 0); signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    -- vme_write @ c_addr, c_data 
    -- cvmeport.vhd
    -- AMvalid      <= '1' when CAM(5 downto 3)&CAM(0) = "0011" else '0'; AM = ("09","0A","0D","0F") 
    -- BoardSel     <= '1' when CA(31 downto 16) = X"E0" & (not DIP) else '0';   
    -- BroadcastSel <= '1' when CA(31 downto 24)&CA(15) = X"E0"&'1' else '0';
    -- BoardSelect <= AMvalid and (BoardSel or BroadcastSel) and CIACK and not CA(0) and not CA(1) and not USBConnected;
    variable ti : time;
    begin
        ti := now;
        if vme_i.CDTACK = '0' or vme_i.CBERR = '0' then
            wait until vme_i.CDTACK = '1' and vme_i.CBERR = '1';
        end if;
        -- default
        vme_o.CD      <= (others => 'Z');
		vme_o.CA      <= (others => '1');
		vme_o.CAM     <= (others => '1');
		vme_o.CWRITE  <= '1';
        vme_o.CAS     <= '1'; 
        vme_o.CDS0    <= '1'; 
        vme_o.CDS1    <= '1';
	    wait for 10 ns; 
		vme_o.CA      <= c_addr;
		vme_o.CAM     <= c_A32_sup;
		vme_o.CWRITE  <= '0';
	    wait for 35 ns; -- check the min time here...for master is 35 ns and for slave 10 ns.
        vme_o.CD      <= c_data;
        vme_o.CAS     <= '0'; 
        vme_o.CDS0    <= '0'; 
        vme_o.CDS1    <= '0'; 
        wait until vme_i.CDTACK = '0' or vme_i.CBERR = '0' or (now > ti + 4 us); -- 
        if vme_i.CBERR = '0' or (now > ti + 4 us) then
            report "SLAVE TIMEOUT OR BERR LINE ASSERTED " severity error;
        end if;     
        vme_o.CAS     <= '1'; 
        wait for 5 ns; 
        vme_o.CDS0    <= '1'; 
        vme_o.CDS1    <= '1';
        vme_o.CD      <= (others => 'Z');
		vme_o.CA      <= (others => '1');
		vme_o.CAM     <= (others => '1');
		vme_o.CWRITE  <= '1';
    end procedure;
-------------------------------------------------------------------------------

end;
