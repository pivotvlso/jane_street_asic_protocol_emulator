// ==========================================
// UART Transmitter (8N1)
// Emulates a standard UART TX on Pin 0
// ==========================================
// Size: 64 Nibbles (Exactly 100% full!)

BOOT:
    SET1 0             // [2] Initialize UART TX to IDLE HIGH
    LOADI 1            // [2] // [EXPECT: ACC=1]
    STORE PIN_DIR      // [2] Set Pin 0 to Output // [EXPECT: PIN_DIR=ACC]
    
    LOAD RX_FIFO       // [2] Wait for Host to send Baud Rate config // [EXPECT: ACC=RX_FIFO]
    STORE R6           // [2] Save to R6 // [EXPECT: R6=ACC]

START:
    LOAD RX_FIFO       // [2] Block until Host sends data // [EXPECT: ACC=RX_FIFO]
    STORE R2           // [2] R2 = Data // [EXPECT: R2=ACC]
    
    SET0 0             // [2] Start bit (LOW)
    LOAD R6            // [2] Load baud delay // [EXPECT: ACC=R6]
    STORE TIMER_L      // [2] Start timer // [EXPECT: TIMER_L=ACC]
    LOAD TIMER_L       // [2] CPU Halts here until timer hits 0! // [EXPECT: ACC=TIMER_L]
    
    LOADI 8            // [2] // [EXPECT: ACC=8]
    STORE R4           // [2] R4 = Bit counter (8) // [EXPECT: R4=ACC]

BIT_LOOP:
    LOAD R2            // [2] // [EXPECT: ACC=R2]
    SHR                // [1] Shift right. LSB -> Carry Flag // [EXPECT: ACC=ACC>>1]
    STORE R2           // [2] // [EXPECT: R2=ACC]
    JMPC SEND_ONE      // [3] Jump if Carry == 1
    
SEND_ZERO:
    SET0 0             // [2]
    JMP WAIT_BIT       // [3]
    
SEND_ONE:
    SET1 0             // [2]

WAIT_BIT:
    LOAD R6            // [2] // [EXPECT: ACC=R6]
    STORE TIMER_L      // [2] Start timer // [EXPECT: TIMER_L=ACC]
    LOAD TIMER_L       // [2] CPU Halts until 0! // [EXPECT: ACC=TIMER_L]
    
    // Decrement Bit Counter
    LOADI 1            // [2] // [EXPECT: ACC=1]
    STORE B            // [2] // [EXPECT: B=ACC]
    LOAD R4            // [2] // [EXPECT: ACC=R4]
    SUB                // [1] ACC = R4 - 1 // [EXPECT: ACC=ACC-B]
    STORE R4           // [2] // [EXPECT: R4=ACC]
    JMPNZ BIT_LOOP     // [3] Jump to BIT_LOOP if not zero!
    
    // Stop Bit
    SET1 0             // [2]
    LOAD R6            // [2] // [EXPECT: ACC=R6]
    STORE TIMER_L      // [2] // [EXPECT: TIMER_L=ACC]
    LOAD TIMER_L       // [2] CPU Halts until 0! // [EXPECT: ACC=TIMER_L]
    
    JMP START          // [3] Loop back for next byte
