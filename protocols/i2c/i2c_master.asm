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
    LOADI 1 // [EXPECT: ACC=1]
    STORE PIN_DIR // [EXPECT: PIN_DIR=ACC]
    
    // Hold START condition so slow software slaves can detect it
    LOADI 15 // [EXPECT: ACC=15]
    STORE R5 // [EXPECT: R5=ACC]
    LOADI 1 // [EXPECT: ACC=1]
    STORE B // [EXPECT: B=ACC]
START_DELAY:
    LOAD R5 // [EXPECT: ACC=R5]
    SUB // [EXPECT: ACC=ACC-B]
    STORE R5 // [EXPECT: R5=ACC]
    JMPNZ START_DELAY
    
    // SDA Output 0, SCL Output 0 -> SCL goes Low
    LOADI 3 // [EXPECT: ACC=3]
    STORE PIN_DIR // [EXPECT: PIN_DIR=ACC]

WRITE_BYTE:
    LOAD RX_FIFO       // [2] Block until Host sends data // [EXPECT: ACC=RX_FIFO]
    STORE R2           // [2] // [EXPECT: R2=ACC]
    
    LOADI 8 // [EXPECT: ACC=8]
    STORE R3           // [2] Bit counter // [EXPECT: R3=ACC]

BIT_LOOP:
    LOADI 12          // 12 iterations // [EXPECT: ACC=12]
    STORE R5 // [EXPECT: R5=ACC]
DELAY_LOW:
    LOAD R5 // [EXPECT: ACC=R5]
    SUB // [EXPECT: ACC=ACC-B]
    STORE R5 // [EXPECT: R5=ACC]
    JMPNZ DELAY_LOW

    LOAD R2 // [EXPECT: ACC=R2]
    SHL                // [1] MSB -> Carry // [EXPECT: ACC=ACC<<1]
    STORE R2 // [EXPECT: R2=ACC]
    JMPC SEND_ONE      // [3]

SEND_ZERO:
    // Drive SDA Low (SCL is already Low)
    LOADI 3            // Both Output (SCL=0, SDA=0) // [EXPECT: ACC=3]
    STORE R4           // Save for SCL Low state // [EXPECT: R4=ACC]
    STORE PIN_DIR // [EXPECT: PIN_DIR=ACC]
    // Release SCL (SCL High-Z)
    LOADI 1            // SCL Input, SDA Output // [EXPECT: ACC=1]
    STORE PIN_DIR // [EXPECT: PIN_DIR=ACC]
    JMP CLK_STRETCH

SEND_ONE:
    // Release SDA (SCL is already Low)
    LOADI 2            // SCL Output, SDA Input // [EXPECT: ACC=2]
    STORE R4           // Save for SCL Low state // [EXPECT: R4=ACC]
    STORE PIN_DIR // [EXPECT: PIN_DIR=ACC]
    // Release SCL (Both High-Z)
    LOADI 0 // [EXPECT: ACC=0]
    STORE PIN_DIR // [EXPECT: PIN_DIR=ACC]

    // Wait for SCL to be HIGH (Pin 1 == 1)
CLK_STRETCH:
    LOADI 2 // [EXPECT: ACC=2]
    STORE B // [EXPECT: B=ACC]
    LOAD PIN_STATE // [EXPECT: ACC=PIN_STATE]
    AND B
    JMPNZ SCL_HIGH
    JMP CLK_STRETCH    // Slave is pulling SCL Low! Wait!

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
    // Pull SCL Low again to finish clock pulse
    LOAD R4 // [EXPECT: ACC=R4]
    STORE PIN_DIR // [EXPECT: PIN_DIR=ACC]
    
    // Loop mgmt
    LOADI 1 // [EXPECT: ACC=1]
    STORE B // [EXPECT: B=ACC]
    LOAD R3 // [EXPECT: ACC=R3]
    SUB // [EXPECT: ACC=ACC-B]
    STORE R3 // [EXPECT: R3=ACC]
    JMPNZ BIT_LOOP     // [3]
    
    // (Omitted ACK check for brevity)
    JMP WRITE_BYTE     // [3]
