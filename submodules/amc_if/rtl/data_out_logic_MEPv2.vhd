----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:     11:45:38 1/14/2023 
-- Design Name:     
-- Module Name:     dataout_logic_MEP - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description:  This is the dataout_logic contained in amc_if_8ch. it's been moved here for readability.
--               it reads the buffer FIFOs and writes the dataout FIFO and the header FIFO.
--
-- Dependencies:   
--
-- Revision: 
-- Revision 0.01    File Created - Marco Panconesi
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


entity data_out_logic_MEPv2 is                                                                                  
    port (
        --data_out_main_FIFO
        MEP_data               : out std_logic_vector (32 downto 0); --Al mep bastano 32 bit ma le fifo di data_manager vogliono 33 bit
        MEP_wen                : out std_logic;
        --header_FIFO
        --header_data            : out std_logic_vector (32 downto 0);
        header_wen             : out std_logic;

        ready                    : in  std_logic;
        lff                      : in  std_logic;
        data_clk                 : in  std_logic;
        trg                      : in  std_logic; --X
        --bos                      : in  std_logic;
        --event_no, spill_no e event_type sono una riga in uscita dalla tcs_fifo 
        event_no                 : in  std_logic_vector (23 downto 0); 
        spill_no                 : in  std_logic_vector (10 downto 0);
        --L0 Trigger Word: L0 Trigger Type (7 downto 2) & ECRST,BCRST (1 downto 0)
        event_type               : in  std_logic_vector (7 downto 0); --è L0 Trigger word --aggiornato alla documentazione: prima era 5 bit   -Marco
        timestamp                : in std_logic_vector (31 downto 0);
        tcs_fifo_empty           : in  std_logic;
        tcs_fifo_rden            : out std_logic; 
        stat_flags               : in std_logic_vector (15 downto 0);
                

    -- ana_ilm or ana_nrm signals
        -- in funzione di active_channels ...
        rd_frame_ff               : in  std_logic_vector(active_channels - 1 downto 0) ;--X 
        frame_fifo_data          : in adc_ddrports(adc_channels - 1 downto 0);            --2*12bit 
        frame_fifo_empty         : in std_logic_vector(active_channels - 1 downto 0);  
        frame_fifo_full         : in std_logic_vector(active_channels - 1 downto 0);--X
        frame_fifo_rden          : out std_logic_vector(active_channels - 1 downto 0);  --(7 downto 0)

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
        
        src_id                : in  std_logic_vector (9 downto 0); --ne userò solo 8 come richiesto dal MEP

        framewidth            : in integer range 0 to 4096; -- 12;

        sysmon           : in std_logic_vector (4 downto 0);

        tcs_status        : in std_logic_vector(7 downto 0);
        tcs_error_flag    : in std_logic

        );
end data_out_logic_MEPv2;




-----------------------------------------------------------------------------------------------------------------------------------------



architecture behavioral of data_out_logic_MEPv2 is
    
    --signal first_ev_of_spill   : std_logic := '0'; 
    signal begin_end_trig      : std_logic := '0';

    signal trigger             : std_logic_vector (1 downto 0) := "01"; --Tipo di trigger: 00-Fisica | 01-Altro | 10-EOB | 11-SOB/CHOKE/ERR..
    --Altro: MONITORING/RANDOM/CALIBRATION/3xRESERVED



    signal is_normal_mode      : integer range 0 to 255 := 255; 
    signal ch_counter          : integer range 0 to adc_channels - 1;  -- era 15 
    signal MEP_frame           : integer range 0 to 13 := 0; --espanso range
    signal size_calc_cnt       : integer range 0 to 4 := 0; 
    signal ev_num_err_i        : std_logic; --aggiunto perchè ev_num_err_i è una porta di uscita mentre ho bisogno di leggere anche il segnale


    signal event_flags         : std_logic_vector (7 downto 0); -- DA MODIFICARE
    signal error_bits          : std_logic_vector (7 downto 0); -- DA MODIFICARE
    signal flags               : std_logic_vector (7 downto 0); -- DA MODIFICARE
    signal num_samples         : std_logic_vector (7 downto 0);
    signal data_length         : std_logic_vector (15 downto 0);
    signal checksum            : std_logic_vector (31 downto 0); -- DA MODIFICARE
    signal MEP_length          : std_logic_vector (13 downto 0); --lunghezza totale MEP
    signal count_framewidth    : integer range 0 to 4096; --contatore framewidth

    signal MEP_head_1          : std_logic_vector(32 downto 0) := (others=> '0');

    type  state  is (
        read_ff,
        write_ff
      );

    signal  frame_fifos   : state := read_ff;


    
    

    

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
    signal cnt_a          : integer range 0 to 5;

    signal MEP_write      : std_logic_vector(1 downto 0) := "00";
    signal channel,channel_t : integer range 0 to adc_channels - 1;

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
  
    all_ch_size <= channel_size; --carico il valore ottenuto in all_ch_size (channel_sz è una variabile mentre all_ch_sz è un segnale)
    MEP_wen  <= '0'; --Disabilito scrittura
    header_wen <= '0'; --Disabilito scrittura
    sysmon_i    <= sysmon; --Passo nel segnale interno sysmon_i il valore ricevuto sulla porta sysmon (system monitoring???)
    
 


    tcs_fifo_rden <= '0'; --Disattivo lettura TCS_FIFO inviando questo segnale che va a [tcs_if]

 
    if reset_i = '1' then
        ev_num_err_i    <= '0';
        MEP_frame      <= 0; --macchina a stati
        ch_counter    <= 0;
        checksum        <= (others => '0');
        ch_no         := ch_counter;
        n_eventi_MEP := 0;
        MEP_length <=  (others => '0');
        event_no_prec <= (others => '0'); --Spostato qui, deve essere inizializzato solo
        tcs_fifo_rden <= '0'; --Disattivo lettura TCS_FIFO inviando questo segnale che va a [tcs_if]
        frame_fifo_rden <= (others => '0');
        MEP_wen  <= '0';
        

    elsif lff = '0' then   --arriva da data_out_manager. Se dataout fifo non è full procedi
        

        case MEP_frame is --SM generale per la scrittura del MEP sulle due FIFO in dataout_manager
        
            when 0 =>      -- TCS_FIFO                                  sleep state, w8 for data in evt_f // 

                
                --devo leggere il trigger qui la prima volta altrimenti non riesco a scrivere la prima riga dell'header
                if tcs_fifo_empty = '0' and flt_err = '0' and ev_num_err_i = '0' then --se tcs_FIFO non è vuota & no errore flt & no errore event number
                    tcs_fifo_rden <= '1'; --allora posso leggere la TCS_FIFO e il timestamp (le due fifo sono pilotate dallo stesso read enable)
                    MEP_frame <= 12;
                    
                end if;
                frame_fifo_rden <= (others => '0');
                MEP_wen  <= '0';
                checksum        <= (others => '0');

            when 12 =>
                MEP_frame <= 13;
                tcs_fifo_rden <= '0';

            when 13 =>
                trigger <= "01"; --Ricordo: 00-Fisica,Monitoring,Random,Calibration | 01-RESERVED  | 10-EOB | 11-SOB/CHOKE/ERR..

                if (n_eventi_MEP = 0) then
                    MEP_frame <= 1; --devo scrivere l'header del MEP
                else 
                    MEP_frame <= 2; --ho già scritto degli eventi, non devo riscrivere l'header del MEP!
                end if;

                case event_type is --Studio il TIPO DI TRIGGER

                    when b"100010_00" | b"100100_00" | b"100101_00" | b"100110_00" | b"100111_00" | b"100000_00" => --  SOB | CHOKE ON | CHOKE OFF | ERROR ON | ERROR OFF | synchronization
                        trigger <= "11"; --mi segno che sono in questo caso
                        event_size := std_logic_vector(to_unsigned(7, 16)); -- 5 parole di header + 1 cheksum + 1 riga reserved (1 per tutti i canali)
                    
                    when b"100011_00" => -- EOB 
                        trigger <= "10";
                        event_size := std_logic_vector(to_unsigned(11, 16)); -- 5 parole di header + 1 cheksum + 5 righe (in totale per tutti i canali)(4 reserved, 1 N° L0trg)
                    
                    when b"100001_00" | b"101001_00" | b"101010_00" | b"101011_00" | b"101110_00" | b"101111_00" => --   RESERVED
                        trigger <= "01";
                        MEP_frame <= 7;

                    when others => -- TRIGGER DI FISICA, CALIBRATION, MONITORING, RANDOM 
                        trigger <= "00";
                        event_size := std_logic_vector(to_unsigned(6, 16)) +  all_ch_size;    -- 5 parole di header dell'evento, 1 checksum finale, all_ch_size righe di dati                                                   
                end case;

                    
            when 1 =>       -- 1 riga header MEP                                          -- sm in sm, with size_calc_cnt being state var

                tcs_fifo_rden <= '0';
                n_eventi_MEP := 0;                                                                      --parto con un nuovo MEP, ho scritto 0 eventi
                if to_integer(unsigned(frame_fifo_empty)) = 0 then
                    MEP_head_1 <= b"0" & src_id(7 downto 0) & event_no;                                 --Prima riga dell'header MEP (aggiungo 0 davanti per arrivare ai 33 bit richiesti dalla fifo in data_out_manager)
                                                                                                        --header_wen  <= '1'; --scrivo nell'header_FIFO
                    MEP_length <= std_logic_vector(to_unsigned(2,14));                                  --Per comodità conto già anche la seconda riga di header MEP perchè ci sarà per forza e in questo
                                                  --modo quando dovrò scriverla mi troverò il segnale MEP_length già col valore corretto senza
                                                  --dover attendere che si aggiorni.
                    MEP_frame   <= 2; --passo allo stato successivo
                end if;
                


            when 2 =>                                                                                   --TRIGGER, 1 riga header evento (azzurra)
                tcs_fifo_rden <= '0';
                header_wen <= '0';
                                                                                                        --RESET iniziale del tipo di trigger (evito che rimangano settati valori precedenti)
                

                MEP_data <= b"0" & stat_flags(7 downto 0) & event_no(7 downto 0) & event_size;          -- PRIMA RIGA NELLA DATA_OUT_MAIN_FIFO -------------<<<
                                                                                                        --status_flag(7 downto 0) = EVENT FLAGS
                MEP_wen  <= '1';                                                                        --abilito scrittura
                MEP_length <= MEP_length + '1'; 
                checksum <= stat_flags(7 downto 0) & event_no(7 downto 0) & event_size;                 --(others => '0'); --RESETTO Checksum per ogni nuovo evento
 
                MEP_frame   <= 3;                                                                       --Passo ad un nuovo stato della FSM


            when 3 =>           -- 2 riga header evento (azzurra)

                MEP_data <= b"0" & timestamp;                                 -- SECONDA RIGA NELLA DATA_OUT_MAIN_FIFO -------------<<<
                MEP_wen  <= '1';
                MEP_length <= MEP_length + '1';
                checksum <= checksum + timestamp; --aggiorno checksum
                MEP_frame   <= 4;


            when 4 =>           -- 3 riga header evento (azzurra)
                
                MEP_data <= b"0" & stat_flags(15 downto 8) & event_type & x"0000";  -- TERZA RIGA NELLA DATA_OUT_MAIN_FIFO -------------<<<   --event_type= L0 trigger word, 16 zeri di source-sub-ID   
                --status_flag(15 downto 8) = ERROR BITS                                                                        
                MEP_wen  <= '1';
                MEP_length <= MEP_length + '1';
                checksum <= checksum + (stat_flags(15 downto 8) & event_type & x"0000");
                
                case trigger is  --   00-Fisica | 01-Altro | 10-EOB | 11-SOB/CHOKE/ERR..

                    when "00" => --Fisica
                        num_samples <= std_logic_vector(to_unsigned(framewidth*2, 8));
                        data_length <= channel_size(13 downto 0) & "00"; --data: framewidth*8*4 = channel_size  8=canali ma metto in bytes -> x4

                    when "01" => --Reserved
                        num_samples <= std_logic_vector(to_unsigned(0, 8)); 
                        data_length <= std_logic_vector(to_unsigned(0, 16));--BYTE

                    when "10" => --EOB
                        num_samples <= std_logic_vector(to_unsigned(0, 8)); 
                        data_length <= std_logic_vector(to_unsigned(20, 16));   --5*4; -- 5 righe 20 BYTE
                        
                    when "11" => --SOB/CHOKE/ERR..
                        num_samples <= std_logic_vector(to_unsigned(0, 8)); 
                        data_length <= std_logic_vector(to_unsigned(4, 16));  -- 1*4; -- 1 riga 4 BYTE
                                
                    when others => --reserved
                        num_samples <= std_logic_vector(to_unsigned(0, 8)); 
                        data_length <= std_logic_vector(to_unsigned(0, 16)); --BYTE

                end case;
                
                MEP_frame <= 5;

            when 5 =>           -- 4 riga header evento (azzurra)

                MEP_data <= b"0" & b"10000000" & num_samples & data_length;                             -- QUARTA RIGA NELLA DATA_OUT_MAIN_FIFO -------------<<<      
                --FLAGS: primo bit: L0 readout   --   secondo bit: NO zero suppressions                      
                MEP_wen <= '1'; --and not begin_end_trig; tolto 
                MEP_length <= MEP_length + '1'; 
                checksum <= checksum + (b"10000000" & num_samples & data_length);                    
                MEP_frame <= 6;
                

            when 6 =>           -- 5 riga header evento (azzurra)

                MEP_data <= b"0" & x"000000FF";  --Channel Mask -> 000...001111_1111  ho 8 canali attivi
                MEP_wen <= '1';
                MEP_length <= MEP_length + '1';
                checksum <= checksum + x"000000FF";
                
                -----------------------

                count_framewidth <= framewidth - 1; --preparo per lo stato dopo  
                MEP_frame <= 7;


            when 7 =>         -- DATA     (Ricordo trigger: 00-Fisica | 01-Reserved | 10-EOB | 11-SOB/CHOKE/ERR..)

                if (trigger = "00") then  -- TRIGGER DI FISICA -> LEGGO TUTTA LA FRAME FIFO -> SCRIVO TUTTO NELLA DATA_OUT_MAIN_FIFO

                    case frame_fifos is
                        when read_ff =>
                            MEP_wen  <= '0';
                            frame_fifo_rden <= (others => '0');
                            frame_fifo_rden(ch_counter) <= '1'; 
                            frame_fifos <= write_ff;
                            count_framewidth <= framewidth - 1;                            

                        when write_ff =>
                            MEP_wen  <= '1';

                            MEP_data <= b"0" & x"0" & frame_fifo_data(ch_counter)(23 downto 12) & x"0" & frame_fifo_data(ch_counter)(11 downto 0) ;
                            MEP_length <= MEP_length + '1';
                            checksum <= checksum + (x"0" & frame_fifo_data(ch_counter)(23 downto 12) & x"0" & frame_fifo_data(ch_counter)(11 downto 0));

                            if count_framewidth /= 0 then                
                                count_framewidth <= count_framewidth - 1;  
                                MEP_frame   <= 7;
                                frame_fifos <= write_ff;
                            else 
                                count_framewidth <= framewidth - 1;
                                frame_fifos <= write_ff;
                                frame_fifo_rden <= (others => '0');
                                frame_fifos <= read_ff;

                                if (ch_counter /= active_channels - 1) then 
                                    ch_counter  <= ch_counter + 1;
                                    MEP_frame   <= 7;  
                                else --ho scritto tutti i canali
                                    ch_counter <= 0;
                                    MEP_frame   <= 8;
                                end if;
                            end if;
                        end case;
                    end if;


                if (trigger = "11") then  -- TRIGGER SOB/CHOKE/ERROR/SYNCHRONIZATION -> SCRIVO 1 riga  che rappresenta tutti i canali.
                    frame_fifo_rden <= (others =>'1');  --scarico tutte le frame fifo
                    checksum <= checksum; --tanto sono tutti 0
                    if count_framewidth /= 0 then                                      -- legge tutta la BUFFER_FIFO del canale "ch_counter"
                        count_framewidth <= count_framewidth-1;  --ho letto una riga quindi decremento
                        MEP_frame  <= 7;
                    else --ho scritto tutte le frame fifos del canale ch_counter
                        --frame_fifo_rden <= (others =>'0'); --Fermo la lettura dai canali
                        count_framewidth <= framewidth-1;
                        MEP_length <= MEP_length + '1';
                        MEP_data <= b"0" & timestamp;
                        MEP_wen  <= '1'; 
                        MEP_frame <= 8;   
                    end if;
                end if;


                if (trigger = "10") then  -- TRIGGER EOB -> SCRIVO 5 righe che rappresentano tutti i canali.
                    frame_fifo_rden <= (others =>'1');  --scarico tutte le frame fifo
                    cnt_a <= 0;

                    if count_framewidth /= 0 then                                      -- legge tutta la BUFFER_FIFO del canale "ch_counter"
                        count_framewidth <= count_framewidth-1;  --ho letto una riga quindi decremento
                        MEP_frame  <= 7;
                    else --ho scritto tutte le frame fifos del canale ch_counter
                        --frame_fifo_rden <= (others =>'0'); --Fermo la lettura dai canali
                        --cnt_a <= cnt_a +1;
                        if (cnt_a = 1) then
                            cnt_a <= cnt_a +1;
                            MEP_data <= b"0" & x"00" & (event_no+1);  --numero l0trigger
                            MEP_wen  <= '1';
                            checksum <= checksum + (x"00" & (event_no+1)); --tanto sono tutti                           
                            MEP_length <= MEP_length + '1';
                            frame_fifo_rden <= (others =>'0');
                        elsif (cnt_a = 5) then
                            cnt_a <= 0;
                            MEP_frame <= 8;
                        elsif( cnt_a = 0) then --cnt_a =0
                            cnt_a <= cnt_a +1;
                            MEP_data <= b"0" & timestamp;
                            MEP_wen  <= '1';
                            MEP_length <= MEP_length + '1';
                        else                   --cnt_a =2,3,4
                            cnt_a <= cnt_a +1;
                            MEP_data <= (others => '0');
                            MEP_wen  <= '1';
                            MEP_length <= MEP_length + '1';
                        end if;
                    end if;


                end if;
        
                if (trigger = "01") then  -- TRIGGER RESERVED -> SVUOTO LE FIFO E NON SCRIVO NIENTE NEL MEP
                    frame_fifo_rden <= (others =>'1');  --scarico tutte le frame fifo
                    if count_framewidth /= 0 then                                      -- legge tutta la FRAME_FIFO del canale "ch_counter"
                        count_framewidth <= count_framewidth-1;  --ho letto una riga quindi decremento
                        MEP_frame  <= 7;
                    else --ho scritto tutte le FRAME fifos del canale ch_counter
                        --frame_fifo_rden <= (others =>'0'); --Fermo la lettura dai canali
                        count_framewidth <= framewidth-1;
                        MEP_frame <= 0;   
                    end if;
                end if;


            when 8 =>           -- Checksum
            
                frame_fifo_rden <= (others => '0');
                MEP_write <= "00";
                MEP_data <= b"0" & checksum; 
                MEP_wen <= '1';
                MEP_length <= MEP_length + '1';
                n_eventi_MEP := n_eventi_MEP +1; --ho completato la scrittura di un evento

                if( n_eventi_MEP = 8 or trigger = "10" ) then --Ho 8 eventi nel MEP oppure ho appena scritto un EOB -> chiudo il MEP 
                    MEP_frame <= 9; --scrivo la seconda riga rimasta dell'header del MEP    
                else --Scrivo il prossimo evento nel MEP
                    MEP_frame <= 0; --torno alla lettura della tcs_fifo attendendo che si riempia.
                end if;
                checksum        <= (others => '0'); --azzero perchè ho terminato di scrivere questo evento
                
            when 9 => --1 riga MEP (scrivo)
                MEP_wen         <= '0';
                MEP_data <= MEP_head_1;
                header_wen      <= '1';  
                MEP_frame       <= 10;  

            when 10 =>           --2 riga header MEP  (CHIUSURA MEP)
                MEP_data     <= b"0" & x"00" &  std_logic_vector(to_unsigned(n_eventi_MEP, 8)) &  MEP_length(13 downto 0) & "00"; --MEP_LENGTH convertita in BYTE
                header_wen      <= '1';
                n_eventi_MEP := 0; --azzero n. eventi nel MEP, ho finito il MEP 
                MEP_length      <= (others => '0'); --azzero il contatore delle dimensioni del MEP, per ripartire.
                checksum        <= (others => '0');
                MEP_frame       <= 11; --scrivo footer

            when 11 =>         -- Internal Footer
                MEP_data <= b"1" & x"cfed1200"; --Footer
                MEP_wen <= '1';
                header_wen      <= '0';
                MEP_frame       <= 0;

                
            when others =>
                MEP_frame <= 0; 
        end case;
    else
        frame_fifo_rden <= (others => '0');
        
    end if;
end if;
end process;
end behavioral;