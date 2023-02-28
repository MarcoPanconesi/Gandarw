###############################################################################
##$Date: 2009/11/26 05:47:37 $
##$Revision: 1.1 $
###############################################################################
## wave_isim.tcl
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


scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/tile0_frame_check0
ntrace select -n begin_r track_data_r data_error_detected_r start_of_packet_detected_r RX_DATA ERROR_COUNT
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/tile0_frame_check1
ntrace select -n begin_r track_data_r data_error_detected_r start_of_packet_detected_r RX_DATA ERROR_COUNT
## {Receive Ports - 8b10b Decoder }
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n RXCHARISCOMMA0_OUT
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n RXCHARISCOMMA1_OUT
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n RXCHARISK0_OUT
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n RXCHARISK1_OUT
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n RXDISPERR0_OUT
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n RXDISPERR1_OUT
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n RXNOTINTABLE0_OUT
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n RXNOTINTABLE1_OUT
## {Receive Ports - Comma Detection and Alignment }
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n RXBYTEISALIGNED0_OUT
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n RXBYTEISALIGNED1_OUT
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n RXENMCOMMAALIGN0_IN
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n RXENMCOMMAALIGN1_IN
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n RXENPCOMMAALIGN0_IN
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n RXENPCOMMAALIGN1_IN
## {Receive Ports - RX Data Path interface }
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n RXDATA0_OUT
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n RXDATA1_OUT
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n RXUSRCLK0_IN
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n RXUSRCLK1_IN
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n RXUSRCLK20_IN
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n RXUSRCLK21_IN
## {Receive Ports - RX Driver,OOB signalling,Coupling and Eq.,CDR }
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n RXN0_IN
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n RXN1_IN
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n RXP0_IN
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n RXP1_IN
## {Shared Ports - Tile and PLL Ports }
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n CLKIN_IN
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n GTPRESET_IN
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n PLLLKDET_OUT
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n REFCLKOUT_OUT
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n RESETDONE0_OUT
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n RESETDONE1_OUT
## {Transmit Ports - 8b10b Encoder Control Ports }
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n TXCHARISK0_IN
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n TXCHARISK1_IN
## {Transmit Ports - TX Data Path interface }
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n TXDATA0_IN
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n TXDATA1_IN
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n TXOUTCLK0_OUT
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n TXOUTCLK1_OUT
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n TXUSRCLK0_IN
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n TXUSRCLK1_IN
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n TXUSRCLK20_IN
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n TXUSRCLK21_IN
## {Transmit Ports - TX Driver and OOB signalling }
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n TXN0_OUT
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n TXN1_OUT
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n TXP0_OUT
scope /DEMO_TB/single_channel_aurora_xc5vsx95t_top_i/single_channel_aurora_xc5vsx95t_i/tile0_single_channel_aurora_xc5vsx95t_i
ntrace select -n TXP1_OUT

ntrace start
run 25us
quit

