# Protocol Emulator ISA Specification (Final - Load/Store Architecture)

To achieve the absolute highest code density and the simplest possible hardware decoder, this ISA uses a **Load/Store Accumulator Architecture** built entirely on 1-nibble and 2-nibble instructions.

This allows the FSM to use 4-bit addresses (giving access to 16 memory-mapped registers). The **Program Counter (PC) is 7 bits**, meaning it can address up to 128 individual nibbles (64 Bytes total) of instruction memory per FSM.

## Instruction Decoder Logic
The hardware decodes instructions based on the 4-bit opcode:
* `0xxx` (Opcodes `0` to `7`): **1-Nibble Instruction** (4 bits total, 0 Operands).
* `1xxx` (Opcodes `8` to `15`): **2-Nibble Instruction** (8 bits total, 1 Operand: 4-bit Address, Pin, or Offset).


---

## Required Data Registers (16 Address Space)
We now have **8 registers** mapped out of the 16 available slots. Every data register is exactly **8 bits (1 byte) wide**, which perfectly matches the payload size of standard serial protocols like UART, SPI, and I2C.

| Address (Hex) | Register Name | Description |
| :--- | :--- | :--- |
| `0x0` | **ACC** | Math Accumulator (Hardwired for ADD/SUB/AND/SHR/SHL/XOR). |
| `0x1` | **B** | Secondary Math Register (Operand for math). |
| `0x2` | **R2** | Scratch Register / Loop Counter. |
| `0x3` | **R3** | Scratch Register. |
| `0xA` | **R4** | Scratch Register (Useful for CRC / Polynomials). |
| `0xB` | **R5** | Scratch Register. |
| `0xC` | **R6** | Scratch Register. |
| `0xD` | **R7** | Scratch Register. |
| `0xE` | **R8** | Scratch Register. |
| `0xF` | **PIN_DIR** | Pin Direction Register (1 = Output, 0 = Input / High-Z). |
| `0x4` | **TX_FIFO** | Memory Mapped. Moving data here pushes it to the SPI host. |
| `0x5` | **RX_FIFO** | Memory Mapped. Moving data from here pops it from the SPI host. |
| `0x6` | **PIN_STATE** | Memory Mapped. Reads the physical pin voltages. |
| `0x7` | **TIMER_L** | Lower 8-bits of the hardware timer. (Reading this register halts the CPU until the timer hits 0!) |
| `0x9` | **FLAGS** | ALU Status Flags (Bit 0: Zero, Bit 1: Carry). Auto-updated by math ops. |
| `0x8` | **TIMER_H** | Upper 8-bits of the hardware timer. (Writing here starts the countdown). |

---

## 1. 1-Nibble Instructions (Opcode MSB `0`)
These instructions require no operands. They operate implicitly on the `ACC` and `B` registers or the Hardware Timer.
| Opcode (Binary) | Instruction | Description |
| :--- | :--- | :--- |
| `0000` | **ADD** | `ACC = ACC + B` |
| `0001` | **SUB** | `ACC = ACC - B` |
| `0010` | **AND** | `ACC = ACC & B` (Bitwise AND) |
| `0011` | **XOR** | `ACC = ACC ^ B` (Bitwise XOR) |
| `0100` | **SHR** | Shifts `ACC` to the right by 1 bit. |
| `0101` | **SHL** | Shifts `ACC` to the left by 1 bit. |
| `0110` | **NOP** | Do absolutely nothing for 1 clock cycle. |
| `0111` | **RETI**| Return from Interrupt. (Restores PC to where it was before IRQ). |

## 2. 2-Nibble Instructions (Opcodes `1000` to `1100`)
These instructions take a single 4-bit operand (a Pin ID, Immediate, or Register Address).
| Opcode (Binary) | Instruction | Description |
| :--- | :--- | :--- |
| `1000` | **SET0** `pin` | Actively drives the specified `pin` LOW (`0`). |
| `1001` | **SET1** `pin` | Actively drives the specified `pin` HIGH (`1`). |
| `1010` | **LOADI** `imm` | Loads a 4-bit constant into `ACC`. (`ACC = imm`) |
| `1011` | **LOAD** `addr`| Loads data from `addr` into `ACC`. (`ACC = memory[addr]`) |
| `1100` | **STORE** `addr`| Stores data from `ACC` into `addr`. (`memory[addr] = ACC`) |

## 3. 3-Nibble Instructions (Opcodes `1101` to `1111`)
These instructions take a 7-bit Absolute Address operand (built from `{curr_op1[2:0], curr_op2}`), allowing jumping anywhere in the 128-nibble Instruction RAM.
| Opcode (Binary) | Instruction | Description |
| :--- | :--- | :--- |
| `1101` | **JMP** `addr` | `PC = addr` unconditionally. |
| `1110` | **JMPNZ** `addr`| `PC = addr` if Zero Flag == 0. |
| `1111` | **JMPC** `addr` | `PC = addr` if Carry Flag == 1. |
