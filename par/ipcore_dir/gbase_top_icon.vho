-------------------------------------------------------------------------------
-- Copyright (c) 2022 Xilinx, Inc.
-- All Rights Reserved
-------------------------------------------------------------------------------
--   ____  ____
--  /   /\/   /
-- /___/  \  /    Vendor     : Xilinx
-- \   \   \/     Version    : 14.7
--  \   \         Application: Xilinx CORE Generator
--  /   /         Filename   : gbase_top_icon.vho
-- /___/   /\     Timestamp  : Thu Feb 03 15:51:27 ora solare Europa occidentale 2022
-- \   \  /  \
--  \___\/\___\
--
-- Design Name: ISE Instantiation template
-- Component Identifier: xilinx.com:ip:chipscope_icon:1.06.a
-------------------------------------------------------------------------------
-- The following code must appear in the VHDL architecture header:

------------- Begin Cut here for COMPONENT Declaration ------ COMP_TAG
component gbase_top_icon
  PORT (
    CONTROL0 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CONTROL1 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CONTROL2 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CONTROL3 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CONTROL4 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CONTROL5 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CONTROL6 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0);
    CONTROL7 : INOUT STD_LOGIC_VECTOR(35 DOWNTO 0));

end component;

-- COMP_TAG_END ------ End COMPONENT Declaration ------------
-- The following code must appear in the VHDL architecture
-- body. Substitute your own instance name and net names.
------------- Begin Cut here for INSTANTIATION Template ----- INST_TAG

your_instance_name : gbase_top_icon
  port map (
    CONTROL0 => CONTROL0,
    CONTROL1 => CONTROL1,
    CONTROL2 => CONTROL2,
    CONTROL3 => CONTROL3,
    CONTROL4 => CONTROL4,
    CONTROL5 => CONTROL5,
    CONTROL6 => CONTROL6,
    CONTROL7 => CONTROL7);

-- INST_TAG_END ------ End INSTANTIATION Template ------------
