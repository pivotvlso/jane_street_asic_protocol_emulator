# Protocol Emulator Architecture: Known Limitations & Constraints

While the Quad-Core Accumulator ASIC is highly flexible and robust, it was designed under severe area constraints for the Sky130 130nm PDK (Tiny Tapeout). As a result, several architectural compromises and limitations exist.

## 1. Instruction Execution Overhead (Overcome via Pipelining)
Because this is a bare-metal, accumulator-based CPU without hardware barrel shifters or complex ALU instructions, single-core execution of complex protocols suffers from massive instruction overhead (e.g., bit shifting takes multiple `SHL` instructions).
* **Limitation:** In the past, a monolithic `uart_rx.asm` routine required ~39 clock cycles just to sample, shift, and store a single bit. 
* **Resolution:** This limitation was fundamentally **overcome** by redesigning the firmware to use a multi-core split-stream pipeline. By dedicating CPU 0 purely to high-speed pin sampling, and offloading the heavy bit-shifting mathematics to CPU 1 via the shared memory interconnect, the instruction execution overhead per core is drastically reduced, allowing for significantly higher physical baud rates.

## 2. No Hardware Interrupts
The CPUs do not possess hardware interrupt request (IRQ) capabilities or stack pointers.
* **Limitation:** A CPU cannot pause execution to service an asynchronous event. 
* **Impact:** Full-Duplex communication (e.g., UART TX and RX simultaneously) cannot be achieved on a single core. It inherently requires allocating independent CPU cores (e.g., CPU 0/1 for RX polling, and CPU 2 for transmitting).

## 3. Instruction Memory Constraints
Because Tiny Tapeout relies on raw D-Flip-Flop (DFF) synthesis for memory rather than dense SRAM macros, RAM is extremely expensive in terms of logic gates.
* **Limitation:** Each CPU is strictly capped at **128 nibbles (64 Bytes)** of Instruction RAM.
* **Impact:** Protocol firmware must be aggressively optimized. The `uart_rx.asm` script utilizes **117 nibbles** to implement noise filtering, center-sampling, and framing error detection. There is virtually no room left for more complex logic without dropping features or adding dedicated hardware accelerators.

## 4. Silent Overrun Errors
The ASIC utilizes small, 8-byte hardware FIFOs to buffer data between the SPI Host and the internal CPUs.
* **Limitation:** If the external RP2040 Host does not poll the SPI bus fast enough to drain the `TX_FIFO`, the hardware will assert a `tx_full` flag. If the internal CPU attempts to push more bytes while the FIFO is full, the CPU will stall (if configured to do so) or the hardware will silently drop the incoming writes to prevent memory corruption.
* **Impact:** The CPU does not currently have a mechanism to generate an "Overrun Error" flag to explicitly alert the Host that data was lost. 

## 5. Parity & Full Duplex Require All 4 Cores
* **Limitation:** The UART firmware cannot fit both standard 8-bit reception and software parity calculation on a single core due to the 128-nibble memory limit. 
* **Impact:** Supporting Parity (e.g., `8E1`) inherently requires allocating a dedicated CPU core to act as a parallel watchdog on the RX pin, purely to count bits and evaluate parity. To achieve Full-Duplex UART with Parity, all 4 cores of the ASIC must be utilized simultaneously: CPU 0 (RX Sampler), CPU 1 (RX Shifter), CPU 2 (TX), and CPU 3 (Parity Watchdog). This leaves no CPU cores available for other protocols.

## 6. Maximum Theoretical Baud Rate
* **Limitation:** The maximum baud rate is dictated by the longest critical path in the split-stream pipeline. Since offloading bit-shifting to background cores, the tightest software polling loops (such as CPU 1's UART sampler) now execute in under 15 clock cycles.
* **Impact:** If the Tiny Tapeout ASIC runs at a maximum master clock of **50 MHz**, a 15-cycle loop overhead equals 300ns per bit. This effectively triples the maximum theoretical baud rate to roughly **~3.33 Mbps** (up from the monolithic core's 1.25 Mbps limit).

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
* **Impact:** Syncing multiple CPUs relies entirely on manual, mathematically precise cycle-counting. If CPU 0's baud delay loop is 28 cycles and CPU 3's parity loop is 57 cycles, the host must manually calibrate their independent `TIMER_H` / `TIMER_L` hardware timers so they remain perfectly phase-aligned over the duration of the transmission.

## 14. I2C Protocol Limitations
* **Limitation:** The current firmware supports standard 8-bit I2C transactions with clock stretching, but lacks advanced features due to architectural constraints.
* **Impact:**
  - **Memory Limits (Split TX/RX):** Because of the 128-nibble memory cap (Limitation #3), it is impossible to fit both Master Transmit and Master Receive logic into a single CPU core. As a result, the I2C routines are split into unidirectional scripts (`i2c_master.asm` for TX, `i2c_master_rx.asm` for RX) that the Host must swap in dynamically.
  - **Multi-Master Arbitration:** The ASIC CPUs share physical pins without a hardware bus arbiter (Limitation #9). Simultaneous master operations will corrupt data.
  - **10-bit Addressing:** Handling 10-bit addressing state machines exceeds the strict 128-nibble memory limit.
  - **High-Speed Mode (3.4 Mbps):** The software bit-banging overhead limits the theoretical maximum speed to ~1.25 Mbps (at 50 MHz), making High-Speed mode physically impossible (Standard and Fast modes are fully supported).

## 15. Register Aliasing: R4 and R5 are Globally Shared
* **Limitation:** In the assembler, the CPU only has four true private internal registers for general use: `ACC`, `B`, `R2`, and `R3`. To provide additional registers, the assembler maps `R4` to memory address `0xB` (`SHARED_2`) and `R5` to memory address `0xC` (`SHARED_3`).
* **Impact:** Because these memory addresses are globally accessible across all 4 CPUs, `R4` and `R5` are **NOT** private to the executing core. If multiple CPUs attempt to use `R4` as a local loop counter simultaneously, they will overwrite each other's state via the global shared memory and cause data corruption (as they are inadvertently ping-ponging the same physical hardware register). Firmware developers must strictly use `R2` or `R3` for private loops, or mathematically coordinate shared usage of `R4`/`R5` across cores.

## 16. 10BASE-T Ethernet Limitations
* **Overview:** Implementing a 10 Mbps Manchester-encoded protocol on a 50 MHz accumulator-based architecture introduces several absolute physical and logical constraints.
* **Key Limitations:**

  1. **Strictly Half-Duplex (Due to 4-Core Limit)**
     - **TX Requirement:** Transmitting differential Ethernet requires all 4 cores working synchronously (Serializer → Encoder → TX+ and TX- Drivers).
     - **RX Requirement:** Receiving requires 2 cores (Edge Detector → Deserializer).
     - **Impact:** Since the ASIC only has 4 cores, Full-Duplex is physically impossible. The Host RP2040 must dynamically hot-swap the internal CPU firmware via SPI to switch between Transmit mode and Receive mode.

  2. **Deterministic Jitter at 50MHz**
     - **Cause:** A 10 Mbps half-bit transition is 50ns. At a 50MHz master clock (20ns per cycle), 50ns equates to exactly 2.5 clock cycles.
     - **Impact:** Because CPUs cannot delay for fractional cycles, the Manchester encoder firmware alternates delays of 2 cycles (40ns) and 3 cycles (60ns). This introduces ±10ns of deterministic jitter. While this fits tightly within the ±11ns IEEE 802.3 tolerance, it leaves virtually no margin for external noise.

  3. **No Hardware CRC32 (Frame Check Sequence)**
     - **Cause:** Calculating the standard 32-bit Ethernet CRC32 polynomial requires complex bit-wise shifting arrays that vastly exceed the strict 128-nibble instruction memory limit of the cores.
     - **Impact:** The ASIC cannot natively generate or verify the FCS payload. The Host RP2040 must pre-calculate and append the CRC32 to outgoing TX frames, and software-verify the CRC32 on incoming RX frames.

  4. **Host-Driven Normal Link Pulses (NLP)**
     - **Cause:** 10BASE-T requires heartbeat link pulses every 16ms to keep the physical link alive. The ASIC has no background timers large enough to autonomously inject these pulses.
     - **Impact:** The Host RP2040 must actively monitor idle periods and manually trigger NLP transmissions via the SPI interface to prevent the downstream switch/router from dropping the link.
