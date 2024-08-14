library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity subwindow is
	port(
		reset: in std_logic; -- reset asserted logic '1' -- this resets the accumulator
		clk: in std_logic; -- latch strong accumulator
		en_strongAccum: in std_logic; -- enable strong accumulator latch
		en_var_norm: in std_logic;
		left_tree: in std_logic_vector(13 downto 0); -- 14 bit signed
		right_tree: in std_logic_vector(13 downto 0); -- 14 bit signed
		weak_thresh: in std_logic_vector(12 downto 0); -- 13 bit signed
		strong_thresh: in std_logic_vector(11 downto 0); -- 12 bit signed
		w0: in std_logic_vector(14 downto 0); -- signed
		w1: in std_logic_vector(14 downto 0); -- signed
		w2: in std_logic_vector(14 downto 0); -- signed
		ii_reg_we: in std_logic;
		ii_reg_address: in std_logic_vector(3 downto 0);
		ii_data: in std_logic_vector(19 downto 0);
		iix2_reg_we: in std_logic;
		iix2_reg_index: in std_logic_vector(1 downto 0);
		iix2_data: in std_logic_vector(27 downto 0);
		detection: out std_logic -- assert '1' for detection
	);
end subwindow;

architecture behavior of subwindow is

component register_file
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
		q3: out std_logic_vector((DATA_WIDTH-1) downto 0);
		q4: out std_logic_vector((DATA_WIDTH-1) downto 0);
		q5: out std_logic_vector((DATA_WIDTH-1) downto 0);
		q6: out std_logic_vector((DATA_WIDTH-1) downto 0);
		q7: out std_logic_vector((DATA_WIDTH-1) downto 0);
		q8: out std_logic_vector((DATA_WIDTH-1) downto 0);
		q9: out std_logic_vector((DATA_WIDTH-1) downto 0);
		q10: out std_logic_vector((DATA_WIDTH-1) downto 0);
		q11: out std_logic_vector((DATA_WIDTH-1) downto 0)
	);
  end component;

component register_file2
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
  end component;

component feature_calc
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
end component;

component var_norm_calc
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
end component;

-- Register signals
  
signal r0: std_logic_vector(19 downto 0); -- unsigned
signal r1: std_logic_vector(19 downto 0); -- unsigned
signal r2: std_logic_vector(19 downto 0); -- unsigned
signal r3: std_logic_vector(19 downto 0); -- unsigned
signal r4: std_logic_vector(19 downto 0); -- unsigned
signal r5: std_logic_vector(19 downto 0); -- unsigned
signal r6: std_logic_vector(19 downto 0); -- unsigned
signal r7: std_logic_vector(19 downto 0); -- unsigned
signal r8: std_logic_vector(19 downto 0); -- unsigned
signal r9: std_logic_vector(19 downto 0); -- unsigned
signal r10: std_logic_vector(19 downto 0); -- unsigned
signal r11: std_logic_vector(19 downto 0); -- unsigned

signal p0: std_logic_vector(19 downto 0); -- unsigned
signal p1: std_logic_vector(19 downto 0); -- unsigned
signal p2: std_logic_vector(19 downto 0); -- unsigned
signal p3: std_logic_vector(19 downto 0); -- unsigned
signal ssp0: std_logic_vector(27 downto 0); --unsigned
signal ssp1: std_logic_vector(27 downto 0); --unsigned
signal ssp2: std_logic_vector(27 downto 0); --unsigned
signal ssp3: std_logic_vector(27 downto 0); --unsigned

signal result_feature: std_logic_vector(38 downto 0); -- signed
signal var_norm_factor: std_logic_vector(21 downto 0); -- signed??
signal var_norm_factor_reg: std_logic_vector(21 downto 0) := (others=>'0');
signal var_norm_weak_thresh: std_logic_vector(34 downto 0); --signed
signal tree_mux_sel: std_logic;
signal tree_mux_result: std_logic_vector(13 downto 0); -- signed
signal strong_accumulator_result: std_logic_vector(21 downto 0); -- signed
signal stage_detection: std_logic;

signal result_mult0: std_logic_vector(26 downto 0); -- 27 bit signed
signal result_mult1: std_logic_vector(15 downto 0); -- 16 bit signed

begin

---- Integral Image Registers ----
   -- address 12 regs ... 4bit unsigned address width
   -- (original imlementation) 320x240 ii value is 19,584,000(dec) max ... 25bit unsigned data
   -- (other imlementation) 160x120 ii value is 4,896,000(dec) max ... 23bit unsigned data
	-- (current imlementation) 39x59 ii value in 8192 word address space ... 20bit unsigned data
ii_reg: register_file
  generic map (ADDR_WIDTH => 4, DATA_WIDTH => 20)
  port map(clk => clk,
    write_en => ii_reg_we,
    write_reg_addr => ii_reg_address,
    write_data => ii_data,
    q0 => r0,
    q1 => r1,
    q2 => r2,
    q3 => r3,
    q4 => r4,
    q5 => r5,
    q6 => r6,
    q7 => r7,
    q8 => r8,
    q9 => r9,
    q10 => r10,
    q11 => r11);
	 
  ---- Integral Image Registers for Varience Normalization ----
   -- share the same write enable and address since they load 
   --	data at the same time and from the same address
  ii_corner_reg: register_file2
  generic map (ADDR_WIDTH => 2, DATA_WIDTH => 20)
  port map(clk => clk,
    write_en => iix2_reg_we,
    write_reg_addr => iix2_reg_index,
    write_data => ii_data,
    q0 => p0,
    q1 => p1,
    q2 => p2,
    q3 => p3);
			
  iix2_corner_reg: register_file2
  generic map (ADDR_WIDTH => 2, DATA_WIDTH => 28)
  port map(clk => clk,
    write_en => iix2_reg_we,
    write_reg_addr => iix2_reg_index,
    write_data => iix2_data,
    q0 => ssp0,
    q1 => ssp1,
    q2 => ssp2,
    q3 => ssp3);

---- feature calc ----
feature_calc0: feature_calc
	port map (w0=>w0, w1=>w1, w2=>w2,
				r0=>r0, r1=>r1, r2=>r2, r3=>r3,
				r4=>r4, r5=>r5, r6=>r6, r7=>r7,
				r8=>r8, r9=>r9, r10=>r10, r11=>r11,
				result_feature=>result_feature);
				
---- variance normalization calc ----
var_norm_calc0: var_norm_calc
	port map (clk=>clk, p0=>p0, p1=>p1, p2=>p2, p3=>p3,
				ssp0=>ssp0, ssp1=>ssp1, ssp2=>ssp2, ssp3=>ssp3,
				var_norm_factor=>var_norm_factor);
				
---- var norm register ----
var_norm_reg: process (clk, en_var_norm)
begin
	if rising_edge(clk) then
		if en_var_norm = '1' then
			var_norm_factor_reg <= var_norm_factor;
		end if;
	end if;
end process;

var_norm_weak_thresh <= std_logic_vector(signed(weak_thresh)*signed(var_norm_factor_reg));
				
---- weak threshold comparator----
weak_thresh_compare0: process (result_feature, var_norm_weak_thresh)
begin
  if signed(result_feature) > signed(var_norm_weak_thresh) then
    tree_mux_sel <= '1';
  else
    tree_mux_sel <= '0';
  end if;
end process;

---- mux left and right weak tree values ----				
left_right_tree_mux0: process(left_tree, right_tree, tree_mux_sel)
begin
	if tree_mux_sel='1' then
		tree_mux_result <= right_tree;
	else
		tree_mux_result <= left_tree;
	end if;
end process;
				
---- strong accumulator ----
strong_accum0: process (clk, reset, strong_accumulator_result, en_strongAccum)
begin
	if (rising_edge(clk) and reset='1') then
		strong_accumulator_result <= (others=>'0');
	elsif (rising_edge(clk) and en_strongAccum='1') then
		strong_accumulator_result <= std_logic_vector(signed(tree_mux_result)+signed(strong_accumulator_result));
	end if;
end process;
				
---- strong threshold comparator ----
 -- vj_cpp calculates by:
 --
 --   if (stage_sum < 0.4*stage_thresh_array[i]) // changed to 6/7*stage_thresh_array[i]
 --   {return -i} //this breaks the classifier cascade

 -- our vhdl implementation avoids fraction multiplicaiton
 -- ... achieved by multiplying inputs by constant decimal values
 -- ... since 0.4=4/10 ... compare(strong_accumulator_result*10 > strong_thresh*4)
 -- ... compare result true = '1', else '0'
result_mult0 <= std_logic_vector(signed(strong_accumulator_result)*to_signed(6, 5));
result_mult1 <= std_logic_vector(signed(strong_thresh)*to_signed(7, 4));
				
process (result_mult0, result_mult1)
begin
  if signed(result_mult0) > signed(result_mult1) then
    stage_detection <= '1';
  else
    stage_detection <= '0';
  end if;
end process;

---- detection output ----
	detection <= stage_detection;

end behavior;
