-------------------------------------------------------------------------------
-- Copyright (c) 2013 Xilinx, Inc.
-- All Rights Reserved
-------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor     : Xilinx
-- \   \   \/     Version    : 14.2
--  \   \         Application: XILINX CORE Generator
--  /   /         Filename   : wb_np_ram_ila.vhd
-- /___/   /\     Timestamp  : Wed Mar 13 14:22:07 CET 2013
-- \   \  /  \
--  \___\/\___\
--
-- Design Name: VHDL Synthesis Wrapper
-------------------------------------------------------------------------------
-- This wrapper is used to integrate with Project Navigator and PlanAhead

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
ENTITY wb_np_ram_ila IS
  port (
    CONTROL: inout std_logic_vector(35 downto 0);
    CLK: in std_logic;
    DATA: in std_logic_vector(31 downto 0);
    TRIG0: in std_logic_vector(7 downto 0));
END wb_np_ram_ila;

ARCHITECTURE wb_np_ram_ila_a OF wb_np_ram_ila IS
BEGIN

END wb_np_ram_ila_a;
