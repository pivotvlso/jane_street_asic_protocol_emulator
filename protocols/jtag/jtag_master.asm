// ==========================================
// JTAG Master (Shift-DR / Shift-IR)
// Emulates JTAG on Pins: 0=TCK, 1=TMS, 2=TDI, 3=TDO
// ==========================================

START:
    LOAD RX_FIFO       // [2] ACC = Data to shift in (TDI)
    STORE R2           // [2] R2 = Data
    
    LOADI 8
    STORE R3           // [2] Loop Counter = 8 bits
    
JTAG_LOOP:
    // 1. Set TDI (Pin 2)
    LOAD R2
    SHR
    STORE R2
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
    LOAD PIN_STATE     // [2] Read all pins
    // (Omitted TDO accumulation logic for brevity)
    
    // 4. Pulse TCK LOW
    SET0 0             // [2] TCK = LOW
    
    // 5. Loop management
    LOAD R3
    LOADI 1
    STORE B
    SUB
    STORE R3           // [2] Decrement R3
    JMPNZ JTAG_LOOP    // [3] Jump if Not Zero
    
    JMP START          // [3]
