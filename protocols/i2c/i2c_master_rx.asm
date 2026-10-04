// ==========================================
// I2C Master RX (Read Byte)
// Emulates I2C on Pin 0 (SDA) and Pin 1 (SCL)
// ==========================================

    // Start with SCL Low, SDA High-Z
    LOADI 2            // SCL=Output(0), SDA=Input(Z)
    STORE PIN_DIR

READ_BYTE:
    LOAD RX_FIFO       // Block until Host triggers read
    LOADI 0
    STORE R2           // Accumulator for received byte
    LOADI 8
    STORE R3           // Bit counter

BIT_LOOP:
    // Release SCL (Both High-Z) -> SCL goes High
    LOADI 0
    STORE PIN_DIR

    // Wait for SCL to be HIGH (Pin 1 == 1) for clock stretching
CLK_STRETCH:
    LOADI 2
    STORE B
    LOAD PIN_STATE
    AND B
    JMPNZ SCL_HIGH
    JMP CLK_STRETCH

SCL_HIGH:
    // Hold SCL High for a while
    LOADI 6
    STORE R5
    LOADI 1
    STORE B
DELAY_HIGH:
    LOAD R5
    SUB
    STORE R5
    JMPNZ DELAY_HIGH

    // Sample SDA (Pin 0)
    LOADI 1
    STORE B
    LOAD PIN_STATE
    AND B
    STORE R6           // Save sampled bit

    // Shift Accumulator Left
    LOAD R2
    SHL
    STORE R2

    // Add sampled bit
    LOAD R6
    STORE B
    LOAD R2
    ADD
    STORE R2

    // Pull SCL Low again
    LOADI 2
    STORE PIN_DIR

    // Delay Low
    LOADI 12
    STORE R5
    LOADI 1
    STORE B
DELAY_LOW:
    LOAD R5
    SUB
    STORE R5
    JMPNZ DELAY_LOW

    // Loop mgmt
    LOADI 1
    STORE B
    LOAD R3
    SUB
    STORE R3
    JMPNZ BIT_LOOP

    // Push received byte to Host
    LOAD R2
    STORE TX_FIFO

    // Jump to next byte (ACK/NACK logic omitted)
    JMP READ_BYTE
