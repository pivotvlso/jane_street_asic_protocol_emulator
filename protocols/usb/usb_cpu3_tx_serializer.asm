// CPU 3: USB TX Serializer (Low-Speed 1.5 Mbps)
    LOADI 0
    STORE R3           // Idle state dummy

START:
    LOAD RX_FIFO
    STORE R2           // Data Byte
    
    // Check if EOP marker (0xFE)
    LOADIB 254
    LOAD R2
    SUB B
    JMPNZ EOP_NOT_MATCH
    JMP SEND_EOP
EOP_NOT_MATCH:
    
    LOADI 8
    STORE R3           // Bit counter

BIT_LOOP:
WAIT_CPU2:
    LOAD FLAGS
    STORE B
    LOADI 4            // SHARED_0 Valid mask (Bit 2)
    AND B
    JMPNZ WAIT_CPU2
    
    // Extract LSB
    LOAD R2
    STORE B
    LOADI 1
    AND B
    STORE SHARED_0     // Push to CPU 2
    
    // Shift R2 right
    LOAD R2
    SHR
    STORE R2
    
    // Decrement counter
    LOADI 1
    STORE B
    LOAD R3
    SUB B
    STORE R3
    
    JMPNZ BIT_LOOP
    JMP START

SEND_EOP:
WAIT_CPU2_EOP:
    LOAD FLAGS
    STORE B
    LOADI 4            // SHARED_0 Valid mask (Bit 2)
    AND B
    JMPNZ WAIT_CPU2_EOP
    
    LOADI 2            // EOP
    STORE SHARED_0     // Push to CPU 2
    
    JMP START
