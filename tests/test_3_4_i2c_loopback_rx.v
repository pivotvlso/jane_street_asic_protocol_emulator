`default_nettype none
`timescale 1ns/1ps

module test_3_4_i2c_loopback_rx;
    reg  [7:0] ui_in;
    wire [7:0] uo_out;
    wire [7:0] uio_in;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;
    reg        ena, clk, rst_n;
    
    // I2C Open-Drain Bus Simulation
    // Since top.v ORs all the cpu_pin_dir signals into uio_oe, 
    // any CPU pulling the line low will assert uio_oe.
    wire sda = (uio_oe[0] && !uio_out[0]) ? 1'b0 : 1'bz;
    wire scl = (uio_oe[1] && !uio_out[1]) ? 1'b0 : 1'bz;
    
    pullup(sda);
    pullup(scl);
    
    // Feed the bus state back to the CPU
    assign uio_in[0] = sda;
    assign uio_in[1] = scl;
    assign uio_in[7:2] = 0; 
    
    top dut (.ui_in(ui_in), .uo_out(uo_out), .uio_in(uio_in),
             .uio_out(uio_out), .uio_oe(uio_oe), .ena(ena), .clk(clk), .rst_n(rst_n));

    initial begin clk = 0; forever #10 clk = ~clk; end

    task spi_send_byte(input [7:0] data);
        integer i; begin
            for (i = 7; i >= 0; i = i - 1) begin
                ui_in[2] = data[i]; #100 ui_in[1] = 1; #100 ui_in[1] = 0;
            end
            #60;
        end
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

    reg [7:0] received_data;

    initial begin
        ui_in = 0; ui_in[0] = 1; ena = 1; rst_n = 0; #50 rst_n = 1; #50;
        
        $display("[Test 3.4] I2C Multi-Core Loopback RX (CPU0=Master_RX, CPU1=Slave_TX)");
        
        // Load CPU 0 with Master RX, CPU 1 with Slave TX
        load_cpu_ram(8'h00, "protocols/i2c/i2c_master_rx");
        load_cpu_ram(8'h01, "protocols/i2c/i2c_slave_tx");
        
        $monitor("[%0t] SCL=%b, SDA=%b", $time, scl, sda);
        
        
        // Start CPU 1 first (Slave) so it can wait for START
        ui_in[5] = 1; #100;
        
        // Start CPU 0 (Master)
        ui_in[4] = 1; #100;
        
        // Push 0x5A into CPU 1 RX FIFO (Slave transmits this)
        $display("Host sending 0x5A to CPU 1 (Slave TX)...");
        ui_in[0] = 0; spi_send_byte(8'h03); spi_send_byte(8'h5A); ui_in[0] = 1; #100;
        
        // Push dummy byte to CPU 0 RX FIFO to trigger Master Read
        $display("Host sending trigger to CPU 0 (Master RX)...");
        ui_in[0] = 0; spi_send_byte(8'h02); spi_send_byte(8'h00); ui_in[0] = 1; #100;
        
        // Wait for I2C transaction to complete
        #500000;
        
        // Check CPU 0 TX FIFO
        $display("Reading from CPU 0 (Master) TX FIFO...");
        ui_in[0] = 0; spi_send_byte(8'h04); spi_read_byte(received_data); ui_in[0] = 1;
        
        $display("Received Data: 0x%0x", received_data);
        if (received_data == 8'h5a)
            $display("RX LOOPBACK PASSED!");
        else
            $display("RX LOOPBACK FAILED!");
            
        #1000;
        $display("[Test 3.4] Completed. Check test_3_4_i2c_loopback_rx.vcd");
        $finish;
    end
    
    initial begin $dumpfile("test_3_4_i2c_loopback_rx.vcd"); $dumpvars(0, test_3_4_i2c_loopback_rx); end
endmodule
