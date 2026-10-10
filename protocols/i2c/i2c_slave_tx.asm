// ==========================================
// I2C Slave TX (Transmit Byte)
// Emulates I2C Slave on Pin 0 (SDA) and Pin 1 (SCL)
// ==========================================

    // Start with SDA Input, SCL Input (High-Z)
    LOADI 0 // [EXPECT: ACC=0]
    STORE PIN_DIR // [EXPECT: PIN_DIR=ACC]

WRITE_BYTE:
    // Cache constants to avoid exceeding OP2 limit
    LOADI 1
    STORE R6
    LOADI 2
    STORE R7
    LOADI 3
    STORE R4

    // Block until Host provides data to send
    LOAD RX_FIFO // [EXPECT: ACC=RX_FIFO]
    STORE R2 // [EXPECT: R2=ACC]

    // 8 bits to send
    LOADI 8 // [EXPECT: ACC=8]
    STORE R3 // [EXPECT: R3=ACC]

BIT_LOOP:
    // Wait for SCL to go LOW before driving SDA
WAIT_SCL_LOW:
    LOAD R7 // [EXPECT: ACC=2]
    STORE B // [EXPECT: B=ACC]
    LOAD PIN_STATE // [EXPECT: ACC=PIN_STATE]
    AND B
    JMPNZ WAIT_SCL_LOW

    // SCL is low. Drive SDA with MSB of R2.
    LOAD R2 // [EXPECT: ACC=R2]
    SHL // [EXPECT: ACC=ACC<<1]
    STORE R2 // [EXPECT: R2=ACC]
    JMPC SEND_ONE

SEND_ZERO:
    // Drive SDA Low (Pin 0 Output)
    LOAD R6 // [EXPECT: ACC=1]
    STORE PIN_DIR // [EXPECT: PIN_DIR=ACC]
    JMP WAIT_SCL_HIGH

SEND_ONE:
    // Release SDA (High-Z)
    LOADI 0 // [EXPECT: ACC=0]
    STORE PIN_DIR // [EXPECT: PIN_DIR=ACC]

    // Wait for Master to pull SCL High
WAIT_SCL_HIGH:
    LOAD R7 // [EXPECT: ACC=2]
    STORE B // [EXPECT: B=ACC]
    LOAD PIN_STATE // [EXPECT: ACC=PIN_STATE]
    AND B
    JMPNZ SCL_IS_HIGH
    JMP WAIT_SCL_HIGH

SCL_IS_HIGH:
    // Wait for Master to pull SCL Low again before next bit
    // This happens naturally by looping back to WAIT_SCL_LOW

    // Loop mgmt
    LOAD R6 // [EXPECT: ACC=1]
    STORE B // [EXPECT: B=ACC]
    LOAD R3 // [EXPECT: ACC=R3]
    SUB // [EXPECT: ACC=ACC-B]
    STORE R3 // [EXPECT: R3=ACC]
    JMPNZ BIT_LOOP

WAIT_SCL_LOW_END:
    LOAD R7 // [EXPECT: ACC=2]
    STORE B // [EXPECT: B=ACC]
    LOAD PIN_STATE // [EXPECT: ACC=PIN_STATE]
    AND B
    JMPNZ WAIT_SCL_LOW_END

    // Release SDA at end of byte
    LOADI 0 // [EXPECT: ACC=0]
    STORE PIN_DIR // [EXPECT: PIN_DIR=ACC]

    JMP WRITE_BYTE
