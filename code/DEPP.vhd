----------------------------------------------------------------------------------
-- @name        Digilent EPP Interface
-- @version     0.3.0
-- @author      Maximilian Passarello (mpassarello.de)
--@             An EPP interface for Digilent FPGA boards
--@             This interface is designed to be used with the Digilent EPP interface
--@             and the Digilent Adept software.
-- @history
-- - 0.2.0 (2010.05.30) Initial version
-- - 0.3.0 (2024.03.06) Refactored and commented
----------------------------------------------------------------------------------
-- Timing Diagram's
-- EPP Address Write
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
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity DEPP is
    generic (
        --@ Number of 8-bit registers
        --@ `DOut` and `DIn` are 8 times this width
        RegisterQuant : integer := 1
    );
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
        --@ @virtualbus EPP-Interface EPP Interface 
        --@ Address strobe 
        DEPP_AddressEnable : in std_logic;
        --@ Data strobe
        DEPP_DataEnable : in std_logic;
        --@ Transfer direction control
        --@ `1` = read (Host from DEPP), `0` = write (Host to DEPP)
        DEPP_WriteEnable : in std_logic;
        --@ Handshake signal
        --@ : `0` = ready for new cycle, `1` = closing current cycle; Keep the signal low to delay the cycle length
        DEPP_Wait : out std_logic;
        --@ Data/Adress bus
        DEPP_Bus : inout std_logic_vector(7 downto 0) := (others => 'Z');
        --@ @end
        --@ Data output
        DOut : out std_logic_vector((RegisterQuant * 8) - 1 downto 0);
        --@ Data input
        DIn : in std_logic_vector((RegisterQuant * 8) - 1 downto 0));
end DEPP;

architecture Behavioral of DEPP is

    --@ Function to calculate the number of bits needed to address the `N` registers
    function min_bits_for_states(N : integer) return integer is
    begin
        if (N <= 2) then
            return 1;
        else
            if (N mod 2 = 0) then
                return 1 + min_bits_for_states(N/2);
            else
                return 1 + min_bits_for_states((N + 1)/2);
            end if;
        end if;
    end function min_bits_for_states;

    type RegisterType is array(RegisterQuant - 1 downto 0)
    of std_logic_vector(7 downto 0);

    signal RegistersIn  : RegisterType;
    signal RegistersOut : RegisterType;

    signal EPPDInternal : std_logic_vector(7 downto 0);
    signal Adress       : std_logic_vector(min_bits_for_states(RegisterQuant) - 1 downto 0);

    signal Intern_CE  : std_logic := '1';
    signal Intern_RST : std_logic := '0';
begin

    DEPP_Wait <= '1' when DEPP_DataEnable = '0' or DEPP_AddressEnable = '0' else
        '0';

    DEPP_Bus <= EPPDInternal when (DEPP_WriteEnable = '1') else
        "ZZZZZZZZ";

    DEPP_AddrIn : process (DEPP_AddressEnable)
    begin
        if rising_edge(DEPP_AddressEnable) then
            if DEPP_WriteEnable = '0' then
                Adress <= DEPP_Bus(min_bits_for_states(RegisterQuant) - 1 downto 0);
            end if;
        end if;
    end process;

    DEPP_DIn : process (DEPP_DataEnable)
    begin
        if rising_edge(DEPP_DataEnable) then
            if DEPP_WriteEnable = '0' then
                RegistersOut(to_integer(unsigned(Adress))) <= DEPP_Bus;
            end if;
        end if;
    end process;
    EPPDInternal <= RegistersIn(to_integer(unsigned(Adress)));

    DOutRegister : process (CLK)
    begin
        if rising_edge(CLK) then
            if Intern_RST = '1' then
                DOut <= (others => '0');
            elsif Intern_CE = '1' then
                for i in 0 to RegisterQuant - 1 loop
                    DOut(((i + 1) * 8) - 1 downto ((i) * 8)) <= RegistersOut(i);
                end loop;
            end if;
        end if;
    end process;

    DInRegister : process (CLK)
    begin
        if rising_edge(CLK) then
            if Intern_RST = '1' then
                null;
            elsif Intern_CE = '1' then
                for i in 0 to RegisterQuant - 1 loop
                    RegistersIn(i) <= DIn(((i + 1) * 8) - 1 downto ((i) * 8));
                end loop;
            end if;
        end if;
    end process;
end Behavioral;