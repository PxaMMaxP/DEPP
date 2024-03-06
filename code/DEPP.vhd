----------------------------------------------------------------------------------
-- @Name 	EPP
--	@Version	0.2
-- @Author	Maximilian Passarello
-- @E-Mail	atom-dragon@gmx.net
----------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY EPP IS
    GENERIC (RegisterQuant : INTEGER := 4);
    PORT (
        CLK : IN STD_LOGIC;
        CE : IN STD_LOGIC;
        RST : IN STD_LOGIC;
        EPPAddE : IN STD_LOGIC;
        EPPDataE : IN STD_LOGIC;
        EPPWE : IN STD_LOGIC;
        EPPD : INOUT STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => 'Z');
        EPPWait : OUT STD_LOGIC;
        Dout : OUT STD_LOGIC_VECTOR((RegisterQuant * 8) - 1 DOWNTO 0);
        Din : IN STD_LOGIC_VECTOR((RegisterQuant * 8) - 1 DOWNTO 0));
END EPP;

ARCHITECTURE Behavioral OF EPP IS

    FUNCTION log2_ceil(N : INTEGER) RETURN INTEGER IS
    BEGIN
        IF (N <= 2) THEN
            RETURN 1;
        ELSE
            IF (N MOD 2 = 0) THEN
                RETURN 1 + log2_ceil(N/2);
            ELSE
                RETURN 1 + log2_ceil((N + 1)/2);
            END IF;
        END IF;
    END FUNCTION log2_ceil;

    TYPE RegisterType IS ARRAY(RegisterQuant - 1 DOWNTO 0)
    OF STD_LOGIC_VECTOR(7 DOWNTO 0);

    SIGNAL RegistersIn : RegisterType;
    SIGNAL RegistersOut : RegisterType;

    SIGNAL EPPDInternal : STD_LOGIC_VECTOR(7 DOWNTO 0);
    SIGNAL Adress : STD_LOGIC_VECTOR(log2_ceil(RegisterQuant) - 1 DOWNTO 0);
BEGIN

    EPPWait <= '1' WHEN EPPDataE = '0' OR EPPAddE = '0' ELSE
        '0';

    EPPD <= EPPDInternal WHEN (EPPWE = '1') ELSE
        "ZZZZZZZZ";

    PROCESS (EPPAddE)
    BEGIN
        IF rising_edge(EPPAddE) THEN
            IF EPPWE = '0' THEN
                Adress <= EPPD(log2_ceil(RegisterQuant) - 1 DOWNTO 0);
            END IF;
        END IF;
    END PROCESS;

    --	process(EPPAddE)
    --	begin
    --		if falling_edge(EPPAddE) then
    --			if EPPWE = '1' then
    --				EPPDInternal(log2_ceil(RegisterQuant)-1 downto 0) <= Adress;
    --			end if;
    --		end if;
    --	end process;

    PROCESS (EPPDataE)
    BEGIN
        IF rising_edge(EPPDataE) THEN
            IF EPPWE = '0' THEN
                RegistersOut(to_integer(unsigned(Adress))) <= EPPD;
            END IF;
        END IF;
    END PROCESS;
    EPPDInternal <= RegistersIn(to_integer(unsigned(Adress)));

    PROCESS (CLK)
    BEGIN
        IF rising_edge(CLK) THEN
            IF RST = '1' THEN
                Dout <= (OTHERS => '0');
            ELSIF CE = '1' THEN
                FOR i IN 0 TO RegisterQuant - 1 LOOP
                    Dout(((i + 1) * 8) - 1 DOWNTO ((i) * 8)) <= RegistersOut(i);
                END LOOP;
            END IF;
        END IF;
    END PROCESS;

    PROCESS (CLK)
    BEGIN
        IF rising_edge(CLK) THEN
            IF RST = '1' THEN
                NULL;
            ELSIF CE = '1' THEN
                FOR i IN 0 TO RegisterQuant - 1 LOOP
                    RegistersIn(i) <= Din(((i + 1) * 8) - 1 DOWNTO ((i) * 8));
                END LOOP;
            END IF;
        END IF;
    END PROCESS;
END Behavioral;