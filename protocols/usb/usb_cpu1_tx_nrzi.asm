// CPU 1: USB TX NRZI & Pin Driver
    LOADI 3
    STORE PIN_DIR      // Set Pin 0 and Pin 1 as Output

    // Initial state: Idle (J State)
    LOADI 0
    STORE R2           // R2 = 0 (J State)
    
    SET1 1             // SET pin 1 (D-)
    SET0 0             // CLEAR pin 0 (D+)

WAIT_FIRST_BIT:
    LOAD FLAGS
    STORE B
    LOADI 8            // SHARED_1 Valid mask
    AND B
    JMPNZ PROCESS_BIT
    JMP WAIT_FIRST_BIT

BIT_LOOP:
    // Timer delay: Wait for exactly 33 cycles per bit.
    LOADI 15
    STORE TIMER_L

WAIT_TIMER:
    LOAD TIMER_L
    JMPNZ WAIT_TIMER
    
WAIT_NEXT_BIT:
    LOAD FLAGS
    STORE B
    LOADI 8            // SHARED_1 Valid mask
    AND B
    JMPNZ PROCESS_BIT
    JMP WAIT_NEXT_BIT

PROCESS_BIT:
    LOAD SHARED_1      // Hardware clears valid flag
    JMPNZ TOGGLE_CHECK
    JMP TOGGLE_STATE   // If 0, toggle state (NRZI)
    
TOGGLE_CHECK:
    STORE B
    LOADI 1
    SUB B
    JMPNZ EOP_SEQUENCE
    JMP HOLD_STATE     // If 1, hold state
    
    // Otherwise it's 2 (EOP)
EOP_SEQUENCE:
    // End Of Packet: Drive SE0 for 2 bit times.
    SET0 0             // CLEAR pin 0
    SET0 1             // CLEAR pin 1
    
    LOADI 21
    STORE TIMER_L
EOP_WAIT1:
    LOAD TIMER_L
    JMPNZ EOP_WAIT1
    
    LOADI 21
    STORE TIMER_L
EOP_WAIT2:
    LOAD TIMER_L
    JMPNZ EOP_WAIT2
    
    // Drive J State for 1 bit time
    SET0 0             // CLEAR pin 0
    SET1 1             // SET pin 1
    LOADI 21
    STORE TIMER_L
EOP_WAIT3:
    LOAD TIMER_L
    JMPNZ EOP_WAIT3
    
    JMP WAIT_FIRST_BIT

TOGGLE_STATE:
    LOADI 1
    STORE B
    LOAD R2
    XOR B
    STORE R2
    JMPNZ DRIVE_K
    
DRIVE_J:
    SET1 1
    SET0 0
    JMP BIT_LOOP
    
DRIVE_K:
    SET0 1
    SET1 0
    JMP BIT_LOOP

HOLD_STATE:
    JMP BIT_LOOP
