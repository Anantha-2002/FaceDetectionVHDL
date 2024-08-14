library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity iix2_address_decoder is
	port(
		iix2_reg_index: in std_logic_vector(1 downto 0); -- 2bit unsigned ... range 0 to 3
		width_ii: in std_logic_vector (5 downto 0); -- 8bit unsigned ... range(0 to 38)
		p_offset: in std_logic_vector(12 downto 0); -- 13bit unsigned ... range(0 to (39*59-1)) or range(4096 to (39*58-1)+4096) -- base address of the subwindow (top left corner)
		iix2_address: out std_logic_vector(12 downto 0) -- 13bit unsigned ... range(0 to (39*59-1)) or range(4096 to (39*58-1)+4096)
	);
end iix2_address_decoder;

architecture behavior of iix2_address_decoder is

signal result_mult0: std_logic_vector(10 downto 0); -- 11 bit unsigned
--signal result_mult0_extend: std_logic_vector(12 downto 0); -- 13 bit unsigned

signal iix2_address0: std_logic_vector(12 downto 0); -- 13 bit unsigned
signal iix2_address1: std_logic_vector(12 downto 0);
signal iix2_address2: std_logic_vector(12 downto 0);
signal iix2_address3: std_logic_vector(12 downto 0);

begin

result_mult0 <= std_logic_vector(to_unsigned(23,5)*unsigned(width_ii));

--result_mult0_extend(10 downto 0) <= result_mult0;
--result_mult0_extend(12 downto 11) <= (others=>'0');

------------ ii_address0 --------------
-- top left corner
-- address=p_offset

iix2_address0 <= p_offset;

------------ ii_address1 --------------
-- top right corner
-- address=p_offset+23 -- subwindow is 24 pixels wide

iix2_address1 <= std_logic_vector(unsigned(p_offset)+to_unsigned(23,13));

------------ ii_address2 --------------
-- bottom left corner
-- address=p_offset+width_ii*23 -- subwindow is 24 pixels tall

iix2_address2 <= std_logic_vector(unsigned(p_offset)+unsigned(result_mult0));

------------ ii_address3 --------------
-- bottom right corner
-- address=p_offset+width_ii*23+23 -- subwindow is 24 pixels tall and 24 pixels wide

iix2_address3 <= std_logic_vector(unsigned(iix2_address2)+to_unsigned(23,13));

	
------------ mux output --------------

mux_output: process (iix2_reg_index, iix2_address0, iix2_address1, iix2_address2, iix2_address3)
begin
	case iix2_reg_index is
		when "00" =>
			iix2_address <= iix2_address0;
		when "01" =>
			iix2_address <= iix2_address1;
		when "10" =>
			iix2_address <= iix2_address2;
		when "11" =>
			iix2_address <= iix2_address3;
		when others =>
			iix2_address <= iix2_address0;
	end case;
end process;

end behavior;
