// ==========================================
// I2C Slave (Receive Byte)
// Emulates I2C Slave on Pin 0 (SDA) and Pin 1 (SCL)
// ==========================================
// Note: Fits in 128 nibbles by omitting WAIT_FOR_IDLE. 
// Assumes point-to-point bus (no other slaves).

START:
    LOADI 0
    STORE PIN_DIR      // Set both pins to Input (High-Z)

WAIT_START:
    // Wait for SCL=1, SDA=0 (Binary 2)
    LOADI 3
    STORE B
    LOAD PIN_STATE
    AND B
    STORE R2           // Save (PIN_STATE & 3) in R2
    LOADI 2
    STORE B
    LOAD R2            // Restore ACC
    SUB
    JMPNZ WAIT_START

READ_BYTE:
    LOADI 8
    STORE R3           // Bit counter
    LOADI 0
    STORE R2           // Initialize accumulator to 0

BIT_LOOP:
    // Wait for SCL LOW (Bit 1 == 0)
WAIT_SCL_LOW:
    LOADI 2
    STORE B
    LOAD PIN_STATE
    AND B
    JMPNZ WAIT_SCL_LOW
    
    // Wait for SCL HIGH
WAIT_SCL_HIGH:
    LOADI 2
    STORE B
    LOAD PIN_STATE
    AND B
    JMPNZ SCL_IS_HIGH
    JMP WAIT_SCL_HIGH
    
SCL_IS_HIGH:
    // Shift R2 left
    LOAD R2
    SHL
    STORE R2
    
    // Read SDA
    LOADI 1
    STORE B
    LOAD PIN_STATE
    AND B
    STORE B            // B = new bit
    
    // Add bit to R2
    LOAD R2
    ADD
    STORE R2
    
    // Decrement Counter
    LOADI 1
    STORE B
    LOAD R3
    SUB
    STORE R3
    JMPNZ BIT_LOOP
    
    // Send received byte to Host
    LOAD R2
    STORE TX_FIFO
    
    // Wait for next byte
    JMP START
