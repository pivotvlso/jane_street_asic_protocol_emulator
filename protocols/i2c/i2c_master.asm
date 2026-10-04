// ==========================================
// I2C Master (Start & Write Byte)
// Emulates I2C on Pin 0 (SDA) and Pin 1 (SCL)
// ==========================================
// I2C requires Open-Drain pins. We achieve this by writing to PIN_DIR.
// 1 = Output (Driven Low via SET0), 0 = Input (High-Z, Pulled High)

START_COND:
    // Drive 0 on both pins (preps for open-drain toggling)
    SET0 0
    SET0 1

    // Release both pins (High-Z) -> SCL High, SDA High
    // (At reset, PIN_DIR is already 0, so pins are High-Z)
    
    // SDA Output 0, SCL High-Z -> Start Condition! (SDA goes Low while SCL High)
    LOADI 1
    STORE PIN_DIR
    
    // Hold START condition so slow software slaves can detect it
    LOADI 15
    STORE R5
    LOADI 1
    STORE B
START_DELAY:
    LOAD R5
    SUB
    STORE R5
    JMPNZ START_DELAY
    
    // SDA Output 0, SCL Output 0 -> SCL goes Low
    LOADI 3
    STORE PIN_DIR

WRITE_BYTE:
    LOAD RX_FIFO       // [2] Block until Host sends data
    STORE R2           // [2]
    
    LOADI 8
    STORE R3           // [2] Bit counter

BIT_LOOP:
    LOADI 12          // 12 iterations
    STORE R5
DELAY_LOW:
    LOAD R5
    SUB
    STORE R5
    JMPNZ DELAY_LOW

    LOAD R2
    SHL                // [1] MSB -> Carry
    STORE R2
    JMPC SEND_ONE      // [3]

SEND_ZERO:
    // Drive SDA Low (SCL is already Low)
    LOADI 3            // Both Output (SCL=0, SDA=0)
    STORE R4           // Save for SCL Low state
    STORE PIN_DIR
    // Release SCL (SCL High-Z)
    LOADI 1            // SCL Input, SDA Output
    STORE PIN_DIR
    JMP CLK_STRETCH

SEND_ONE:
    // Release SDA (SCL is already Low)
    LOADI 2            // SCL Output, SDA Input
    STORE R4           // Save for SCL Low state
    STORE PIN_DIR
    // Release SCL (Both High-Z)
    LOADI 0
    STORE PIN_DIR

    // Wait for SCL to be HIGH (Pin 1 == 1)
CLK_STRETCH:
    LOADI 2
    STORE B
    LOAD PIN_STATE
    AND B
    JMPNZ SCL_HIGH
    JMP CLK_STRETCH    // Slave is pulling SCL Low! Wait!

SCL_HIGH:
    // Hold SCL High for a while
    LOADI 6
    STORE R5
    LOADI 1
    STORE B
DELAY_HIGH:
    LOAD R5
    SUB
    STORE R5
    JMPNZ DELAY_HIGH
    // Pull SCL Low again to finish clock pulse
    LOAD R4
    STORE PIN_DIR
    
    // Loop mgmt
    LOADI 1
    STORE B
    LOAD R3
    SUB
    STORE R3
    JMPNZ BIT_LOOP     // [3]
    
    // (Omitted ACK check for brevity)
    JMP WRITE_BYTE     // [3]
