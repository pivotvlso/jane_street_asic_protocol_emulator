`default_nettype none
`timescale 1ns/1ps

module tb_top;

    // Tiny Tapeout IOs
    reg  [7:0] ui_in;
    wire [7:0] uo_out;
    wire [7:0] uio_in;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;
    reg        ena;
    reg        clk;
    reg        rst_n;

    // Internal routing
    assign uio_in = uio_out; // Loopback outputs to inputs for reading PIN_STATE

    // SPI Signals mapping
    wire spi_cs = ui_in[0];
    wire spi_sclk = ui_in[1];
    wire spi_mosi = ui_in[2];
    wire spi_miso = uo_out[0];
    


    top dut (
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_in(uio_in),
        .uio_out(uio_out),
        .uio_oe(uio_oe),
        .ena(ena),
        .clk(clk),
        .rst_n(rst_n)
    );

    // Clock generation (50MHz)
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // SPI Transaction Task
    task spi_send_byte(input [7:0] data);
        integer i;
        begin
            for (i = 7; i >= 0; i = i - 1) begin
                ui_in[2] = data[i]; // MOSI
                #20 ui_in[1] = 1; // SCLK Rising edge
                #20 ui_in[1] = 0; // SCLK Falling edge
            end
        end
    endtask

    // Program CPU 0 Memory via SPI
    task load_cpu0_program(input [8*64-1:0] hex_file);
        integer file, r;
        reg [3:0] nibble;
        begin
            ui_in[0] = 0; // CS LOW
            spi_send_byte(8'h00); // Command: Write CPU 0 RAM
            
            // Read from hex file
            file = $fopen(hex_file, "r");
            if (file) begin
                while (!$feof(file)) begin
                    r = $fscanf(file, "%x\n", nibble);
                    if (r == 1) begin
                        spi_send_byte({4'b0, nibble});
                    end
                end
                $fclose(file);
            end else begin
                $display("ERROR: Could not open %s", hex_file);
            end
            
            ui_in[0] = 1; // CS HIGH
            #100;
        end
    endtask

    initial begin
        // Init
        ui_in = 0;
        ui_in[0] = 1; // CS HIGH
        ena = 1;
        
        // Reset
        rst_n = 0;
        #50 rst_n = 1;
        #50;
        
        // Load UART TX Program into CPU 0
        $display("Loading UART TX program into CPU 0...");
        load_cpu0_program("protocols/uart/uart_tx.hex");
        
        // Start CPU 0
        $display("Starting CPU 0...");
        ui_in[0] = 0; // CS LOW
        spi_send_byte(8'h06); // Command: RUN CPU 0
        ui_in[0] = 1; // CS HIGH
        #100;
        
        // Push a byte 'A' (0x41) into RX FIFO so UART TX starts
        $display("Pushing 'A' (0x41) into CPU 0 RX FIFO...");
        ui_in[0] = 0; // CS LOW
        spi_send_byte(8'h02); // Command: Write CPU 0 RX FIFO
        spi_send_byte(8'h41); // Payload: 'A'
        ui_in[0] = 1; // CS HIGH
        
        // Let it run for a while to observe UART TX on uio_out[0]
        #100000;
        
        $display("Simulation complete.");
        $finish;
    end
    
    // Dump waves
    initial begin
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);
    end

endmodule
