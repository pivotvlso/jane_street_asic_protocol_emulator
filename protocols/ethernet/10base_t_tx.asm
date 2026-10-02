// ==========================================
// Ethernet 10BASE-T Transmitter Concept
// Features: Manchester Encoding 
// Pins: Pin 0 = TX+, Pin 1 = TX-
// ==========================================
// 10 Mbps = 100ns per bit. 
// Manchester encoding splits the bit into two 50ns halves.
// Note: At a 50MHz CPU clock (20ns), a 50ns half-bit is 2.5 cycles. 
// To make this jitter-free, the ASIC should be underclocked to 40MHz 
// (25ns per cycle = exactly 2 cycles per half-bit).

START:
    LOAD RX_FIFO       // [2] Block until Host sends data
    STORE R2           // [2] R2 = Data
    
    LOADI 8
    STORE R3           // [2] R3 = Bit Counter (8)

BIT_LOOP:
    LOAD R2
    SHL                // [1] Shift MSB into Carry Flag
    STORE R2
    
    JMPC SEND_ONE      // [3] Jump if MSB was 1

SEND_ZERO:
    // Manchester '0' = Transition from HIGH to LOW (TX+ High, then Low)
    // First Half (High)
    LOADI 1            // 0001 (TX+ = 1, TX- = 0)
    STORE PIN_STATE
    
    // Second Half (Low)
    LOADI 2            // 0010 (TX+ = 0, TX- = 1)
    STORE PIN_STATE
    
    JMP BIT_DONE       // [3]

SEND_ONE:
    // Manchester '1' = Transition from LOW to HIGH (TX+ Low, then High)
    // First Half (Low)
    LOADI 2            // 0010 (TX+ = 0, TX- = 1)
    STORE PIN_STATE
    
    // Second Half (High)
    LOADI 1            // 0001 (TX+ = 1, TX- = 0)
    STORE PIN_STATE

BIT_DONE:
    // Decrement Loop Counter
    LOAD R3
    LOADI 1
    STORE B
    SUB
    STORE R3
    JMPNZ BIT_LOOP     // [3] Loop if not 0
    
    JMP START          // [3] Next byte
