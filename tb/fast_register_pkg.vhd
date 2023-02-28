-- vsg_off
----------------------------------------------------------------------------------
-- Company:         INFN-LNF
-- Engineer:        alessandro.balla@lnf.infn.it
-- 
-- Create Date:     11:43:03 19/07/2021 
-- Design Name: 
-- Module Name:     fast_register_pkg.vhd - TestBench 
-- Project Name:    GANDARW
-- Target Devices:  XC5VSX95T-2FF1136
-- Tool versions:   ISE 14.7, QUESTASIM 10.7
-- Description:     Mix of Gandalf (amc) and Arwen\gbase_arwen 
--
-- Dependencies:    CPLD, DDR
--
-- Revision:        Revision 0.01 - File Created
--
-- Comments:        From "GANDALF Framework User Guide"
--                  Version 1.1 December 2011
--                  CPLD design 2.2.2 ver 1.1 (12/06/2011)
--
-- TestBench :      \Xil_14.7\GandArw\rtl\tb\testbench.vhd
-- Package :        \Xil_14.7\GandArw\rtl\tb\fast_register_pkg.vhd
----------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.STD_LOGIC_UNSIGNED.ALL;

LIBRARY STD;
USE STD.STANDARD.ALL;
USE STD.TEXTIO.ALL;

USE WORK.IEEE_TO_STRING.ALL;
USE WORK.G_PARAMETERS.ALL;
USE WORK.VME_PKG.ALL;

package FAST_REGISTER_PKG is

-- Procedure body
    -- VME
    procedure x_boardstatus(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);
    procedure x_r_vision_fifo(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);
    procedure x_armbroadcast(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);
    procedure x_bc_fpga_cfg(v_data : in std_logic_vector(31 downto 0); signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);
    procedure x_bc_switch(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);
    procedure x_display_w(v_data : in std_logic_vector(31 downto 0);signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);
    -- not yet implemented :
    -- procedure x_cfm_r_w(v_data : in std_logic_vector(31 downto 0);signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);
    -- procedure x_set_fr(v_data : in std_logic_vector(31 downto 0);signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);

    -- FAST REGISTER
    procedure x_fr_dac_calib_enable(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);      --  3
    procedure x_fr_dac_calib_disable(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);     --  3
    procedure x_fr_trg_temp_rdout(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);        --  4
    procedure x_fr_trg_volt_rdout(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);        --  5
    -- da rivedere queste 4 ...
    procedure x_fr_rd_eeprom_up(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);          --  6
    procedure x_fr_wr_eeprom_up(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);          --  7
    procedure x_fr_rd_eeprom_dw(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);          --  8
    procedure x_fr_wr_eeprom_dw(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);          --  9
    --
    procedure x_fr_load_si(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);               -- 10                
    procedure x_fr_load_dacs(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);             -- 11   
    procedure x_fr_load_ips(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);              -- 12       
    procedure x_fr_read_gta_conf(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);         -- 13       
    procedure x_fr_vme_reset0(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);            -- 14       
    procedure x_fr_vme_reset1(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);            -- 15       
    procedure x_fr_ext_bor(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);               -- 16       
    procedure x_fr_ext_bos(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);               -- 17   
    procedure x_fr_ext_eos(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);               -- 18   
    procedure x_fr_art_trg(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);               -- 19   
    procedure x_fr_slink_reset(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);           -- 20       
    procedure x_fr_smux_reset(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);            -- 21       
    procedure x_fr_wr_status(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);             -- 22
    -- not yet implemented :
    -- procedure x_fr_res_ct_bos(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);
    -- procedure x_fr_self_trig(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);
    -- procedure x_fr_toggle_tcs_rate(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);
    procedure x_fr_clear_biterr_flag(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);     -- 31 
    procedure x_fr_readouttigerready(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);     -- 41 
    procedure x_fr_triggertigerready(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);     -- 42 
    procedure x_fr_startvxslinkcal_0(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);     -- 43 
    procedure x_fr_startvxslinkcal_1(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);     -- 43 
    procedure x_fr_write_gta_conf(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);        -- 50        
    procedure x_fr_read_gta_delay(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);        -- 51        
    procedure x_fr_read_adc_edge_info(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);    -- 52           
    procedure x_fr_data_valid(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);            -- 53   
    procedure x_fr_sweep_si(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);              -- 60
    procedure x_fr_phase_align_si(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);        -- 61       
    procedure x_fr_reset_si(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);              -- 62   
    procedure x_fr_out_slink_en(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);          -- 70-71   
    procedure x_fr_out_vxs_en(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);            -- 70-71   
    procedure x_fr_out_arw_en(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);            -- 70-71   
    procedure x_fr_out_disable(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);           -- 70-71   
    procedure x_fr_out_spy_en(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);            -- 72   
    procedure x_fr_out_spy_dis(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);           -- 72   

    procedure x_fr_res_mem_fpga(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);          -- 132   
    procedure x_fr_en_prog_arwen(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out);         -- 133   

    
end;

package body FAST_REGISTER_PKG is

-- Procedure declaration
-------------------------------------------------------------------------------
-- VME Interface Registers
    -- Return Board status
    procedure x_boardstatus(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
        variable v_data : std_logic_vector(31 downto 0);
    begin
        vme_read(
                c_addr  => X"E0" & not BS_DIP & X"00FC",
                c_data  => v_data,
                vme_i   => vme_i,
                vme_o   => vme_o
                );
        report "BOARDSTATUS : HEXID = " & to_hexstring(v_data(27 downto 20)) & " GEOADD = " & to_hexstring(v_data(17 downto 12)) & " SN = " & to_hexstring(v_data(9 downto 0));
    end;

    -- Return valid data from spy fifo
    procedure x_r_vision_fifo(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
        variable v_data : std_logic_vector(31 downto 0);
    begin
        vme_read(
                c_addr  => X"E0" & not BS_DIP & X"3000",
                c_data  => v_data,
                vme_i   => vme_i,
                vme_o   => vme_o
                );
        report "Read Spy Fifo : HEX = " & to_hexstring(v_data(31 downto 0));
        -- For some reason the cpld assert also the BERR signal
        -- after assert DTACK, put here a delay to avoid BERR Timeout ...
        wait for 300 ns; 
    end;

    -- Reset module with hexid(8) to accept broadcasting data
    procedure x_armbroadcast(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
                c_addr  => X"E0" & not BS_DIP & X"0010",
                c_data  => X"00000000",
                vme_i   => vme_i,
                vme_o   => vme_o
                );
        report "Reset module with hexid(8) to accept broadcasting data";
    end;

    -- VME address to write broadcast configuration data for DSP configuration to MEM configuration
    procedure x_bc_fpga_cfg(v_data : in std_logic_vector(31 downto 0); signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
                c_addr  => X"E0" & not BS_DIP & X"8000",
                c_data  => v_data,
                vme_i   => vme_i,
                vme_o   => vme_o
                );
        report "Switch from DSP configuration to MEM configuration";
    end;

    -- VME address to switch from DSP configuration to MEM configuration
    procedure x_bc_switch(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
                c_addr  => X"E0" & not BS_DIP & X"0014",
                c_data  => X"00000000",
                vme_i   => vme_i,
                vme_o   => vme_o
                );
        report "Switch from DSP configuration to MEM configuration";
    end;

    -- VME address to write data to the front display. Use the DATAWORD(32) = DISP0(8) & DISP1(8) & DISP2(8) & DISP3(8) 
    -- to define the values shown on the 4 segment display. The following values can be set with
    -- corresponding hex values 0x00 to 0x12: = 0,1,2,...,9,A,B,C,D,E,F,G,S,X.
    procedure x_display_w(v_data : in std_logic_vector(31 downto 0); signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
                c_addr  => X"E0" & not BS_DIP & X"0004",
                c_data  => v_data,
                vme_i   => vme_i,
                vme_o   => vme_o
                );
        report "Write display value Hex = " & to_hexstring(v_data(7 downto 0)) & to_hexstring(v_data(15 downto 8)) & to_hexstring(v_data(23 downto 16)) & to_hexstring(v_data(31 downto 24));
    end;

-- FAST REGISTERS
    -- VHDL Fast Register signal 3 
    -- Enables DAC calibration.
    procedure x_fr_dac_calib_enable(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
                c_addr  => X"E0" & not BS_DIP & X"7" & X"00C", 
                c_data  => X"00000001",
                vme_i   => vme_i,
                vme_o   => vme_o
        );
    end;

    -- VHDL Fast Register signal 3
    -- Disables DAC calibration.
    procedure x_fr_dac_calib_disable(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
                c_addr  => X"E0" & not BS_DIP & X"7" & X"00C", 
                c_data  => X"00000000",
                vme_i   => vme_i,
                vme_o   => vme_o
        );
    end;

    -- VHDL Fast Register signal 4
    -- Triggers readout of all temperature values (AMC,FPGA temp sensors) 
procedure x_fr_trg_temp_rdout(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
                c_addr  => X"E0" & not BS_DIP & X"7" & X"010", 
                c_data  => X"00000002",
                vme_i   => vme_i,
                vme_o   => vme_o
        );
    end;

    -- VHDL Fast Register signal 5
    -- Triggers readout of all voltage values (FPGA voltage sensors) 
    procedure x_fr_trg_volt_rdout(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
                c_addr  => X"E0" & not BS_DIP & X"7" & X"014", 
                c_data  => X"00000002",
                vme_i   => vme_i,
                vme_o   => vme_o
        );
    end;

    -- VHDL Fast Register signal 6 -- non esiste in gandalf da implementare ...
    -- Triggers readout of EEPROM data to configuration memory of mezzanine
    -- in card slot up (this takes 200ms).
    procedure x_fr_rd_eeprom_up(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
                c_addr  => X"E0" & not BS_DIP & X"7" & X"018", 
                c_data  => X"00000002",
                vme_i   => vme_i,
                vme_o   => vme_o
        );
    end;

    -- VHDL Fast Register signal 7 -- non esiste in gandalf da implementare ...
    -- Triggers storage of configuration memory data to EEPROM of mezzanine in
    -- card slot up (this takes 1.0s)
    procedure x_fr_wr_eeprom_up(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
                c_addr  => X"E0" & not BS_DIP & X"7" & X"01C", 
                c_data  => X"00000002",
                vme_i   => vme_i,
                vme_o   => vme_o
        );
    end;

    -- VHDL Fast Register signal 8 -- in gandalf legge la dw e la up partendo da dw ...
    -- Triggers readout of EEPROM data to configuration memory of mezzanine
    -- in card slot dw (this takes 200ms).
    procedure x_fr_rd_eeprom_dw(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
                c_addr  => X"E0" & not BS_DIP & X"7" & X"020", 
                c_data  => X"00000002",
                vme_i   => vme_i,
                vme_o   => vme_o
        );
    end;

    -- VHDL Fast Register signal 9 -- in gandalf scrive la dw e la up partendo da dw ...
    -- Triggers storage of configuration memory data to EEPROM of mezzanine in
    -- card slot dw (this takes 1.0s)
    procedure x_fr_wr_eeprom_dw(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
                c_addr  => X"E0" & not BS_DIP & X"7" & X"024", 
                c_data  => X"00000002",
                vme_i   => vme_i,
                vme_o   => vme_o
        );
    end;

    -- VHDL Fast Register signal 10
    -- Triggers configuration of the SI5326 clock synthesizer located on
    -- the GANDALF module and all SI5326 on the mounted AMCs. The
    -- configuration data is stored in the configuration memory registers
    -- SI_CONF_DATA0 - SI_CONF_DATA11
procedure x_fr_load_si(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
                c_addr  => X"E0" & not BS_DIP & X"7" & X"028", 
                c_data  => X"00000002",
                vme_i   => vme_i,
                vme_o   => vme_o
        );
    end;

    -- VHDL Fast Register signal 11
    -- Triggers configuration of the AD5665R DACs located on the AMCs. The
    -- DAC values are stored in the configuration memory registers 
    -- DAC_V AL0 - DAC_V AL3.
    procedure x_fr_load_dacs(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
                c_addr  => X"E0" & not BS_DIP & X"7" & X"02C", 
                c_data  => X"00000002",
                vme_i   => vme_i,
                vme_o   => vme_o
        );
    end;

    -- VHDL Fast Register signal 12
    -- Load the IP address in cf_mem to ARWEN FPGA. 
    procedure x_fr_load_ips(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
                c_addr  => X"E0" & not BS_DIP & X"7" & X"030", 
                c_data  => X"00000002",
                vme_i   => vme_i,
                vme_o   => vme_o
        );
    end;

    -- VHDL Fast Register signal 13
    -- Updates all configuration values written into the configuration memory to
    -- the active FPGA logic. (fr_load_gconf_val)
    procedure x_fr_read_gta_conf(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
                c_addr  => X"E0" & not BS_DIP & X"7" & X"034", 
                c_data  => X"00000002",
                vme_i   => vme_i,
                vme_o   => vme_o
        );
    end;

    -- VHDL Fast Register signal 14
    -- Performs a reset on reset level 0.
    procedure x_fr_vme_reset0(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
                c_addr  => X"E0" & not BS_DIP & X"7" & X"038", 
                c_data  => X"00000002",
                vme_i   => vme_i,
                vme_o   => vme_o
        );
    end;

    -- VHDL Fast Register signal 15
    -- Performs a reset on reset level 1.
    procedure x_fr_vme_reset1(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
                c_addr  => X"E0" & not BS_DIP & X"7" & X"03C", 
                c_data  => X"00000002",
                vme_i   => vme_i,
                vme_o   => vme_o
        );
    end;

    -- VHDL Fast Register signal 16
    -- Used to generate an artificial BOR signal. Can be used if no TCS is adapted.
    procedure x_fr_ext_bor(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
                c_addr  => X"E0" & not BS_DIP & X"7" & X"040", 
                c_data  => X"00000002",
                vme_i   => vme_i,
                vme_o   => vme_o
        );
    end;

    -- VHDL Fast Register signal 17
    -- Used to generate an artificial BOS signal. Can be used if no TCS is adapted.
    procedure x_fr_ext_bos(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
                c_addr  => X"E0" & not BS_DIP & X"7" & X"044", 
                c_data  => X"00000002",
                vme_i   => vme_i,
                vme_o   => vme_o
        );
    end;

    -- VHDL Fast Register signal 18
    -- Used to generate an artificial EOS signal. Can be used if no TCS is adapted.
    procedure x_fr_ext_eos(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
                c_addr  => X"E0" & not BS_DIP & X"7" & X"048", 
                c_data  => X"00000002",
                vme_i   => vme_i,
                vme_o   => vme_o
        );
    end;

    -- VHDL Fast Register signal 19
    -- Used to generate an artificial trigger signal. Can be used if no TCS is adapted.
    procedure x_fr_art_trg(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
                c_addr  => X"E0" & not BS_DIP & X"7" & X"04C", 
                c_data  => X"00000002",
                vme_i   => vme_i,
                vme_o   => vme_o
        );
    end;

    -- VHDL Fast Register signal 20
    -- Triggers the S-LINK reset procedure as explained in the S-LINK specification
    procedure x_fr_slink_reset(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
                c_addr  => X"E0" & not BS_DIP & X"7" & X"050", 
                c_data  => X"00000002",
                vme_i   => vme_i,
                vme_o   => vme_o
        );
    end;

    -- VHDL Fast Register signal 21
    -- Triggers a reset signal on the SRESET pin C30 (P2,see Tab. 3.2) to perform
    -- a common reset on up to four SMUX transition cards.
    procedure x_fr_smux_reset(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
                c_addr  => X"E0" & not BS_DIP & X"7" & X"054", 
                c_data  => X"00000002",
                vme_i   => vme_i,
                vme_o   => vme_o
        );
    end;

    -- VHDL Fast Register signal 22
    -- Trigger a signal to write all the status in the cf_mem 
    procedure x_fr_wr_status(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
                c_addr  => X"E0" & not BS_DIP & X"7" & X"058", 
                c_data  => X"00000002",
                vme_i   => vme_i,
                vme_o   => vme_o
        );
    end;


    -- VHDL Fast Register signal 31
    -- Triggers a reset signal on the reset edge status of ADC bits. 
    procedure x_fr_clear_biterr_flag(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
                c_addr  => X"E0" & not BS_DIP & X"7" & X"07C", 
                c_data  => X"00000002",
                vme_i   => vme_i,
                vme_o   => vme_o
        );
    end;

    -- VHDL Fast Register signal 41
    -- Must be set to 1, when ReadoutTiger is ready. Enables the VXS SLINK outputs
    procedure x_fr_readouttigerready(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
                c_addr  => X"E0" & not BS_DIP & X"7" & X"0A4", 
                c_data  => X"00000001",
                vme_i   => vme_i,
                vme_o   => vme_o
        );
    end;

    -- VHDL Fast Register signal 42
    -- Must be set to 1, when TriggerTiger is ready. Enables the VXS Trigger outputs
    procedure x_fr_triggertigerready(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
                c_addr  => X"E0" & not BS_DIP & X"7" & X"0A8", 
                c_data  => X"00000001",
                vme_i   => vme_i,
                vme_o   => vme_o
        );
    end;

    -- VHDL Fast Register signal 43
    -- Used to start the calibration of the VXS data transfer link, set to '0'
    procedure x_fr_startvxslinkcal_0(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
                c_addr  => X"E0" & not BS_DIP & X"7" & X"0A0", 
                c_data  => X"00000000",
                vme_i   => vme_i,
                vme_o   => vme_o
        );
    end;

    -- VHDL Fast Register signal 43
    -- Used to start the calibration of the VXS data transfer link, set to '1'
    procedure x_fr_startvxslinkcal_1(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
                c_addr  => X"E0" & not BS_DIP & X"7" & X"0A0", 
                c_data  => X"00000001",
                vme_i   => vme_i,
                vme_o   => vme_o
        );
    end;

    -- VHDL Fast Register signal 50
    -- Updates all configuration values written into the active FPGA logic to
    -- the configuration memory. (fr_load_gconf_val)
    procedure x_fr_write_gta_conf(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
                c_addr  => X"E0" & not BS_DIP & X"7" & X"0C8", 
                c_data  => X"00000002",
                vme_i   => vme_i,
                vme_o   => vme_o
        );
    end;

    -- VHDL Fast Register signal 51
    -- Increment the IODelay as specified in configuration register 'AMC delay setting'
    procedure x_fr_read_gta_delay(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
                c_addr  => X"E0" & not BS_DIP & X"7" & X"0CC", 
                c_data  => X"00000002",
                vme_i   => vme_i,
                vme_o   => vme_o
        );
    end;

    -- VHDL Fast Register signal 52
    -- Write the configuration register AMC edge status
    procedure x_fr_read_adc_edge_info(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
        variable v_data : std_logic_vector(31 downto 0);
    begin
        vme_write(
                c_addr  => X"E0" & not BS_DIP & X"00D0",
                c_data  => X"00000002",
                vme_i   => vme_i,
                vme_o   => vme_o
                );
        -- da capire bene, fatto a caso per ora ...
        report "*** INIT pin is = " & to_string(v_data(0)) & " and DONE pin is " & to_string(v_data(1));
    end;

    -- VHDL Fast Register signal 53
    -- Used for programming arwen fpga
    procedure x_fr_data_valid(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
                c_addr  => X"E0" & not BS_DIP & X"7" & X"0D4", 
                c_data  => X"00000002",
                vme_i   => vme_i,
                vme_o   => vme_o
        );
    end;

    -- VHDL Fast Register signal 60
    -- Starts sweep process of the SI clock sythesizers for phase offset alignment
    procedure x_fr_sweep_si(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
                c_addr  => X"E0" & not BS_DIP & X"7" & X"0F0", 
                c_data  => X"00000002",
                vme_i   => vme_i,
                vme_o   => vme_o
        );
    end;

    -- VHDL Fast Register signal 61
    -- Start phase align process of the SI clock sythesizers
    procedure x_fr_phase_align_si(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
                c_addr  => X"E0" & not BS_DIP & X"7" & X"0F4", 
                c_data  => X"00000002",
                vme_i   => vme_i,
                vme_o   => vme_o
        );
    end;

    -- VHDL Fast Register signal 62 (NOT USED/IMPLEMENTED)
    -- Resets all mounted SI chips (GANDALF and Mezzanine Card slots) using
    -- the reset in pin of the chip 
    procedure x_fr_reset_si(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
                c_addr  => X"E0" & not BS_DIP & X"7" & X"0F8", 
                c_data  => X"00000002",
                vme_i   => vme_i,
                vme_o   => vme_o
        );
    end;

    -- VHDL Fast Register signal 70-71
    -- Enable slink output from data manager
    procedure x_fr_out_slink_en(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
                c_addr  => X"E0" & not BS_DIP & X"7" & X"118", 
                c_data  => X"00000001",
                vme_i   => vme_i,
                vme_o   => vme_o
        );
        vme_write(
            c_addr  => X"E0" & not BS_DIP & X"7" & X"11C", 
            c_data  => X"00000000",
            vme_i   => vme_i,
            vme_o   => vme_o
        );
    end;

    -- VHDL Fast Register signal 70-71
    -- Enable vxs output from data manager
    procedure x_fr_out_vxs_en(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
            c_addr  => X"E0" & not BS_DIP & X"7" & X"118", 
            c_data  => X"00000000",
            vme_i   => vme_i,
            vme_o   => vme_o
        );
        vme_write(
            c_addr  => X"E0" & not BS_DIP & X"7" & X"11C", 
            c_data  => X"00000001",
            vme_i   => vme_i,
            vme_o   => vme_o
        );
  
    end;

    -- VHDL Fast Register signal 70-71
    -- Enable Arwen output from data manager
    procedure x_fr_out_arw_en(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
            c_addr  => X"E0" & not BS_DIP & X"7" & X"118", 
            c_data  => X"00000001",
            vme_i   => vme_i,
            vme_o   => vme_o
        );
        vme_write(
            c_addr  => X"E0" & not BS_DIP & X"7" & X"11C", 
            c_data  => X"00000001",
            vme_i   => vme_i,
            vme_o   => vme_o
        );
    end;

    -- VHDL Fast Register signal 70-71
    -- Disable all output from data manager
    procedure x_fr_out_disable(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
            c_addr  => X"E0" & not BS_DIP & X"7" & X"118", 
            c_data  => X"00000000",
            vme_i   => vme_i,
            vme_o   => vme_o
        );
        vme_write(
            c_addr  => X"E0" & not BS_DIP & X"7" & X"11C", 
            c_data  => X"00000000",
            vme_i   => vme_i,
            vme_o   => vme_o
        ); 
    end;

    -- VHDL Fast Register signal 72
    -- Enable spy fifo from data manager
    procedure x_fr_out_spy_en(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
            c_addr  => X"E0" & not BS_DIP & X"7" & X"120", 
            c_data  => X"00000001",
            vme_i   => vme_i,
            vme_o   => vme_o
        );
    end;

    -- VHDL Fast Register signal 72
    -- Disable spy fifo from data manager
    procedure x_fr_out_spy_dis(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
            c_addr  => X"E0" & not BS_DIP & X"7" & X"120", 
            c_data  => X"00000000",
            vme_i   => vme_i,
            vme_o   => vme_o
        );
    end;

    -- VHDL Fast Register signal 132
    -- Reset mem fpga
    procedure x_fr_res_mem_fpga(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
            c_addr  => X"E0" & not BS_DIP & X"7" & X"210", 
            c_data  => X"00000002",
            vme_i   => vme_i,
            vme_o   => vme_o
        );
    end;

    -- VHDL Fast Register signal 133
    -- enable bit to allow arwen fpga programmig
    procedure x_fr_en_prog_arwen(signal vme_i : in r_vme_in; signal vme_o : out r_vme_out) is
    begin
        vme_write(
            c_addr  => X"E0" & not BS_DIP & X"7" & X"214", 
            c_data  => X"00000001",
            vme_i   => vme_i,
            vme_o   => vme_o
        );
    end;

end;