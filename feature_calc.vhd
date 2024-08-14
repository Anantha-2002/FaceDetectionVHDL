library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity feature_calc is
	port(
		w0: in std_logic_vector(14 downto 0); -- signed
		w1: in std_logic_vector(14 downto 0); -- signed
		w2: in std_logic_vector(14 downto 0); -- signed
		r0: in std_logic_vector(19 downto 0); -- unsigned
		r1: in std_logic_vector(19 downto 0); -- unsigned
		r2: in std_logic_vector(19 downto 0); -- unsigned
		r3: in std_logic_vector(19 downto 0); -- unsigned
		r4: in std_logic_vector(19 downto 0); -- unsigned
		r5: in std_logic_vector(19 downto 0); -- unsigned
		r6: in std_logic_vector(19 downto 0); -- unsigned
		r7: in std_logic_vector(19 downto 0); -- unsigned
		r8: in std_logic_vector(19 downto 0); -- unsigned
		r9: in std_logic_vector(19 downto 0); -- unsigned
		r10: in std_logic_vector(19 downto 0); -- unsigned
		r11: in std_logic_vector(19 downto 0); -- unsigned
		result_feature: out std_logic_vector(38 downto 0) -- signed
	);
end feature_calc;

architecture behavior of feature_calc is

--rect0 calc
--w0*([r0+r3]-[r1+r2])=result_rect0 ... bit width = WEIGHT_WIDTH+RECT_II_DATA_WIDTH
--rect1 calc
--w1*([r4+r7]-[r5+r6])=result_rect1 ... bit width = WEIGHT_WIDTH+RECT_II_DATA_WIDTH
--rect2 calc
--w2*([r8+r11]-[r9+r10])=result_rect2 ... bit width = WEIGHT_WIDTH+RECT_II_DATA_WIDTH

--result_temp=result_rect0+result_rect1 ... signed + signed ... both could be positive or negative ... WEIGHT_WIDTH+RECT_II_DATA_WIDTH+1
--result_feature=result_temp+result_rect2 ... signed + signed ... both could be positive or negative ... WEIGHT_WIDTH+RECT_II_DATA_WIDTH+2

signal result_rect0: std_logic_vector(36 downto 0);
signal result_rect1: std_logic_vector(36 downto 0);
signal result_rect2: std_logic_vector(36 downto 0);
signal result_rect2_extend: std_logic_vector((36+1) downto 0);
signal result_temp: std_logic_vector((36+1) downto 0);

signal c_out0: std_logic;
signal c_out1: std_logic;

component rect_calc
	port(
		weight: in std_logic_vector(14 downto 0);--signed input
		a: in std_logic_vector(19 downto 0);--unsigned input
		b: in std_logic_vector(19 downto 0);--unsigned input
		c: in std_logic_vector(19 downto 0);--unsigned input
		d: in std_logic_vector(19 downto 0);--unsigned input
		--maximum signed multiplier output requires a bit width of (multiplier_bit_width+multplicand_bit_width)
		result: out std_logic_vector(36 downto 0)--signed result
	);
end component;

begin

rect0: rect_calc port map (weight=>w0, a=>r0, b=>r1, c=>r2, d=>r3, result=>result_rect0);

rect1: rect_calc port map (weight=>w1, a=>r4, b=>r5, c=>r6, d=>r7, result=>result_rect1);

rect2: rect_calc port map (weight=>w2, a=>r8, b=>r9, c=>r10, d=>r11, result=>result_rect2);

result_temp <= std_logic_vector(signed(result_rect0(36) & result_rect0)+signed(result_rect1(36) & result_rect1));
	
--must sign extent result_rect2 to match result_temp bit width
result_rect2_extend(37)<=result_rect2(36);
result_rect2_extend(36 downto 0)<=result_rect2;

result_feature <= std_logic_vector(signed(result_rect2_extend(37) & result_rect2_extend)+signed(result_temp(37) & result_temp));

end behavior;
