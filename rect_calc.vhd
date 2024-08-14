library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity rect_calc is
	port(
		weight: in std_logic_vector(14 downto 0);--signed input
		a: in std_logic_vector(19 downto 0);--unsigned input
		b: in std_logic_vector(19 downto 0);--unsigned input
		c: in std_logic_vector(19 downto 0);--unsigned input
		d: in std_logic_vector(19 downto 0);--unsigned input
		--maximum signed multiplier output requires a bit width of (multiplier_bit_width+multplicand_bit_width)
		result: out std_logic_vector(36 downto 0)--signed result
	);
end rect_calc;

architecture behavior of rect_calc is

--rect0 calc
--weight*([r0+r3]-[r1+r2])

--rect adder0 ... a+d ... result is signed to facilitate signed multiplicaiton
--rect adder1 ... b+c ... result is signed to facilitate signed multiplicaiton
--rect adder2(subtractor) ... adder0_result-adder1_result ... always a positive number since (r0+r3)>(r1+r2) always ... result is signed to facilitate signed multiplicaiton
--rect multiplier (SLL) ... weight determines a scalar and a sign ... result is a signed

signal result_add0: std_logic_vector(20 downto 0); -- MSbit is carry from add0
signal result_add1: std_logic_vector(20 downto 0); -- MSbit is carry from add1
signal result_sub0: std_logic_vector(20 downto 0);
signal result_sub0_extend: std_logic_vector(21 downto 0);

begin

result_add0 <= std_logic_vector(unsigned('0' & a)+unsigned('0' & d));
	
result_add1 <= std_logic_vector(unsigned('0' & b)+unsigned('0' & c));

result_sub0 <= std_logic_vector(unsigned(result_add0)-unsigned(result_add1));

-- must extend the unsigned sub0 result to a signed result
result_sub0_extend(21) <= '0'; -- MSbit is always positive
result_sub0_extend(20 downto 0) <= result_sub0;

result <= std_logic_vector(signed(result_sub0_extend)*signed(weight));
	
end behavior;
