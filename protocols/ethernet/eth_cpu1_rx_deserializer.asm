// ==========================================
// Ethernet CPU 1: RX Deserializer
// Reads decoded bits from SHARED_0.
// Shifts them into a byte (LSB first).
// Pushes completed byte to TX_FIFO (to Host).
// ==========================================

    LOADI 4
    STORE R4           // Bit 2 (SHARED_0 Valid) mask 

START:
    LOADI 8 8 bits per byte // [EXPECT: ACC=8 8 bits per byte]
    STORE R3 // [EXPECT: R3=ACC]
    LOADI 0 Byte accumulator // [EXPECT: ACC=0 Byte accumulator]
    STORE R2 // [EXPECT: R2=ACC]

BIT_LOOP:
WAIT_CPU0:
    LOAD FLAGS
    STORE B
    LOAD R4
    AND B
    JMPNZ PROCESS      // Jump out of wait loop if valid bit is 1
    JMP WAIT_CPU0      // Otherwise keep waiting

PROCESS:
    LOAD SHARED_0      // Read bit (Hardware clears valid flag)
    JMPNZ SET_MSB      // If bit is 1, go set MSB
    LOADI 0 Else bit is 0 // [EXPECT: ACC=0 Else bit is 0]
    JMP ADD_TO_ACC

SET_MSB:
    // Shift 1 to MSB (0x80)
    LOADI 8 // [EXPECT: ACC=8]
    STORE B // [EXPECT: B=ACC]
    LOADI 8 // [EXPECT: ACC=8]
    SHL // [EXPECT: ACC=ACC<<1]
    SHL // [EXPECT: ACC=ACC<<1]
    SHL // [EXPECT: ACC=ACC<<1]
    SHL // [EXPECT: ACC=ACC<<1]

ADD_TO_ACC:
    // Add bit to accumulator (which was shifted right)
    STORE B // [EXPECT: B=ACC]
    LOAD R2 // [EXPECT: ACC=R2]
    SHR // [EXPECT: ACC=ACC>>1]
    ADD // [EXPECT: ACC=ACC+B]
    STORE R2 // [EXPECT: R2=ACC]

    STORE R2 // [EXPECT: R2=ACC] 

    // Decrement Counter
    LOADI 1            // [2] 
    STORE B            // [2] 
    LOAD R3            // [2] 
    SUB                // [1] 
    STORE R3           // [2] 
    
    JMPNZ BIT_LOOP     // [3] Loop if not 8 bits yet

    // Byte is complete, push to Host!
    LOAD R2            // [2] // [EXPECT: ACC=R2]
    STORE TX_FIFO      // [2] 
    
    JMP START          // [3]
