// ==========================================
// UART RX Parity Watchdog (8E1)
// Emulates a parallel UART RX on Pin 1 to calculate EVEN parity
// ==========================================

BOOT:
    LOAD RX_FIFO       // [2] Get Half Baud Delay from Host // [EXPECT: ACC=RX_FIFO]
    STORE R6           // [2] // [EXPECT: R6=ACC]
    LOAD RX_FIFO       // [2] Get Full Baud Delay from Host // [EXPECT: ACC=RX_FIFO]
    STORE R7           // [2] // [EXPECT: R7=ACC]

    LOADI 2            // [2] Mask for Pin 1 // [EXPECT: ACC=2]
    STORE B            // [2] // [EXPECT: B=ACC]
WAIT_START:
    // Poll Pin 1 for LOW (Start Bit)
    LOAD PIN_STATE     // [2] // [EXPECT: ACC=PIN_STATE]
    AND B              // [1]
    JMPNZ WAIT_START   // [3] Loop if Pin 1 is HIGH
    
    // Found Start Bit! Wait Half Baud to sample middle.
    LOAD R6            // [2] // [EXPECT: ACC=R6]
    STORE TIMER_L      // [2] // [EXPECT: TIMER_L=ACC]
    LOAD TIMER_L       // [2] // [EXPECT: ACC=TIMER_L]
    
    // NOISE FILTER: Check if Pin 1 is still LOW
    LOAD PIN_STATE     // [2] // [EXPECT: ACC=PIN_STATE]
    AND B              // [1]
    JMPNZ WAIT_START   // [3] False alarm!
    
    // Setup Bit Counter and Parity Accumulator
    LOADI 8            // [2] 7 Data Bits + 1 Parity Bit (8 total bits) // [EXPECT: ACC=8]
    STORE R4           // [2] // [EXPECT: R4=ACC]
    LOADI 0            // [2] // [EXPECT: ACC=0]
    STORE R2           // [2] R2 = Number of 1s received // [EXPECT: R2=ACC]

BIT_LOOP:
    // Wait Full Baud
    LOAD R7            // [2] // [EXPECT: ACC=R7]
    STORE TIMER_L      // [2] // [EXPECT: TIMER_L=ACC]
    LOAD TIMER_L       // [2] // [EXPECT: ACC=TIMER_L]
    
    // Sample Pin 1
    LOADI 2            // [3] // [EXPECT: ACC=2]
    STORE B            // [3] // [EXPECT: B=ACC]
    LOAD PIN_STATE     // [3] // [EXPECT: ACC=PIN_STATE]
    AND B              // [2] ACC is now 0 or 2
    
    // Shift right to get 0 or 1
    SHR                // [2] // [EXPECT: ACC=ACC>>1]
    STORE B            // [3] // [EXPECT: B=ACC]
    
    // Add to number of 1s
    LOAD R2            // [3] // [EXPECT: ACC=R2]
    ADD                // [2] // [EXPECT: ACC=ACC+B]
    STORE R2           // [3] // [EXPECT: R2=ACC]
    
    // Decrement bit counter
    LOADI 1            // [3] // [EXPECT: ACC=1]
    STORE B            // [3] // [EXPECT: B=ACC]
    LOAD R4            // [3] // [EXPECT: ACC=R4]
    SUB                // [2] // [EXPECT: ACC=ACC-B]
    STORE R4           // [3] // [EXPECT: R4=ACC]
    JMPNZ BIT_LOOP     // [3] Loop until R4 == 0
    
    // Evaluate EVEN Parity
    LOADI 1            // [2] // [EXPECT: ACC=1]
    STORE B            // [2] // [EXPECT: B=ACC]
    LOAD R2            // [2] Number of 1s // [EXPECT: ACC=R2]
    AND B              // [1] If Even, LSB is 0. If Odd, LSB is 1.
    
    JMPNZ PARITY_ERR   // [3] If 1 (Not Zero), Parity is Invalid!
    JMP PARITY_OK      // [3] If 0, Parity is Valid!
    
PARITY_ERR:
    // Parity Error! Push 0xFF
    LOADI 15           // [2] // [EXPECT: ACC=15]
    STORE B            // [2] // [EXPECT: B=ACC]
    LOADI 15           // [2] // [EXPECT: ACC=15]
    SHL                // [1] // [EXPECT: ACC=ACC<<1]
    SHL                // [1] // [EXPECT: ACC=ACC<<1]
    SHL                // [1] // [EXPECT: ACC=ACC<<1]
    SHL                // [1] // [EXPECT: ACC=ACC<<1]
    ADD                // [1] // [EXPECT: ACC=ACC+B]
    STORE TX_FIFO      // [2] // [EXPECT: TX_FIFO=ACC]
    JMP WAIT_STOP      // [3]
    
PARITY_OK:
    LOADI 0            // [2] Push 0x00 (Valid) // [EXPECT: ACC=0]
    STORE TX_FIFO      // [2] // [EXPECT: TX_FIFO=ACC]

WAIT_STOP:
    LOAD R7            // [2] // [EXPECT: ACC=R7]
    STORE TIMER_L      // [2] // [EXPECT: TIMER_L=ACC]
    LOAD TIMER_L       // [2] // [EXPECT: ACC=TIMER_L]
    
    LOADI 2            // [2] Restore Mask for Pin 1 // [EXPECT: ACC=2]
    STORE B            // [2] // [EXPECT: B=ACC]
    
    JMP WAIT_START     // [3]
