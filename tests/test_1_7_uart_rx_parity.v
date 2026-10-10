`default_nettype none
`timescale 1ns/1ps

module test_1_7_uart_rx_parity;
    reg  [7:0] ui_in;
    wire [7:0] uo_out, uio_out, uio_oe;
    reg  [7:0] uio_in;
    reg        ena, clk, rst_n;
    
    top dut (.ui_in(ui_in), .uo_out(uo_out), .uio_in(uio_in), .uio_out(uio_out), .uio_oe(uio_oe), .ena(ena), .clk(clk), .rst_n(rst_n));

    initial begin clk = 0; forever #10 clk = ~clk; end

    task spi_send_byte(input [7:0] data);
        integer i; begin for (i = 7; i >= 0; i = i - 1) begin ui_in[2] = data[i]; #100 ui_in[1] = 1; #100 ui_in[1] = 0; end #60; end
    endtask

    task spi_read_byte(output [7:0] data);
        integer i; begin data = 0; for (i = 7; i >= 0; i = i - 1) begin ui_in[2] = 0; #100 ui_in[1] = 1; data[i] = uo_out[0]; #100 ui_in[1] = 0; end #60; end
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

    task send_uart_byte_parity(input [7:0] data, input integer baud_cycles);
        integer i; begin
            uio_in[1] = 0; // START BIT
            #(baud_cycles * 20);
            for (i = 0; i < 8; i = i + 1) begin
                uio_in[1] = data[i]; // 7 Data Bits + 1 Parity Bit combined into 'data'
                #(baud_cycles * 20);
            end
            
            uio_in[1] = 1; // STOP BIT
            #(baud_cycles * 20);
            
            uio_in[1] = 1; // Idle line high
            #(baud_cycles * 20);
        end
    endtask

    reg [7:0] data_out;
    reg [7:0] parity_out;

    initial begin
        ui_in = 0; ui_in[0] = 1; uio_in = 8'hFF; ena = 1; rst_n = 0; #50 rst_n = 1; #50;
        $display("[Test 1.7] UART RX Parallel Parity Check (Dual-Core)");
        
        load_cpu_ram(8'h01, "protocols/uart/uart_rx"); // Load CPU 1
        load_cpu_ram(8'h08, "protocols/uart/uart_parity"); // Load CPU 2 (Command 0x08)
        
        // Start CPU 1 and CPU 2 simultaneously!
        ui_in[0] = 0; spi_send_byte(8'h07); ui_in[0] = 1; #20; // RUN CPU 1
        ui_in[0] = 0; spi_send_byte(8'h0E); ui_in[0] = 1; #20; // RUN CPU 2 (Command 0x0E)
        #100;
        
        // Target: 100 cycles per bit
        // CPU 1 (RX) Overhead: ~39 cycles. Timer = 61. Half = 30.
        ui_in[0] = 0; spi_send_byte(8'h03); spi_send_byte(8'd62); ui_in[0] = 1; #20;
        ui_in[0] = 0; spi_send_byte(8'h03); spi_send_byte(8'd38); ui_in[0] = 1; #20;
        
        // CPU 2 (Parity) Overhead: ~50 cycles. Timer = 50. Half = 45.
        ui_in[0] = 0; spi_send_byte(8'h0A); spi_send_byte(8'd45); ui_in[0] = 1; #20;
        ui_in[0] = 0; spi_send_byte(8'h0A); spi_send_byte(8'd50); ui_in[0] = 1; #20;
        
        #500;
        
        // ----------------------------------------------------
        // 1. SEND VALID PARITY (7E1)
        // Data: 'A' (0x41) is 7 bits: 1000001 (Two 1s).
        // Parity is 0. So byte is 0x41. Total 1s = 2 (Even).
        // ----------------------------------------------------
        $display("Sending byte 'A' (0x41) with VALID Parity (0)...");
        send_uart_byte_parity(8'h41, 100); 
        #4000;
        
        // Read CPU 1 (Data)
        ui_in[0] = 0; spi_send_byte(8'h05); spi_read_byte(data_out); ui_in[0] = 1; #20;
        // Read CPU 2 (Parity Flag)
        ui_in[0] = 0; spi_send_byte(8'h0C); spi_read_byte(parity_out); ui_in[0] = 1; #20;
        
        $display("CPU 1 Data: 0x%h, CPU 2 Parity Flag: 0x%h", data_out, parity_out);
        if (data_out == 8'h41 && parity_out == 8'h00) $display("PASS: Perfect Valid Receive!");
        else $display("FAILED!");
        
        #500;
        
        // ----------------------------------------------------
        // 2. SEND INVALID PARITY (7E1)
        // Data: 'A' (0x41). If we set Parity (MSB) to 1 -> 0xC1.
        // Total 1s = 3 (Odd). So Parity is INVALID!
        // ----------------------------------------------------
        $display("Sending byte 0xC1 (0x41 + Parity=1) with INVALID Parity...");
        send_uart_byte_parity(8'hC1, 100); 
        #4000;
        
        ui_in[0] = 0; spi_send_byte(8'h05); spi_read_byte(data_out); ui_in[0] = 1; #20;
        ui_in[0] = 0; spi_send_byte(8'h0C); spi_read_byte(parity_out); ui_in[0] = 1; #20;
        
        $display("CPU 1 Data: 0x%h, CPU 2 Parity Flag: 0x%h", data_out, parity_out);
        if (data_out == 8'hC1 && parity_out == 8'hFF) $display("PASS: Correctly caught Parity Error (0xFF)!");
        else $display("FAILED!");
        
        $display("[Test 1.7] Completed. Check test_1_7_uart_rx_parity.vcd");
        $finish;
    end
    
    initial begin $dumpfile("test_1_7_uart_rx_parity.vcd"); $dumpvars(0, test_1_7_uart_rx_parity); end
endmodule
