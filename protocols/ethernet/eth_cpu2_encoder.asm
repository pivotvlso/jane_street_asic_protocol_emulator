// ==========================================
// Ethernet CPU 2: Manchester Encoder
// Reads bits from SHARED_0 (1 = bit 0, 2 = bit 1).
// Encodes them and pushes state to SHARED_1 for CPUs 0 & 1.
// State 1 = TX+ HIGH, TX- LOW
// State 2 = TX+ LOW, TX- HIGH
// ==========================================

    LOADI 0 // [EXPECT: ACC=0]
    STORE SHARED_1 

START:
    // Wait for bit from CPU 3
    LOAD SHARED_0      // [2] 
    STORE B            // [2] // [EXPECT: B=ACC]
    LOADI 0            // [2] // [EXPECT: ACC=0]
    SUB                // [1] // [EXPECT: ACC=ACC-B]
    JMPNZ PROCESS      // [3]
    JMP START          // [3]

PROCESS:
    // Clear SHARED_0 to acknowledge
    LOADI 0            // [2] // [EXPECT: ACC=0]
    STORE SHARED_0     // [2] 

    // Determine Bit
    LOADI 1            // [2] // [EXPECT: ACC=1]
    SUB                // [1] ACC = 1 - B // [EXPECT: ACC=ACC-B]
    JMPNZ BIT_1        // [3] If B!=1 (it's 2), go to BIT_1

BIT_0:
    // IEEE 802.3 Logic 0: HIGH to LOW transition
    // First Half: TX+ HIGH (State 1)
    LOADI 1            // [2] // [EXPECT: ACC=1]
    STORE SHARED_1     // [2] Tell Drivers! 

    // Wait half-bit time (approx 20 cycles)
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP

    // Second Half: TX+ LOW (State 2)
    LOADI 2            // [2] // [EXPECT: ACC=2]
    STORE SHARED_1     // [2] 

    // Wait half-bit time
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    JMP DONE           // [3]

BIT_1:
    // IEEE 802.3 Logic 1: LOW to HIGH transition
    // First Half: TX+ LOW (State 2)
    LOADI 2            // [2] // [EXPECT: ACC=2]
    STORE SHARED_1     // [2] 

    // Wait half-bit time
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP

    // Second Half: TX+ HIGH (State 1)
    LOADI 1            // [2] // [EXPECT: ACC=1]
    STORE SHARED_1     // [2] 

    // Wait half-bit time
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    JMP DONE           // [3]

DONE:
    // Clear drivers (optional, or just leave in last state)
    // LOADI 0
    // STORE SHARED_1
    JMP START          // [3]
