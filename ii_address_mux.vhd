library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ii_address_mux is
	port(
		sel: in std_logic_vector(1 downto 0); -- 2bit unsigned select
		a: in std_logic_vector(14 downto 0); -- 15bit unsigned
		b: in std_logic_vector(14 downto 0); -- 15bit unsigned
		c: in std_logic_vector(14 downto 0); -- 15bit unsigned
		d: in std_logic_vector(14 downto 0); -- 15bit unsigned
		q: out std_logic_vector(14 downto 0) -- 15bit unsigned
	);
end ii_address_mux;

architecture behavior of ii_address_mux is

begin

mux0: process(a, b, c, d, sel)
begin
	case sel is
		when "00" =>
			q <= a;
		when "01" =>
			q <= b;
		when "10" =>
			q <= c;
		when "11" =>
			q <= d;
		when others =>
			q <= (others=>'0');
		end case;

end process;

end behavior;
