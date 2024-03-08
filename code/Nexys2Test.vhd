library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity Nexys2Test is
    port (
        CLK             : in std_logic;
        RST             : in std_logic;
        LED             : out std_logic_vector(7 downto 0);
        Switches        : in std_logic_vector(7 downto 0);
        DataOutFullFlag : in std_logic;
        RequestFullFlag : in std_logic;
        -- Logic Analyzer
        LA_AddressEnable : out std_logic;
        LA_DataEnable    : out std_logic;
        LA_WriteEnable   : out std_logic;
        LA_Wait          : out std_logic;
        LA_Bus           : inout std_logic_vector(7 downto 0);
        -- EPP Interface
        DEPP_AddressEnable : in std_logic;
        DEPP_DataEnable    : in std_logic;
        DEPP_WriteEnable   : in std_logic;
        DEPP_Wait          : out std_logic;
        DEPP_Bus           : inout std_logic_vector(7 downto 0) := (others => 'Z')
    );
end Nexys2Test;

architecture Behavioral of Nexys2Test is

    component DEPP
        port (
            CLK                        : in std_logic;
            CE                         : in std_logic;
            RST                        : in std_logic;
            DEPP_AddressEnable         : in std_logic;
            DEPP_DataEnable            : in std_logic;
            DEPP_WriteEnable           : in std_logic;
            DEPP_Wait                  : out std_logic;
            DEPP_Bus                   : inout std_logic_vector(7 downto 0);
            DataOutFifo_Data           : out std_logic_vector(7 downto 0);
            DataOutFifo_Address        : out std_logic_vector(7 downto 0);
            DataOutFifo_WriteEnable    : out std_logic;
            DataOutFifo_FullFlag       : in std_logic;
            DataInFifo_Data            : in std_logic_vector(7 downto 0);
            DataInFifo_EmptyFlag       : in std_logic;
            DataInFifo_ReadEnable      : out std_logic;
            AddressOutFifo_Data        : out std_logic_vector(7 downto 0);
            AddressOutFifo_WriteEnable : out std_logic;
            AddressOutFifo_FullFlag    : in std_logic
        );
    end component;

    signal InterLED      : std_logic_vector(7 downto 0);
    signal InterSwitches : std_logic_vector(7 downto 0);
    signal DataAviable   : std_logic;
    signal InternWait    : std_logic;
    signal InternRST     : std_logic;

    signal EPP_Bus : std_logic_vector(7 downto 0);
begin

    DEPP_inst : DEPP
    port map(
        CLK                        => CLK,
        CE                         => '1',
        RST                        => InternRST,
        DEPP_AddressEnable         => DEPP_AddressEnable,
        DEPP_DataEnable            => DEPP_DataEnable,
        DEPP_WriteEnable           => DEPP_WriteEnable,
        DEPP_Wait                  => InternWait,
        DEPP_Bus                   => EPP_Bus,
        DataOutFifo_Data           => InterLED,
        DataOutFifo_Address        => open,
        DataOutFifo_WriteEnable    => DataAviable,
        DataOutFifo_FullFlag       => DataOutFullFlag,
        DataInFifo_Data            => InterSwitches,
        DataInFifo_EmptyFlag       => '0',
        DataInFifo_ReadEnable      => open,
        AddressOutFifo_Data        => open,
        AddressOutFifo_WriteEnable => open,
        AddressOutFifo_FullFlag    => RequestFullFlag
    );

    DEPP_Wait        <= InternWait;
    DEPP_Bus         <= EPP_Bus;
    LA_Bus           <= EPP_Bus;
    LA_AddressEnable <= DEPP_AddressEnable;
    LA_DataEnable    <= DEPP_DataEnable;
    LA_WriteEnable   <= DEPP_WriteEnable;
    LA_Wait          <= InternWait;

    process (CLK)
    begin
        if rising_edge(CLK) then
            LED       <= InterLED;
            InternRST <= RST;

            InterSwitches <= Switches;
        end if;
    end process;
end Behavioral;
