--------------------------------------------------------------------------------
-- Test of Simple UART Transmit.
-- Transmits "HELLO\nGG", "GG" being streamed without deactivating I_txSig.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
 
ENTITY uast_simple_tx_tb IS
END uast_simple_tx_tb;
 
ARCHITECTURE behavior OF uart_simple_tx_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT uart_simple
    PORT(
        I_clk : IN  std_logic;
        I_clk_baud_count : in STD_LOGIC_VECTOR (15 downto 0);
        I_reset : IN  std_logic;
        I_txData : IN  std_logic_vector(7 downto 0);
        I_txSig : IN  std_logic;
        O_txRdy : OUT  std_logic;
        O_tx : OUT  std_logic;
        I_rx : in STD_LOGIC;
        I_rxCont: in STD_LOGIC;
        O_rxData : out STD_LOGIC_VECTOR (7 downto 0);
        O_rxSig : out STD_LOGIC;
        O_rxFrameError : out STD_LOGIC
        );
    END COMPONENT;
    

   --Inputs
   signal I_clk : std_logic := '0';
   signal I_reset : std_logic := '0';
   signal I_txData : std_logic_vector(7 downto 0) := (others => '0');
   signal I_txSig : std_logic := '0';

  --Outputs
   signal O_txRdy : std_logic;
   signal O_tx : std_logic;
   signal O_rxFrameError : std_logic;

   -- Clock period definitions
   constant I_clk_period : time := 20 ns;
 
BEGIN
 
  -- Instantiate the Unit Under Test (UUT)
    uut: uart_simple PORT MAP (
        I_clk => I_clk,
        I_clk_baud_count => X"1458", -- 9600bps @ 50MHz I_clk
        I_reset => I_reset,
        I_txData => I_txData,
        I_txSig => I_txSig,
        O_txRdy => O_txRdy,
        O_tx => O_tx,
        I_rx => '0',
        I_rxCont => '0',
        O_rxFrameError => O_rxFrameError
    );

    -- Clock process definitions
    I_clk_process :process
    begin
        I_clk <= '0';
        wait for I_clk_period/2;
        I_clk <= '1';
        wait for I_clk_period/2;
    end process;
  

    -- Stimulus process
    stim_proc: process
    begin		
        -- hold reset state for 100 ns.
        I_reset <='1';
        wait for 100 ns;	
        I_reset <='0';

        wait for I_clk_period*10;

        -- send hello\n - 0x48, 0x45, 0x4c, 0x4c, 0x4f, 0x0d
        -- H
        I_txData <= X"48";
        I_txSig <= '1';
        wait until O_txRdy= '0';
        I_txSig <= '0';

        -- E
        wait until O_txRdy= '1';
        I_txData <= X"45";
        I_txSig <= '1';
        wait until O_txRdy= '0';
        I_txSig <= '0';

        -- L
        wait until O_txRdy= '1';
        I_txData <= X"4c";
        I_txSig <= '1';
        wait until O_txRdy= '0';
        I_txSig <= '0';

        -- L
        wait until O_txRdy= '1';
        I_txData <= X"4c";
        I_txSig <= '1';
        wait until O_txRdy= '0';
        I_txSig <= '0'; 

        -- O
        wait until O_txRdy= '1';
        I_txData <= X"4f";
        I_txSig <= '1';
        wait until O_txRdy= '0';
        I_txSig <= '0'; 

        -- \n
        wait until O_txRdy= '1';
        I_txData <= X"0d";
        I_txSig <= '1';
        wait until O_txRdy= '0';
        I_txSig <= '0';


        -- G, streamed
        wait until O_txRdy= '1';
        I_txData <= X"47";
        I_txSig <= '1';
        wait until O_txRdy= '0';
        I_txData <= X"47";
        I_txSig <= '1';
        wait until O_txRdy= '0';
        I_txSig <= '0'; 

        wait until O_txRdy= '1';


        -- insert stimulus here 

        wait;
    end process;

END;
