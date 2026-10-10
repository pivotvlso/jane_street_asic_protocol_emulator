// ==========================================
// Ethernet CPU 2: Manchester Encoder
// Reads bits from SHARED_0 (1 = bit 0, 2 = bit 1).
// Encodes them and pushes state to SHARED_1 for CPUs 0 & 1.
// State 1 = TX+ HIGH, TX- LOW
// State 2 = TX+ LOW, TX- HIGH
// ==========================================

    LOADI 4
    STORE R4           // Bit 2 (SHARED_0 Valid) mask
    LOADI 8
    STORE R5           // Bit 3 (SHARED_1 Valid) mask 

START:
    // Wait for bit from CPU 3
    LOAD FLAGS         // [2] 
    STORE B            // [2] 
    LOAD R4            // [2] 
    AND B              // [1] 
    JMPNZ PROCESS
    JMP START          // [3] Loop if SHARED_0_valid is 0

PROCESS:
    // Read SHARED_0 (Hardware automatically clears valid flag)
    LOAD SHARED_0      // [2]  

    STORE B            // [2] // [EXPECT: B=ACC]
    LOADI 1            // [2] // [EXPECT: ACC=1]
    AND B              // [1] 
    JMPNZ BIT_1        // [3] If B==1, go to BIT_1

BIT_0:
    // Wait for Drivers to be ready
WAIT_DRV1:
    LOAD FLAGS
    STORE B
    LOAD R5
    AND B
    JMPNZ WAIT_DRV1    // Loop if SHARED_1_valid is 1

    // First Half: TX+ HIGH (State 1)
    LOADI 1            // [2] // [EXPECT: ACC=1]
    STORE SHARED_1     // [2] Tell Drivers! 

    // Wait half-bit time
    NOP
    NOP
    NOP
    NOP

WAIT_DRV2:
    LOAD FLAGS
    STORE B
    LOAD R5
    AND B
    JMPNZ WAIT_DRV2

    // Second Half: TX+ LOW (State 2)
    LOADI 2            // [2] // [EXPECT: ACC=2]
    STORE SHARED_1     // [2] 

    // Wait half-bit time
    NOP
    NOP
    NOP
    NOP
    JMP DONE           // [3]

BIT_1:
WAIT_DRV3:
    LOAD FLAGS
    STORE B
    LOAD R5
    AND B
    JMPNZ WAIT_DRV3

    // First Half: TX+ LOW (State 2)
    LOADI 2            // [2] // [EXPECT: ACC=2]
    STORE SHARED_1     // [2] 

    // Wait half-bit time
    NOP
    NOP
    NOP
    NOP

WAIT_DRV4:
    LOAD FLAGS
    STORE B
    LOAD R5
    AND B
    JMPNZ WAIT_DRV4

    // Second Half: TX+ HIGH (State 1)
    LOADI 1            // [2] // [EXPECT: ACC=1]
    STORE SHARED_1     // [2] 

    // Wait half-bit time
    NOP
    NOP
    NOP
    NOP
    JMP DONE           // [3]

DONE:
    JMP START          // [3]
