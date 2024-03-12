----------------------------------------------------------------------------------
-- @name        Digilent EPP Interface
-- @version     0.3.2
-- @author      Maximilian Passarello (mpassarello.de)
--@             An EPP interface for Digilent FPGA boards
--@             This interface is designed to be used with the Digilent EPP interface
--@             and the Digilent Adept software.
--@             
--@             **Measured data rate ≈ 4.68 kByte/s**
--@             
--@             ## Usage
--@             The module is designed to be used with a FIFO interface.
--@             Either the data & address (**write**) are transferred via the FIFO interface 
--@             **or** the requested address is transferred first and then the corresponding data is expected.
--@             ### Data Write:
--@             With a data write request, the module transfers the **data** and the **address** 
--@             to the two corresponding FIFO interfaces.
--@             ### Data Read:
--@             With a data read request, the module transfers the **requested address** 
--@             to the FIFO interface. It then expects the corresponding data 
--@             via the data input FIFO.
--@
--@             
--@ ## History:
--@ - 0.2.0 (2010.05.30) Initial version
--@ - 0.3.0 (2024.03.06) Refactored and commented
--@ - 0.3.1 (2024.03.09) Complet overhaul of the module
--@ - 0.3.2 (2024.03.13) The forwarding of the address to be read to the FIFO is now implemented correctly. 
--@                      A usage description has been added. Documentation improved.
----------------------------------------------------------------------------------
--@ ## Timing diagrams of the EPP bus
--@ ### EPP Address Write
--@ {
--@   "signal": [
--@     { "name": "DEPP_Bus", "wave": "xx3....xxx", "data": ["Adress"] },
--@     { "name": "DEPP_WriteEnable", "wave": "1.0....1.." },
--@     { "node": "...A...B", "phase": 0.15 },
--@     { "name": "DEPP_AddressEnable", "wave": "1..0...1.." },
--@     { "node": "...E.F.H.I", "phase": 0.15 },
--@     { "node": ".C.D.G", "phase": 0.15 },
--@     { "name": "DEPP_Wait", "wave": "x0...1...0" }
--@   ],
--@   "head": {
--@     "text": "EPP Address Write"
--@   },
--@   "foot": {
--@     "text": "EPP Address Write Cycle Timing Diagram"
--@   },
--@   "edge": ["A+B min. 80 ns", "C+D min. 40ns", "E+F 0 to 10ms", "H+I 0 to 10ms"]
--@ }
--@ ### EPP Data Write
--@ {
--@   "signal": [
--@     { "name": "DEPP_Bus", "wave": "xx3....xxx", "data": ["Data"] },
--@     { "name": "DEPP_WriteEnable", "wave": "1.0....1.." },
--@     { "node": "...A...B", "phase": 0.15 },
--@     { "name": "DEPP_DataEnable", "wave": "1..0...1.." },
--@     { "node": "...E.F.H.I", "phase": 0.15 },
--@     { "node": ".C.D.G", "phase": 0.15 },
--@     { "name": "DEPP_Wait", "wave": "x0...1...0" }
--@   ],
--@   "head": {
--@     "text": "EPP Data Write"
--@   },
--@   "foot": {
--@     "text": "EPP Data Write Cycle Timing Diagram"
--@   },
--@   "edge": ["A+B min. 80 ns", "C+D min. 40ns", "E+F 0 to 10ms", "H+I 0 to 10ms"]
--@ }
--@ ### EPP Data Read
--@ {
--@   "signal": [
--@     { "name": "DEPP_Bus", "wave": "zz...3...x", "data": ["Data"] },
--@     { "node": "...J.K.L.M", "phase": 0.15 },
--@     { "name": "DEPP_WriteEnable", "wave": "x1........" },
--@     { "node": "...A...B", "phase": 0.15 },
--@     { "name": "DEPP_DataEnable", "wave": "1..0...1.." },
--@     { "node": "...E..FH.I", "phase": 0.15 },
--@     { "node": ".C.D.G", "phase": 0.15 },
--@     { "name": "DEPP_Wait", "wave": "x0....1..0" }
--@   ],
--@   "head": {
--@     "text": "EPP Data Read"
--@   },
--@   "foot": {
--@     "text": "EPP Data Read Cycle Timing Diagram"
--@   },
--@   "edge": ["A+B min. 80 ns", "C+D min. 40 ns", "E+F 0 to 10 ms", "H+I 0 to 10 ms", "J+K max. 20 ns", "L+M min. 20 ns"
--@           ]
--@ }

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity DEPP is
    port (
        --@ Clock signal
        --@ Rising edge triggered
        CLK : in std_logic;
        --@ Chip enable
        --@ `1` = enabled, `0` = disabled
        CE : in std_logic;
        --@ Reset signal
        --@ `1` = reset, `0` = normal operation
        RST : in std_logic;
        --@ @virtualbus EPP-Interface @dir out EPP Interface 
        --@ Address strobe 
        DEPP_AddressEnable : in std_logic;
        --@ Data strobe
        DEPP_DataEnable : in std_logic;
        --@ Transfer direction control
        --@ 
        --@ `1` = read (Host from DEPP);
        --@ `0` = write (Host to DEPP)
        DEPP_WriteEnable : in std_logic;
        --@ Handshake signal  
        --@ 
        --@ `0` = ready for new cycle;
        --@ `1` = closing current cycle and not ready for new cycle
        --@ 
        --@ Keep the signal low to delay the cycle length
        DEPP_Wait : out std_logic := '1';
        --@ Data/Adress bus;
        --@ Tri-state
        DEPP_Bus : inout std_logic_vector(7 downto 0) := (others => 'Z');
        --@ @end
        --@ @virtualbus FIFO-Data-Out @dir out Data & Address Output. FIFO compatible interface
        --@ Data output corosponding to the address
        DataOutFifo_Data : out std_logic_vector(7 downto 0);
        --@ Address output
        DataOutFifo_Address : out std_logic_vector(7 downto 0);
        --@ Valid data & adress output if `1`. Is only 1 cycle valid
        DataOutFifo_WriteEnable : out std_logic;
        --@ If `1` the module delays the bus
        --@ and dont rise the `WriteEnable` signal
        DataOutFifo_FullFlag : in std_logic;
        --@ @end
        --@ @virtualbus FIFO-Data-In Data input. FIFO compatible interface
        --@ Data input
        DataInFifo_Data : in std_logic_vector(7 downto 0);
        --@ If the fifo is not empty, the module will read the data
        DataInFifo_EmptyFlag : in std_logic;
        --@ Is one cycle `1` to indicate that the data is read
        DataInFifo_ReadEnable : out std_logic;
        --@ @end
        --@ @virtualbus FIFO-Address-Out @dir out Request address output. FIFO compatible interface
        --@ Address output for read requests
        AddressOutFifo_Data : out std_logic_vector(7 downto 0);
        --@ Valid address output if `1`. Is only 1 cycle valid
        AddressOutFifo_WriteEnable : out std_logic;
        --@ If `1` the module delays the bus
        --@ and dont rise the `RequestEnable` signal
        AddressOutFifo_FullFlag : in std_logic
        --@ @end
    );
end DEPP;

architecture Behavioral of DEPP is

    --@ Catch the address as long as the mode (read/write) has not yet been decided.
    signal TempAddressRegister : std_logic_vector(7 downto 0) := (others => '0');

    --@ Shift register for the rising/falling edge detection of the `DEPP_AddressEnable` signal
    signal EPP_AddressEnableShiftRegister : std_logic_vector(1 downto 0) := (others => '0');
    --@ Shift register for the rising/falling edge detection of the `DEPP_DataEnable` signal
    signal EPP_DataEnableShiftRegister : std_logic_vector(1 downto 0) := (others => '0');

    --@ The states of the main state machine
    type ModeType is (Idle, RequestActive, SetData, WriteActive, WaitForFallingDataEnable, WaitingForFallingAddressEnable, AdressActive);
    --@ The current state of the main state machine
    signal Mode : ModeType := Idle;

    --@ The output signals for the output data fifo; also controls the address fifo.
    signal InterWriteEnableOut : std_logic := '0';
    --@ The output signals for the output address fifo
    signal InterRequestEnable : std_logic := '0';
    --@ Intermediary signal to start the address write cycle
    signal InterAddressEnable : std_logic := '0';
    --@ Negated `DataInFifo_EmptyFlag` signal
    signal DataInFifo_DataAviable : std_logic;
begin

    DataInFifo_DataAviable     <= not DataInFifo_EmptyFlag;
    DataOutFifo_WriteEnable    <= InterWriteEnableOut;
    AddressOutFifo_WriteEnable <= InterRequestEnable or InterWriteEnableOut;

    --@ Shifts the value from the `DEPP_AddressEnable` signal into the `EPP_AddressEnableShiftRegister`
    --@ for the rising/falling edge detection.
    EPP_AddressEnableCatch : process (CLK)
    begin
        if rising_edge(CLK) then
            if RST = '1' then
                EPP_AddressEnableShiftRegister <= (others => '0');
            elsif CE = '1' then
                EPP_AddressEnableShiftRegister <= EPP_AddressEnableShiftRegister(0) & DEPP_AddressEnable;
            end if;
        end if;
    end process;

    --@ Shifts the value from the `DEPP_DataEnable` signal into the `EPP_DataEnableShiftRegister`.
    --@ for the rising/falling edge detection.
    EPP_DataEnableCatch : process (CLK)
    begin
        if rising_edge(CLK) then
            if RST = '1' then
                EPP_DataEnableShiftRegister <= (others => '0');
            elsif CE = '1' then
                EPP_DataEnableShiftRegister <= EPP_DataEnableShiftRegister(0) & DEPP_DataEnable;
            end if;
        end if;
    end process;

    --@ Redirection of the `DataInFifo_EmptyFlag` signal to the `DataInFifo_ReadEnable` signal
    --@ if in the `RequestActive` mode: Minimize the latency of the data read.
    DataInFIFOMinimizeLatency : process (Mode, DataInFifo_DataAviable)
    begin
        if Mode = RequestActive then
            DataInFifo_ReadEnable <= DataInFifo_DataAviable;
        else
            DataInFifo_ReadEnable <= '0';
        end if;
    end process;

    EPP_WaitManagement : process (CLK)
    begin
        if rising_edge(CLK) then
            if RST = '1' then
                DEPP_Wait <= '1';
                DEPP_Bus  <= (others => 'Z');
                Mode      <= Idle;
            elsif CE = '1' then
                case Mode is
                    when Idle =>
                        --@ In idle state the module waits for the beginning of a new cycle
                        --@ like write address, write data or read data.
                        --@ A new cycle is signaled via the signals `InterRequestEnable`,
                        --@ `InterWriteEnableOut` and `InterAddressEnable` provided by the
                        --@ `EPP_AddressCatch`, `EPP_ReciveData` and `EPP_ReciveRequest` processes.

                        DEPP_Bus <= (others => 'Z');
                        --@ If the data or address output fifo is full the module signals the host to wait.
                        DEPP_Wait <= DataOutFifo_FullFlag or AddressOutFifo_FullFlag;

                        if InterRequestEnable = '1' then
                            --@ Start the read cycle
                            Mode      <= RequestActive;
                            DEPP_Wait <= '0';
                        elsif InterWriteEnableOut = '1' then
                            --@ Start the write cycle
                            Mode <= WaitForFallingDataEnable;
                        elsif InterAddressEnable = '1' then
                            --@ Start the address write cycle
                            Mode <= WaitingForFallingAddressEnable;
                        end if;
                    when AdressActive =>
                        --@ Intermediary state to hold the `DEPP_Wait` minimum one cycle high.
                        Mode <= WaitingForFallingAddressEnable;
                    when WriteActive =>
                        --@ Intermediary state to hold the `DEPP_Wait` minimum one cycle high.
                        Mode <= WaitForFallingDataEnable;
                    when RequestActive =>
                        DEPP_Wait <= '0';
                        if DataInFifo_DataAviable = '1' then
                            Mode <= SetData;
                        end if;
                    when SetData =>
                        DEPP_Bus <= DataInFifo_Data;
                        Mode     <= WaitForFallingDataEnable;
                    when WaitForFallingDataEnable =>
                        DEPP_Wait <= '1';
                        if EPP_DataEnableShiftRegister = "01" then
                            Mode <= Idle;
                        elsif (EPP_DataEnableShiftRegister = "11") and (EPP_AddressEnableShiftRegister = "11") then
                            Mode <= Idle;
                        end if;
                    when WaitingForFallingAddressEnable =>
                        DEPP_Wait <= '1';
                        if EPP_AddressEnableShiftRegister = "01" then
                            Mode <= Idle;
                        elsif (EPP_DataEnableShiftRegister = "11") and (EPP_AddressEnableShiftRegister = "11") then
                            Mode <= Idle;
                        end if;
                    when others =>
                        DEPP_Wait <= '1';
                        DEPP_Bus  <= (others => 'Z');
                        Mode      <= Idle;
                end case;
            end if;
        end if;
    end process;

    --@ Address write cycle:
    --@ If the `DEPP_AddressEnable` signal rises, 
    --@ he `DEPP_WriteEnable` signal is low and the module is in idle state
    --@ the `DEPP_Bus` is stored in the `TempAddressRegister`.
    EPP_AddressCatch : process (CLK)
    begin
        if rising_edge(CLK) then
            if RST = '1' then
                TempAddressRegister <= (others => '0');
                InterAddressEnable  <= '0';
            elsif CE = '1' then
                -- Self reset the `InterAddressEnableRst` signal after one cycle high.
                if InterAddressEnable = '1' then
                    InterAddressEnable <= '0';
                end if;

                if (EPP_AddressEnableShiftRegister = "10") and (DEPP_WriteEnable = '0') and (Mode = Idle) then
                    TempAddressRegister <= DEPP_Bus;
                    InterAddressEnable  <= '1';
                end if;
            end if;
        end if;
    end process;

    --@ Data write cycle:
    --@ If the `DEPP_DataEnable` signal rises,
    --@ the `DEPP_WriteEnable` signal is low
    --@ and the module is in idle state
    --@ the `DEPP_Bus` is stored in the `DataOut`,
    --@ the `TempAddressRegister` is stored in the `AddressOut`
    --@ and the `WriteEnableOut` signal is set to `1`.
    EPP_ReciveData : process (CLK)
    begin
        if rising_edge(CLK) then
            if RST = '1' then
                DataOutFifo_Address <= (others => '0');
                DataOutFifo_Data    <= (others => '0');
                InterWriteEnableOut <= '0';
            elsif CE = '1' then
                -- Self reset the `WriteEnableOut` signal after one cycle high.
                if InterWriteEnableOut = '1' then
                    InterWriteEnableOut <= '0';
                end if;

                if (EPP_DataEnableShiftRegister = "10") and (DEPP_WriteEnable = '0') and (Mode = Idle) then
                    DataOutFifo_Address <= TempAddressRegister;
                    DataOutFifo_Data    <= DEPP_Bus;
                    InterWriteEnableOut <= '1';
                end if;
            end if;
        end if;
    end process;

    --@ Data read cycle:
    --@ If the `DEPP_DataEnable` signal rises,
    --@ the `DEPP_WriteEnable` signal is high (read)
    --@ and the module is in idle state
    --@ the `TempAddressRegister` is stored in the `RequestAddress`
    --@ and the `RequestEnable` signal is set to `1`.
    EPP_ReciveRequest : process (CLK)
    begin
        if rising_edge(CLK) then
            if RST = '1' then
                AddressOutFifo_Data <= (others => '0');
                InterRequestEnable  <= '0';
            elsif CE = '1' then
                -- Self reset the `RequestEnable` signal after one cycle high.
                if InterRequestEnable = '1' then
                    InterRequestEnable <= '0';
                end if;

                if (EPP_DataEnableShiftRegister = "10") and (DEPP_WriteEnable = '1') and (Mode = Idle) then
                    AddressOutFifo_Data <= TempAddressRegister;
                    InterRequestEnable  <= '1';
                end if;
            end if;
        end if;
    end process;
end Behavioral;