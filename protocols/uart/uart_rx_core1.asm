// ==========================================
// UART RX - Core 1 (The Processor)
// Receives sampled bits from Core 0 and shifts them
// ==========================================

BOOT:
    // Wait for Core 0 to send the START token (Hardware Stall)
    LOAD SHARED_1
    
    // Initialize Shift Register (R2) and Counter (R3)
    LOADI 0
    STORE R2           // R2 = Data [EXPECT: ACC=0x00]
    LOADI 8
    STORE R3           // R3 = 8 bits [EXPECT: ACC=0x08]

PROCESS_LOOP:
    // Wait for Core 0 to send next bit (Hardware Stall)
    LOAD SHARED_1
    
    // Mask Pin 1 (0x2)
    LOADIB 2
    AND B              // ACC = 0 or 2
    
    // Shift it to MSB (0x80)
    SHL
    SHL
    SHL
    SHL
    SHL
    SHL                // ACC is now 0x00 or 0x80
    
    // Merge into R2
    STORE B
    LOAD R2
    SHR                // Shift running data right
    ADD                // ACC = (New_MSB) + (Data >> 1)
    STORE R2
    
    // Decrement counter
    LOADIB 1
    LOAD R3
    SUB
    STORE R3
    JMPNZ PROCESS_LOOP
    
    // We got all 8 bits! Push to Host!
    LOAD R2
    STORE TX_FIFO      // [EXPECT: ACC=0xA5]
    STORE SHARED_0     // Share with parity watchdog
    
    JMP BOOT           // Wait for next START token!
