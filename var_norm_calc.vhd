library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity var_norm_calc is
	port(
		clk: in std_logic;
		p0: in std_logic_vector(19 downto 0); -- unsigned
		p1: in std_logic_vector(19 downto 0); -- unsigned
		p2: in std_logic_vector(19 downto 0); -- unsigned
		p3: in std_logic_vector(19 downto 0); -- unsigned
		ssp0: in std_logic_vector(27 downto 0); -- unsigned
		ssp1: in std_logic_vector(27 downto 0); -- unsigned
		ssp2: in std_logic_vector(27 downto 0); -- unsigned
		ssp3: in std_logic_vector(27 downto 0); -- unsigned
		var_norm_factor: out std_logic_vector(21 downto 0) -- signed??
	);
end var_norm_calc;

architecture behavior of var_norm_calc is

signal result_add0: std_logic_vector(20 downto 0); -- MSbit is carry from add0
signal result_add1: std_logic_vector(20 downto 0); -- MSbit is carry from add1
signal result_sub0: std_logic_vector(20 downto 0);
signal result_mult0: std_logic_vector(41 downto 0);
signal result_mult0_extend: std_logic_vector(42 downto 0);

signal result_add2: std_logic_vector(28 downto 0); -- MSbit is carry from add0
signal result_add3: std_logic_vector(28 downto 0); -- MSbit is carry from add1
signal result_sub1: std_logic_vector(28 downto 0);

signal result_divide0: std_logic_vector(28 downto 0);
signal result_divide0_extend: std_logic_vector(42 downto 0);

signal result_sub2: std_logic_vector(43 downto 0); --MSB is ...
signal result_sub2_cout: std_logic; --

signal result_sqrt0: std_logic_vector(21 downto 0);

component altsqrt_varianceCalc
	PORT
	(
		clk		: IN STD_LOGIC ;
		radical		: IN STD_LOGIC_VECTOR (43 DOWNTO 0);
		q		: OUT STD_LOGIC_VECTOR (21 DOWNTO 0);
		remainder		: OUT STD_LOGIC_VECTOR (22 DOWNTO 0)
	);
END component;

begin

-------------- m -----------------------------

result_add0 <= std_logic_vector(unsigned('0' & p0)+unsigned('0' & p3));
	
result_add1 <= std_logic_vector(unsigned('0' & p1)+unsigned('0' & p2));
	
result_sub0 <= std_logic_vector(unsigned(result_add0)-unsigned(result_add1));
	
-------------- m^2 ---------------------------

result_mult0 <= std_logic_vector(unsigned(result_sub0)*unsigned(result_sub0));
	
result_mult0_extend(42) <= '0'; -- always positive
result_mult0_extend(41 downto 0) <= result_mult0;

-------------- sum(x^2) ----------------------

result_add2 <= std_logic_vector(unsigned('0' & ssp0)+unsigned('0' & ssp3));

result_add3 <= std_logic_vector(unsigned('0' & ssp1)+unsigned('0' & ssp2));
	
result_sub1 <= std_logic_vector(unsigned(result_add2)-unsigned(result_add3));

-------------- sum(x^2)/n --------------------

--instead of divide by 24*24=576, so divide by 512 by shift right logical ... IN>>9=OUT
  -- result_sub1 is 29bit unsigned
  -- result_divide0 is 29bit
  result_divide0(28 downto 20) <= (others=>'0');
  result_divide0(19 downto 0) <= result_sub1(28 downto 9);

-- extend result_divide0 -- always positive ... extended bits are all zero for signed vale
result_divide0_extend(42 downto 29) <= (others=>'0');
result_divide0_extend(28 downto 0) <= result_divide0;

-------------- m^2 - sum(x^2)/n --------------

result_sub2(42 downto 0) <= std_logic_vector(signed(result_mult0_extend)-signed(result_divide0_extend));--no cout implementation needed

-------------- sqrt(m^2 - sum(x^2)/n) --------

-- 44 bit unsigned sqrt, latancy of 11 clock cycles
sqrt0: altsqrt_varianceCalc
	port map
	(
		clk => clk,
		radical => result_sub2,
		q => result_sqrt0,
		remainder => open
	);

-------------- sqrt mux --------------

result_sub2(43) <= result_sub2(42); -- should always be positive ???

result_mux: process (result_sub2(43), result_sqrt0)
begin
	if ( result_sub2(43) = '0') then
		var_norm_factor <= result_sqrt0;
	else
		var_norm_factor <= std_logic_vector(to_unsigned(1, 22)); -- (integer value, bit width)
	end if;
end process;
	
end behavior;
