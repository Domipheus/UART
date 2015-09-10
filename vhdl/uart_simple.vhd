----------------------------------------------------------------------------------
-- Project Name: Simple UART
--
-- Description: 
--
-- Very simple, non-buffered implementation of 8 data bits, 0 parity, 1 stop bit
-- serial communications channel. Should be able to work at any baud (with a 
-- degree of error) by setting I_clk_baud_count respectively:
--
--    For a 50MHz I_clk:
--            I_clk_baud_count := X"1458" -- 9600bps
--            I_clk_baud_count := X"01B2" -- 115200bps
--
--    To generate other timings, perform calculation:
--          <I_clk in Hz> / <expected baud> =  I_clk_baud_count
--              50000000  /  9600           =  5208       (0x1458)
-- 
-- Inputs/Outputs:
--
--   SYS:
--    I_clk            - system clock - at least 16x baud rate for recieve
--                       but can be less if only using TX.
--    I_clk_baud_count - the number of cycles of I_clk between baud ticks
--                       used to set a known transmit/recieve baud rate.
--    I_reset          - reset line. ideally, reset whilst changing baud.
--
--   TX:
--    I_txData   - data to transmit.
--    I_txSig    - signal to transmit (deassert when txReady low) or
--                 change I_txData to stream out.
--    O_txRdy    - '1' when idle, '0' when transmitting.
--    O_tx       - actual serial output.
--
--   RX:
--    I_rx           - actual serial input.
--    I_rxCont       - receive enable/continue.
--    O_rxData       - data received.
--    O_rxSig        - data available signal - does not deassert until new
--                     frame starts being received.
--    O_rxFrameError - Stop bit invalid/frame error. Deasserts on next receive,
--                     but the data received may still be invalid.
--
-- Debug Ports
--
-- There are outputs set up to expose internal state information when debugging
-- or simulating issues. They could also be used to sync other parts of a top 
-- level design. These ports are prefixed 'D_'.
-- 
-- Revision: 1
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

entity uart_simple is
	Port ( 
		I_clk : in  STD_LOGIC;
		I_clk_baud_count : in STD_LOGIC_VECTOR (15 downto 0);

		I_reset: in  STD_LOGIC;

		I_txData : in  STD_LOGIC_VECTOR (7 downto 0);
		I_txSig : in  STD_LOGIC;
		O_txRdy : out  STD_LOGIC;
		O_tx : out  STD_LOGIC;

		I_rx : in STD_LOGIC;
		I_rxCont: in STD_LOGIC;
		O_rxData : out STD_LOGIC_VECTOR (7 downto 0);
		O_rxSig : out STD_LOGIC;
		O_rxFrameError : out STD_LOGIC;

		-- Internal debug ports for inspecting issues
		-- These can be removed 
		D_rxClk : out STD_LOGIC;
		D_rxState: out integer;
		D_txClk : out STD_LOGIC;
		D_txState: out integer
	);
end uart_simple;

architecture Behavioral of uart_simple is
	signal tx_data : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	signal tx_state: integer := 0;
	signal tx_rdy : STD_LOGIC := '1';
	signal tx: STD_LOGIC := '1';
	
	signal rx_sample_count : integer := 0;
	signal rx_sample_offset : integer := 3;
	signal rx_state: integer := 0;
	signal rx_data : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
	signal rx_sig : STD_LOGIC := '0';
	signal rx_frameError : STD_LOGIC := '0';
	
	signal rx_clk_counter : integer := 0;
	signal rx_clk_reset : STD_LOGIC := '0';
	signal rx_clk_baud_tick: STD_LOGIC := '0';
	
	signal tx_clk_counter : integer := 0;
	signal tx_clk : STD_LOGIC := '0';
	
	constant OFFSET_START_BIT: integer := 7;
	constant OFFSET_DATA_BITS: integer := 15;
	constant OFFSET_STOP_BIT: integer := 7;
begin

	-- dbg signals
	D_rxClk <= rx_clk_baud_tick;
	D_rxState <= rx_state;
	D_txClk <= tx_clk;
	D_txState <= tx_state;
	-- dbg end

	clk_gen: process (I_clk)
	begin
		if rising_edge(I_clk) then
		
			-- RX baud 'ticks' generated for sampling, with reset
			if rx_clk_counter = 0 then
				-- x16 sampled - so chop off 4 LSB
				rx_clk_counter <= to_integer(unsigned(I_clk_baud_count(15 downto 4)));
				rx_clk_baud_tick <= '1';
			else
				if rx_clk_reset = '1' then
					rx_clk_counter <= to_integer(unsigned(I_clk_baud_count(15 downto 4)));
				else
					rx_clk_counter <= rx_clk_counter - 1;
				end if;
				rx_clk_baud_tick <= '0';
			end if;
			
			-- TX standard baud clock, no reset
			if tx_clk_counter = 0 then
				-- chop off LSB to get a clock
				tx_clk_counter <= to_integer(unsigned(I_clk_baud_count(15 downto 1)));
				tx_clk <= not tx_clk;
			else
				tx_clk_counter <= tx_clk_counter - 1;
			end if;
		end if;
	end process;
	
	O_rxFrameError <= rx_frameError;
	O_rxSig <= rx_sig;
	
	rx_proc: process (I_clk, I_reset, I_rx, I_rxCont)
	begin
		-- RX runs off the system clock, and operates on baud 'ticks'
		if rising_edge(I_clk) then
			if rx_clk_reset = '1' then
				rx_clk_reset <= '0';
			end if;
			if I_reset = '1' then
				rx_state <= 0;
				rx_sig <= '0';
				rx_sample_count <= 0;
				rx_sample_offset <= OFFSET_START_BIT;
				rx_data <= X"00";
				O_rxData <= X"00";
			elsif I_rx = '0' and rx_state = 0 and I_rxCont = '1' then
				-- first encounter of falling edge start
				rx_state <= 1; -- start bit sample stage
				rx_sample_offset <= OFFSET_START_BIT;
				rx_sample_count <= 0;
				
				-- need to reset the baud tick clock to line up with the start 
				-- bit leading edge.
				rx_clk_reset <= '1';
			elsif rx_clk_baud_tick = '1' and I_rx = '0' and rx_state = 1 then
				-- inc sample count
				rx_sample_count <= rx_sample_count + 1;
				if rx_sample_count = rx_sample_offset then
					-- start bit sampled, time to enable data
					
					rx_sig <= '0';
					rx_state <= 2;
					rx_data <= X"00";
					rx_sample_offset <= OFFSET_DATA_BITS; 
					rx_sample_count <= 0;
				end if;
			elsif rx_clk_baud_tick = '1' and rx_state >= 2  and rx_state < 10 then
				-- sampling data
				if rx_sample_count = rx_sample_offset then
					rx_data(6 downto 0) <= rx_data(7 downto 1);
					rx_data(7) <= I_rx;
					rx_sample_count <= 0;
					rx_state <= rx_state + 1;
				else
					rx_sample_count <= rx_sample_count + 1;
				end if;
			elsif rx_clk_baud_tick = '1' and rx_state = 10 then
				if rx_sample_count = OFFSET_STOP_BIT then
					rx_state <= 0;
					rx_sig <= '1';
					O_rxData <= rx_data; -- latch data out
					
					if I_rx = '1' then 
						-- stop bit correct
						rx_frameError <= '0';
					else
						-- stop bit is always high, if we don't see it, there 
						-- has been an issue. Signal an error.
						rx_frameError <= '1';
					end if;
				else
					rx_sample_count <= rx_sample_count + 1;
				end if;
			end if;
		end if;
	end process;


	O_tx <= tx;
	O_txRdy <= tx_rdy;
	
	tx_proc: process (tx_clk, I_reset, I_txSig, tx_state)
	begin
		-- TX runs off the TX baud clock
		if rising_edge(tx_clk) then
			if I_reset = '1' then
				tx_state <= 0;
				tx_data <= X"00";
				tx_rdy <= '1';
				tx <= '1';
			else
				if tx_state = 0 and I_txSig = '1' then
					tx_state <= 1;
					tx_data <= I_txData;
					tx_rdy <= '0';
					tx <= '0'; -- start bit
				elsif tx_state < 9 and tx_rdy = '0' then
					tx <= tx_data(0);
					tx_data <= '0' & tx_data (7 downto 1);
					tx_state <= tx_state + 1;
				elsif tx_state = 9 and tx_rdy = '0' then
					tx <= '1'; -- stop bit
					tx_rdy <= '1';
					tx_state <= 0;
				end if;
			end if;
		end if;
	end process;

end Behavioral;
