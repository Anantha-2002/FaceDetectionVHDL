## Generated SDC file "faceDetectSystem.out.sdc"

## Copyright (C) 1991-2015 Altera Corporation. All rights reserved.
## Your use of Altera Corporation's design tools, logic functions 
## and other software and tools, and its AMPP partner logic 
## functions, and any output files from any of the foregoing 
## (including device programming or simulation files), and any 
## associated documentation or information are expressly subject 
## to the terms and conditions of the Altera Program License 
## Subscription Agreement, the Altera Quartus Prime License Agreement,
## the Altera MegaCore Function License Agreement, or other 
## applicable license agreement, including, without limitation, 
## that your use is for the sole purpose of programming logic 
## devices manufactured by Altera and sold by Altera or its 
## authorized distributors.  Please refer to the applicable 
## agreement for further details.


## VENDOR  "Altera"
## PROGRAM "Quartus Prime"
## VERSION "Version 15.1.0 Build 185 10/21/2015 SJ Lite Edition"

## DATE    "Wed Mar 23 16:37:00 2016"

##
## DEVICE  "EP4CE115F29C7"
##


#**************************************************************
# Time Information
#**************************************************************

set_time_format -unit ns -decimal_places 3



#**************************************************************
# Create Clock
#**************************************************************

create_clock -name {clk_50} -period 20.000 -waveform { 0.000 10.000 } [get_ports {clk_50}]
create_clock -name {ov7670_pclk} -period 1.000 -waveform { 0.000 0.500 } [get_ports {ov7670_pclk}]


#**************************************************************
# Create Generated Clock
#**************************************************************

create_generated_clock -name {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]} -source [get_pins {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50.000 -multiply_by 4 -divide_by 5 -master_clock {clk_50} [get_pins {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}] 
create_generated_clock -name {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[1]} -source [get_pins {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50.000 -multiply_by 2 -master_clock {clk_50} [get_pins {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[1]}] 
create_generated_clock -name {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[2]} -source [get_pins {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50.000 -multiply_by 1 -master_clock {clk_50} [get_pins {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[2]}] 
create_generated_clock -name {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[3]} -source [get_pins {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|inclk[0]}] -duty_cycle 50.000 -multiply_by 1 -divide_by 2 -master_clock {clk_50} [get_pins {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[3]}] 


#**************************************************************
# Set Clock Latency
#**************************************************************



#**************************************************************
# Set Clock Uncertainty
#**************************************************************

set_clock_uncertainty -rise_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[1]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[1]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[3]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[3]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {ov7670_pclk}] -setup 0.110  
set_clock_uncertainty -rise_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {ov7670_pclk}] -hold 0.080  
set_clock_uncertainty -rise_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {ov7670_pclk}] -setup 0.110  
set_clock_uncertainty -rise_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {ov7670_pclk}] -hold 0.080  
set_clock_uncertainty -fall_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[1]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[1]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[3]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[3]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {ov7670_pclk}] -setup 0.110  
set_clock_uncertainty -fall_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}] -rise_to [get_clocks {ov7670_pclk}] -hold 0.080  
set_clock_uncertainty -fall_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {ov7670_pclk}] -setup 0.110  
set_clock_uncertainty -fall_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}] -fall_to [get_clocks {ov7670_pclk}] -hold 0.080  
set_clock_uncertainty -rise_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[1]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[1]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {ov7670_pclk}] -setup 0.110  
set_clock_uncertainty -rise_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {ov7670_pclk}] -hold 0.080  
set_clock_uncertainty -rise_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {ov7670_pclk}] -setup 0.110  
set_clock_uncertainty -rise_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {ov7670_pclk}] -hold 0.080  
set_clock_uncertainty -fall_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[1]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[1]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {ov7670_pclk}] -setup 0.110  
set_clock_uncertainty -fall_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[1]}] -rise_to [get_clocks {ov7670_pclk}] -hold 0.080  
set_clock_uncertainty -fall_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {ov7670_pclk}] -setup 0.110  
set_clock_uncertainty -fall_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[1]}] -fall_to [get_clocks {ov7670_pclk}] -hold 0.080  
set_clock_uncertainty -rise_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[2]}] -rise_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[2]}] -fall_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[3]}] -rise_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[3]}] -fall_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[3]}] -rise_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[3]}] -fall_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[3]}] -rise_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[3]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[3]}] -fall_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[3]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[3]}] -rise_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[3]}] -fall_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[3]}] -rise_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[3]}] -fall_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[2]}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[3]}] -rise_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[3]}]  0.030  
set_clock_uncertainty -fall_from [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[3]}] -fall_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[3]}]  0.030  
set_clock_uncertainty -rise_from [get_clocks {ov7670_pclk}] -rise_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.080  
set_clock_uncertainty -rise_from [get_clocks {ov7670_pclk}] -rise_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.110  
set_clock_uncertainty -rise_from [get_clocks {ov7670_pclk}] -fall_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.080  
set_clock_uncertainty -rise_from [get_clocks {ov7670_pclk}] -fall_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.110  
set_clock_uncertainty -rise_from [get_clocks {ov7670_pclk}] -rise_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[1]}] -setup 0.080  
set_clock_uncertainty -rise_from [get_clocks {ov7670_pclk}] -rise_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[1]}] -hold 0.110  
set_clock_uncertainty -rise_from [get_clocks {ov7670_pclk}] -fall_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[1]}] -setup 0.080  
set_clock_uncertainty -rise_from [get_clocks {ov7670_pclk}] -fall_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[1]}] -hold 0.110  
set_clock_uncertainty -rise_from [get_clocks {ov7670_pclk}] -rise_to [get_clocks {ov7670_pclk}]  0.020  
set_clock_uncertainty -rise_from [get_clocks {ov7670_pclk}] -fall_to [get_clocks {ov7670_pclk}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {ov7670_pclk}] -rise_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.080  
set_clock_uncertainty -fall_from [get_clocks {ov7670_pclk}] -rise_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.110  
set_clock_uncertainty -fall_from [get_clocks {ov7670_pclk}] -fall_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}] -setup 0.080  
set_clock_uncertainty -fall_from [get_clocks {ov7670_pclk}] -fall_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}] -hold 0.110  
set_clock_uncertainty -fall_from [get_clocks {ov7670_pclk}] -rise_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[1]}] -setup 0.080  
set_clock_uncertainty -fall_from [get_clocks {ov7670_pclk}] -rise_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[1]}] -hold 0.110  
set_clock_uncertainty -fall_from [get_clocks {ov7670_pclk}] -fall_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[1]}] -setup 0.080  
set_clock_uncertainty -fall_from [get_clocks {ov7670_pclk}] -fall_to [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[1]}] -hold 0.110  
set_clock_uncertainty -fall_from [get_clocks {ov7670_pclk}] -rise_to [get_clocks {ov7670_pclk}]  0.020  
set_clock_uncertainty -fall_from [get_clocks {ov7670_pclk}] -fall_to [get_clocks {ov7670_pclk}]  0.020  


#**************************************************************
# Set Input Delay
#**************************************************************



#**************************************************************
# Set Output Delay
#**************************************************************



#**************************************************************
# Set Clock Groups
#**************************************************************

set_clock_groups -exclusive -group [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0]}] -group [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[1] Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[2] Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[3] ov7670_pclk}] 
set_clock_groups -exclusive -group [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[1]}] -group [get_clocks {Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[0] Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[2] Inst_four_clocks_pll|altpll_component|auto_generated|pll1|clk[3] ov7670_pclk}] 


#**************************************************************
# Set False Path
#**************************************************************



#**************************************************************
# Set Multicycle Path
#**************************************************************



#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************

