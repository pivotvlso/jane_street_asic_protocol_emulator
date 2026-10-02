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
