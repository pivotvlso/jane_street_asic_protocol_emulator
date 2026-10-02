// ==========================================
// UART Receiver (8N1)
// Emulates a standard UART RX on Pin 1
// Uses Polling and TIMER_L hardware timer.
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
    LOAD TIMER_L       // [2] Halts CPU until timer expires
    
    // NOISE FILTER: Check if Pin 1 is still LOW. If it went High, it was a glitch!
    LOAD PIN_STATE     // [2]
    AND B              // [1] (B is still 2 from above)
    JMPNZ WAIT_START   // [3] False alarm! Go back to waiting for a real start bit.
    
    // Setup Bit Counter and Acc
    LOADI 8            // [2]
    STORE R4           // [2] R4 = 8
    LOADI 0            // [2]
    STORE R2           // [2] R2 = Data Acc

BIT_LOOP:
    // Wait Full Baud
    LOAD R7            // [2]
    STORE TIMER_L      // [2]
    LOAD TIMER_L       // [2]
    
    // Sample Pin 1
    LOADI 2            // [2]
    STORE B            // [2]
    LOAD PIN_STATE     // [2]
    AND B              // [1] ACC is now 0 or 2
    
    // Shift this into the MSB (0x80)
    SHL                // [1] 4
    SHL                // [1] 8
    SHL                // [1] 16
    SHL                // [1] 32
    SHL                // [1] 64
    SHL                // [1] 128 (0x80)
    
    // Add to R2 (which is shifted right)
    STORE B            // [2]
    LOAD R2            // [2]
    SHR                // [1]
    ADD                // [1] ACC = (Pin<<6) + (R2>>1)
    STORE R2           // [2]
    
    // Decrement bit counter
    LOADI 1            // [2]
    STORE B            // [2]
    LOAD R4            // [2]
    SUB                // [1]
    STORE R4           // [2]
    JMPNZ BIT_LOOP     // [3] Loop until R4 == 0
    
    // Push received byte to TX_FIFO (To host)
    LOAD R2            // [2]
    STORE TX_FIFO      // [2]
    
    // Wait Full Baud to reach center of Stop Bit
    LOAD R7            // [2]
    STORE TIMER_L      // [2]
    LOAD TIMER_L       // [2]
    
    // FRAMING ERROR CHECK: Sample Stop Bit
    LOADI 2            // [2] Mask Pin 1
    STORE B            // [2]
    LOAD PIN_STATE     // [2]
    AND B              // [1]
    JMPNZ WAIT_START   // [3] If HIGH (Non-Zero), Stop Bit is VALID! Go wait for next byte.
    
    // If we reach here, Stop Bit was LOW (Framing Error!)
    // Generate 0xFF error code and push to FIFO
    LOADI 15           // [2] 0x0F
    STORE B            // [2]
    LOADI 15           // [2] 0x0F
    SHL                // [1]
    SHL                // [1]
    SHL                // [1]
    SHL                // [1] ACC = 0xF0
    ADD                // [1] ACC = 0xF0 + 0x0F = 0xFF
    STORE TX_FIFO      // [2] Push 0xFF to host!
    
    JMP WAIT_START     // [3] Recover and wait for next byte
