`default_nettype none
`timescale 1ns/1ps

module test_3_1_i2c_master;
    reg  [7:0] ui_in;
    wire [7:0] uo_out;
    wire [7:0] uio_in;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;
    reg        ena, clk, rst_n;
    
    // I2C Open-Drain Bus Simulation
    wire sda = (uio_oe[0] && !uio_out[0]) ? 1'b0 : 1'bz;
    wire scl = (uio_oe[1] && !uio_out[1]) ? 1'b0 : 1'bz;
    
    pullup(sda);
    pullup(scl);
    
    // Slave Clock Stretching
    reg slave_stretch;
    assign scl = slave_stretch ? 1'b0 : 1'bz;
    
    // Feed the bus state back to the CPU
    assign uio_in[0] = sda;
    assign uio_in[1] = scl;
    assign uio_in[7:2] = uio_out[7:2]; // loopback others
    
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

    task load_cpu_ram(input [7:0] cmd, input [8*100-1:0] hex_file);
        integer file, r; reg [3:0] nibble; begin
            ui_in[0] = 0; spi_send_byte(cmd);
            file = $fopen(hex_file, "r");
            if (file) begin
                while (!$feof(file)) begin
                    r = $fscanf(file, "%x\n", nibble);
                    if (r == 1) spi_send_byte({4'b0, nibble});
                end $fclose(file);
            end ui_in[0] = 1; #100;
        end
    endtask

    initial begin
        ui_in = 0; ui_in[0] = 1; ena = 1; rst_n = 0; slave_stretch = 0; #50 rst_n = 1; #50;
        
        $display("[Test 3.1] I2C Master - Start Condition, Arbitration & Clock Stretch");
        
        load_cpu_ram(8'h00, "protocols/i2c/i2c_master.hex");
        ui_in[0] = 0; spi_send_byte(8'h06); ui_in[0] = 1; // Run CPU 0
        
        #1000;
        
        // Wait for Start condition visually
        $display("Sending 0xAA (10101010) over I2C...");
        ui_in[0] = 0; spi_send_byte(8'h02); spi_send_byte(8'hAA); ui_in[0] = 1; 
        
        // Let it send a few bits...
        #15000;
        
        // Simulate Clock Stretching!
        $display("Slave pulling SCL Low (Clock Stretching)...");
        slave_stretch = 1;
        #10000;
        $display("Slave releasing SCL...");
        slave_stretch = 0;
        
        // Finish byte
        #30000;
        
        $display("[Test 3.1] Completed. Check test_3_1_i2c_master.vcd");
        $finish;
    end
    
    initial begin $dumpfile("test_3_1_i2c_master.vcd"); $dumpvars(0, test_3_1_i2c_master); end
endmodule
