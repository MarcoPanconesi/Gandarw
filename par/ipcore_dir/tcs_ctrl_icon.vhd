-------------------------------------------------------------------------------
-- Copyright (c) 2022 Xilinx, Inc.
-- All Rights Reserved
-------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor     : Xilinx
-- \   \   \/     Version    : 14.7
--  \   \         Application: XILINX CORE Generator
--  /   /         Filename   : tcs_ctrl_icon.vhd
-- /___/   /\     Timestamp  : Thu Feb 03 14:59:20 ora solare Europa occidentale 2022
-- \   \  /  \
--  \___\/\___\
--
-- Design Name: VHDL Synthesis Wrapper
-------------------------------------------------------------------------------
-- This wrapper is used to integrate with Project Navigator and PlanAhead

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
ENTITY tcs_ctrl_icon IS
  port (
    CONTROL0: inout std_logic_vector(35 downto 0));
END tcs_ctrl_icon;

ARCHITECTURE tcs_ctrl_icon_a OF tcs_ctrl_icon IS
BEGIN

END tcs_ctrl_icon_a;
