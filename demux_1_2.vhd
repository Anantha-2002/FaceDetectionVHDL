library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- this is a 1:2 demux

entity demux_1_2 is
  generic(DATA_WIDTH: integer := 4);
  port(
    sel: in std_logic; -- 
    a: in std_logic_vector(DATA_WIDTH-1 downto 0); -- 
    q0: out std_logic_vector(DATA_WIDTH-1 downto 0); -- 
    q1: out std_logic_vector(DATA_WIDTH-1 downto 0) -- 
  );
end demux_1_2;

architecture behavior of demux_1_2 is

begin
  
  mux0: process(a, sel)
  begin
  
    if sel='1' then
      q0 <= (others=>'0');
      q1 <= a;
    else
      q0 <= a;
      q1 <= (others=>'0');
    end if;
  
  end process;
  
end behavior;
