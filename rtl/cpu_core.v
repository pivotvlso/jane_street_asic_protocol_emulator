`default_nettype none

module cpu_core (
    input  wire       clk,
    input  wire       rst_n,
    
    // CPU Control
    input  wire       run,      // 1 = Run, 0 = Halt
    input  wire       irq,      // Hardware Interrupt
    
    // Physical Pin Interface
    output reg  [3:0] pin_out,  // Data driven to uio
    output reg  [3:0] pin_dir,  // 1 = Output, 0 = High-Z
    
    // Instruction ROM Interface (Async Read)
    output wire [6:0] rom_addr,
    input  wire [3:0] rom_data,
    
    // Memory-Mapped IO Interface (External Peripherals)
    output reg  [3:0] mem_addr,
    output reg  [7:0] mem_wdata,
    output reg        mem_we,
    output reg        mem_re,
    input  wire [7:0] mem_rdata,
    input  wire       mem_stall // High when FIFO empty/full or Timer blocking
);

    // Core Registers
    reg [6:0] pc;
    reg [6:0] ret_pc;
    reg       in_irq;
    
    reg [7:0] acc;
    reg [7:0] b_reg;
    reg [7:0] r_regs [2:14]; // Scratch registers
    
    reg       flag_zero;
    reg       flag_carry;

    // Pipeline Registers
    reg [3:0] curr_opcode;
    reg [3:0] curr_op1;
    reg [3:0] curr_op2;
    
    // Decoder Instantiation
    wire is_1_nibble, is_2_nibble, is_3_nibble;
    decoder dec_inst (
        .opcode(curr_opcode),
        .is_1_nibble(is_1_nibble),
        .is_2_nibble(is_2_nibble),
        .is_3_nibble(is_3_nibble)
    );

    localparam ST_HALT      = 3'd0;
    localparam ST_FETCH_OP  = 3'd1;
    localparam ST_FETCH_OP1 = 3'd2;
    localparam ST_FETCH_OP2 = 3'd3;
    localparam ST_EXECUTE   = 3'd4;
    localparam ST_MEM_WAIT  = 3'd5;
    
    reg [2:0] state;
    
    assign rom_addr = pc;
    
    wire [8:0] add_res = acc + b_reg;
    wire [8:0] sub_res = acc - b_reg;
    
    function is_internal_reg(input [3:0] addr);
        begin
            // 0=ACC, 1=B, 2=R2, 3=R3, 8=FLAGS, A..E=R4..R8, F=PIN_DIR
            is_internal_reg = (addr <= 4'h3) || (addr == 4'h8) || (addr >= 4'hA);
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= ST_HALT;
            pc <= 0;
            ret_pc <= 0;
            in_irq <= 0;
            acc <= 0;
            b_reg <= 0;
            flag_zero <= 0;
            flag_carry <= 0;
            mem_we <= 0;
            mem_re <= 0;
            pin_out <= 0;
            pin_dir <= 0;
        end else begin
            mem_we <= 0;
            mem_re <= 0;
            
            case (state)
                ST_HALT: begin
                    if (run) state <= ST_FETCH_OP;
                end
                
                ST_FETCH_OP: begin
                    if (!run) begin
                        state <= ST_HALT;
                    end else if (irq && !in_irq) begin
                        ret_pc <= pc;
                        pc <= 0;
                        in_irq <= 1;
                    end else begin
                        curr_opcode <= rom_data;
                        pc <= pc + 1;
                        if (rom_data[3] == 1'b0) state <= ST_EXECUTE;
                        else state <= ST_FETCH_OP1;
                    end
                end
                
                ST_FETCH_OP1: begin
                    curr_op1 <= rom_data;
                    pc <= pc + 1;
                    if (curr_opcode >= 4'hD) state <= ST_FETCH_OP2; // 3-Nibble jumps
                    else state <= ST_EXECUTE;
                end
                
                ST_FETCH_OP2: begin
                    curr_op2 <= rom_data;
                    pc <= pc + 1;
                    state <= ST_EXECUTE;
                end
                
                ST_EXECUTE: begin
                    case (curr_opcode)
                        4'h0: begin // ADD
                            acc <= add_res[7:0]; flag_carry <= add_res[8]; flag_zero <= (add_res[7:0] == 0);
                            state <= ST_FETCH_OP;
                        end
                        4'h1: begin // SUB
                            acc <= sub_res[7:0]; flag_carry <= sub_res[8]; flag_zero <= (sub_res[7:0] == 0);
                            state <= ST_FETCH_OP;
                        end
                        4'h2: begin // AND
                            acc <= acc & b_reg; flag_zero <= ((acc & b_reg) == 0);
                            state <= ST_FETCH_OP;
                        end
                        4'h3: begin // XOR
                            acc <= acc ^ b_reg; flag_zero <= ((acc ^ b_reg) == 0);
                            state <= ST_FETCH_OP;
                        end
                        4'h4: begin // SHR
                            acc <= {1'b0, acc[7:1]}; flag_carry <= acc[0]; flag_zero <= (acc[7:1] == 0);
                            state <= ST_FETCH_OP;
                        end
                        4'h5: begin // SHL
                            acc <= {acc[6:0], 1'b0}; flag_carry <= acc[7]; flag_zero <= (acc[6:0] == 0);
                            state <= ST_FETCH_OP;
                        end
                        4'h6: begin // NOP
                            state <= ST_FETCH_OP;
                        end
                        4'h7: begin // RETI
                            pc <= ret_pc; in_irq <= 0;
                            state <= ST_FETCH_OP;
                        end
                        4'h8: begin // SET0 pin
                            if (curr_op1 < 4) pin_out[curr_op1[1:0]] <= 1'b0;
                            state <= ST_FETCH_OP;
                        end
                        4'h9: begin // SET1 pin
                            if (curr_op1 < 4) pin_out[curr_op1[1:0]] <= 1'b1;
                            state <= ST_FETCH_OP;
                        end
                        4'hA: begin // LOADI imm
                            acc <= {4'b0000, curr_op1};
                            state <= ST_FETCH_OP;
                        end
                        4'hB: begin // LOAD addr
                            if (is_internal_reg(curr_op1)) begin
                                if (curr_op1 == 4'h0) acc <= acc;
                                else if (curr_op1 == 4'h1) acc <= b_reg;
                                else if (curr_op1 == 4'h8) acc <= {6'b0, flag_carry, flag_zero};
                                else if (curr_op1 == 4'hF) acc <= {4'b0, pin_dir};
                                else acc <= r_regs[curr_op1];
                                state <= ST_FETCH_OP;
                            end else begin
                                mem_addr <= curr_op1;
                                mem_re <= 1;
                                state <= ST_MEM_WAIT;
                            end
                        end
                        4'hC: begin // STORE addr
                            if (is_internal_reg(curr_op1)) begin
                                if (curr_op1 == 4'h1) b_reg <= acc;
                                else if (curr_op1 == 4'hF) pin_dir <= acc[3:0];
                                else if (curr_op1 != 4'h0 && curr_op1 != 4'h8) r_regs[curr_op1] <= acc;
                                state <= ST_FETCH_OP;
                            end else begin
                                mem_addr <= curr_op1;
                                mem_wdata <= acc;
                                mem_we <= 1;
                                state <= ST_MEM_WAIT;
                            end
                        end
                        4'hD: begin // JMP
                            pc <= {curr_op1[2:0], curr_op2};
                            state <= ST_FETCH_OP;
                        end
                        4'hE: begin // JMPNZ
                            if (!flag_zero) pc <= {curr_op1[2:0], curr_op2};
                            state <= ST_FETCH_OP;
                        end
                        4'hF: begin // JMPC
                            if (flag_carry) pc <= {curr_op1[2:0], curr_op2};
                            state <= ST_FETCH_OP;
                        end
                    endcase
                end
                
                ST_MEM_WAIT: begin
                    if (!mem_stall) begin
                        if (mem_re) acc <= mem_rdata;
                        state <= ST_FETCH_OP;
                    end else begin
                        mem_re <= mem_re;
                        mem_we <= mem_we;
                    end
                end
            endcase
        end
    end
endmodule
