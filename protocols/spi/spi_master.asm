// ==========================================
// SPI Master (Mode 0)
// Emulates SPI on Pin 0 (MOSI) and Pin 1 (SCK)
// Optionally reads MISO on Pin 2
// ==========================================

START:
    LOAD RX_FIFO       // [2 Nibbles] Block until Host sends data // [EXPECT: ACC=RX_FIFO]
    STORE R2           // [2 Nibbles] R2 = Data to send // [EXPECT: R2=ACC]
    
    LOADI 8 // [EXPECT: ACC=8]
    STORE R4           // [2 Nibbles] R4 = Bit counter (8) // [EXPECT: R4=ACC]

BIT_LOOP:
    // --------------------------------------
    // 1. SET MOSI (Pin 0) - MSB First
    // --------------------------------------
    LOAD R2 // [EXPECT: ACC=R2]
    SHL                // Shift left. MSB goes into Carry Flag (Bit 1) // [EXPECT: ACC=ACC<<1]
    STORE R2 // [EXPECT: R2=ACC]
    
    JMPC SEND_ONE      // [3]
    
SEND_ZERO:
    SET0 0             // [2] MOSI = LOW
    JMP CLOCK_PULSE    // [3]
    
SEND_ONE:
    SET1 0             // [2] MOSI = HIGH

CLOCK_PULSE:
    // --------------------------------------
    // 2. RISING EDGE (SCK)
    // --------------------------------------
    NOP                // Setup time
    SET1 1             // SCK (Pin 1) HIGH
    
    // (Optional: Sample MISO here if needed)
    
    // --------------------------------------
    // 3. FALLING EDGE (SCK)
    // --------------------------------------
    NOP                // Hold time
    SET0 1             // SCK (Pin 1) LOW
    
    // --------------------------------------
    // 4. DECREMENT LOOP
    // --------------------------------------
    LOAD R4 // [EXPECT: ACC=R4]
    LOADI 1 // [EXPECT: ACC=1]
    STORE B // [EXPECT: B=ACC]
    SUB // [EXPECT: ACC=ACC-B]
    STORE R4 // [EXPECT: R4=ACC]
    
    JMPNZ BIT_LOOP     // [3]
    
    // --------------------------------------
    // 5. NEXT BYTE
    // --------------------------------------
    JMP START          // Perfectly loops back for next payload byte!
