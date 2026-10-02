# Protocol Emulator Architecture: Known Limitations & Constraints

While the Quad-Core Accumulator ASIC is highly flexible and robust, it was designed under severe area constraints for the Sky130 130nm PDK (Tiny Tapeout). As a result, several architectural compromises and limitations exist.

## 1. Instruction Execution Overhead
Because this is a bare-metal, accumulator-based CPU without hardware barrel shifters or complex ALU instructions, simple operations require multiple instructions to execute.
* **Limitation:** The instruction execution overhead for bit-banging protocols can be massive. For example, in `uart_rx.asm`, the software `BIT_LOOP` requires approximately **39 clock cycles** just to sample, shift, and store a single bit. 
* **Impact:** The ASIC cannot emulate high-speed baud rates that approach the master clock frequency. The external RP2040 Host MUST calibrate the hardware `TIMER_L` values to mathematically subtract this software instruction overhead when configuring baud rates (e.g., programming a timer delay of `61` to achieve a physical baud rate of `100` cycles/bit).

## 2. No Hardware Interrupts
The CPUs do not possess hardware interrupt request (IRQ) capabilities or stack pointers.
* **Limitation:** A CPU cannot pause execution to service an asynchronous event. 
* **Impact:** Full-Duplex communication (e.g., UART TX and RX simultaneously) cannot be achieved on a single core. It inherently requires allocating two independent CPU cores (one dedicated to polling the RX pin, and one dedicated to transmitting the TX pin).

## 3. Instruction Memory Constraints
Because Tiny Tapeout relies on raw D-Flip-Flop (DFF) synthesis for memory rather than dense SRAM macros, RAM is extremely expensive in terms of logic gates.
* **Limitation:** Each CPU is strictly capped at **128 nibbles (64 Bytes)** of Instruction RAM.
* **Impact:** Protocol firmware must be aggressively optimized. The `uart_rx.asm` script utilizes **117 nibbles** to implement noise filtering, center-sampling, and framing error detection. There is virtually no room left for more complex logic without dropping features or adding dedicated hardware accelerators.

## 4. Silent Overrun Errors
The ASIC utilizes small, 8-byte hardware FIFOs to buffer data between the SPI Host and the internal CPUs.
* **Limitation:** If the external RP2040 Host does not poll the SPI bus fast enough to drain the `TX_FIFO`, the hardware will assert a `tx_full` flag. If the internal CPU attempts to push more bytes while the FIFO is full, the CPU will stall (if configured to do so) or the hardware will silently drop the incoming writes to prevent memory corruption.
* **Impact:** The CPU does not currently have a mechanism to generate an "Overrun Error" flag to explicitly alert the Host that data was lost. 

## 5. Single-Core Parity is Unsupported
* **Limitation:** The UART firmware cannot fit both standard 8-bit reception and software parity calculation on a single core. 
* **Impact:** Due to the 128-nibble memory limit, parity checking requires complex bitwise XOR/AND loops on the accumulator that overflow the instruction RAM. Supporting Parity (e.g., `8E1`) inherently requires allocating a **second CPU core** to act as a parallel watchdog on the RX pin, purely to count bits and evaluate parity.

## 6. Maximum Theoretical Baud Rate
* **Limitation:** The minimum execution time for a bit-banging loop is approximately 40 clock cycles (39 cycles of instruction overhead + 1 cycle of timer wait).
* **Impact:** If the Tiny Tapeout ASIC runs at a maximum master clock of **50 MHz**, 40 cycles equals 800ns per bit. Therefore, the absolute maximum UART baud rate the chip can emulate is **~1.25 Mbps**.

## 7. No Indirect Memory Addressing (No Pointers)
* **Limitation:** The ISA only supports direct addressing (`LOAD addr`). There is no support for pointers, indirect addressing (e.g., `LOAD [R2]`), or a Stack Pointer.
* **Impact:** It is impossible to implement arrays, dynamic memory allocation, or recursive function calls in software. The CPU is strictly limited to operating on the 16 fixed memory-mapped registers.

## 8. No Hardware Multiplier or Barrel Shifter
* **Limitation:** The ALU only supports single-bit shifts (`SHL`, `SHR`) and basic addition/subtraction.
* **Impact:** Shifting a bit to the MSB requires executing `SHL` six or seven times sequentially. This artificially inflates both the execution time and the instruction memory footprint for protocols that are MSB-first.

## 9. Logical Pin Contention (No Bus Arbitration)
* **Limitation:** All four CPUs share the same `uio_out[3:0]` pins. Their outputs are logically `OR`-ed together in hardware. There is no hardware bus-arbiter or lock mechanism.
* **Impact:** If CPU 0 and CPU 1 both mistakenly attempt to drive Pin 0 at the same time, the hardware will not short-circuit, but the data will be logically corrupted (a `1` from CPU 0 will overwrite a `0` from CPU 1). The system relies 100% on software discipline to ensure cores don't talk over each other.

## 10. Only 4 Shared External Pins
* **Limitation:** The design only exposes 4 bidirectional pins (`uio[3:0]`) to the CPU cores.
* **Impact:** While 4 pins are exactly enough for a full 4-wire SPI bus (`MISO`, `MOSI`, `SCLK`, `CS`), it means you cannot run two independent SPI buses at the same time, because there aren't enough physical pins available.

## 11. Register Bottlenecks & Software Complexity
* **Limitation:** The CPU only contains a single Accumulator (`ACC`) and one Scratchpad Register (`B`). Everything else requires memory-mapped I/O (like `R2` through `R8`).
* **Impact:** Algorithms frequently overwrite the `B` register since it is the only operand for ALU instructions (like `AND B`). When using `B` to hold a bit-mask for reading hardware pins, developers must be extremely careful not to accidentally overwrite it with an arithmetic operand, as it can cause the CPU to silently start polling the wrong hardware pin and stall.

## 12. Lack of Hardware Debugging & Cycle-Profiling Tools
* **Limitation:** Because this is a bare-metal custom ISA, there are no traditional hardware debuggers, breakpoints, or JTAG step-through capabilities.
* **Impact:** Firmware debugging requires extracting raw Verilog VCD trace files, locating the CPU's internal 4-bit accumulator, and manually mapping raw binary numbers to assembly execution line-by-line across hundreds of simulated nanoseconds.

## 13. Complex Inter-Processor Synchronization
* **Limitation:** When multiple CPUs interact with the same external bus (e.g., CPU 1 extracting UART data and CPU 2 acting as a Parity watchdog on the same wire), there are no hardware synchronization primitives (semaphores, mutexes) between them.
* **Impact:** Syncing multiple CPUs relies entirely on manual, mathematically precise cycle-counting. If CPU 1's baud delay loop is 62 cycles and CPU 2's parity loop is 50 cycles, the host must manually calibrate their independent `TIMER_L` hardware timers so they remain perfectly phase-aligned over the duration of the transmission.
