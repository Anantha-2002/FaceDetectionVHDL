library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- this is a 2:1 mux

entity mux_2_1 is
  generic(DATA_WIDTH: integer := 4);
  port(
    sel: in std_logic; -- 
    a: in std_logic_vector(DATA_WIDTH-1 downto 0); -- 
    b: in std_logic_vector(DATA_WIDTH-1 downto 0); -- 
    q: out std_logic_vector(DATA_WIDTH-1 downto 0) -- 
  );
end mux_2_1;

architecture behavior of mux_2_1 is

begin
  
  mux0: process(a, b, sel)
  begin
  
    if sel='1' then
      q <= b;
    else
      q <= a;
    end if;
  
  end process;
  
end behavior;
