library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity register_file2 is
	generic (
	ADDR_WIDTH	: integer := 4;
	DATA_WIDTH	: integer := 18
	);
	port(
	clk: in std_logic;
	write_en: in std_logic;
	write_reg_addr: in std_logic_vector((ADDR_WIDTH-1) downto 0);
	write_data: in std_logic_vector((DATA_WIDTH-1) downto 0);
	q0: out std_logic_vector((DATA_WIDTH-1) downto 0);
	q1: out std_logic_vector((DATA_WIDTH-1) downto 0);
	q2: out std_logic_vector((DATA_WIDTH-1) downto 0);
	q3: out std_logic_vector((DATA_WIDTH-1) downto 0)
	);
end register_file2;

architecture behavior of register_file2 is
type registerType is array(0 to (2**ADDR_WIDTH-1)) of std_logic_vector((DATA_WIDTH-1) downto 0);

signal reg : registerType:=(others=>(others=>'0'));
begin

	regFile: process(clk)
	begin
		if rising_edge(clk) then
			if write_en = '1' then
				reg(to_integer(unsigned(write_reg_addr))) <= write_data;
			end if;
		end if;
	end process;
	q0 <= reg(0);
	q1 <= reg(1);
	q2 <= reg(2);
	q3 <= reg(3);
	
end behavior;
