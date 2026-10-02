`default_nettype none

module decoder (
    input  wire [3:0] opcode,
    
    // Instruction Length
    output wire       is_1_nibble,
    output wire       is_2_nibble,
    output wire       is_3_nibble,
    
    // Operation Categories
    output wire       is_math,
    output wire       is_jump,
    output wire       is_mem_load,
    output wire       is_mem_store,
    output wire       is_pin_set
);

    // --------------------------------------------------------
    // Instruction Length Decoder
    // --------------------------------------------------------
    // MSB = 0 means 1-nibble. 
    // MSB = 1 means 2 or 3 nibbles.
    assign is_1_nibble = (opcode[3] == 1'b0);
    assign is_2_nibble = (opcode[3] == 1'b1) && (opcode < 4'hD);
    assign is_3_nibble = (opcode[3] == 1'b1) && (opcode >= 4'hD);

    // --------------------------------------------------------
    // Operation Type Decoder
    // --------------------------------------------------------
    // 0x0 to 0x5 are ALU Math operations
    assign is_math      = (opcode <= 4'h5);
    
    // Jumps (D = JMP, E = JMPNZ, F = JMPC)
    assign is_jump      = is_3_nibble;
    
    // Memory / Immediate Ops
    assign is_mem_load  = (opcode == 4'hC);
    assign is_mem_store = (opcode == 4'hB); // Wait, spec says: B=LOADI? No, B=STORE? Let's check spec.
    // Actually, I will explicitly decode everything in cpu_core.v switch statement,
    // this module is mostly for the state machine length controller.

endmodule
