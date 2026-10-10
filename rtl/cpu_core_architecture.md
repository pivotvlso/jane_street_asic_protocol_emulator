# Architecture and Understanding of `cpu_core.v`

**`cpu_core.v`** is the heart of the Quad-Core Accumulator architecture. It is a multicycle, 8-bit soft-core processor designed specifically for minimal area (gate count) and high code density.

Here is a breakdown of how it works and the architectural decisions behind it:

## 1. 1-Cycle Split-Stream Pipeline
The CPU is deeply pipelined and executes every instruction in **exactly 1 clock cycle**. Because the fundamental memory width is only 4 bits (1 nibble), fetching a 3-nibble instruction sequentially would take 3 clock cycles. 

To break this limitation, the ASIC uses a **Split-Stream (Decoupled) Architecture**:
The Instruction memory is split into 3 separate physical RAMs:
* **`rom_op`**: Contains only the opcodes.
* **`rom_op1`**: Contains the first operand nibbles.
* **`rom_op2`**: Contains the second operand nibbles.

During a single clock cycle, the CPU combinationally fetches all 3 nibbles simultaneously from the three RAMs using three separate program counters (`pc_op`, `pc_op1`, `pc_op2`). 
* If the instruction is 1 nibble long, it executes and only increments `pc_op`.
* If the instruction is 2 nibbles long, it executes and increments both `pc_op` and `pc_op1`.
* If the instruction is 3 nibbles long, it executes and increments all three pointers.

## 2. Internal Registers vs. Memory-Mapped Peripherals
The CPU uses a 4-bit address space for `LOAD` and `STORE` instructions. To fit everything in, `cpu_core.v` divides this 16-slot address space into **Internal Registers** and **External (Memory-Mapped) Peripherals**.

This division is handled by the `is_internal_reg` function:
```verilog
    function is_internal_reg(input [3:0] addr);
        begin
            // 0=ACC, 1=B, 2=R2, 3=R3, 8=FLAGS, D=R6, E=R7, F=PIN_DIR
            is_internal_reg = (addr <= 4'h3) || (addr == 4'h8) || (addr >= 4'hD);
        end
    endfunction
```
*   **Internal Registers (`is_internal_reg == 1`):** Includes `ACC`, `B`, `R2`, `R3`, `R6-R7`, the ALU flags (`0x8`), and `PIN_DIR`. Reads/writes to these happen instantly inside the core in `ST_EXECUTE`.
*   **External Peripherals (`is_internal_reg == 0`):** Includes `TX_FIFO` (4), `RX_FIFO` (5), `PIN_STATE` (6), `TIMER_L` (7), `SHARED_0` (9), `SHARED_1` (A), `SHARED_2` (B), `SHARED_3` (C). If a `LOAD` or `STORE` targets these, `cpu_core.v` asserts `mem_re` or `mem_we` to the external `top.v` bus and waits for the transaction to complete.

## 3. The Execution Logic
All instructions execute in a single combinational cycle.
*   **ALU Ops (0x0 to 0x5):** Performs 8-bit math using `add_res` and `sub_res` combinational logic. It strictly operates on `ACC` and `b_reg` and updates the `flag_zero` and `flag_carry` bits.
*   **Memory Ops (0xB, 0xC):** Evaluates `is_internal_reg` to decide whether to update the internal `r_regs` array or trigger an external memory transaction. 
*   **Branching (0xD to 0xF):** Branching in a split-stream architecture is highly complex because all three `pc` pointers must be perfectly synchronized to the target label. To solve this in 1 clock cycle, the CPU contains a **Hardware Jump Table**. The `JMP` instruction is a 2-nibble instruction providing a 4-bit Jump ID. The CPU reads the `{target_pc_op, target_pc_op1, target_pc_op2}` from the Jump Table based on the ID, and instantly overwrites all three pointers.

---

## Architecture Fixes Applied

There is a discrepancy between `isa_spec.md` and `cpu_core.v`:

In `isa_spec.md`, address `0x8` is described as a dual-purpose address:
*   **Read:** ALU Status Flags (Zero, Carry) and Shared Register Valid Flags (Bits 2-5). (Internal)
*   **Write:** Starts the Timer Countdown (`TIMER_H`) (External)



### The `LOADI` State Machine Bug
In `isa_spec.md`, the `LOADI` (`0xA`) instruction is defined as a 3-nibble instruction that loads an 8-bit immediate into the Accumulator. However, the state machine in `cpu_core.v` originally implemented `LOADI` as a 2-nibble instruction that only loaded a 4-bit immediate!
- It skipped `ST_FETCH_OP2` entirely.
- It only parsed `curr_op1` and loaded `{4'b0000, curr_op1}` into the Accumulator.
- Because it exited early, the lower 4-bits of the immediate in ROM were erroneously fetched as the *next* opcode on the following cycle, causing catastrophic CPU crashes!

This has been fixed by routing `0xA` (and the new `0x7` `LOADIB` instruction) through the complete `ST_FETCH_OP1 -> ST_FETCH_OP2 -> ST_EXECUTE` cycle. Both instructions now correctly load the full 8-bit immediate `{curr_op1, curr_op2}` in exactly 4 clock cycles.

### Hardware Memory Stalling
To maximize IPC (Inter-Process Communication) and timer precision, the CPU supports **Hardware Stalling** during `LOAD` and `STORE` instructions. 
When the CPU executes a memory-mapped operation that isn't ready, `top.v` asserts the `mem_stall` signal. The pipeline will literally freeze (all `pc` counters pause, consuming 0 instructions) until the hardware clears the stall condition.
- `LOAD TIMER_L`: Stalls until the hardware timer reaches 0.
- `LOAD SHARED_X`: Stalls until the valid flag for that shared register goes high.
- `LOAD RX_FIFO`: Stalls if the UART/SPI hardware FIFO is empty.
- `STORE TX_FIFO`: Stalls if the TX hardware FIFO is full.

