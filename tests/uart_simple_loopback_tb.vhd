--------------------------------------------------------------------------------
-- Test of Simple UART loopback.
-- Transmits "HELLO\nGG" twice, once at 115,200bps and then at 9600bps.
-- The bps switch happens before the second G is transmitted, but you see it the
-- second time.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
 
ENTITY uart_simple_loopback_tb IS
END uart_simple_loopback_tb;
 
ARCHITECTURE behavior OF uart_simple_loopback_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT uart_simple
    PORT(
         I_clk : IN  std_logic;
         I_clk_baud_count : IN  std_logic_vector(15 downto 0);
         I_reset : IN  std_logic;
         I_txData : IN  std_logic_vector(7 downto 0);
         I_txSig : IN  std_logic;
         O_txRdy : OUT  std_logic;
         O_tx : OUT  std_logic;
         I_rx : IN  std_logic;
         I_rxCont : IN  std_logic;
         O_rxData : OUT  std_logic_vector(7 downto 0);
         O_rxSig : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal I_clk : std_logic := '0';
   signal I_clk_baud_count : std_logic_vector(15 downto 0) := (others => '0');
   signal I_reset : std_logic := '0';
   signal I_txData : std_logic_vector(7 downto 0) := (others => '0');
   signal I_txSig : std_logic := '0';
   signal I_rx : std_logic := '0';
   signal I_rxCont : std_logic := '0';

 	--Outputs
   signal O_txRdy : std_logic;
   signal O_tx : std_logic;
   signal O_rxData : std_logic_vector(7 downto 0);
   signal O_rxSig : std_logic;

   -- Clock period definitions
   constant I_clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: uart_simple PORT MAP (
          I_clk => I_clk,
          I_clk_baud_count => I_clk_baud_count,
          I_reset => I_reset,
          I_txData => I_txData,
          I_txSig => I_txSig,
          O_txRdy => O_txRdy,
          O_tx => O_tx,
          I_rx => I_rx,
          I_rxCont => I_rxCont,
          O_rxData => O_rxData,
          O_rxSig => O_rxSig
        );
		
   I_rx <= O_tx;

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
		I_reset <= '1';
		I_clk_baud_count <= X"01b2"; -- 115200bps @ 50MHz clock
		
		I_rxCont <= '1';
		
		wait for 100 ns;	
		
		I_reset <= '0';
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
		
		
		-- G
		wait until O_txRdy= '1';
		I_txData <= X"47";
		I_txSig <= '1';
		wait until O_txRdy= '0';
		I_txSig <= '0'; 
		-- G
		wait until O_txRdy= '1';
		I_txData <= X"47";
		I_txSig <= '1';
		wait until O_txRdy= '0';
		I_txSig <= '0'; 
		
		wait until O_txRdy= '1';
		

		-- hold reset state for 100 ns.
		I_reset <= '1';
		I_clk_baud_count <= X"1458"; -- 9600bps @ 50MHz clock
		
		I_rxCont <= '1';
		
		wait for 100 ns;	

		I_reset <= '0';
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
		
		
		-- G
		wait until O_txRdy= '1';
		I_txData <= X"47";
		I_txSig <= '1';
		wait until O_txRdy= '0';
		I_txSig <= '0'; 
		-- G
		wait until O_txRdy= '1';
		I_txData <= X"47";
		I_txSig <= '1';
		wait until O_txRdy= '0';
		I_txSig <= '0'; 
		
		wait until O_txRdy= '1';
		

		wait;
	end process;

END;
