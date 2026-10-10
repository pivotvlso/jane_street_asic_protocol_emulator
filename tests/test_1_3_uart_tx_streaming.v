`default_nettype none
`timescale 1ns/1ps

module uart_tx_streaming;
    reg  [7:0] ui_in; wire [7:0] uo_out, uio_in, uio_out, uio_oe; reg ena, clk, rst_n;
    assign uio_in = uio_out;
    top dut (.ui_in(ui_in), .uo_out(uo_out), .uio_in(uio_in), .uio_out(uio_out), .uio_oe(uio_oe), .ena(ena), .clk(clk), .rst_n(rst_n));

    initial begin clk = 0; forever #10 clk = ~clk; end

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
        reg [3:0] exp_op [0:127];
        reg [3:0] exp_op1 [0:63];
        reg [3:0] exp_op2 [0:7];
        reg [14:0] exp_jmp [0:15];
        integer i, fail_cnt;
        begin
            op_file = {base_file, "_op.hex"};
            op1_file = {base_file, "_op1.hex"};
            op2_file = {base_file, "_op2.hex"};
            jmp_file = {base_file, "_jmp.hex"};
            
            for (i=0; i<128; i=i+1) exp_op[i] = 4'hx;
            for (i=0; i<64; i=i+1) exp_op1[i] = 4'hx;
            for (i=0; i<8; i=i+1) exp_op2[i] = 4'hx;
            for (i=0; i<16; i=i+1) exp_jmp[i] = 15'hx;
            $readmemh(op_file, exp_op);
            $readmemh(op1_file, exp_op1);
            $readmemh(op2_file, exp_op2);
            $readmemh(jmp_file, exp_jmp);

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
            end

            // Assertions
            fail_cnt = 0;
            if (cmd == 8'h00) begin
                for (i=0; i<128; i=i+1) if (exp_op[i] !== 4'hx && dut.cpu0_rom_op[i] !== exp_op[i]) begin $display("ASSERTION FAILED: CPU0 OP[%0d] expected %h got %h", i, exp_op[i], dut.cpu0_rom_op[i]); fail_cnt = fail_cnt + 1; end
            end

            if (fail_cnt > 0) begin
                $display("HALTING due to %0d RAM assertion failures before CPI execution.", fail_cnt);
                $finish;
            end
        end
    endtask

    initial begin
        ui_in = 0; ui_in[0] = 1; ena = 1; rst_n = 0; #50 rst_n = 1; #50;
        $display("[Test 1.3] UART TX Streaming - Sending 'B', 'U', 'G' back-to-back");
        
        load_cpu_ram(8'h00, "protocols/uart/uart_tx");
        ui_in[4] = 1; // Run CPU 0
        
        #100;
        // Test Fast Baud Streaming
        ui_in[0] = 0; spi_send_byte(8'h02); spi_send_byte(8'd5); ui_in[0] = 1; // Fast Baud (5 cycles)
        #100;
        
        // Push 3 bytes immediately into RX FIFO
        ui_in[0] = 0; spi_send_byte(8'h02); spi_send_byte("B"); ui_in[0] = 1;
        ui_in[0] = 0; spi_send_byte(8'h02); spi_send_byte("U"); ui_in[0] = 1;
        ui_in[0] = 0; spi_send_byte(8'h02); spi_send_byte("G"); ui_in[0] = 1;
        
        #80000;
        
        // Test Realistic Baud Streaming
        ui_in[0] = 0; spi_send_byte(8'h02); spi_send_byte(8'd57); ui_in[0] = 1; #20;
        #500;
        $display("Pushing 'H', 'E', 'L' into CPU 0 for Transmission...");
        ui_in[0] = 0; spi_send_byte(8'h02); spi_send_byte(8'h48); ui_in[0] = 1; #20;
        ui_in[0] = 0; spi_send_byte(8'h02); spi_send_byte(8'h45); ui_in[0] = 1; #20;
        ui_in[0] = 0; spi_send_byte(8'h02); spi_send_byte(8'h4C); ui_in[0] = 1; #20;
        
        #250000;

        $display("[Test 1.3] Completed. Check uart_tx_streaming.vcd to ensure the stop bits don't truncate!");
        $finish;
    end
    
    initial begin $dumpfile("uart_tx_streaming.vcd"); $dumpvars(0, uart_tx_streaming); end
endmodule
