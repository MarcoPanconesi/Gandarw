----------------------------------------------------------------------------------
-- Company:         INFN-LNF
-- Engineer:        alessandro.balla@lnf.infn.it
-- 
-- Create Date:     11:43:03 15/07/2021 
-- Design Name: 
-- Module Name:     ieee_to_string.vhd - Package 
-- Project Name:    
-- Target Devices:  
-- Tool versions:   ISE 14.7, QUESTASIM 10.7
-- Description:     Convert std_logic_vector to string or to hex string 
--
-- Dependencies:    
--
-- Revision:        Revision 0.01 - File Created
--
-- Additional Comments: 
--
-- Package :        ieee_to_string.vhd
-- Note :           Modified to_hexstring to accept std_logic_vector(x downto y)
--                  
----------------------------------------------------------------------------------

library ieee; 
use ieee.std_logic_1164.all; 


package ieee_to_string is 
   function to_string(constant value: in std_ulogic; 
                      constant as_char_lit: in boolean := true) 
            return string; 


  function to_string(constant value: in std_ulogic_vector; 
                      constant as_string_lit: in boolean := true) 
            return string; 


  function to_string(constant value: in std_logic_vector; 
                      constant as_string_lit: in boolean := true) 
            return string; 

  	function to_hexstring(constant value: in std_logic_vector) return string;


end; 


package body ieee_to_string is 


  type val_list is array (std_ulogic) of character; 
   constant char_val : val_list := "UX01ZWLH-"; 


  function to_string(constant value: in std_ulogic; 
                      constant as_char_lit: in boolean := true) 
   return string 
   is 
   begin 
     if as_char_lit then 
       return string'("'" & char_val(value) & "'"); 
     end if; 
     return string'("" & char_val(value)); 
   end; 


  function to_string(constant value: in std_ulogic_vector; 
                      constant as_string_lit: in boolean := true) 
   return string 
   is 
     variable str: string(1 to value'length) := (others => ' '); 
     variable idx: natural := 1; 
   begin 
     for i in value'range loop 
       str(idx to idx) := to_string(value(i), false); 
       idx := idx + 1; 
     end loop; 
     if as_string_lit then 
       return string'('"' & str & '"'); 
     end if; 
     return str; 
   end; 


  function to_string(constant value: in std_logic_vector; 
                      constant as_string_lit: in boolean := true) 
   return string 
   is 
   begin 
     return to_string(std_ulogic_vector(value), as_string_lit); 
   end; 

-- converts a std_logic_vector into a hex string.
	function to_hexstring(constant value: in std_logic_vector) return string is
	    variable hexlen: integer;
	    variable longslv : std_logic_vector(67 downto 0) := (others => '0');
	    variable hex : string(1 to 16);
	    variable fourbit : std_logic_vector(3 downto 0);
	  begin
	    hexlen := (value'length)/4;
	    if (value'length) mod 4 /= 0 then
	      hexlen := hexlen + 1;
	    end if;
	    longslv(value'length - 1 downto 0) := value;
	    for i in (hexlen -1) downto 0 loop
	      fourbit := longslv(((i*4)+3) downto (i*4));
	      case fourbit is
	        when "0000" => hex(hexlen -I) := '0';
	        when "0001" => hex(hexlen -I) := '1';
	        when "0010" => hex(hexlen -I) := '2';
	        when "0011" => hex(hexlen -I) := '3';
	        when "0100" => hex(hexlen -I) := '4';
	        when "0101" => hex(hexlen -I) := '5';
	        when "0110" => hex(hexlen -I) := '6';
	        when "0111" => hex(hexlen -I) := '7';
	        when "1000" => hex(hexlen -I) := '8';
	        when "1001" => hex(hexlen -I) := '9';
	        when "1010" => hex(hexlen -I) := 'A';
	        when "1011" => hex(hexlen -I) := 'B';
	        when "1100" => hex(hexlen -I) := 'C';
	        when "1101" => hex(hexlen -I) := 'D';
	        when "1110" => hex(hexlen -I) := 'E';
	        when "1111" => hex(hexlen -I) := 'F';
	        when "ZZZZ" => hex(hexlen -I) := 'Z';
	        when "UUUU" => hex(hexlen -I) := 'U';
	        when "XXXX" => hex(hexlen -I) := 'X';
	        when others => hex(hexlen -I) := '?';
	      end case;
	    end loop;
	    return hex(1 to hexlen);
	  end to_hexstring;

end; 
