`default_nettype none
`timescale 1ns/1ps

module uart_tx_basic;
    reg  [7:0] ui_in;
    wire [7:0] uo_out;
    wire [7:0] uio_in, uio_out, uio_oe;
    reg        ena, clk, rst_n;

    assign uio_in = uio_out; // Loopback
    
    top dut (.ui_in(ui_in), .uo_out(uo_out), .uio_in(uio_in),
             .uio_out(uio_out), .uio_oe(uio_oe), .ena(ena), .clk(clk), .rst_n(rst_n));

    initial begin clk = 0; forever #10 clk = ~clk; end

    task spi_send_byte(input [7:0] data);
        integer i; begin
            for (i = 7; i >= 0; i = i - 1) begin
                ui_in[2] = data[i]; #100 ui_in[1] = 1; #100 ui_in[1] = 0;
            end
            #60; // Allow internal state machines to finish syncing
        end
    endtask

    task load_cpu_ram(input [7:0] cmd, input [8*100-1:0] base_file);
        reg [8*150-1:0] op_file, op1_file, op2_file, jmp_file;
        begin
            op_file = {base_file, "_op.hex"};
            op1_file = {base_file, "_op1.hex"};
            op2_file = {base_file, "_op2.hex"};
            jmp_file = {base_file, "_jmp.hex"};
            
            if (cmd == 8'h00) begin
                $readmemh(op_file, dut.cpu0_rom_op);
                $readmemh(op1_file, dut.cpu0_rom_op1);
                $readmemh(op2_file, dut.cpu0_rom_op2);
                $readmemh(jmp_file, dut.cpu0_jmp_table);
            end else if (cmd == 8'h01) begin
                $readmemh(op_file, dut.cpu1_rom_op);
                $readmemh(op1_file, dut.cpu1_rom_op1);
                $readmemh(op2_file, dut.cpu1_rom_op2);
                $readmemh(jmp_file, dut.cpu1_jmp_table);
            end else if (cmd == 8'h08) begin
                $readmemh(op_file, dut.cpu2_rom_op);
                $readmemh(op1_file, dut.cpu2_rom_op1);
                $readmemh(op2_file, dut.cpu2_rom_op2);
                $readmemh(jmp_file, dut.cpu2_jmp_table);
            end else if (cmd == 8'h09) begin
                $readmemh(op_file, dut.cpu3_rom_op);
                $readmemh(op1_file, dut.cpu3_rom_op1);
                $readmemh(op2_file, dut.cpu3_rom_op2);
                $readmemh(jmp_file, dut.cpu3_jmp_table);
            end
        end
    endtask

    initial begin
        ui_in = 0; ui_in[0] = 1; ena = 1; rst_n = 0; #50 rst_n = 1; #50;
        $display("[Test 1.1] UART TX Basic - Sending 'A'");
        
        load_cpu_ram("protocols/uart/uart_tx");
        ui_in[0] = 0; spi_send_byte(8'h06); ui_in[0] = 1; // Run CPU 0
        
        #100;
        ui_in[0] = 0; spi_send_byte(8'h02); spi_send_byte(8'd5); ui_in[0] = 1; // Baud 5
        #100;
        ui_in[0] = 0; spi_send_byte(8'h02); spi_send_byte(8'h41); ui_in[0] = 1; // 'A'
        
        #30000;
        $display("[Test 1.1] Completed. Check uart_tx_basic.vcd");
        $finish;
    end
    
    initial begin $dumpfile("uart_tx_basic.vcd"); $dumpvars(0, uart_tx_basic); end
endmodule
