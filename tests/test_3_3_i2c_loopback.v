`default_nettype none
`timescale 1ns/1ps

module test_3_3_i2c_loopback;
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

    task load_cpu_ram(input [7:0] cmd, input [8*100-1:0] hex_file);
        integer file, r; reg [3:0] nibble; begin
            ui_in[0] = 0; spi_send_byte(cmd);
            file = $fopen(hex_file, "r");
            if (file) begin
                while (!$feof(file)) begin
                    r = $fscanf(file, "%x\n", nibble);
                    if (r == 1) begin
                        //$display("Loading %x", nibble); // Optional, commented to avoid spam
                        spi_send_byte({4'b0, nibble});
                    end
                end $fclose(file);
            end ui_in[0] = 1; #100;
        end
    endtask

    reg [7:0] received_data;

    initial begin
        ui_in = 0; ui_in[0] = 1; ena = 1; rst_n = 0; #50 rst_n = 1; #50;
        
        $display("[Test 3.3] I2C Multi-Core Loopback (CPU0=Master, CPU1=Slave)");
        
        // Load CPU 0 with Master, CPU 1 with Slave
        load_cpu_ram(8'h00, "protocols/i2c/i2c_master.hex");
        load_cpu_ram(8'h01, "protocols/i2c/i2c_slave.hex");
        
        $monitor("[%0t] SCL=%b, SDA=%b", $time, scl, sda);
        
        
        // Start CPU 1 first (Slave) so it can wait for START
        ui_in[0] = 0; spi_send_byte(8'h07); ui_in[0] = 1; #100;
        
        // Start CPU 0 (Master)
        ui_in[0] = 0; spi_send_byte(8'h06); ui_in[0] = 1; #100;
        
        // Push 0x77 into CPU 0 RX FIFO
        $display("Host sending 0x77 to CPU 0 (Master)...");
        ui_in[0] = 0; spi_send_byte(8'h02); spi_send_byte(8'h77); ui_in[0] = 1;
        
        // Wait for I2C transaction to complete
        // Master writes 8 bits and reads ACK
        // Slave receives 8 bits and sends ACK
        #500000;
        
        // Check CPU 1 TX FIFO
        $display("Reading from CPU 1 (Slave) TX FIFO...");
        ui_in[0] = 0; spi_send_byte(8'h05); spi_read_byte(received_data); ui_in[0] = 1;
        
        $display("Received Data: 0x%0x", received_data);
        if (received_data == 8'h77)
            $display("LOOPBACK PASSED!");
        else
            $display("LOOPBACK FAILED!");
            
        #1000;
        $display("[Test 3.3] Completed. Check test_3_3_i2c_loopback.vcd");
        $finish;
    end
    
    initial begin $dumpfile("test_3_3_i2c_loopback.vcd"); $dumpvars(0, test_3_3_i2c_loopback); end
endmodule
