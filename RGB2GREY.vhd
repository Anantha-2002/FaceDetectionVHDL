library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity RGB2GREY is
  Port ( 
    Din : in  STD_LOGIC_VECTOR (11 downto 0);  -- 12bit color
    Dout : out  STD_LOGIC_VECTOR (7 downto 0) -- 8bit greyscale
  );      
end RGB2GREY;


architecture Behavioral of RGB2GREY is
 -- [1] https://en.wikipedia.org/wiki/Grayscale
 -- [2] https://sites.google.com/site/andrewlumbang/projects/vhdl-object-tracking
 -- [1] states that the luminace component of YUV can be calculated as:
 --     Y' = 0.299*R' + 0.587*G' + 0.114*B'
 -- This luminace can be utilized to represent greyscale
 -- [2] utilized a simple method of implementing this equaiton for VHDL RGB to greyscale conversion.
 -- They simply round the coefficients to numbers that can faciliate easy bit shifting (i.e.):
 --     Greyscale = 0.25*R + 0.5*G + 0.125*B
 
 -- This is equivalent to:
 -- X = R/4 = R >> 2
 -- Y = G/2 = G >> 1
 -- Z = B/8 = B >> 3
 -- Greyscale = X + Y + Z

 -- Our implementation uses RGB444 which consists of RRRR:GGGG:BBBB
 
 signal R,G,B : std_logic_vector(3 downto 0);
 signal X,Y,Z : std_logic_vector(7 downto 0);
 signal Q : std_logic_vector(7 downto 0);
 
begin

 -- VERSION1
 -- RRRR0000 >> 2 = 11110000 >> 2 = 00111100 = 60 (dec)
 -- GGGG0000 >> 1 = 11110000 >> 1 = 01111000 = 120 (dec)
 -- BBBB0000 >> 3 = 11110000 >> 3 = 00011110 = 30 (dec)
 -- 00111100 + 01111000 + 000111110 = 11010010 = 210 (dec) max
 
 -- VERSION2
 -- R(3 downto 0) & R(3 downto 0) >> 2 = "00" & R & R(3 downto 2) = 00111111 = 63 (dec)
 -- G(3 downto 0) & G(3 downto 0) >> 1 = '0' & G & G(3 downto 1) = 01111111 = 127 (dec)
 -- B(3 downto 0) & B(3 downto 0) >> 3 = "000" & B & B(3) = 00011111 = 31 (dec)
 -- GREYSCALE = R>>2 + G>>1 + B>>3 = 221 (dec) max .. more greyscale contrast ... VERY IMPORTANT!!! ...
 -- ... tests with version1 did not detect faces unless area around face was black and face was the only lit up item in frame 
 
 -- Split RRRR:GGGG:BBBB
 R <= Din(11 downto 8);
 G <= Din(7 downto 4);
 B <= Din(3 downto 0);
 
 -- R >> 2
 X <= "00" & R & R(3 downto 2);
 
 -- G >> 1
 Y <= '0' & G & G(3 downto 1);
 
 -- B >> 8
 Z <= "000" & B & B(3);

 -- R>>2 + G>>1 + B>>3
 Dout <= std_logic_vector(unsigned(X)+unsigned(Y)+unsigned(Z));


end Behavioral;
