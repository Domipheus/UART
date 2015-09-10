--------------------------------------------------------------------------------
-- Test of Simple UART Receive.
-- Transmits "HELLO\nGG", "GG" being streamed without deactivating I_txSig.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
ENTITY uart_simple_rx_tb IS
END uart_simple_rx_tb;
 
ARCHITECTURE behavior OF uart_simple_rx_tb IS 
 
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
         I_rx : IN  std_logic;
         I_rxCont : IN  std_logic;
         O_rxData : OUT  std_logic_vector(7 downto 0);
         O_rxSig : OUT  std_logic;
         O_rxFrameError : out STD_LOGIC
         
         -- ; -- debug internals
         --D_rxClk : out STD_LOGIC;
         --D_rxState: out integer;
         --D_txClk : out STD_LOGIC;
         --D_txState: out integer
           
        );
    END COMPONENT;
    
   -- DBG Internals
   --signal D_rxClk : STD_LOGIC;
   --signal D_rxState: integer;
   --signal D_txClk : STD_LOGIC;
   --signal D_txState: integer;

   --Inputs
   signal I_clk : std_logic := '0';
   signal I_reset : std_logic := '0';
   signal I_txData : std_logic_vector(7 downto 0) := (others => '0');
   signal I_txSig : std_logic := '0';
   signal I_rx : std_logic := '1';
   signal I_rxCont : std_logic := '0';

   --Outputs
   signal O_txRdy : std_logic;
   signal O_tx : std_logic;
   signal O_rxData : std_logic_vector(7 downto 0) := X"00";
   signal O_rxSig : std_logic;
   signal O_rxFrameError : std_logic;

   -- Clock period definitions
   constant I_clk_period : time := 20 ns;
   constant I_baud_clk_pediod : time := 8680 ns ;--104167 ns; -- 115.2K or 9.6K
   signal I_baud_clk : std_logic := '0';
   
   signal s_data : std_logic_vector(80 downto 0) 
      := "000010010101010001010001100101000110010101111001010101100001000010010010101000101";
   signal s_data_pos : integer := 80;
   signal s_data_oversample: integer:= 8;
   signal s_data_begin : std_logic:= '0';
BEGIN
 
   -- Instantiate the Unit Under Test (UUT)
   uut: uart_simple PORT MAP (
          I_clk => I_clk,
          I_clk_baud_count => X"01b2",--X"1458", -- 115.2K or 9.6K
          I_reset => I_reset,
          I_txData => I_txData,
          I_txSig => I_txSig,
          O_txRdy => O_txRdy,
          O_tx => O_tx,
          I_rx => I_rx,
          I_rxCont => I_rxCont,
          O_rxData => O_rxData,
          O_rxSig => O_rxSig,
          
          O_rxFrameError => O_rxFrameError
           
          --D_rxClk => D_rxClk,
          --D_rxState => D_rxState,
          --D_txClk => D_txClk,
          --D_txState => D_txState
        );

   -- Clock process definitions
   I_clk_process :process
   begin
      I_clk <= '0';
      wait for I_clk_period/2;
      I_clk <= '1';
      wait for I_clk_period/2;
   end process;
   
      -- Clock process definitions
   I_baud_clk_process :process
   begin
      I_baud_clk <= '0';
      wait for I_baud_clk_pediod/2;
      I_baud_clk <= '1';
      wait for I_baud_clk_pediod/2;
   end process;
 
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      I_reset <='1';
      wait for 100 ns;	
      I_reset <='0';

      wait for I_clk_period*10;
      
      I_rxCont <= '1';
      s_data_begin <= '1';
      -- insert stimulus here 

      wait;
   end process;
   
   data_sender: process (I_baud_clk )
   begin
      if rising_edge(I_baud_clk ) and s_data_begin = '1' and s_data_pos >= 0 then
         I_rx <= s_data(s_data_pos);
         s_data_pos <= s_data_pos - 1;
      end if;
   end process;

END;
