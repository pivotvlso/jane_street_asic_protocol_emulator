// ==========================================
// JTAG Master (Shift-DR / Shift-IR)
// Emulates JTAG on Pins: 0=TCK, 1=TMS, 2=TDI, 3=TDO
// ==========================================

START:
    LOAD RX_FIFO       // [2] ACC = Data to shift in (TDI) // [EXPECT: ACC=RX_FIFO]
    STORE R2           // [2] R2 = Data // [EXPECT: R2=ACC]
    
    LOADI 8 // [EXPECT: ACC=8]
    STORE R3           // [2] Loop Counter = 8 bits // [EXPECT: R3=ACC]
    
JTAG_LOOP:
    // 1. Set TDI (Pin 2)
    LOAD R2 // [EXPECT: ACC=R2]
    SHR // [EXPECT: ACC=ACC>>1]
    STORE R2 // [EXPECT: R2=ACC]
    JMPC SEND_ONE      // [3]
SEND_ZERO:
    SET0 2             // [2] TDI = LOW
    JMP PULSE_CLOCK    // [3]
SEND_ONE:
    SET1 2             // [2] TDI = HIGH

PULSE_CLOCK:
    // 2. Pulse TCK (Pin 0) HIGH
    SET1 0             // [2] TCK = HIGH
    
    // 3. Read TDO (Pin 3)
    LOAD PIN_STATE     // [2] Read all pins // [EXPECT: ACC=PIN_STATE]
    // (Omitted TDO accumulation logic for brevity)
    
    // 4. Pulse TCK LOW
    SET0 0             // [2] TCK = LOW
    
    // 5. Loop management
    LOAD R3 // [EXPECT: ACC=R3]
    LOADI 1 // [EXPECT: ACC=1]
    STORE B // [EXPECT: B=ACC]
    SUB // [EXPECT: ACC=ACC-B]
    STORE R3           // [2] Decrement R3 // [EXPECT: R3=ACC]
    JMPNZ JTAG_LOOP    // [3] Jump if Not Zero
    
    JMP START          // [3]
