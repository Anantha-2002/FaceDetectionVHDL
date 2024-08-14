library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity counter is
	generic (COUNT_WIDTH : integer := 4);
	port(
		clk: in std_logic;
		reset: in std_logic;
		en: in std_logic;
		count: out std_logic_vector(COUNT_WIDTH-1 downto 0)
	);
end counter;

architecture behavior of counter is


begin
	
count_proc: process (clk, reset, en)
 variable num: unsigned(COUNT_WIDTH-1 downto 0) := (others=>'0');
begin
	if (reset='1') then
		num := (others=>'0');
	elsif (rising_edge(clk) and (en='1')) then
		num := num + 1;
	end if;
	count <= std_logic_vector(num);
end process;
	
end behavior;
