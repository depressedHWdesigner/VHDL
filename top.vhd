
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top is
  Port (
    --Señales de datos del ADC
    clk_adc:            in std_logic;
    I0:                 in std_logic;
    I1:                 in std_logic;
    I2:                 in std_logic;
    I3:                 in std_logic;
    I4:                 in std_logic;
    I5:                 in std_logic;
    I6:                 in std_logic;
    I7:                 in std_logic;
    I8:                 in std_logic;
    I9:                 in std_logic;
    I10:                in std_logic;
    I11:                in std_logic;
    
    Q0:                 in std_logic;
    Q1:                 in std_logic;
    Q2:                 in std_logic;
    Q3:                 in std_logic;
    Q4:                 in std_logic;
    Q5:                 in std_logic;
    Q6:                 in std_logic;
    Q7:                 in std_logic;
    Q8:                 in std_logic;
    Q9:                 in std_logic;
    Q10:                in std_logic;
    Q11:                in std_logic;  
                   
    --Señales ICs (SPI, enable, etc)
    SPI0_SCLK_O_0:      out std_logic;
    SPI0_MOSI_O_0:      out std_logic;
    SPI0_SS_O_0:        out std_logic;  --CS del PLL
    SPI0_SS1_O_0:       out std_logic; --CS del atenuador
    CE:                 out std_logic;--Enable del PLL
    EN_PM:              out std_logic;--Enable de los LDOs
    muxout:             in std_logic;
    
    --Señales del wrapper del block diagram
    DDR_addr:           inout std_logic_vector(14 downto 0);
    DDR_ba:             inout std_logic_vector(2 downto 0);
    DDR_cas_n:          inout std_logic;
    DDR_ck_n:           inout std_logic;
    DDR_ck_p:           inout std_logic;
    DDR_cke:            inout std_logic;
    DDR_cs_n:           inout std_logic;
    DDR_dm:             inout std_logic_vector(3 downto 0);
    DDR_dq:             inout std_logic_vector(31 downto 0);
    DDR_dqs_n:          inout std_logic_vector(3 downto 0);
    DDR_dqs_p:          inout std_logic_vector(3 downto 0);
    DDR_odt:            inout std_logic;
    DDR_ras_n:          inout std_logic;
    DDR_reset_n:        inout std_logic;
    DDR_we_n:           inout std_logic;
    FIXED_IO_ddr_vrn  : inout std_logic;
    FIXED_IO_ddr_vrp  : inout std_logic;
    FIXED_IO_mio      : inout std_logic_vector(53 downto 0);
    FIXED_IO_ps_clk   : inout std_logic;
    FIXED_IO_ps_porb  : inout std_logic;
    FIXED_IO_ps_srstb : inout std_logic
   );
end top;

architecture Behavioral of top is
--Signal declaration
signal sysclk: std_logic;--Clock proporcionado por el PS
signal start: std_logic;


signal data_debug:  std_logic_vector(31 downto 0);
signal AXI_data_fifo_s_axis_tlast:     std_logic;
signal AXI_data_fifo_s_axis_tvalid:    std_logic;
signal AXI_data_fifo_s_axis_tready:    std_logic;

--Reset synchronization signals
signal async_rst:   std_logic;--Señal de reset asincron a nivel bajo proporcionada por el PS
signal async_sysclk_rst_reg: std_logic_vector(1 downto 0):=(others => '1');
signal sync_sysclk_rst:  std_logic;--Reset sincrono con sysclk

signal sync_clk_adc_rst: std_logic;--Reset sincrono con clk_adc
signal async_clk_adc_rst_reg: std_logic_vector(1 downto 0):=(others => '1');

signal muxout_reg: std_logic_vector(1 downto 0):=(others => '0');
signal sync_sysclk_muxout: std_logic;
--Component Declaration
component ProcessingSystem_wrapper is
    port (
    --Señales ICs (SPI, enable, etc)
    SPI0_SCLK_O_0:                  out std_logic;
    SPI0_MOSI_O_0:                  out std_logic;
    SPI0_SS_O_0:                    out std_logic;  --CS del PLL
    SPI0_SS1_O_0:                   out std_logic; --CS del atenuador
    CE:                             out std_logic;--Enable del PLL
    EN_PM:                          out std_logic;--Enable de los LDOs
    
    --Señales de la AXI DATA FIFO
    data_debug:                     in std_logic_vector(31 downto 0);
    AXI_data_fifo_s_axis_tlast:     in std_logic;
    AXI_data_fifo_s_axis_tvalid:    in std_logic;
    AXI_data_fifo_s_axis_tready:    out std_logic;
    
    --Señales del wrapper del block diagram
    peripheral_aresetn:             out std_logic;
    DDR_addr:                       inout std_logic_vector(14 downto 0);
    DDR_ba:                         inout std_logic_vector(2 downto 0);
    DDR_cas_n:                      inout std_logic;
    DDR_ck_n:                       inout std_logic;
    DDR_ck_p:                       inout std_logic;
    DDR_cke:                        inout std_logic;
    DDR_cs_n:                       inout std_logic;
    DDR_dm:                         inout std_logic_vector(3 downto 0);
    DDR_dq:                         inout std_logic_vector(31 downto 0);
    DDR_dqs_n:                      inout std_logic_vector(3 downto 0);
    DDR_dqs_p:                      inout std_logic_vector(3 downto 0);
    DDR_odt:                        inout std_logic;
    DDR_ras_n:                      inout std_logic;
    DDR_reset_n:                    inout std_logic;
    DDR_we_n:                       inout std_logic;
    FCLK:                    out std_logic;--Clock proporcionado por el PS (actualmente 50 MHz)
    FIXED_IO_ddr_vrn  :             inout std_logic;
    FIXED_IO_ddr_vrp  :             inout std_logic;
    FIXED_IO_mio      :             inout std_logic_vector(53 downto 0);
    FIXED_IO_ps_clk   :             inout std_logic;
    FIXED_IO_ps_porb  :             inout std_logic;
    FIXED_IO_ps_srstb :             inout std_logic
    );
end component;    

component ProgrammableLogic is 
  Port ( 
        clk_adc:                        in std_logic;--Reloj del ADC a 20 MHz
        sysclk:                         in std_logic;--Reloj del sistema
        sync_sysclk_rst:                in std_logic;--Señal de reset sincrona del dominio de sysclk
        sync_clk_adc_rst:               in std_logic;--Señal de reset sincrona del dominio clk_adc
        muxout:                         in std_logic;
        start:                          in std_logic;
        
        I0:                             in std_logic;
        I1:                             in std_logic;
        I2:                             in std_logic;
        I3:                             in std_logic;
        I4:                             in std_logic;
        I5:                             in std_logic;
        I6:                             in std_logic;
        I7:                             in std_logic;
        I8:                             in std_logic;
        I9:                             in std_logic;
        I10:                            in std_logic;
        I11:                            in std_logic;
        
        Q0:                             in std_logic;
        Q1:                             in std_logic;
        Q2:                             in std_logic;
        Q3:                             in std_logic;
        Q4:                             in std_logic;
        Q5:                             in std_logic;
        Q6:                             in std_logic;
        Q7:                             in std_logic;
        Q8:                             in std_logic;
        Q9:                             in std_logic;
        Q10:                            in std_logic;
        Q11:                            in std_logic;
        AXI_data_fifo_s_axis_tlast:     out std_logic;
        AXI_data_fifo_s_axis_tvalid:    out std_logic;
        AXI_data_fifo_s_axis_tready:    in std_logic;
        data_debug:                     out std_logic_vector(31 downto 0)--Concatenacion de I_data y Q_data para debugging
--        I_data: out std_logic_vector(11 downto 0); 
--        Q_data: out std_logic_vector(11 downto 0)
  );
end component;
begin

--Component Instantiation
PS: ProcessingSystem_wrapper
    PORT MAP(
        SPI0_SCLK_O_0 => SPI0_SCLK_O_0,
        SPI0_MOSI_O_0 => SPI0_MOSI_O_0,
        SPI0_SS_O_0 => SPI0_SS_O_0,
        SPI0_SS1_O_0 => SPI0_SS1_O_0,
        CE => CE,
        EN_PM => EN_PM,
        data_debug => data_debug,
        peripheral_aresetn => async_rst,--The processor system reset generates an asynchronous reset signal we must synchronize to both clock domains
        AXI_data_fifo_s_axis_tlast => AXI_data_fifo_s_axis_tlast,
        AXI_data_fifo_s_axis_tvalid => AXI_data_fifo_s_axis_tvalid,
        AXI_data_fifo_s_axis_tready => AXI_data_fifo_s_axis_tready,
        DDR_addr => DDR_addr,
        DDR_ba => DDR_ba,
        DDR_cas_n => DDR_cas_n,
        DDR_ck_n => DDR_ck_n,
        DDR_ck_p => DDR_ck_p, 
        DDR_cke => DDR_cke,
        DDR_cs_n => DDR_cs_n,
        DDR_dm => DDR_dm,
        DDR_dq => DDR_dq,
        DDR_dqs_n => DDR_dqs_n,
        DDR_dqs_p => DDR_dqs_p,
        DDR_odt => DDR_odt,
        DDR_ras_n => DDR_ras_n,
        DDR_reset_n => DDR_reset_n,
        DDR_we_n => DDR_we_n,
        FCLK => sysclk,
        FIXED_IO_ddr_vrn => FIXED_IO_ddr_vrn,
        FIXED_IO_ddr_vrp => FIXED_IO_ddr_vrp,
        FIXED_IO_mio => FIXED_IO_mio,
        FIXED_IO_ps_clk => FIXED_IO_ps_clk,
        FIXED_IO_ps_porb => FIXED_IO_ps_porb,
        FIXED_IO_ps_srstb => FIXED_IO_ps_srstb
    );

PL: ProgrammableLogic
    PORT MAP(
        sysclk => sysclk, 
        clk_adc => clk_adc,
        sync_sysclk_rst => sync_sysclk_rst,--Reset sincrono con sysclk
        sync_clk_adc_rst => sync_clk_adc_rst,
        start => start,
        muxout => muxout,
        I0 => I0,
        I1 => I1,
        I2 => I2,
        I3 => I3,
        I4 => I4,
        I5 => I5,
        I6 => I6,
        I7 => I7,
        I8 => I8,
        I9 => I9,
        I10 => I10,
        I11 => I11,
        Q0 => Q0,
        Q1 => Q1,
        Q2 => Q2,
        Q3 => Q3,
        Q4 => Q4,
        Q5 => Q5,
        Q6 => Q6,
        Q7 => Q7,
        Q8 => Q8,
        Q9 => Q9,
        Q10 => Q10,
        Q11 => Q11,
        AXI_data_fifo_s_axis_tlast => AXI_data_fifo_s_axis_tlast,
        AXI_data_fifo_s_axis_tvalid => AXI_data_fifo_s_axis_tvalid,
        AXI_data_fifo_s_axis_tready => AXI_data_fifo_s_axis_tready,
        data_debug => data_debug
        
    );

--Proceso para sincronizar el reset con sysclk
reset_sysclk_process: process(sysclk)
begin
    if rising_edge(sysclk) then
        async_sysclk_rst_reg(0) <= async_rst;
        async_sysclk_rst_reg(1) <= async_sysclk_rst_reg(0);
    end if;
end process;
sync_sysclk_rst <= async_sysclk_rst_reg(1);

--Proceso para sincronizar el reset con clk_adc
reset_clk_adc_process: process(clk_adc)
begin
    if rising_edge(clk_adc) then
        async_clk_adc_rst_reg(0) <= async_rst;
        async_clk_adc_rst_reg(1) <= async_clk_adc_rst_reg(0);
    end if;
end process;
sync_clk_adc_rst <= async_clk_adc_rst_reg(1);


--Proceso para sincronizar muxout con sysclk
muxout_sysclk_process: process(sysclk)
begin
    if rising_edge(sysclk) then
        muxout_reg(0) <= muxout;
        muxout_reg(1)<= muxout_reg(0);
    end if;
end process;
sync_sysclk_muxout <= muxout_reg(1);

process(sysclk)
begin
    if rising_edge(sysclk) then
        if sync_sysclk_rst = '0' then
            start <= '0';
        elsif sync_sysclk_muxout = '1' then
            start <= '1';  -- se mantiene en 1 permanentemente
        end if;
    end if;
end process;
end Behavioral;
