// ==========================================
// Ethernet CPU 3: TX Serializer
// Reads payload from RX_FIFO.
// Serializes LSB first and pushes to SHARED_0
// Handshake: Waits for SHARED_0 to be 0 before sending next bit.
// Output: 1 for bit=0, 2 for bit=1
// ==========================================

    LOADI 0 // [EXPECT: ACC=0]
    STORE SHARED_0 

START:
    LOAD RX_FIFO       // [2] Block until byte arrives from Host 
    STORE R2           // [2] // [EXPECT: R2=ACC]
    LOADI 8            // [2] // [EXPECT: ACC=8]
    STORE R3           // [2] Bit counter // [EXPECT: R3=ACC]

BIT_LOOP:
WAIT_CPU2:
    LOAD SHARED_0      // [2] Wait for Encoder to consume previous bit 
    JMPNZ WAIT_CPU2    // [3]

    // Extract LSB
    LOAD R2            // [2] // [EXPECT: ACC=R2]
    STORE B            // [2] // [EXPECT: B=ACC]
    LOADI 1            // [2] // [EXPECT: ACC=1]
    AND B              // [1] ACC = 0 or 1
    
    // Map bit=0 to 1, bit=1 to 2 (so 0 means idle/consumed)
    STORE B            // [2] // [EXPECT: B=ACC]
    LOADI 1            // [2] // [EXPECT: ACC=1]
    ADD                // [1] ACC = 1 or 2 // [EXPECT: ACC=ACC+B]
    STORE SHARED_0     // [2] Send to CPU 2 

    // Shift data right
    LOAD R2            // [2] // [EXPECT: ACC=R2]
    SHR                // [1] // [EXPECT: ACC=ACC>>1]
    STORE R2           // [2] // [EXPECT: R2=ACC]

    // Decrement counter
    LOADI 1            // [2] 
    STORE B            // [2] 
    LOAD R3            // [2] 
    SUB                // [1] 
    STORE R3           // [2] 
    
    JMPNZ BIT_LOOP     // [3]
    JMP START          // [3]
