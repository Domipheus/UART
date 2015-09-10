# UART
Simple UART implementation in VHDL

# Description

Very simple, non-buffered implementation of 8 data bits, 0 parity, 1 stop bit serial communications channel. Should be able to work at any baud (with a degree of error) by setting I_clk_baud_count respectively:

    For a 50MHz I_clk:
            I_clk_baud_count := X"1458" -- 9600bps
            I_clk_baud_count := X"01B2" -- 115200bps

    To generate other timings, perform calculation:
          <I_clk in Hz> / <expected baud> =  I_clk_baud_count
              50000000  /  9600           =  5208       (0x1458)
 
#Inputs/Outputs:

    SYS:
    I_clk            - system clock - at least 16x baud rate for recieve
                       but can be less if only using TX.
    I_clk_baud_count - the number of cycles of I_clk between baud ticks
                       used to set a known transmit/recieve baud rate.
    I_reset          - reset line. ideally, reset whilst changing baud.

    TX:
    I_txData   - data to transmit.
    I_txSig    - signal to transmit (deassert when txReady low) or
                 change I_txData to stream out.
    O_txRdy    - '1' when idle, '0' when transmitting.
    O_tx       - actual serial output.

    RX:
    I_rx           - actual serial input.
    I_rxCont       - receive enable/continue.
    O_rxData       - data received.
    O_rxSig        - data available signal - does not deassert until new
                     frame starts being received.
    O_rxFrameError - Stop bit invalid/frame error. Deasserts on next receive,
                     but the data received may still be invalid.

#Debug Ports

There are outputs set up to expose internal state information when debugging or simulating issues. They could also be used to sync other parts of a top level design. These ports are prefixed 'D_'.