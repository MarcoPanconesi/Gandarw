-------------------------------------------------------------------------------
-- Copyright (c) 2022 Xilinx, Inc.
-- All Rights Reserved
-------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor     : Xilinx
-- \   \   \/     Version    : 14.7
--  \   \         Application: XILINX CORE Generator
--  /   /         Filename   : gtp_if_ila.vhd
-- /___/   /\     Timestamp  : Thu Jun 16 16:07:33 ora legale Europa occidentale 2022
-- \   \  /  \
--  \___\/\___\
--
-- Design Name: VHDL Synthesis Wrapper
-------------------------------------------------------------------------------
-- This wrapper is used to integrate with Project Navigator and PlanAhead

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
ENTITY gtp_if_ila IS
  port (
    CONTROL: inout std_logic_vector(35 downto 0);
    CLK: in std_logic;
    DATA: in std_logic_vector(63 downto 0);
    TRIG0: in std_logic_vector(15 downto 0));
END gtp_if_ila;

ARCHITECTURE gtp_if_ila_a OF gtp_if_ila IS
BEGIN

END gtp_if_ila_a;
