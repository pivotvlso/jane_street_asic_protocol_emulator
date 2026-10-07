// ==========================================
// UART Receiver (8N1)
// Emulates a standard UART RX on Pin 1
// Uses Polling and TIMER_L hardware timer.
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
    LOAD TIMER_L       // [2] Halts CPU until timer expires // [EXPECT: ACC=TIMER_L]
    
    // NOISE FILTER: Check if Pin 1 is still LOW. If it went High, it was a glitch!
    LOAD PIN_STATE     // [2] // [EXPECT: ACC=PIN_STATE]
    AND B              // [1] (B is still 2 from above)
    JMPNZ WAIT_START   // [3] False alarm! Go back to waiting for a real start bit.
    
    // Setup Bit Counter and Acc
    LOADI 8            // [2] // [EXPECT: ACC=8]
    STORE R4           // [2] R4 = 8 // [EXPECT: R4=ACC]
    LOADI 0            // [2] // [EXPECT: ACC=0]
    STORE R2           // [2] R2 = Data Acc // [EXPECT: R2=ACC]

BIT_LOOP:
    // Wait Full Baud
    LOAD R7            // [2] // [EXPECT: ACC=R7]
    STORE TIMER_L      // [2] // [EXPECT: TIMER_L=ACC]
    LOAD TIMER_L       // [2] // [EXPECT: ACC=TIMER_L]
    
    // Sample Pin 1
    LOADI 2            // [2] // [EXPECT: ACC=2]
    STORE B            // [2] // [EXPECT: B=ACC]
    LOAD PIN_STATE     // [2] // [EXPECT: ACC=PIN_STATE]
    AND B              // [1] ACC is now 0 or 2
    
    // Shift this into the MSB (0x80)
    SHL                // [1] 4 // [EXPECT: ACC=ACC<<1]
    SHL                // [1] 8 // [EXPECT: ACC=ACC<<1]
    SHL                // [1] 16 // [EXPECT: ACC=ACC<<1]
    SHL                // [1] 32 // [EXPECT: ACC=ACC<<1]
    SHL                // [1] 64 // [EXPECT: ACC=ACC<<1]
    SHL                // [1] 128 (0x80) // [EXPECT: ACC=ACC<<1]
    
    // Add to R2 (which is shifted right)
    STORE B            // [2] // [EXPECT: B=ACC]
    LOAD R2            // [2] // [EXPECT: ACC=R2]
    SHR                // [1] // [EXPECT: ACC=ACC>>1]
    ADD                // [1] ACC = (Pin<<6) + (R2>>1) // [EXPECT: ACC=ACC+B]
    STORE R2           // [2] // [EXPECT: R2=ACC]
    
    // Decrement bit counter
    LOADI 1            // [2] // [EXPECT: ACC=1]
    STORE B            // [2] // [EXPECT: B=ACC]
    LOAD R4            // [2] // [EXPECT: ACC=R4]
    SUB                // [1] // [EXPECT: ACC=ACC-B]
    STORE R4           // [2] // [EXPECT: R4=ACC]
    JMPNZ BIT_LOOP     // [3] Loop until R4 == 0
    
    // Push received byte to TX_FIFO (To host)
    LOAD R2            // [2] // [EXPECT: ACC=R2]
    STORE TX_FIFO      // [2] // [EXPECT: TX_FIFO=ACC]
    
    // Wait Full Baud to reach center of Stop Bit
    LOAD R7            // [2] // [EXPECT: ACC=R7]
    STORE TIMER_L      // [2] // [EXPECT: TIMER_L=ACC]
    LOAD TIMER_L       // [2] // [EXPECT: ACC=TIMER_L]
    
    // FRAMING ERROR CHECK: Sample Stop Bit
    LOADI 2            // [2] Mask Pin 1 // [EXPECT: ACC=2]
    STORE B            // [2] // [EXPECT: B=ACC]
    LOAD PIN_STATE     // [2] // [EXPECT: ACC=PIN_STATE]
    AND B              // [1]
    JMPNZ WAIT_START   // [3] If HIGH (Non-Zero), Stop Bit is VALID! Go wait for next byte.
    
    // If we reach here, Stop Bit was LOW (Framing Error!)
    // Generate 0xFF error code and push to FIFO
    LOADI 15           // [2] 0x0F // [EXPECT: ACC=15]
    STORE B            // [2] // [EXPECT: B=ACC]
    LOADI 15           // [2] 0x0F // [EXPECT: ACC=15]
    SHL                // [1] // [EXPECT: ACC=ACC<<1]
    SHL                // [1] // [EXPECT: ACC=ACC<<1]
    SHL                // [1] // [EXPECT: ACC=ACC<<1]
    SHL                // [1] ACC = 0xF0 // [EXPECT: ACC=ACC<<1]
    ADD                // [1] ACC = 0xF0 + 0x0F = 0xFF // [EXPECT: ACC=ACC+B]
    STORE TX_FIFO      // [2] Push 0xFF to host! // [EXPECT: TX_FIFO=ACC]
    
    JMP WAIT_START     // [3] Recover and wait for next byte
