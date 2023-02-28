-------------------------------------------------------------------------------
-- Copyright (c) 2021 Xilinx, Inc.
-- All Rights Reserved
-------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor     : Xilinx
-- \   \   \/     Version    : 14.7
--  \   \         Application: XILINX CORE Generator
--  /   /         Filename   : arwen_prog_ila.vhd
-- /___/   /\     Timestamp  : Thu Jul 08 17:57:27 ora legale Europa occidentale 2021
-- \   \  /  \
--  \___\/\___\
--
-- Design Name: VHDL Synthesis Wrapper
-------------------------------------------------------------------------------
-- This wrapper is used to integrate with Project Navigator and PlanAhead

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
ENTITY arwen_prog_ila IS
  port (
    CONTROL: inout std_logic_vector(35 downto 0);
    CLK: in std_logic;
    DATA: in std_logic_vector(255 downto 0);
    TRIG0: in std_logic_vector(7 downto 0));
END arwen_prog_ila;

ARCHITECTURE arwen_prog_ila_a OF arwen_prog_ila IS
BEGIN

END arwen_prog_ila_a;
