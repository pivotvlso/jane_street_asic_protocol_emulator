`default_nettype none
`timescale 1ns/1ps

module test_3_2_i2c_slave;
    reg  [7:0] ui_in;
    wire [7:0] uo_out;
    wire [7:0] uio_in;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;
    reg        ena, clk, rst_n;
    
    // I2C Open-Drain Bus Simulation
    wire sda_drv, scl_drv;
    wire sda = (uio_oe[0] && !uio_out[0]) || sda_drv ? 1'b0 : 1'bz;
    wire scl = (uio_oe[1] && !uio_out[1]) || scl_drv ? 1'b0 : 1'bz;
    
    reg master_sda, master_scl;
    assign sda_drv = !master_sda;
    assign scl_drv = !master_scl;
    
    pullup(sda);
    pullup(scl);
    
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

    task i2c_master_write_byte(input [7:0] data);
        integer i; begin
            // Start condition
            master_scl = 1; master_sda = 1; #500;
            master_sda = 0; #500;
            master_scl = 0; #500;
            
            // 8 Data Bits
            for (i = 7; i >= 0; i = i - 1) begin
                master_sda = data[i]; #500;
                master_scl = 1; #500;
                master_scl = 0; #500;
            end
            
            // Release SDA for ACK
            master_sda = 1; #500;
            master_scl = 1; #500; // Let Slave ACK
            master_scl = 0; #500;
            
            // Stop condition
            master_sda = 0; #500;
            master_scl = 1; #500;
            master_sda = 1; #500;
        end
    endtask

    initial begin
        ui_in = 0; ui_in[0] = 1; ena = 1; rst_n = 0;
        master_sda = 1; master_scl = 1; 
        #50 rst_n = 1; #50;
        
        $display("[Test 3.2] I2C Slave - Receive Byte");
        
        load_cpu_ram(8'h00, "protocols/i2c/i2c_slave");
        ui_in[0] = 0; spi_send_byte(8'h06); ui_in[0] = 1; // Run CPU 0
        
        #5000;
        
        // Host master sends byte 0x5A
        $display("Master sending 0x5A to Slave...");
        i2c_master_write_byte(8'h5A);
        
        // Wait for CPU to push to TX_FIFO
        #5000;
        
        // Read out TX_FIFO
        ui_in[0] = 0; spi_send_byte(8'h0A); // Pop byte from CPU 0
        // (Add SPI receive logic here if necessary, but we'll check VCD)
        ui_in[0] = 1;
        
        #5000;
        $display("[Test 3.2] Completed. Check test_3_2_i2c_slave.vcd");
        $finish;
    end
    
    initial begin $dumpfile("test_3_2_i2c_slave.vcd"); $dumpvars(0, test_3_2_i2c_slave); end
endmodule
