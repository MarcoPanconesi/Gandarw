------------------------------------------------------------------------------------------------
-- This model is the property of Cypress Semiconductor Corp and is protected 
-- by the US copyright laws, any unauthorized copying and distribution is prohibited.
-- Cypress reserves the right to change any of the functional specifications without
-- any prior notice.
-- Cypress is not liable for any damages which may result from the use of this 
-- functional model.
--
--  
--	Model:	CY7C1515V18 2M x 36 QDR(tm)-II Burst-of-4 SRAM
-- 	Date:	September 21, 2005
--
--	Release:	1.0
--
--	Description: This is the VHDL functional model of the QDR(tm)-II SRAM. This information
--		     is confidential. 
--
--	Revision History
--	Rev 1.0- First revision of model
--
--      Note: - BSDL model available separately
--            - Set simulator resolution to 'pS' timescale
--    	      - Simulator: Model Technology
------------------------------------------------------------------------------------------------
LIBRARY IEEE;
    USE IEEE.STD_LOGIC_1164.ALL;
    USE IEEE.STD_LOGIC_UNSIGNED.ALL;
    USE IEEE.STD_LOGIC_ARITH.ALL;

ENTITY CY7C1515bV18_c0 IS
    GENERIC (
        -- Constant Parameters
        addr_bits : INTEGER :=      19;         -- This is external address
        data_bits : INTEGER :=      36; 
        mem_sizes : INTEGER :=  2097151;

        
	 -- Clock Times for 300 Mhz device
        --tCYC    : TIME    :=       3.3 ns;
        --tKH     : TIME    :=       1.32 ns;
        --tKL     : TIME    :=       1.32 ns;

        -- Output Times
        --tCO     : TIME    :=       0.45 ns;

        -- Setup Times
        --tSA     : TIME    :=       0.4 ns;
        --tSC     : TIME    :=       0.4 ns;
        --tSD     : TIME    :=       0.3 ns;

        -- Hold Times
        --tHA     : TIME    :=       0.4 ns;
        --tHC     : TIME    :=       0.4 ns;
        --tHD     : TIME    :=       0.3 ns

	
	-- Clock Times for 250 Mhz device
        --tCYC    : TIME    :=       4.0 ns;
        --tKH     : TIME    :=       1.6 ns;
        --tKL     : TIME    :=       1.6 ns;

        -- Output Times
        --tCO     : TIME    :=       0.45 ns;

        -- Setup Times
        --tSA     : TIME    :=       0.5 ns;
        --tSC     : TIME    :=       0.5 ns;
        --tSD     : TIME    :=       0.35 ns;

        -- Hold Times
        --tHA     : TIME    :=       0.5 ns;
        --tHC     : TIME    :=       0.5 ns;
        --tHD     : TIME    :=       0.35 ns
        
        -- Clock Times for 200 Mhz device
        tCYC    : TIME    :=       5.0 ns;
        tKH     : TIME    :=       2.0 ns;
        tKL     : TIME    :=       2.0 ns;

        -- Output Times
        tCO     : TIME    :=       0.45 ns;

        -- Setup Times
        tSA     : TIME    :=       0.6 ns;
        tSC     : TIME    :=       0.6 ns;
        tSD     : TIME    :=       0.4 ns;

        -- Hold Times
        tHA     : TIME    :=       0.6 ns;
        tHC     : TIME    :=       0.6 ns;
        tHD     : TIME    :=       0.4 ns
        
--        -- Clock Times for 167 Mhz device
--        tCYC    : TIME    :=       6.0 ns;
--        tKH     : TIME    :=       2.4 ns;
--        tKL     : TIME    :=       2.4 ns;
--
--        -- Output Times
--        tCO     : TIME    :=       0.5 ns;
--
--        -- Setup Times
--        tSA     : TIME    :=       0.7 ns;
--        tSC     : TIME    :=       0.7 ns;
--        tSD     : TIME    :=       0.5 ns;
--
--        -- Hold Times
--        tHA     : TIME    :=       0.7 ns;
--        tHC     : TIME    :=       0.7 ns;
--        tHD     : TIME    :=       0.5 ns
    );
    
    PORT (
        D         : IN    STD_LOGIC_VECTOR (data_bits - 1 DOWNTO 0);
        Q         : OUT   STD_LOGIC_VECTOR (data_bits - 1 DOWNTO 0);
        A        : IN    STD_LOGIC_VECTOR (addr_bits - 1 DOWNTO 0);
        RPS_n       : IN    STD_LOGIC;
        WPS_n       : IN    STD_LOGIC;
        BW_n      : IN    STD_LOGIC_VECTOR (3 DOWNTO 0);
        K         : IN    STD_LOGIC;
        K_n       : IN    STD_LOGIC;
        C         : IN    STD_LOGIC;
        C_n       : IN    STD_LOGIC;
        CQ        : OUT   STD_LOGIC;
        CQ_n      : OUT   STD_LOGIC
    );
END CY7C1515bV18_c0;

ARCHITECTURE behave OF CY7C1515bV18_c0 IS
    TYPE memory  IS ARRAY (mem_sizes DOWNTO 0) OF STD_LOGIC_VECTOR (data_bits - 1 DOWNTO 0);
    TYPE a4xaddr IS ARRAY (3 DOWNTO 0) OF STD_LOGIC_VECTOR (addr_bits - 1 DOWNTO 0);
    TYPE a4xcmnd IS ARRAY (3 DOWNTO 0) OF STD_LOGIC;

    SIGNAL C_Int, C_Int_n, C_chk : STD_LOGIC;
    SIGNAL Output_buf : STD_LOGIC_VECTOR (data_bits - 1 DOWNTO 0) := (OTHERS => 'Z');
    SIGNAL Output_reg : STD_LOGIC_VECTOR (data_bits - 1 DOWNTO 0) := (OTHERS => 'Z');
BEGIN
    -- Output Buffer
    Q <= Output_buf;
    
    -- Internal Output Clock Generators
    C_Int <= TRANSPORT K AFTER tCO WHEN (C_chk = '1') ELSE C AFTER tCO;
    C_Int_n <= TRANSPORT K_n AFTER tCO WHEN (C_chk = '1') ELSE C_n AFTER tCO;

    -- Echo Clock Generator
    CQ <= C_Int;
    CQ_n <= C_Int_n;
    
    main : PROCESS
        -- Memory Array
        VARIABLE Bank0 : memory;
        
        -- Declare Connection Variables
        VARIABLE Data_in_enable  : STD_LOGIC := '0';
        VARIABLE Data_out_enable : STD_LOGIC := '0';

        VARIABLE Input_reg  : STD_LOGIC_VECTOR (data_bits - 1 DOWNTO 0);

        VARIABLE Addr_read_reg  : STD_LOGIC_VECTOR (addr_bits - 1 DOWNTO 0);
        VARIABLE Addr_write_reg : STD_LOGIC_VECTOR (addr_bits - 1 DOWNTO 0);

        -- Pipeline Variables
        VARIABLE Addr_pipe : a4xaddr;
        VARIABLE Cmnd_pipe : a4xcmnd;

        -- Counter
        VARIABLE Burst_read_counter  : STD_LOGIC_VECTOR (1 DOWNTO 0);
        VARIABLE Burst_write_counter : STD_LOGIC_VECTOR (1 DOWNTO 0);

    BEGIN
        WAIT ON K, K_n, C_Int, C_Int_n;

        -- Data IO
        IF ((K'EVENT AND K = '1') OR (K_n'EVENT AND K_n = '1')) THEN
            -- Check C toggle
            IF C = '1' AND C_n = '1' THEN
                C_chk <= '1';
            ELSE
                C_chk <= '0';
            END IF;

            -- Command Pipeline
            Cmnd_pipe (0) := Cmnd_pipe (1);
            Cmnd_pipe (1) := Cmnd_pipe (2);
            Cmnd_pipe (2) := Cmnd_pipe (3);
            Cmnd_pipe (3) := 'X';

            -- Address Pipeline
            Addr_pipe (0) := Addr_pipe (1);
            Addr_pipe (1) := Addr_pipe (2);
            Addr_pipe (2) := Addr_pipe (3);
            Addr_pipe (3) := (OTHERS => 'X');

            -- Internal Read or Write Command
            IF (Cmnd_pipe (0) = '0') THEN
                Data_in_enable := '1';
                Addr_write_reg := Addr_pipe (0);
                Burst_write_counter := "00";
            ELSIF (Cmnd_pipe (0) = '1') THEN
                Data_out_enable := '1';
                Addr_read_reg := Addr_pipe (0);
                Burst_read_counter := "00";
            END IF;

            -- Data In Register
            IF (Data_in_enable = '1') THEN
                -- Read Data Into Input Register
                Input_reg := Bank0 (CONV_INTEGER(Addr_write_reg & Burst_write_counter));
                
                -- Perform BW# Operation
                IF (BW_n (0) = '0') THEN
                    Input_reg ( 8 DOWNTO  0) := D ( 8 DOWNTO  0);
                END IF;
                IF (BW_n (1) = '0') THEN
                    Input_reg (17 DOWNTO  9) := D (17 DOWNTO  9);
                END IF;
                IF (BW_n (2) = '0') THEN
                    Input_reg (26 DOWNTO 18) := D (26 DOWNTO 18);
                END IF;
                IF (BW_n (3) = '0') THEN
                    Input_reg (35 DOWNTO 27) := D (35 DOWNTO 27);
                END IF;
                
                -- Write Back to Memory
                Bank0 (CONV_INTEGER(Addr_write_reg & Burst_write_counter)) := Input_reg;
                
                -- Reset
                IF (Burst_write_counter = "11" AND Data_in_enable = '1') THEN
                    Data_in_enable := '0';
                END IF;

                -- Increasement Counter
                Burst_write_counter := Burst_write_counter + 1;
            END IF;

            -- Data Out Register
            IF (Data_out_enable = '1') THEN
                -- Read Data Into Output Register
                Output_reg <= Bank0 (CONV_INTEGER (Addr_read_reg & Burst_read_counter)) AFTER tCO;

                -- Reset
                IF (Burst_read_counter = "11" AND Data_out_enable = '1') THEN
                    Data_out_enable := '0';
                END IF;

                -- Increasement Counter
                Burst_read_counter := Burst_read_counter + 1;
            ELSE
                Output_reg <= (OTHERS => 'Z') AFTER tCO;
            END IF;
        END IF;

        -- Latch External Command
        IF (K'EVENT AND K = '1') THEN
        	   IF (RPS_n = '0' AND Cmnd_pipe (1) /= '1') THEN
                Cmnd_pipe (3) := '1';
                Addr_pipe (3) := A;
            ELSIF (RPS_n = '0' AND WPS_n = '0' AND Cmnd_pipe (1) = '1') THEN
            	   Cmnd_pipe (2) := '0';
                Addr_pipe (2) := A;
            ELSIF (WPS_n = '0' AND RPS_n = '1' AND Cmnd_pipe (0) /= '0') THEN
                Cmnd_pipe (2) := '0';
                Addr_pipe (2) := A;
            END IF;
        END IF;

        --Output Buffer
        IF ((C_Int'EVENT AND C_Int = '1') OR (C_Int_n'EVENT AND C_Int_n = '1')) THEN   
            Output_buf <= Output_reg;
        END IF; 
    END PROCESS main;

    -- Check for K Timing Violation
    K_check : PROCESS
        VARIABLE k_high, k_low : TIME := 0 ns;
    BEGIN
        WAIT ON K;
        IF K = '1' AND NOW >= tCYC THEN
            ASSERT (NOW - k_low >= tKH)
                REPORT "K width low - tKH violation"
                SEVERITY ERROR;
            ASSERT (NOW - k_high >= tCYC)
                REPORT "K period high - tCYC violation"
                SEVERITY ERROR;
            k_high := NOW;
        ELSIF K = '0' AND NOW >= tCYC THEN
            ASSERT (NOW - k_high >= tKL)
                REPORT "K width high - tKL violation"
                SEVERITY ERROR;
            ASSERT (NOW - k_low >= tCYC)
                REPORT "K period low - tCYC violation"
                SEVERITY ERROR;
            k_low := NOW;
        END IF;
    END PROCESS;

    -- Check for K# Timing Violation
    K_n_check : PROCESS
        VARIABLE k_n_high, k_n_low : TIME := 0 ns;
    BEGIN
        WAIT ON K_n;
        IF K_n = '1' AND NOW >= tCYC THEN
            ASSERT (NOW - k_n_low >= tKH)
                REPORT "K# width low - tKH violation"
                SEVERITY ERROR;
            ASSERT (NOW - k_n_high >= tCYC)
                REPORT "K# period high - tCYC violation"
                SEVERITY ERROR;
            k_n_high := NOW;
        ELSIF K_n = '0' AND NOW >= tCYC THEN
            ASSERT (NOW - k_n_high >= tKL)
                REPORT "K# width high - tKL violation"
                SEVERITY ERROR;
            ASSERT (NOW - k_n_low >= tCYC)
                REPORT "K# period low - tCYC violation"
                SEVERITY ERROR;
            k_n_low := NOW;
        END IF;
    END PROCESS;

    -- Check for C Timing Violation
    C_check : PROCESS
        VARIABLE c_high, c_low : TIME := 0 ns;
    BEGIN
        WAIT ON C;
        IF C = '1' AND NOW >= tCYC THEN
            ASSERT (NOW - c_low >= tKH)
                REPORT "C width low - tKH violation"
                SEVERITY ERROR;
            ASSERT (NOW - c_high >= tCYC)
                REPORT "C period high - tCYC violation"
                SEVERITY ERROR;
            c_high := NOW;
        ELSIF C = '0' AND NOW >= tCYC THEN
            ASSERT (NOW - c_high >= tKL)
                REPORT "C width high - tKL violation"
                SEVERITY ERROR;
            ASSERT (NOW - c_low >= tCYC)
                REPORT "C period low - tCYC violation"
                SEVERITY ERROR;
            c_low := NOW;
        END IF;
    END PROCESS;

    -- Check for C# Timing Violation
    C_n_check : PROCESS
        VARIABLE c_n_high, c_n_low : TIME := 0 ns;
    BEGIN
        WAIT ON C_n;
        IF C_n = '1' AND NOW >= tCYC THEN
            ASSERT (NOW - c_n_low >= tKH)
                REPORT "C# width low - tKH violation"
                SEVERITY ERROR;
            ASSERT (NOW - c_n_high >= tCYC)
                REPORT "C# period high - tCYC violation"
                SEVERITY ERROR;
            c_n_high := NOW;
        ELSIF K_n = '0' AND NOW >= tCYC THEN
            ASSERT (NOW - c_n_high >= tKL)
                REPORT "C# width high - tKL violation"
                SEVERITY ERROR;
            ASSERT (NOW - c_n_low >= tCYC)
                REPORT "C# period low - tCYC violation"
                SEVERITY ERROR;
            c_n_low := NOW;
        END IF;
    END PROCESS;

    -- Check for Setup Timing Violation
    setup_check : PROCESS
    BEGIN
        WAIT ON K;
        IF K = '1' THEN
            ASSERT (RPS_n'LAST_EVENT >= tSC)
                REPORT "R# - tSC violation"
                SEVERITY ERROR;
            ASSERT (WPS_n'LAST_EVENT >= tSC)
                REPORT "W# - tSC violation"
                SEVERITY ERROR;
            ASSERT (A'LAST_EVENT >= tSA)
                REPORT "A - tSA violation"
                SEVERITY ERROR;
            ASSERT (D'LAST_EVENT >= tSD)
                REPORT "D - tSD violation"
                SEVERITY ERROR;
        END IF;
    END PROCESS;

    -- Check for Hold Timing Violation
    tHC_check : PROCESS
    BEGIN
        WAIT ON K'DELAYED(tHC);
        IF K'DELAYED(tHC) = '1' THEN
            ASSERT (RPS_n'LAST_EVENT > tHC)
                REPORT "R# - tHC violation"
                SEVERITY ERROR;
            ASSERT (WPS_n'LAST_EVENT > tHC)
                REPORT "W# - tHC violation"
                SEVERITY ERROR;
        END IF;
    END PROCESS;

    tHA_check : PROCESS
    BEGIN
        WAIT ON K'DELAYED(tHA);
        IF K'DELAYED(tHA) = '1' THEN
            ASSERT (A'LAST_EVENT > tHA)
                REPORT "A - tHA violation"
                SEVERITY ERROR;
        END IF;
    END PROCESS;

    tHD_check : PROCESS
    BEGIN
        WAIT ON K'DELAYED(tHD);
        IF K'DELAYED(tHD) = '1' THEN
            ASSERT (D'LAST_EVENT > tHD)
                REPORT "D - tHD violation"
                SEVERITY ERROR;
        END IF;
    END PROCESS;

END behave; 
