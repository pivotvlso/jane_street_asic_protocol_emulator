`default_nettype none
`timescale 1ns/1ps

module test_1_5_uart_rx_noise;
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

    task load_cpu_ram(input [7:0] cmd, input [8*100-1:0] hex_file);
        integer file, r; reg [3:0] nibble; begin
            ui_in[0] = 0; spi_send_byte(cmd);
            file = $fopen(hex_file, "r");
            if (file) begin while (!$feof(file)) begin r = $fscanf(file, "%x\n", nibble); if (r == 1) spi_send_byte({4'b0, nibble}); end $fclose(file); end
            ui_in[0] = 1; #100;
        end
    endtask

    task send_uart_byte(input [7:0] data, input integer baud_cycles);
        integer i; begin
            uio_in[1] = 0; // START BIT
            #(baud_cycles * 20);
            for (i = 0; i < 8; i = i + 1) begin
                uio_in[1] = data[i];
                #(baud_cycles * 20);
            end
            uio_in[1] = 1; // STOP BIT
            #(baud_cycles * 20);
        end
    endtask

    reg [7:0] rx_data;

    initial begin
        ui_in = 0; ui_in[0] = 1; uio_in = 8'hFF; ena = 1; rst_n = 0; #50 rst_n = 1; #50;
        $display("[Test 1.5] UART RX Noise Rejection");
        
        load_cpu_ram(8'h01, "protocols/uart/uart_rx.hex"); // Load CPU 1
        
        ui_in[0] = 0; spi_send_byte(8'h07); ui_in[0] = 1; #20; // RUN CPU 1
        #100;
        
        // Config: Half Baud = 30 cycles, Full Baud = 61 cycles
        ui_in[0] = 0; spi_send_byte(8'h03); spi_send_byte(8'd62); ui_in[0] = 1; #20;
        ui_in[0] = 0; spi_send_byte(8'h03); spi_send_byte(8'd38); ui_in[0] = 1; #20;
        
        #500;
        
        // ----------------------------------------------------
        // 1. SIMULATE ELECTRICAL NOISE (FALSE START BIT)
        // ----------------------------------------------------
        $display("Injecting 40ns noise spike on RX line...");
        uio_in[1] = 0; // Spike LOW (looks like start bit)
        #40;           // Only 2 clock cycles (Full baud is 10 cycles)
        uio_in[1] = 1; // Return to HIGH
        
        // Wait long enough for a whole byte to have been transmitted
        #25000;
        
        // Check if FIFO accidentally received garbage data
        ui_in[0] = 0; spi_send_byte(8'h05); spi_read_byte(rx_data); ui_in[0] = 1;
        if (rx_data !== 8'hxx && rx_data !== 8'h00) begin
            $display("FAILED: CPU was fooled by noise and received 0x%h!", rx_data);
        end else begin
            $display("PASS: CPU successfully ignored the noise spike!");
        end
        
        // ----------------------------------------------------
        // 2. SEND LEGITIMATE BYTE
        // ----------------------------------------------------
        $display("Sending legitimate byte 'N' (0x4E)...");
        send_uart_byte(8'h4E, 100);
        
        // Wait for CPU to finish processing
        #5000;
        
        // Check if CPU successfully received 'N'
        ui_in[0] = 0; spi_send_byte(8'h05); spi_read_byte(rx_data); ui_in[0] = 1;
        if (rx_data == 8'h4E) begin
            $display("SUCCESS: CPU successfully received 'N' (0x4E)!");
        end else begin
            $display("FAILED: CPU received 0x%h instead of 0x4E", rx_data);
        end
        
        $display("[Test 1.5] Completed. Check test_1_5_uart_rx_noise.vcd");
        $finish;
    end
    
    initial begin $dumpfile("test_1_5_uart_rx_noise.vcd"); $dumpvars(0, test_1_5_uart_rx_noise); end
endmodule
