library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rect_mux is
	port(
		sel: in std_logic_vector(1 downto 0); -- 2bit unsigned select
		a: in std_logic_vector(4 downto 0); -- 5bit unsigned
		b: in std_logic_vector(4 downto 0); -- 5bit unsigned
		c: in std_logic_vector(4 downto 0); -- 5bit unsigned
		q: out std_logic_vector(4 downto 0) -- 5bit unsigned
	);
end rect_mux;

architecture behavior of rect_mux is

begin

mux0: process(a, b, c, sel)
begin
	case sel is
		when "00" =>
			q <= a;
		when "01" =>
			q <= b;
		when "10" =>
			q <= c;
		when others =>
			q <= (others=>'0');
		end case;

end process;

end behavior;
