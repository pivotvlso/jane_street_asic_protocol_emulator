`default_nettype none

module cpu_core (
    input  wire       clk,
    input  wire       rst_n,
    
    // CPU Control
    input  wire       run,      // 1 = Run, 0 = Halt
    
    // Physical Pin Interface
    input  wire [3:0] pin_state, // Data read from uio
    output reg  [3:0] pin_out,  // Data driven to uio
    output reg  [3:0] pin_dir,  // 1 = Output, 0 = High-Z
    
    // Instruction ROM Interface (Async Read)
    output wire [6:0] rom_addr,
    input  wire [3:0] rom_data,
    
    // Memory-Mapped IO Interface (External Peripherals)
    output wire [3:0] mem_addr,
    output wire [7:0] mem_wdata,
    output wire       mem_we,
    output wire       mem_re,
    input  wire [7:0] mem_rdata,
    input  wire       mem_stall, // High when FIFO empty/full or Timer blocking
    
    // Debug
    output wire [6:0] exec_pc
);

    // Core Registers
    reg [6:0] pc;
    
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
    
    assign exec_pc = pc - (is_1_nibble ? 7'd1 : (is_2_nibble ? 7'd2 : 7'd3));
    
    reg [2:0] state;
    
    assign rom_addr = pc;
    
    wire [8:0] add_res = acc + b_reg;
    wire [8:0] sub_res = acc - b_reg;
    
    assign mem_addr = curr_op1;
    assign mem_wdata = acc;
    assign mem_we = (state == ST_EXECUTE && curr_opcode == 4'hC && (!is_internal_reg(curr_op1) || curr_op1 == 4'h8));
    assign mem_re = (state == ST_EXECUTE && curr_opcode == 4'hB && !is_internal_reg(curr_op1));
    
    function is_internal_reg(input [3:0] addr);
        begin
            // 0=ACC, 1=B, 2=R2, 3=R3, 8=FLAGS, B..E=R4..R7, F=PIN_DIR
            is_internal_reg = (addr <= 4'h3) || (addr == 4'h8) || (addr >= 4'hB);
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= ST_HALT;
            pc <= 0;
            acc <= 0;
            b_reg <= 0;
            flag_zero <= 0;
            flag_carry <= 0;
            pin_out <= 0;
            pin_dir <= 0;
        end else if (!run) begin
            state <= ST_HALT;
            pc <= 0;
        end else begin
            
            case (state)
                ST_HALT: begin
                    state <= ST_FETCH_OP;
                end
                
                ST_FETCH_OP: begin
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
                        4'h7: begin // UNUSED (formerly RETI)
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
                            flag_zero <= (curr_op1 == 0);
                            state <= ST_FETCH_OP;
                        end
                        4'hB: begin // LOAD addr
                            if (is_internal_reg(curr_op1)) begin
                                if (curr_op1 == 4'h0) begin acc <= acc; flag_zero <= (acc == 0); end
                                else if (curr_op1 == 4'h1) begin acc <= b_reg; flag_zero <= (b_reg == 0); end
                                else if (curr_op1 == 4'h8) begin acc <= {6'b0, flag_carry, flag_zero}; flag_zero <= ({6'b0, flag_carry, flag_zero} == 0); end
                                else if (curr_op1 == 4'hF) begin acc <= {pin_state, pin_dir}; flag_zero <= ({pin_state, pin_dir} == 0); end
                                else begin acc <= r_regs[curr_op1]; flag_zero <= (r_regs[curr_op1] == 0); end
                                state <= ST_FETCH_OP;
                            end else begin
                                acc <= mem_rdata;
                                flag_zero <= (mem_rdata == 0);
                                state <= ST_FETCH_OP;
                            end
                        end
                        4'hC: begin // STORE addr
                            if (is_internal_reg(curr_op1)) begin
                                if (curr_op1 == 4'h1) b_reg <= acc;
                                else if (curr_op1 == 4'hF) pin_dir <= acc[3:0];
                                else if (curr_op1 != 4'h0 && curr_op1 != 4'h8) r_regs[curr_op1] <= acc;
                                state <= ST_FETCH_OP;
                            end else begin
                                state <= ST_FETCH_OP;
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
            endcase
        end
    end
endmodule
