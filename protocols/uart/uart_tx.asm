// ==========================================
// UART Transmitter (8N1)
// Emulates a standard UART TX on Pin 0
// ==========================================
// Size: 64 Nibbles (Exactly 100% full!)

BOOT:
    SET1 0             // [2] Initialize UART TX to IDLE HIGH
    LOADI 1            // [2]
    STORE PIN_DIR      // [2] Set Pin 0 to Output
    
    LOAD RX_FIFO       // [2] Wait for Host to send Baud Rate config
    STORE R8           // [2] Save to R8

START:
    LOAD RX_FIFO       // [2] Block until Host sends data
    STORE R2           // [2] R2 = Data
    
    SET0 0             // [2] Start bit (LOW)
    LOAD R8            // [2] Load baud delay
    STORE TIMER_L      // [2] Start timer
    LOAD TIMER_L       // [2] CPU Halts here until timer hits 0!
    
    LOADI 8            // [2]
    STORE R4           // [2] R4 = Bit counter (8)

BIT_LOOP:
    LOAD R2            // [2]
    SHR                // [1] Shift right. LSB -> Carry Flag
    STORE R2           // [2]
    JMPC SEND_ONE      // [3] Jump if Carry == 1
    
SEND_ZERO:
    SET0 0             // [2]
    JMP WAIT_BIT       // [3]
    
SEND_ONE:
    SET1 0             // [2]

WAIT_BIT:
    LOAD R8            // [2]
    STORE TIMER_L      // [2] Start timer
    LOAD TIMER_L       // [2] CPU Halts until 0!
    
    // Decrement Bit Counter
    LOADI 1            // [2]
    STORE B            // [2]
    LOAD R4            // [2]
    SUB                // [1] ACC = R4 - 1
    STORE R4           // [2]
    JMPNZ BIT_LOOP     // [3] Jump to BIT_LOOP if not zero!
    
    // Stop Bit
    SET1 0             // [2]
    LOAD R8            // [2]
    STORE TIMER_L      // [2]
    LOAD TIMER_L       // [2] CPU Halts until 0!
    
    JMP START          // [3] Loop back for next byte
