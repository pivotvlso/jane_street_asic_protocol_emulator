`default_nettype none
`timescale 1ns/1ps

module uart_concurrent;
    reg  [7:0] ui_in; wire [7:0] uo_out, uio_in, uio_out, uio_oe; reg ena, clk, rst_n;
    
    // Physical hardware loopback! CPU 0 TX (Pin 0) feeds into CPU 1 RX (Pin 1)
    assign uio_in[1] = uio_out[0]; 
    assign uio_in[7:2] = 0;
    assign uio_in[0] = 0;
    
    top dut (.ui_in(ui_in), .uo_out(uo_out), .uio_in(uio_in), .uio_out(uio_out), .uio_oe(uio_oe), .ena(ena), .clk(clk), .rst_n(rst_n));

    initial begin clk = 0; forever #10 clk = ~clk; end

    always @(uio_out[0]) $display("[%0t] CPU 0 TX PIN: %b", $time, uio_out[0]);
    always @(uio_in[1])  $display("[%0t] CPU 1 RX PIN: %b", $time, uio_in[1]);

    task spi_send_byte(input [7:0] data);
        integer i; begin for (i = 7; i >= 0; i = i - 1) begin ui_in[2] = data[i]; #100 ui_in[1] = 1; #100 ui_in[1] = 0; end #60; end
    endtask

    task spi_read_byte(output [7:0] data);
        integer i; begin 
            data = 0;
            for (i = 7; i >= 0; i = i - 1) begin 
                ui_in[2] = 0;
                #100 ui_in[1] = 1; 
                data[i] = uo_out[0]; // Sample MISO
                #100 ui_in[1] = 0; 
            end 
            #60;
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

    reg [7:0] rx_data;

    initial begin
        ui_in = 0; ui_in[0] = 1; ena = 1; rst_n = 0; #50 rst_n = 1; #50;
        $display("[Test 1.4] UART Full-Duplex Concurrent (CPU 0 -> TX, CPU 1 -> RX)");
        
        // 1. Program CPU 0 with TX, CPU 1 with RX
        load_cpu_ram(8'h00, "protocols/uart/uart_tx"); // Command 0x00: CPU 0 RAM
        load_cpu_ram(8'h01, "protocols/uart/uart_rx"); // Command 0x01: CPU 1 RAM
        
        // 2. Start Both CPUs
        ui_in[0] = 0; spi_send_byte(8'h06); ui_in[0] = 1; #20; // RUN CPU 0
        ui_in[0] = 0; spi_send_byte(8'h07); ui_in[0] = 1; #20; // RUN CPU 1
        #100;
        
        // 3. Configure Baud Rates (Target 100 cycles-per-bit on the wire)
        ui_in[0] = 0; spi_send_byte(8'h02); spi_send_byte(8'd57); ui_in[0] = 1; #20;
        
        // CPU 1 (RX) has a ~62-cycle overhead per bit. Timer = 100 - 62 = 38.
        ui_in[0] = 0; spi_send_byte(8'h03); spi_send_byte(8'd62); ui_in[0] = 1; #20;
        ui_in[0] = 0; spi_send_byte(8'h03); spi_send_byte(8'd38); ui_in[0] = 1; #20;
        
        #500;
        
        // 4. Send Payload: 'X' (0x58) to CPU 0 (TX)
        $display("Pushing 'X' (0x58) into CPU 0 for Transmission...");
        ui_in[0] = 0; spi_send_byte(8'h02); spi_send_byte(8'h58); ui_in[0] = 1; #20;
        
        // Wait for Transmission & Reception to complete! (10 bits * 10 cycles * 20ns = 2000ns)
        #60000;
        
        // 5. Read back from CPU 1 TX FIFO to see if it successfully decoded 'X'!
        $display("Reading result from CPU 1...");
        ui_in[0] = 0; 
        spi_send_byte(8'h05); // Command 0x05: Read CPU 1 TX FIFO
        spi_read_byte(rx_data);
        ui_in[0] = 1;
        
        if (rx_data == 8'h58) begin
            $display("SUCCESS: CPU 1 perfectly received 'X' (0x58) from CPU 0!");
        end else begin
            $display("FAILED: CPU 1 received 0x%h instead of 0x58", rx_data);
        end
        
        $display("[Test 1.4] Completed. Check test_1_4_uart_concurrent.vcd");
        $finish;
    end
    
    initial begin $dumpfile("test_1_4_uart_concurrent.vcd"); $dumpvars(0, uart_concurrent); end
endmodule
