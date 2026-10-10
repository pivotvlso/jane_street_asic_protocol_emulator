# Dual-Core UART RX Architecture

Because this custom ASIC lacks hardware bit-shifting and hardware data sampling, performing UART RX entirely in software is cycle-intensive. If a single CPU handles the timer polling, pin sampling, masking, bit-shifting, and FIFO pushing, the sheer number of clock cycles required limits the maximum baud rate to roughly 1 Mbps (assuming a 50 MHz master clock).

To achieve higher speeds and completely eliminate sampling jitter, the UART RX protocol is split into a **2-Stage Software Pipeline** across two CPUs: **Core 0 (The Sampler)** and **Core 1 (The Processor)**. 

They communicate exclusively via **SHARED_1 (0xA)**, which acts as a 1-byte hardware FIFO. 
- When Core 0 writes to `SHARED_1`, the hardware instantly sets a **Valid Flag** (Bit 3 in the `FLAGS` register).
- When Core 1 reads from `SHARED_1`, the hardware instantly clears this Valid Flag.

---

## Stage 1: Core 0 (The Sampler)

Core 0's only job is strict real-time precision. It runs an extremely tight loop that polls the hardware timer and samples the physical pins. It does **no math or data processing**.

1. **Start Bit Detection:** Core 0 polls `PIN_STATE` waiting for a falling edge.
2. **Timing & Sampling:** Once found, it uses the Timer to wait exactly half a baud period, verifies the start bit, and sends a special `0xFF` start token to `SHARED_1`.
3. **Data Loop:** It waits a full baud period, samples `PIN_STATE`, and pushes the raw pins directly into `SHARED_1`.
4. **Handshake:** Core 0 doesn't need to explicitly toggle any software flags! The hardware automatically flags the data as valid for Core 1. Core 0 simply polls the `FLAGS` register to ensure Core 1 has read the data before looping.

Because Core 0's loop is incredibly short (approx. 10 instructions), the sampling jitter is near zero.

---

## Stage 2: Core 1 (The Processor)

Core 1 handles the heavy mathematical lifting. Because Core 0 has already locked in the exact sampling time, Core 1 has an entire baud period (the time until the next bit arrives) to do its processing.

1. **Hardware Stall:** Core 1 executes `LOAD SHARED_1`. If data is not ready, the hardware physically halts Core 1's clock.
2. **Immediate Read:** As soon as Core 0 writes data, Core 1 instantly resumes, loading the data and **clearing the valid flag in hardware**, acknowledging to Core 0 that the data was received!
3. **Processing:** Core 1 now takes its time doing the heavy lifting:
   - Masks the relevant RX pin.
   - Shifts the bit 6 times (`SHL`) to move it to the MSB (`0x80`).
   - Shifts the running Accumulator data right (`SHR`).
   - Adds the new MSB bit (`ADD`).
   - Decrements the bit counter.
4. **Completion:** After 8 bits, it dumps the fully assembled byte into the hardware `TX_FIFO` for the SPI host to read.

---

## Why Not 3 Cores? (Amdahl's Law in Action)

While it might seem logical to pipeline the math even further (e.g., have Core 1 do the bit shifting and Core 2 do the accumulating), this actually results in **slower performance**.

In this Accumulator-based architecture, every `LOAD` and `STORE` takes 3 clock cycles, and all memory access must funnel through the single Accumulator. 

To perform a safe handshake between Core 1 and Core 2:
1. Core 1 must save its shifted bit into scratch memory (`STORE R3`).
2. Read Core 2's flag into the Accumulator (`LOAD SHARED_2`).
3. Check the flag.
4. Restore its shifted bit from scratch memory (`LOAD R3`).
5. Send the bit (`STORE SHARED_3`).

This strict "data juggling" costs roughly **27 clock cycles** of IPC (Inter-Process Communication) overhead. Because the math being offloaded to Core 2 (`SHR`, `ADD`, `SUB`) only takes about **5 clock cycles**, the cost of communication massively outweighs the benefit of parallelization. 

Thus, the **2-Core Pipeline** is the mathematical sweet spot for this specific ISA!

---

## 4. Performance and Clock Cycle Analysis

The maximum theoretical Baud Rate is determined by the **bottleneck** in the pipeline. Because the two cores run in parallel, the maximum speed is dictated by the slowest loop. 

Core 0's timer setup and sampling logic takes only ~30 clock cycles. Core 1, however, must perform the heavy bitwise math.

### Core 1 Cycle Trace (Per Bit)
Because the CPU now uses a **1-Cycle Split-Stream Pipeline**, every instruction takes exactly 1 clock cycle to execute, regardless of how many nibbles it uses!

1. **Hardware Stall & Mask:** `LOAD SHARED_1` (1), `LOADIB 2` (1), `AND B` (1) = **3 cycles**
2. **Shifting to MSB:** 6x `SHL` (6 * 1) = **6 cycles**
3. **Merge to Accumulator:** `STORE B` (1), `LOAD R2` (1), `SHR` (1), `ADD` (1), `STORE R2` (1) = **5 cycles**
4. **Decrement Counter:** `LOADIB 1` (1), `LOAD R4` (1), `SUB` (1), `STORE R4` (1), `JMPNZ` (1) = **5 cycles**

**Total Core 1 Processing Time:** `3 + 6 + 5 + 5` = **19 Clock Cycles per bit.**

### Maximum Baud Rate Calculation
Because Core 1 needs 19 cycles to process a bit, the Baud Rate delay (the timer value set by Core 0) **must be at least 19 clock cycles**. If bits arrive faster than this, Core 1 will fall behind and corrupt the data.

- **At 50 MHz:** `50,000,000 / 19` = **~2.63 Mbps**
- **At 100 MHz:** `100,000,000 / 19` = **~5.26 Mbps**

Thanks to the True 1-Cycle Pipeline, hardware `FLAGS` polling, and the zero-clobber `LOADIB` instruction, the software UART pipeline is capable of sustaining a blazing fast 5.26 Mbps connection.
