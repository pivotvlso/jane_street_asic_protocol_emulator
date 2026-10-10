reg [6:0] last_pc_1;
reg [7:0] last_acc_1;
reg [7:0] last_b_1;
always @(posedge clk) begin
    if (dut.core1.run && !dut.core1.mem_stall) begin
        last_pc_1 <= dut.core1.pc_op;
        last_acc_1 <= dut.core1.acc;
        last_b_1 <= dut.core1.b_reg;
    end
end
always @(posedge clk) begin
    if (dut.core1.run) begin
        case (last_pc_1)
            7'h00: if (!(dut.core1.acc === 8'h04)) $display("ASSERTION FAILED CPU 1 PC %02X: Expected LOADI 4, got ACC=%h B=%h R2=%h R3=%h (last_acc=%h)", last_pc_1, dut.core1.acc, dut.core1.b_reg, dut.core1.r_regs[2], dut.core1.r_regs[3], last_acc_1);
            7'h02: if (!(dut.core1.acc === 8'h08)) $display("ASSERTION FAILED CPU 1 PC %02X: Expected LOADI 8, got ACC=%h B=%h R2=%h R3=%h (last_acc=%h)", last_pc_1, dut.core1.acc, dut.core1.b_reg, dut.core1.r_regs[2], dut.core1.r_regs[3], last_acc_1);
            7'h03: if (!(dut.core1.r_regs[3] === last_acc_1)) $display("ASSERTION FAILED CPU 1 PC %02X: Expected STORE R3, got ACC=%h B=%h R2=%h R3=%h (last_acc=%h)", last_pc_1, dut.core1.acc, dut.core1.b_reg, dut.core1.r_regs[2], dut.core1.r_regs[3], last_acc_1);
            7'h04: if (!(dut.core1.acc === 8'h00)) $display("ASSERTION FAILED CPU 1 PC %02X: Expected LOADI 0, got ACC=%h B=%h R2=%h R3=%h (last_acc=%h)", last_pc_1, dut.core1.acc, dut.core1.b_reg, dut.core1.r_regs[2], dut.core1.r_regs[3], last_acc_1);
            7'h05: if (!(dut.core1.r_regs[2] === last_acc_1)) $display("ASSERTION FAILED CPU 1 PC %02X: Expected STORE R2, got ACC=%h B=%h R2=%h R3=%h (last_acc=%h)", last_pc_1, dut.core1.acc, dut.core1.b_reg, dut.core1.r_regs[2], dut.core1.r_regs[3], last_acc_1);
            7'h07: if (!(dut.core1.b_reg === last_acc_1)) $display("ASSERTION FAILED CPU 1 PC %02X: Expected STORE B, got ACC=%h B=%h R2=%h R3=%h (last_acc=%h)", last_pc_1, dut.core1.acc, dut.core1.b_reg, dut.core1.r_regs[2], dut.core1.r_regs[3], last_acc_1);
            7'h0E: if (!(dut.core1.acc === 8'h00)) $display("ASSERTION FAILED CPU 1 PC %02X: Expected LOADI 0, got ACC=%h B=%h R2=%h R3=%h (last_acc=%h)", last_pc_1, dut.core1.acc, dut.core1.b_reg, dut.core1.r_regs[2], dut.core1.r_regs[3], last_acc_1);
            7'h10: if (!(dut.core1.acc === 8'h08)) $display("ASSERTION FAILED CPU 1 PC %02X: Expected LOADI 8, got ACC=%h B=%h R2=%h R3=%h (last_acc=%h)", last_pc_1, dut.core1.acc, dut.core1.b_reg, dut.core1.r_regs[2], dut.core1.r_regs[3], last_acc_1);
            7'h11: if (!(dut.core1.b_reg === last_acc_1)) $display("ASSERTION FAILED CPU 1 PC %02X: Expected STORE B, got ACC=%h B=%h R2=%h R3=%h (last_acc=%h)", last_pc_1, dut.core1.acc, dut.core1.b_reg, dut.core1.r_regs[2], dut.core1.r_regs[3], last_acc_1);
            7'h12: if (!(dut.core1.acc === 8'h08)) $display("ASSERTION FAILED CPU 1 PC %02X: Expected LOADI 8, got ACC=%h B=%h R2=%h R3=%h (last_acc=%h)", last_pc_1, dut.core1.acc, dut.core1.b_reg, dut.core1.r_regs[2], dut.core1.r_regs[3], last_acc_1);
            7'h17: if (!(dut.core1.b_reg === last_acc_1)) $display("ASSERTION FAILED CPU 1 PC %02X: Expected STORE B, got ACC=%h B=%h R2=%h R3=%h (last_acc=%h)", last_pc_1, dut.core1.acc, dut.core1.b_reg, dut.core1.r_regs[2], dut.core1.r_regs[3], last_acc_1);
            7'h18: if (!(dut.core1.acc === dut.core1.r_regs[2])) $display("ASSERTION FAILED CPU 1 PC %02X: Expected LOAD R2, got ACC=%h B=%h R2=%h R3=%h (last_acc=%h)", last_pc_1, dut.core1.acc, dut.core1.b_reg, dut.core1.r_regs[2], dut.core1.r_regs[3], last_acc_1);
            7'h1B: if (!(dut.core1.r_regs[2] === last_acc_1)) $display("ASSERTION FAILED CPU 1 PC %02X: Expected STORE R2, got ACC=%h B=%h R2=%h R3=%h (last_acc=%h)", last_pc_1, dut.core1.acc, dut.core1.b_reg, dut.core1.r_regs[2], dut.core1.r_regs[3], last_acc_1);
            7'h1C: if (!(dut.core1.r_regs[2] === last_acc_1)) $display("ASSERTION FAILED CPU 1 PC %02X: Expected STORE R2, got ACC=%h B=%h R2=%h R3=%h (last_acc=%h)", last_pc_1, dut.core1.acc, dut.core1.b_reg, dut.core1.r_regs[2], dut.core1.r_regs[3], last_acc_1);
            7'h1D: if (!(dut.core1.acc === 8'h01)) $display("ASSERTION FAILED CPU 1 PC %02X: Expected LOADI 1, got ACC=%h B=%h R2=%h R3=%h (last_acc=%h)", last_pc_1, dut.core1.acc, dut.core1.b_reg, dut.core1.r_regs[2], dut.core1.r_regs[3], last_acc_1);
            7'h1E: if (!(dut.core1.b_reg === last_acc_1)) $display("ASSERTION FAILED CPU 1 PC %02X: Expected STORE B, got ACC=%h B=%h R2=%h R3=%h (last_acc=%h)", last_pc_1, dut.core1.acc, dut.core1.b_reg, dut.core1.r_regs[2], dut.core1.r_regs[3], last_acc_1);
            7'h1F: if (!(dut.core1.acc === dut.core1.r_regs[3])) $display("ASSERTION FAILED CPU 1 PC %02X: Expected LOAD R3, got ACC=%h B=%h R2=%h R3=%h (last_acc=%h)", last_pc_1, dut.core1.acc, dut.core1.b_reg, dut.core1.r_regs[2], dut.core1.r_regs[3], last_acc_1);
            7'h21: if (!(dut.core1.r_regs[3] === last_acc_1)) $display("ASSERTION FAILED CPU 1 PC %02X: Expected STORE R3, got ACC=%h B=%h R2=%h R3=%h (last_acc=%h)", last_pc_1, dut.core1.acc, dut.core1.b_reg, dut.core1.r_regs[2], dut.core1.r_regs[3], last_acc_1);
            7'h23: if (!(dut.core1.acc === dut.core1.r_regs[2])) $display("ASSERTION FAILED CPU 1 PC %02X: Expected LOAD R2, got ACC=%h B=%h R2=%h R3=%h (last_acc=%h)", last_pc_1, dut.core1.acc, dut.core1.b_reg, dut.core1.r_regs[2], dut.core1.r_regs[3], last_acc_1);
        endcase
    end
end
