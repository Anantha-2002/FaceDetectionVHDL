library ieee, altera;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity ram is
  generic (
    ADDR_WIDTH					: integer := 10;        
    DATA_WIDTH					: integer := 18;
    MAX_PRELOAD_ADDRESS		: integer := 575;
    MEM_FILE_NAME	: string :="fileName.txt";
    MIF_FILE_NAME	: string :="fileName.mif");
  port(
    data: IN std_logic_vector ((DATA_WIDTH-1) DOWNTO 0);
    rdaddress: IN STD_logic_vector((ADDR_WIDTH-1) downto 0);
    rdclock: IN STD_LOGIC;
    wraddress: IN STD_logic_vector((ADDR_WIDTH-1) downto 0);
    wrclock: IN STD_LOGIC;
    we: IN STD_LOGIC;
    re: IN STD_LOGIC;
    q: OUT std_logic_vector ((DATA_WIDTH-1) DOWNTO 0));
end ram;

architecture rtl of ram is

  TYPE MEM IS ARRAY(0 TO MAX_PRELOAD_ADDRESS) OF std_logic_vector((DATA_WIDTH-1) DOWNTO 0);
  
  impure function init_mem(mif_file_name : in string) return MEM is
    file mif_file : text open read_mode is mif_file_name;
    variable mif_line : line;
    variable temp_bv : bit_vector(DATA_WIDTH-1 downto 0);
    variable temp_mem : MEM;
    begin
      for i in 0 to MAX_PRELOAD_ADDRESS loop
        readline(mif_file, mif_line);
        read(mif_line, temp_bv);
        temp_mem(i) := to_stdlogicvector(temp_bv);
      end loop;
      return temp_mem;
  end function;
  
  --signal ram_block: MEM:= init_mem(MEM_FILE_NAME); -- use for simulation
  signal ram_block: MEM; -- use for hardware programming
  attribute ram_init_file : string;
  attribute ram_init_file of ram_block : signal is MIF_FILE_NAME;
  
  signal read_address_reg: std_logic_vector((ADDR_WIDTH-1) downto 0) := (others=>'0');
  
begin

  process (wrclock, rdclock)
  begin
    if (rising_edge(wrclock)) then
      if (we = '1') then
        ram_block(to_integer(unsigned(wraddress))) <= data;
      end if;
    end if;
    if (rising_edge(rdclock)) then
      if (re = '1') then
        q <= ram_block(to_integer(unsigned(rdaddress)));
      end if;
    end if;
  end process;

end rtl;