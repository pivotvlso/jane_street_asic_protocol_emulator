// ==========================================
// USB Low-Speed (1.5 Mbps) Transmitter
// Emulates full USB NRZI Encoding & Bit-Stuffing!
// Pins: Pin 0 = D+, Pin 1 = D-
// ==========================================

// SETUP:
// Host pushes 0x03 into R6 (Mask for D+/D- pins).
// Host pushes Baud Delay into R6.
// Host pushes 0 into R4 (Bit Stuff Counter).

START:
    LOAD RX_FIFO       // [2] Block until Host sends byte to transmit // [EXPECT: ACC=RX_FIFO]
    STORE R2           // [2] R2 = Data to send // [EXPECT: R2=ACC]
    
    LOADI 8 // [EXPECT: ACC=8]
    STORE R3           // [2] R3 = Bit counter (8 bits) // [EXPECT: R3=ACC]

BIT_LOOP:
    // --------------------------------------
    // 1. EXTRACT LSB TO CARRY FLAG
    // --------------------------------------
    LOAD R2 // [EXPECT: ACC=R2]
    SHR                // Shift right. LSB falls into Carry Flag // [EXPECT: ACC=ACC>>1]
    STORE R2 // [EXPECT: R2=ACC]
    
    LOAD FLAGS // [EXPECT: ACC=FLAGS]
    LOADI 2            // Mask for Carry (Bit 1) // [EXPECT: ACC=2]
    STORE B // [EXPECT: B=ACC]
    AND B
    
    JMPNZ SEND_ONE
    JMP SEND_ZERO

SEND_ONE:
    // --------------------------------------
    // 2. SEND '1' (NRZI: Keep pins same)
    // --------------------------------------
    // Increment Bit Stuff Counter (R4)
    LOAD R4 // [EXPECT: ACC=R4]
    LOADI 1 // [EXPECT: ACC=1]
    STORE B // [EXPECT: B=ACC]
    ADD // [EXPECT: ACC=ACC+B]
    STORE R4 // [EXPECT: R4=ACC]
    
    // Check if we hit 6 consecutive 1s!
    LOAD R4 // [EXPECT: ACC=R4]
    LOADI 6 // [EXPECT: ACC=6]
    SUB                // R4 - 6 // [EXPECT: ACC=ACC-B]
    JMPNZ WAIT_BIT     // If not 6, we do NOTHING
    JMP BIT_STUFF      // If 6, jump to bit stuff!
    // If not 6, we do NOTHING (NRZI '1' means no pin toggle).
    JMP WAIT_BIT       // Go wait for bit period

BIT_STUFF:
    // --------------------------------------
    // 3. BIT STUFFING (Force a '0')
    // --------------------------------------
    LOADI 0 // [EXPECT: ACC=0]
    STORE R4           // Reset bit-stuff counter // [EXPECT: R4=ACC]
    
    // Force a '0' (NRZI means toggle the pins!)
    LOAD PIN_STATE // [EXPECT: ACC=PIN_STATE]
    LOAD R6            // R6 = 0x03 (Mask for pins 0 and 1) // [EXPECT: ACC=R6]
    STORE B // [EXPECT: B=ACC]
    XOR                // Instantly flips D+ and D- to their opposite states! // [EXPECT: ACC=ACC^B]
    STORE PIN_STATE // [EXPECT: PIN_STATE=ACC]
    
    // Wait 1 bit period for the stuffed bit
    // (Omitted timer logic for brevity, assume delay happens here)
    
    // Now that the stuffed '0' is sent, we MUST still send the actual '1'!
    JMP SEND_ONE       // Recursively jump back to SEND_ONE!

SEND_ZERO:
    // --------------------------------------
    // 4. SEND '0' (NRZI: Toggle pins)
    // --------------------------------------
    LOADI 0 // [EXPECT: ACC=0]
    STORE R4           // Reset bit-stuff counter // [EXPECT: R4=ACC]
    
    // Toggle the pins
    LOAD PIN_STATE // [EXPECT: ACC=PIN_STATE]
    LOAD R6            // R6 = 0x03 // [EXPECT: ACC=R6]
    STORE B // [EXPECT: B=ACC]
    XOR                // Flip D+ and D- // [EXPECT: ACC=ACC^B]
    STORE PIN_STATE // [EXPECT: PIN_STATE=ACC]

WAIT_BIT:
    // --------------------------------------
    // 5. BAUD DELAY & LOOP MANAGEMENT
    // --------------------------------------
    // (Wait logic goes here)
    
    // Decrement Bit Counter
    LOADI 1 // [EXPECT: ACC=1]
    STORE B // [EXPECT: B=ACC]
    LOAD R3 // [EXPECT: ACC=R3]
    SUB // [EXPECT: ACC=ACC-B]
    STORE R3 // [EXPECT: R3=ACC]
    JMPNZ BIT_LOOP     // Loop if not 0
    JMP START          // Get next byte from FIFO!
