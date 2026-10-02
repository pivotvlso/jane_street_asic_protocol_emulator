`default_nettype none
`timescale 1ns/1ps

module tb_uart;
    reg  [7:0] ui_in;
    wire [7:0] uo_out;
    wire [7:0] uio_in;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;
    reg        ena;
    reg        clk;
    reg        rst_n;

    assign uio_in = uio_out; // Loopback
    
    top dut (
        .ui_in(ui_in), .uo_out(uo_out), .uio_in(uio_in),
        .uio_out(uio_out), .uio_oe(uio_oe), .ena(ena), .clk(clk), .rst_n(rst_n)
    );

    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    task spi_send_byte(input [7:0] data);
        integer i;
        begin
            for (i = 7; i >= 0; i = i - 1) begin
                ui_in[2] = data[i]; // MOSI
                #20 ui_in[1] = 1;   // SCLK Rise
                #20 ui_in[1] = 0;   // SCLK Fall
            end
        end
    endtask

    task load_cpu_ram(input [7:0] cmd, input [8*64-1:0] hex_file);
        integer file, r;
        reg [3:0] nibble;
        begin
            ui_in[0] = 0; // CS LOW
            spi_send_byte(cmd);
            file = $fopen(hex_file, "r");
            if (file) begin
                while (!$feof(file)) begin
                    r = $fscanf(file, "%x\n", nibble);
                    if (r == 1) spi_send_byte({4'b0, nibble});
                end
                $fclose(file);
            end
            ui_in[0] = 1; // CS HIGH
            #100;
        end
    endtask

    initial begin
        ui_in = 0; ui_in[0] = 1; ena = 1;
        rst_n = 0; #50 rst_n = 1; #50;
        
        $display("----------------------------------");
        $display(" UART TX VERIFICATION TESTBENCH ");
        $display("----------------------------------");
        
        // 1. Program CPU 0 with UART TX
        load_cpu_ram(8'h00, "protocols/uart/uart_tx.hex");
        
        // 2. Start CPU 0
        ui_in[0] = 0; spi_send_byte(8'h06); ui_in[0] = 1;
        #100;
        
        // 3. Send Baud Rate Config (e.g. 5 clock cycles per bit)
        ui_in[0] = 0; spi_send_byte(8'h02); spi_send_byte(8'd5); ui_in[0] = 1;
        
        // 4. Send Payload: 'A' (0x41)
        #500;
        ui_in[0] = 0; spi_send_byte(8'h02); spi_send_byte(8'h41); ui_in[0] = 1;
        
        // Wait for UART TX to finish
        #30000;
        
        $display("Simulation Complete. Check tb_uart.vcd for uio_out[0] waveforms!");
        $finish;
    end
    
    initial begin
        $dumpfile("tb_uart.vcd");
        $dumpvars(0, tb_uart);
    end
endmodule
