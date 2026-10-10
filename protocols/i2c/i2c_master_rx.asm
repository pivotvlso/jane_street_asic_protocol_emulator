// ==========================================
// I2C Master RX (Read Byte)
// Emulates I2C on Pin 0 (SDA) and Pin 1 (SCL)
// ==========================================

    // Start with SCL Low, SDA High-Z
    LOAD R7            // SCL=Output(0), SDA=Input(Z) // [EXPECT: ACC=2]
    STORE PIN_DIR // [EXPECT: PIN_DIR=ACC]

READ_BYTE:
    // Cache constants to avoid exceeding OP2 limit
    LOADI 1
    STORE R6
    LOADI 2
    STORE R7
    LOADI 3
    STORE R4

    LOAD RX_FIFO       // Block until Host triggers read // [EXPECT: ACC=RX_FIFO]
    STORE B
    SUB
    STORE R2           // Accumulator for received byte // [EXPECT: R2=ACC]
    LOADI 8 // [EXPECT: ACC=8]
    STORE R3           // Bit counter // [EXPECT: R3=ACC]

BIT_LOOP:
    // Release SCL (Both High-Z) -> SCL goes High
    STORE B
    SUB
    STORE PIN_DIR // [EXPECT: PIN_DIR=ACC]

    // Wait for SCL to be HIGH (Pin 1 == 1) for clock stretching
    LOADI 255
    STORE TIMER_L
CLK_STRETCH:
    LOAD R7 // [EXPECT: ACC=2]
    STORE B // [EXPECT: B=ACC]
    LOAD PIN_STATE // [EXPECT: ACC=PIN_STATE]
    AND B
    JMPNZ SCL_HIGH
    
    LOAD TIMER_L
    JMPNZ CLK_STRETCH
    
    // Timeout Error! Release bus and retry
    STORE B
    SUB
    STORE PIN_DIR
    JMP READ_BYTE

SCL_HIGH:
    // Hold SCL High for a while
    LOADI 24
    STORE TIMER_L
DELAY_HIGH:
    LOAD TIMER_L
    JMPNZ DELAY_HIGH

    // Shift Accumulator Left
    LOAD R2
    SHL
    STORE R2

    // Sample SDA (Pin 0)
    LOAD R6
    STORE B
    LOAD PIN_STATE
    AND B
    
    // Add sampled bit
    STORE B
    LOAD R2
    ADD
    STORE R2

    // Pull SCL Low again
    LOAD R7 // [EXPECT: ACC=2]
    STORE PIN_DIR // [EXPECT: PIN_DIR=ACC]

    // Delay Low
    LOADI 48
    STORE TIMER_L
DELAY_LOW:
    LOAD TIMER_L
    JMPNZ DELAY_LOW

    // Loop mgmt
    LOAD R6 // [EXPECT: ACC=1]
    STORE B // [EXPECT: B=ACC]
    LOAD R3 // [EXPECT: ACC=R3]
    SUB // [EXPECT: ACC=ACC-B]
    STORE R3 // [EXPECT: R3=ACC]
    JMPNZ BIT_LOOP

    // Push received byte to Host
    LOAD R2 // [EXPECT: ACC=R2]
    STORE TX_FIFO // [EXPECT: TX_FIFO=ACC]

    // Jump to next byte (ACK/NACK logic omitted)
    JMP READ_BYTE
