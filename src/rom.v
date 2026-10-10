`default_nettype none

module rom_cpu0 (
    input wire [6:0] pc_op,
    output reg [3:0] op_data,
    input wire [5:0] pc_op1,
    output reg [3:0] op1_data,
    input wire [3:0] pc_op2,
    output reg [3:0] op2_data,
    input wire [3:0] jmp_addr,
    output reg [16:0] jmp_data
);
    always @(*) begin
        op_data = 0; op1_data = 0; op2_data = 0; jmp_data = 0;
        case (pc_op)
            default: op_data = 0;
        endcase
        case (pc_op1)
            default: op1_data = 0;
        endcase
        case (pc_op2)
            default: op2_data = 0;
        endcase
        case (jmp_addr)
            default: jmp_data = 0;
        endcase
    end
endmodule

module rom_cpu1 (
    input wire [6:0] pc_op,
    output reg [3:0] op_data,
    input wire [5:0] pc_op1,
    output reg [3:0] op1_data,
    input wire [3:0] pc_op2,
    output reg [3:0] op2_data,
    input wire [3:0] jmp_addr,
    output reg [16:0] jmp_data
);
    always @(*) begin
        op_data = 0; op1_data = 0; op2_data = 0; jmp_data = 0;
        case (pc_op)
            7'h0: op_data = 4'hA;
            7'h1: op_data = 4'hC;
            7'h2: op_data = 4'hA;
            7'h3: op_data = 4'hC;
            7'h4: op_data = 4'h9;
            7'h5: op_data = 4'h8;
            7'h6: op_data = 4'hB;
            7'h7: op_data = 4'hC;
            7'h8: op_data = 4'hA;
            7'h9: op_data = 4'h2;
            7'ha: op_data = 4'hE;
            7'hb: op_data = 4'hD;
            7'hc: op_data = 4'hA;
            7'hd: op_data = 4'hC;
            7'he: op_data = 4'hB;
            7'hf: op_data = 4'hE;
            7'h10: op_data = 4'hB;
            7'h11: op_data = 4'hC;
            7'h12: op_data = 4'hA;
            7'h13: op_data = 4'h2;
            7'h14: op_data = 4'hE;
            7'h15: op_data = 4'hD;
            7'h16: op_data = 4'hB;
            7'h17: op_data = 4'hE;
            7'h18: op_data = 4'hD;
            7'h19: op_data = 4'hC;
            7'h1a: op_data = 4'hA;
            7'h1b: op_data = 4'h1;
            7'h1c: op_data = 4'hE;
            7'h1d: op_data = 4'hD;
            7'h1e: op_data = 4'h8;
            7'h1f: op_data = 4'h8;
            7'h20: op_data = 4'hA;
            7'h21: op_data = 4'hC;
            7'h22: op_data = 4'hB;
            7'h23: op_data = 4'hE;
            7'h24: op_data = 4'hA;
            7'h25: op_data = 4'hC;
            7'h26: op_data = 4'hB;
            7'h27: op_data = 4'hE;
            7'h28: op_data = 4'h8;
            7'h29: op_data = 4'h9;
            7'h2a: op_data = 4'hA;
            7'h2b: op_data = 4'hC;
            7'h2c: op_data = 4'hB;
            7'h2d: op_data = 4'hE;
            7'h2e: op_data = 4'hD;
            7'h2f: op_data = 4'hA;
            7'h30: op_data = 4'hC;
            7'h31: op_data = 4'hB;
            7'h32: op_data = 4'h3;
            7'h33: op_data = 4'hC;
            7'h34: op_data = 4'hE;
            7'h35: op_data = 4'h9;
            7'h36: op_data = 4'h8;
            7'h37: op_data = 4'hD;
            7'h38: op_data = 4'h8;
            7'h39: op_data = 4'h9;
            7'h3a: op_data = 4'hD;
            7'h3b: op_data = 4'hD;
            default: op_data = 0;
        endcase
        case (pc_op1)
            6'h0: op1_data = 4'h0;
            6'h1: op1_data = 4'hF;
            6'h2: op1_data = 4'h0;
            6'h3: op1_data = 4'h2;
            6'h4: op1_data = 4'h1;
            6'h5: op1_data = 4'h0;
            6'h6: op1_data = 4'h8;
            6'h7: op1_data = 4'h1;
            6'h8: op1_data = 4'h0;
            6'h9: op1_data = 4'h1;
            6'ha: op1_data = 4'h0;
            6'hb: op1_data = 4'h0;
            6'hc: op1_data = 4'h7;
            6'hd: op1_data = 4'h7;
            6'he: op1_data = 4'h3;
            6'hf: op1_data = 4'h8;
            6'h10: op1_data = 4'h1;
            6'h11: op1_data = 4'h0;
            6'h12: op1_data = 4'h1;
            6'h13: op1_data = 4'h4;
            6'h14: op1_data = 4'hA;
            6'h15: op1_data = 4'h5;
            6'h16: op1_data = 4'h6;
            6'h17: op1_data = 4'h1;
            6'h18: op1_data = 4'h0;
            6'h19: op1_data = 4'h7;
            6'h1a: op1_data = 4'h8;
            6'h1b: op1_data = 4'h0;
            6'h1c: op1_data = 4'h1;
            6'h1d: op1_data = 4'h1;
            6'h1e: op1_data = 4'h7;
            6'h1f: op1_data = 4'h7;
            6'h20: op1_data = 4'h9;
            6'h21: op1_data = 4'h1;
            6'h22: op1_data = 4'h7;
            6'h23: op1_data = 4'h7;
            6'h24: op1_data = 4'hA;
            6'h25: op1_data = 4'h0;
            6'h26: op1_data = 4'h1;
            6'h27: op1_data = 4'h1;
            6'h28: op1_data = 4'h7;
            6'h29: op1_data = 4'h7;
            6'h2a: op1_data = 4'hB;
            6'h2b: op1_data = 4'h0;
            6'h2c: op1_data = 4'h0;
            6'h2d: op1_data = 4'h1;
            6'h2e: op1_data = 4'h2;
            6'h2f: op1_data = 4'h2;
            6'h30: op1_data = 4'hC;
            6'h31: op1_data = 4'h1;
            6'h32: op1_data = 4'h0;
            6'h33: op1_data = 4'h2;
            6'h34: op1_data = 4'h1;
            6'h35: op1_data = 4'h0;
            6'h36: op1_data = 4'h2;
            6'h37: op1_data = 4'h2;
            default: op1_data = 0;
        endcase
        case (pc_op2)
            4'h0: op2_data = 4'h3;
            4'h1: op2_data = 4'h0;
            4'h2: op2_data = 4'h8;
            4'h3: op2_data = 4'hF;
            4'h4: op2_data = 4'h8;
            4'h5: op2_data = 4'h1;
            4'h6: op2_data = 4'h5;
            4'h7: op2_data = 4'h5;
            4'h8: op2_data = 4'h5;
            4'h9: op2_data = 4'h1;
            default: op2_data = 0;
        endcase
        case (jmp_addr)
            4'h0: jmp_data = 17'h01862;
            4'h1: jmp_data = 17'h05945;
            4'h2: jmp_data = 17'h030B3;
            4'h3: jmp_data = 17'h038D4;
            4'h4: jmp_data = 17'h040F4;
            4'h5: jmp_data = 17'h06575;
            4'h6: jmp_data = 17'h0BEC9;
            4'h7: jmp_data = 17'h079B6;
            4'h8: jmp_data = 17'h0EF7A;
            4'h9: jmp_data = 17'h089F7;
            4'ha: jmp_data = 17'h09A38;
            4'hb: jmp_data = 17'h0B299;
            4'hc: jmp_data = 17'h0E34A;
            4'hd: jmp_data = 17'h0D71A;
            4'he: jmp_data = 17'h00000;
            4'hf: jmp_data = 17'h00000;
            default: jmp_data = 0;
        endcase
    end
endmodule

module rom_cpu2 (
    input wire [6:0] pc_op,
    output reg [3:0] op_data,
    input wire [5:0] pc_op1,
    output reg [3:0] op1_data,
    input wire [3:0] pc_op2,
    output reg [3:0] op2_data,
    input wire [3:0] jmp_addr,
    output reg [16:0] jmp_data
);
    always @(*) begin
        op_data = 0; op1_data = 0; op2_data = 0; jmp_data = 0;
        case (pc_op)
            7'h0: op_data = 4'hA;
            7'h1: op_data = 4'hC;
            7'h2: op_data = 4'hB;
            7'h3: op_data = 4'hC;
            7'h4: op_data = 4'hA;
            7'h5: op_data = 4'h2;
            7'h6: op_data = 4'hE;
            7'h7: op_data = 4'hD;
            7'h8: op_data = 4'hB;
            7'h9: op_data = 4'hC;
            7'ha: op_data = 4'hE;
            7'hb: op_data = 4'hD;
            7'hc: op_data = 4'hC;
            7'hd: op_data = 4'hA;
            7'he: op_data = 4'h1;
            7'hf: op_data = 4'hE;
            7'h10: op_data = 4'hD;
            7'h11: op_data = 4'hA;
            7'h12: op_data = 4'hC;
            7'h13: op_data = 4'hA;
            7'h14: op_data = 4'hD;
            7'h15: op_data = 4'hA;
            7'h16: op_data = 4'hC;
            7'h17: op_data = 4'hB;
            7'h18: op_data = 4'hD;
            7'h19: op_data = 4'hA;
            7'h1a: op_data = 4'hC;
            7'h1b: op_data = 4'hB;
            7'h1c: op_data = 4'h0;
            7'h1d: op_data = 4'hC;
            7'h1e: op_data = 4'hC;
            7'h1f: op_data = 4'hA;
            7'h20: op_data = 4'h1;
            7'h21: op_data = 4'hE;
            7'h22: op_data = 4'hD;
            7'h23: op_data = 4'hB;
            7'h24: op_data = 4'hD;
            7'h25: op_data = 4'hB;
            7'h26: op_data = 4'hC;
            7'h27: op_data = 4'hA;
            7'h28: op_data = 4'h2;
            7'h29: op_data = 4'hE;
            7'h2a: op_data = 4'hA;
            7'h2b: op_data = 4'hC;
            7'h2c: op_data = 4'hA;
            7'h2d: op_data = 4'hC;
            7'h2e: op_data = 4'hA;
            7'h2f: op_data = 4'hC;
            7'h30: op_data = 4'hB;
            7'h31: op_data = 4'hC;
            7'h32: op_data = 4'hA;
            7'h33: op_data = 4'h2;
            7'h34: op_data = 4'hE;
            7'h35: op_data = 4'hB;
            7'h36: op_data = 4'hC;
            7'h37: op_data = 4'hD;
            default: op_data = 0;
        endcase
        case (pc_op1)
            6'h0: op1_data = 4'h0;
            6'h1: op1_data = 4'h3;
            6'h2: op1_data = 4'h8;
            6'h3: op1_data = 4'h1;
            6'h4: op1_data = 4'h0;
            6'h5: op1_data = 4'h1;
            6'h6: op1_data = 4'h0;
            6'h7: op1_data = 4'h9;
            6'h8: op1_data = 4'h2;
            6'h9: op1_data = 4'h2;
            6'ha: op1_data = 4'h3;
            6'hb: op1_data = 4'h1;
            6'hc: op1_data = 4'h0;
            6'hd: op1_data = 4'h4;
            6'he: op1_data = 4'h5;
            6'hf: op1_data = 4'h0;
            6'h10: op1_data = 4'h3;
            6'h11: op1_data = 4'h0;
            6'h12: op1_data = 4'h6;
            6'h13: op1_data = 4'h0;
            6'h14: op1_data = 4'h3;
            6'h15: op1_data = 4'h2;
            6'h16: op1_data = 4'h6;
            6'h17: op1_data = 4'h0;
            6'h18: op1_data = 4'h1;
            6'h19: op1_data = 4'h3;
            6'h1a: op1_data = 4'h3;
            6'h1b: op1_data = 4'h1;
            6'h1c: op1_data = 4'h0;
            6'h1d: op1_data = 4'h7;
            6'h1e: op1_data = 4'h8;
            6'h1f: op1_data = 4'h2;
            6'h20: op1_data = 4'h6;
            6'h21: op1_data = 4'h8;
            6'h22: op1_data = 4'h1;
            6'h23: op1_data = 4'h0;
            6'h24: op1_data = 4'h9;
            6'h25: op1_data = 4'h0;
            6'h26: op1_data = 4'hA;
            6'h27: op1_data = 4'h0;
            6'h28: op1_data = 4'h3;
            6'h29: op1_data = 4'h0;
            6'h2a: op1_data = 4'h2;
            6'h2b: op1_data = 4'h8;
            6'h2c: op1_data = 4'h1;
            6'h2d: op1_data = 4'h0;
            6'h2e: op1_data = 4'hA;
            6'h2f: op1_data = 4'h2;
            6'h30: op1_data = 4'hA;
            6'h31: op1_data = 4'h0;
            default: op1_data = 0;
        endcase
        case (pc_op2)
            4'h0: op2_data = 4'h0;
            4'h1: op2_data = 4'h4;
            4'h2: op2_data = 4'h1;
            4'h3: op2_data = 4'h0;
            4'h4: op2_data = 4'h2;
            4'h5: op2_data = 4'h0;
            4'h6: op2_data = 4'h1;
            4'h7: op2_data = 4'h6;
            4'h8: op2_data = 4'h8;
            4'h9: op2_data = 4'h0;
            4'ha: op2_data = 4'h0;
            4'hb: op2_data = 4'h1;
            4'hc: op2_data = 4'h8;
            default: op2_data = 0;
        endcase
        case (jmp_addr)
            4'h0: jmp_data = 17'h00821;
            4'h1: jmp_data = 17'h02072;
            4'h2: jmp_data = 17'h030B2;
            4'h3: jmp_data = 17'h05535;
            4'h4: jmp_data = 17'h044F3;
            4'h5: jmp_data = 17'h06576;
            4'h6: jmp_data = 17'h0BEAC;
            4'h7: jmp_data = 17'h08DF8;
            4'h8: jmp_data = 17'h09618;
            4'h9: jmp_data = 17'h09618;
            4'ha: jmp_data = 17'h0C2BC;
            4'hb: jmp_data = 17'h00000;
            4'hc: jmp_data = 17'h00000;
            4'hd: jmp_data = 17'h00000;
            4'he: jmp_data = 17'h00000;
            4'hf: jmp_data = 17'h00000;
            default: jmp_data = 0;
        endcase
    end
endmodule

module rom_cpu3 (
    input wire [6:0] pc_op,
    output reg [3:0] op_data,
    input wire [5:0] pc_op1,
    output reg [3:0] op1_data,
    input wire [3:0] pc_op2,
    output reg [3:0] op2_data,
    input wire [3:0] jmp_addr,
    output reg [16:0] jmp_data
);
    always @(*) begin
        op_data = 0; op1_data = 0; op2_data = 0; jmp_data = 0;
        case (pc_op)
            7'h0: op_data = 4'hA;
            7'h1: op_data = 4'hC;
            7'h2: op_data = 4'hB;
            7'h3: op_data = 4'hC;
            7'h4: op_data = 4'h7;
            7'h5: op_data = 4'hB;
            7'h6: op_data = 4'h1;
            7'h7: op_data = 4'hE;
            7'h8: op_data = 4'hD;
            7'h9: op_data = 4'hA;
            7'ha: op_data = 4'hC;
            7'hb: op_data = 4'hB;
            7'hc: op_data = 4'hC;
            7'hd: op_data = 4'hA;
            7'he: op_data = 4'h2;
            7'hf: op_data = 4'hE;
            7'h10: op_data = 4'hB;
            7'h11: op_data = 4'hC;
            7'h12: op_data = 4'hA;
            7'h13: op_data = 4'h2;
            7'h14: op_data = 4'hC;
            7'h15: op_data = 4'hB;
            7'h16: op_data = 4'h4;
            7'h17: op_data = 4'hC;
            7'h18: op_data = 4'hA;
            7'h19: op_data = 4'hC;
            7'h1a: op_data = 4'hB;
            7'h1b: op_data = 4'h1;
            7'h1c: op_data = 4'hC;
            7'h1d: op_data = 4'hE;
            7'h1e: op_data = 4'hD;
            7'h1f: op_data = 4'hB;
            7'h20: op_data = 4'hC;
            7'h21: op_data = 4'hA;
            7'h22: op_data = 4'h2;
            7'h23: op_data = 4'hE;
            7'h24: op_data = 4'hA;
            7'h25: op_data = 4'hC;
            7'h26: op_data = 4'hD;
            default: op_data = 0;
        endcase
        case (pc_op1)
            6'h0: op1_data = 4'h0;
            6'h1: op1_data = 4'h3;
            6'h2: op1_data = 4'h5;
            6'h3: op1_data = 4'h2;
            6'h4: op1_data = 4'hF;
            6'h5: op1_data = 4'h2;
            6'h6: op1_data = 4'h1;
            6'h7: op1_data = 4'h2;
            6'h8: op1_data = 4'h0;
            6'h9: op1_data = 4'h3;
            6'ha: op1_data = 4'h8;
            6'hb: op1_data = 4'h1;
            6'hc: op1_data = 4'h0;
            6'hd: op1_data = 4'h4;
            6'he: op1_data = 4'h2;
            6'hf: op1_data = 4'h1;
            6'h10: op1_data = 4'h0;
            6'h11: op1_data = 4'h9;
            6'h12: op1_data = 4'h2;
            6'h13: op1_data = 4'h2;
            6'h14: op1_data = 4'h0;
            6'h15: op1_data = 4'h1;
            6'h16: op1_data = 4'h3;
            6'h17: op1_data = 4'h3;
            6'h18: op1_data = 4'h3;
            6'h19: op1_data = 4'h0;
            6'h1a: op1_data = 4'h8;
            6'h1b: op1_data = 4'h1;
            6'h1c: op1_data = 4'h0;
            6'h1d: op1_data = 4'h5;
            6'h1e: op1_data = 4'h0;
            6'h1f: op1_data = 4'h9;
            6'h20: op1_data = 4'h0;
            default: op1_data = 0;
        endcase
        case (pc_op2)
            4'h0: op2_data = 4'h0;
            4'h1: op2_data = 4'hE;
            4'h2: op2_data = 4'h8;
            4'h3: op2_data = 4'h4;
            4'h4: op2_data = 4'h1;
            4'h5: op2_data = 4'h1;
            4'h6: op2_data = 4'h4;
            4'h7: op2_data = 4'h2;
            default: op2_data = 0;
        endcase
        case (jmp_addr)
            4'h0: jmp_data = 17'h00821;
            4'h1: jmp_data = 17'h02482;
            4'h2: jmp_data = 17'h07DA6;
            4'h3: jmp_data = 17'h02CA3;
            4'h4: jmp_data = 17'h02CA3;
            4'h5: jmp_data = 17'h07DA6;
            4'h6: jmp_data = 17'h00000;
            4'h7: jmp_data = 17'h00000;
            4'h8: jmp_data = 17'h00000;
            4'h9: jmp_data = 17'h00000;
            4'ha: jmp_data = 17'h00000;
            4'hb: jmp_data = 17'h00000;
            4'hc: jmp_data = 17'h00000;
            4'hd: jmp_data = 17'h00000;
            4'he: jmp_data = 17'h00000;
            4'hf: jmp_data = 17'h00000;
            default: jmp_data = 0;
        endcase
    end
endmodule

