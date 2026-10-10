// ==========================================
// UART RX - Core 0 (The Sampler)
// Pin 1: RX Input
// ==========================================

BOOT:
    // Wait for Host to send Baud Rate config
    LOAD RX_FIFO
    STORE R6           // R6 = Full Baud Delay [EXPECT: ACC=0x1E]
    SHR
    STORE R7           // R7 = Half Baud Delay [EXPECT: ACC=0x0F]

START:
WAIT_START:
    // Poll Pin 1 for LOW (Start Bit)
    LOADIB 2
    LOAD PIN_STATE
    AND B
    JMPNZ WAIT_START   // If Pin 1 is HIGH (0x2), keep waiting
    
    // Found start bit edge! Wait half a baud period.
    LOAD R7
    STORE TIMER_L
    LOAD TIMER_L       // Hardware stall until timer is 0!
    
    // Verify it's still LOW (Noise filter)
    LOAD PIN_STATE
    AND B
    JMPNZ WAIT_START   // False alarm!
    
    // Tell Core 1 to reset for a new byte! (Send 0xFF as a special start token)
    LOADI 0xFF
    STORE SHARED_1     // [EXPECT: ACC=0xFF]
    
    // Setup Bit Counter
    LOADI 8
    STORE R4           // R4 = 8 bits [EXPECT: ACC=0x08]

BIT_LOOP:
    // Wait full baud to sample next bit
    LOAD R6
    STORE TIMER_L
    LOAD TIMER_L       // Hardware stall until timer is 0!
    
    // Sample the pin!
    LOAD PIN_STATE
    STORE SHARED_1     // Send raw pins to Core 1
    
    // Wait for Core 1 to Acknowledge (Hardware Flag Bit 3 == 0)
    LOADIB 8           // Mask for Bit 3 (SHARED_1)
WAIT_ACK:
    LOAD FLAGS
    AND B
    JMPNZ WAIT_ACK     // Loop if Bit 3 is still 1
    
    // Decrement bit counter
    LOADIB 1
    LOAD R4
    SUB
    STORE R4
    JMPNZ BIT_LOOP     // Loop if not 0
    
    // Wait for Stop Bit (Full baud)
    LOAD R6
    STORE TIMER_L
    LOAD TIMER_L       // Hardware stall until timer is 0!
    
    JMP START          // Done! Back to waiting for next byte
