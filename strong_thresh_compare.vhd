library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity strong_thresh_compare is
	port(
		strong_accumulator_result: in std_logic_vector(21 downto 0); -- 22 bit signed
		strong_thresh: in std_logic_vector(11 downto 0); -- 12 bit signed
		q: out std_logic -- assert '1' for strong_accumulator_result > strong_thresh
	);
end strong_thresh_compare;

architecture behavior of strong_thresh_compare is

-- vj_cpp calculates by:
-- if (stage_sum < 0.4*stage_thresh_array[i])
-- {return -i} //this breaks the classifier cascade

-- our vhdl implementation will avoid fraction multiplicaiton
-- ... achieved by multiplying inputs by constant decimal values
-- ... since 0.4=4/10 ... compare(strong_accumulator_result*10 > strong_thresh*4)
-- ... compare result true = '1', else '0'

signal result_mult0: std_logic_vector(26 downto 0); -- 27 bit signed
signal result_mult1: std_logic_vector(15 downto 0); -- 16 bit signed

begin

result_mult0 <= std_logic_vector(signed(strong_accumulator_result)*to_signed(6, 5));
result_mult1 <= std_logic_vector(signed(strong_thresh)*to_signed(7, 4));
				
process (result_mult0, result_mult1)
begin
  if signed(result_mult0) > signed(result_mult1) then
    q <= '1';
  else
    q <= '0';
  end if;
end process;

end behavior;
