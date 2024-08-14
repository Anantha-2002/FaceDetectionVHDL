library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- this is a 2:1 mux

entity mux_std_logic is
  port(
    sel: in std_logic; -- 
    a: in std_logic; -- 
    b: in std_logic; -- 
    q: out std_logic -- 
  );
end mux_std_logic;

architecture behavior of mux_std_logic is

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
