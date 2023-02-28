library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

library UNISIM;
use UNISIM.VCOMPONENTS.all;

library UNIMACRO;
use UNIMACRO.VCOMPONENTS.all;

entity tcs_if_MEP is
    generic (
        chipscope : boolean := true;
        fpga_type : string  := "xc5vsx95t"
        );
    port (
        -- control   : inout std_logic_vector(35 downto 0);
-- tcs inputs
        TCS_CLK  : in    std_logic;  --155 MHz
        TCS_DATA : in    std_logic;


-- fast register inputs
        FR_BOS : in std_logic;
        FR_EOS : in std_logic;
        FR_TRG : in std_logic;
        
        readout_rdy : in std_logic;

-- tcs outputs

        SYNCED  : out std_logic;
        CLK38EN : out std_logic;

        BOS        : out std_logic;                                                                  
        EOS        : out std_logic;                                                                     
        FLT        : out std_logic;
        EVENT_NO   : out std_logic_vector (23 downto 0); --|
        SPILL_NO   : out std_logic_vector (10 downto 0); --| USCITA TCS_FIFO
        EVENT_TYPE : out std_logic_vector (7 downto 0);  --|                            
        FIFO_EMPTY : out std_logic;
        FIFO_FULL  : out std_logic;
--      FIFO_VALID : out std_logic;
        FIFO_RDCLK : in  std_logic;
        FIFO_RDEN  : in  std_logic;

        TIMESTAMP : out std_logic_vector (31 downto 0);
        timestamp_bv : in std_logic_vector (31 downto 0);
        TIMESTAMP_RDEN : in std_logic

        );
end tcs_if_MEP;



architecture Behavorial of tcs_if_MEP is
-------------------------------------------------------------------------------
-- the tcs fifo
    component tcs_fifo
        port (
            wr_clk : in  std_logic;
            rd_clk : in  std_logic;
            din    : in  std_logic_vector(35 downto 0);
            wr_en  : in  std_logic;
            rd_en  : in  std_logic;
            dout   : out std_logic_vector(35 downto 0);
            full   : out std_logic;
            valid  : out std_logic;
            empty  : out std_logic
            );
    end component;
-------------------------------------------------------------------------------


    signal sFLT    : std_logic;


    signal STROBE         : std_logic;
    signal sEVENT_NO      : std_logic_vector (23 downto 0) := (others =>'0');    -- it was std_logic_vector
    signal TCS_WORD       : std_logic_vector (15 downto 0); --VEN/marco
    signal FIFO_WREN      : std_logic;
    signal FIFO_WRCLK     : std_logic;
    signal EventToFIFO    : std_logic;
    signal RESET_fifo     : std_logic;

    signal FIFO_DI  : std_logic_vector (31 downto 0) := (others => '0');
    signal FIFO_DO  : std_logic_vector (31 downto 0);
    --------------------------------------------------------------
    alias regEVENT_NO   : std_logic_vector (23 downto 0) is FIFO_DI(23 downto 0);
    alias regEVENT_TYPE : std_logic_vector (7 downto 0) is FIFO_DI(31 downto 24); --VEN: prima era (4 downto 0) is FIFO_DI(35 downto 31); --marco

    alias TCS_CMD    : std_logic_vector (7 downto 0) is TCS_WORD(13 downto 6); --VEN/marco  COMANDO/DATO
    alias TCS_CHKSUM : std_logic_vector (4 downto 0) is TCS_WORD(5 downto 1); --VEN/marcO   CHECKSUM
    --l'ultimo bit è un bit di STOP

    signal clk38en_i,synced_i : std_logic;
    signal RDCOUNT,WRCOUNT : std_logic_vector(8 downto 0);
    signal RDCOUNT_1,WRCOUNT_1 : std_logic_vector(8 downto 0);
    signal sTIMESTAMP : std_logic_vector(31 downto 0) := (others =>'0');
    signal TIMESTAMP_DO : std_logic_vector(31 downto 0);

    signal FLT_i        : std_logic;
    signal TIMESTAMP_WE : std_logic;

    signal ECRST        : std_logic;
    signal BCRST        : std_logic;


    component tcs_decode_MEP
    port (DATA      : in  std_logic;
          CLK       : in  std_logic;
          CE38MHz   : out std_logic; --usiamo a 40 mhz, prima era da ven: ce38mhz  --alex/marco
          FLT       : out std_logic;
          ECRST     : out std_logic;
          BCRST     : out std_logic;
          TCS_WORD  : out std_logic_vector (15 downto 0);
          START     : out std_logic;
          SYNCED    : out std_logic
       );
end component;


-------------------------------------------------------------------------------
begin
-------------------------------------------------------------------------------
-- static connections
    
    RESET_fifo <= not synced_i or (ECRST and BCRST); --resettiamo la FIFO finchè non siamo sincronizzati o se arriva SOB_HW
    FLT <= FLT_i;

    FLT_i <= (sFLT or FR_TRG); --aggiornato a VEN con FR_TRG 


    CLK38EN <= clk38en_i;
    SYNCED  <= synced_i;

    TIMESTAMP <= TIMESTAMP_DO;  --timestamp inviato in uscita

-------------------------------------------------------------------------------


    EVENT_NO   <= FIFO_DO(23 downto 0);
    EVENT_TYPE <= FIFO_DO(31 downto 24); --VEN/marco
    BOS        <= (BCRST and ECRST) or FR_BOS; -- perchè è a 1 quando ho 11 negli ultimi due bit dopo la trigger word
    EOS        <= (not BCRST and ECRST) or FR_EOS;
    FIFO_WREN <= EventToFIFO;
    FIFO_WRCLK <= TCS_CLK; 
    --FIFO_WREN  <= EventToFIFO and (not RESET_fifo) and ( postFirstBOS);--precedente nostro che non scriveva niente prima del BOS

    --Count events internally (NA62)
    count_events: process(TCS_CLK)
    begin
        if (TCS_CLK = '1' and TCS_CLK'event) then
            TIMESTAMP_WE <= '0';

            if(clk38en_i='1') then 
                if FLT_i = '1' then
                    sEVENT_NO <= sEVENT_NO + 1;         -- (EV COUNTER)
                    TIMESTAMP_WE <= '1';            
                end if;
                
                sTIMESTAMP <= sTIMESTAMP + 1;           -- (BC COUNTER)

                if BCRST = '1' then                 
                    sTIMESTAMP <= timestamp_bv; -- Prevedere di precaricare il TimeStamp (BC Counter) con un valore definito nella CPLD_IF ...
                end if;
                if ECRST = '1' then
                    sEVENT_NO <= (others => '0');
                end if;

            end if;
        end if;         
    end process;
-------------------------------------------------------------------------------

on_rising_strobe: process (TCS_CLK)
        begin
                                        -- on rising edge of STROBE
            if (TCS_CLK = '1' and TCS_CLK'event) then
            
                regEVENT_NO     <= sEVENT_NO;
                regEVENT_TYPE   <= TCS_CMD(7 downto 0);
                
                if(STROBE = '1') then
                
                    EventToFIFO     <= '1';
                else
                    EventToFIFO <= '0';
                end if;
            end if;
        end process;

-------------------------------------------------------------------------------

inst_tcs_decode : tcs_decode_MEP
    port map (
            DATA        => TCS_DATA,    
            CLK         => TCS_CLK,
            CE38MHz     => clk38en_i,
            FLT         => sFLT,
            ECRST       => ECRST,           -- ADDED (Alex)
            BCRST       => BCRST,           -- ADDED (Alex)
            TCS_WORD    => TCS_WORD,
            START       => STROBE,
            SYNCED      => synced_i
            );

          

FIFO_TCS_TYPE_inst : FIFO_DUALCLOCK_MACRO  --TCS FIFO
generic map (
   DEVICE => "VIRTEX5",            -- Target Device: "VIRTEX5", "VIRTEX6" 
   ALMOST_FULL_OFFSET => X"0080",  -- Sets almost full threshold
   ALMOST_EMPTY_OFFSET => X"0080", -- Sets the almost empty threshold
   DATA_WIDTH => 32,   -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
   FIFO_SIZE => "18Kb",            -- Target BRAM, "18Kb" or "36Kb" 
   FIRST_WORD_FALL_THROUGH => FALSE, -- Sets the FIFO FWFT to TRUE or FALSE
   SIM_MODE => "FAST") -- Simulation "SAFE" vs "FAST", 
                       -- see "Synthesis and Simulation Design Guide" for details
port map (
   ALMOSTEMPTY => open,         -- Output almost empty 
   ALMOSTFULL => FIFO_FULL,     -- Output almost full
   DO => FIFO_DO,                     -- Output data
   EMPTY => FIFO_EMPTY,               -- Output empty
   FULL => open,                 -- Output full
   RDCOUNT => RDCOUNT,           -- Output read count
   RDERR => open,                -- Output read error
   WRCOUNT => WRCOUNT,           -- Output write count
   WRERR => open,                -- Output write error
   DI => FIFO_DI,                     -- Input data
   RDCLK => FIFO_RDCLK,               -- Input read clock
   RDEN => FIFO_RDEN,                 -- Input read enable
   RST => RESET_fifo,                 -- Input reset
   WRCLK => FIFO_WRCLK,               -- Input write clock
   WREN => FIFO_WREN                  -- Input write enable
);

--FIFO TIMESTAMP
FIFO_TIMESTAMP_inst : FIFO_DUALCLOCK_MACRO
generic map (
   DEVICE => "VIRTEX5",            -- Target Device: "VIRTEX5", "VIRTEX6" 
   ALMOST_FULL_OFFSET => X"0080",  -- Sets almost full threshold
   ALMOST_EMPTY_OFFSET => X"0080", -- Sets the almost empty threshold
   DATA_WIDTH => 32,   -- Valid values are 1-72 (37-72 only valid when FIFO_SIZE="36Kb")
   FIFO_SIZE => "18Kb",            -- Target BRAM, "18Kb" or "36Kb" 
   FIRST_WORD_FALL_THROUGH => FALSE, -- Sets the FIFO FWFT to TRUE or FALSE
   SIM_MODE => "FAST") -- Simulation "SAFE" vs "FAST", 
                       -- see "Synthesis and Simulation Design Guide" for details
port map (
   ALMOSTEMPTY => open,         -- Output almost empty 
   ALMOSTFULL => open,     -- Output almost full
   DO => TIMESTAMP_DO,                     -- Output data
   EMPTY => open,               -- Output empty
   FULL => open,                 -- Output full
   RDCOUNT => RDCOUNT_1,           -- Output read count
   RDERR => open,                -- Output read error
   WRCOUNT => WRCOUNT_1,           -- Output write count
   WRERR => open,                -- Output write error
   DI => sTIMESTAMP,                     -- Input data
   RDCLK => FIFO_RDCLK,               -- Input read clock
   RDEN => TIMESTAMP_RDEN,                 -- Input read enable
   RST => RESET_fifo,                 -- Input reset
   WRCLK => FIFO_WRCLK,               -- Input write clock
   WREN => TIMESTAMP_WE                -- Input write enable
);
------------------------------------------------------------------------------- 
end Behavorial;
