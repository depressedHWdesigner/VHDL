
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ProgrammableLogic is
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
end ProgrammableLogic;

architecture Behavioral of ProgrammableLogic is
--Signal declaration

--Component declaration
component ADC_sampler is 
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
ADC_Reader: ADC_sampler
    PORT MAP(
        clk_adc => clk_adc,
        sysclk => sysclk,
        sync_sysclk_rst => sync_sysclk_rst,
        sync_clk_adc_rst => sync_clk_adc_rst,
        muxout => muxout,
        start => start,
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
--        I_data => I_data,
--        Q_data => Q_data
        
    );

end Behavioral;
