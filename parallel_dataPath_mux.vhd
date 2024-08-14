library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- special mux/shifter for parallel data path control ... assumes that there are 16 downstream subwindow detectors

entity parallel_dataPath_mux is
  generic(DATA_WIDTH_OUT : integer:= 23);
  port(
    sel: in std_logic_vector(3 downto 0);
    a: in std_logic_vector((16*DATA_WIDTH_OUT)-1 downto 0);
	 b: in std_logic_vector((16*DATA_WIDTH_OUT)-1 downto 0);
	 q0: out std_logic_vector(DATA_WIDTH_OUT-1 downto 0);
	 q1: out std_logic_vector(DATA_WIDTH_OUT-1 downto 0);
	 q2: out std_logic_vector(DATA_WIDTH_OUT-1 downto 0);
	 q3: out std_logic_vector(DATA_WIDTH_OUT-1 downto 0);
	 q4: out std_logic_vector(DATA_WIDTH_OUT-1 downto 0);
	 q5: out std_logic_vector(DATA_WIDTH_OUT-1 downto 0);
	 q6: out std_logic_vector(DATA_WIDTH_OUT-1 downto 0);
	 q7: out std_logic_vector(DATA_WIDTH_OUT-1 downto 0);
	 q8: out std_logic_vector(DATA_WIDTH_OUT-1 downto 0);
	 q9: out std_logic_vector(DATA_WIDTH_OUT-1 downto 0);
	 q10: out std_logic_vector(DATA_WIDTH_OUT-1 downto 0);
	 q11: out std_logic_vector(DATA_WIDTH_OUT-1 downto 0);
	 q12: out std_logic_vector(DATA_WIDTH_OUT-1 downto 0);
	 q13: out std_logic_vector(DATA_WIDTH_OUT-1 downto 0);
	 q14: out std_logic_vector(DATA_WIDTH_OUT-1 downto 0);
	 q15: out std_logic_vector(DATA_WIDTH_OUT-1 downto 0)
  );
end parallel_dataPath_mux;

architecture behavior of parallel_dataPath_mux is
  
  signal path : std_logic_vector((16*DATA_WIDTH_OUT)-1 downto 0);
  
begin
  
  mux: process(sel, a, b)
  begin
    case sel is
	   when X"0"=> path <= a((16*DATA_WIDTH_OUT)-1 downto 0);
		when X"1"=> path <= b((1*DATA_WIDTH_OUT)-1 downto 0) & a((16*DATA_WIDTH_OUT)-1 downto (1*DATA_WIDTH_OUT));
		when X"2"=> path <= b((2*DATA_WIDTH_OUT)-1 downto 0) & a((16*DATA_WIDTH_OUT)-1 downto (2*DATA_WIDTH_OUT));
		when X"3"=> path <= b((3*DATA_WIDTH_OUT)-1 downto 0) & a((16*DATA_WIDTH_OUT)-1 downto (3*DATA_WIDTH_OUT));
		when X"4"=> path <= b((4*DATA_WIDTH_OUT)-1 downto 0) & a((16*DATA_WIDTH_OUT)-1 downto (4*DATA_WIDTH_OUT));
		when X"5"=> path <= b((5*DATA_WIDTH_OUT)-1 downto 0) & a((16*DATA_WIDTH_OUT)-1 downto (5*DATA_WIDTH_OUT));
		when X"6"=> path <= b((6*DATA_WIDTH_OUT)-1 downto 0) & a((16*DATA_WIDTH_OUT)-1 downto (6*DATA_WIDTH_OUT));
		when X"7"=> path <= b((7*DATA_WIDTH_OUT)-1 downto 0) & a((16*DATA_WIDTH_OUT)-1 downto (7*DATA_WIDTH_OUT));
		when X"8"=> path <= b((8*DATA_WIDTH_OUT)-1 downto 0) & a((16*DATA_WIDTH_OUT)-1 downto (8*DATA_WIDTH_OUT));
		when X"9"=> path <= b((9*DATA_WIDTH_OUT)-1 downto 0) & a((16*DATA_WIDTH_OUT)-1 downto (9*DATA_WIDTH_OUT));
		when X"A"=> path <= b((10*DATA_WIDTH_OUT)-1 downto 0) & a((16*DATA_WIDTH_OUT)-1 downto (10*DATA_WIDTH_OUT));
		when X"B"=> path <= b((11*DATA_WIDTH_OUT)-1 downto 0) & a((16*DATA_WIDTH_OUT)-1 downto (11*DATA_WIDTH_OUT));
		when X"C"=> path <= b((12*DATA_WIDTH_OUT)-1 downto 0) & a((16*DATA_WIDTH_OUT)-1 downto (12*DATA_WIDTH_OUT));
		when X"D"=> path <= b((13*DATA_WIDTH_OUT)-1 downto 0) & a((16*DATA_WIDTH_OUT)-1 downto (13*DATA_WIDTH_OUT));
		when X"E"=> path <= b((14*DATA_WIDTH_OUT)-1 downto 0) & a((16*DATA_WIDTH_OUT)-1 downto (14*DATA_WIDTH_OUT));
		when X"F"=> path <= b((15*DATA_WIDTH_OUT)-1 downto 0) & a((16*DATA_WIDTH_OUT)-1 downto (15*DATA_WIDTH_OUT));
		when others=> path <= (others=>'0');
    end case;
  end process;
  
  q0 <= path((1*DATA_WIDTH_OUT)-1 downto 0);
  q1 <= path((2*DATA_WIDTH_OUT)-1 downto (1*DATA_WIDTH_OUT));
  q2 <= path((3*DATA_WIDTH_OUT)-1 downto (2*DATA_WIDTH_OUT));
  q3 <= path((4*DATA_WIDTH_OUT)-1 downto (3*DATA_WIDTH_OUT));
  q4 <= path((5*DATA_WIDTH_OUT)-1 downto (4*DATA_WIDTH_OUT));
  q5 <= path((6*DATA_WIDTH_OUT)-1 downto (5*DATA_WIDTH_OUT));
  q6 <= path((7*DATA_WIDTH_OUT)-1 downto (6*DATA_WIDTH_OUT));
  q7 <= path((8*DATA_WIDTH_OUT)-1 downto (7*DATA_WIDTH_OUT));
  q8 <= path((9*DATA_WIDTH_OUT)-1 downto (8*DATA_WIDTH_OUT));
  q9 <= path((10*DATA_WIDTH_OUT)-1 downto (9*DATA_WIDTH_OUT));
  q10 <= path((11*DATA_WIDTH_OUT)-1 downto (10*DATA_WIDTH_OUT));
  q11 <= path((12*DATA_WIDTH_OUT)-1 downto (11*DATA_WIDTH_OUT));
  q12 <= path((13*DATA_WIDTH_OUT)-1 downto (12*DATA_WIDTH_OUT));
  q13 <= path((14*DATA_WIDTH_OUT)-1 downto (13*DATA_WIDTH_OUT));
  q14 <= path((15*DATA_WIDTH_OUT)-1 downto (14*DATA_WIDTH_OUT));
  q15 <= path((16*DATA_WIDTH_OUT)-1 downto (15*DATA_WIDTH_OUT));
  
end behavior;