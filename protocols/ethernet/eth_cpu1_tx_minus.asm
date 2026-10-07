// ==========================================
// Ethernet CPU 1: TX- Push-Pull Driver
// Reads SHARED_1. 
// If SHARED_1 == 1, drives TX- (Pin 1) LOW
// If SHARED_1 == 2, drives TX- (Pin 1) HIGH
// ==========================================

    // Initialize Pin 1 as Output
    LOADI 2 // [EXPECT: ACC=2]
    STORE PIN_DIR // [EXPECT: PIN_DIR=ACC]

START:
    LOAD SHARED_1      // [2] 
    STORE B            // [2] // [EXPECT: B=ACC]
    LOADI 0            // [2] // [EXPECT: ACC=0]
    SUB                // [1] ACC = 0 - B // [EXPECT: ACC=ACC-B]
    JMPNZ PROCESS      // [3] If B != 0, go process
    JMP START          // [3] Else loop

PROCESS:
    LOADI 1            // [2] // [EXPECT: ACC=1]
    SUB                // [1] ACC = 1 - B // [EXPECT: ACC=ACC-B]
    JMPNZ DRIVE_2      // [3] If B != 1, it must be 2

DRIVE_1:
    SET0 1             // [2] Drive TX- LOW
    JMP DONE           // [3]

DRIVE_2:
    SET1 1             // [2] Drive TX- HIGH
    NOP                // [1] Balance cycles with JMP DONE
    NOP                // [1] 
    NOP                // [1]

DONE:
    // Wait for SHARED_1 to return to 0 before looping back
WAIT_CLEAR:
    LOAD SHARED_1      // [2] 
    STORE B            // [2] // [EXPECT: B=ACC]
    LOADI 0            // [2] // [EXPECT: ACC=0]
    SUB                // [1] // [EXPECT: ACC=ACC-B]
    JMPNZ WAIT_CLEAR   // [3] Loop if not zero

    JMP START          // [3]
