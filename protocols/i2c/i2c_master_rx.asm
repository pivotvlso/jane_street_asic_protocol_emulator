// ==========================================
// I2C Master RX (Read Byte)
// Emulates I2C on Pin 0 (SDA) and Pin 1 (SCL)
// ==========================================

    // Start with SCL Low, SDA High-Z
    LOADI 2            // SCL=Output(0), SDA=Input(Z) // [EXPECT: ACC=2]
    STORE PIN_DIR // [EXPECT: PIN_DIR=ACC]

READ_BYTE:
    LOAD RX_FIFO       // Block until Host triggers read // [EXPECT: ACC=RX_FIFO]
    LOADI 0 // [EXPECT: ACC=0]
    STORE R2           // Accumulator for received byte // [EXPECT: R2=ACC]
    LOADI 8 // [EXPECT: ACC=8]
    STORE R3           // Bit counter // [EXPECT: R3=ACC]

BIT_LOOP:
    // Release SCL (Both High-Z) -> SCL goes High
    LOADI 0 // [EXPECT: ACC=0]
    STORE PIN_DIR // [EXPECT: PIN_DIR=ACC]

    // Wait for SCL to be HIGH (Pin 1 == 1) for clock stretching
CLK_STRETCH:
    LOADI 2 // [EXPECT: ACC=2]
    STORE B // [EXPECT: B=ACC]
    LOAD PIN_STATE // [EXPECT: ACC=PIN_STATE]
    AND B
    JMPNZ SCL_HIGH
    JMP CLK_STRETCH

SCL_HIGH:
    // Hold SCL High for a while
    LOADI 6 // [EXPECT: ACC=6]
    STORE R5 // [EXPECT: R5=ACC]
    LOADI 1 // [EXPECT: ACC=1]
    STORE B // [EXPECT: B=ACC]
DELAY_HIGH:
    LOAD R5 // [EXPECT: ACC=R5]
    SUB // [EXPECT: ACC=ACC-B]
    STORE R5 // [EXPECT: R5=ACC]
    JMPNZ DELAY_HIGH

    // Sample SDA (Pin 0)
    LOADI 1 // [EXPECT: ACC=1]
    STORE B // [EXPECT: B=ACC]
    LOAD PIN_STATE // [EXPECT: ACC=PIN_STATE]
    AND B
    STORE R6           // Save sampled bit // [EXPECT: R6=ACC]

    // Shift Accumulator Left
    LOAD R2 // [EXPECT: ACC=R2]
    SHL // [EXPECT: ACC=ACC<<1]
    STORE R2 // [EXPECT: R2=ACC]

    // Add sampled bit
    LOAD R6 // [EXPECT: ACC=R6]
    STORE B // [EXPECT: B=ACC]
    LOAD R2 // [EXPECT: ACC=R2]
    ADD // [EXPECT: ACC=ACC+B]
    STORE R2 // [EXPECT: R2=ACC]

    // Pull SCL Low again
    LOADI 2 // [EXPECT: ACC=2]
    STORE PIN_DIR // [EXPECT: PIN_DIR=ACC]

    // Delay Low
    LOADI 12 // [EXPECT: ACC=12]
    STORE R5 // [EXPECT: R5=ACC]
    LOADI 1 // [EXPECT: ACC=1]
    STORE B // [EXPECT: B=ACC]
DELAY_LOW:
    LOAD R5 // [EXPECT: ACC=R5]
    SUB // [EXPECT: ACC=ACC-B]
    STORE R5 // [EXPECT: R5=ACC]
    JMPNZ DELAY_LOW

    // Loop mgmt
    LOADI 1 // [EXPECT: ACC=1]
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
