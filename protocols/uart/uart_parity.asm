// ==========================================
// UART RX Parity Watchdog (8E1)
// Emulates a parallel UART RX on Pin 1 to calculate EVEN parity
// ==========================================

BOOT:
    LOAD RX_FIFO       // [2] Get Half Baud Delay from Host
    STORE R8           // [2]
    LOAD RX_FIFO       // [2] Get Full Baud Delay from Host
    STORE R7           // [2]

    LOADI 2            // [2] Mask for Pin 1
    STORE B            // [2]
WAIT_START:
    // Poll Pin 1 for LOW (Start Bit)
    LOAD PIN_STATE     // [2]
    AND B              // [1]
    JMPNZ WAIT_START   // [3] Loop if Pin 1 is HIGH
    
    // Found Start Bit! Wait Half Baud to sample middle.
    LOAD R8            // [2]
    STORE TIMER_L      // [2]
    LOAD TIMER_L       // [2]
    
    // NOISE FILTER: Check if Pin 1 is still LOW
    LOAD PIN_STATE     // [2]
    AND B              // [1]
    JMPNZ WAIT_START   // [3] False alarm!
    
    // Setup Bit Counter and Parity Accumulator
    LOADI 8            // [2] 7 Data Bits + 1 Parity Bit (8 total bits)
    STORE R4           // [2]
    LOADI 0            // [2]
    STORE R2           // [2] R2 = Number of 1s received

BIT_LOOP:
    // Wait Full Baud
    LOAD R7            // [2]
    STORE TIMER_L      // [2]
    LOAD TIMER_L       // [2]
    
    // Sample Pin 1
    LOADI 2            // [3]
    STORE B            // [3]
    LOAD PIN_STATE     // [3]
    AND B              // [2] ACC is now 0 or 2
    
    // Shift right to get 0 or 1
    SHR                // [2]
    STORE B            // [3]
    
    // Add to number of 1s
    LOAD R2            // [3]
    ADD                // [2]
    STORE R2           // [3]
    
    // Decrement bit counter
    LOADI 1            // [3]
    STORE B            // [3]
    LOAD R4            // [3]
    SUB                // [2]
    STORE R4           // [3]
    JMPNZ BIT_LOOP     // [3] Loop until R4 == 0
    
    // Evaluate EVEN Parity
    LOADI 1            // [2]
    STORE B            // [2]
    LOAD R2            // [2] Number of 1s
    AND B              // [1] If Even, LSB is 0. If Odd, LSB is 1.
    
    JMPNZ PARITY_ERR   // [3] If 1 (Not Zero), Parity is Invalid!
    JMP PARITY_OK      // [3] If 0, Parity is Valid!
    
PARITY_ERR:
    // Parity Error! Push 0xFF
    LOADI 15           // [2]
    STORE B            // [2]
    LOADI 15           // [2]
    SHL                // [1]
    SHL                // [1]
    SHL                // [1]
    SHL                // [1]
    ADD                // [1]
    STORE TX_FIFO      // [2]
    JMP WAIT_STOP      // [3]
    
PARITY_OK:
    LOADI 0            // [2] Push 0x00 (Valid)
    STORE TX_FIFO      // [2]

WAIT_STOP:
    LOAD R7            // [2]
    STORE TIMER_L      // [2]
    LOAD TIMER_L       // [2]
    
    LOADI 2            // [2] Restore Mask for Pin 1
    STORE B            // [2]
    
    JMP WAIT_START     // [3]
