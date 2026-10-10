# Architecture and Understanding of `spi_slave.v`

`spi_slave.v` is the bridge between the external microcontroller (the "Host", like an RP2040) and the four internal soft-cores. Because the Tiny Tapeout ASIC has a very limited number of pins, it's impossible to expose a full parallel data/address bus to program the CPUs. Instead, the design multiplexes all configuration and data streaming through a standard 4-wire SPI bus.

It operates as an SPI Mode 0 slave (shifts in on the rising edge of `sclk`, shifts out on the falling edge). 

## Transaction Structure
When `spi_cs` (Chip Select) goes low, the very first byte it receives is interpreted as a **Command Byte**. All subsequent bytes sent while `spi_cs` remains low are treated as a continuous payload for that command.

The SPI Slave doesn't actually need to know in advance how much data is being sent. It relies entirely on the `spi_cs` pin. As long as `spi_cs` remains LOW, the state machine will endlessly accept bits, grouping them into 8-bit bytes, and firing the appropriate write/read strobes.

When the host has finished sending the "last data," it simply raises the `spi_cs` pin HIGH. This immediately aborts the current transaction, resets the internal bit counter, and prepares the SPI Slave to expect a brand new Command Byte the next time the chip select goes low.

## Commands Supported

### 1. Programming the Split-Stream Instruction RAMs
Due to the new 1-cycle pipeline architecture, each CPU has its instruction memory split into four separate parallel streams:
- `OP` (Opcode stream, 128 nibbles)
- `OP1` (First Operand stream, 64 nibbles)
- `OP2` (Second Operand stream, 8 nibbles)
- `JMP` (Jump Table, 16 entries of 15 bits)

The SPI Slave supports distinct commands for each stream and CPU:
- **CPU 0:** `0x00` (OP), `0x10` (OP1), `0x20` (OP2), `0x30` (JMP)
- **CPU 1:** `0x01` (OP), `0x11` (OP1), `0x21` (OP2), `0x31` (JMP)
- **CPU 2:** `0x08` (OP), `0x18` (OP1), `0x28` (OP2), `0x38` (JMP)
- **CPU 3:** `0x09` (OP), `0x19` (OP1), `0x29` (OP2), `0x39` (JMP)

For `OP`, `OP1`, and `OP2`, the SPI slave isolates the lower 4 bits of each received byte and writes it to the RAM.
For `JMP`, each jump target is 15 bits wide, so the SPI slave groups every two bytes received into a 15-bit address and writes it to the jump table.
All streams automatically auto-increment their respective internal address pointers with each write, allowing the host to quickly flash the firmware.

### 2. Streaming Data to RX FIFOs (Commands: `0x02`, `0x03`, `0x0A`, `0x0B`)
If a CPU is emulating a protocol that transmits data (like a UART transmitter), the host can supply that data by sending a write command (e.g., `0x02` for CPU 0). The SPI slave collects 8-bit bytes from the `spi_mosi` pin and pushes them directly into the CPU's `RX_FIFO` by asserting the `rx_fifo_we` strobe.

### 3. Reading Data from TX FIFOs (Commands: `0x04`, `0x05`, `0x0C`, `0x0D`)
Conversely, if a CPU is emulating a protocol that receives data from the outside world (like a UART receiver), it pushes that data into its `TX_FIFO`. The external host can read this data out by sending a read command (e.g., `0x04` for CPU 0). The SPI slave will pop an 8-bit byte from the FIFO using the `tx_fifo_re` strobe and shift it out bit-by-bit onto the `spi_miso` pin for the host to consume.

Essentially, `spi_slave.v` is the "DMA Controller" that lets the outside world seamlessly flash programs and stream data into and out of the multi-core emulator!
