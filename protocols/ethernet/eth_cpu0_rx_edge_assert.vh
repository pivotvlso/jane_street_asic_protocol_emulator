reg [6:0] last_pc_0;
reg [7:0] last_acc_0;
reg [7:0] last_b_0;
always @(posedge clk) begin
    if (dut.core0.run && !dut.core0.mem_stall) begin
        last_pc_0 <= dut.core0.pc_op;
        last_acc_0 <= dut.core0.acc;
        last_b_0 <= dut.core0.b_reg;
    end
end
always @(posedge clk) begin
    if (dut.core0.run) begin
        case (last_pc_0)
            7'h03: if (!(dut.core0.b_reg === last_acc_0)) $display("ASSERTION FAILED CPU 0 PC %02X: Expected STORE B, got ACC=%h B=%h R2=%h R3=%h (last_acc=%h)", last_pc_0, dut.core0.acc, dut.core0.b_reg, dut.core0.r_regs[2], dut.core0.r_regs[3], last_acc_0);
            7'h04: if (!(dut.core0.acc === 8'h01)) $display("ASSERTION FAILED CPU 0 PC %02X: Expected LOADI 1, got ACC=%h B=%h R2=%h R3=%h (last_acc=%h)", last_pc_0, dut.core0.acc, dut.core0.b_reg, dut.core0.r_regs[2], dut.core0.r_regs[3], last_acc_0);
            7'h06: if (!(dut.core0.r_regs[2] === last_acc_0)) $display("ASSERTION FAILED CPU 0 PC %02X: Expected STORE R2, got ACC=%h B=%h R2=%h R3=%h (last_acc=%h)", last_pc_0, dut.core0.acc, dut.core0.b_reg, dut.core0.r_regs[2], dut.core0.r_regs[3], last_acc_0);
            7'h08: if (!(dut.core0.b_reg === last_acc_0)) $display("ASSERTION FAILED CPU 0 PC %02X: Expected STORE B, got ACC=%h B=%h R2=%h R3=%h (last_acc=%h)", last_pc_0, dut.core0.acc, dut.core0.b_reg, dut.core0.r_regs[2], dut.core0.r_regs[3], last_acc_0);
            7'h09: if (!(dut.core0.acc === 8'h01)) $display("ASSERTION FAILED CPU 0 PC %02X: Expected LOADI 1, got ACC=%h B=%h R2=%h R3=%h (last_acc=%h)", last_pc_0, dut.core0.acc, dut.core0.b_reg, dut.core0.r_regs[2], dut.core0.r_regs[3], last_acc_0);
            7'h0B: if (!(dut.core0.r_regs[3] === last_acc_0)) $display("ASSERTION FAILED CPU 0 PC %02X: Expected STORE R3, got ACC=%h B=%h R2=%h R3=%h (last_acc=%h)", last_pc_0, dut.core0.acc, dut.core0.b_reg, dut.core0.r_regs[2], dut.core0.r_regs[3], last_acc_0);
            7'h0C: if (!(dut.core0.b_reg === last_acc_0)) $display("ASSERTION FAILED CPU 0 PC %02X: Expected STORE B, got ACC=%h B=%h R2=%h R3=%h (last_acc=%h)", last_pc_0, dut.core0.acc, dut.core0.b_reg, dut.core0.r_regs[2], dut.core0.r_regs[3], last_acc_0);
            7'h0D: if (!(dut.core0.acc === dut.core0.r_regs[2])) $display("ASSERTION FAILED CPU 0 PC %02X: Expected LOAD R2, got ACC=%h B=%h R2=%h R3=%h (last_acc=%h)", last_pc_0, dut.core0.acc, dut.core0.b_reg, dut.core0.r_regs[2], dut.core0.r_regs[3], last_acc_0);
            7'h11: if (!(dut.core0.acc === dut.core0.r_regs[3])) $display("ASSERTION FAILED CPU 0 PC %02X: Expected LOAD R3, got ACC=%h B=%h R2=%h R3=%h (last_acc=%h)", last_pc_0, dut.core0.acc, dut.core0.b_reg, dut.core0.r_regs[2], dut.core0.r_regs[3], last_acc_0);
            7'h12: if (!(dut.core0.r_regs[2] === last_acc_0)) $display("ASSERTION FAILED CPU 0 PC %02X: Expected STORE R2, got ACC=%h B=%h R2=%h R3=%h (last_acc=%h)", last_pc_0, dut.core0.acc, dut.core0.b_reg, dut.core0.r_regs[2], dut.core0.r_regs[3], last_acc_0);
            7'h13: if (!(dut.core0.acc === dut.core0.r_regs[3])) $display("ASSERTION FAILED CPU 0 PC %02X: Expected LOAD R3, got ACC=%h B=%h R2=%h R3=%h (last_acc=%h)", last_pc_0, dut.core0.acc, dut.core0.b_reg, dut.core0.r_regs[2], dut.core0.r_regs[3], last_acc_0);
            7'h19: if (!(dut.core0.b_reg === last_acc_0)) $display("ASSERTION FAILED CPU 0 PC %02X: Expected STORE B, got ACC=%h B=%h R2=%h R3=%h (last_acc=%h)", last_pc_0, dut.core0.acc, dut.core0.b_reg, dut.core0.r_regs[2], dut.core0.r_regs[3], last_acc_0);
            7'h1A: if (!(dut.core0.acc === 8'h01)) $display("ASSERTION FAILED CPU 0 PC %02X: Expected LOADI 1, got ACC=%h B=%h R2=%h R3=%h (last_acc=%h)", last_pc_0, dut.core0.acc, dut.core0.b_reg, dut.core0.r_regs[2], dut.core0.r_regs[3], last_acc_0);
            7'h1C: if (!(dut.core0.r_regs[2] === last_acc_0)) $display("ASSERTION FAILED CPU 0 PC %02X: Expected STORE R2, got ACC=%h B=%h R2=%h R3=%h (last_acc=%h)", last_pc_0, dut.core0.acc, dut.core0.b_reg, dut.core0.r_regs[2], dut.core0.r_regs[3], last_acc_0);
        endcase
    end
end
