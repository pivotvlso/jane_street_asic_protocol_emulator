// ==========================================
// Ethernet CPU 0: RX Edge Detector (Manchester)
// Emulates 10BASE-T Manchester decoding.
// Syncs to data edges, skips clock edges using 3/4 T delay.
// Pushes decoded bits (1=0, 2=1) to SHARED_0.
// ==========================================

    // Get 3/4 Bit Time Delay from Host
    LOAD RX_FIFO 
    STORE R7 // [EXPECT: R7=ACC]

    // Initialize Old State
    LOAD PIN_STATE // [EXPECT: ACC=PIN_STATE]
    STORE B // [EXPECT: B=ACC]
    LOADI 1 Mask Pin 0 // [EXPECT: ACC=1 Mask Pin 0]
    AND B
    STORE R2 R2 = Old State

WAIT_EDGE:
    LOAD PIN_STATE // [EXPECT: ACC=PIN_STATE]
    STORE B // [EXPECT: B=ACC]
    LOADI 1 // [EXPECT: ACC=1]
    AND B
    STORE R3 // [EXPECT: R3=ACC]
    
    STORE B // [EXPECT: B=ACC]
    LOAD R2 // [EXPECT: ACC=R2]
    SUB // [EXPECT: ACC=ACC-B]
    JMPNZ EDGE_FOUND
    JMP WAIT_EDGE

EDGE_FOUND:
    // Update Old State
    LOAD R3 // [EXPECT: ACC=R3]
    STORE R2 // [EXPECT: R2=ACC]

    // Send Bit to CPU 1
    // New state IS the bit! (High-to-Low = 0, Low-to-High = 1)
    LOAD R3 // [EXPECT: ACC=R3]
    STORE SHARED_0 

    // Wait 3/4 Bit Time to skip potential clock edge
    LOAD R7 // [EXPECT: ACC=R7]
    STORE TIMER_L 
    LOAD TIMER_L 

    // Update Old State to ignore clock edge during sleep
    LOAD PIN_STATE // [EXPECT: ACC=PIN_STATE]
    STORE B // [EXPECT: B=ACC]
    LOADI 1 // [EXPECT: ACC=1]
    AND B
    STORE R2 // [EXPECT: R2=ACC]

    JMP WAIT_EDGE      // [3]
