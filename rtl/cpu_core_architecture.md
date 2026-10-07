# Architecture and Understanding of `cpu_core.v`

**`cpu_core.v`** is the heart of the Quad-Core Accumulator architecture. It is a multicycle, 8-bit soft-core processor designed specifically for minimal area (gate count) and high code density.

Here is a breakdown of how it works and the architectural decisions behind it:

## 1. The Multi-Cycle FSM (Finite State Machine)
The CPU isn't deeply pipelined; instead, it uses a multi-cycle state machine to execute instructions over several clock cycles. This saves area and avoids complex hazard-detection logic.
*   **`ST_HALT` (0):** The CPU sits idle here until the `run` signal goes high. Note: If `run` goes low at any point, the CPU immediately forces a synchronous reset to `ST_HALT` and resets `pc = 0`.
*   **`ST_FETCH_OP` (1):** Reads a 4-bit nibble from the ROM using the `pc`.
*   **`ST_FETCH_OP1` (2) & `ST_FETCH_OP2` (3):** If the opcode requires operands (like a 4-bit immediate, a register address, or a 3-nibble jump address), it steps through these states to fetch the additional nibbles.
*   **`ST_EXECUTE` (4):** The actual execution phase where the ALU processes data, or internal registers are updated. 
*   **`ST_MEM_WAIT` (5):** If the CPU needs to read from an external memory-mapped peripheral (like `RX_FIFO` or `PIN_STATE`), it enters this state for exactly 1 cycle. (Note: `mem_stall` logic has been completely removed, so the CPU never stalls here even if a FIFO is empty).

## 2. Internal Registers vs. Memory-Mapped Peripherals
The CPU uses a 4-bit address space for `LOAD` and `STORE` instructions. To fit everything in, `cpu_core.v` divides this 16-slot address space into **Internal Registers** and **External (Memory-Mapped) Peripherals**.

This division is handled by the `is_internal_reg` function:
```verilog
    function is_internal_reg(input [3:0] addr);
        begin
            // 0=ACC, 1=B, 2=R2, 3=R3, 8=FLAGS, B..E=R4..R7, F=PIN_DIR
            is_internal_reg = (addr <= 4'h3) || (addr == 4'h8) || (addr >= 4'hB);
        end
    endfunction
```
*   **Internal Registers (`is_internal_reg == 1`):** Includes `ACC`, `B`, `R2`, `R3`, `R4-R7`, the ALU flags (`0x8`), and `PIN_DIR`. Reads/writes to these happen instantly inside the core in `ST_EXECUTE`.
*   **External Peripherals (`is_internal_reg == 0`):** Includes `TX_FIFO` (4), `RX_FIFO` (5), `PIN_STATE` (6), `TIMER_L` (7), `SHARED_0` (9). If a `LOAD` or `STORE` targets these, `cpu_core.v` asserts `mem_re` or `mem_we` to the external `top.v` bus and waits for the transaction to complete.

## 3. The Execution Logic
During `ST_EXECUTE`, it evaluates the `curr_opcode` (which was fetched in `ST_FETCH_OP`).
*   **ALU Ops (0x0 to 0x5):** Performs 8-bit math using `add_res` and `sub_res` combinational logic. It strictly operates on `ACC` and `b_reg` and updates the `flag_zero` and `flag_carry` bits.
*   **Memory Ops (0xB, 0xC):** Evaluates `is_internal_reg` to decide whether to update the internal `r_regs` array or trigger an external memory transaction. 
*   **Branching (0xD to 0xF):** Absolute jumps that write the assembled 12-bit address (`{curr_op1[2:0], curr_op2}`) directly to the `pc`.

---

## Architecture Fixes Applied

There is a discrepancy between `isa_spec.md` and `cpu_core.v`:

In `isa_spec.md`, address `0x8` is described as a dual-purpose address:
*   **Read:** ALU Status Flags (Internal)
*   **Write:** Starts the Timer Countdown (`TIMER_H`) (External)

However, `cpu_core.v` previously evaluated `is_internal_reg(8)` as `TRUE` for **both reads and writes**. This meant if you wrote `STORE TIMER_H` (opcode `0xC 0x8`), the CPU treated it as an internal register write and silently ignored it, never sending the write out to the external timer in `top.v`. This has been fixed!


