library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity weak_thresh_compare is
	port(
		result_feature: in std_logic_vector(41 downto 0); -- 42 bit signed
		var_norm_weak_thresh: in std_logic_vector(37 downto 0); -- 48 bit signed
		q: out std_logic -- assert '1' for strong_accumulator_result > strong_thresh
	);
end weak_thresh_compare;

architecture behavior of weak_thresh_compare is

component lpm_compare_sign42bit_a_ge_b
	PORT
	(
		dataa		: IN STD_LOGIC_VECTOR (41 DOWNTO 0);
		datab		: IN STD_LOGIC_VECTOR (41 DOWNTO 0);
		aeb		: OUT STD_LOGIC ;
		ageb		: OUT STD_LOGIC 
	);
END component;

signal var_norm_weak_thresh_extend: std_logic_vector(41 downto 0); -- 42 bit signed

begin

---- sign extend var_norm_weak_thresh ----
var_norm_weak_thresh_extend(37 downto 0) <= var_norm_weak_thresh;
var_norm_weak_thresh_extend(41 downto 38) <= (others=>var_norm_weak_thresh(37));

---- compare result_feature >= var_norm_weak_thresh_extend ----
compare0: lpm_compare_sign42bit_a_ge_b
	port map(dataa => result_feature,
				datab => var_norm_weak_thresh_extend,
				aeb => open,
				ageb => q);

end behavior;
