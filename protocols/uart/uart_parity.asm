// ==========================================
// UART RX Parity Watchdog - Core (CPU 3)
// Reads the received byte from SHARED_0 (pushed by CPU 2)
// Calculates parity and compares it with Parity Bit from PIN_STATE
// If error, pushes 0xFF to TX FIFO
// ==========================================

BOOT:
    // Wait for byte to be ready in SHARED_0
    LOAD SHARED_0
    STORE R2           // R2 = Data byte
    
    // Calculate parity of R2 (xor all bits)
    // R3 = Parity sum
    LOADI 0
    STORE R3
    
    // Loop 8 times to XOR bits
    LOADI 8
    STORE R4

PARITY_LOOP:
    LOAD R2
    STORE B
    LOADIB 1
    AND B              // ACC = R2 & 1
    
    STORE B
    LOAD R3
    XOR                // ACC = R3 ^ (R2 & 1)
    STORE R3
    
    LOAD R2
    SHR
    STORE R2           // R2 = R2 >> 1
    
    LOADIB 1
    LOAD R4
    SUB
    STORE R4
    JMPNZ PARITY_LOOP
    
    // Now R3 contains the calculated parity (0 or 1)
    
    // Read the parity bit from PIN_STATE!
    // Wait, the parity bit is already received by Core 1!
    // In test_1_7, it's 7E1. 7 data bits, 1 parity bit.
    // So the received byte (in SHARED_0) IS 8 bits: {Parity, Data[6:0]}!
    // So if Parity is Even, the parity of the ENTIRE 8 bits SHOULD BE 0!
    // Wait! Is that true?
    // If Data = 'A' (0x41 = 1000001), 2 ones. Parity bit is 0. 
    // Total byte = 0x41. Parity sum of all 8 bits = 0 (Even).
    // If Invalid Data = 0xC1 = 11000001 (3 ones). 
    // Parity sum of all 8 bits = 1 (Odd).
    // So we just check if R3 == 0!
    
    LOAD R3
    // We expect R3 to be 0 for Even Parity!
    JMPNZ PARITY_ERROR
    
    // Parity is valid! Output 0x00 to TX FIFO
    LOADI 0
    STORE TX_FIFO
    JMP BOOT

PARITY_ERROR:
    // Output 0xFF to TX FIFO
    LOADI 0xFF
    STORE TX_FIFO
    JMP BOOT
