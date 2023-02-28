----------------------------------------------------------------------------------
-- Company:         INFN-LNF
-- Engineer:        alessandro.balla@lnf.infn.it
-- 
-- Create Date:     11:43:03 16/07/2021 
-- Design Name: 
-- Module Name:     tb_pkg.vhd - Package 
-- Project Name:    GANDARW
-- Target Devices:  XC5VSX95T-2FF1136
-- Tool versions:   ISE 14.7, QUESTASIM 10.7
-- Description:     Mix of Gandalf (amc) and Arwen\gbase_arwen 
--
-- Dependencies:    CPLD, DDR
--
-- Revision:        Revision 0.01 - File Created
--
-- Other Comments:  Eliminated gandalf_module entity from this file 
--
-- TestBench :      \Xil_14.7\GandArw\rtl\tb\testbench.vhd
-- Package :        \Xil_14.7\GandArw\rtl\tb\tb_pkg.vhd
-- Simulation :     
--                  
----------------------------------------------------------------------------------

LIBRARY ieee;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;
USE STD.STANDARD.ALL;
use STD.TEXTIO.all;

use WORK.G_PARAMETERS.ALL;

package TB_PKG is

    procedure tbprint (message : in string);

end;

package body TB_PKG is

    function std_bool (EXP_IN : in boolean) return std_logic is
    begin
        if (EXP_IN) then
            return('1');
        else
            return('0');
        end if;
    end std_bool;

    procedure tbprint (message : in string) is
        variable outline : line;
    begin
      write(outline, string'("## Time: "));
      write(outline, NOW, RIGHT, 0, ps);
      write(outline, string'("  "));
      write(outline, string'(message));
      writeline(output,outline);
    end tbprint;

end;
