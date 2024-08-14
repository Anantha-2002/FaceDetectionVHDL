library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package component_package is
  
  -- PLL --
  
  COMPONENT my_altpll
    PORT(
      areset : IN STD_LOGIC  := '0';
      inclk0 : IN STD_LOGIC  := '0';
      c0     : OUT STD_LOGIC ;
      c1     : OUT STD_LOGIC ;
      c2     : OUT STD_LOGIC ;
      c3     : OUT STD_LOGIC ;
      locked : OUT STD_LOGIC 
    );
  END COMPONENT;
  
  -- IMAGE BUFFERS --
  
  COMPONENT image_frame_buffer
	PORT
	(
		address_a : IN STD_LOGIC_VECTOR (16 DOWNTO 0);
		address_b : IN STD_LOGIC_VECTOR (16 DOWNTO 0);
		clock_a   : IN STD_LOGIC  := '1';
		clock_b   : IN STD_LOGIC ;
		data_a    : IN STD_LOGIC_VECTOR (11 DOWNTO 0);
		data_b    : IN STD_LOGIC_VECTOR (11 DOWNTO 0);
		wren_a    : IN STD_LOGIC  := '0';
		wren_b    : IN STD_LOGIC  := '0';
		q_a       : OUT STD_LOGIC_VECTOR (11 DOWNTO 0);
		q_b       : OUT STD_LOGIC_VECTOR (11 DOWNTO 0)
	);
  END COMPONENT;
  
  COMPONENT ii_buffer
    PORT(
      address_a : IN STD_LOGIC_VECTOR (12 DOWNTO 0);
      address_b : IN STD_LOGIC_VECTOR (8 DOWNTO 0);
      clock_a   : IN STD_LOGIC  := '1';
      clock_b   : IN STD_LOGIC ;
      data_a    : IN STD_LOGIC_VECTOR (19 DOWNTO 0);
      data_b    : IN STD_LOGIC_VECTOR (319 DOWNTO 0);
      wren_a    : IN STD_LOGIC  := '0';
      wren_b    : IN STD_LOGIC  := '0';
      q_a       : OUT STD_LOGIC_VECTOR (19 DOWNTO 0);
      q_b       : OUT STD_LOGIC_VECTOR (319 DOWNTO 0)
    );
  END COMPONENT;
  
  COMPONENT iix2_buffer
    PORT(
      address_a : IN STD_LOGIC_VECTOR (12 DOWNTO 0);
      address_b : IN STD_LOGIC_VECTOR (8 DOWNTO 0);
      clock_a   : IN STD_LOGIC  := '1';
      clock_b   : IN STD_LOGIC ;
      data_a    : IN STD_LOGIC_VECTOR (27 DOWNTO 0);
      data_b    : IN STD_LOGIC_VECTOR (447 DOWNTO 0);
      wren_a    : IN STD_LOGIC  := '0';
      wren_b    : IN STD_LOGIC  := '0';
      q_a       : OUT STD_LOGIC_VECTOR (27 DOWNTO 0);
      q_b       : OUT STD_LOGIC_VECTOR (447 DOWNTO 0)
    );
  END COMPONENT;
  
  -- ov7670 CAMERA --
  
  COMPONENT debounce
    PORT ( 
      clk : IN  STD_LOGIC;
      i   : IN  STD_LOGIC;
      o   : OUT  STD_LOGIC);
  END COMPONENT;
  
  COMPONENT ov7670_capture
    PORT(
      pclk    : IN std_logic;
      capture : IN std_logic;
      vsync   : IN std_logic;
      href    : IN std_logic;
      d       : IN std_logic_vector(7 downto 0);          
      addr    : OUT std_logic_vector(16 downto 0);
      dout    : OUT std_logic_vector(11 downto 0);
      we      : OUT std_logic;
      busy    : OUT std_logic
    );
  END COMPONENT;
  
  COMPONENT ov7670_controller
    PORT(
      clk    : IN std_logic;
      resend : IN std_logic;    
      siod   : INOUT std_logic;      
      config_finished : OUT std_logic;
      sioc   : OUT std_logic;
      reset  : OUT std_logic;
      pwdn   : OUT std_logic;
      xclk   : OUT std_logic
    );
  END COMPONENT;
  
  -- VGA DISPLAY --
  
  COMPONENT Address_Generator
    PORT(
      rst_i   : in std_logic;
      CLK25   : IN  std_logic;
      enable  : IN  std_logic;       
      vsync   : in  STD_LOGIC;
      address : OUT std_logic_vector(16 downto 0)
    );
  END COMPONENT;
  
  COMPONENT RGB
    PORT(
      Din    : IN std_logic_vector(11 downto 0);
      Nblank : IN std_logic;          
      R      : OUT std_logic_vector(7 downto 0);
      G      : OUT std_logic_vector(7 downto 0);
      B      : OUT std_logic_vector(7 downto 0)
    );
  END COMPONENT;
  
  COMPONENT VGA
    PORT(
      CLK25  : IN std_logic;    
      Hsync  : OUT std_logic;
      Vsync  : OUT std_logic;
      Nblank : OUT std_logic;      
      clkout : OUT std_logic;
      activeArea : OUT std_logic;
      Nsync  : OUT std_logic
    );
  END COMPONENT;
  
  -- FACE DETECTION TOP LEVEL COMPONENTS --
  
  COMPONENT ii_gen
    PORT(
      clk             : in std_logic;
      reset           : in std_logic;
      start           : in std_logic;
      image_scale     : in std_logic_vector(3 downto 0);
      image_data_i    : in std_logic_vector(11 downto 0);
      ii_data_i       : in std_logic_vector(19 downto 0);
      iix2_data_i     : in std_logic_vector(27 downto 0);
	   mem_state       : in std_logic;
	   scaleImg_x_base : in std_logic_vector(8 downto 0);
	   scaleImg_y_base : in std_logic_vector(7 downto 0);
      image_rdaddress : out std_logic_vector(16 downto 0);
      ii_address      : out std_logic_vector(12 downto 0);
      ii_wren         : out std_logic;
      ii_data_o       : out std_logic_vector(19 downto 0);
      iix2_data_o     : out std_logic_vector(27 downto 0);
      done            : out std_logic
    );
  END COMPONENT;
  
  COMPONENT subwindow_top
    PORT(
      reset: in std_logic;
      clk_sys: in std_logic;
      start: in std_logic;
		mem_state: in std_logic;
      x_pos_subwin0: in std_logic_vector(5 downto 0);
      y_pos_subwin0: in std_logic_vector(5 downto 0);
      ii_rddata: in std_logic_vector((16*20*2)-1 downto 0);
	   iix2_rddata: in std_logic_vector((16*28*2)-1 downto 0);
	   ii_rdaddress: out std_logic_vector(8 downto 0);
	   iix2_rdaddress: out std_logic_vector(8 downto 0);
      fail_out: out std_logic_vector(15 downto 0);
      done: out std_logic
    );
  END COMPONENT;
  
  COMPONENT faceBox
    PORT(
      reset: in std_logic;
		clk_subwin: in std_logic;
		clk_faceBox: in std_logic;
		start_draw: in std_logic;
		scale: in std_logic_vector(3 downto 0);
		x_pos_subwin: in std_logic_vector(8 downto 0);
		y_pos_subwin: in std_logic_vector(7 downto 0);
		subwin_done: in std_logic;
		subwin_detection: in std_logic_vector(15 downto 0);
		img_wraddress: out std_logic_vector(16 downto 0);
		img_wrdata: out std_logic_vector(11 downto 0);
		img_wren: out std_logic;
		done_draw: out std_logic
    );
  END COMPONENT;
  
  -- GENERIC COUNTERS --
  
  COMPONENT counter -- async reset
    GENERIC (COUNT_WIDTH : integer := 4);
    PORT(
      clk   : in std_logic;
      reset : in std_logic;
      en    : in std_logic;
      count : out std_logic_vector(COUNT_WIDTH-1 downto 0)
    );
  END COMPONENT;
  
  COMPONENT counter2 -- sync reset
    GENERIC (COUNT_WIDTH : integer := 4);
    PORT(
      clk   : in std_logic;
      reset : in std_logic;
      en    : in std_logic;
      count : out std_logic_vector(COUNT_WIDTH-1 downto 0)
    );
  END COMPONENT;
  
  -- GENERIC MUXs --
  
  COMPONENT mux_std_logic
    PORT(
      sel : in std_logic;
      a   : in std_logic;
      b   : in std_logic;
      q   : out std_logic
    );
  END COMPONENT;
  
  COMPONENT mux_2_1
    GENERIC(DATA_WIDTH: integer := 4);
    PORT(
      sel : in std_logic;
      a   : in std_logic_vector(DATA_WIDTH-1 downto 0);
      b   : in std_logic_vector(DATA_WIDTH-1 downto 0);
      q   : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
  END COMPONENT;
  
  COMPONENT demux_1_2
    GENERIC(DATA_WIDTH: integer := 4);
    PORT(
      sel : in std_logic;
      a   : in std_logic_vector(DATA_WIDTH-1 downto 0);
      q0   : out std_logic_vector(DATA_WIDTH-1 downto 0);
      q1   : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
  END COMPONENT;
  
end component_package;