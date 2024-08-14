library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity strong_accumulator is
	port(
		reset: in std_logic; -- async reset
		en: in std_logic;
		clk: in std_logic; -- 
		din: in std_logic_vector(13 downto 0); -- 14bit signed
		dout: out std_logic_vector(21 downto 0) -- 22bit signed
	);
end strong_accumulator;

architecture behavior of strong_accumulator is

signal din_extend: std_logic_vector(21 downto 0); -- 22bit signed
signal dout_reg: std_logic_vector(21 downto 0):= (others=>'0'); -- 22bit signed
signal result_adder0: std_logic_vector(21 downto 0); -- 22bit signed

begin

------------ sign extener -------------
--extend: process (din(13)) -- sign extend based on MSbit of din .. din(13)
--begin
--	if (din(13)='1') then
--		din_extend(21 downto 14) <= (others=>'1');
--	else
--		din_extend(21 downto 14) <= (others=>'0');
--	end if;
--end process;
--din_extend(13 downto 0) <= din;

---------- signed 22bit adder -------

result_adder0 <= std_logic_vector(signed(din)+signed(dout_reg));

---------- register accumulator -----

accum: process (clk, reset, result_adder0, en)
begin
	if (rising_edge(clk) and reset='1') then
		dout_reg <= (others=>'0');
	elsif (rising_edge(clk) and en='1') then
		dout_reg <= result_adder0;
	end if;
end process;

dout <= dout_reg;

end behavior;
