library IEEE;
use IEEE.STD_LOGIC_1164.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;



entity randomtrigger is	 -- siehe http://www.technik-emden.de/~rabe/veranstaltungen/Digitaltechnik/Praktikum/PraktDigi_V5_FPGA_PRNG.pdf
	port (
		clk	   : in	 std_logic;
		ce	   : in	 std_logic;
		bos	   : in	 std_logic;
		eos	   : in	 std_logic;
		freq   : in	 std_logic_vector (2 downto 0);
		random : out std_logic
		);
end randomtrigger;

architecture BEH of randomtrigger is


	type random31_arr is array (1 to 18) of std_logic_vector (1 to 31);

	signal random31 : random31_arr :=
		(
			b"010"& x"bcdef01",
			b"010"& x"8472830",
			b"101"& x"cef8321",
			b"011"& x"948bc63",
			b"110"& x"037ef72",
			b"000"& x"67840bc",
			b"011"& x"73840ac",
			b"101"& x"b472839",
			b"110"& x"f930193",
			b"000"& x"0578493",
			b"011"& x"b4738c5",
			b"101"& x"83920bf",
			b"110"& x"8394038",
			b"000"& x"0cd3839",
			b"011"& x"383920c",
			b"101"& x"94028bc",
			b"110"& x"9cdef78",
			b"000"& x"cf47389"
			);

	signal int_deadtime : integer range 0 to 40000		 := 0;
	signal trg_state	: std_logic_vector (2 downto 0)	 := "000";
	signal N			: integer range 0 to 31;  --nur 12 bis 18 macht hier sinn
	signal sig_random	: std_logic						 := '0';
	signal trg			: std_logic_vector (31 downto 0) := x"00000000";  --nur 18 downto 12 macht hier sinn

	attribute equivalent_register_removal			  : string;
	attribute equivalent_register_removal of random31 : signal is "no";
	attribute equivalent_register_removal of trg	  : signal is "no";
	attribute keep									  : string;
	attribute keep of random31						  : signal is "true";
	attribute keep of trg							  : signal is "true";
	

begin

	
	random <= sig_random;


	proc_deadtime : process
	begin
		wait until rising_edge(clk);
		if ce = '1' then
			sig_random <= '0';
			case trg_state is
				when "000" =>
					if bos = '1' then trg_state <= "001";
					end if;
					N							<= 19 - to_integer(unsigned(freq));
					
				when "001" =>
					if int_deadtime = 40000 then
						int_deadtime <= 0;	--1ms deadtime
						trg_state	 <= "010";
					else int_deadtime <= int_deadtime + 1;
					end if;
					
				when "010" =>
					if eos = '1' then
						trg_state <= "101";
					else
						if trg(N) = '1' then
							trg_state <= "011";
						end if;
					end if;
					
				when "011" =>
					if eos = '1' then
						trg_state <= "101";
					else
						sig_random <= '1';
						trg_state  <= "100";
					end if;

				when "100" =>
					if eos = '1' then
						trg_state <= "101";
					elsif int_deadtime = 50 then
						int_deadtime <= 0;
						trg_state	 <= "010";
					else int_deadtime <= int_deadtime + 1;
					end if;
					
				when "101" =>
					int_deadtime <= 0; trg_state <= "110";
					
				when others =>
					trg_state <= "000";

			end case;
		end if;
	end process;


	process
	begin
		wait until rising_edge(clk);
		if ce = '1' then
			for i in 1 to 18 loop
				random31(i) <= (random31(i)(31)xor random31(i)(28))& random31(i)(1 to 30);
			end loop;
		end if;
	end process;




	trg(18) <= '1' when
			   (random31(1)(1) = '1' and random31(2)(1) = '1' and random31(3)(1) = '1' and random31(4)(1) = '1'
				and random31(5)(1) = '1' and random31(6)(1) = '1' and random31(7)(1) = '1'
				and random31(8)(1) = '1' and random31(9)(1) = '1' and random31(10)(1) = '1'
				and random31(11)(1) = '1' and random31(12)(1) = '1' and random31(13)(1) = '1'
				and random31(14)(1) = '1' and random31(15)(1) = '1' and random31(16)(1) = '1'
				and random31(17)(1) = '1' and random31(18)(1) = '1')					
			   else '0';

	trg(17) <= '1' when
			   (random31(1)(1) = '1' and random31(2)(1) = '1' and random31(3)(1) = '1' and random31(4)(1) = '1'
				and random31(5)(1) = '1' and random31(6)(1) = '1' and random31(7)(1) = '1'
				and random31(8)(1) = '1' and random31(9)(1) = '1' and random31(10)(1) = '1'
				and random31(11)(1) = '1' and random31(12)(1) = '1' and random31(13)(1) = '1'
				and random31(14)(1) = '1' and random31(15)(1) = '1' and random31(16)(1) = '1'
				and random31(17)(1) = '1')					  
			   else '0';


	trg(16) <= '1' when
			   (random31(1)(1) = '1' and random31(2)(1) = '1' and random31(3)(1) = '1' and random31(4)(1) = '1'
				and random31(5)(1) = '1' and random31(6)(1) = '1' and random31(7)(1) = '1'
				and random31(8)(1) = '1' and random31(9)(1) = '1' and random31(10)(1) = '1'
				and random31(11)(1) = '1' and random31(12)(1) = '1' and random31(13)(1) = '1'
				and random31(14)(1) = '1' and random31(15)(1) = '1' and random31(16)(1) = '1')					  
			   else '0';


	trg(15) <= '1' when
			   (random31(1)(1) = '1' and random31(2)(1) = '1' and random31(3)(1) = '1' and random31(4)(1) = '1'
				and random31(5)(1) = '1' and random31(6)(1) = '1' and random31(7)(1) = '1'
				and random31(8)(1) = '1' and random31(9)(1) = '1' and random31(10)(1) = '1'
				and random31(11)(1) = '1' and random31(12)(1) = '1' and random31(13)(1) = '1'
				and random31(14)(1) = '1' and random31(15)(1) = '1')					
			   else '0';


	trg(14) <= '1' when
			   (random31(1)(1) = '1' and random31(2)(1) = '1' and random31(3)(1) = '1' and random31(4)(1) = '1'
				and random31(5)(1) = '1' and random31(6)(1) = '1' and random31(7)(1) = '1'
				and random31(8)(1) = '1' and random31(9)(1) = '1' and random31(10)(1) = '1'
				and random31(11)(1) = '1' and random31(12)(1) = '1' and random31(13)(1) = '1'
				and random31(14)(1) = '1')					  
			   else '0';

	trg(13) <= '1' when
			   (random31(1)(1) = '1' and random31(2)(1) = '1' and random31(3)(1) = '1' and random31(4)(1) = '1'
				and random31(5)(1) = '1' and random31(6)(1) = '1' and random31(7)(1) = '1'
				and random31(8)(1) = '1' and random31(9)(1) = '1' and random31(10)(1) = '1'
				and random31(11)(1) = '1' and random31(12)(1) = '1' and random31(13)(1) = '1')					  
			   else '0';

	trg(12) <= '1' when
			   (random31(1)(1) = '1' and random31(2)(1) = '1' and random31(3)(1) = '1' and random31(4)(1) = '1'
				and random31(5)(1) = '1' and random31(6)(1) = '1' and random31(7)(1) = '1'
				and random31(8)(1) = '1' and random31(9)(1) = '1' and random31(10)(1) = '1'
				and random31(11)(1) = '1' and random31(12)(1) = '1')					
			   else '0';
	
end BEH;
