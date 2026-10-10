# Protocol Emulator Architecture

This diagram illustrates the final **Quad-Core Accumulator Architecture** mapped to the Tiny Tapeout constraints. 

To allow for full-duplex emulation across multiple protocols, the ASIC features **Four Independent Accumulator CPUs**. Each CPU is capable of addressing the shared bidirectional protocol pins. The external RP2040 uses an SPI bus to program and stream data to Core 0, 1, 2, or 3.

```text
                               +-----------------------------+
                               |     EXTERNAL RP2040 HOST    |
                               +--+-----------------------+--+
                                  | SPI Bus               | Run Signals
                                  | (CS, SCLK, MOSI)      | (ui_in[7:4])
                                  | MISO (uo_out[0])      |
==================================|=======================|=================
                                  v                       v
                         +--------+--------+      +-------+-------+
                         |  HARDWARE SPI   |      |  RUN CONTROL  |
                         | SLAVE & ROUTER  |      |   (Direct)    |
                         +---+----------+--+      +---+-------+---+
                             |          |             |       |
         +-------------------+          +-------------+       +-------------+
         |                                                                  |
         v                                                                  v
  +---------------+               +---------------+                  +---------------+               +---------------+
  | CPU 0 (Core 0)|               | CPU 1 (Core 1)|                  | CPU 2 (Core 2)|               | CPU 3 (Core 3)|
  |               |               |               |                  |               |               |               |
  |  [Inst RAM]   |               |  [Inst RAM]   |                  |  [Inst RAM]   |               |  [Inst RAM]   |
  | (128 Nibbles) |               | (128 Nibbles) |                  | (128 Nibbles) |               | (128 Nibbles) |
  |  [ FIFOs  ]   |               |  [ FIFOs  ]   |                  |  [ FIFOs  ]   |               |  [ FIFOs  ]   |
  +-------+-------+               +-------+-------+                  +-------+-------+               +-------+-------+
          |                               |                                  |                               |
          +-------------------------------+----------------------------------+-------------------------------+
                                          |
                                [ SHARED REGISTERS ]
                                [  SHARED_0 (0x9)  ]
                                [  SHARED_1 (0xA)  ]
                                [  SHARED_2 (0xB)  ]
                                [  SHARED_3 (0xC)  ]
                                          |
                                          v
                                     [uio[3:0]]
                                 (4 Shared I/O Pins)
```

### Pin Breakdown (24 User I/O Pins)
According to the Tiny Tapeout pinout:
1. **`ui_in[7:0]` (8 Input Pins):** 
   - `ui_in[0]`: SPI `CS`
   - `ui_in[1]`: SPI `SCLK`
   - `ui_in[2]`: SPI `MOSI`
   - `ui_in[3]`: Unused / Spare
   - `ui_in[4]`: CPU 0 Run (Start/Stop)
   - `ui_in[5]`: CPU 1 Run (Start/Stop)
   - `ui_in[6]`: CPU 2 Run (Start/Stop)
   - `ui_in[7]`: CPU 3 Run (Start/Stop)
2. **`uo_out[7:0]` (8 Output Pins):**
   - `uo_out[0]`: SPI `MISO`
   - `uo_out[7:1]`: Hardwired to output the **FIFO Status Flags** (e.g., RX Empty, TX Full) for the cores. This allows the RP2040 host to instantly poll the FIFO health via physical pins instead of wasting SPI bandwidth.
3. **`uio_[7:0]` (8 Bidirectional Pins):** 
   - **`uio[3:0]`**: Shared and directly accessible by **CPU 0, 1, 2, and 3**. Their output directions and logic levels are logically OR-ed to prevent contention.
   - **`uio[7:4]`**: Unused / Available for future expansion.
