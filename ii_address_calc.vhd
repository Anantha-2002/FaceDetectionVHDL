library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ii_address_calc is
	port(
		x_pos_point: in std_logic_vector(4 downto 0); -- 5bit unsigned ... range(0 to 23)
		y_pos_point: in std_logic_vector(4 downto 0); -- 5bit unsigned ... range(0 to 23)
		width_ii: in std_logic_vector(5 downto 0); -- 6bit unsigned ... range(0 to 38)
		p_offset: in std_logic_vector(12 downto 0); -- 13bit unsigned ... range(0 to (39*59-1)) or range(4096 to (39*58-1)+4096)
		ii_address: out std_logic_vector(12 downto 0) -- 13bit unsigned ... range(0 to (39*59-1)) or range(4096 to (39*58-1)+4096)
	);
end ii_address_calc;

architecture behavior of ii_address_calc is

signal result_mult0: std_logic_vector(10 downto 0); -- 11 bit unsigned
signal reuslt_add0: std_logic_vector(12 downto 0); -- 13bit unsigned

begin
	
result_mult0 <= std_logic_vector(unsigned(y_pos_point)*unsigned(width_ii)); -- 5bit*6bit=11bit

reuslt_add0 <= std_logic_vector(unsigned(x_pos_point)+unsigned(p_offset)); -- 5bit+13bit=13bit ... 24max+(39*58-1)+4096=6,382 max = 13bit uns

ii_address <= std_logic_vector(unsigned(reuslt_add0)+unsigned(result_mult0)); -- 13bit+11bit=13bit

end behavior;
