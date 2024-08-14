library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity pixel_offset is
	port(
		mem_state: in std_logic;
		x_pos_subwin: in std_logic_vector(5 downto 0); -- 6bit unsigned ... range(0 to 38)
		y_pos_subwin: in std_logic_vector(5 downto 0); -- 6bit unsigned ... range(0 to 58)
		width_ii: in std_logic_vector(5 downto 0); -- 6bit unsigned ... range(0 to 38)
		p_offset: out std_logic_vector(12 downto 0) -- 13bit unsigned ... range(0 to (39*59-1)) or range(4096 to (39*59-1)+4096)
	);
end pixel_offset;

architecture behavior of pixel_offset is

  signal p_offset_s: std_logic_vector(12 downto 0); -- 13bit unsigned
  signal result_mult0: std_logic_vector(11 downto 0); -- 12bit unsigned

begin
	
  result_mult0 <= std_logic_vector(unsigned(y_pos_subwin)*unsigned(width_ii));
  
  p_offset_s(12) <= not mem_state; -- determines if lower or upper memory is selected ... if mem_state='1' then lower, otherwise upper 
  p_offset_s(11 downto 0) <= std_logic_vector(unsigned(result_mult0)+unsigned(x_pos_subwin));
  p_offset <= p_offset_s;
  
end behavior;
