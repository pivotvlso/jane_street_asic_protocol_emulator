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
    
    // Split-Stream Instruction ROM Interfaces
    output reg  [6:0] pc_op,
    input  wire [3:0] rom_op_data,
    
    output reg  [5:0] pc_op1,
    input  wire [3:0] rom_op1_data,
    
    output reg  [2:0] pc_op2,
    input  wire [3:0] rom_op2_data,

    // Jump Table Interface (Hardware Jump Table managed by top.v)
    output wire [3:0]  jmp_table_addr, // The jump ID to lookup
    input  wire [15:0] jmp_table_data, // {pc_op[6:0], pc_op1[5:0], pc_op2[2:0]}
    
    // Memory-Mapped IO Interface (External Peripherals)
    output wire [3:0] mem_addr,
    output wire [7:0] mem_wdata,
    output wire       mem_we,
    output wire       mem_re,
    input  wire [7:0] mem_rdata,
    input  wire       mem_stall, // High when FIFO empty/full or Timer blocking
    
    // Special internal status flags mapped to address 0x8
    input  wire [3:0] shared_valid
);

    // Internal Registers
    reg [7:0] r_regs [0:15]; 
    reg [7:0] acc;
    reg [7:0] b_reg;
    
    reg       flag_zero;
    reg       flag_carry;

    // Decoder Instantiation
    wire is_1_nibble, is_2_nibble, is_3_nibble;
    decoder dec_inst (
        .opcode(rom_op_data),
        .is_1_nibble(is_1_nibble),
        .is_2_nibble(is_2_nibble),
        .is_3_nibble(is_3_nibble)
    );

    wire [8:0] add_res = acc + b_reg;
    wire [8:0] sub_res = acc - b_reg;
    
    assign mem_addr = rom_op1_data;
    assign mem_wdata = acc;
    assign mem_we = (rom_op_data == 4'hC && (!is_internal_reg(rom_op1_data) || rom_op1_data == 4'h8) && run);
    assign mem_re = (rom_op_data == 4'hB && !is_internal_reg(rom_op1_data) && run);
    
    assign jmp_table_addr = rom_op1_data;

    function is_internal_reg(input [3:0] addr);
        begin
            is_internal_reg = (addr <= 4'h3) || (addr == 4'h8) || (addr >= 4'hB);
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pc_op <= 0;
            pc_op1 <= 0;
            pc_op2 <= 0;
            acc <= 0;
            b_reg <= 0;
            flag_zero <= 0;
            flag_carry <= 0;
            pin_out <= 0;
            pin_dir <= 0;
        end else if (!run) begin
            pc_op <= 0;
            pc_op1 <= 0;
            pc_op2 <= 0;
        end else if (!mem_stall) begin
            // Assertion: Stop if executing uninitialized instruction
            if (rom_op_data === 4'hx) begin
                $display("[%0t] ASSERTION FAILED: CPU executed uninitialized instruction RAM at PC %0d!", $time, pc_op);
                $finish;
            end
            
            // Instruction Execution
            case (rom_op_data)
                4'h0: begin acc <= add_res[7:0]; flag_carry <= add_res[8]; flag_zero <= (add_res[7:0] == 0); end
                4'h1: begin acc <= sub_res[7:0]; flag_carry <= sub_res[8]; flag_zero <= (sub_res[7:0] == 0); end
                4'h2: begin acc <= acc & b_reg; flag_zero <= ((acc & b_reg) == 0); end
                4'h3: begin acc <= acc ^ b_reg; flag_zero <= ((acc ^ b_reg) == 0); end
                4'h4: begin flag_carry <= acc[0]; acc <= {1'b0, acc[7:1]}; flag_zero <= ({1'b0, acc[7:1]} == 0); end
                4'h5: begin flag_carry <= acc[7]; acc <= {acc[6:0], 1'b0}; flag_zero <= ({acc[6:0], 1'b0} == 0); end
                4'h6: begin /* NOP */ end
                4'h7: begin b_reg <= {rom_op1_data, rom_op2_data}; end
                4'h8: begin pin_out[rom_op1_data[1:0]] <= 1'b0; end
                4'h9: begin pin_out[rom_op1_data[1:0]] <= 1'b1; end
                4'hA: begin acc <= {rom_op1_data, rom_op2_data}; flag_zero <= ({rom_op1_data, rom_op2_data} == 0); end
                4'hB: begin // LOAD
                    if (is_internal_reg(rom_op1_data)) begin
                        if (rom_op1_data == 4'h0) begin acc <= acc; flag_zero <= (acc == 0); end
                        else if (rom_op1_data == 4'h1) begin acc <= b_reg; flag_zero <= (b_reg == 0); end
                        else if (rom_op1_data == 4'h8) begin acc <= {2'b0, shared_valid, flag_carry, flag_zero}; flag_zero <= ({2'b0, shared_valid, flag_carry, flag_zero} == 0); end
                        else if (rom_op1_data == 4'hF) begin acc <= {pin_state, pin_dir}; flag_zero <= ({pin_state, pin_dir} == 0); end
                        else begin acc <= r_regs[rom_op1_data]; flag_zero <= (r_regs[rom_op1_data] == 0); end
                    end else begin
                        acc <= mem_rdata;
                        flag_zero <= (mem_rdata == 0);
                    end
                end
                4'hC: begin // STORE
                    if (is_internal_reg(rom_op1_data)) begin
                        if (rom_op1_data == 4'h1) b_reg <= acc;
                        else if (rom_op1_data == 4'hF) pin_dir <= acc[3:0];
                        else if (rom_op1_data != 4'h0 && rom_op1_data != 4'h8) r_regs[rom_op1_data] <= acc;
                    end
                end
            endcase

            // PC Increment Logic
            if (rom_op_data == 4'hD || 
               (rom_op_data == 4'hE && !flag_zero) || 
               (rom_op_data == 4'hF && flag_carry)) begin
                // Take Branch (Jump)
                pc_op <= jmp_table_data[15:9];
                pc_op1 <= jmp_table_data[8:3];
                pc_op2 <= jmp_table_data[2:0];
            end else begin
                // Normal PC Increment
                pc_op <= pc_op + 1;
                if (!is_1_nibble) pc_op1 <= pc_op1 + 1;
                if (is_3_nibble) pc_op2 <= pc_op2 + 1;
            end
        end
    end
endmodule
