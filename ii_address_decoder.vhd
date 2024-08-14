library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ii_address_decoder is
	port(
		ii_reg_index: in std_logic_vector(3 downto 0); -- 4bit unsigned ... range 0 to 11
		width_ii: in std_logic_vector (5 downto 0); -- 6bit unsigned ... range(0 to 39)
		p_offset: in std_logic_vector(12 downto 0); -- 13bit unsigned ... range(0 to (39*58-1)) or range(4096 to (39*58-1)+4096)
		x_rect0: in std_logic_vector(4 downto 0); -- 5bit unsigned ... range(0 to 23)
		x_rect1: in std_logic_vector(4 downto 0); -- 5bit unsigned ... range(0 to 23)
		x_rect2: in std_logic_vector(4 downto 0); -- 5bit unsigned ... range(0 to 23)
		y_rect0: in std_logic_vector(4 downto 0); -- 5bit unsigned ... range(0 to 23)
		y_rect1: in std_logic_vector(4 downto 0); -- 5bit unsigned ... range(0 to 23)
		y_rect2: in std_logic_vector(4 downto 0); -- 5bit unsigned ... range(0 to 23)
		w_rect0: in std_logic_vector(4 downto 0); -- 5bit unsigned ... range(0 to 24)
		w_rect1: in std_logic_vector(4 downto 0); -- 5bit unsigned ... range(0 to 24)
		w_rect2: in std_logic_vector(4 downto 0); -- 5bit unsigned ... range(0 to 24)
		h_rect0: in std_logic_vector(4 downto 0); -- 5bit unsigned ... range(0 to 24)
		h_rect1: in std_logic_vector(4 downto 0); -- 5bit unsigned ... range(0 to 24)
		h_rect2: in std_logic_vector(4 downto 0); -- 5bit unsigned ... range(0 to 24)
		ii_address: out std_logic_vector(12 downto 0) -- 13bit unsigned ... range(0 to (39*58-1)) or range(4096 to (39*59-1)+4096)
	);
end ii_address_decoder;

architecture behavior of ii_address_decoder is

component ii_address_calc
	port(
		x_pos_point: in std_logic_vector(4 downto 0); -- 5bit unsigned ... range(0 to 23)
		y_pos_point: in std_logic_vector(4 downto 0); -- 5bit unsigned ... range(0 to 23)
		width_ii: in std_logic_vector(5 downto 0); -- 6bit unsigned ... range(0 to 38)
		p_offset: in std_logic_vector(12 downto 0); -- 13bit unsigned ... range(0 to (39*59-1)) or range(4096 to (39*58-1)+4096)
		ii_address: out std_logic_vector(12 downto 0) -- 13bit unsigned ... range(0 to (39*59-1)) or range(4096 to (39*58-1)+4096)
	);
end component;

signal x_rect0_plus_w_rect0: std_logic_vector(4 downto 0);
signal x_rect1_plus_w_rect1: std_logic_vector(4 downto 0);
signal x_rect2_plus_w_rect2: std_logic_vector(4 downto 0);

signal y_rect0_plus_h_rect0: std_logic_vector(4 downto 0);
signal y_rect1_plus_h_rect1: std_logic_vector(4 downto 0);
signal y_rect2_plus_h_rect2: std_logic_vector(4 downto 0);

signal ii_address0: std_logic_vector(12 downto 0);
signal ii_address1: std_logic_vector(12 downto 0);
signal ii_address2: std_logic_vector(12 downto 0);
signal ii_address3: std_logic_vector(12 downto 0);
signal ii_address4: std_logic_vector(12 downto 0);
signal ii_address5: std_logic_vector(12 downto 0);
signal ii_address6: std_logic_vector(12 downto 0);
signal ii_address7: std_logic_vector(12 downto 0);
signal ii_address8: std_logic_vector(12 downto 0);
signal ii_address9: std_logic_vector(12 downto 0);
signal ii_address10: std_logic_vector(12 downto 0);
signal ii_address11: std_logic_vector(12 downto 0);

begin

------------ x_rect + w_rect ----------

x_rect0_plus_w_rect0 <= std_logic_vector(unsigned(x_rect0)+unsigned(w_rect0));
x_rect1_plus_w_rect1 <= std_logic_vector(unsigned(x_rect1)+unsigned(w_rect1));
x_rect2_plus_w_rect2 <= std_logic_vector(unsigned(x_rect2)+unsigned(w_rect2));

------------ y_rect + h_rect ----------

y_rect0_plus_h_rect0 <= std_logic_vector(unsigned(y_rect0)+unsigned(h_rect0));
y_rect1_plus_h_rect1 <= std_logic_vector(unsigned(y_rect1)+unsigned(h_rect1));
y_rect2_plus_h_rect2 <= std_logic_vector(unsigned(y_rect2)+unsigned(h_rect2));

------------ ii_address_calcs  rect0 --------------

ii_addr0: ii_address_calc
	port map
	(
		x_pos_point => x_rect0,
		y_pos_point => y_rect0,
		width_ii => width_ii,
		p_offset => p_offset,
		ii_address => ii_address0
	);

ii_addr1: ii_address_calc
	port map
	(
		x_pos_point => x_rect0_plus_w_rect0,
		y_pos_point => y_rect0,
		width_ii => width_ii,
		p_offset => p_offset,
		ii_address => ii_address1
	);

ii_addr2: ii_address_calc
	port map
	(
		x_pos_point => x_rect0,
		y_pos_point => y_rect0_plus_h_rect0,
		width_ii => width_ii,
		p_offset => p_offset,
		ii_address => ii_address2
	);

ii_addr3: ii_address_calc
	port map
	(
		x_pos_point => x_rect0_plus_w_rect0,
		y_pos_point => y_rect0_plus_h_rect0,
		width_ii => width_ii,
		p_offset => p_offset,
		ii_address => ii_address3
	);

------------ ii_address_calcs  rect1 --------------

ii_addr4: ii_address_calc
	port map
	(
		x_pos_point => x_rect1,
		y_pos_point => y_rect1,
		width_ii => width_ii,
		p_offset => p_offset,
		ii_address => ii_address4
	);

ii_addr5: ii_address_calc
	port map
	(
		x_pos_point => x_rect1_plus_w_rect1,
		y_pos_point => y_rect1,
		width_ii => width_ii,
		p_offset => p_offset,
		ii_address => ii_address5
	);

ii_addr6: ii_address_calc
	port map
	(
		x_pos_point => x_rect1,
		y_pos_point => y_rect1_plus_h_rect1,
		width_ii => width_ii,
		p_offset => p_offset,
		ii_address => ii_address6
	);

ii_addr7: ii_address_calc
	port map
	(
		x_pos_point => x_rect1_plus_w_rect1,
		y_pos_point => y_rect1_plus_h_rect1,
		width_ii => width_ii,
		p_offset => p_offset,
		ii_address => ii_address7
	);

------------ ii_address_calcs  rect2 --------------

ii_addr8: ii_address_calc
	port map
	(
		x_pos_point => x_rect2,
		y_pos_point => y_rect2,
		width_ii => width_ii,
		p_offset => p_offset,
		ii_address => ii_address8
	);

ii_addr9: ii_address_calc
	port map
	(
		x_pos_point => x_rect2_plus_w_rect2,
		y_pos_point => y_rect2,
		width_ii => width_ii,
		p_offset => p_offset,
		ii_address => ii_address9
	);

ii_addr10: ii_address_calc
	port map
	(
		x_pos_point => x_rect2,
		y_pos_point => y_rect2_plus_h_rect2,
		width_ii => width_ii,
		p_offset => p_offset,
		ii_address => ii_address10
	);

ii_addr11: ii_address_calc
	port map
	(
		x_pos_point => x_rect2_plus_w_rect2,
		y_pos_point => y_rect2_plus_h_rect2,
		width_ii => width_ii,
		p_offset => p_offset,
		ii_address => ii_address11
	);
	
------------ mux control --------------

mux_control: process (ii_reg_index, ii_address0, ii_address1, ii_address2, ii_address3,
												ii_address4, ii_address5, ii_address6, ii_address7,
												ii_address8, ii_address9, ii_address10, ii_address11)
begin
	case ii_reg_index is
		when X"0" =>
			ii_address <= ii_address0;
		when X"1" =>
			ii_address <= ii_address1;
		when X"2" =>
			ii_address <= ii_address2;
		when X"3" =>
			ii_address <= ii_address3;
		when X"4" =>
			ii_address <= ii_address4;
		when X"5" =>
			ii_address <= ii_address5;
		when X"6" =>
			ii_address <= ii_address6;
		when X"7" =>
			ii_address <= ii_address7;
		when X"8" =>
			ii_address <= ii_address8;
		when X"9" =>
			ii_address <= ii_address9;
		when X"A" =>
			ii_address <= ii_address10;
		when X"B" =>
			ii_address <= ii_address11;
		when others =>
			ii_address <= ii_address0;--default, won't be selected
	end case;
end process;

end behavior;
