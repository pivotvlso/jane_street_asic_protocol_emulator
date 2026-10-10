`default_nettype none
`timescale 1ns/1ps

module uart_concurrent;
    reg  [7:0] ui_in; wire [7:0] uo_out, uio_in, uio_out, uio_oe; reg ena, clk, rst_n;
    
    // Physical hardware loopback! CPU 0 TX (Pin 0) feeds into CPU 1 RX (Pin 1)
    assign uio_in[1] = uio_out[0]; // CPU1 uses Pin 1 for RX
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
            end else if (cmd == 8'h09) begin
                $readmemh(op_file, dut.cpu3_rom_op);
                $readmemh(op1_file, dut.cpu3_rom_op1);
                $readmemh(op2_file, dut.cpu3_rom_op2);
                $readmemh(jmp_file, dut.cpu3_jmp_table);
            end

            // Assertions
            fail_cnt = 0;
            if (cmd == 8'h00) begin
                for (i=0; i<128; i=i+1) if (exp_op[i] !== 4'hx && dut.cpu0_rom_op[i] !== exp_op[i]) begin $display("ASSERTION FAILED: CPU0 OP[%0d] expected %h got %h", i, exp_op[i], dut.cpu0_rom_op[i]); fail_cnt = fail_cnt + 1; end
                for (i=0; i<64; i=i+1) if (exp_op1[i] !== 4'hx && dut.cpu0_rom_op1[i] !== exp_op1[i]) begin $display("ASSERTION FAILED: CPU0 OP1[%0d] expected %h got %h", i, exp_op1[i], dut.cpu0_rom_op1[i]); fail_cnt = fail_cnt + 1; end
                for (i=0; i<8; i=i+1) if (exp_op2[i] !== 4'hx && dut.cpu0_rom_op2[i] !== exp_op2[i]) begin $display("ASSERTION FAILED: CPU0 OP2[%0d] expected %h got %h", i, exp_op2[i], dut.cpu0_rom_op2[i]); fail_cnt = fail_cnt + 1; end
                for (i=0; i<16; i=i+1) if (exp_jmp[i] !== 15'hx && dut.cpu0_jmp_table[i] !== exp_jmp[i]) begin $display("ASSERTION FAILED: CPU0 JMP[%0d] expected %h got %h", i, exp_jmp[i], dut.cpu0_jmp_table[i]); fail_cnt = fail_cnt + 1; end
            end else if (cmd == 8'h01) begin
                for (i=0; i<128; i=i+1) if (exp_op[i] !== 4'hx && dut.cpu1_rom_op[i] !== exp_op[i]) begin $display("ASSERTION FAILED: CPU1 OP[%0d] expected %h got %h", i, exp_op[i], dut.cpu1_rom_op[i]); fail_cnt = fail_cnt + 1; end
                for (i=0; i<64; i=i+1) if (exp_op1[i] !== 4'hx && dut.cpu1_rom_op1[i] !== exp_op1[i]) begin $display("ASSERTION FAILED: CPU1 OP1[%0d] expected %h got %h", i, exp_op1[i], dut.cpu1_rom_op1[i]); fail_cnt = fail_cnt + 1; end
                for (i=0; i<8; i=i+1) if (exp_op2[i] !== 4'hx && dut.cpu1_rom_op2[i] !== exp_op2[i]) begin $display("ASSERTION FAILED: CPU1 OP2[%0d] expected %h got %h", i, exp_op2[i], dut.cpu1_rom_op2[i]); fail_cnt = fail_cnt + 1; end
                for (i=0; i<16; i=i+1) if (exp_jmp[i] !== 15'hx && dut.cpu1_jmp_table[i] !== exp_jmp[i]) begin $display("ASSERTION FAILED: CPU1 JMP[%0d] expected %h got %h", i, exp_jmp[i], dut.cpu1_jmp_table[i]); fail_cnt = fail_cnt + 1; end
            end else if (cmd == 8'h08) begin
                for (i=0; i<128; i=i+1) if (exp_op[i] !== 4'hx && dut.cpu2_rom_op[i] !== exp_op[i]) begin $display("ASSERTION FAILED: CPU2 OP[%0d] expected %h got %h", i, exp_op[i], dut.cpu2_rom_op[i]); fail_cnt = fail_cnt + 1; end
                for (i=0; i<64; i=i+1) if (exp_op1[i] !== 4'hx && dut.cpu2_rom_op1[i] !== exp_op1[i]) begin $display("ASSERTION FAILED: CPU2 OP1[%0d] expected %h got %h", i, exp_op1[i], dut.cpu2_rom_op1[i]); fail_cnt = fail_cnt + 1; end
                for (i=0; i<8; i=i+1) if (exp_op2[i] !== 4'hx && dut.cpu2_rom_op2[i] !== exp_op2[i]) begin $display("ASSERTION FAILED: CPU2 OP2[%0d] expected %h got %h", i, exp_op2[i], dut.cpu2_rom_op2[i]); fail_cnt = fail_cnt + 1; end
                for (i=0; i<16; i=i+1) if (exp_jmp[i] !== 15'hx && dut.cpu2_jmp_table[i] !== exp_jmp[i]) begin $display("ASSERTION FAILED: CPU2 JMP[%0d] expected %h got %h", i, exp_jmp[i], dut.cpu2_jmp_table[i]); fail_cnt = fail_cnt + 1; end
            end else if (cmd == 8'h09) begin
                for (i=0; i<128; i=i+1) if (exp_op[i] !== 4'hx && dut.cpu3_rom_op[i] !== exp_op[i]) begin $display("ASSERTION FAILED: CPU3 OP[%0d] expected %h got %h", i, exp_op[i], dut.cpu3_rom_op[i]); fail_cnt = fail_cnt + 1; end
                for (i=0; i<64; i=i+1) if (exp_op1[i] !== 4'hx && dut.cpu3_rom_op1[i] !== exp_op1[i]) begin $display("ASSERTION FAILED: CPU3 OP1[%0d] expected %h got %h", i, exp_op1[i], dut.cpu3_rom_op1[i]); fail_cnt = fail_cnt + 1; end
                for (i=0; i<8; i=i+1) if (exp_op2[i] !== 4'hx && dut.cpu3_rom_op2[i] !== exp_op2[i]) begin $display("ASSERTION FAILED: CPU3 OP2[%0d] expected %h got %h", i, exp_op2[i], dut.cpu3_rom_op2[i]); fail_cnt = fail_cnt + 1; end
                for (i=0; i<16; i=i+1) if (exp_jmp[i] !== 15'hx && dut.cpu3_jmp_table[i] !== exp_jmp[i]) begin $display("ASSERTION FAILED: CPU3 JMP[%0d] expected %h got %h", i, exp_jmp[i], dut.cpu3_jmp_table[i]); fail_cnt = fail_cnt + 1; end
            end

            if (fail_cnt > 0) begin
                $display("HALTING due to %0d RAM assertion failures before CPI execution.", fail_cnt);
                $finish;
            end
        end
    endtask

    reg [7:0] rx_data;

    initial begin
        ui_in = 0; ui_in[0] = 1; ena = 1; rst_n = 0; #50 rst_n = 1; #50;
        $display("[Test 1.7] UART Dual-Core RX (CPU0: TX, CPU1: RX_Core0, CPU2: RX_Core1)");
        
        // 1. Program CPU 0 with TX, CPU 1 with RX_Core0, CPU 2 with RX_Core1
        // 1. Program CPU 0 with RX0, CPU 1 with RX1, CPU 2 with TX, CPU 3 with Parity
        load_cpu_ram(8'h00, "protocols/uart/uart_rx_core0"); 
        load_cpu_ram(8'h01, "protocols/uart/uart_rx_core1"); 
        load_cpu_ram(8'h08, "protocols/uart/uart_tx"); 
        load_cpu_ram(8'h09, "protocols/uart/uart_parity"); 
        
        // 2. Start CPUs
        ui_in[4] = 1; // RUN CPU 0
        ui_in[5] = 1; // RUN CPU 1
        ui_in[6] = 1; // RUN CPU 2
        ui_in[7] = 1; // RUN CPU 3
        #100;
        
        // 3. Configure Baud Rates
        // TX Baud = 57 cycles (CPU 2)
        ui_in[0] = 0; spi_send_byte(8'h0A); spi_send_byte(8'd57); ui_in[0] = 1; #20;
        
        // RX Baud (Core 0 handles baud timer, CPU 0)
        // Full Baud = 57 cycles, Half Baud = 28 cycles
        ui_in[0] = 0; spi_send_byte(8'h02); spi_send_byte(8'd57); ui_in[0] = 1; #20;
        ui_in[0] = 0; spi_send_byte(8'h02); spi_send_byte(8'd28); ui_in[0] = 1; #20;
        
        #500;
        
        $display("STARTING CPU 3 PROBE");
        

        // 4. Send Payload: 'X' (0x58) to CPU 0 (TX)
        // 4. Send Payload: 'X' (0x58 = 88). Wait, to test Parity, let's send a byte.
        // Wait, 'uart_tx.asm' just sends whatever is in CPU 2 RX FIFO!
        $display("Pushing 'X' (0x58) into CPU 2 for Transmission...");
        ui_in[0] = 0; spi_send_byte(8'h0A); spi_send_byte(8'h58); ui_in[0] = 1; #20;
        
        // Wait for Transmission & Reception to complete!
        #60000;
        
        // 5. Read back from CPU 1 TX FIFO to see if it successfully decoded 'X'!
        $display("Reading result from CPU 1 (RX_Core1)...");
        ui_in[0] = 0; 
        spi_send_byte(8'h05); // Command 0x05: Read CPU 1 TX FIFO
        spi_read_byte(rx_data);
        ui_in[0] = 1;
        
        if (rx_data == 8'h58) begin
            $display("SUCCESS: CPU 1 perfectly received 'X' (0x58) from CPU 2!");
        end else begin
            $display("FAILED: CPU 1 received 0x%h instead of 0x58", rx_data);
        end

        // 6. Read back from CPU 3 TX FIFO (Parity Watchdog)
        // Wait, 'X' is 0x58 = 01011000. That's 3 ones. Odd parity.
        // Wait! In 8N1, there is NO parity bit sent by uart_tx.asm!
        // The parity watchdog assumes 7E1 format.
        // If we send 8 bits from TX without a parity bit, it's just raw data.
        // Let's just read it to see what happens.
        $display("Reading parity result from CPU 3...");
        ui_in[0] = 0;
        spi_send_byte(8'h0D);
        spi_read_byte(rx_data);
        ui_in[0] = 1;
        
        $display("CPU 3 Parity output: 0x%h", rx_data);
        
        $display("[Test 1.7] Completed.");
        $finish;
    end
    
    initial begin $dumpfile("test_1_7_uart_dual_core.vcd"); $dumpvars(0, uart_concurrent); end

endmodule
