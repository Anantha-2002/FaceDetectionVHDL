-- The integral image generator converts portions of the original color image to greyscale and then to integral image (ii) and integral image squared (iix2) format 
--   which is then stored in respective integral image buffers in the top level.
-- The ii and iix2 buffers share both ii_wraddress and ii_rdaddress since ii and iix2 calculations executed in tandem.
-- Each buffer is divided in to upper and lower memeory partitions, so mem_state specifies which partition the ii_gen process operates on.
-- 
-- The integral image values are calculated as follows (includes linear scaling):
-- 
-- Input: (scale, mem_state, scaleImg_x_base, scaleImg_y_base)
-- y <= 0 //init
-- y_scaled <= 0
-- done <= '0'
-- &image_mem <= [scaleImg_y_base*320+scaleImg_x_base]*scale // set ii base address relative to original image dimentions
-- if mem_state='0' then // assign base address; integral image memories are partitioned
--   &ii_mem <= 0 // operate on lower integral image memory partition
--   &iix2_mem <= 0
-- else
--   &ii_mem <= 4096 // operate on upper integral image memory partition
--   &iix2_mem <= 4096
-- end if
-- while y<(II_HEIGHT-1) do
--   x <= 0
--   x_scaled <= 0
--   ii_accum <= 0
--   iix2_accum <= 0
--   while x<(II_WIDTH-1) do
--     grey_data <= image_mem[x_scaled,y_scaled]
--     grey_data_square <= grey_data*grey_data
--     if y=0 then
--       ii_accum <= ii_accum + grey_data
--       iix2_accum <= iix2_accum + grey_data_square
--     else
--       ii_accum <= ii_accum + grey_data + ii_mem[x,y-1]
--       iix2_accum <= iix2_accum + grey_data_square + iix2_mem[x,y-1]
--     end if
--     ii_mem[x,y] <= ii_accum
--     iix2_mem[x,y] <= iix2_accum
--     x++
--     x_scaled+=scale
--   end while
--   y++
--   y_scaled+=scale
-- end while
-- while (not reset) do
--   done <= '1' // hold done='1' until reset
-- end while
-- 
-- Integral image buffers are split into two parts: upper and lower addressable regions
-- Lower addressable integral image base address = 0 (dec)
-- Upper addressable integral image base address = 4096 (dec)
-- Integral image has 8,192 addressable words ... 13bit uns address
-- Integral image address MSbit determines which area to operate on

-- II_WIDTH = 39 pixels
-- II_HEIGHT = 59 pixels
-- Max greyscale value = 255 (dec)
-- II pixel area = 39*59 = 2,301 words
-- II max data val = 2,301*(255) = 586,755 ... 20bit uns
-- IIx2 max data val = 2,301*(255)^2 = 149,622,525 ... 28bit uns

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ii_gen is
  port(
    clk             : in std_logic;
    reset           : in std_logic;
    start           : in std_logic; -- start ii_gen processes, single clock cycle pulse starts process
    image_scale     : in std_logic_vector(3 downto 0);
    image_data_i    : in std_logic_vector(11 downto 0); -- 12 bit color (RGB444) from image_buffer read data (q) output
    ii_data_i       : in std_logic_vector(19 downto 0);
    iix2_data_i     : in std_logic_vector(27 downto 0);
    mem_state       : in std_logic;
    scaleImg_x_base : in std_logic_vector(8 downto 0);
    scaleImg_y_base : in std_logic_vector(7 downto 0);
    image_rdaddress : out std_logic_vector(16 downto 0);
    ii_address      : out std_logic_vector(12 downto 0); -- address for ii and iix2 buffers
    ii_wren         : out std_logic;                     -- wren for ii and iix2 buffers
    ii_data_o       : out std_logic_vector(19 downto 0);
    iix2_data_o     : out std_logic_vector(27 downto 0);
    done            : out std_logic -- asserted logic high once ii_gen process is complete, de-asserted when whole module is reset
  );
end ii_gen;

architecture behavior of ii_gen is
 
  -- COMPONENTS
 
  component RGB2GREY
    Port ( 
      Din : in  STD_LOGIC_VECTOR (11 downto 0); -- 12bit color
      Dout : out  STD_LOGIC_VECTOR (7 downto 0) -- 8bit greyscale
    );      
  end component;
  
  -- CONSTANTS
  
  constant II_WIDTH : unsigned(5 downto 0) := to_unsigned(39,6);
  constant II_HEIGHT : unsigned(5 downto 0) := to_unsigned(59,6);
  
  -- SIGNALS
  signal grey_data : std_logic_vector(7 downto 0);
  signal grey_data_square : std_logic_vector(15 downto 0); -- 7bit * 7bit results in 14 bit unsigned
  
  signal temp0 : std_logic_vector(15 downto 0);
  signal temp1 : std_logic_vector(15 downto 0);
  signal temp3 : std_logic_vector(16 downto 0);
  signal scaleImg_address_base : std_logic_vector(16 downto 0);
  signal image_address_base : std_logic_vector(16 downto 0);
  signal temp_image_address_base : std_logic_vector(20 downto 0);
  
  signal x : std_logic_vector(5 downto 0); -- 39dec max
  signal x_count_reset : std_logic;
  signal x_count_en : std_logic;
  
  signal y : std_logic_vector(5 downto 0); -- 59dec max
  signal y_count_reset : std_logic;
  signal y_count_en : std_logic;
  
  signal ii_address_sel : std_logic;
  signal ii_wraddress : std_logic_vector(12 downto 0);
  signal ii_rdaddress : std_logic_vector(12 downto 0);
  signal image_rdaddress_s : std_logic_vector(16 downto 0);
  signal address_accum_reset : std_logic;
  signal buffer_we : std_logic;
  
  signal accum_reset : std_logic;
  signal accum_en : std_logic;
  signal ii_data_accum : std_logic_vector(13 downto 0); -- accumulator register out
  signal iix2_data_accum : std_logic_vector(21 downto 0); -- accumulator register out
  signal add2 : std_logic_vector(13 downto 0);
  signal add3 : std_logic_vector(21 downto 0);
  signal add2_extend : std_logic_vector(19 downto 0);
  signal add3_extend : std_logic_vector(27 downto 0);
  signal add4 : std_logic_vector(19 downto 0);
  signal add5 : std_logic_vector(27 downto 0);
  
  signal ii_data_o_s : std_logic_vector(19 downto 0); -- unsigned
  signal iix2_data_o_s : std_logic_vector(27 downto 0); -- unsigned
  
  signal done_s : std_logic;
  
  type STATE_TYPE is (s_RESET,s_latch_RAM_read,s_latch_RAM_write,s_soft_reset,s_DONE);
  signal state,next_state : STATE_TYPE;  
  
  -- EXTRA VALUE TO INC IMAGE RDADDRESS -- max_img_width*scale-(ii_width-1)*scale
  type lut0 is array ( 0 to 8 ) of std_logic_vector(11 downto 0);
  constant my_lut0 : lut0 := ( std_logic_vector(to_unsigned(0, 12)), -- not used
                               std_logic_vector(to_unsigned(320*1-(39-1)*1, 12)),
                               std_logic_vector(to_unsigned(320*2-(39-1)*2, 12)),
                               std_logic_vector(to_unsigned(320*3-(39-1)*3, 12)),
                               std_logic_vector(to_unsigned(320*4-(39-1)*4, 12)),
                               std_logic_vector(to_unsigned(320*5-(39-1)*5, 12)),
                               std_logic_vector(to_unsigned(320*6-(39-1)*6, 12)),
                               std_logic_vector(to_unsigned(320*7-(39-1)*7, 12)),
                               std_logic_vector(to_unsigned(320*8-(39-1)*8, 12)) );
  signal lut0_q : std_logic_vector(11 downto 0); -- output signal of my_lut0 process
  
  -- PIPELINE CONTROL
  signal pipeline_reset : std_logic;
  signal pipeline_advance : std_logic;
  
  -- PIPELINE REGISTERS
  -- R0
  signal reg0_x : std_logic_vector(5 downto 0);
  signal reg0_y : std_logic_vector(5 downto 0);
  signal reg0_ii_wraddress : std_logic_vector(12 downto 0);
  signal reg0_image_data : std_logic_vector(11 downto 0);
  signal reg0_ii_data : std_logic_vector(19 downto 0);
  signal reg0_iix2_data : std_logic_vector(27 downto 0);
  signal reg0_accum_reset : std_logic;
  signal reg0_accum_en : std_logic;
  signal reg0_done : std_logic;
  -- R1
  signal reg1_x : std_logic_vector(5 downto 0);
  signal reg1_y : std_logic_vector(5 downto 0);
  signal reg1_ii_wraddress : std_logic_vector(12 downto 0);
  signal reg1_grey_data : std_logic_vector(7 downto 0);
  signal reg1_ii_data : std_logic_vector(19 downto 0);
  signal reg1_iix2_data : std_logic_vector(27 downto 0);
  signal reg1_accum_reset : std_logic;
  signal reg1_accum_en : std_logic;
  signal reg1_done : std_logic;
  -- R2
  signal reg2_x : std_logic_vector(5 downto 0);
  signal reg2_y : std_logic_vector(5 downto 0);
  signal reg2_ii_wraddress : std_logic_vector(12 downto 0);
  signal reg2_grey_data : std_logic_vector(7 downto 0);
  signal reg2_grey_data_square : std_logic_vector(15 downto 0);
  signal reg2_ii_data : std_logic_vector(19 downto 0);
  signal reg2_iix2_data : std_logic_vector(27 downto 0);
  signal reg2_accum_reset : std_logic;
  signal reg2_accum_en : std_logic;
  signal reg2_done : std_logic;
  -- R3
  signal reg3_x : std_logic_vector(5 downto 0);
  signal reg3_y : std_logic_vector(5 downto 0);
  signal reg3_ii_wraddress : std_logic_vector(12 downto 0);
  signal reg3_add2_extend : std_logic_vector(19 downto 0);
  signal reg3_add3_extend : std_logic_vector(27 downto 0);
  signal reg3_add4 : std_logic_vector(19 downto 0);
  signal reg3_add5 : std_logic_vector(27 downto 0);
  signal reg3_done : std_logic;
  
  signal reset_done_reg : std_logic;
  signal done_reg : std_logic;
  
begin
  -- x counter; relative to integral image dimentions
  x_counter: process (clk, x_count_reset, x_count_en)
  begin
    if (x_count_reset='1') then
      x <= (others => '0');
    elsif (rising_edge(clk) and (x_count_en='1')) then
      x <= std_logic_vector(unsigned(x) + to_unsigned(1,6));
    end if;
  end process;
  
  -- y counter; relative to integral image dimentions
  y_counter: process (clk, y_count_reset, y_count_en)
  begin
    if (y_count_reset='1') then
      y <= (others => '0');
    elsif (rising_edge(clk) and (y_count_en='1')) then
      y <= std_logic_vector(unsigned(y) + to_unsigned(1,6));
    end if;
  end process;
 
  -- convert 12bit color (RGB444) to 8bit greyscale data
  RGB2GREY_inst: RGB2GREY port map( Din => reg0_image_data, Dout => grey_data);
  grey_data_square <= std_logic_vector(unsigned(reg1_grey_data)*unsigned(reg1_grey_data)); -- 8bit * 8bit ... 16 bit unsigned
  
  -- calculate the base address location of the integral image relative to the scaled image
  -- scaleImg_address_base = scaleImg_y_base*(max_img_width) + scaleImg_x_base
  temp0 <= scaleImg_y_base & "00000000";                                  -- y * 256; y << 9 ... 240*256=61,440 ... 16bit uns
  temp1 <= "00" & scaleImg_y_base & "000000";                             -- y * 64; y << 7 ... 240*64=15,360 ... 16bit uns 
  temp3 <= std_logic_vector(unsigned('0' & temp0)+unsigned('0' & temp1)); -- y*256 + y*64 = y*(320) =y*max_img_width ... 240*320=76,800 ... 17bit uns
  scaleImg_address_base <= std_logic_vector(unsigned(temp3)+unsigned(scaleImg_x_base));
  
  -- calculate the base address location of the integral image relative to the orinal image; this is the base address used for linear scaling
  -- image_address_base = scaleImg_address_base*image_scale
  temp_image_address_base <= std_logic_vector(unsigned(scaleImg_address_base)*unsigned(image_scale));
  image_address_base <= temp_image_address_base(16 downto 0);
  
  -- value used for image_rdaddress vertical increment 
  lut0_q <= my_lut0(to_integer(unsigned(image_scale)));
  
  -- image_rdaddress accumulator
  -- (1) since the integral image scans the oringal image, image_address_base specifies the location of the integral image relative to oringal image with scaling adjustments
  -- (2) increment the image_rdaddress in a linear scaling fashion
  --     by x_scaled+=image_scale
  --     or x_scaled=0, y_scaled+=image_scale
  image_rdaddress_accum: process (clk, address_accum_reset, x_count_en, y_count_en, image_scale, lut0_q, image_address_base)
  begin
    if rising_edge(clk) and address_accum_reset='1' then
      image_rdaddress_s <= image_address_base;
    elsif rising_edge(clk) and x_count_en='1' then -- address += scale
      image_rdaddress_s <= std_logic_vector( unsigned(image_rdaddress_s) + unsigned(image_scale) );
    elsif rising_edge(clk) and y_count_en='1' then -- address += max_img_width*scale-(ii_width-1)*scale
      image_rdaddress_s <= std_logic_vector( unsigned(image_rdaddress_s) + unsigned(lut0_q) );
    end if;
  end process;
  image_rdaddress <= image_rdaddress_s;
  
  -- ii_wraddress accumulator; write to ii_mem[x,y]
  -- (1) specify the base ii_wraddress relative to the mem_state, then increment sequentially
  --     i.e. mem_state='0' writes the integral image from address 0 to (II_WIDTH*II_HEIGHT-1)
  --          mem_state='1' writes the integral image from address 4096 to 4096+(II_WIDTH*II_HEIGHT-1)
  ii_wraddress_accum: process (clk, address_accum_reset, x_count_en, y_count_en)
  begin
    if rising_edge(clk) and address_accum_reset='1' then
      if mem_state='0' then           -- load ii into lower mem
        ii_wraddress <= (others=>'0');
      else                            -- load ii into upper mem
        ii_wraddress <= std_logic_vector(to_unsigned(4096,13));
      end if;
    elsif rising_edge(clk) and (x_count_en='1' or y_count_en='1') then
      ii_wraddress <= std_logic_vector( unsigned(ii_wraddress) + to_unsigned(1,8));
    end if;
  end process;
  
  -- ii_rdaddress is always ii_mem[x,y-1] = ii_wraddress - II_WIDTH
  ii_rdaddress <= std_logic_vector(unsigned(ii_wraddress) - II_WIDTH);
  
  -- integral image read and write address share the same buffer address input
  address_mux: process(reg3_ii_wraddress, ii_rdaddress, ii_address_sel)
  begin
    if ii_address_sel='0' then
      ii_address <= ii_rdaddress;
    else
      ii_address <= reg3_ii_wraddress;
    end if;
  end process;
  
  -- accumulator data path
  -- grey_data + ii_mem[x,y-1]
  add2 <= std_logic_vector(unsigned(reg2_grey_data)+unsigned(ii_data_accum)); -- max = 39*255 = 9,945 = 14bit uns 
  -- grey_data_square + iix2_mem[x,y-1]
  add3 <= std_logic_vector(unsigned(reg2_grey_data_square)+unsigned(iix2_data_accum)); -- max = 39*(255*255) = 2,535,975 = 22bit uns
  add2_extend(19 downto 14) <= (others=>'0');
  add2_extend(13 downto 0) <= add2;
  add3_extend(27 downto 22) <= (others=>'0');
  add3_extend(21 downto 0) <= add3;
  
  -- accumulate the ii and iix2 values for a single row at a time
  accum_reg: process(clk, reset, reg2_accum_reset, reg2_accum_en, add2, add3, pipeline_advance)
  begin
    if (rising_edge(clk) and reg2_accum_reset='1'and pipeline_advance='1') then
      ii_data_accum <= (others=>'0'); -- sync register reset
      iix2_data_accum <= (others=>'0');
    else
      if (rising_edge(clk) and reg2_accum_en='1' and pipeline_advance='1') then -- only accumulate when new data is shifted in pipeline
        ii_data_accum <= add2; -- latch register
        iix2_data_accum <= add3;
      end if;
    end if;
  end process;
  
  add4 <= std_logic_vector(unsigned(reg2_ii_data)+unsigned(add2));   -- ii_accum + grey_data + ii_mem[x,y-1]
  add5 <= std_logic_vector(unsigned(reg2_iix2_data)+unsigned(add3)); -- iix2_accum + grey_data_square + iix2_mem[x,y-1]
  
  -- data output mux .. sel='1' when y=0(dec)
  mux0: process(reg3_y,reg3_add2_extend,reg3_add3_extend,reg3_add4,reg3_add5)
  begin
    if (reg3_y="000000") then
       ii_data_o_s <= reg3_add2_extend;   -- ii_mem[x,y] <= ii_accum + grey_data
     iix2_data_o_s <= reg3_add3_extend; -- iix2_mem[x,y] <= iix2_accum + grey_data_square
    else
       ii_data_o_s <= reg3_add4;   -- ii_mem[x,y] <= ii_accum + grey_data + ii_mem[x,y-1]
     iix2_data_o_s <= reg3_add5; -- iix2_mem[x,y] <= iix2_accum + grey_data_square + iix2_mem[x,y-1]
    end if;
  end process;
  
  pipeline: process (clk, pipeline_reset, pipeline_advance, x, y, ii_wraddress, image_data_i, ii_data_i, iix2_data_i, grey_data, grey_data_square, add2_extend, add3_extend, add4, add5, accum_reset, accum_en, done_s)
  begin
    if pipeline_reset='1' then -- reset all registers in pipeline
      reg0_x            <= (others=>'0');
      reg0_y            <= (others=>'0'); 
      reg0_ii_wraddress <= (others=>'0'); 
      reg0_image_data   <= (others=>'0');
      reg0_ii_data      <= (others=>'0');
      reg0_iix2_data    <= (others=>'0');
      reg0_accum_reset  <= '1';
      reg0_accum_en     <= '0';
      reg0_done         <= '0';
      
      reg1_x            <= (others=>'0');
      reg1_y            <= (others=>'0'); 
      reg1_ii_wraddress <= (others=>'0'); 
      reg1_grey_data    <= (others=>'0');
      reg1_ii_data      <= (others=>'0');
      reg1_iix2_data    <= (others=>'0');
      reg1_accum_reset  <= '1';
      reg1_accum_en     <= '0';
      reg1_done         <= '0';
  
      reg2_x                <= (others=>'0');
      reg2_y                <= (others=>'0'); 
      reg2_ii_wraddress     <= (others=>'0'); 
      reg2_grey_data_square <= (others=>'0');
      reg2_ii_data          <= (others=>'0');
      reg2_iix2_data        <= (others=>'0');
      reg2_accum_reset  <= '1';
      reg2_accum_en     <= '0';
      reg2_done         <= '0';
  
      reg3_x            <= (others=>'0');
      reg3_y            <= (others=>'0'); 
      reg3_ii_wraddress <= (others=>'0'); 
      reg3_add2_extend  <= (others=>'0');
      reg3_add3_extend  <= (others=>'0');
      reg3_add4         <= (others=>'0');
      reg3_add5         <= (others=>'0');
      reg3_done         <= '0';
  
    elsif rising_edge(clk) and pipeline_advance='1' then -- pipline data advances
      reg0_x            <= x;
      reg0_y            <= y; 
      reg0_ii_wraddress <= ii_wraddress; 
      reg0_image_data   <= image_data_i;
      reg0_ii_data      <= ii_data_i;
      reg0_iix2_data    <= iix2_data_i;
      reg0_accum_reset  <= accum_reset;
      reg0_accum_en     <= accum_en;
      reg0_done         <= done_s;
      
      reg1_x            <= reg0_x;
      reg1_y            <= reg0_y; 
      reg1_ii_wraddress <= reg0_ii_wraddress; 
      reg1_grey_data    <= grey_data;
      reg1_ii_data      <= reg0_ii_data;
      reg1_iix2_data    <= reg0_iix2_data;
      reg1_accum_reset  <= reg0_accum_reset;
      reg1_accum_en     <= reg0_accum_en;
      reg1_done         <= reg0_done;
      
      reg2_x                <= reg1_x;
      reg2_y                <= reg1_y; 
      reg2_ii_wraddress     <= reg1_ii_wraddress; 
      reg2_grey_data        <= reg1_grey_data;
      reg2_grey_data_square <= grey_data_square;
      reg2_ii_data          <= reg1_ii_data;
      reg2_iix2_data        <= reg1_iix2_data;
      reg2_accum_reset      <= reg1_accum_reset;
      reg2_accum_en         <= reg1_accum_en;
      reg2_done             <= reg1_done;
      
      reg3_x            <= reg2_x;
      reg3_y            <= reg2_y; 
      reg3_ii_wraddress <= reg2_ii_wraddress; 
      reg3_add2_extend  <= add2_extend;
      reg3_add3_extend  <= add3_extend;
      reg3_add4         <= add4;
      reg3_add5         <= add5;
      reg3_done         <= reg2_done;
    
    end if;
  end process;
  
  -- state machine flip flop
  ff_SM: process(clk, reset, next_state)
  begin
    if (reset='1') then
      state <= s_RESET;
    elsif (rising_edge(clk)) then
      state <= next_state;
    end if;
  end process;
  
  -- state machine combinational logic
  combA: process(state, start, x, y, ii_address_sel, done_reg)
  begin
    accum_reset <= '0';
    buffer_we <= '0';
    accum_en <= '0';
    x_count_reset <= '0';
    x_count_en <= '0';
    y_count_reset <= '0';
    y_count_en <= '0';
    done_s <= '0';
    ii_address_sel <= '0';
    address_accum_reset <= '0';
    pipeline_advance <= '0';
    pipeline_reset <= '0';
    reset_done_reg <= '0';
  
    case state is
      when s_RESET =>
        accum_reset <= '1';
        address_accum_reset <= '1';
        x_count_reset <= '1';
        y_count_reset <= '1';
        pipeline_reset <= '1';
        reset_done_reg <= '1';
        if (start='1') then
          next_state <= s_latch_RAM_read;
        else
          next_state <= s_RESET;
        end if;
        
      when s_latch_RAM_read =>
        ii_address_sel <= '0'; -- setup image_rdaddress and ii_rdaddress
        next_state <= s_latch_RAM_write;
      
      when s_latch_RAM_write =>
        pipeline_advance <= '1';
        buffer_we <= '1'; -- setup ii_wren
        ii_address_sel <= '1'; -- setup ii_wraddress
        
        if (unsigned(x)=II_WIDTH-to_unsigned(1,6))  then -- current ii row accumulation done
          accum_reset <= '1';
          if (unsigned(y)=II_HEIGHT-to_unsigned(1,6)) then -- completed all ii calcs
            -- go to done state
            done_s <= '1'; -- flag last pipeline execution with done
            next_state <= s_DONE;
          else
            y_count_en <= '1'; --increment to next ii row
            next_state <= s_soft_reset;
          end if;
        else
          accum_en <= '1'; -- continue to accumulate row ii values
          x_count_en <= '1';
          next_state <= s_latch_RAM_read;
        end if;
        
      when s_soft_reset =>
        x_count_reset <= '1'; -- sync reset ii x position
        next_state <= s_latch_RAM_read;
        
      when s_DONE =>
        -- continue to write ii values to buffer unitl done assertion is recieved from last pipeline operation
        if done_reg='1' then
        -- null, stop writing to ii buffer
        else
          ii_address_sel <= '1'; -- setup wraddress
          pipeline_advance <= '1'; -- advance remaining pipeline data
          buffer_we <= '1';
        end if;
        next_state <= s_DONE; -- stay here, reset at top level
      
    end case;
  end process;
  
  done_register: process(clk, reset_done_reg, reg3_done)
  begin
    if reset_done_reg='1' then
      done_reg <= '0';
    elsif rising_edge(clk) and reg3_done='1' then
      done_reg <= '1';
    end if;
  end process;
  
  ii_wren <= buffer_we;
  ii_data_o <= ii_data_o_s;
  iix2_data_o <= iix2_data_o_s;
  done <= done_reg;
 
end behavior;