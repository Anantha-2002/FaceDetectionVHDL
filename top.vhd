-- Project: Viola Jones Face Detection on FPGA : 4/8/2016
-- Project done using Quartus II 15.1 and tested on DE2-115
--
-- Contributing Members:
--   Dr. Cristinel Ababei
--   Peter Irgens
--   Curtis Bader
--   Theresa Le
--   Devansh Saxena
-- 
-- System Specifications
--   Capture Resolution: 320x240
--   Scales: 1-4
-- 
-- General Theory of Opperation:
--  The top level of this design consists of a number of major components.
--  This includes:
--   (1) top level state machine and misc. behavioral logic
--   (2) ov7670 camera controller and capture entities
--   (3) image frame buffer
--   (4) integral image frame buffers
--   (5) integral image generator
--   (6) parallel subwindow top level
--   (7) faceBox record container/ box generator
--   (8) VGA related entities
--  
--  The top level state machine coordinates the sequential execution from image capture to drawing boxes on detected faces.
--  ov7670 entities are responsible for configuring the complex register set of the ov7670 camera peripheral and capturing frames from the camera.
--  The image frame buffer stores the current image that is to be processed by the face detection subsystems and  is overwritten with red boxes where faces are detected.
--  The integral image generator converts portions of the original color image to greyscale and then to integral image (ii) and integral image squared (iix2) format 
--   which is then stored in respective integral image buffers.
--  Each integral image (ii and iix2) is duplicated such that, since the high bit width dual port RAM implementation is not addressable by individual words, 16 words plus the
--   adjacent 16 words in the integral image can be read at the same time such that any 16 word chunk can be fed to the subwindow as necessary in the same memory read operation.
--  If this was not implemented, the first 16 words would need to be registered and then the second 16 words would then be read on a second read cycle, thus taking two memory read cycles to
--   facilitate one lump data transfer to 16 parallel subwindows.
--  The current implementatoin utilizes redundant embedded RAM for integral images, but facilitates less clock cycles for one full 16 subwindow memory read operation.
--  It is important to minimize the number of clock cycles for subwindow memory read operations since this eats up most of the systems total execution time.
--  Note that future optimizations should revolve around speeding up these memory read operations.
--  The parallel subwindow top level is a container for the the state machine process, global classifier cascade parameters, and the 16 subwindows that enable
--   concurrent evaluation of feature arithmatic.
--  Failure flags are asserted from the subwindow entities if non faces are detected within the respective subwindow locations and if at least one subwindow passed does not
--   assert a failure then the detection result is logged by faceBox.
--  FaceBox has a dual port RAM entity that facilitates storage of the current image scale, coordinate of the top left corner of subwindow0 and the detection result of all 16 subwindows.
--  FaceBox also contains a state machine process that writes red boxes to the image buffer for logged face detections. This process is executed once all images are processed in the image pyramid.
--  
--  
--  See code for more details.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.component_package.all;

entity top is
  Port ( 
    clk_50 : in  STD_LOGIC;
    slide_sw_RESET : in  STD_LOGIC; -- reset the whole animal; SW17
    slide_sw_resend_reg_values : in  STD_LOGIC; -- rewrite all OV7670's registers; SW16
    slide_sw_capture_mode : in STD_LOGIC; -- '0'= video mode, '1'=button capture mode; sw15
    btn_capture : in STD_LOGIC; -- logic '0' input when pressed; KEY0
    
    LED_config_finished : out STD_LOGIC; -- lets us know camera registers are now written; -- LEDR1
    LED_dll_locked : out STD_LOGIC; -- PLL is locked now; -- LEDR0
    
    vga_hsync : out  STD_LOGIC;
    vga_vsync : out  STD_LOGIC;
    vga_r : out  STD_LOGIC_VECTOR(7 downto 0);
    vga_g : out  STD_LOGIC_VECTOR(7 downto 0);
    vga_b : out  STD_LOGIC_VECTOR(7 downto 0);
    vga_blank_N : out  STD_LOGIC;
    vga_sync_N : out  STD_LOGIC;
    vga_CLK : out  STD_LOGIC;
    
    ov7670_pclk : in  STD_LOGIC;
    ov7670_xclk : out STD_LOGIC;
    ov7670_vsync : in  STD_LOGIC;
    ov7670_href : in  STD_LOGIC;
    ov7670_data : in  STD_LOGIC_VECTOR(7 downto 0);
    ov7670_sioc : out STD_LOGIC;
    ov7670_siod : inout STD_LOGIC;
    ov7670_pwdn : out STD_LOGIC;
    ov7670_reset : out STD_LOGIC;
    
    ii_gen_done  : out STD_LOGIC; -- GPIO[35], debug
    subwin_done  : out STD_LOGIC; -- GPIO[29], debug
    faceBox_done : out STD_LOGIC; -- GPIO[27], debug
    
    measure_performance : out STD_LOGIC -- GPIO[34], toggles after every faceBox process completion ... so half period on o-scope is indicates the processed FPS
  );
end top;

architecture structure of top is
  
  -- constants
  constant II_WIDTH : unsigned(5 downto 0) := to_unsigned(39,6);
  constant II_HEIGHT : unsigned(5 downto 0) := to_unsigned(59,6);
  
  -- clock signals
  signal clk_50_camera : std_logic;
  signal clk_25_vga : std_logic;
  signal clk_sys : std_logic;
  signal clk_iigen : std_logic;
  signal clk_faceBox : std_logic;
  signal dll_locked : std_logic;
  
  -- user controls;
  signal reset : std_logic;
  signal resend_reg_values : std_logic;
  signal capture_mode : std_logic;
  signal capture : std_logic;
  
  -- buffer signals
  signal buff_1A_mux_sel : std_logic;
  signal buff_1B_mux_sel : std_logic;
  signal address_buff_1A : std_logic_vector(16 downto 0);
  signal address_buff_1B : std_logic_vector(16 downto 0);
  signal clk_buff_1A : std_logic;
  signal clk_buff_1B : std_logic;
  signal rddata_buff_1A : std_logic_vector(11 downto 0);
  signal rddata_buff_1B : std_logic_vector(11 downto 0);
  
  signal wren_buff_2A : std_logic;
  signal address_buff_2A : std_logic_vector(12 downto 0);
  signal wrdata_buff_2A : std_logic_vector(19 downto 0); 
  signal rddata_buff_2A : std_logic_vector(19 downto 0);
  signal address_buff_2B : std_logic_vector(8 downto 0);
  signal address_buff_2B_prime : std_logic_vector(8 downto 0);
  signal rddata_buff_2B : std_logic_vector((16*20*2)-1 downto 0); -- 16 subwindows, 20bit wide words, 2 ram entities connected
  
  signal wren_buff_3A : std_logic;
  signal address_buff_3A : std_logic_vector(12 downto 0);
  signal wrdata_buff_3A : std_logic_vector(27 downto 0); 
  signal rddata_buff_3A : std_logic_vector(27 downto 0);
  signal address_buff_3B : std_logic_vector(8 downto 0);
  signal address_buff_3B_prime : std_logic_vector(8 downto 0);
  signal rddata_buff_3B : std_logic_vector((16*28*2)-1 downto 0);-- 16 subwindows, 28bit wide words, 2 ram entities connected
  
  -- integral image related
  signal next_mem_state, mem_state : std_logic;
  signal next_ii_gen_x_base,  ii_gen_x_base : std_logic_vector(8 downto 0);
  signal next_ii_gen_y_base, ii_gen_y_base : std_logic_vector(7 downto 0);
  signal image_rdaddress_from_iigen : std_logic_vector(16 downto 0); -- when in ii_gen mode, rd address comes from ii_gen
  signal ii_gen_start_s : std_logic;
  signal ii_gen_reset_s : std_logic;
  signal ii_gen_done_s : std_logic;
  
  -- subwindow related
  signal subwin_fail_s : std_logic_vector(15 downto 0);
  signal subwin_any_fail : std_logic;
  signal subwin_all_fail :std_logic;
  signal next_subwin_x_base, subwin_x_base : std_logic_vector(8 downto 0);
  signal next_subwin_y_base, subwin_y_base : std_logic_vector(7 downto 0);
  signal next_subwin_x_base_offset,  subwin_x_base_offset : std_logic_vector(5 downto 0);
  signal next_subwin_y_base_offset,  subwin_y_base_offset : std_logic_vector(5 downto 0);
  signal subwin_x_pos : std_logic_vector(8 downto 0);
  signal subwin_y_pos : std_logic_vector(7 downto 0);
  signal subwin_start_s : std_logic;
  signal subwin_done_s : std_logic;
  signal subwin_reset_s : std_logic;
  
  -- RGB related
  signal red,green,blue : std_logic_vector(7 downto 0);
  signal activeArea : std_logic;
  signal nBlank     : std_logic;
  signal vSync      : std_logic;
  
  -- capture related
  signal take_snapshot : std_logic;
  signal image_wraddress_from_ov7670_capture : std_logic_vector(16 downto 0);
  signal image_wrdata_from_ov7670_capture : std_logic_vector(11 downto 0);
  signal image_wren_from_ov7670_capture : std_logic;
  signal ov7670_capture_busy : std_logic;
  
  -- faceBox related
  signal image_wraddress_from_faceBox : std_logic_vector(16 downto 0);
  signal image_wrdata_from_faceBox : std_logic_vector(11 downto 0);
  signal image_wren_from_faceBox: std_logic;
  signal faceBox_start_s : std_logic;
  signal faceBox_done_s : std_logic;
  signal faceBox_wren : std_logic;
  signal faceBox_reset_s : std_logic;
  
  -- VGA related
  signal image_rdaddress_from_addr_gen : std_logic_vector(16 downto 0); -- when in video mode, rd address comes from address_generator
  
  -- top level state machine
  type STATE_TYPE is (s_RESET,s_CAPTURE_start,s_CAPTURE,s_newScale_RESET,s_ii_gen_init,s_subwin_RESET,s_ii_gen_subwin_RESET, s_ii_gen_subwin, s_scale,s_faceBox_start,s_faceBox);--
  signal current_state,next_state   : STATE_TYPE;
  
  -- image size and position signals
  signal scale_count : std_logic_vector(3 downto 0);
  signal scale_count_en : std_logic;
  signal scale_count_reset : std_logic;
  signal width_scale_img: std_logic_vector(8 downto 0); -- assigned lut0
  signal height_scale_img: std_logic_vector(7 downto 0); -- assigned lut1
  
  -- scale image width lookup table
  type lut0 is array ( 0 to 8 ) of std_logic_vector(8 downto 0);
  constant my_lut0 : lut0 := ( std_logic_vector(to_unsigned(0, 9)), -- scale 0 not used
                               std_logic_vector(to_unsigned(320, 9)), 
                               std_logic_vector(to_unsigned(160, 9)),
                               std_logic_vector(to_unsigned(107, 9)),
                               std_logic_vector(to_unsigned(80, 9)),
                               std_logic_vector(to_unsigned(64, 9)),
                               std_logic_vector(to_unsigned(54, 9)),
                               std_logic_vector(to_unsigned(46, 9)),
                               std_logic_vector(to_unsigned(40, 9)) );
  
  -- scale image height lookup table
  type lut1 is array ( 0 to 8 ) of std_logic_vector(7 downto 0);
  constant my_lut1 : lut1 := ( std_logic_vector(to_unsigned(0, 8)), -- scale 0 not used
                               std_logic_vector(to_unsigned(240, 8)), 
                               std_logic_vector(to_unsigned(120, 8)),
                               std_logic_vector(to_unsigned(80, 8)),
                               std_logic_vector(to_unsigned(60, 8)),
                               std_logic_vector(to_unsigned(48, 8)),
                               std_logic_vector(to_unsigned(40, 8)),
                               std_logic_vector(to_unsigned(35, 8)),
                               std_logic_vector(to_unsigned(30, 8)) );
  
  signal measure_performance_reg : std_logic := '0';
  
begin
  
  -- inputs
  reset <= slide_sw_RESET;
  capture_mode <= slide_sw_capture_mode;
  capture <= not btn_capture; -- invert button assertion logic
  
  -- scale counter and associated height/width lookup tables
  scale_counter: process (clk_sys, scale_count_reset, scale_count_en)
    variable num: unsigned(3 downto 0) := to_unsigned(1,4);
  begin
    if (scale_count_reset='1') then
      num := to_unsigned(1,4); -- begin at scale=1
    elsif (rising_edge(clk_sys) and (scale_count_en='1')) then
      num := num + 1; -- increment to the next scale
    end if;
    scale_count <= std_logic_vector(num);
  end process;
  width_scale_img <= my_lut0(to_integer(unsigned(scale_count)));
  height_scale_img <= my_lut1(to_integer(unsigned(scale_count)));
  
  -- determine if subwindows all fail or only some fail
  any_fail_wide_OR : process(subwin_fail_s)
  begin
    subwin_any_fail <= subwin_fail_s(0) or subwin_fail_s(1) or subwin_fail_s(2) or subwin_fail_s(3) or 
                      subwin_fail_s(4) or subwin_fail_s(5) or subwin_fail_s(6) or subwin_fail_s(7) or 
                      subwin_fail_s(8) or subwin_fail_s(9) or subwin_fail_s(10) or subwin_fail_s(11) or 
                      subwin_fail_s(12) or subwin_fail_s(13) or subwin_fail_s(14) or subwin_fail_s(15);
  end process;
  
  all_fail_wide_AND : process(subwin_fail_s)
  begin
    subwin_all_fail <= subwin_fail_s(0) and subwin_fail_s(1) and subwin_fail_s(2) and subwin_fail_s(3) and 
                      subwin_fail_s(4) and subwin_fail_s(5) and subwin_fail_s(6) and subwin_fail_s(7) and 
                      subwin_fail_s(8) and subwin_fail_s(9) and subwin_fail_s(10) and subwin_fail_s(11) and 
                      subwin_fail_s(12) and subwin_fail_s(13) and subwin_fail_s(14) and subwin_fail_s(15);
  end process;
  
  -- TOP LEVEL STATE MACHINE
  
  ------------ state machine flip flop ------

  process (clk_sys, reset)
  begin
    if reset='1' then
      current_state <= s_RESET;
      mem_state <= '0';
      subwin_x_base_offset <= (others=>'0');
      subwin_y_base_offset <= (others=>'0');
      ii_gen_x_base <= (others=>'0');
      ii_gen_y_base <= (others=>'0');
      subwin_x_base <= (others=>'0');
      subwin_y_base <= (others=>'0');
    elsif rising_edge(clk_sys) then
      current_state <= next_state;
      mem_state <= next_mem_state;
      subwin_x_base_offset <= next_subwin_x_base_offset;
      subwin_y_base_offset <= next_subwin_y_base_offset;
      ii_gen_x_base <= next_ii_gen_x_base;
      ii_gen_y_base <= next_ii_gen_y_base;
      subwin_x_base <= next_subwin_x_base;
      subwin_y_base <= next_subwin_y_base;
    end if;
  end process;
  
  ------------ state machine combinational logic -------
  
  SM_TOP: process (current_state, take_snapshot, ii_gen_start_s, subwin_start_s, ii_gen_done_s, subwin_done_s, 
                   faceBox_start_s, faceBox_done_s, width_scale_img, height_scale_img, 
                   subwin_any_fail, subwin_all_fail, scale_count, ov7670_vsync, vsync, ov7670_capture_busy,
                   mem_state, subwin_x_base_offset, subwin_y_base_offset, ii_gen_x_base, ii_gen_y_base, subwin_x_base, subwin_y_base,
                   capture, capture_mode)
  begin
    
    buff_1A_mux_sel <= '0';
    buff_1B_mux_sel <= '0';
    subwin_reset_s <= '0';
    subwin_start_s <= '0';
    faceBox_start_s <= '0';
    faceBox_reset_s <= '0';
    ii_gen_start_s <= '0';
    ii_gen_reset_s <= '0';
    scale_count_reset <= '0';
    scale_count_en <= '0';
    take_snapshot <= '0';
    next_mem_state <= mem_state;
    next_subwin_x_base_offset <= subwin_x_base_offset;
    next_subwin_y_base_offset <= subwin_y_base_offset;
    next_ii_gen_x_base <= ii_gen_x_base;
    next_ii_gen_y_base <= ii_gen_y_base;
    next_subwin_x_base <= subwin_x_base;
    next_subwin_y_base <= subwin_y_base;
  
    case current_state is
      when s_RESET =>
        subwin_reset_s <= '1';
        faceBox_reset_s <= '1';
        scale_count_reset <= '1';
        ii_gen_reset_s <= '1';
        next_mem_state <= '0';
        next_subwin_x_base_offset <= (others=>'0');
        next_subwin_y_base_offset <= (others=>'0');
        next_ii_gen_x_base <= (others=>'0');
        next_ii_gen_x_base <= (others=>'0');
        next_subwin_x_base <= (others=>'0');
        next_subwin_y_base <= (others=>'0');
        next_state <= s_CAPTURE_start;
        
      -- continuously capture individual frames or capture continuously in video mode
      when s_CAPTURE_start =>
        if ov7670_capture_busy='1' then -- wait until camera capture controller begins
          next_state <= s_CAPTURE;
        else
          if capture_mode = '0' then -- video mode
            take_snapshot <= '1';
          else
            if capture = '1' then -- capture single frame, until capture button is released
              take_snapshot <= '1';
            end if;
          end if;
          next_state <= s_CAPTURE_start;
        end if;
        
      -- wait until frame is captured
      when s_CAPTURE =>
        if ov7670_capture_busy='0' then
          next_state <= s_newScale_RESET;
        else
          next_state <= s_CAPTURE;
        end if;
        
      -- perform soft reset before processing the new scale image
      when s_newScale_RESET =>
        -- make sure ii_gen and subwindow are reset
        ii_gen_reset_s <= '1';
        subwin_reset_s <= '1';
        -- next ii_gen process will store the initial integral image in the lower part of the integral image buffer
        next_mem_state <= '0';
        -- make sure that ii_gen and subwindow location registers are reset to scaled image (0,0) position
        next_subwin_x_base <= (others=>'0');
        next_subwin_y_base <= (others=>'0');
        next_ii_gen_x_base <= (others=>'0');
        next_ii_gen_y_base <= (others=>'0');
        next_subwin_x_base_offset <= (others=>'0');
        next_subwin_y_base_offset <= (others=>'0');
        next_state <= s_ii_gen_init;
        
      -- process the initial integral image
      when s_ii_gen_init =>
        if ii_gen_done_s='1' then -- wait until  the ii_gen process completes
          -- advance integral image base for next ii_gen process (relative to the current scale image)
          next_ii_gen_x_base <= (others=>'0');
          next_ii_gen_y_base <= std_logic_vector(to_unsigned(36,8)); -- offset by number of vertical subwindow scans per integral image = II_HEIGHT-SUBWIN_DIM+1 =59-24+1=36
          next_state <= s_ii_gen_subwin_RESET;
        else
          ii_gen_start_s <= '1'; -- start the ii_gen process
          buff_1B_mux_sel <= '1'; -- mux ii_gen clock and generated rdaddress to image buffer portB
          next_state <= s_ii_gen_init;
        end if;
      
       -- subwindow only reset
      when s_subwin_RESET =>
        buff_1B_mux_sel <= '1';
        subwin_reset_s <= '1';
        if subwin_any_fail='1' then -- dont start until all subwindow fail flags are reset
          next_state <= s_subwin_RESET;
        else
          next_state <= s_ii_gen_subwin;
        end if;
        
      -- ii_gen and subwindow reset, also invert integral image memeory state
      when s_ii_gen_subwin_RESET =>
        buff_1B_mux_sel <= '1';
        ii_gen_reset_s <= '1';
        subwin_reset_s <= '1';
        if subwin_any_fail='1' then -- dont start until all subwindow fail flags are reset
          next_state <= s_ii_gen_subwin_RESET;
        else
          next_mem_state <= not mem_state; -- invert integral image memeory state
          next_state <= s_ii_gen_subwin;
        end if;
        
      -- generate the next integral image by scanning the ii_gen process through the scaled image,
      -- and scan the parallel subwindows through the current integral image
      when s_ii_gen_subwin =>
        next_subwin_x_base_offset <= (others=>'0'); -- base address of subwindow is always zero relative to current integral dimentions
        buff_1B_mux_sel <= '1';
        
        ii_gen_start_s <= '1'; -- start ii_gen process
        subwin_start_s <= '1'; -- start subwin process
        
        -- when the current classifier cascade finishes or all subwindows fail
        if subwin_done_s='1'or subwin_all_fail='1' then
          
          -- scan all possible subwindow areas in the current integral image
          if (unsigned(subwin_y_base_offset) < (II_HEIGHT-to_unsigned(24,6))) and (unsigned(subwin_y_base_offset) < (unsigned(height_scale_img)-to_unsigned(24,6))) then
            next_subwin_y_base_offset <= std_logic_vector(unsigned(subwin_y_base_offset)+to_unsigned(1,6)); -- subwin_y_base_offset+=1
            next_state <= s_subwin_RESET; -- only restart subwindow
          else
            
            -- increment integral image location when the subwindows scan through all locations within the current integral image
            -- and ii_gen has generated the next integral image for subwindow evaluation	
            if ii_gen_done_s='1' then
              next_subwin_y_base_offset <= (others=>'0'); -- reset
              next_subwin_x_base <= ii_gen_x_base; -- update subwindow cascade base index with old ii_gen base index
              next_subwin_y_base <= ii_gen_y_base;
              
              -- scan all possible integral image areas in the current scaled image
              if signed('0' & ii_gen_y_base) < (signed('0' & height_scale_img)-signed('0' & II_HEIGHT)) then
                next_ii_gen_y_base <= std_logic_vector(unsigned(ii_gen_y_base)+to_unsigned(36,8)); -- ii_gen_y_base +=36
                next_state <= s_ii_gen_subwin_RESET; -- restart subwindow process and integral image process
              else
                if signed('0' & ii_gen_x_base) < (signed('0' & width_scale_img)-signed('0' & II_WIDTH)) then
                  next_ii_gen_x_base <= std_logic_vector(unsigned(ii_gen_x_base)+to_unsigned(16,9)); -- ii_gen_x_base += 16
                  next_ii_gen_y_base <= (others=>'0'); -- ii_gen_y_base = 0 ; async reset
                  next_state <= s_ii_gen_subwin_RESET;  -- restart subwindow process and integral image process
                else
                  -- done with image process at the current scale
                  next_state <= s_scale;
                end if;
              end if;
              
            else -- ii_gen process is not done, wait until done
              next_state <= s_ii_gen_subwin;
            end if;
          end if;
        else
          -- cascade still processing
          next_state <= s_ii_gen_subwin;
        end if;
      
      -- increment the image scale
      when s_scale =>
        subwin_reset_s <= '1';
        ii_gen_reset_s <= '1';
        if scale_count = "1000" then -- first 4 scales implemented
          next_state <= s_faceBox_start;
        else
          scale_count_en <= '1'; -- increment scale
          next_state <= s_newScale_RESET;
        end if;
      
      -- start the faceBox process
      when s_faceBox_start =>
        faceBox_start_s <= '1';
        next_state <= s_faceBox;
      
      -- wait until the faceBox process is done
      when s_faceBox =>
        buff_1A_mux_sel <= '1';
        if faceBox_done_s='1' then
          next_state <= s_RESET;
        else
          faceBox_start_s <= '1';
          next_state <= s_faceBox;
        end if;
   
      end case;
  end process;
  
  -- clocks generation;
  Inst_four_clocks_pll: my_altpll PORT MAP(
    areset => '0', -- reset_general?
    inclk0 => clk_50,    --50MHz
    c0 => clk_sys,       -- 40MHz
    c1 => clk_iigen,     -- 100MHz
    c2 => clk_50_camera, -- 50MHz
    c3 => clk_25_vga,    -- 25MHz
    locked => dll_locked -- drives an LED;
  );
  clk_faceBox <= clk_sys;
  LED_dll_locked <= dll_locked;
  
  -- debouncing slide switches;
  -- take entity input slide_sw_resend_reg_values and debounce it to
  -- get clean resend_reg_values signal;
  Inst_debounce_resend: debounce PORT MAP(
    clk => clk_25_vga,
    i   => slide_sw_resend_reg_values,
    o   => resend_reg_values
  );
  
  -- camera module related 
  Inst_ov7670_controller: ov7670_controller PORT MAP(
    clk             => clk_50_camera,
    resend          => resend_reg_values, -- debounced;
    config_finished => LED_config_finished, -- LEDRed[1] notifies user;
    sioc            => ov7670_sioc,
    siod            => ov7670_siod,
    reset           => ov7670_reset,
    pwdn            => ov7670_pwdn,
    xclk            => ov7670_xclk
  );
   
  Inst_ov7670_capture: ov7670_capture PORT MAP(
    pclk  => ov7670_pclk,
    capture => take_snapshot,
    vsync => ov7670_vsync,
    href  => ov7670_href,
    d     => ov7670_data,
    addr  => image_wraddress_from_ov7670_capture,
    dout  => image_wrdata_from_ov7670_capture,
    we    => image_wren_from_ov7670_capture,
    busy  => ov7670_capture_busy
  );
  
  -- VGA related
  Inst_Address_Generator: Address_Generator PORT MAP(
    rst_i => '0',
    CLK25 => clk_25_vga,
    enable => activeArea,
    vsync => vsync,
    address => image_rdaddress_from_addr_gen
  );
  
  Inst_VGA: VGA PORT MAP(
    CLK25      => clk_25_vga,
    clkout     => vga_CLK,
    Hsync      => vga_hsync,
    Vsync      => vsync,
    Nblank     => nBlank,
    Nsync      => vga_sync_N,
    activeArea => activeArea
  );  
  
  Inst_RGB: RGB PORT MAP(
    Din => rddata_buff_1A,
    Nblank => activeArea,
    R => red,
    G => green,
    B => blue
  );
  
  vga_r <= red(7 downto 0);
  vga_g <= green(7 downto 0);
  vga_b <= blue(7 downto 0);
  vga_vsync <= vsync;
  vga_blank_N <= nBlank;
  
  -- Image Frame Buffer Setup: Stores 12bit color data for conversion to integral image and vga display
  --   write port A : faceBox
  --   write port B : camera capture
  --   read port A : VGA
  --   read port B : ii_gen
  image_ram1: image_frame_buffer PORT MAP(
    address_a => address_buff_1A,
    address_b => address_buff_1B,
    clock_a => clk_buff_1A,
    clock_b => clk_buff_1B,
    data_a => image_wrdata_from_faceBox,
    data_b => image_wrdata_from_ov7670_capture,
    wren_a => image_wren_from_faceBox,
    wren_b => image_wren_from_ov7670_capture,
    q_a => rddata_buff_1A,
    q_b => rddata_buff_1B
  );
  
  -- Integral Image Frame Buffer Setup:
  --  Theory: 
  --    Two parallel buffers were implemented for integral image (ii) and integral image square (iix2).
  --    One buffer addresses the lower chunk of data for high bandwidth memory read while the other buffer addresses the next(upper) chunk.
  --    Subwindow_top.vhd addresses these chunks based on subwindow(0)'s relative position in the scaled integral image.
  --    16 subwindow's are currently implemented, so each buffer data output width is 16*wordSize; where wordSize is 21bit for ii and 29bit for iix2.
  --    Each subwindow instance is offset by 1 pixel in the X direction, relative to the integral image.
  --    These chunks are adjacent in memory and allow a large mux like entity to route any 16*wordSize data set from these two addressed chunks.
  --    
  --    Subwindow_top.vhd generates a 13bit address where the upper 9bits are used to address the integral image buffers
  --    and the lower 4bits are used as select signals for the large data mux routing.
  --
  --    This type of memory architecture eliminates the need to access the memory twice to access data for the 16 subwindows,
  --    but comes at the cost of doubling the amount of memory needed for integral image buffering. 
  --
  --    An example data access: 
  --      If subwindow(0) requires the data stored at pixel location x=3,y=0, then subwindow(1) will receive the data from x=4,y=0
  --      and subwindow(15) will receive the data from x=18,y=0.
  --      So the upper 9 bits of the generated ii_rdaddress, within subwindow_top.vhd, will be zero
  --      to address the first 16 words in memory via the lower chunk buffer and the following 16 words via the upper chunk buffer.
  --      The lower 4 bits of the generated ii_rdaddress are used to select which 16 words are routed to the subwindows.
  --      Since the addressed pixel location was x=3,y=0, word(3):word(18) are routed to subwindow(0):subwindow(15) respectively.
  --    
  --    It should also be noted that each integral image buffer is divided into two partitions. These are upper and lower partitions within the same
  --    addressable RAM entity. The division of each integral image buffer allows one portion to be written to by the integral image generator process
  --    while the other can be read from by the subwindow process. In this implementation, a buffer contains two 39*59 pixel integral images in the same buffer.
  --    Each buffer contains 8,192 addressable memory locations and the MSbit of the 13bit address determines if the lower or upper memory partitions is being operated on.
  --    So effectively 0(dec) is the base address of the lower memory partitions and 4,096(dec) is the base address of the upper memory partitions.
  --    In the top level, the mem_state signal determines which partitions of the integral image memory space is being written to by ii_gen and read from subwindow_top.
  --      mem_state='0' ... lower memory partition is being written to while the upper is being read
  --      mem_state='1' ... upper memory partition is being written to while the lower is being read
  --
  --    But how does this memory architecture impact the system performance? This architecture allows the current subwindow classifier cascade to execute while the next
  --    integral image to be evaluated is generated. The ii_gen process is always completed before the parallel subwindows can scan through the 36 possible scan locations
  --    within the current integral image. So performance is effectively the same as buffer that contains the integral image of the entire scaled image.
  --    
  --  buffer1:
  --    write portA : ii_gen
  --    write portB : GND
  --    read portA : ii_gen
  --    read portB : subwindow_top, lower data chunk //width=(16 * wordSize)
  --  buffer2:
  --    write portA : ii_gen
  --    write portB : GND
  --    read portA : OPEN
  --    read portB : subwindow_top, upper data chunk //width=(16 * wordSize)
  ii_ram1: ii_buffer PORT MAP(-- lower 16 words in 32 word chunk
    address_a => address_buff_2A,
    address_b => address_buff_2B,
    clock_a => clk_iigen,
    clock_b => clk_sys,
    data_a => wrdata_buff_2A,
    data_b => (others=>'0'),
    wren_a => wren_buff_2A,
    wren_b => '0',
    q_a => rddata_buff_2A,
    q_b => rddata_buff_2B((16*20*1)-1 downto 0)
  );
  
  address_buff_2B_prime <= std_logic_vector(unsigned(address_buff_2B)+to_unsigned(1,9));
  ii_ram2: ii_buffer PORT MAP(-- upper 16 words in 32 word chunk
    address_a => address_buff_2A,
    address_b => address_buff_2B_prime,
    clock_a => clk_iigen,
    clock_b => clk_sys,
    data_a => wrdata_buff_2A,
    data_b => (others=>'0'),
    wren_a => wren_buff_2A,
    wren_b => '0',
    q_a => open,
    q_b => rddata_buff_2B((16*20*2)-1 downto (16*20*1))
  );
  
  iix2_ram1: iix2_buffer PORT MAP(-- lower 16 words 32 word chunk
    address_a => address_buff_3A,
    address_b => address_buff_3B,
    clock_a => clk_iigen,
    clock_b => clk_sys,
    data_a => wrdata_buff_3A,
    data_b => (others=>'0'),
    wren_a => wren_buff_3A,
    wren_b => '0',
    q_a => rddata_buff_3A,
    q_b => rddata_buff_3B((16*28*1)-1 downto 0)
  );
  
  address_buff_3B_prime <= std_logic_vector(unsigned(address_buff_3B)+to_unsigned(1,9));
  iix2_ram2: iix2_buffer PORT MAP(-- upper 16 words 32 word chunk
    address_a => address_buff_3A,
    address_b => address_buff_3B_prime,
    clock_a => clk_iigen,
    clock_b => clk_sys,
    data_a => wrdata_buff_3A,
    data_b => (others=>'0'),
    wren_a => wren_buff_3A,
    wren_b => '0',
    q_a => open,
    q_b => rddata_buff_3B((16*28*2)-1 downto (16*28*1))
  );
  
  -- buffer mux's 
  clk_buff_1A_mux : mux_std_logic PORT MAP(
    sel => buff_1A_mux_sel,
    a => clk_25_vga,
    b => clk_faceBox,
    q => clk_buff_1A
  );
  
  clk_buff_1B_mux : mux_std_logic PORT MAP(
    sel => buff_1B_mux_sel,
    a => ov7670_pclk,
    b => clk_iigen,
    q => clk_buff_1B
  );
  
  address_buff_1A_mux : mux_2_1
  GENERIC MAP(DATA_WIDTH => 17)
  PORT MAP(
    sel => buff_1A_mux_sel,
    a => image_rdaddress_from_addr_gen, -- VGA address gen
    b => image_wraddress_from_faceBox, -- faceBox address gen
    q => address_buff_1A
  );
  
  address_buff_1B_mux : mux_2_1
  GENERIC MAP(DATA_WIDTH => 17)
  PORT MAP(
    sel => buff_1B_mux_sel,
    a => image_wraddress_from_ov7670_capture, -- camera address gen
    b => image_rdaddress_from_iigen, -- ii_gen address gen
    q => address_buff_1B
  );
  
  -- ii_gen process
  ii_gen_inst: ii_gen PORT MAP(
    clk             => clk_iigen,
    reset           => ii_gen_reset_s,
    start           => ii_gen_start_s,
    image_data_i    => rddata_buff_1B,
    image_scale     => scale_count,
    ii_data_i       => rddata_buff_2A,
    iix2_data_i     => rddata_buff_3A,
    mem_state       => mem_state,
    scaleImg_x_base => ii_gen_x_base,
    scaleImg_y_base => ii_gen_y_base,
    image_rdaddress => image_rdaddress_from_iigen,
    ii_address      => address_buff_2A,
    ii_wren         => wren_buff_2A,
    ii_data_o       => wrdata_buff_2A,
    iix2_data_o     => wrdata_buff_3A,
    done            => ii_gen_done_s
  );
  address_buff_3A <= address_buff_2A; -- same address for ii and iix2 ii_gen process
  wren_buff_3A <= wren_buff_2A; -- same wren for ii and iix2 ii_gen process
  
  -- subwindow top level
  subwin_top_inst: subwindow_top PORT MAP(
    reset           => subwin_reset_s,
    clk_sys         => clk_sys,
    start           => subwin_start_s,
    mem_state       => mem_state,
    x_pos_subwin0   => subwin_x_base_offset,
    y_pos_subwin0   => subwin_y_base_offset,
    ii_rddata       => rddata_buff_2B,
    iix2_rddata     => rddata_buff_3B,
    ii_rdaddress    => address_buff_2B,
    iix2_rdaddress  => address_buff_3B,
    fail_out        => subwin_fail_s,
    done            => subwin_done_s
  );
  
  -- calculate x and y position of subwindow0 within the scaled image
  --   Depends on:
  --    (1) current integral image location relative to the scaled image
  --    (2) subwindow location relative to the integral image
  subwin_x_pos <= std_logic_vector(unsigned(subwin_x_base)+unsigned(subwin_x_base_offset));
  subwin_y_pos <= std_logic_vector(unsigned(subwin_y_base)+unsigned(subwin_y_base_offset));
  
  -- faceBox buffer/process
  --   only write to faceBox buffer when the cascade is done and there is at least one subdinow that contains a face
  faceBox_wren <= subwin_done_s and not subwin_all_fail;
  faceBox_inst: faceBox PORT MAP(
    reset         => faceBox_reset_s,
    clk_subwin    => clk_sys,
    clk_faceBox   => clk_faceBox,
    start_draw    => faceBox_start_s,
    scale         => scale_count,
    x_pos_subwin  => subwin_x_pos,
    y_pos_subwin  => subwin_y_pos,
    subwin_done   => faceBox_wren,
    subwin_detection => subwin_fail_s,
    img_wraddress => image_wraddress_from_faceBox,
    img_wrdata    => image_wrdata_from_faceBox,
    img_wren      => image_wren_from_faceBox,
    done_draw     => faceBox_done_s
  );
 
  -- debug and performance related
  prformance_reg: process (clk_faceBox, faceBox_done_s)
  begin
    if rising_edge(clk_faceBox) and faceBox_done_s='1' then
      measure_performance_reg <= not measure_performance_reg;
    end if;
  end process;
  -- toggles after every faceBox process completion 
  -- half period on o-scope indicates the processed FPS
  measure_performance <= measure_performance_reg;
  
  ii_gen_done <= ii_gen_done_s; -- debug
  subwin_done <= subwin_done_s; -- debug
  faceBox_done <= faceBox_done_s; -- debug
  
  
end structure;