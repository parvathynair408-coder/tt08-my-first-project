# SPI Master Controller ASIC

## How it works
This SPI Master Controller converts byte-wide parallel input data into a serial bitstream over MOSI while generating the corresponding SPI clock (SCLK) and active-low chip select (CS_N). Incoming serial data from MISO is sampled and latched into lower output lines.

## How to test
1. Set rst_n to 0 to reset the internal state machine, then release to 1.
2. Provide an 8-bit parallel byte on ui_in[7:0].
3. Monitor uo_out[0] (SCLK) and uo_out[1] (MOSI) to observe serial transmission.
