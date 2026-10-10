// ==========================================
// Ethernet CPU 0: TX+ Push-Pull Driver
// Reads SHARED_1. 
// If SHARED_1 == 1, drives TX+ (Pin 0) HIGH
// If SHARED_1 == 2, drives TX+ (Pin 0) LOW
// ==========================================

    // Initialize Pin 0 as Output
    LOADI 1 // [EXPECT: ACC=1]
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
    SET1 0             // [2] Drive TX+ HIGH
    JMP DONE           // [3]

DRIVE_2:
    SET0 0             // [2] Drive TX+ LOW
    NOP                // [1] Balance cycles with JMP DONE
    NOP                // [1] 
    NOP                // [1]

DONE:
    JMP START          // [3]
