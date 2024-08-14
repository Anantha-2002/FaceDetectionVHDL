-- This is the top level of the subwindow detection bundle.
-- This bundle includes:
--   (1) classifier cascade state machine
--   (2) global ROM entities that store the classifer cascade parameters
--   (3) address decoders for subwindow corner regestering and subwindow rectangle feature registering
--   (4) integral image datapath routing
--   (5) 16 parallel subwindows, each offset by one integral image pixel in the x direction
--   (6) failure register, which latches any failures flaged at the end of a strong stage comparison 
-- 
-- Each subwindow has a dimention of 24x24 pixels
-- The classifier cascade consists of 25 strong stages that are divided into 2913 weak stages
-- 
-- Subwindows are processed as follows:
-- 
-- *Note that addressing data from the integral image buffers is relative to addressing for subwindow0
-- *Note that subwindow failures are registered and persist through the cascade evaluation
-- *Note that the top level will reset this process and evaluate new subwindows if all subwindows fail or the cascade runs to completion
-- 
-- wait for start flag //from top level
-- load initial strong_thresh and weak_stage_num
-- for (2913 weak stages)                    //run the full classifier cascade until done or reset by top level
--   if (weak_count < weak_stage_num-1) then
--     if (var_norm_prep = not done) then
--       for subwin_corner=0:3                             //four subwindow corners
--         register 16 adjacent ii subwindow corner values //concurrent latch for 16 subwindows
--       end for
--       calculate variance normalization //concurrent calculation for 16 suwbwindows
--       var_norm_prep <= done
--     else
--       load weak stage classifier cascade parameters
--       for (feature_rect=0:2) do                    //three feature rectangles per weak stage
--         for (rectangle_corner=0:3) do              //four rectangle corners per rectangle
--           register 16 adjacent ii rectangle values //concurrent latch for 16 subwindows
--         end for
--       end for
--       perform feature calculation
--       latch strong accumulator
--       weak_count++
--     end if
--   else         //current strong stage complete
--     latch subwindow strong threshold failures
--     load new strong_thresh and weak_stage_num
--   end if
-- end for
-- assert cascade done
-- wait for reset //from top level

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity subwindow_top is
  port(
    reset: in std_logic; -- reset asserted logic '1'
    clk_sys: in std_logic;
    start: in std_logic;
    mem_state: in std_logic;
    x_pos_subwin0: in std_logic_vector(5 downto 0); -- relative to the integral image
    y_pos_subwin0: in std_logic_vector(5 downto 0); -- relative to the integral image
    ii_rddata: in std_logic_vector((16*20*2)-1 downto 0);
    iix2_rddata: in std_logic_vector((16*28*2)-1 downto 0);
    ii_rdaddress: out std_logic_vector(8 downto 0);
    iix2_rdaddress: out std_logic_vector(8 downto 0);
    fail_out: out std_logic_vector(15 downto 0);
    done: out std_logic
  );
end subwindow_top;

architecture structure of subwindow_top is
  
  component ram
    generic (
      ADDR_WIDTH     : integer := 10;        
      DATA_WIDTH     : integer := 18;
      MAX_PRELOAD_ADDRESS  : integer := 575;
      MEM_FILE_NAME : string :="fileName.txt";
      MIF_FILE_NAME : string :="fileName.mif");
    port(
      data: IN std_logic_vector ((DATA_WIDTH-1) DOWNTO 0);
      rdaddress: IN STD_logic_vector((ADDR_WIDTH-1) downto 0);
      rdclock: IN STD_LOGIC;
      wraddress: IN STD_logic_vector((ADDR_WIDTH-1) downto 0);
      wrclock: IN STD_LOGIC;
      we: IN STD_LOGIC;
      re: IN STD_LOGIC;
      q: OUT std_logic_vector ((DATA_WIDTH-1) DOWNTO 0));
  end component;
  
  component parallel_dataPath_mux
    generic(DATA_WIDTH_OUT : integer:= 20);
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
  end component;
  
  component subwindow
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
  end component;
  
  component ii_address_decoder
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
  end component;
  
  component iix2_address_decoder --used for ii and iix2 corner addressing
    port(
      iix2_reg_index: in std_logic_vector(1 downto 0); -- 2bit unsigned ... range 0 to 3
      width_ii: in std_logic_vector (5 downto 0); -- 8bit unsigned ... range(0 to 38)
      p_offset: in std_logic_vector(12 downto 0); -- 13bit unsigned ... range(0 to (39*59-1)) or range(4096 to (39*58-1)+4096) -- base address of the subwindow0 (top left corner)
      iix2_address: out std_logic_vector(12 downto 0) -- 13bit unsigned ... range(0 to (39*59-1)) or range(4096 to (39*58-1)+4096)
    );
  end component;

  component pixel_offset
    port(
      mem_state: in std_logic;
      x_pos_subwin: in std_logic_vector(5 downto 0); -- 6bit unsigned ... range(0 to 38)
      y_pos_subwin: in std_logic_vector(5 downto 0); -- 6bit unsigned ... range(0 to 58)
      width_ii: in std_logic_vector(5 downto 0); -- 6bit unsigned ... range(0 to 38)
      p_offset: out std_logic_vector(12 downto 0) -- 13bit unsigned ... range(0 to (39*58-1)) or range(4096 to (39*58-1)+4096)
    );
  end component;
  
  component counter
    generic (COUNT_WIDTH : integer := 4);
    port(
      clk: in std_logic;
      reset: in std_logic;
      en: in std_logic;
      count: out std_logic_vector(COUNT_WIDTH-1 downto 0)
    );
  end component;
  
  -- CONSTANTS
  
  constant II_WIDTH : unsigned(5 downto 0) := to_unsigned(39,6);
  constant II_HEIGHT : unsigned(5 downto 0) := to_unsigned(59,6);
  
  -- Counter signals
  
  signal strongStage_count: std_logic_vector(4 downto 0); -- unsigned
  signal weakNode_count: std_logic_vector(11 downto 0); -- unsigned
  signal weak_count: std_logic_vector(7 downto 0);
  
  -- Strong stage ROM data signals
  
  signal weak_stage_num: std_logic_vector(7 downto 0); --unsigned
  signal strong_thresh: std_logic_vector(11 downto 0); -- signed
  
  -- Weak stage ROM data signals
  
  signal left_tree: std_logic_vector(13 downto 0); -- signed
  signal right_tree: std_logic_vector(13 downto 0); -- signed
  signal weak_thresh: std_logic_vector(12 downto 0); -- signed
  
  signal weight_rect0: std_logic_vector(14 downto 0); -- signed
  signal weight_rect1: std_logic_vector(14 downto 0); -- signed
  signal weight_rect2: std_logic_vector(14 downto 0); -- signed
  
  signal x_rect0: std_logic_vector(4 downto 0); -- unsigned
  signal x_rect1: std_logic_vector(4 downto 0); -- unsigned
  signal x_rect2: std_logic_vector(4 downto 0); -- unsigned
  signal y_rect0: std_logic_vector(4 downto 0); -- unsigned
  signal y_rect1: std_logic_vector(4 downto 0); -- unsigned
  signal y_rect2: std_logic_vector(4 downto 0); -- unsigned
  signal w_rect0: std_logic_vector(4 downto 0); -- unsigned
  signal w_rect1: std_logic_vector(4 downto 0); -- unsigned
  signal w_rect2: std_logic_vector(4 downto 0); -- unsigned
  signal h_rect0: std_logic_vector(4 downto 0); -- unsigned
  signal h_rect1: std_logic_vector(4 downto 0); -- unsigned
  signal h_rect2: std_logic_vector(4 downto 0); -- unsigned
  
  -- ii and iix2 address generator signals
  signal ii_address_mux0: std_logic_vector(12 downto 0); -- unsigned, signal into ii RAM address from mux
  
  signal ii_address0: std_logic_vector(12 downto 0); -- unsigned
  type array_type1 is array (0 to 15) of std_logic_vector(19 downto 0); -- unsigned
  signal ii_data: array_type1;
  signal ii_reg_index: std_logic_vector(3 downto 0);
  
  signal iix2_address0: std_logic_vector(12 downto 0); -- unsigned
  type array_type2 is array (0 to 15) of std_logic_vector(27 downto 0); -- unsigned
  signal iix2_data: array_type2;
  signal iix2_reg_index: std_logic_vector(1 downto 0); -- unsigned
  
  -- Subwindow position signals
  signal p_offset0: std_logic_vector(12 downto 0); -- unsigned
  
  -- Control signals
  
  signal cascade_done: std_logic;
  signal cascade_start: std_logic;
  
  signal subwindow_reset: std_logic; -- reset the strong accumulator to zero
  signal en_strongAccum0: std_logic;
  signal en_var_norm0: std_logic;
  
  signal ii_reg_we0: std_logic;
  signal ii_reg_address: std_logic_vector(3 downto 0); -- unsigned

  signal ii_rdaddress_mux_sel: std_logic;
  signal iix2_reg_we0: std_logic;
  signal iix2_regLoad_DONE: std_logic;
  signal iix2_regLoad_DONE_latch: std_logic;
  signal iix2_regLoad_DONE_reset: std_logic;
  
  signal fail_reg: std_logic_vector(15 downto 0);
  signal fail_reg_latch: std_logic;
  signal fail_reg_reset: std_logic;
  signal face_detected_s: std_logic_vector(15 downto 0);
  
  signal ii_reg_index_count_en: std_logic;
  signal ii_reg_index_count_reset: std_logic;
  signal weakNode_count_en: std_logic;
  signal weakNode_count_reset: std_logic;
  signal weak_count_en: std_logic;
  signal weak_count_reset: std_logic;
  signal strongStage_count_en: std_logic;
  signal strongStage_count_reset: std_logic;
  signal iix2_reg_index_count_en: std_logic;
  signal iix2_reg_index_count_reset: std_logic;
  
  -- State machine signals
  type STATE_TYPE is (s_RESET, s_latch_ROM, s_latch_RAM_address, s_latch_iix2_reg, s_latch_ii_reg, s_latch_strongAccum, s_strongCompare, s_flagDone, s_DONE);
  signal current_state,next_state   : STATE_TYPE;
  
  -- clock signals
  signal clk, clk_memRead: std_logic;
  
begin

  -- input assignments
  cascade_start <= start;
  clk <= clk_sys;
  clk_memRead <= clk_sys;
  
  -- big data mux's; selects 16 adjacent words from the 32 word input
  ii_data_mux: parallel_dataPath_mux
   generic map(DATA_WIDTH_OUT => 20)
   port map(
    sel => ii_address_mux0(3 downto 0),
    a => ii_rddata((16*20*1)-1 downto 0),
    b => ii_rddata((16*20*2)-1 downto (16*20*1)),
    q0 => ii_data(0),
    q1 => ii_data(1),
    q2 => ii_data(2),
    q3 => ii_data(3),
    q4 => ii_data(4),
    q5 => ii_data(5),
    q6 => ii_data(6),
    q7 => ii_data(7),
    q8 => ii_data(8),
    q9 => ii_data(9),
    q10 => ii_data(10),
    q11 => ii_data(11),
    q12 => ii_data(12),
    q13 => ii_data(13),
    q14 => ii_data(14),
    q15 => ii_data(15)
  );
  
  iix2_data_mux: parallel_dataPath_mux
   generic map(DATA_WIDTH_OUT => 28)
   port map(
    sel => iix2_address0(3 downto 0),
    a => iix2_rddata((16*28*1)-1 downto 0),
    b => iix2_rddata((16*28*2)-1 downto (16*28*1)),
    q0 => iix2_data(0),
    q1 => iix2_data(1),
    q2 => iix2_data(2),
    q3 => iix2_data(3),
    q4 => iix2_data(4),
    q5 => iix2_data(5),
    q6 => iix2_data(6),
    q7 => iix2_data(7),
    q8 => iix2_data(8),
    q9 => iix2_data(9),
    q10 => iix2_data(10),
    q11 => iix2_data(11),
    q12 => iix2_data(12),
    q13 => iix2_data(13),
    q14 => iix2_data(14),
    q15 => iix2_data(15)
  );
  
  ------ counters ------

  ii_reg_index_counter: counter
  generic map(COUNT_WIDTH  => 4)
  port map(
    clk => clk,
    reset => ii_reg_index_count_reset,
    en => ii_reg_index_count_en,
    count => ii_reg_index
  );

  iix2_reg_index_counter: counter
  generic map(COUNT_WIDTH => 2)
  port map(
    clk => clk,
    reset => iix2_reg_index_count_reset,
    en => iix2_reg_index_count_en,
    count => iix2_reg_index
  );

  weakNode_counter: counter
  generic map(COUNT_WIDTH => 12)
  port map(
    clk => clk,
    reset => weakNode_count_reset,
    en => weakNode_count_en,
    count => weakNode_count
  );

  weak_counter: counter
  generic map(COUNT_WIDTH => 8)
  port map(
    clk => clk,
    reset => weak_count_reset,
    en => weak_count_en,
    count => weak_count
  );

  strongStage_counter: counter
  generic map(COUNT_WIDTH => 5)
  port map(
    clk => clk,
    reset => strongStage_count_reset,
    en => strongStage_count_en,
    count => strongStage_count
  );
 
  
  ---- misc state machine registers ----
  
  fail_reg0: process (clk, fail_reg_reset, fail_reg_latch)
  begin
    if (fail_reg_reset='1') then
      fail_reg <= (others=>'0');
    elsif (rising_edge(clk) and (fail_reg_latch='1')) then
      fail_reg <= fail_reg or (not face_detected_s); -- fail status persists until regesters are reset
    end if;
  end process;
  fail_out <= fail_reg;

  iix2_regLoad_DONE_reg: process (clk, iix2_regLoad_DONE_reset, iix2_regLoad_DONE_latch)
  begin
    if (iix2_regLoad_DONE_reset='1') then
      iix2_regLoad_DONE <= '0';
    elsif (rising_edge(clk) and (iix2_regLoad_DONE_latch='1')) then
      iix2_regLoad_DONE <= '1';
    end if;
  end process;
  
  ------------ state machine flip flop ------

  process (clk, reset)
  begin
    if (reset='1') then
      current_state <= s_RESET;
    elsif (rising_edge(clk)) then
      current_state <= next_state;
    end if;
  end process;
  
  ------------ state machine combinational logic -------

 --ii_reg_address counts from 0 to 11
 --weakNode_count counts from 0 to 2912
 --weak_count counts from 1 to weak_stage_num ... max=211
 --strongStage_count counts from 0 to 24

  rect_SM: process (current_state, cascade_start, weak_stage_num, weakNode_count, weak_count, ii_reg_index, iix2_reg_index, iix2_regLoad_DONE)
  begin
 
    en_var_norm0 <= '0';
    subwindow_reset <= '0';
    en_strongAccum0 <= '0';
    ii_reg_we0 <= '0';
    ii_reg_index_count_en <= '0';
    ii_reg_index_count_reset <= '0';
    iix2_reg_we0 <= '0';
    iix2_reg_index_count_en <= '0';
    iix2_reg_index_count_reset <= '0';
    weakNode_count_en <= '0';
    weakNode_count_reset <= '0';
    weak_count_en <= '0';
    weak_count_reset <= '0';
    strongStage_count_en <= '0';
    strongStage_count_reset <= '0';
    ii_rdaddress_mux_sel <= '0';
    cascade_done <= '0';
    fail_reg_latch <= '0';
    fail_reg_reset <= '0';
    iix2_regLoad_DONE_latch <= '0';
    iix2_regLoad_DONE_reset <= '0';
    
    case current_state is
      when s_RESET => -- reset
        subwindow_reset <= '1';
        ii_reg_index_count_reset   <= '1';
        iix2_reg_index_count_reset <= '1';
        weakNode_count_reset       <= '1';
        weak_count_reset           <= '1';
        strongStage_count_reset    <= '1';
        fail_reg_reset             <= '1';
        iix2_regLoad_DONE_reset    <= '1';
        if (cascade_start='1') then
          next_state <= s_latch_ROM;
        else
          next_state <= s_RESET;
        end if;
        
      -- new weak node; must load new classifier parameters
      when s_latch_ROM =>
        -- setup classifer ROM rdaddress
        next_state <= s_latch_RAM_address;
        
      -- setup time for ii buffer rdaddress; generated from address decoders
      when s_latch_RAM_address =>
        if (iix2_regLoad_DONE='0') then
          ii_rdaddress_mux_sel <= '1';-- setup ii rdaddress for subwindow corner values first
          next_state <= s_latch_iix2_reg;
        else 
          --ii_rdaddress_mux_sel <= '0'; -- setup ii rdaddress for subwindow feature rectangle values second
          next_state <= s_latch_ii_reg;
        end if;
        
      -- latch ii and iix2 corner values into corner registers
      -- note that the ii and iix2 corner values share the same address and are latched at the same time
      when s_latch_iix2_reg =>
        ii_rdaddress_mux_sel <= '1';
        iix2_reg_we0 <= '1';
        if (iix2_reg_index = std_logic_vector(to_unsigned(3,2))) then -- 4 corner register values latched
          en_var_norm0 <= '1'; -- start variance norm calculation once corner registers are latched
          iix2_regLoad_DONE_latch <= '1';
          next_state <= s_latch_RAM_address;
        else
          iix2_reg_index_count_en <= '1'; -- inc ii and iix2 register2 index
          next_state <= s_latch_RAM_address;
        end if;
   
      -- latch ii rectangle values into registers
      when s_latch_ii_reg =>
        en_var_norm0 <= '1'; -- variance norm calculation since sqrt() entity has a multi-cycle delay
        ii_reg_we0 <= '1';
        if (ii_reg_index = std_logic_vector(to_unsigned(11,4))) then -- 12 rectangle feature register values latched
          next_state <= s_latch_strongAccum;
        else
          ii_reg_index_count_en <= '1';
          next_state <= s_latch_RAM_address;
        end if;
   
      -- latch the strong accumulator when all register values are loaded;
      -- subwindow modules only require a sincle clock cycle to calculate rectangle features and select a value from the tree mux
      when s_latch_strongAccum =>
        en_strongAccum0 <= '1';
        ii_reg_index_count_reset <= '1';
        if (unsigned(weak_count)<(unsigned(weak_stage_num)-to_unsigned(1,12))) then -- continue to process current weak stage
          weakNode_count_en <= '1';
          weak_count_en <= '1';
          next_state <= s_latch_ROM;
        else      -- if at end if weak stage, latch stongAccum register and then proceed to check strong threshold conditions
          next_state <= s_strongCompare;
        end if;
   
      -- latch the result of the strong stage in fail_reg
      when s_strongCompare =>
        if (unsigned(weakNode_count)<to_unsigned(2911,12)) then -- full cascade not complete
          weakNode_count_en <= '1';
          subwindow_reset <= '1';
          fail_reg_latch <= '1';
          weak_count_reset <= '1';
          strongStage_count_en <= '1';
          next_state <= s_latch_ROM;
        else                         -- cascade calculations complete
          fail_reg_latch <= '1'; -- latch final result of the cascade
          next_state <= s_flagDone;
        end if;
   
      -- flag top level that cascade is done and log facebox data
      when s_flagDone =>
        cascade_done <= '1'; -- make sure that this flag is asserted for only one cycle such that duplicae rectangles are not logged by facebox
        next_state <= s_DONE;
   
      when s_DONE => 
        next_state <= s_DONE; -- stay here and only reset when top level flags a reset
   
    end case;
  end process;
  
  ---- Pixel offset for subwindow scaning functionality ----
  -- generates the base subwindow0 pixel address relative to the integral image dimentions
  pixel_offset0: pixel_offset
  port map(
      mem_state => mem_state, -- determines address offset for integral image read
      x_pos_subwin => x_pos_subwin0, -- range from 0 to II_WIDTH-1 = 0 to 38
      y_pos_subwin => y_pos_subwin0, -- range from 0 to II_HEIGHT-1 = 0 to 58
      width_ii => std_logic_vector(II_WIDTH), -- width of integral image
      p_offset => p_offset0);

  ---- Integral Image Address Decoder ----
  -- generate addresses relative to subwindow0 to register rectangle feature values
  ii_address_decoder0: ii_address_decoder
  port map(
    ii_reg_index => ii_reg_index,
    width_ii => std_logic_vector(II_WIDTH),
    p_offset => p_offset0,
    x_rect0 => x_rect0,
    x_rect1 => x_rect1,
    x_rect2 => x_rect2,
    y_rect0 => y_rect0,
    y_rect1 => y_rect1,
    y_rect2 => y_rect2,
    w_rect0 => w_rect0,
    w_rect1 => w_rect1,
    w_rect2 => w_rect2,
    h_rect0 => h_rect0,
    h_rect1 => h_rect1,
    h_rect2 => h_rect2,
    ii_address => ii_address0);
  
  ---- Integral Image RAM Address MUX ----
  ii_ram_addr_mux: process (ii_rdaddress_mux_sel, ii_address0, iix2_address0)
  begin
    if(ii_rdaddress_mux_sel='1') then 
      ii_address_mux0 <= iix2_address0; -- pass iix2 address to ii read address
    else 
      ii_address_mux0 <= ii_address0; -- pass ii address to ii read address
    end if;
  end process;
  
  ---- Integral Image Address Decoder ----
  -- generate addresses relative to subwindow0 to register subwindow corner values
  iix2_address_decoder0: iix2_address_decoder
  port map(
    iix2_reg_index => iix2_reg_index,
    width_ii => std_logic_vector(II_WIDTH),
    p_offset => p_offset0,
    iix2_address => iix2_address0);
  
  
  ---- Strong Thresh ROM ----
   -- stores the stong threshold for strong stage comparison
   -- 25 strong theshold stages ... values range from -1290 to -766 ... 12 bit signed
   -- max address = 25-1 ... for addressing from 0 to (25-1) ... 5 bit unsigned address width
  stongThresh_rom: ram 
  generic map (ADDR_WIDTH => 5,DATA_WIDTH => 12,
    MAX_PRELOAD_ADDRESS => (25-1),
    MEM_FILE_NAME => "strongThresh.txt",
    MIF_FILE_NAME => "strongThresh.mif")
  port map (data => (others=>'0'),rdaddress => strongStage_count,
    rdclock => clk_memRead,wraddress => (others=>'0'),
    wrclock => clk,we => '0',re => '1',q => strong_thresh);

  ---- Weak Stages Num ROM ---- 
   -- specifies the number of weak stages in the current strong stage calculation
   -- 25 strong theshold stages ... weak stage number values range from 9 to 211 ... 8 bit unsigned
   -- max address = 25-1 ... for addressing from 0 to (25-1) ... 5 bit unsigned address width
  weakStageNum_rom: ram 
  generic map (ADDR_WIDTH => 5,DATA_WIDTH => 8,
    MAX_PRELOAD_ADDRESS => (25-1),
    MEM_FILE_NAME => "weakStageNum.txt",
    MIF_FILE_NAME => "weakStageNum.mif")
  port map (data => (others=>'0'),rdaddress => strongStage_count,
    rdclock => clk_memRead,wraddress => (others=>'0'),
    wrclock => clk,we => '0',re => '1',q => weak_stage_num);

  ---- Weak Node ROM ----
   -- stores classifier cascade parameters relivent to the weak node count
   -- 2913 weak nodes ... 12 bit unsigned address width
   -- max address = 2913-1 ... for addressing from 0 to (2913-1) 
   -- weight values range from -4096 to 12288 ... 15 bit signed data width
   -- rectangle x,y,w,h values range from 0 to 23 ... 5 bit unsigned data width
   -- left tree values range from ___ to ___ ... 14 bit signed data width
   -- right tree values range from ___ to ___ ... 14 bit signed data width
   -- weak tree threshold values range from -1647 to 2705 ... 13 bit signed
  weight0_rom: ram 
  generic map (ADDR_WIDTH => 12,DATA_WIDTH => 15,
    MAX_PRELOAD_ADDRESS => (2913-1),
    MEM_FILE_NAME => "weight0.txt",
    MIF_FILE_NAME => "weight0.mif")
  port map (data => (others=>'0'),rdaddress => weakNode_count,
    rdclock => clk_memRead,wraddress => (others=>'0'),
    wrclock => clk,we => '0',re => '1',q => weight_rect0);

  weight1_rom: ram 
  generic map (ADDR_WIDTH => 12,DATA_WIDTH => 15,
    MAX_PRELOAD_ADDRESS => (2913-1),
    MEM_FILE_NAME => "weight1.txt",
    MIF_FILE_NAME => "weight1.mif")
  port map (data => (others=>'0'),rdaddress => weakNode_count,
    rdclock => clk_memRead,wraddress => (others=>'0'),
    wrclock => clk,we => '0',re => '1',q => weight_rect1);
   
  weight2_rom: ram 
  generic map (ADDR_WIDTH => 12,DATA_WIDTH => 15,
    MAX_PRELOAD_ADDRESS => (2913-1),
    MEM_FILE_NAME => "weight2.txt",
    MIF_FILE_NAME => "weight2.mif")
  port map (data => (others=>'0'),rdaddress => weakNode_count,
    rdclock => clk_memRead,wraddress => (others=>'0'),
    wrclock => clk,we => '0',re => '1',q => weight_rect2);
   
  x_rect0_rom: ram 
  generic map (ADDR_WIDTH => 12,DATA_WIDTH => 5,
    MAX_PRELOAD_ADDRESS => (2913-1),
    MEM_FILE_NAME => "x_rect0.txt",
    MIF_FILE_NAME => "x_rect0.mif")
  port map (data => (others=>'0'),rdaddress => weakNode_count,
    rdclock => clk_memRead,wraddress => (others=>'0'),
    wrclock => clk,we => '0',re => '1',q => x_rect0);
   
  x_rect1_rom: ram 
  generic map (ADDR_WIDTH => 12,DATA_WIDTH => 5,
    MAX_PRELOAD_ADDRESS => (2913-1),
    MEM_FILE_NAME => "x_rect1.txt",
    MIF_FILE_NAME => "x_rect1.mif")
  port map (data => (others=>'0'),rdaddress => weakNode_count,
    rdclock => clk_memRead,wraddress => (others=>'0'),
    wrclock => clk,we => '0',re => '1',q => x_rect1);
   
  x_rect2_rom: ram 
  generic map (ADDR_WIDTH => 12,DATA_WIDTH => 5,
    MAX_PRELOAD_ADDRESS => (2913-1),
    MEM_FILE_NAME => "x_rect2.txt",
    MIF_FILE_NAME => "x_rect2.mif")
  port map (data => (others=>'0'),rdaddress => weakNode_count,
    rdclock => clk_memRead,wraddress => (others=>'0'),
    wrclock => clk,we => '0',re => '1',q => x_rect2);
   
  y_rect0_rom: ram 
  generic map (ADDR_WIDTH => 12,DATA_WIDTH => 5,
    MAX_PRELOAD_ADDRESS => (2913-1),
    MEM_FILE_NAME => "y_rect0.txt",
    MIF_FILE_NAME => "y_rect0.mif")
  port map (data => (others=>'0'),rdaddress => weakNode_count,
    rdclock => clk_memRead,wraddress => (others=>'0'),
    wrclock => clk,we => '0',re => '1',q => y_rect0);
   
  y_rect1_rom: ram 
  generic map (ADDR_WIDTH => 12,DATA_WIDTH => 5,
    MAX_PRELOAD_ADDRESS => (2913-1),
    MEM_FILE_NAME => "y_rect1.txt",
    MIF_FILE_NAME => "y_rect1.mif")
  port map (data => (others=>'0'),rdaddress => weakNode_count,
    rdclock => clk_memRead,wraddress => (others=>'0'),
    wrclock => clk,we => '0',re => '1',q => y_rect1);
   
  y_rect2_rom: ram 
  generic map (ADDR_WIDTH => 12,DATA_WIDTH => 5,
    MAX_PRELOAD_ADDRESS => (2913-1),
    MEM_FILE_NAME => "y_rect2.txt",
    MIF_FILE_NAME => "y_rect2.mif")
  port map (data => (others=>'0'),rdaddress => weakNode_count,
    rdclock => clk_memRead,wraddress => (others=>'0'),
    wrclock => clk,we => '0',re => '1',q => y_rect2);
   
  w_rect0_rom: ram 
  generic map (ADDR_WIDTH => 12,DATA_WIDTH => 5,
    MAX_PRELOAD_ADDRESS => (2913-1),
    MEM_FILE_NAME => "w_rect0.txt",
    MIF_FILE_NAME => "w_rect0.mif")
  port map (data => (others=>'0'),rdaddress => weakNode_count,
    rdclock => clk_memRead,wraddress => (others=>'0'),
    wrclock => clk,we => '0',re => '1',q => w_rect0);
   
  w_rect1_rom: ram 
  generic map (ADDR_WIDTH => 12,DATA_WIDTH => 5,
    MAX_PRELOAD_ADDRESS => (2913-1),
    MEM_FILE_NAME => "w_rect1.txt",
    MIF_FILE_NAME => "w_rect1.mif")
  port map (data => (others=>'0'),rdaddress => weakNode_count,
    rdclock => clk_memRead,wraddress => (others=>'0'),
    wrclock => clk,we => '0',re => '1',q => w_rect1);
   
  w_rect2_rom: ram 
  generic map (ADDR_WIDTH => 12,DATA_WIDTH => 5,
    MAX_PRELOAD_ADDRESS => (2913-1),
    MEM_FILE_NAME => "w_rect2.txt",
    MIF_FILE_NAME => "w_rect2.mif")
  port map (data => (others=>'0'),rdaddress => weakNode_count,
    rdclock => clk_memRead,wraddress => (others=>'0'),
    wrclock => clk,we => '0',re => '1',q => w_rect2);
   
  h_rect0_rom: ram 
  generic map (ADDR_WIDTH => 12,DATA_WIDTH => 5,
    MAX_PRELOAD_ADDRESS => (2913-1),
    MEM_FILE_NAME => "h_rect0.txt",
    MIF_FILE_NAME => "h_rect0.mif")
  port map (data => (others=>'0'),rdaddress => weakNode_count,
    rdclock => clk_memRead,wraddress => (others=>'0'),
    wrclock => clk,we => '0',re => '1',q => h_rect0);
   
  h_rect1_rom: ram 
  generic map (ADDR_WIDTH => 12,DATA_WIDTH => 5,
    MAX_PRELOAD_ADDRESS => (2913-1),
    MEM_FILE_NAME => "h_rect1.txt",
    MIF_FILE_NAME => "h_rect1.mif")
  port map (data => (others=>'0'),rdaddress => weakNode_count,
    rdclock => clk_memRead,wraddress => (others=>'0'),
    wrclock => clk,we => '0',re => '1',q => h_rect1);
   
  h_rect2_rom: ram 
  generic map (ADDR_WIDTH => 12,DATA_WIDTH => 5,
    MAX_PRELOAD_ADDRESS => (2913-1),
    MEM_FILE_NAME => "h_rect2.txt",
    MIF_FILE_NAME => "h_rect2.mif")
  port map (data => (others=>'0'),rdaddress => weakNode_count,
    rdclock => clk_memRead,wraddress => (others=>'0'),
    wrclock => clk,we => '0',re => '1',q => h_rect2);
   
  left_tree_rom: ram 
  generic map (ADDR_WIDTH => 12,DATA_WIDTH => 14,
    MAX_PRELOAD_ADDRESS => (2913-1),
    MEM_FILE_NAME => "left_tree.txt",
    MIF_FILE_NAME => "left_tree.mif")
  port map (data => (others=>'0'),rdaddress => weakNode_count,
    rdclock => clk_memRead,wraddress => (others=>'0'),
    wrclock => clk,we => '0',re => '1',q => left_tree);
   
  right_tree_rom: ram 
  generic map (ADDR_WIDTH => 12,DATA_WIDTH => 14,
    MAX_PRELOAD_ADDRESS => (2913-1),
    MEM_FILE_NAME => "right_tree.txt",
    MIF_FILE_NAME => "right_tree.mif")
  port map (data => (others=>'0'),rdaddress => weakNode_count,
    rdclock => clk_memRead,wraddress => (others=>'0'),
    wrclock => clk,we => '0',re => '1',q => right_tree);
   
  weakThresh_rom: ram 
  generic map (ADDR_WIDTH => 12,DATA_WIDTH => 13,
    MAX_PRELOAD_ADDRESS => (2913-1),
    MEM_FILE_NAME => "weakThresh.txt",
    MIF_FILE_NAME => "weakThresh.mif")
  port map (data => (others=>'0'),rdaddress => weakNode_count,
    rdclock => clk_memRead,wraddress => (others=>'0'),
    wrclock => clk,we => '0',re => '1',q => weak_thresh);
  
  -- parallel subwindows
  subwindow0: subwindow
  port map(
    reset => subwindow_reset,
    clk => clk,
    en_strongAccum => en_strongAccum0,
    en_var_norm => en_var_norm0,
    left_tree => left_tree,
    right_tree => right_tree,
    weak_thresh => weak_thresh,
    strong_thresh => strong_thresh,
    w0 => weight_rect0,
    w1 => weight_rect1,
    w2 => weight_rect2,
    ii_reg_we => ii_reg_we0,
    ii_reg_address => ii_reg_index,
    ii_data => ii_data(0),
    iix2_reg_we => iix2_reg_we0,
    iix2_reg_index => iix2_reg_index,
    iix2_data => iix2_data(0),
    detection => face_detected_s(0)
  );
  
  subwindow1: subwindow
  port map(
    reset => subwindow_reset,
    clk => clk,
    en_strongAccum => en_strongAccum0,
    en_var_norm => en_var_norm0,
    left_tree => left_tree,
    right_tree => right_tree,
    weak_thresh => weak_thresh,
    strong_thresh => strong_thresh,
    w0 => weight_rect0,
    w1 => weight_rect1,
    w2 => weight_rect2,
    ii_reg_we => ii_reg_we0,
    ii_reg_address => ii_reg_index,
    ii_data => ii_data(1),
    iix2_reg_we => iix2_reg_we0,
    iix2_reg_index => iix2_reg_index,
    iix2_data => iix2_data(1),
    detection => face_detected_s(1)
  );
  
  subwindow2: subwindow
  port map(
    reset => subwindow_reset,
    clk => clk,
    en_strongAccum => en_strongAccum0,
    en_var_norm => en_var_norm0,
    left_tree => left_tree,
    right_tree => right_tree,
    weak_thresh => weak_thresh,
    strong_thresh => strong_thresh,
    w0 => weight_rect0,
    w1 => weight_rect1,
    w2 => weight_rect2,
    ii_reg_we => ii_reg_we0,
    ii_reg_address => ii_reg_index,
    ii_data => ii_data(2),
    iix2_reg_we => iix2_reg_we0,
    iix2_reg_index => iix2_reg_index,
    iix2_data => iix2_data(2),
    detection => face_detected_s(2)
  );
  
  subwindow3: subwindow
  port map(
    reset => subwindow_reset,
    clk => clk,
    en_strongAccum => en_strongAccum0,
    en_var_norm => en_var_norm0,
    left_tree => left_tree,
    right_tree => right_tree,
    weak_thresh => weak_thresh,
    strong_thresh => strong_thresh,
    w0 => weight_rect0,
    w1 => weight_rect1,
    w2 => weight_rect2,
    ii_reg_we => ii_reg_we0,
    ii_reg_address => ii_reg_index,
    ii_data => ii_data(3),
    iix2_reg_we => iix2_reg_we0,
    iix2_reg_index => iix2_reg_index,
    iix2_data => iix2_data(3),
    detection => face_detected_s(3)
  );
  
  subwindow4: subwindow
  port map(
    reset => subwindow_reset,
    clk => clk,
    en_strongAccum => en_strongAccum0,
    en_var_norm => en_var_norm0,
    left_tree => left_tree,
    right_tree => right_tree,
    weak_thresh => weak_thresh,
    strong_thresh => strong_thresh,
    w0 => weight_rect0,
    w1 => weight_rect1,
    w2 => weight_rect2,
    ii_reg_we => ii_reg_we0,
    ii_reg_address => ii_reg_index,
    ii_data => ii_data(4),
    iix2_reg_we => iix2_reg_we0,
    iix2_reg_index => iix2_reg_index,
    iix2_data => iix2_data(4),
    detection => face_detected_s(4)
  );
  
  subwindow5: subwindow
  port map(
    reset => subwindow_reset,
    clk => clk,
    en_strongAccum => en_strongAccum0,
    en_var_norm => en_var_norm0,
    left_tree => left_tree,
    right_tree => right_tree,
    weak_thresh => weak_thresh,
    strong_thresh => strong_thresh,
    w0 => weight_rect0,
    w1 => weight_rect1,
    w2 => weight_rect2,
    ii_reg_we => ii_reg_we0,
    ii_reg_address => ii_reg_index,
    ii_data => ii_data(5),
    iix2_reg_we => iix2_reg_we0,
    iix2_reg_index => iix2_reg_index,
    iix2_data => iix2_data(5),
    detection => face_detected_s(5)
  );
  
  subwindow6: subwindow
  port map(
    reset => subwindow_reset,
    clk => clk,
    en_strongAccum => en_strongAccum0,
    en_var_norm => en_var_norm0,
    left_tree => left_tree,
    right_tree => right_tree,
    weak_thresh => weak_thresh,
    strong_thresh => strong_thresh,
    w0 => weight_rect0,
    w1 => weight_rect1,
    w2 => weight_rect2,
    ii_reg_we => ii_reg_we0,
    ii_reg_address => ii_reg_index,
    ii_data => ii_data(6),
    iix2_reg_we => iix2_reg_we0,
    iix2_reg_index => iix2_reg_index,
    iix2_data => iix2_data(6),
    detection => face_detected_s(6)
  );
  
  subwindow7: subwindow
  port map(
    reset => subwindow_reset,
    clk => clk,
    en_strongAccum => en_strongAccum0,
    en_var_norm => en_var_norm0,
    left_tree => left_tree,
    right_tree => right_tree,
    weak_thresh => weak_thresh,
    strong_thresh => strong_thresh,
    w0 => weight_rect0,
    w1 => weight_rect1,
    w2 => weight_rect2,
    ii_reg_we => ii_reg_we0,
    ii_reg_address => ii_reg_index,
    ii_data => ii_data(7),
    iix2_reg_we => iix2_reg_we0,
    iix2_reg_index => iix2_reg_index,
    iix2_data => iix2_data(7),
    detection => face_detected_s(7)
  );
  
  subwindow8: subwindow
  port map(
    reset => subwindow_reset,
    clk => clk,
    en_strongAccum => en_strongAccum0,
    en_var_norm => en_var_norm0,
    left_tree => left_tree,
    right_tree => right_tree,
    weak_thresh => weak_thresh,
    strong_thresh => strong_thresh,
    w0 => weight_rect0,
    w1 => weight_rect1,
    w2 => weight_rect2,
    ii_reg_we => ii_reg_we0,
    ii_reg_address => ii_reg_index,
    ii_data => ii_data(8),
    iix2_reg_we => iix2_reg_we0,
    iix2_reg_index => iix2_reg_index,
    iix2_data => iix2_data(8),
    detection => face_detected_s(8)
  );
  
  subwindow9: subwindow
  port map(
    reset => subwindow_reset,
    clk => clk,
    en_strongAccum => en_strongAccum0,
    en_var_norm => en_var_norm0,
    left_tree => left_tree,
    right_tree => right_tree,
    weak_thresh => weak_thresh,
    strong_thresh => strong_thresh,
    w0 => weight_rect0,
    w1 => weight_rect1,
    w2 => weight_rect2,
    ii_reg_we => ii_reg_we0,
    ii_reg_address => ii_reg_index,
    ii_data => ii_data(9),
    iix2_reg_we => iix2_reg_we0,
    iix2_reg_index => iix2_reg_index,
    iix2_data => iix2_data(9),
    detection => face_detected_s(9)
  );
  
  subwindow10: subwindow
  port map(
    reset => subwindow_reset,
    clk => clk,
    en_strongAccum => en_strongAccum0,
    en_var_norm => en_var_norm0,
    left_tree => left_tree,
    right_tree => right_tree,
    weak_thresh => weak_thresh,
    strong_thresh => strong_thresh,
    w0 => weight_rect0,
    w1 => weight_rect1,
    w2 => weight_rect2,
    ii_reg_we => ii_reg_we0,
    ii_reg_address => ii_reg_index,
    ii_data => ii_data(10),
    iix2_reg_we => iix2_reg_we0,
    iix2_reg_index => iix2_reg_index,
    iix2_data => iix2_data(10),
    detection => face_detected_s(10)
  );
  
  subwindow11: subwindow
  port map(
    reset => subwindow_reset,
    clk => clk,
    en_strongAccum => en_strongAccum0,
    en_var_norm => en_var_norm0,
    left_tree => left_tree,
    right_tree => right_tree,
    weak_thresh => weak_thresh,
    strong_thresh => strong_thresh,
    w0 => weight_rect0,
    w1 => weight_rect1,
    w2 => weight_rect2,
    ii_reg_we => ii_reg_we0,
    ii_reg_address => ii_reg_index,
    ii_data => ii_data(11),
    iix2_reg_we => iix2_reg_we0,
    iix2_reg_index => iix2_reg_index,
    iix2_data => iix2_data(11),
    detection => face_detected_s(11)
  );
  
  subwindow12: subwindow
  port map(
    reset => subwindow_reset,
    clk => clk,
    en_strongAccum => en_strongAccum0,
    en_var_norm => en_var_norm0,
    left_tree => left_tree,
    right_tree => right_tree,
    weak_thresh => weak_thresh,
    strong_thresh => strong_thresh,
    w0 => weight_rect0,
    w1 => weight_rect1,
    w2 => weight_rect2,
    ii_reg_we => ii_reg_we0,
    ii_reg_address => ii_reg_index,
    ii_data => ii_data(12),
    iix2_reg_we => iix2_reg_we0,
    iix2_reg_index => iix2_reg_index,
    iix2_data => iix2_data(12),
    detection => face_detected_s(12)
  );
  
  subwindow13: subwindow
  port map(
    reset => subwindow_reset,
    clk => clk,
    en_strongAccum => en_strongAccum0,
    en_var_norm => en_var_norm0,
    left_tree => left_tree,
    right_tree => right_tree,
    weak_thresh => weak_thresh,
    strong_thresh => strong_thresh,
    w0 => weight_rect0,
    w1 => weight_rect1,
    w2 => weight_rect2,
    ii_reg_we => ii_reg_we0,
    ii_reg_address => ii_reg_index,
    ii_data => ii_data(13),
    iix2_reg_we => iix2_reg_we0,
    iix2_reg_index => iix2_reg_index,
    iix2_data => iix2_data(13),
    detection => face_detected_s(13)
  );
  
  subwindow14: subwindow
  port map(
    reset => subwindow_reset,
    clk => clk,
    en_strongAccum => en_strongAccum0,
    en_var_norm => en_var_norm0,
    left_tree => left_tree,
    right_tree => right_tree,
    weak_thresh => weak_thresh,
    strong_thresh => strong_thresh,
    w0 => weight_rect0,
    w1 => weight_rect1,
    w2 => weight_rect2,
    ii_reg_we => ii_reg_we0,
    ii_reg_address => ii_reg_index,
    ii_data => ii_data(14),
    iix2_reg_we => iix2_reg_we0,
    iix2_reg_index => iix2_reg_index,
    iix2_data => iix2_data(14),
    detection => face_detected_s(14)
  );
  
  subwindow15: subwindow
  port map(
    reset => subwindow_reset,
    clk => clk,
    en_strongAccum => en_strongAccum0,
    en_var_norm => en_var_norm0,
    left_tree => left_tree,
    right_tree => right_tree,
    weak_thresh => weak_thresh,
    strong_thresh => strong_thresh,
    w0 => weight_rect0,
    w1 => weight_rect1,
    w2 => weight_rect2,
    ii_reg_we => ii_reg_we0,
    ii_reg_address => ii_reg_index,
    ii_data => ii_data(15),
    iix2_reg_we => iix2_reg_we0,
    iix2_reg_index => iix2_reg_index,
    iix2_data => iix2_data(15),
    detection => face_detected_s(15)
  );
  
  ---- ii and iix2 address ouput assignments
  ii_rdaddress <= ii_address_mux0(12 downto 4);
  iix2_rdaddress <= iix2_address0(12 downto 4);
  
  ---- Classifier Cascade Done Flag ----
  done <= cascade_done;
  
end structure;
