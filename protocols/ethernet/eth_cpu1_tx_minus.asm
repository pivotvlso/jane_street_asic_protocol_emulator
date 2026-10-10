// ==========================================
// Ethernet CPU 1: TX- Push-Pull Driver
// Reads SHARED_1. 
// If SHARED_1 == 1, drives TX- (Pin 1) LOW
// If SHARED_1 == 2, drives TX- (Pin 1) HIGH
// ==========================================

    // Initialize Pin 1 as Output
    LOADI 2 // [EXPECT: ACC=2]
    STORE PIN_DIR // [EXPECT: PIN_DIR=ACC]
    LOADI 8
    STORE R5           // Bit 3 (SHARED_1 Valid) mask

START:
    LOAD FLAGS         // [2] 
    STORE B            // [2] 
    LOAD R5            // [2] 
    AND B              // [1] 
    JMPNZ PROCESS      // [3] Wait until SHARED_1 is valid
    JMP START

PROCESS:
    LOAD SHARED_1      // Read SHARED_1 (Hardware automatically clears valid flag)
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
    JMP START          // [3]
