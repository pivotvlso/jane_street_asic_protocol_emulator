reg [6:0] last_pc_1;
always @(posedge clk) begin
    if (dut.core1.run && dut.core1.state == 3'd4) begin
        last_pc_1 <= dut.core1.exec_pc;
    end
end
always @(posedge clk) begin
    if (dut.core1.run && dut.core1.state == 3'd1) begin
        case (last_pc_1)
            7'h00: if (!(dut.core1.acc === 8'h00)) $display("ASSERTION FAILED CPU 1 PC 00: Expected ACC=0, got ACC=%h B=%h R2=%h R3=%h", dut.core1.acc, dut.core1.b_reg, dut.core1.r_regs[2], dut.core1.r_regs[3]);
            7'h04: if (!(dut.core1.acc === 8'h08)) $display("ASSERTION FAILED CPU 1 PC 04: Expected ACC=8 8 bits per byte, got ACC=%h B=%h R2=%h R3=%h", dut.core1.acc, dut.core1.b_reg, dut.core1.r_regs[2], dut.core1.r_regs[3]);
            7'h06: if (!(dut.core1.r_regs[3] === dut.core1.acc)) $display("ASSERTION FAILED CPU 1 PC 06: Expected R3=ACC, got ACC=%h B=%h R2=%h R3=%h", dut.core1.acc, dut.core1.b_reg, dut.core1.r_regs[2], dut.core1.r_regs[3]);
            7'h08: if (!(dut.core1.acc === 8'h00)) $display("ASSERTION FAILED CPU 1 PC 08: Expected ACC=0 Byte accumulator, got ACC=%h B=%h R2=%h R3=%h", dut.core1.acc, dut.core1.b_reg, dut.core1.r_regs[2], dut.core1.r_regs[3]);
            7'h0A: if (!(dut.core1.r_regs[2] === dut.core1.acc)) $display("ASSERTION FAILED CPU 1 PC 0A: Expected R2=ACC, got ACC=%h B=%h R2=%h R3=%h", dut.core1.acc, dut.core1.b_reg, dut.core1.r_regs[2], dut.core1.r_regs[3]);
            7'h14: if (!(dut.core1.b_reg === dut.core1.acc)) $display("ASSERTION FAILED CPU 1 PC 14: Expected B=ACC, got ACC=%h B=%h R2=%h R3=%h", dut.core1.acc, dut.core1.b_reg, dut.core1.r_regs[2], dut.core1.r_regs[3]);
            7'h16: if (!(dut.core1.acc === 8'h01)) $display("ASSERTION FAILED CPU 1 PC 16: Expected ACC=1, got ACC=%h B=%h R2=%h R3=%h", dut.core1.acc, dut.core1.b_reg, dut.core1.r_regs[2], dut.core1.r_regs[3]);
            7'h1C: if (!(dut.core1.acc === 8'h00)) $display("ASSERTION FAILED CPU 1 PC 1C: Expected ACC=0 Else bit is 0, got ACC=%h B=%h R2=%h R3=%h", dut.core1.acc, dut.core1.b_reg, dut.core1.r_regs[2], dut.core1.r_regs[3]);
            7'h21: if (!(dut.core1.acc === 8'h08)) $display("ASSERTION FAILED CPU 1 PC 21: Expected ACC=8, got ACC=%h B=%h R2=%h R3=%h", dut.core1.acc, dut.core1.b_reg, dut.core1.r_regs[2], dut.core1.r_regs[3]);
            7'h23: if (!(dut.core1.b_reg === dut.core1.acc)) $display("ASSERTION FAILED CPU 1 PC 23: Expected B=ACC, got ACC=%h B=%h R2=%h R3=%h", dut.core1.acc, dut.core1.b_reg, dut.core1.r_regs[2], dut.core1.r_regs[3]);
            7'h25: if (!(dut.core1.acc === 8'h08)) $display("ASSERTION FAILED CPU 1 PC 25: Expected ACC=8, got ACC=%h B=%h R2=%h R3=%h", dut.core1.acc, dut.core1.b_reg, dut.core1.r_regs[2], dut.core1.r_regs[3]);
            7'h2B: if (!(dut.core1.b_reg === dut.core1.acc)) $display("ASSERTION FAILED CPU 1 PC 2B: Expected B=ACC, got ACC=%h B=%h R2=%h R3=%h", dut.core1.acc, dut.core1.b_reg, dut.core1.r_regs[2], dut.core1.r_regs[3]);
            7'h2D: if (!(dut.core1.acc === dut.core1.r_regs[2])) $display("ASSERTION FAILED CPU 1 PC 2D: Expected ACC=R2, got ACC=%h B=%h R2=%h R3=%h", dut.core1.acc, dut.core1.b_reg, dut.core1.r_regs[2], dut.core1.r_regs[3]);
            7'h31: if (!(dut.core1.r_regs[2] === dut.core1.acc)) $display("ASSERTION FAILED CPU 1 PC 31: Expected R2=ACC, got ACC=%h B=%h R2=%h R3=%h", dut.core1.acc, dut.core1.b_reg, dut.core1.r_regs[2], dut.core1.r_regs[3]);
            7'h33: if (!(dut.core1.acc === 8'h00)) $display("ASSERTION FAILED CPU 1 PC 33: Expected ACC=0, got ACC=%h B=%h R2=%h R3=%h", dut.core1.acc, dut.core1.b_reg, dut.core1.r_regs[2], dut.core1.r_regs[3]);
            7'h43: if (!(dut.core1.acc === dut.core1.r_regs[2])) $display("ASSERTION FAILED CPU 1 PC 43: Expected ACC=R2, got ACC=%h B=%h R2=%h R3=%h", dut.core1.acc, dut.core1.b_reg, dut.core1.r_regs[2], dut.core1.r_regs[3]);
        endcase
    end
end
