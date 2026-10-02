// ==========================================
// I2C Master (Start & Write Byte)
// Emulates I2C on Pin 0 (SDA) and Pin 1 (SCL)
// ==========================================
// I2C requires Open-Drain pins. We achieve this by writing to PIN_DIR.
// 1 = Output (Driven Low via SET0), 0 = Input (High-Z, Pulled High)

START_COND:
    // Release both pins (High-Z)
    LOADI 0
    STORE PIN_DIR      // [2] Both pins Input (Pulled High by external resistors)
    

    // Pull SDA LOW
    SET0 0             // [2] Drive 0
    LOADI 1            // [2] Set Pin 0 to Output
    STORE PIN_DIR      // [2]
    
    // Pull SCL LOW
    SET0 1             // [2] Drive 0
    LOADI 3            // [2] Set Pins 0 & 1 to Output
    STORE PIN_DIR      // [2]

WRITE_BYTE:
    LOAD RX_FIFO       // [2] Block until Host sends data
    STORE R2           // [2]
    
    LOADI 8
    STORE R3           // [2] Bit counter

BIT_LOOP:
    LOAD R2
    SHL                // [1] MSB -> Carry
    STORE R2
    JMPC SEND_ONE      // [3]
    
SEND_ZERO:
    // Drive SDA Low
    LOADI 3            // [2] Both pins output (SCL=0, SDA=0)
    STORE PIN_DIR
    JMP PULSE_SCL      // [3]
    
SEND_ONE:
    // Release SDA (High-Z)
    LOADI 2            // [2] Pin 1 Output (SCL=0), Pin 0 Input (SDA=High-Z)
    STORE PIN_DIR

PULSE_SCL:
    // Release SCL (High-Z)
    LOADI 0            // [2] Both pins input
    // Wait for Clock Stretching from Slave here (check PIN_STATE)
    
    // Pull SCL Low
    LOADI 2            // [2] Pin 1 Output (SCL=0)
    STORE PIN_DIR
    
    // Loop mgmt
    LOAD R3
    LOADI 1
    STORE B
    SUB
    STORE R3
    JMPNZ BIT_LOOP     // [3]
    
    // (Omitted ACK check for brevity)
    JMP WRITE_BYTE     // [3]
