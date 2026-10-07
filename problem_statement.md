# Jane Street ASIC Emulator Contest - Problem Statement

Jane Street has announced a hardware challenge to design an **open-source, general-purpose protocol emulator ASIC**.

## The Goal
The objective is to design a chip that acts as a flexible protocol emulator. The focus is on creating a "tiny CPU" with an instruction set specialized for:
- Reading pins
- Writing pins
- Precise cycle counting

The emulator must be capable of handling common protocols such as:
- UART
- SPI
- I2C

**Stretch Goals:**
- USB emulation
- Ethernet emulation

## The Reward
Jane Street will fund the fabrication of their favorite designs. Winners will receive a fabricated copy of their chip mounted on a development board to test in real silicon.

## Context
This competition follows a recent "reverse-engineering" puzzle where Jane Street provided participants with a raw GDS file (the geometric layout of a chip) and asked them to figure out what the circuit did. It also follows the "Advent of FPGA" challenge from late 2025.

## Implementation Status
Our Quad-Core Emulator currently implements the following protocol interfaces in assembly firmware:
- **UART:** TX (Basic, Dynamic Baud, Streaming), RX (Noise Resilient, Framing, Parity) - Fully Verified
- **SPI:** Master Mode - Fully Verified
- **I2C:** Master TX, Master RX, Slave TX, Slave RX (Includes clock stretching support) - Fully Verified
- **JTAG:** Master Mode - Partially implemented/Tested
- **USB:** TX Emulation - Included (Stretch Goal)
- **Ethernet:** 10BASE-T TX & RX Emulation - Fully Verified (Uses 4-core shared-memory pipeline for zero-skew differential transmission, and a 2-core pipeline for Manchester edge-decoding and deserialization).
