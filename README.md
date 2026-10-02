# Quad-Core Protocol Emulator ASIC

This project is an official entry for the **Jane Street Hardware Hackathon / Competition**, designed and developed by the team at **[PivotVLSI](https://pivotvlsi.in/)**. 

## Project Overview

The **Quad-Core Protocol Emulator** is a novel, highly constrained hardware-software co-design targeted for the Sky130 130nm PDK (Tiny Tapeout). 

Instead of using dedicated hardware macros (like a hardware UART, SPI, or I2C peripheral), this ASIC features **four custom-designed, 4-bit accumulator-based CPUs** running in parallel. These cores share access to external bidirectional pins and emulate complex communication protocols entirely in software (bit-banging).

This "software-defined peripheral" approach provides immense flexibility, allowing the ASIC to act as a UART transceiver, SPI Master, I2C Controller, or even a USB Low-Speed bit-banger, simply by loading different assembly firmware onto the cores via a master SPI bus.

## Key Features
*   **Quad-Core Architecture:** 4 independent 4-bit accumulator CPUs running in parallel.
*   **Zero Hardware Peripherals:** All protocols are 100% bit-banged in software firmware.
*   **Dual-Core Collaboration:** Cores can snoop the same wire simultaneously (e.g., Core 1 receiving UART data while Core 2 evaluates Parity in parallel).
*   **Highly Optimized ISA:** Custom Instruction Set Architecture designed for single-cycle execution and minimal logic gate utilization.

## Documentation Navigation
To understand the architecture and how to run the verification suite, please refer to the following documentation:

1.  **[Architecture Overview](arch.md)**: Details the CPU internals, memory maps, and the shared bus infrastructure.
2.  **[ISA Specification](isa_spec.md)**: The complete instruction set for the custom 4-bit CPU.
3.  **[Pin Mapping](pin_mapping.md)**: The physical pinout mapping for the Tiny Tapeout ASIC framework.
4.  **[Verification Guide](verif_readme.md)**: Instructions on how to compile the assembly firmware and run the automated testbenches.
5.  **[Limitations & Constraints](limitations.md)**: An honest look at the architectural bottlenecks, software debugging complexities, and theoretical maximum baud rates.

---
*Built with silicon passion by [PivotVLSI](https://pivotvlsi.in/)*
