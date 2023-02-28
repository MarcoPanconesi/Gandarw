###############################################################################
##$Date: 2009/11/26 05:47:37 $
##$Revision: 1.1 $
###############################################################################
## wave_mti.do
###############################################################################
## 
## 
## (c) Copyright 2006-2010 Xilinx, Inc. All rights reserved.
## 
## This file contains confidential and proprietary information
## of Xilinx, Inc. and is protected under U.S. and
## international copyright and other intellectual property
## laws.
## 
## DISCLAIMER
## This disclaimer is not a license and does not grant any
## rights to the materials distributed herewith. Except as
## otherwise provided in a valid license issued to you by
## Xilinx, and to the maximum extent permitted by applicable
## law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
## WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
## AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
## BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
## INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
## (2) Xilinx shall not be liable (whether in contract or tort,
## including negligence, or under any other theory of
## liability) for any loss or damage of any kind or nature
## related to, arising under or in connection with these
## materials, including for any direct, or any indirect,
## special, incidental, or consequential loss or damage
## (including loss of data, profits, goodwill, or any type of
## loss or damage suffered as a result of any action brought
## by a third party) even if such damage or loss was
## reasonably foreseeable or Xilinx had been advised of the
## possibility of the same.
## 
## CRITICAL APPLICATIONS
## Xilinx products are not designed or intended to be fail-
## safe, or for use in any application requiring fail-safe
## performance, such as life-support or safety devices or
## systems, Class III medical devices, nuclear facilities,
## applications related to the deployment of airbags, or any
## other applications that could lead to death, personal
## injury, or severe property or environmental damage
## (individually and collectively, "Critical
## Applications"). Customer assumes the sole risk and
## liability of any use of Xilinx products in Critical
## Applications, subject only to applicable laws and
## regulations governing limitations on product liability.
## 
## THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
## PART OF THIS FILE AT ALL TIMES. 


onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider {FRAME CHECK MODULE tile0_frame_check0 }
add wave -noupdate -format Logic /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/tile0_frame_check0/begin_r
add wave -noupdate -format Logic /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/tile0_frame_check0/track_data_r
add wave -noupdate -format Logic /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/tile0_frame_check0/data_error_detected_r
add wave -noupdate -format Logic /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/tile0_frame_check0/start_of_packet_detected_r
add wave -noupdate -format Logic -radix hexadecimal /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/tile0_frame_check0/RX_DATA
add wave -noupdate -format Logic -radix hexadecimal /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/tile0_frame_check0/ERROR_COUNT
add wave -noupdate -divider {FRAME CHECK MODULE tile0_frame_check1 }
add wave -noupdate -format Logic /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/tile0_frame_check1/begin_r
add wave -noupdate -format Logic /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/tile0_frame_check1/track_data_r
add wave -noupdate -format Logic /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/tile0_frame_check1/data_error_detected_r
add wave -noupdate -format Logic /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/tile0_frame_check1/start_of_packet_detected_r
add wave -noupdate -format Logic -radix hexadecimal /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/tile0_frame_check1/RX_DATA
add wave -noupdate -format Logic -radix hexadecimal /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/tile0_frame_check1/ERROR_COUNT
add wave -noupdate -divider {TILE0_SINGLE_CHANNEL_AURORA_XC5VSX95T }
add wave -noupdate -divider {Receive Ports - 8b10b Decoder }
add wave -noupdate -format Literal -radix hexadecimal /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/RXCHARISCOMMA0_OUT
add wave -noupdate -format Literal -radix hexadecimal /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/RXCHARISCOMMA1_OUT
add wave -noupdate -format Literal -radix hexadecimal /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/RXCHARISK0_OUT
add wave -noupdate -format Literal -radix hexadecimal /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/RXCHARISK1_OUT
add wave -noupdate -format Literal -radix hexadecimal /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/RXDISPERR0_OUT
add wave -noupdate -format Literal -radix hexadecimal /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/RXDISPERR1_OUT
add wave -noupdate -format Literal -radix hexadecimal /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/RXNOTINTABLE0_OUT
add wave -noupdate -format Literal -radix hexadecimal /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/RXNOTINTABLE1_OUT
add wave -noupdate -divider {Receive Ports - Comma Detection and Alignment }
add wave -noupdate -format Logic /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/RXBYTEISALIGNED0_OUT
add wave -noupdate -format Logic /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/RXBYTEISALIGNED1_OUT
add wave -noupdate -format Logic /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/RXENMCOMMAALIGN0_IN
add wave -noupdate -format Logic /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/RXENMCOMMAALIGN1_IN
add wave -noupdate -format Logic /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/RXENPCOMMAALIGN0_IN
add wave -noupdate -format Logic /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/RXENPCOMMAALIGN1_IN
add wave -noupdate -divider {Receive Ports - RX Data Path interface }
add wave -noupdate -format Literal -radix hexadecimal /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/RXDATA0_OUT
add wave -noupdate -format Literal -radix hexadecimal /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/RXDATA1_OUT
add wave -noupdate -format Logic /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/RXUSRCLK0_IN
add wave -noupdate -format Logic /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/RXUSRCLK1_IN
add wave -noupdate -format Logic /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/RXUSRCLK20_IN
add wave -noupdate -format Logic /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/RXUSRCLK21_IN
add wave -noupdate -divider {Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR }
add wave -noupdate -format Logic /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/RXN0_IN
add wave -noupdate -format Logic /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/RXN1_IN
add wave -noupdate -format Logic /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/RXP0_IN
add wave -noupdate -format Logic /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/RXP1_IN
add wave -noupdate -divider {Shared Ports - Tile and PLL Ports }
add wave -noupdate -format Logic /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/CLKIN_IN
add wave -noupdate -format Logic /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/GTPRESET_IN
add wave -noupdate -format Logic /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/PLLLKDET_OUT
add wave -noupdate -format Logic /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/REFCLKOUT_OUT
add wave -noupdate -format Logic /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/RESETDONE0_OUT
add wave -noupdate -format Logic /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/RESETDONE1_OUT
add wave -noupdate -divider {Transmit Ports - 8b10b Encoder Control Ports }
add wave -noupdate -format Literal -radix hexadecimal /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/TXCHARISK0_IN
add wave -noupdate -format Literal -radix hexadecimal /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/TXCHARISK1_IN
add wave -noupdate -divider {Transmit Ports - TX Data Path interface }
add wave -noupdate -format Literal -radix hexadecimal /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/TXDATA0_IN
add wave -noupdate -format Literal -radix hexadecimal /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/TXDATA1_IN
add wave -noupdate -format Logic /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/TXOUTCLK0_OUT
add wave -noupdate -format Logic /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/TXOUTCLK1_OUT
add wave -noupdate -format Logic /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/TXUSRCLK0_IN
add wave -noupdate -format Logic /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/TXUSRCLK1_IN
add wave -noupdate -format Logic /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/TXUSRCLK20_IN
add wave -noupdate -format Logic /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/TXUSRCLK21_IN
add wave -noupdate -divider {Transmit Ports - TX Driver and OOB signalling }
add wave -noupdate -format Logic /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/TXN0_OUT
add wave -noupdate -format Logic /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/TXN1_OUT
add wave -noupdate -format Logic /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/TXP0_OUT
add wave -noupdate -format Logic /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i/TXP1_OUT

TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
configure wave -namecolwidth 282
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
update
WaveRestoreZoom {0 ps} {5236 ps}

