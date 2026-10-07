# Protocol Emulator ISA Specification (Final - Load/Store Architecture)

To achieve the absolute highest code density and the simplest possible hardware decoder, this ISA uses a **Load/Store Accumulator Architecture** built entirely on 1-nibble and 2-nibble instructions.

This allows the FSM to use 4-bit addresses (giving access to 16 memory-mapped registers). The **Program Counter (PC) is 7 bits**, meaning it can address up to 128 individual nibbles (64 Bytes total) of instruction memory per FSM.

## Instruction Decoder Logic
The hardware decodes instructions based on the 4-bit opcode:
* `0xxx` (Opcodes `0` to `7`): **1-Nibble Instruction** (4 bits total, 0 Operands).
* `1000` to `1100` (Except `1010`): **2-Nibble Instruction** (8 bits total, 1 Operand: 4-bit Address or Pin).
* `1101` to `1111` & `1010`: **3-Nibble Instruction** (12 bits total, 2 Operands for Jumps and LOADI).


---

## Required Data Registers (16 Address Space)
We now have **8 registers** mapped out of the 16 available slots. Every data register is exactly **8 bits (1 byte) wide**, which perfectly matches the payload size of standard serial protocols like UART, SPI, and I2C.

| Address (Hex) | Register Name | Description |
| :--- | :--- | :--- |
| `0x0` | **ACC** | Math Accumulator (Hardwired for ADD/SUB/AND/SHR/SHL/XOR). |
| `0x1` | **B** | Secondary Math Register (Operand for math). |
| `0x2` | **R2** | Scratch Register / Loop Counter. |
| `0x3` | **R3** | Scratch Register. |
| `0xA` | **SHARED_1** | Memory Mapped. Shared register across all 4 CPUs for cross-communication. |
| `0xB` | **R4** | Scratch Register (Useful for CRC / Polynomials). |
| `0xC` | **R5** | Scratch Register. |
| `0xD` | **R6** | Scratch Register. |
| `0xE` | **R7** | Scratch Register. |
| `0xF` | **PIN_DIR** | Pin Direction Register (1 = Output, 0 = Input). **Read:** Returns `{pin_state, pin_dir}`. |
| `0x4` | **TX_FIFO** | Memory Mapped. Moving data here pushes it to the SPI host. |
| `0x5` | **RX_FIFO** | Memory Mapped. Moving data from here pops it from the SPI host. |
| `0x6` | **PIN_STATE** | Memory Mapped. Reads the physical pin voltages. |
| `0x7` | **TIMER_L** | Lower 8-bits of the hardware timer. (Reading this register returns the current countdown value instantly; it no longer halts!) |
| `0x8` | **TIMER_H / FLAGS** | **Write:** Starts timer countdown. **Read:** ALU Status Flags (Bit 0: Zero, Bit 1: Carry). |
| `0x9` | **SHARED_0** | Memory Mapped. Shared register across all 4 CPUs for cross-communication. |

---

## Instruction Set Summary

| Opcode | Length | Instruction | Description |
| :--- | :--- | :--- | :--- |
| `0000` | 1 Nibble | **ADD** | `ACC = ACC + B` |
| `0001` | 1 Nibble | **SUB** | `ACC = ACC - B` |
| `0010` | 1 Nibble | **AND** | `ACC = ACC & B` (Bitwise AND) |
| `0011` | 1 Nibble | **XOR** | `ACC = ACC ^ B` (Bitwise XOR) |
| `0100` | 1 Nibble | **SHR** | Shifts `ACC` to the right by 1 bit. |
| `0101` | 1 Nibble | **SHL** | Shifts `ACC` to the left by 1 bit. |
| `0110` | 1 Nibble | **NOP** | Do absolutely nothing for 1 clock cycle. |
| `0111` | - | - | *(Unused)* |
| `1000` | 2 Nibbles | **SET0** `pin` | Actively drives the specified `pin` LOW (`0`). |
| `1001` | 2 Nibbles | **SET1** `pin` | Actively drives the specified `pin` HIGH (`1`). |
| `1010` | 3 Nibbles | **LOADI** `imm8`| Loads an 8-bit constant into `ACC`. (`ACC = imm8`). Consumes 2 operand nibbles. |
| `1011` | 2 Nibbles | **LOAD** `addr`| Loads data from `addr` into `ACC`. (`ACC = memory[addr]`) |
| `1100` | 2 Nibbles | **STORE** `addr`| Stores data from `ACC` into `addr`. (`memory[addr] = ACC`) |
| `1101` | 3 Nibbles | **JMP** `addr` | `PC = addr` unconditionally. |
| `1110` | 3 Nibbles | **JMPNZ** `addr`| `PC = addr` if Zero Flag == 0. |
| `1111` | 3 Nibbles | **JMPC** `addr` | `PC = addr` if Carry Flag == 1. |
