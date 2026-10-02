`default_nettype none
`timescale 1ns/1ps

module test_1_6_uart_rx_framing;
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

    task send_uart_byte(input [7:0] data, input integer baud_cycles, input reg drop_stop_bit);
        integer i; begin
            uio_in[1] = 0; // START BIT
            #(baud_cycles * 20);
            for (i = 0; i < 8; i = i + 1) begin
                uio_in[1] = data[i];
                #(baud_cycles * 20);
            end
            
            if (drop_stop_bit) begin
                uio_in[1] = 0; // INTENTIONAL FRAMING ERROR! Stop bit is missing (LOW)
            end else begin
                uio_in[1] = 1; // Normal Stop Bit
            end
            #(baud_cycles * 20);
            
            uio_in[1] = 1; // Idle line high eventually
            #(baud_cycles * 20);
        end
    endtask

    reg [7:0] rx_data;
    reg [7:0] rx_error;

    initial begin
        ui_in = 0; ui_in[0] = 1; uio_in = 8'hFF; ena = 1; rst_n = 0; #50 rst_n = 1; #50;
        $display("[Test 1.6] UART RX Framing Error Detection");
        
        load_cpu_ram(8'h01, "protocols/uart/uart_rx.hex"); // Load CPU 1
        
        ui_in[0] = 0; spi_send_byte(8'h07); ui_in[0] = 1; #20; // RUN CPU 1
        #100;
        
        // Config: Half Baud = 30 cycles, Full Baud = 61 cycles
        ui_in[0] = 0; spi_send_byte(8'h03); spi_send_byte(8'd62); ui_in[0] = 1; #20;
        ui_in[0] = 0; spi_send_byte(8'h03); spi_send_byte(8'd38); ui_in[0] = 1; #20;
        
        #500;
        
        // ----------------------------------------------------
        // 1. SEND VALID BYTE (Should NOT push 0xFF)
        // ----------------------------------------------------
        $display("Sending valid byte 'A' (0x41)...");
        send_uart_byte(8'h41, 100, 0); // No error
        
        // CPU needs extra instruction overhead time before it finishes
        #5000;
        
        ui_in[0] = 0; spi_send_byte(8'h05); spi_read_byte(rx_data); ui_in[0] = 1;
        if (rx_data == 8'h41) $display("PASS: CPU received 'A' (0x41)");
        
        // Verify no error code was pushed
        ui_in[0] = 0; spi_send_byte(8'h05); spi_read_byte(rx_error); ui_in[0] = 1;
        if (rx_error !== 8'hFF) $display("PASS: No Framing Error generated!");
        else $display("FAILED: Erroneously generated framing error!");
        
        #500;
        
        // ----------------------------------------------------
        // 2. SEND INVALID BYTE (Should push Data AND 0xFF)
        // ----------------------------------------------------
        $display("Sending corrupted byte 'B' (0x42) with MISSING Stop Bit...");
        send_uart_byte(8'h42, 100, 1); // DROP STOP BIT!
        
        #5000;
        
        ui_in[0] = 0; 
        spi_send_byte(8'h05); 
        spi_read_byte(rx_data); 
        spi_read_byte(rx_error); 
        ui_in[0] = 1; #20;
        
        if (rx_data == 8'h42 && rx_error == 8'hFF) begin
            $display("SUCCESS: CPU received 'B' and correctly flagged FRAMING ERROR (0xFF)!");
        end else begin
            $display("FAILED: Expected [0x42, 0xFF], Got [0x%h, 0x%h]", rx_data, rx_error);
        end
        
        $display("[Test 1.6] Completed. Check test_1_6_uart_rx_framing.vcd");
        $finish;
    end
    
    initial begin $dumpfile("test_1_6_uart_rx_framing.vcd"); $dumpvars(0, test_1_6_uart_rx_framing); end
endmodule
