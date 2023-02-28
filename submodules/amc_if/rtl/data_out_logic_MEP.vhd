----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:     11:45:38 12/22/2022 
-- Design Name:     
-- Module Name:     dataout_logic_MEP - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description:  This is the dataout_logic contained in amc_if_8ch. it's been moved here for readability.
--               it reads the event FIFOs and writes the dataout FIFOs.
--
-- Dependencies:   
--
-- Revision: 
-- Revision 0.01    File Created -Marco
-- More Comments: 
--                  The symbol --X means that the port is unused
----------------------------------------------------------------------------------

library ieee;
library unisim;
library unimacro;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.std_logic_unsigned.all;
USE unisim.vcomponents.all;
USE unimacro.vcomponents.all;
USE work.top_level_desc.all;
USE work.g_parameters.all;
USE work.ddr_interface_pkg.all;


entity data_out_logic_MEP is                                                                                  
    port (
        --data_out_main_FIFO
        MEP_data               : out std_logic_vector (32 downto 0); --Al mep bastano 32 bit ma le fifo di data_manager vogliono 33 bit
        MEP_wen                : out std_logic;
        --header_FIFO
        header_data            : out std_logic_vector (32 downto 0);
        header_wen             : out std_logic;

        ready                    : in  std_logic;
        lff                      : in  std_logic;
        data_clk                 : in  std_logic;
        trg                      : in  std_logic; --X
        bos                      : in  std_logic;
        --event_no, spill_no e event_type sono una riga in uscita dalla tcs_fifo 
        event_no                 : in  std_logic_vector (19 downto 0); --gliene fornisco 24 di bit, ne spreco un po
        spill_no                 : in  std_logic_vector (10 downto 0);
        --L0 Trigger Word: L0 Trigger Type (7 downto 2) & ECRST,BCRST (1 downto 0)
        event_type               : in  std_logic_vector (7 downto 0); --è L0 Trigger word --aggiornato alla documentazione: prima era 5 bit   -Marco
        tcs_fifo_empty           : in  std_logic;
        tcs_fifo_rden            : out std_logic; 
        
        --------------------------------------------------------------------------------------------------------------
        -- segnali interni di amc_if_8ch diventati porte:
        --------------------------------------------------------------------------------------------------------------
    -- amc input signal 
    -- xxxxxxxxxxxxxxxxx
    --  added for 8ch version ...
        --adc_clk              : in std_logic; --X
        --si_a_clk_to_dly      : in  std_logic_vector(adc_channels - 1 downto 0);--X
        --si_a_clk_to_buf      : in std_logic_vector(adc_channels - 1 downto 0);--X
        --si_a_clk             : in std_logic_vector(adc_channels - 1 downto 0);--X
        --wr_fifo_pl1          : out std_logic_vector(adc_channels - 1 downto 0); --X           

    -- ana_ilm or ana_nrm signals
        -- in funzione di active_channels ...
        rd_frame_ff              : in  std_logic_vector(active_channels - 1 downto 0) ;--X 
        buffer_fifo_data          : in data_ports(active_channels - 1 downto 0);                               -- 31 bit
        buffer_fifo_empty         : in std_logic_vector(active_channels - 1 downto 0);  
        buffer_fifos_full         : in std_logic_vector(active_channels - 1 downto 0);--X
        buffer_fifo_rden          : out std_logic_vector(active_channels - 1 downto 0);  --(7 downto 0)

    -- variable delay needs this:                        
    -- xxxxxxxxxxxxxxxxxxxxxxxxx (eliminate)
    ---readout logic---
        flt_sr      : in std_logic_vector(1 downto 0);--X
        flt_err     : in std_logic;  -- X         First Level Trigger Error = settato a 1 quando arriva un flt mentre sta ancora elaborando il precedente.
         
        ev_num_err  : out std_logic;-- ev_num_err_i: é un segnale interno, lo prendo come output e sfrutto segnale di appoggio                                                
        --trigger_i   : in std_logic;--X
        --fbos_i      : in std_logic;--X
        --bos_i       : in std_logic;--X
        --set_bos     : in std_logic;--X
        --biterr_flag : in std_logic;--X
        --trg_done    : in std_logic;--X
        --fbos_done   : in std_logic;--X
        --bos_done    : in std_logic;--X
        --bos_count   : in std_logic_vector (7 downto 0);--X
    --    flt_count   : std_logic_vector (19 downto 0)                     := (others => '0');
        reset_i     : in std_logic; 
        del_count   : in integer range 0 to 1023;--X                               
        ready_dly   : in std_logic; --X 
        --first_ev_of_spill : in std_logic; -- first_ev_of_spill: é un segnale interno usato solo in dataout_logic, lo ridefinisco come segnale interno
        --begin_end_trig : in std_logic; -- begin_end_trig: é un segnale interno usato solo in dataout_logic, lo ridefinisco come segnale interno                                     
        

        --SPENGO TUTTE QUESTE PORTE POICHè NON USATE.-----------------------------------------
        --type rdout_state_typ is (--X 
        --    st_armed,
        --    st_wr_frame,
        --    st_swap_fbus,
        --    st_wr_coarse_t
        --    );
    -- new bos sync signals
        --bos_sr                   : in  std_logic_vector(1 downto 0);--X 
        --res_ct_bos_sr            : in std_logic_vector(1 downto 0);--X 
        --bos_edge_detected        : in std_logic;--X 
        --res_ct_bos_edge_detected : in std_logic;--X 

        --rdout_state : rdout_state_typ;--X
       -- type bos_logic_typ is (--X
       --     st_wait,
       --     st_armed,
       --     st_send_bos
       --     );
       --------------------------------------------------------------------------------------------


        --bos_logic             : bos_logic_typ                                  := st_wait;--X
        -- is_normal_mode        : integer range 0 to 255                         := 255; é un segnale interno usato solo in dataout_logic, lo ridefinisco come segnale interno
        --sec_alg_is_on         : in std_logic;                                   --X
       -- fr_counter            : in integer range 0 to 4096;                     --X
        --ch_counter            : in integer range 0 to adc_channels - 1;                     -- era 15;é un segnale interno usato solo in dataout_logic, lo ridefinisco come segnale interno
        --coarse_t              : in  std_logic_vector (37 downto 0)                 := (others => '0');--X
        --coarse_cnt            : in std_logic_vector (36 downto 0)                 := (others => '0');--X
        --constant zero_ct               : std_logic_vector (36 downto 0)                 := (others => '0');--X
        --write_ring            : std_logic                                      := '0';--X
        --wea_ring              : std_logic_vector(3 downto 0);--X
        --write_fifo            : std_logic                                      := '0';--X
        --    wr_fifo_pl1           : std_logic                                      := '0';
        --read_ram              : std_logic                                      := '0';--X
        --write_lsb             : std_logic                                      := '0';--X

    -- ring buffer signals 
    -- see BRAM_SDP_MACRO configuration Table for correct value
        --constant ring_buf_width        : integer := 1; -- 2;             --X                       
        --constant ring_buf_addr         : integer := 15; -- 14;      --X
        -- replicate the addresses for better timing
        --type     addresses_t is array (adc_channels - 1 downto 0) of std_logic_vector(ring_buf_addr - 1 downto 0); -- era 10  --X
        --write_addresses       : addresses_t;
        --read_addresses        : addresses_t;

        -- XXXXXXXXXXXXXXXXX da controllare se sono tutti ingressi
        -- These value are now stored in the config memory
        src_id                : in  std_logic_vector (9 downto 0); --ne userò solo 8 come richiesto dal MEP
        --latency               : in std_logic_vector (15 downto 0);--X  -- x"000d";  -- !! write adress is 10 downto 0!!
        --framewidth_slv        : in std_logic_vector (10 downto 0);--X  -- "00010000000";
        --baseline              : in std_logic_vector (10 downto 0);--X   -- b"000" & x"c8";      -- must be below the real baseline, because of substraction
        --prescaler_base        : in std_logic_vector (7 downto 0);--X  --"00000000";          -- "00000010";
        --frac                  : in std_logic_vector (5 downto 0);--X    -- b"000010";
        --delay                 : in std_logic_vector (4 downto 0);--X    -- '0' & x"a";
        --threshold             : in std_logic_vector (7 downto 0);--X   -- x"1e";
        --cf_max_dist           : in std_logic_vector (2 downto 0);--X   -- b"011";
        --t_threshold           : in std_logic_vector (12 downto 0);--X -- b"00000" & x"0a";
        --t_cf_max_dist         : in std_logic_vector (2 downto 0);--X  -- b"011";

        -- also these should be stored in the config memory
        --t_baseline            : std_logic_vector(12 downto 0)                  := b"00000" & x"c8"; --X
        --t_fraction            : std_logic_vector (5 downto 0)                  := b"000011";--X
        --t_delay               : std_logic_vector (4 downto 0)                  := b"0" & x"c";--X
        -- until here ...

        framewidth            : in integer range 0 to 4096; -- 128;
        --before_zc             : std_logic_vector(2 downto 0)                   := "001";--X
        --after_zc              : std_logic_vector(2 downto 0)                   := "101";--X

        -- 
        --subtype  fifo_cnt is std_logic_vector(8 downto 0); -- era 9   --X
        --type     fifo_cnts is array (integer range<>) of fifo_cnt;--X
        --rd_fifo_cnt           : fifo_cnts(adc_channels-1 downto 0);--X
        --wr_fifo_cnt           : fifo_cnts(adc_channels-1 downto 0);--X

        --frame_fifos_full      : std_logic_vector(adc_channels - 1 downto 0); -- era 15  --X
        --some_event_fifo_full  : std_logic                                      := '0';  --X
        --some_buffer_fifo_full : std_logic                                      := '0';  --X
        --some_frame_fifo_full  : std_logic                                      := '0';  --X
    ---slink logic ---  

        --MEP_frame         : integer range 0 to 9                                 := 0; é un segnale interno usato solo in dataout_logic, lo ridefinisco come segnale interno
        --size_calc_cnt    : integer range 0 to 4                                 := 0; é un segnale interno usato solo in dataout_logic, lo ridefinisco come segnale interno
        --subtype ch_sz_word is std_logic_vector(11 downto 0);                          é un tipo di dato e segnale interno usato solo in dataout_logic, lo ridefinisco come segnale interno
        --type    ch_sz_words is array (integer range<>) of ch_sz_word;   
        --ch_sz            : ch_sz_words(0 to active_channels - 1)                := (others => (others => '0'));
        --subtype two_ch_sz_word is std_logic_vector(12 downto 0);                      é un tipo di dato e segnale interno usato solo in dataout_logic, lo ridefinisco come segnale interno
        --type    two_ch_sz_words is array (integer range<>) of two_ch_sz_word;       
        --two_ch_sz        : two_ch_sz_words(0 to  active_channels/2 - 1)         := (others => (others => '0')); 
        --all_ch_size      : std_logic_vector(14 downto 0)                        := (others => '0');  é un segnale interno usato solo in dataout_logic, lo ridefinisco come segnale interno
        --channel_has_hits : std_logic_vector(active_channels - 1 downto 0);            é un segnale interno usato solo in dataout_logic, lo ridefinisco come segnale interno    
        --subtype channel_int_word is integer range 0 to 7;                             é un tipo di dato e segnale interno usato solo in dataout_logic, lo ridefinisco come segnale interno
        --type    channel_int_words is array (integer range<>) of channel_int_word;   
        --channel_int      : channel_int_words(0 to active_channels - 1)          := (others => 0);
        sysmon           : in std_logic_vector (4 downto 0);
        --sysmon_i         : std_logic_vector (4 downto 0)                        := '0' & x"0"; é un segnale interno usato solo in dataout_logic, lo ridefinisco come segnale interno
        --load_src_id      : std_logic                                            := '0'; --X
        --load_lat         : std_logic                                            := '0'; --X
        --load_cfd         : std_logic                                            := '0'; --X
        --load_basel       : std_logic                                            := '0'; --X
        --load_t_cfd       : std_logic                                            := '0'; --X
        --load_t_cfd_2     : std_logic                                            := '0'; --X
        --wait_bram        : std_logic                                            := '0'; --X
        --bram_dir         : std_logic                                            := '0'; --X

    ---cf_mem---
        --config_mem_bram_addr_i : std_logic_vector(15 downto 0)                   := "1000000000011111";                --X
        --alias memoryaddr              : std_logic_vector (9 downto 0) is config_mem_bram_addr_i(14 downto 5);     --X
        --type cf_mem_logic_typ is (    --X
        --    st_wait,
        --    st_srcid,
        --    st_latency,
        --    st_baseline,
        --    st_cfd,
        --    st_t_cfd,
            -- st_t_max_dist,
    -- st_write_bos_flt,
        --    st_changedelays,
        --    st_writeedges
        --    );

        --cfmem_logic       : cf_mem_logic_typ                                     := st_wait; --X
        --cf_enable         : integer range 0 to 4;   --X
    ---debug
        --data_i_debug1     : adc_ddrports(adc_channels-1 downto 0); --X
        --data_i_debug2     : adc_ddrports(adc_channels-1 downto 0); --X
        --dbg_state_ana_ilm : std_logic_vector(31 downto 0)                        := (others => '0'); --X
        --dbg_state_amc_if  : std_logic_vector(3 downto 0)                         := (others => '0'); --X
        tcs_status        : in std_logic_vector(7 downto 0);
        tcs_error_flag    : in std_logic

        );
end data_out_logic_MEP;




-----------------------------------------------------------------------------------------------------------------------------------------



architecture behavioral of data_out_logic_MEP is
    
    signal first_ev_of_spill   : std_logic := '0'; 
    signal begin_end_trig      : std_logic := '0';

    signal trigger             : std_logic_vector (1 downto 0) := "01"; --Tipo di trigger: 00-Fisica | 01-Altro | 10-EOB | 11-SOB/CHOKE/ERR..
    --Altro: MONITORING/RANDOM/CALIBRATION/3xRESERVED
    -- signal special_trigger     : std_logic := '0'; 
    -- signal EOB                 : std_logic := '0';
    -- signal physics_trigger     : std_logic := '0';


    signal is_normal_mode      : integer range 0 to 255 := 255; 
    signal ch_counter          : integer range 0 to adc_channels - 1;  -- era 15 
    signal MEP_frame           : integer range 0 to 10 := 0; --espanso range
    signal size_calc_cnt       : integer range 0 to 4 := 0; 
    signal ev_num_err_i        : std_logic; --aggiunto perchè ev_num_err_i è una porta di uscita mentre ho bisogno di leggere anche il segnale


    signal event_flags         : std_logic_vector (7 downto 0); -- DA MODIFICARE
    signal timestamp           : std_logic_vector (31 downto 0); -- DA MODIFICARE
    signal error_bits          : std_logic_vector (7 downto 0); -- DA MODIFICARE
    signal flags               : std_logic_vector (7 downto 0); -- DA MODIFICARE
    signal num_samples         : std_logic_vector (7 downto 0);
    signal data_length         : std_logic_vector (15 downto 0);
    signal checksum            : std_logic_vector (31 downto 0); -- DA MODIFICARE
    signal MEP_length          : integer range 0 to 434; --lunghezza totale MEP
    
    

    

    subtype ch_sz_word is std_logic_vector(11 downto 0);                       
        type    ch_sz_words is array (integer range<>) of ch_sz_word;   
            signal ch_sz       : ch_sz_words(0 to active_channels - 1) := (others => (others => '0')); --array di parole a 12 bit

    subtype two_ch_sz_word is std_logic_vector(12 downto 0);                    
        type    two_ch_sz_words is array (integer range<>) of two_ch_sz_word;       
            signal two_ch_sz   : two_ch_sz_words(0 to  active_channels/2 - 1) := (others => (others => '0')); -- non fornito su porta out

    signal all_ch_size         : std_logic_vector(15 downto 0) := (others => '0'); -- non fornito su porta out
    signal channel_has_hits    : std_logic_vector(active_channels - 1 downto 0); -- non fornito su porta out

    subtype channel_int_word is integer range 0 to 7;                           
        type    channel_int_words is array (integer range<>) of channel_int_word;   
            signal channel_int : channel_int_words(0 to active_channels - 1) := (others => 0); -- non fornito su porta out

    signal sysmon_i            : std_logic_vector (4 downto 0) := '0' & x"0"; -- non fornito su porta out

    -------NEW:
    signal event_no_prec       : std_logic_vector (19 downto 0); --event_no precedente per il confronto e la generazione dell'eventuale errore




------------------------------------------------------------------------
begin  --------------------------- begin --------------------------------
------------------------------------------------------------------------
ev_num_err <= ev_num_err_i; 
--Legge le event FIFO e scrive le dataout FIFO



data_out_logic_process : process(data_clk)
variable ch_no          : integer range 0 to 7; --abbassato per GANDALF
variable size           : unsigned(15 downto 0);
variable event_size     : std_logic_vector(15 downto 0);
-- variable dmode          : std_logic_vector(1 downto 0);
variable fer            : std_logic;
variable format         : std_logic_vector(7 downto 0);

variable tmp_i          : integer range 0 to 8;
variable channel_size   : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(framewidth*8, 16));

variable n_eventi_MEP   : integer range 0 to 8; --al MAX 8 eventi nel MEP, conto così perchè mi indica il numero di eventi GIA' SCRITTI.



begin --del processo sopra (data_out_logic_process)


if rising_edge(data_clk) then
    --channel_size := framewidth*8;  --DIM totale parte dati spostata sopra    
    all_ch_size <= channel_size; --carico il valore ottenuto in all_ch_size (channel_sz è una variabile mentre all_ch_sz è un segnale)
    MEP_data <= (others => '0'); --Azzero MEP_data
    MEP_wen  <= '0'; --Disabilito scrittura
    header_data <= (others => '0'); --Azzero header_data
    header_wen <= '0'; --Disabilito scrittura
    n_eventi_MEP := 0;
    sysmon_i    <= sysmon; --Passo nel segnale interno sysmon_i il valore ricevuto sulla porta sysmon (system monitoring???)
    
    for i in 0 to 7 loop --setto la dimensione dati per tutti i canali a 12 righe. Serve nel caso di trigger di fisica.
        ch_sz (i) <= std_logic_vector(to_unsigned(framewidth, 15));
    end loop;



    tcs_fifo_rden <= '0'; --Disattivo lettura TCS_FIFO inviando questo segnale che va a [tcs_if]

    if ready = '0' then --ready dice se la dataout_FIFO è pronta a ricevere i dati (=0 NON è pronta a ricevere i dati)
                        -- e anche che i fast register sono in modalità RESET ARWEN + NO scrittura SPY_FIFO
        ev_num_err_i <= '0'; --Nessun errore nel event number (quello del trigger e quello di gandalf coincidono vedi appunti)
        --è solo un reset questo sopra
        
    end if;
    --------------------------------------------------- NEW: SPOSTA AL MOMENTO IN CUI SCRIVI GLI ERROR BITS OPPURE SPOSTA IN tcs_if DOVE VENGONO CONTEGGIATI GLI EVENTI?
    -- event_no_prec <= event_no; --si aggiorna dopo
    -- if (event_no_prec + 1 = event_no) then
    --     ev_num_err_i <= '0';
    -- else 
    --     ev_num_err_i <= '1'; --Se non coincidono, come da documentazione setto l'errore
    -- end if;

    ---------------------------------------------------- sarebbe opportuno inserirlo negli error bits dell'evento.
    if reset_i = '1' then
        ev_num_err_i    <= '0';
        MEP_frame      <= 0; --macchina a stati
        ch_counter    <= 0;
        ch_no         := ch_counter;
        event_no_prec <= (others => '0'); --Spostato qui, deve essere inizializzato solo
        

    elsif lff = '0' then   --arriva da data_out_manager. Se dataout fifo non è full procedi

                                
        if bos = '1' then --se si verifica BeginOfSpill
            first_ev_of_spill <= '1'; -- allora questo è il primo evento dello spill 
        end if;
        

        case MEP_frame is --SM generale per la scrittura del MEP sulle due FIFO in dataout_manager
        
            when 0 =>      -- TCS_FIFO                                  sleep state, w8 for data in evt_f // 

                
                --devo leggere il trigger qui la prima volta altrimenti non riesco a scrivere la prima riga dell'header
                if tcs_fifo_empty = '0' and flt_err = '0' and ev_num_err_i = '0' then --se tcs_FIFO non è vuota & no errore flt & no errore event number
                    tcs_fifo_rden <= '1'; --allora posso leggere la TCS_FIFO
                    if (n_eventi_MEP = 0) then
                        --MEP_length <= 0; --sto iniziando con un nuovo MEP 
                        MEP_frame <= 1; --devo scrivere l'header del MEP
                    else 
                        MEP_frame <= 2; --ho già scritto degli eventi, non devo riscrivere l'header del MEP!
                    end if;

                end if;

                

                -----------------------------------------------------------------------------------------------------------------------------------
                -- if tcs_fifo_empty = '0' and flt_err = '0' and ev_num_err_i = '0' then --se tcs_FIFO non è vuota & no errore flt & no errore event number
                --     tcs_fifo_rden <= '1'; --allora posso leggere la TCS_FIFO
                --     MEP_frame <= 1; --NEXT STATE
                -- end if;
                --size_calc_cnt <= 4; --size_calculation_counter mi va a gestire un'altra FSM interna a quella si MEP_frame.
                -----------------------------------------------------------------------------------------------------------------------------------

            when 1 =>       -- 1 riga header MEP                                          -- sm in sm, with size_calc_cnt being state var

                tcs_fifo_rden <= '0';
                n_eventi_MEP := 0; --parto con un nuovo MEP, ho scritto 0 eventi
                if to_integer(unsigned(buffer_fifo_empty)) = 0 then
                    header_data <= b"0" & src_id(7 downto 0) & x"0" & event_no;  --Prima riga dell'header MEP (aggiungo 0 davanti per arrivare ai 33 bit richiesti dalla fifo in data_out_manager)
                    header_wen  <= '1'; --scrivo nell'header_FIFO
                    MEP_length <= MEP_length + 2; --Per comodità conto già anche la seconda riga di header MEP perchè ci sarà per forza e in questo
                                                  --modo quando dovrò scriverla mi troverò il segnale MEP_length già col valore corretto senza
                                                  --dover attendere che si aggiorni.
                    MEP_frame   <= 2; --passo allo stato successivo
                end if;

                -----------------------------------------------------------------------------------------------------------------------------------
                       --~ TODO case size_calc_cnt
                --if to_integer(unsigned(buffer_fifo_empty)) = 0 then -- quando tutte le BUFFER FIFO hanno dati vengono lette in parallelo  
                -- -- ( controllo che il segnale buffer_fifo_empty sia una parola di tutti zeri ovvero tutti i canali NON siano vuoti).
                --     if size_calc_cnt = 4 then  -- enable event fifo readenable (TODO check if state is obsolete)  
                --         --buffer_fifo_rden <= (others => '1'); --attivo la lettura di TUTTE le Buffer_FIFO || NO, non devo più leggere la prima riga subito per trovare le dimensioni
                --         size_calc_cnt <= 3; --aggiorno fsm interna
                --     end if;
                -- end if;
                -- if size_calc_cnt = 3 then -- Calcolo dimensioni evento (da noi è framewidth)                                           
                --     for i in 0 to active_channels - 1 loop -- per ogni canale:                  -- Alex: aggiunta variabile per il numero di canali da leggere
                --     -- for i in 0 to adc_channels/2 - 1 loop                                    -- Paolo: per ogni canale si controlla la size e si decide se ha hit
                --         buffer_fifo_rden(i) <= '0'; --azzero il flag di lettura del canale (ho già ricevuto i dati in uscita)

                --         -------------------------------------------------------------------------------------------------------------------------------------------
                --         -- --Marco: Si può togliere perchè non c'è più la EVENT_FIFO che mette la dimensione della parte dati davanti per distinguire se ci sono hit o no,
                --         -- --       ora inviamo solo dati grezzi.
                --         -- --buffer_fifo_data è un array di 8 elementi ognuno da 31 bit (8 x 31bit) --> controllo solo gli ultimi 12 (rappresentano il dato dell'evento)
                --         -- if buffer_fifo_data(i)(12 downto 0) /= x"000" then  --se buffer_fifo_data diverso da esadecimale tutti zeri c'è hit --CORREZIONE: prima era 11 downto 0
                --         --     channel_has_hits(i) <= '1'; -- mi segno che il canale "i" ha avuto un hit
                --         -- else
                --         --     channel_has_hits(i) <= '0';
                --         -- end if;
                --         -------------------------------------------------------------------------------------------------------------------------------------------

                --         --le informazioni dell'evento (ultimi 12 bit di buffer_fifo_data) li prendo e li metto in ch_sz (channelsize) 
                --         --QUALSIASI sia l'esito precedente (hit o no)
                --         --ch_sz(i) <= buffer_fifo_data(i)(12 downto 0);      --NON SERVE PIù,stesso motivo sopra, non ho più distinzione tra hit e no                      -- Paolo: si carica lib ch_sz la dimensione dei dati presenti nella BUFFER_FIFO
                --         ch_sz(i) <= framewidth; --sommo 12, numero di linee di dati grezzi ( 2 dati x linea = 24 dati)
                --     end loop;

                --     for i in 0 to  active_channels/2 - 1 loop --4 canali                        -- Paolo: si somma la size di due canali
                --         --two_ch_sz(i) <= buffer_fifo_data(i)(12 downto 0) + buffer_fifo_data(i+active_channels/2)(12 downto 0); --Marco: non più necessario, ora riga sotto:
                --         --dovrebbe essere perchè la buffer_fifo_data contiene la dimensione di buffer_counter (al MAX 12 bit) + ci può essere il frame (11bit di dimensione).
                --         --Sommando i due numeri uno a 12 bit e l'altro a 11 il risultato finisce in un numero a 13 bit al MAX ecco perchè.
                --         two_ch_sz(i) <= 2*framewidth; --dim dati grezzi di due canali
                        
                --     end loop;

                --     -- ---------------------------------------------------------------------------------------------------------------------------------------------  
                --     -- --Marco: non più necessario, tutti i pacchetti sono debug, sostituisco con riga sotto: 
                --     -- --Controllo nel 1°canale (canale 0) il 31-esimo bit (buffer_fifo_data và da 0 a 30) mi dice il tipo di pacchetto
                --     -- if buffer_fifo_data(0)(30) = '0' then  -- frame or debug?
                --     --     is_normal_mode <= 1;              -- frame (se è uguale a 0)
                --     -- else
                --     --     is_normal_mode <= 0;              --debug
                --     -- end if;
                --     -- ---------------------------------------------------------------------------------------------------------------------------------------------  

                --     is_normal_mode <= 0; --Marco: sempre DEBUG 
                --     size_calc_cnt    <= 2; --Finita questa fase di lettura dalle EVENT FIFO. Aggiorno size_calc_cnt per passare alla prossima fase.

                -- end if;

                -- if size_calc_cnt = 2 then
                --     --channel_int è un array (DIM=numero di canali ADC) di interi (con range tra 0 e 7)

                --     -- ---------------------------------------------------------------------------------------------------------------------------------------------
                --     -- --Marco: tolgo tutto, non considero più se ho hit o no  
                --     -- channel_int <= (others => 0); --resetto tutto
                --     -- tmp_i       := 0;
                --     -- for i in 0 to active_channels - 1 loop                          -- Paolo: si crea un vettore che contiene il numero dei canali che hanno hit
                --     --     if channel_has_hits(i) = '1' then --controllo se canale i-esimo ha avuto un hit
                --     --         channel_int(tmp_i) <= i;  --salvo nella prima posizione libera di channel_int il numero del canale che avuto l'hit      -- contains ordered numbers of non-empty channels
                --     --         tmp_i              := tmp_i+1; --Aggiorno indice 
                --     --         --Possibile configurazione finale:  23600000  => ho avuto hit nel canale 2, 3 e 6.
                --     --     end if;
                --     -- end loop;
                --     -- ---------------------------------------------------------------------------------------------------------------------------------------------  

                --     -- keep in mind addition is expensive inside FPGA               -- Modificata somma brutale Alex 
                --     channel_size := (others => '0');  -- azzero questo vettore da 15 bit
                --     for i in 0 to  active_channels/2 - 1 loop                       -- Paolo: si somma la size di due "doppi" canali 
                --         channel_size := channel_size + ("00" & two_ch_sz(i)); --concateno due zeri davanti a two_ch_sz e lo sommo agli altri two_ch_sz concatenati
                --         --dentro a channel_size.
                --     end loop;
                    -- channel_size := framewidth*8;  --DIM totale parte dati      
                    -- all_ch_size <= channel_size; --carico il valore ottenuto in all_ch_size (channel_sz è una variabile mentre all_ch_sz è un segnale)
                    --!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!! fino a qui OK!
                    --metto nel canale di uscita 100000..000 (1 seguito da 32 zeri). é la START WORD
                    -- header_data <= src_id(7 downto 0) & x"0" & event_no;  --Prima riga dell'header MEP
                    -- header_wen  <= '1'; --scrivo nell'header_FIFO
                    -- MEP_frame   <= 2; --passo allo stato successivo
                --end if;
                -----------------------------------------------------------------------------------------------------------------------------------


            when 2 =>           --TRIGGER, 1 riga header evento (azzurra)
                tcs_fifo_rden <= '0';
                checksum <= (others => '0'); --RESETTO Checksum per ogni nuovo evento
                --RESET iniziale del tipo ti trigger (evito che rimangano settati valori precedenti)
                trigger <= "01"; --Ricordo: 00-Fisica | 01-Altro | 10-EOB | 11-SOB/CHOKE/ERR..

                case event_type is --Studio il TIPO DI TRIGGER

                    when b"100010_11" | b"100100_00" | b"100101_00" | b"100110_00" | b"100111_00" | b"100000_00" => --  SOB | CHOKE ON | CHOKE OFF | ERROR ON | ERROR OFF | synchronization
                        trigger <= "11"; --mi segno che sono in questo caso
                        event_size := std_logic_vector(to_unsigned(7, 16)); -- 5 parole di header + 1 cheksum + 1 riga reserved (1 per tutti i canali)
                    
                    when b"10001110" => -- EOB 
                        trigger <= "10";
                        event_size := std_logic_vector(to_unsigned(11, 16)); -- 5 parole di header + 1 cheksum + 5 righe (in totale per tutti i canali)(4 reserved, 1 N° L0trg)
            
                    when others => 
                        if (event_type(7) = '0') then  -- TRIGGER DI FISICA
                            trigger <= "00";
                            event_size := std_logic_vector(to_unsigned(6, 16)) + ('0' & all_ch_size);    -- 5 parole di header dell'evento, 1 checksum finale, all_ch_size righe di dati
                         -- CASI RESTANTI - Non gestiti, avrò tutti e 3 i segnali rimasti a 0                            
                        end if;
                end case;

                MEP_data <= b"0" & event_flags & event_no(7 downto 0) & event_size;          -- PRIMA RIGA NELLA DATA_OUT_MAIN_FIFO -------------<<<
                MEP_wen  <= '1'; --abilito scrittura
                MEP_length <= MEP_length + 1; 
                MEP_frame   <= 3; --Passo ad un nuovo stato della FSM


                -----------------------------------------------------------------------------------------------------------------------------------
                -- -- Alex & Paolo: Non serve piu' guardare gen_rdm(3) ...  sempre normal sampling mode                                          
                -- --if gen_rdm(3) = '0' then        --normal sampling mode        
                -- --    event_size(15 downto 0) := std_logic_vector(to_unsigned((framewidth+2)*adc_channels + 3, 16));        -- sbagliato da indicizzare (adc_channels)...

                -- -- elsif gen_rdm(3) = '1' then     --interleaved mode                   
                --     if is_normal_mode = 0 then  -- DEBUG frame  (come già visto precedentemente se =0 il pacchetto è di debug)                                                        
                --           event_size(15 downto 0) := std_logic_vector(to_unsigned(6, 16)) + ('0' & all_ch_size);    -- 5 parole di header dell'evento, 1 checksum finale
                --         --std_logic_vector(to_unsigned(2 * active_channels + 3, 16)) = 1011 preceduto da 12 zeri (16 bit totali) 3 parole di header o bit ?????? 2 ??????
                --         --adatto le dimensioni di all_ch_size aggiungendo uno zero davanti.
                --         --somma le dimensioni degli eventi su tutti i canali aggiungendo l'header e debug...+ debug... righe sopra 
                --         -- dmode                   := b"10";  -- TODO change to  or remove
                --     else --FRAME
                --         event_size(15 downto 0) := std_logic_vector(to_unsigned(3, 16)) + ('0' & all_ch_size);          -- Alex & Paolo: OK
                --         --dimensione di tutti gli eventi + 3 parole di header
                --         -- dmode                   := b"00";
                --     end if;
                -- -- end if;
                
                -- in case of triggers that are generated at begin/end of spill/run,
                -- we only put a header event on the slink

                --> tcs_error_flag è a 0 solo se tutti i tcs_status (varie tipoligie di errori, 16 in totale stati in tcs_status) sono a zero (zero= tutto bene)  
                
                -- if event_type = b"11100" then --- ???? 3 ??????? 
                --     fer := '1';  -- first event of run, TODO rename
                -- else
                --     fer := '0';
                -- end if;
                -----------------------------------------------------------------------------------------------------------------------------------


            when 3 =>           -- 2 riga header evento (azzurra)

                MEP_data <= b"0" & timestamp;                                 -- SECONDA RIGA NELLA DATA_OUT_MAIN_FIFO -------------<<<
                MEP_wen  <= '1';
                MEP_length <= MEP_length + 1;
                MEP_frame   <= 4;

                -----------------------------------------------------------------------------------------------------------------------------------
                -- if first_ev_of_spill = '1' then --eventualmente aggiungere confronto event_no 
                --     first_ev_of_spill <= '0';
                --     if event_no /= std_logic_vector(to_unsigned(1, 20)) then                    --Paolo: sembra generare errore se l'event_no è diverso da 1??????? --Marco: andrebbe aggiunto confronto con vecchio event_no+1
                --         ev_num_err_i <= '1';                                                      --speriamo sia giusto ...--lo fa cosi perchè siamo nel 1 evento dello spill
                --     else 
                --         ev_num_err_i <= '0';
                --     end if;
                -- end if;
                -----------------------------------------------------------------------------------------------------------------------------------


            when 4 =>           -- 3 riga header evento (azzurra)
                --format     := fer & b"110" & gen_rdm; -- (3) & dmode & b"0";    --first evt run & g_adc & (0)nml/ilm(1) & nml/debug data & adc readout -- da mettere 101
                MEP_data <= b"0" & error_bits & event_type & x"0000";  -- TERZA RIGA NELLA DATA_OUT_MAIN_FIFO -------------<<<   --event_type= L0 trigger word, 16 zeri di source-sub-ID                                                                           
                MEP_wen  <= '1';
                MEP_length <= MEP_length + 1;
                
                case trigger is  --   00-Fisica | 01-Altro | 10-EOB | 11-SOB/CHOKE/ERR..

                    when "00" => --Fisica
                        num_samples <= std_logic_vector(to_unsigned(24, 8));
                        data_length <= channel_size; --data: framewidth*8 = channel_size

                    when "01" => --Altro
                        num_samples <= std_logic_vector(to_unsigned(24, 8)); --PER ORA!!!!!!!!!!!!! DA MODIFICARE !!!!!!!!!!!!
                        data_length <= channel_size; --PER ORA!!!!!!!!!!!!! DA MODIFICARE !!!!!!!!!!!! 

                    when "10" => --EOB
                        num_samples <= std_logic_vector(to_unsigned(24, 8)); --PER ORA!!!!!!!!!!!!! DA MODIFICARE !!!!!!!!!!!!
                        data_length <= std_logic_vector(to_unsigned(5, 16)); -- 5 righe
                        

                    when "11" => --SOB/CHOKE/ERR..
                        num_samples <= std_logic_vector(to_unsigned(24, 8)); --PER ORA!!!!!!!!!!!!! DA MODIFICARE !!!!!!!!!!!!
                        data_length <= std_logic_vector(to_unsigned(1, 16)); -- 1 riga
								
					when others => --considero come trigger di fisica
						num_samples <= std_logic_vector(to_unsigned(24, 8));
                        data_length <= channel_size; --data: framewidth*8 = channel_size

                end case;

                -----------------------------------------------------------------------------------------------------------------------------------
                -- if is_normal_mode = 0 then  --debug mode   --Noi entriamo sempre qui
                --     MEP_frame <= 5;
                -- else            --proc mode --SALTA

                --     if all_ch_size /= 0 then                                    -- Paolo: legge la prima EVENT FIFO con dati
                --         buffer_fifo_rden(channel_int(ch_counter)) <= '1';
                --         MEP_frame                                 <= 6;
                --     else
                --         MEP_frame <= 8;
                --     end if;

                -- end if;
                -----------------------------------------------------------------------------------------------------------------------------------

            when 5 =>           -- 4 riga header evento (azzurra)

                MEP_data <= b"0" & flags & num_samples & data_length;                             -- QUARTA RIGA NELLA DATA_OUT_MAIN_FIFO -------------<<<                            
                MEP_wen <= '1'; --and not begin_end_trig; tolto 
                MEP_length <= MEP_length + 1;                     
                MEP_frame <= 6;


                -----------------------------------------------------------------------------------------------------------------------------------
                -- if active_channels = adc_channels/2 then --se lavoro con 4 canali (NO)
                --     ch_no      := ch_counter * 2; --in modo da "spazzare" la metà dei canali (ovvero 4 dato che ch_counter spazzerà 8 valori)
                -- else --se lavoro con 8 canali
                --     ch_no      := ch_counter;
                -- end if;
                -----------------------------------------------------------------------------------------------------------------------------------

                

            when 6 =>           -- 5 riga header evento (azzurra)

                MEP_data <= b"0" & x"000000FF";  --Channel Mask -> 000...001111_1111  ho 8 canali attivi
                MEP_wen <= '1';
                MEP_length <= MEP_length + 1;
                
                -----------------------

                buffer_fifo_rden(ch_counter) <= '1';    --Attivo lettura della BUFFER_FIFO del canale >ch_counter<   
                MEP_frame <= 7;


            when 7 =>         -- DATA     (Ricordo trigger: 00-Fisica | 01-Altro | 10-EOB | 11-SOB/CHOKE/ERR..)

                if (trigger = "00") then  -- TRIGGER DI FISICA -> LEGGO TUTTA LA BUFFER FIFO -> SCRIVO TUTTO NELLA DATA_OUT_MAIN_FIFO
                    buffer_fifo_rden(ch_counter) <= '1';
                    MEP_data <= b"00" & buffer_fifo_data(ch_counter); -- '0' necessario per adeguare le dimensioni (31 bit -> 32 bit)
                    MEP_wen  <= '1'; --and not begin_end_trig;  tolto
                    MEP_length <= MEP_length + 1;
                    if ch_sz(ch_counter) /= 1 then                                      -- legge tutta la BUFFER_FIFO del canale "ch_counter"
                        ch_sz(ch_counter) <= ch_sz(ch_counter)-1;  --ho letto una riga quindi decremento
                        MEP_frame  <= 7;
                    else --ho scritto tutta la buffer fifo del canale ch_counter
                        buffer_fifo_rden(ch_counter) <= '0'; --Fermo la lettura da quel canale.

                        if (ch_counter /= active_channels - 1 ) then --ho altri canali da leggere
                            ch_counter <= ch_counter +1;
                            MEP_frame  <= 7;  --ripeto lo stato 7
                        else --ho scritto tutti i canali
                            ch_counter <= 0;
                            --calcolo CHECKSUM (sfrutta magari una variabile di appoggio che si aggiorna subito da settare dentro ciascun if dei trigger in modo da
                            -- poter fare poi un controllo sul valore di questa variabile [dopo tutti i trigger] e scrivere il calcolo del checksum una sola volta!)
                            MEP_frame <= 8;
                        end if;
                    end if;
                end if;
                if (trigger = "11") then  -- TRIGGER SOB/CHOKE/ERROR/SYNCHRONIZATION -> SCRIVO 1 riga  che rappresenta tutti i canali.
                    --capire come implementare
                    --
                    --
                    --
                end if;
                if (trigger = "10") then  -- TRIGGER EOB -> SCRIVO 5 righe che rappresentano tutti i canali.
                    --capire come implementare
                    --
                    --
                    --
                end if;
                if (trigger = "01") then  -- TRIGGER MONITORING/RANDOM/CALIBRATION/3xRESERVED -> SCRIVO 5 righe che rappresentano tutti i canali.
                    --capire come implementare
                    --
                    --
                    --
                end if;

                



                -----------------------------------------------------------------------------------------------------------------------------------
                -- --Legge tutte le parole (dati grezzi) + resto contenuti nella EVENT_FIFO
                -- if is_normal_mode = 0 then    --DEBUG MODE                                          -- paolo: debug mode
                --     buffer_fifo_rden(ch_counter) <= '1';  ---!!!!!!!!!!!!!!!!!!
                --     MEP_data                  <= b"01" & buffer_fifo_data(ch_counter);  --decode data & buffer_fifo_data from ana_ilm.vhd
                --     MEP_wen                   <= '1' and not begin_end_trig;
                --     if ch_sz(ch_counter) /= 1 then                                      -- paolo:  legge tutta la EVENT FIFO del canale "ch_counter"
                --         ch_sz(ch_counter) <= ch_sz(ch_counter)-1;
                --     else
                --         buffer_fifo_rden(ch_counter) <= '0';
                --         MEP_frame                    <= 8;  --add trailer for debug data mode
                --     end if;
                -- else               --SALTA NO NORMAL MODE !!!!!!!!                                                 -- GO ON HERE in proc mode
                --     buffer_fifo_rden(channel_int(ch_counter)) <= '1';  --!!!!!!!!!!!!!!!!!!!!!!!!
                --     MEP_data                               <= b"01" & buffer_fifo_data(channel_int(ch_counter));  --decode data & buffer_fifo_data from ana_ilm.vhd
                --     MEP_wen                                <= '1' and not begin_end_trig;
                --     if ch_sz(channel_int(ch_counter)) /= 1 and ch_sz(channel_int(ch_counter)) /= 0 then     -- paolo: legge tutta la EVENT FIFO del canale con dati
                --         ch_sz(channel_int(ch_counter)) <= ch_sz(channel_int(ch_counter))-1;
                --     else
                --         if ch_counter < active_channels - 1 then                                                   -- paolo:   scorre tutte i canali che hanno dati, aggiornando
                --             if channel_int(ch_counter+1) /= 0 then                                          --          il ch_counter 
                --                 ch_counter                                 <= ch_counter+1;                 --          il 7 va indicizzato 
                --                 buffer_fifo_rden(channel_int(ch_counter))   <= '0';
                --                 buffer_fifo_rden(channel_int(ch_counter+1)) <= '1';
                --             else
                --                 buffer_fifo_rden(channel_int(ch_counter)) <= '0';
                --                 MEP_frame                                 <= 9;
                --                 ch_counter                               <= 0;
                --             end if;
                --         else
                --             buffer_fifo_rden(channel_int(ch_counter)) <= '0';
                --             MEP_frame                                 <= 9;
                --             ch_counter                               <= 0;
                --         end if;
                --     end if;
                -----------------------------------------------------------------------------------------------------------------------------------

            when 8 =>           -- Checksum
            
                MEP_data <= b"0" & checksum;
                MEP_wen <= '1';
                MEP_length <= MEP_length + 1;
                n_eventi_MEP := n_eventi_MEP +1; --ho completato la scrittura di un evento

                if( n_eventi_MEP = 8 or trigger = "10" ) then --Ho 8 eventi nel MEP oppure ho appena scritto un EOB -> chiudo il MEP 
                    MEP_frame <= 9; --scrivo la seconda riga rimasta dell'header del MEP    
                else --Scrivo il prossimo evento nel MEP
                    MEP_frame <= 0; --torno alla lettura della tcs_fifo attendendo che si riempia.
                end if;
                
                
                -----------------------------------------------------------------------------------------------------------------------------------
                -- if ch_counter /= (active_channels - 1) then    --Se ci sono ancora canali da scrivere torni a 5 e ripeti tutto scrivendoli                 --go to header write next channel ... era 15 ...  
                --     ch_counter <= ch_counter + 1;
                --     MEP_frame   <= 5;
                -- else     --Hai letto tutti i dati di tutte le EVENT_FIFO scrivendoli in slink.   --debug readout finished for this event
                --     ch_counter <= 0;
                --     MEP_frame   <= 9;
                -- end if;

                -- MEP_data <= b"001" & event_no(5 downto 0)                                 --decode trailer & event no
                --               & std_logic_vector(to_unsigned(ch_no, 4)) & sysmon_i          --ch & sys mon
                --               & std_logic_vector(to_unsigned(framewidth, 11)) & gen_rdm;    --framewidth & readout mode
                -- MEP_wen <= '1' and not begin_end_trig;
                -----------------------------------------------------------------------------------------------------------------------------------



            when 9 =>           --2 riga header MEP  (CHIUSURA MEP)
                header_data <= b"0" & x"00" &  std_logic_vector(to_unsigned(n_eventi_MEP, 8)) &  std_logic_vector(to_unsigned(MEP_length, 16));
                header_wen <= '1';
                n_eventi_MEP := 0; --azzero n. eventi nel MEP, ho finito il MEP 
                MEP_length <= 0; --azzero il contatore delle dimensioni del MEP, per ripartire.
                MEP_frame   <= 0; --attendo un trigger

            when 10 =>
                MEP_frame      <= 0; --DA CONTROLLAREEEEE

            when others =>
                MEP_frame <= 0; --DA CONTROLLAREEEEE
        end case;
    else
        buffer_fifo_rden <= (others => '0');
        
    end if;
end if;
end process;
end behavioral;