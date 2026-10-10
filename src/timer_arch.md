# Architecture and Understanding of `timer.v`

`timer.v` implements a **16-bit countdown timer** for each CPU. Because the CPU itself is simple and operates strictly on 8-bit registers, the timer is accessed via two 8-bit memory-mapped registers: `TIMER_L` (address `0x7`) and `TIMER_H` (address `0x8`).

Here is a breakdown of how the timer functions and how it is used by the CPU:

## 1. Setting an 8-bit Delay (`TIMER_L`)
When a CPU writes to `TIMER_L` (address `0x7`), the timer automatically:
1. Clears the upper 8-bits (`count[15:8] <= 0`)
2. Loads the provided 8-bit data into the lower 8-bits (`count[7:0] <= wdata`)
3. Immediately starts the timer counting down (`running <= 1`).

This is a convenience feature allowing the CPU to trigger short delays (up to 255 clock cycles) with a single `STORE TIMER_L` instruction.

## 2. Setting a 16-bit Delay (`TIMER_H`)
If the CPU needs a delay longer than 255 clock cycles, it must perform two writes in sequence:
1. First, it writes to `TIMER_L`. This sets the lower 8 bits and auto-clears the top half.
2. Second, it writes to `TIMER_H` (address `0x8`). Writing to `TIMER_H` loads the upper 8 bits (`count[15:8] <= wdata`) without disturbing the lower bits, and explicitly starts the countdown.

## 3. Counting and Output
Once `running` is set, the timer decrements the full 16-bit `count` by 1 every clock cycle until it reaches `0`. 

It provides two outputs back to the system:
- **`rdata_l`**: Exposes the current live value of the lower 8-bits (`count[7:0]`). When the CPU reads `TIMER_L`, this is what it sees.
- **`is_zero`**: A boolean flag that stays low until the full 16-bit counter hits `0`. 

*(Note: Prior to removing the `mem_stall` logic from `top.v`, the `is_zero` signal was used to literally freeze the CPU's clock state whenever it tried to read `TIMER_L` before the timer had finished. Now that we have removed stalling, a CPU must actively poll `TIMER_L` in a loop in assembly to create a delay).*
