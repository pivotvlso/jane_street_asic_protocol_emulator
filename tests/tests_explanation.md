# UART TX Verification Tests

This folder contains standalone Verilog testbenches designed to exhaustively verify the UART Transmitter capabilities of the dual-core ASIC. Each testbench simulates the RP2040 Host communicating with the ASIC over SPI to load the `uart_tx.hex` binary and inject test stimulus.

### How to Run a Test
You can run any individual test by compiling it with the RTL filelist:
```bash
iverilog -o sim.out -c ../filelist/filelist.f <test_file.v>
vvp sim.out
```
This will generate a `.vcd` waveform file in the current directory, which can be viewed using GTKWave.

---

## Test 1.1: UART TX Basic (`test_1_1_uart_tx_basic.v`)
**Goal:** Verify standard 8N1 UART transmission of a single byte.
**Explanation:** 
This is the baseline sanity test. The testbench loads the CPU with the UART TX program and starts it. The CPU hits the bootloader block (`LOAD RX_FIFO`, `STORE R8`) and pauses, waiting for configuration. The testbench pushes `5` over SPI into the CPU's RX FIFO. The CPU wakes up, configures its baud delay to 5 clock cycles, and pauses again at the main loop. The testbench then pushes the ASCII character `'A'` (`0x41`). The CPU unpacks this byte, asserting the `START` bit, the 8 data bits (LSB first), and the `STOP` bit onto physical pin `uio_out[0]`.

## Test 1.2: UART TX Dynamic Baud (`test_1_2_uart_tx_dynamic_baud.v`)
**Goal:** Prove that the CPU dynamically adjusts its pulse width based on the Host's configuration byte.
**Explanation:** 
In rigid hardware UART modules, changing the baud rate requires altering complex division registers. In our software-defined ASIC, the baud rate is entirely controlled by the `TIMER_L` block. This test mimics Test 1.1, but pushes a massive baud delay of `100` into the RX FIFO during boot. It then pushes the test byte `0x5A` (`01011010`). When viewed in a waveform viewer, the pulse widths for each bit should be exactly 20x wider than the pulses in Test 1.1, verifying that the dynamic bootloader and hardware timer integration work flawlessly.

## Test 1.3: UART TX Streaming (`test_1_3_uart_tx_streaming.v`)
**Goal:** Verify back-to-back streaming without dropping bits or violating the STOP bit protocol.
**Explanation:** 
Serial protocols often fail during continuous streaming if the state machine's turnaround time is too slow (causing dropped bits) or too fast (truncating the required STOP bit). This testbench configures a fast baud rate of `5`, and then immediately blasts three consecutive bytes (`'B'`, `'U'`, `'G'`) into the ASIC's RX FIFO over SPI. Because SPI is much faster than UART, the FIFO will fill up. The CPU must pull from the FIFO, transmit the first byte, hold the STOP bit for exactly one full baud period, and then immediately drop into the START bit of the next byte. Inspecting the VCD will prove that the hardware FIFO and CPU FSM stay perfectly synchronized under heavy load.
