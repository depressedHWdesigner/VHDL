----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 09.04.2025 09:46:35
-- Design Name: 
-- Module Name: DataSampler - Behavioral
-- Description: ADC Sampler with double-register synchronization for asynchronous input
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity DataSampler is
  Port ( 
    Start:          in std_logic;
    MUXOUT:         in std_logic;
    Clk:            in std_logic; -- 40MHz clock
    Reset:          in std_logic;
    
    -- JB Ports
    JB0 : in STD_LOGIC; JB1 : in STD_LOGIC; JB2 : in STD_LOGIC; JB3 : in STD_LOGIC;
    JB4 : in STD_LOGIC; JB5 : in STD_LOGIC; JB6 : in STD_LOGIC; JB7 : in STD_LOGIC;

    -- JC Ports
    JC0 : in STD_LOGIC; JC1 : in STD_LOGIC; JC2 : in STD_LOGIC; JC3 : in STD_LOGIC;
    JC4 : in STD_LOGIC; JC5 : in STD_LOGIC; JC6 : in STD_LOGIC; JC7 : in STD_LOGIC;  

    -- JD Ports
    JD0 : in STD_LOGIC; JD1 : in STD_LOGIC; JD2 : in STD_LOGIC; JD3 : in STD_LOGIC;
    JD4 : in STD_LOGIC; JD5 : in STD_LOGIC; JD6 : in STD_LOGIC; JD7 : in STD_LOGIC;  

    data_valid      : out STD_LOGIC;
    debug_tvalid    : out std_logic;
    debug_tready    : in std_logic;
    debug_tlast     : out std_logic;
    data_debug      : out std_logic_vector(31 downto 0);
    DATA_CH_A       : out std_logic_vector(11 downto 0);--I
    DATA_CH_B       : out std_logic_vector(11 downto 0)--Q
  );
end DataSampler;

architecture Behavioral of DataSampler is

    signal clk_counter:            unsigned(2 downto 0):= (others => '0');
    signal DATA_CHANNEL_A, DATA_CHANNEL_B: std_logic_vector(11 downto 0);
    signal data_debug_counter:    unsigned(10 downto 0);
    constant DMA_buffer_size:     integer := 1024;
    constant DMA_transfer_length: integer := 100;
    signal data_sampled:          std_logic;
    signal data_sampled_counter:  integer;
    constant MUXOUT_limit:        integer := 2;
    constant data_sampled_period: integer := 200;

    signal MUXOUT_reg:            std_logic;
    signal MUXOUT_valid:          std_logic;
    signal MUXOUT_counter:        integer;
    constant two_ramps_muxout:    integer := 6; 
    constant one_ramp_muxout:     integer := 3;
    signal sampling_enable:       std_logic;

    -- Sincronización doble para evitar errores de lectura asincrónica
    signal JB_sync_1, JB_sync_2 : std_logic_vector(7 downto 0);
    signal JC_sync_1, JC_sync_2 : std_logic_vector(7 downto 0);
    signal JD_sync_1, JD_sync_2 : std_logic_vector(7 downto 0);
    
component ila_0  is
    port(
        clk: in std_logic;
        probe0: std_logic_vector(31 downto 0);
        probe1: std_logic;
        probe2: std_logic;
        probe3: std_logic;
        probe4: std_logic;
        probe5: std_logic;
        probe6: std_logic;
        probe7: std_logic;
        probe8: std_logic;
        probe9: std_logic;
        probe10: std_logic;
        probe11: std_logic;
        probe12: std_logic;
        probe13: std_logic;
        probe14: std_logic;
        probe15: std_logic;
        probe16: std_logic;
        probe17: std_logic;
        probe18: std_logic;
        probe19: std_logic;
        probe20: std_logic;
        probe21: std_logic;
        probe22: std_logic;
        probe23: std_logic;
        probe24: std_logic;
        probe25: std_logic;
        probe26: std_logic;
        probe27: std_logic_vector(11 downto 0);
        probe28: std_logic_vector(11 downto 0)
    
    
    ); 
end component;         

begin

process(all)
    variable DataSamplerCounter  : integer := 0;
begin
    if Reset = '0' then
        data_valid <= '0';
        DATA_CHANNEL_A <= (others => 'Z');
        DATA_CHANNEL_B <= (others => 'Z');
        data_debug <= (others => 'Z');
        data_debug_counter <= (others => '0');
        debug_tvalid <= '0';
        debug_tlast <= '0';
        data_sampled <= '0';
        data_sampled_counter <= 0;
        MUXOUT_counter <= 0;
        MUXOUT_reg <= '0';
        MUXOUT_valid <= '0';
        sampling_enable <= '0';
    elsif rising_edge(Clk) then
        -- Etapa 1: primer registro (captura)
        JB_sync_1 <= JB7 & JB6 & JB5 & JB4 & JB3 & JB2 & JB1 & JB0;
        JC_sync_1 <= JC7 & JC6 & JC5 & JC4 & JC3 & JC2 & JC1 & JC0;
        JD_sync_1 <= JD7 & JD6 & JD5 & JD4 & JD3 & JD2 & JD1 & JD0;

        -- Etapa 2: segundo registro (estable)
        JB_sync_2 <= JB_sync_1;
        JC_sync_2 <= JC_sync_1;
        JD_sync_2 <= JD_sync_1;

        MUXOUT_reg <= MUXOUT;

        if Start = '1' then
            DATA_CH_A <= DATA_CHANNEL_A;
            DATA_CH_B <= DATA_CHANNEL_B;

            if DataSamplerCounter = 1 then
                -- Sampleo de datos sincronizados
                DATA_CHANNEL_A(0)  <= JB_sync_2(4);
                DATA_CHANNEL_A(1)  <= JB_sync_2(0);
                DATA_CHANNEL_A(2)  <= JB_sync_2(5);
                DATA_CHANNEL_A(3)  <= JB_sync_2(1);
                DATA_CHANNEL_A(4)  <= JB_sync_2(6);
                DATA_CHANNEL_A(5)  <= JB_sync_2(2);
                DATA_CHANNEL_A(6)  <= JB_sync_2(7);
                DATA_CHANNEL_A(7)  <= JB_sync_2(3);
                DATA_CHANNEL_A(8)  <= JC_sync_2(4);
                DATA_CHANNEL_A(9)  <= JC_sync_2(0);
                DATA_CHANNEL_A(10) <= JC_sync_2(5);
                DATA_CHANNEL_A(11) <= JC_sync_2(1);

                DATA_CHANNEL_B(0)  <= JC_sync_2(6);
                DATA_CHANNEL_B(1)  <= JC_sync_2(2);
                DATA_CHANNEL_B(2)  <= JC_sync_2(7);
                DATA_CHANNEL_B(3)  <= JC_sync_2(3);
                DATA_CHANNEL_B(4)  <= JD_sync_2(4);
                DATA_CHANNEL_B(5)  <= JD_sync_2(0);
                DATA_CHANNEL_B(6)  <= JD_sync_2(5);
                DATA_CHANNEL_B(7)  <= JD_sync_2(1);
                DATA_CHANNEL_B(8)  <= JD_sync_2(6);
                DATA_CHANNEL_B(9)  <= JD_sync_2(2);
                DATA_CHANNEL_B(10) <= JD_sync_2(7);
                DATA_CHANNEL_B(11) <= JD_sync_2(3);

                data_valid <= '1';

                -- Control de rampa doble
                if MUXOUT_valid = '1' then
                    MUXOUT_counter <= MUXOUT_counter + 1;
                end if;

                if sampling_enable = '0' then     
                    if (MUXOUT_counter = one_ramp_muxout - 1) then
                        data_sampled <= '0';
                        sampling_enable <= '1';
                        MUXOUT_counter <= 0;
                    else
                        data_sampled <= '1';
                    end if;
                end if;

            end if;

            -- Control AXI debug FIFO
            debug_tlast <= '0';
            debug_tvalid <= '0';

            if (data_sampled = '1' and (data_debug_counter < DMA_transfer_length)) then
                debug_tvalid <= '1';
                data_debug <= DATA_CHANNEL_A & DATA_CHANNEL_B & "00000000";

                if (debug_tready = '1') then 
                    if (data_debug_counter = DMA_transfer_length - 1) then
                        debug_tlast <= '1';
                        data_debug_counter <= (others => '0');
                    else
                        data_debug_counter <= data_debug_counter + 1;
                    end if;
                end if;
            else
                debug_tvalid <= '0';    
            end if;

            if DataSamplerCounter = 2 then
                DataSamplerCounter := 0;
            else    
                DataSamplerCounter := DataSamplerCounter + 1;
            end if;
        end if;
    end if;

    MUXOUT_valid <= MUXOUT AND (NOT(MUXOUT_reg)); -- Solo un ciclo activo
end process;

ILA_DS: ila_0
    port map(
        clk => clk, 
        probe0 => data_debug,
        probe1 => JB_sync_2(0),
        probe2 => JB_sync_2(1),
        probe3 => JB_sync_2(2),
        probe4 => JB_sync_2(3),
        probe5 => JB_sync_2(4),
        probe6 => JB_sync_2(5),
        probe7 => JB_sync_2(6),
        probe8 => JB_sync_2(7),
        probe9 => JC_sync_2(0),
        probe10 => JC_sync_2(1),
        probe11 => JC_sync_2(2),
        probe12 => JC_sync_2(3),
        probe13 => JC_sync_2(4),
        probe14 => JC_sync_2(5),
        probe15 => JC_sync_2(6),
        probe16 => JC_sync_2(7),
        probe17 => JD_sync_2(0),
        probe18 => JD_sync_2(1),
        probe19 => JD_sync_2(2),
        probe20 => JD_sync_2(3),
        probe21 => JD_sync_2(4),
        probe22 => JD_sync_2(5),
        probe23 => JD_sync_2(6),
        probe24 => JD_sync_2(7),
        probe25 => MUXOUT,
        probe26 => MUXOUT_valid,
        probe27 => DATA_CHANNEL_A,
        probe28 => DATA_CHANNEL_B
    
    );
end Behavioral;
