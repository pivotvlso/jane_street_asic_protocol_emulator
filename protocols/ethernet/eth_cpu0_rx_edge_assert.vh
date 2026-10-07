reg [6:0] last_pc_0;
always @(posedge clk) begin
    if (dut.core0.run && dut.core0.state == 3'd4) begin
        last_pc_0 <= dut.core0.exec_pc;
    end
end
always @(posedge clk) begin
    if (dut.core0.run && dut.core0.state == 3'd1) begin
        case (last_pc_0)
            7'h02: if (!(dut.core0.r_regs[7] === dut.core0.acc)) $display("ASSERTION FAILED CPU 0 PC 02: Expected R7=ACC, got ACC=%h B=%h R2=%h R3=%h", dut.core0.acc, dut.core0.b_reg, dut.core0.r_regs[2], dut.core0.r_regs[3]);
            7'h04: if (!(dut.core0.acc === {4'b0, dut.core0.pin_state})) $display("ASSERTION FAILED CPU 0 PC 04: Expected ACC=PIN_STATE, got ACC=%h B=%h R2=%h R3=%h", dut.core0.acc, dut.core0.b_reg, dut.core0.r_regs[2], dut.core0.r_regs[3]);
            7'h06: if (!(dut.core0.b_reg === dut.core0.acc)) $display("ASSERTION FAILED CPU 0 PC 06: Expected B=ACC, got ACC=%h B=%h R2=%h R3=%h", dut.core0.acc, dut.core0.b_reg, dut.core0.r_regs[2], dut.core0.r_regs[3]);
            7'h08: if (!(dut.core0.acc === 8'h01)) $display("ASSERTION FAILED CPU 0 PC 08: Expected ACC=1 Mask Pin 0, got ACC=%h B=%h R2=%h R3=%h", dut.core0.acc, dut.core0.b_reg, dut.core0.r_regs[2], dut.core0.r_regs[3]);
            7'h0D: if (!(dut.core0.acc === {4'b0, dut.core0.pin_state})) $display("ASSERTION FAILED CPU 0 PC 0D: Expected ACC=PIN_STATE, got ACC=%h B=%h R2=%h R3=%h", dut.core0.acc, dut.core0.b_reg, dut.core0.r_regs[2], dut.core0.r_regs[3]);
            7'h0F: if (!(dut.core0.b_reg === dut.core0.acc)) $display("ASSERTION FAILED CPU 0 PC 0F: Expected B=ACC, got ACC=%h B=%h R2=%h R3=%h", dut.core0.acc, dut.core0.b_reg, dut.core0.r_regs[2], dut.core0.r_regs[3]);
            7'h11: if (!(dut.core0.acc === 8'h01)) $display("ASSERTION FAILED CPU 0 PC 11: Expected ACC=1, got ACC=%h B=%h R2=%h R3=%h", dut.core0.acc, dut.core0.b_reg, dut.core0.r_regs[2], dut.core0.r_regs[3]);
            7'h14: if (!(dut.core0.r_regs[3] === dut.core0.acc)) $display("ASSERTION FAILED CPU 0 PC 14: Expected R3=ACC, got ACC=%h B=%h R2=%h R3=%h", dut.core0.acc, dut.core0.b_reg, dut.core0.r_regs[2], dut.core0.r_regs[3]);
            7'h16: if (!(dut.core0.b_reg === dut.core0.acc)) $display("ASSERTION FAILED CPU 0 PC 16: Expected B=ACC, got ACC=%h B=%h R2=%h R3=%h", dut.core0.acc, dut.core0.b_reg, dut.core0.r_regs[2], dut.core0.r_regs[3]);
            7'h18: if (!(dut.core0.acc === dut.core0.r_regs[2])) $display("ASSERTION FAILED CPU 0 PC 18: Expected ACC=R2, got ACC=%h B=%h R2=%h R3=%h", dut.core0.acc, dut.core0.b_reg, dut.core0.r_regs[2], dut.core0.r_regs[3]);
            7'h21: if (!(dut.core0.acc === dut.core0.r_regs[3])) $display("ASSERTION FAILED CPU 0 PC 21: Expected ACC=R3, got ACC=%h B=%h R2=%h R3=%h", dut.core0.acc, dut.core0.b_reg, dut.core0.r_regs[2], dut.core0.r_regs[3]);
            7'h23: if (!(dut.core0.r_regs[2] === dut.core0.acc)) $display("ASSERTION FAILED CPU 0 PC 23: Expected R2=ACC, got ACC=%h B=%h R2=%h R3=%h", dut.core0.acc, dut.core0.b_reg, dut.core0.r_regs[2], dut.core0.r_regs[3]);
            7'h25: if (!(dut.core0.acc === dut.core0.r_regs[3])) $display("ASSERTION FAILED CPU 0 PC 25: Expected ACC=R3, got ACC=%h B=%h R2=%h R3=%h", dut.core0.acc, dut.core0.b_reg, dut.core0.r_regs[2], dut.core0.r_regs[3]);
            7'h27: if (!(dut.core0.b_reg === dut.core0.acc)) $display("ASSERTION FAILED CPU 0 PC 27: Expected B=ACC, got ACC=%h B=%h R2=%h R3=%h", dut.core0.acc, dut.core0.b_reg, dut.core0.r_regs[2], dut.core0.r_regs[3]);
            7'h29: if (!(dut.core0.acc === 8'h01)) $display("ASSERTION FAILED CPU 0 PC 29: Expected ACC=1, got ACC=%h B=%h R2=%h R3=%h", dut.core0.acc, dut.core0.b_reg, dut.core0.r_regs[2], dut.core0.r_regs[3]);
            7'h2E: if (!(dut.core0.acc === dut.core0.r_regs[7])) $display("ASSERTION FAILED CPU 0 PC 2E: Expected ACC=R7, got ACC=%h B=%h R2=%h R3=%h", dut.core0.acc, dut.core0.b_reg, dut.core0.r_regs[2], dut.core0.r_regs[3]);
            7'h34: if (!(dut.core0.acc === {4'b0, dut.core0.pin_state})) $display("ASSERTION FAILED CPU 0 PC 34: Expected ACC=PIN_STATE, got ACC=%h B=%h R2=%h R3=%h", dut.core0.acc, dut.core0.b_reg, dut.core0.r_regs[2], dut.core0.r_regs[3]);
            7'h36: if (!(dut.core0.b_reg === dut.core0.acc)) $display("ASSERTION FAILED CPU 0 PC 36: Expected B=ACC, got ACC=%h B=%h R2=%h R3=%h", dut.core0.acc, dut.core0.b_reg, dut.core0.r_regs[2], dut.core0.r_regs[3]);
            7'h38: if (!(dut.core0.acc === 8'h01)) $display("ASSERTION FAILED CPU 0 PC 38: Expected ACC=1, got ACC=%h B=%h R2=%h R3=%h", dut.core0.acc, dut.core0.b_reg, dut.core0.r_regs[2], dut.core0.r_regs[3]);
            7'h3B: if (!(dut.core0.r_regs[2] === dut.core0.acc)) $display("ASSERTION FAILED CPU 0 PC 3B: Expected R2=ACC, got ACC=%h B=%h R2=%h R3=%h", dut.core0.acc, dut.core0.b_reg, dut.core0.r_regs[2], dut.core0.r_regs[3]);
        endcase
    end
end
