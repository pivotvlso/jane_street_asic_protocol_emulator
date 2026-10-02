`default_nettype none
`timescale 1ns/1ps

module uart_tx_dynamic_baud;
    reg  [7:0] ui_in; wire [7:0] uo_out, uio_in, uio_out, uio_oe; reg ena, clk, rst_n;
    assign uio_in = uio_out;
    top dut (.ui_in(ui_in), .uo_out(uo_out), .uio_in(uio_in), .uio_out(uio_out), .uio_oe(uio_oe), .ena(ena), .clk(clk), .rst_n(rst_n));

    initial begin clk = 0; forever #10 clk = ~clk; end

    task spi_send_byte(input [7:0] data);
        integer i; begin for (i = 7; i >= 0; i = i - 1) begin ui_in[2] = data[i]; #100 ui_in[1] = 1; #100 ui_in[1] = 0; end end
    endtask

    task load_cpu_ram(input [8*100-1:0] hex_file);
        integer file, r; reg [3:0] nibble; begin
            ui_in[0] = 0; spi_send_byte(8'h00);
            file = $fopen(hex_file, "r");
            if (file) begin while (!$feof(file)) begin r = $fscanf(file, "%x\n", nibble); if (r == 1) spi_send_byte({4'b0, nibble}); end $fclose(file); end
            ui_in[0] = 1; #100;
        end
    endtask

    initial begin
        ui_in = 0; ui_in[0] = 1; ena = 1; rst_n = 0; #50 rst_n = 1; #50;
        $display("[Test 1.2] UART TX Dynamic Baud - Very Slow Baud Rate");
        
        load_cpu_ram("protocols/uart/uart_tx.hex");
        ui_in[0] = 0; spi_send_byte(8'h06); ui_in[0] = 1; // Run CPU 0
        
        #100;
        ui_in[0] = 0; spi_send_byte(8'h02); spi_send_byte(8'd100); ui_in[0] = 1; // Baud 100 cycles!
        #100;
        ui_in[0] = 0; spi_send_byte(8'h02); spi_send_byte(8'h5A); ui_in[0] = 1; // 0x5A (01011010)
        
        #500000;
        $display("[Test 1.2] Completed. Check uart_tx_dynamic_baud.vcd for widened pulses.");
        $finish;
    end
    
    initial begin $dumpfile("uart_tx_dynamic_baud.vcd"); $dumpvars(0, uart_tx_dynamic_baud); end
endmodule
