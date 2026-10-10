// ==========================================
// UART RX - Core 2 (The Accumulator)
// Receives shifted bits from Core 1, merges them,
// and pushes bytes to the Host.
// ==========================================

BOOT:
WAIT_START:
    LOAD SHARED_2
    JMPNZ READ_START
    JMP WAIT_START
    
READ_START:
    // Core 1 sends 0xFF to indicate start of a new byte
    LOAD SHARED_3
    
    // Clear flag
    LOADI 0
    STORE SHARED_2
    
    // Initialize Accumulator and Counter
    LOADI 0
    STORE R2           // R2 = Data
    LOADI 8
    STORE R4           // R4 = 8 bits
    
PROCESS_LOOP:
    // Wait for bit from Core 1
WAIT_DATA:
    LOAD SHARED_2
    JMPNZ HAS_DATA
    JMP WAIT_DATA
    
HAS_DATA:
    // Read the shifted MSB bit
    LOAD SHARED_3
    STORE B
    
    // ACK Core 1
    LOADI 0
    STORE SHARED_2
    
    // Merge into R2
    LOAD R2
    SHR                // Shift running data right
    ADD                // ACC = (New_MSB) + (Data >> 1)
    STORE R2
    
    // Decrement counter
    LOADI 1
    STORE B
    LOAD R4
    SUB
    STORE R4
    JMPNZ PROCESS_LOOP
    
    // We got all 8 bits! Push to Host!
    LOAD R2
    STORE TX_FIFO
    
    JMP BOOT
