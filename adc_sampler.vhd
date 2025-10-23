
--Los datos provinientes del ADC se escriben en una FIFO
--Una vez llena los leemos con el reloj de la fpga y se serializan
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ADC_sampler is
  Port (
        clk_adc:    in std_logic;--Reloj del ADC a 20 MHz
        sysclk:     in std_logic;--Reloj del sistema
        rst:        in std_logic;
        muxout:     in std_logic;
        start:      in std_logic;
        
        I0:         in std_logic;
        I1:         in std_logic;
        I2:         in std_logic;
        I3:         in std_logic;
        I4:         in std_logic;
        I5:         in std_logic;
        I6:         in std_logic;
        I7:         in std_logic;
        I8:         in std_logic;
        I9:         in std_logic;
        I10:        in std_logic;
        I11:        in std_logic;
        
        Q0:         in std_logic;
        Q1:         in std_logic;
        Q2:         in std_logic;
        Q3:         in std_logic;
        Q4:         in std_logic;
        Q5:         in std_logic;
        Q6:         in std_logic;
        Q7:         in std_logic;
        Q8:         in std_logic;
        Q9:         in std_logic;
        Q10:        in std_logic;
        Q11:        in std_logic;
        AXI_data_fifo_s_axis_tlast: out std_logic;
        AXI_data_fifo_s_axis_tvalid:out std_logic;
        AXI_data_fifo_s_axis_tready:in std_logic;
        data_debug: out std_logic_vector(31 downto 0)--Concatenacion de I_data y Q_data para debugging
--        I_data: out std_logic_vector(11 downto 0); 
--        Q_data: out std_logic_vector(11 downto 0)
   );
end ADC_sampler;

architecture Behavioral of ADC_sampler is

--Internal signals
signal I0_reg, I1_reg, I2_reg, I3_reg, I4_reg, I5_reg, I6_reg, I7_reg, I8_reg, I9_reg, I10_reg, I11_reg: std_logic;
signal Q0_reg, Q1_reg, Q2_reg, Q3_reg, Q4_reg, Q5_reg, Q6_reg, Q7_reg, Q8_reg, Q9_reg, Q10_reg, Q11_reg: std_logic;
signal I_reg, Q_reg : std_logic_vector(11 downto 0);
signal adc_raw_i, adc_raw_q, fifo_i_din, fifo_q_din: std_logic_vector(11 downto 0);--Concatenamos aqui los datos en crudo
signal write_enable, read_enable: std_logic;
signal fifo_i_dout, fifo_q_dout:    std_logic_vector(11 downto 0); 
signal fifo_i_full, fifo_q_full:    std_logic;
signal fifo_i_empty, fifo_q_empty:  std_logic;
signal fifo_i_wr_rst_busy, fifo_i_rd_rst_busy, fifo_q_wr_rst_busy, fifo_q_rd_rst_busy: std_logic;
signal fifo_rst: std_logic;

signal muxout_reg:                      std_logic;
signal muxout_valid:                    std_logic;
signal muxout_counter:                  integer;
constant DMA_buffer_size:               integer:= 1024;--Depends on XAxiDma_BdSetLength()
constant DMA_transfer_length:           integer:=10;
signal data_debug_counter:              integer;
signal sampling_enable:                 std_logic;--La uso para enviar 2 rampas solo una vez
constant two_chirps_muxout:             integer:=4;

signal send_debug_data: std_logic;

signal start_adc_domain: std_logic:='0';
signal start_adc_sync: std_logic_vector(1 downto 0):=(others => '0');--Double fli-flop for synchronization with clk_adc domain

--Component declaration
--Tenemos dos canales de datos de 12 bits: I[11:0] y Q[11:0]
--Usamos dos FIFOs, una para cada canal, de 2048x12
COMPONENT fifo_generator_0
  PORT (
    rst : IN STD_LOGIC;
    wr_clk : IN STD_LOGIC;
    rd_clk : IN STD_LOGIC;
    din : IN STD_LOGIC_VECTOR(11 DOWNTO 0);
    wr_en : IN STD_LOGIC;
    rd_en : IN STD_LOGIC;
    dout : OUT STD_LOGIC_VECTOR(11 DOWNTO 0);
    full : OUT STD_LOGIC;
    empty : OUT STD_LOGIC;
    wr_rst_busy : OUT STD_LOGIC;
    rd_rst_busy : OUT STD_LOGIC 
  );
END COMPONENT;
component ila_0 is
    port (
        clk      : in std_logic;
        probe0   : in std_logic;
        probe1   : in std_logic;
        probe2   : in std_logic;
        probe3   : in std_logic;
        probe4   : in std_logic;
        probe5   : in std_logic_vector(11 downto 0)
    );
end component;
begin
--Component instantiation
fifo_rst <= not(rst);
FIFO_I : fifo_generator_0
  PORT MAP (
    rst => fifo_rst,
    wr_clk => clk_adc,
    rd_clk => sysclk,
    din => fifo_i_din,
    wr_en => write_enable,
    rd_en => read_enable,
    dout => fifo_i_dout,
    full => fifo_i_full,
    empty => fifo_i_empty,
    wr_rst_busy => fifo_i_wr_rst_busy,
    rd_rst_busy => fifo_i_rd_rst_busy
  );
  
  FIFO_Q : fifo_generator_0
  PORT MAP (
    rst => fifo_rst,
    wr_clk => clk_adc,
    rd_clk => sysclk,
    din => fifo_q_din,
    wr_en => write_enable,
    rd_en => read_enable,
    dout => fifo_q_dout,
    full => fifo_q_full,
    empty => fifo_q_empty,
    wr_rst_busy => fifo_q_wr_rst_busy,
    rd_rst_busy => fifo_q_rd_rst_busy
  );
--Sincronizacion de señal de start con clk_Adc
start_adc_process: process(clk_adc)
begin
    if rising_edge(clk_adc) then
        start_adc_sync(0) <= start;
        start_adc_sync(1)<= start_adc_sync(0);
    end if;
end process;
start_adc_domain <= start_adc_sync(1);

data_register_process:  process(clk_adc, rst)
  begin
    if rst = '0' then
        I_reg      <= (others => '0');
        Q_reg      <= (others => '0');
        
        adc_raw_i <= (others => '0');
        adc_raw_q <= (others => '0');

    elsif rising_edge(clk_adc) then
        --Registramos datos de entrada
  
        if start_adc_domain = '1' then

            I_reg <= I11 & I10 & I9 & I8 & I7 & I6 & I5 & I4 & I3 & I2 & I1 & I0;
            Q_reg <= Q11 & Q10 & Q9 & Q8 & Q7 & Q6 & Q5 & Q4 & Q3 & Q2 & Q1 & Q0;
            adc_raw_i <= I_reg;
            adc_raw_q <= Q_reg;
        end if;  
    end if;

  end process;
 
 write_process: process(clk_adc, rst)
 begin
    if rst = '0' then
        write_enable <= '0';
        fifo_i_din   <= (others => '0'); 
        fifo_q_din   <= (others => '0');       
    elsif rising_edge(clk_adc) then
        -- Espero a que las FIFOs terminen su reset
       
        if start_adc_domain = '1' then
            
            if fifo_i_wr_rst_busy = '1' or fifo_q_wr_rst_busy = '1' then
                write_enable <= '0';
                
            --Solo escribe si no está llena    
            elsif fifo_i_full = '0' and fifo_q_full = '0' then
                write_enable <= '1';
                fifo_i_din <= adc_raw_i;
                fifo_q_din <= adc_raw_q;
                
            else
                write_enable <= '0';    
            end if;  
        end if;
  
    end if;
  
 end process; 
 
 read_process: process(sysclk, rst)
 begin
    if rst = '0' then
        read_enable <= '0';
        AXI_data_fifo_s_axis_tlast <= '0';
        AXI_data_fifo_s_axis_tvalid <= '0';
        data_debug  <= (others => '0');
        data_debug_counter <= 0;
                
        muxout_reg <= '0';
        muxout_valid <= '0';
        muxout_counter <= 0;
        send_debug_data<= '0';
    elsif rising_edge(sysclk) then
        -- Condiciones para leer y cargar a la vez
        muxout_reg <= muxout;
         
        read_enable <= '0';
        AXI_data_fifo_s_axis_tlast <= '0';
       
        
        if start='1' then
            send_debug_data <= '1';--Start sending debug data
            
            if muxout_valid = '1' then 
                muxout_counter <= muxout_counter +1;
            end if;
            
            if sampling_enable = '0' then
                if (muxout_counter = two_chirps_muxout) then
                    sampling_enable <= '1';--No mandes mas
                    muxout_counter <= 0;
                else 
                    send_debug_data <= '1';
                end if;
             end if;    
            
            if (fifo_i_rd_rst_busy = '0') and (fifo_q_rd_rst_busy = '0') and
               (fifo_i_empty = '0') and (fifo_q_empty = '0') and send_debug_data = '1' then
                --read_enable <= '1';  -- leer de las FIFOs
                
                --Ponemos datos en el bus
                AXI_data_fifo_s_axis_tvalid <= '1';
                data_debug <= fifo_i_dout & fifo_q_dout & "00000000";
                -----------------------------------------------------------------
                -- Handshake: solo avanzamos si el receptor acepta (tready = '1')
                -----------------------------------------------------------------
                if AXI_data_fifo_s_axis_tready = '1' then
                    read_enable <= '1';
                    
                    if (data_debug_counter = DMA_transfer_length - 1) then
                        AXI_data_fifo_s_axis_tlast <= '1';
                        data_debug_counter <= 0;  
                    else 
                        data_debug_counter <= data_debug_counter + 1;
                    end if;
                end if; 
                else
                    AXI_data_fifo_s_axis_tvalid <= '0';
                end if;
               end if; 
           end if;
     muxout_valid <= muxout and(not(muxout_reg));--De este modo la señal muxout dura un solo ciclo de reloj  
 end process;  

ILA_DS : ila_0
    port map (
        clk      => sysclk,      -- input wire clk
        probe0   => rst,   -- input wire std_logic
        probe1   => muxout,
        probe2   => read_enable,
        probe3   => send_debug_data,
        probe4   => start,
        probe5   => fifo_i_dout
    );

--I_data <= fifo_i_dout;
--Q_data <= fifo_q_dout;
end Behavioral;
