// ==========================================
// I2C Slave (Receive Byte)
// Emulates I2C Slave on Pin 0 (SDA) and Pin 1 (SCL)
// ==========================================
// Note: Fits in 128 nibbles by omitting WAIT_FOR_IDLE. 
// Assumes point-to-point bus (no other slaves).

START:
    // Cache constants to avoid exceeding OP2 limit
    LOADI 1
    STORE R6
    LOADI 2
    STORE R7
    LOADI 3
    STORE R4

    LOADI 0 // [EXPECT: ACC=0]
    STORE PIN_DIR      // Set both pins to Input (High-Z) // [EXPECT: PIN_DIR=ACC]

WAIT_START:
    // Wait for SCL=1, SDA=0 (Binary 2)
    LOAD R4 // [EXPECT: ACC=3]
    STORE B // [EXPECT: B=ACC]
    LOAD PIN_STATE
    AND B
    STORE R2           // Save (PIN_STATE & 3) in R2 // [EXPECT: R2=ACC]
    LOAD R7 // [EXPECT: ACC=2]
    STORE B // [EXPECT: B=ACC]
    LOAD R2            // Restore ACC // [EXPECT: ACC=R2]
    SUB // [EXPECT: ACC=ACC-B]
    JMPNZ WAIT_START

READ_BYTE:
    LOADI 8 // [EXPECT: ACC=8]
    STORE R3           // Bit counter // [EXPECT: R3=ACC]
    LOADI 0 // [EXPECT: ACC=0]
    STORE R2           // Initialize accumulator to 0 // [EXPECT: R2=ACC]

BIT_LOOP:
    // Wait for SCL LOW (Bit 1 == 0)
WAIT_SCL_LOW:
    LOAD R7 // [EXPECT: ACC=2]
    STORE B // [EXPECT: B=ACC]
    LOAD PIN_STATE // [EXPECT: ACC=PIN_STATE]
    AND B
    JMPNZ WAIT_SCL_LOW
    
    // Wait for SCL HIGH
WAIT_SCL_HIGH:
    LOAD R7 // [EXPECT: ACC=2]
    STORE B // [EXPECT: B=ACC]
    LOAD PIN_STATE // [EXPECT: ACC=PIN_STATE]
    AND B
    JMPNZ SCL_IS_HIGH
    JMP WAIT_SCL_HIGH
    
SCL_IS_HIGH:
    // Shift R2 left
    LOAD R2 // [EXPECT: ACC=R2]
    SHL // [EXPECT: ACC=ACC<<1]
    STORE R2 // [EXPECT: R2=ACC]
    
    // Read SDA
    LOAD R6 // [EXPECT: ACC=1]
    STORE B // [EXPECT: B=ACC]
    LOAD PIN_STATE // [EXPECT: ACC=PIN_STATE]
    AND B
    STORE B            // B = new bit // [EXPECT: B=ACC]
    
    // Add bit to R2
    LOAD R2 // [EXPECT: ACC=R2]
    ADD // [EXPECT: ACC=ACC+B]
    STORE R2 // [EXPECT: R2=ACC]
    
    // Decrement Counter
    LOAD R6 // [EXPECT: ACC=1]
    STORE B // [EXPECT: B=ACC]
    LOAD R3 // [EXPECT: ACC=R3]
    SUB // [EXPECT: ACC=ACC-B]
    STORE R3 // [EXPECT: R3=ACC]
    JMPNZ BIT_LOOP
    
    // Send received byte to Host
    LOAD R2 // [EXPECT: ACC=R2]
    STORE TX_FIFO // [EXPECT: TX_FIFO=ACC]
    
    // Wait for next byte
    JMP START
