// CPU 2: USB TX Bit Stuffer (Low-Speed)
    LOADI 0
    STORE R3           // R3 = Consecutive 1s counter

WAIT_IN_BIT:
    LOAD FLAGS
    STORE B
    LOADI 4            // SHARED_0 Valid mask (Bit 2)
    AND B
    JMPNZ PROCESS_IN_BIT
    JMP WAIT_IN_BIT

PROCESS_IN_BIT:
    LOAD SHARED_0      // Clears valid flag
    STORE R2           // Save the bit

    JMPNZ IN_BIT_NOT_ZERO
    JMP HANDLE_ZERO

IN_BIT_NOT_ZERO:
    STORE B
    LOADI 1
    SUB B
    JMPNZ HANDLE_EOP
    JMP HANDLE_ONE
    
HANDLE_EOP:
    LOADI 0
    STORE R3           // Reset counter
    LOADI 2            // Push EOP
    JMP PUSH_OUT_BIT

HANDLE_ZERO:
    LOADI 0
    STORE R3           // Reset counter
    LOAD R2            // Load 0
    JMP PUSH_OUT_BIT
    
HANDLE_ONE:
    LOADI 1
    STORE B
    LOAD R3
    ADD B
    STORE R3           // Counter++
    
    STORE B
    LOADI 6
    SUB B              // If Counter == 6, need to stuff
    JMPNZ NO_STUFF
    JMP STUFF_BIT
NO_STUFF:
    
    LOAD R2            // Load 1
    JMP PUSH_OUT_BIT

STUFF_BIT:
WAIT_STUFF_OUT:
    LOAD FLAGS
    STORE B
    LOADI 8            // SHARED_1 Valid mask (Bit 3)
    AND B
    JMPNZ WAIT_STUFF_OUT
    
    LOADI 0
    STORE SHARED_1     // Push stuffed 0
    
    LOADI 0
    STORE R3           // Reset counter
    
    LOADI 1            // Now push the original 1
    // Fallthrough to PUSH_OUT_BIT

PUSH_OUT_BIT:
    STORE R2           // Save bit to push
    
WAIT_OUT:
    LOAD FLAGS
    STORE B
    LOADI 8            // SHARED_1 Valid mask (Bit 3)
    AND B
    JMPNZ WAIT_OUT
    
    LOAD R2
    STORE SHARED_1
    
    JMP WAIT_IN_BIT
