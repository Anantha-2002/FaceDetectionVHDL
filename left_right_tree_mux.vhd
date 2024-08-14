library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity left_right_tree_mux is
	port(
		sel: in std_logic; -- 1bit unsigned select
		left_val: in std_logic_vector(13 downto 0); -- 14bit signed
		right_val: in std_logic_vector(13 downto 0); -- 14bit signed
		q: out std_logic_vector(13 downto 0) -- 14bit signed
	);
end left_right_tree_mux;

architecture behavior of left_right_tree_mux is

begin

mux0: process(left_val, right_val, sel)
begin
	if (sel='1') then
		q <= right_val;
	else
		q <= left_val;
	end if;
end process;

end behavior;
