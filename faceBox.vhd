library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity faceBox is
	port(
		reset: in std_logic;
		clk_subwin: in std_logic; -- faceBox buffer write clock and box_in_counter clock ... faceBox buffer wren and box in count are asserted by subwindow process, so sync to subwinow clock
		clk_faceBox: in std_logic; -- faceBox buffer read clock and faceBox system clock1
		start_draw: in std_logic; -- begin state machine process to write all box's to the image buffer
		scale: in std_logic_vector(3 downto 0); -- current image scale size, integer form 1 to 8 (scale =1/1 to 1/8)
		x_pos_subwin: in std_logic_vector(8 downto 0); -- 320 max, 9bit uns. -- subwindow0 base x pos
		y_pos_subwin: in std_logic_vector(7 downto 0); -- 240 max, 8bit uns. -- subwindow0 base y pos
		subwin_done: in std_logic; -- lacth subwindow data into faceBox  buffer
		subwin_detection: in std_logic_vector(15 downto 0); -- failure results from the subwindow fail register
		img_wraddress: out std_logic_vector(16 downto 0); -- image buffer address to write box data
		img_wrdata: out std_logic_vector(11 downto 0); -- constant 12 bit color
		img_wren: out std_logic; -- write enable for image buffer
		done_draw: out std_logic -- flag box draw process is done
	);
end faceBox;

architecture behavior of faceBox is
 
 component counter
  generic (COUNT_WIDTH : integer := 4);
  port(
    clk: in std_logic;
    reset: in std_logic;
    en: in std_logic;
    count: out std_logic_vector(COUNT_WIDTH-1 downto 0)
  );
 end component;
 
 component counter2
  generic (COUNT_WIDTH : integer := 4);
  port(
    clk: in std_logic;
    reset: in std_logic;
    en: in std_logic;
    count: out std_logic_vector(COUNT_WIDTH-1 downto 0)
  );
 end component;
 
 COMPONENT faceBox_buff
  PORT
  (
    data		: IN STD_LOGIC_VECTOR (36 DOWNTO 0);
    rdaddress		: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
    rdclock		: IN STD_LOGIC ;
    wraddress		: IN STD_LOGIC_VECTOR (9 DOWNTO 0);
    wrclock		: IN STD_LOGIC  := '1';
    wren		: IN STD_LOGIC  := '0';
    q		: OUT STD_LOGIC_VECTOR (36 DOWNTO 0)
  );
 END COMPONENT;
 
 -- faceBox buffer related
 signal info_wren : std_logic;
 signal info_wrdata : std_logic_vector(36 downto 0); -- encode data
 signal info_rddata : std_logic_vector(36 downto 0); -- decode data
 
 -- counter signals
 signal count_box_in : std_logic_vector(9 downto 0); -- range from 0 to 255
 signal count_box_in_en : std_logic;
 signal count_box_in_reset: std_logic;
 signal count_box_out : std_logic_vector(13 downto 0); -- range from 0 to 255
 signal count_box_out_en : std_logic;
 signal count_box_out_reset: std_logic;
 signal count_box_dim : std_logic_vector(8 downto 0); -- range from 0 to dim_box ... 0 to 320
 signal count_box_dim_en : std_logic;
 signal count_box_dim_reset: std_logic;
 
 -- box processing signals
 signal detection : std_logic_vector(15 downto 0);
 signal scale_s : std_logic_vector(3 downto 0);        -- decoder signal from buffer
 signal x_pos_subwin_s : std_logic_vector(8 downto 0); -- decoder signal from buffer
 signal y_pos_subwin_s : std_logic_vector(7 downto 0); -- decoder signal from buffer
 
 signal x_box : std_logic_vector(12 downto 0);
 signal y_box : std_logic_vector(11 downto 0);
 signal dim_box : std_logic_vector(8 downto 0);
 
 signal img_wraddress_s : std_logic_vector(16 downto 0);
 signal img_wren_s : std_logic;
 
 signal sel_inc_num : std_logic;
 signal inc_num : std_logic_vector(8 downto 0);
 signal box_base_address : std_logic_vector(20 downto 0);
 signal img_wraddress_reset, wraddress_accum_en : std_logic;
 signal box_detection : std_logic;
 
 signal mult_temp : std_logic_vector(20 downto 0);
 signal mult_temp2 : std_logic_vector(7 downto 0);
 signal add_temp : std_logic_vector(12 downto 0);
 
 -- State machine signals
  type STATE_TYPE is (s_RESET, s_setup_info_rdaddress, s_buff_setup, s_TOP, s_RIGHT, s_LEFT, s_BOTTOM, s_check_box_out_count, s_DONE);
  signal current_state,next_state : STATE_TYPE;
  
  type STATE_TYPE2 is (s_RESET, s_img_buff_latch);
  signal cs_logDetection, ns_logDetection : STATE_TYPE2;
 
begin
 
 -- inputs/buffer write controls; signals asserted from subwindow_top.vhd
 count_box_in_reset <= reset;
 info_wren <= subwin_done;
 count_box_in_en <= subwin_done;
 
 -- consolidate data to write into boxBuff
 info_wrdata <= subwin_detection & scale & x_pos_subwin & y_pos_subwin;
 
 -- counts the number of box's that were logged into the faceBox buffer
 box_in_counter: counter
  generic map(COUNT_WIDTH => 10)
  port map(
    clk => clk_subwin,
    reset => count_box_in_reset,
    en => count_box_in_en,
    count => count_box_in
  );
  
 -- counts the number of box's that have been read from the faceBox buffer
 box_out_counter: counter
  generic map(COUNT_WIDTH => 14)
  port map(
    clk => clk_faceBox,
    reset => count_box_out_reset,
    en => count_box_out_en,
    count => count_box_out
  );
 
 -- counts up to dim_box
 box_dim_counter: counter2
  generic map(COUNT_WIDTH => 9)
  port map(
    clk => clk_faceBox,
    reset => count_box_dim_reset, -- sync reset
    en => count_box_dim_en,
    count => count_box_dim
  );
 
 -- stores relivent data needed to scale and position boxes relative to the original image dimentions
 faceBox_ram: faceBox_buff
  port map
  (
    data => info_wrdata,
    rdaddress => count_box_out(13 downto 4),
    rdclock => clk_faceBox,
    wraddress => count_box_in,
    wrclock => clk_subwin,
    wren => info_wren,
    q => info_rddata);
 
 -- mux for inc_num
 mux_inc_num: process (sel_inc_num)
 begin
   if sel_inc_num='0' then
	  inc_num <= std_logic_vector(to_unsigned(1,9)); -- add 1 to box draw wraddress
	else
	  inc_num <= std_logic_vector(to_unsigned(320,9)); -- add 320 to box draw address
	end if;
 end process;
 
 -- accumulator register for img_wraddress
 img_wraddress_reg: process (clk_faceBox, img_wraddress_reset, wraddress_accum_en, box_base_address, inc_num)
 begin
   if rising_edge(clk_faceBox) then
	  if img_wraddress_reset = '1' then
	    img_wraddress_s <= box_base_address(16 downto 0);
	  elsif wraddress_accum_en='1' then
	    img_wraddress_s <= img_wraddress_s+inc_num; -- 15bit unsigned result
	  end if;
   end if;
 end process;
 
 -- get current indexed failure result
 box_detection <= detection(to_integer(unsigned(count_box_out(3 downto 0))));
 
   ------------ state machine flip flop ------

 FF: process (clk_faceBox, reset)
 begin
  if (reset='1') then
    current_state <= s_RESET;
  elsif (rising_edge(clk_faceBox)) then
    current_state <= next_state;
  end if;
 end process;
 
  ------------ state machine combinational logic -------
 
 SM: process (current_state, start_draw, count_box_dim, dim_box, count_box_out, count_box_in, box_detection)
 begin
   img_wraddress_reset <= '0';
	sel_inc_num <= '0';
	img_wren_s <= '0';
	wraddress_accum_en <= '0';
	count_box_dim_reset <= '0';
	count_box_dim_en <= '0';
	count_box_out_reset <= '0';
	count_box_out_en <= '0';
	done_draw <= '0';
	
   case current_state is
	  when s_RESET =>
       count_box_out_reset <= '1'; --  sync reset the output box counter
		 
		 if start_draw='1' then -- wait for start_draw, process logged boxes
		   if unsigned(count_box_in) = to_unsigned(0,10) then -- wait for start_draw, no boxes logged ... assert done
			  next_state <= s_DONE;
			else
			  next_state <= s_setup_info_rdaddress;
			end if;
		 else
		   next_state <= s_RESET;
		 end if;
		 
	  when s_setup_info_rdaddress =>
	    --null, setup faceBox buffer read address
		 next_state <= s_buff_setup;
		 
	  -- setup base address of box to draw and check logged subwindow failure status
     when s_buff_setup =>
		 img_wraddress_reset <= '1'; -- set img_wraddress <= box_base_address; ... sync reset
		 if box_detection = '0' then -- check for no failures logged
         next_state <= s_TOP;
		 else                        -- if current detection evaluatoin = '1' = failure, move on to s_check_box_out_count an inc index's / address's as necessary
		   next_state <= s_check_box_out_count;
		 end if;
		 
	  -- generate/write top box row
	  when s_TOP => 
	    img_wren_s <= '1'; -- write to address on next rising clock edge
	    sel_inc_num <= '0'; -- base address inc's by 1 for next address
		 
		 if count_box_dim < dim_box then
		   wraddress_accum_en <= '1'; -- inc address on next rising clock edge
		   count_box_dim_en <= '1'; -- inc box dimention counter
		   next_state <= s_TOP;
		 else
		   count_box_dim_reset <= '1'; -- sync reset count_box_dim
		   next_state <= s_RIGHT;
		 end if;
		
	  -- generate/write right side box column	
	  when s_RIGHT =>
	    img_wren_s <= '1'; -- write to address on next rising clock edge
	    sel_inc_num <= '1'; -- base address inc's by 320 for next address
		 
		 if count_box_dim < dim_box then
		   wraddress_accum_en <= '1'; -- inc address on next rising clock edge
		   count_box_dim_en <= '1'; -- inc box dimention counter
		   next_state <= s_RIGHT;
		 else
		   count_box_dim_reset <= '1'; -- sync reset count_box_dim
			img_wraddress_reset <= '1'; -- sync reset img_wraddress to box_base_address for s_LEFT state
		   next_state <= s_LEFT;
		 end if;
		 
	  -- generate/write left side box column
     when s_LEFT =>
	    img_wren_s <= '1'; -- write to address on next rising clock edge
	    sel_inc_num <= '1'; -- base address inc's by 320 for next address
		 
		 if count_box_dim < dim_box then
		   wraddress_accum_en <= '1'; -- inc address on next rising clock edge
		   count_box_dim_en <= '1'; -- inc box dimention counter
		   next_state <= s_LEFT;
		 else
		   count_box_dim_reset <= '1'; -- sync reset count_box_dim
		   next_state <= s_BOTTOM;
		 end if;
		 
	  -- generate/write bottom box row
     when s_BOTTOM =>
	    img_wren_s <= '1'; -- write to address on next rising clock edge
	    sel_inc_num <= '0'; -- base address inc's by 1 for next address
		 
		 if count_box_dim < dim_box then
		   wraddress_accum_en <= '1'; -- inc address on next rising clock edge
		   count_box_dim_en <= '1'; -- inc box dimention counter
		   next_state <= s_BOTTOM;
		 else
		   count_box_dim_reset <= '1'; -- sync reset count_box_dim
		   next_state <= s_check_box_out_count;
		 end if;
		 
	  -- increment the logged box index
	  when s_check_box_out_count =>
		 if count_box_out(13 downto 4) = count_box_in-1  then
	      next_state <= s_DONE;
	    else
			count_box_out_en <= '1';  -- inc count_box_out to address new box parameters
	      count_box_dim_reset <= '1'; -- sync reset img_wraddress to box_base_address for next s_TOP state, if any
         next_state <= s_setup_info_rdaddress;
	    end if;
		 
	 when s_DONE =>
	   done_draw <= '1';
	   next_state <= s_RESET;
			
	end case;
 end process;
 
 
 -- decode box buffer output
 detection <= info_rddata(36 downto 21);
 scale_s <= info_rddata(20 downto 17);
 x_pos_subwin_s <= info_rddata(16 downto 8);
 y_pos_subwin_s <= info_rddata(7 downto 0);
 
 -- scale box parameters that were logged to original image dimentions
 dim_box <= std_logic_vector(to_unsigned(23,5)*unsigned(scale_s)); -- 5bit uns * 4bit uns = 9bit uns max
 x_box <= x_pos_subwin_s*scale_s; -- 9bit uns * 4bit uns = 13bit uns max ... only care about 9 bits since (x_box < 320) always
 y_box <= y_pos_subwin_s*scale_s; -- 8bit uns * 4bit uns = 12bit uns max ... only care about 8 bits since (y_box < 240) always
 mult_temp <= std_logic_vector( unsigned(y_box) * to_unsigned(320,9) ); -- 21bit uns
 mult_temp2 <= std_logic_vector(unsigned(count_box_out(3 downto 0))*unsigned(scale_s)); -- 8bit uns, SUBWINDOW XPOS OFFSET, 1 pixel delta between scaled image subwindows, so distance between suwbwindos in origina image is by 1pixel*scale 
 add_temp <= std_logic_vector(unsigned(x_box) + unsigned(mult_temp2)); -- 13bit uns
 box_base_address <= std_logic_vector(unsigned(mult_temp) + unsigned(add_temp)); -- 21bit uns
 
 -- output assignments
 img_wrdata <= "111100000000"; -- constant 12 bit RGB444 red for box draw data
 --img_wrdata <= "111100001111"; -- constant 12 bit RGB444 purple for box draw data
 img_wren <= img_wren_s;
 img_wraddress <= img_wraddress_s;
 
end behavior;
