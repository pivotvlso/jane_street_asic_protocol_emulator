`default_nettype none
`timescale 1ns/1ps

module test_5_1_usb_tx;
    reg clk;
    reg rst_n;
    reg [7:0] ui_in;
    wire [7:0] uo_out;
    reg [7:0] uio_in;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

    top dut (
        .ui_in(ui_in),
        .uo_out(uo_out),
        .uio_in(uio_in),
        .uio_out(uio_out),
        .uio_oe(uio_oe),
        .ena(1'b1),
        .clk(clk),
        .rst_n(rst_n)
    );

    always #10 clk = ~clk;

    task spi_write(input [7:0] cmd, input [7:0] data);
        integer i;
        reg [16:0] packet;
        begin
            // Prepend a dummy 0 bit to compensate for the SPI slave missing the first clock edge
            packet = {1'b0, cmd, data};
            $display("SPI_WRITE cmd=%h data=%h packet=%b", cmd, data, packet);
            ui_in[0] = 0; // CS low
            #40;
            for (i=16; i>=0; i=i-1) begin
                ui_in[1] = 0; // SCLK low
                ui_in[2] = packet[i];
                #20 ui_in[1] = 1; // SCLK high
                #20;
            end
            ui_in[0] = 1; // CS high
            #40;
        end
    endtask

    initial begin
        $dumpfile("test_5_1_usb_tx.vcd");
        $dumpvars(0, test_5_1_usb_tx);

        clk = 0;
        rst_n = 0;
        ui_in = 8'h01; // CS high
        uio_in = 8'h00;
        
        #100;
        rst_n = 1;
        #100;

        // Load CPU 3 Serializer
        $readmemh("protocols/usb/usb_cpu3_tx_serializer_op.hex", dut.cpu3_rom_op);
        $readmemh("protocols/usb/usb_cpu3_tx_serializer_op1.hex", dut.cpu3_rom_op1);
        $readmemh("protocols/usb/usb_cpu3_tx_serializer_op2.hex", dut.cpu3_rom_op2);
        $readmemh("protocols/usb/usb_cpu3_tx_serializer_jmp.hex", dut.cpu3_jmp_table);
        
        // Load CPU 2 Bit Stuffer
        $readmemh("protocols/usb/usb_cpu2_tx_stuffer_op.hex", dut.cpu2_rom_op);
        $readmemh("protocols/usb/usb_cpu2_tx_stuffer_op1.hex", dut.cpu2_rom_op1);
        $readmemh("protocols/usb/usb_cpu2_tx_stuffer_op2.hex", dut.cpu2_rom_op2);
        $readmemh("protocols/usb/usb_cpu2_tx_stuffer_jmp.hex", dut.cpu2_jmp_table);
        
        // Load CPU 1 NRZI Driver
        $readmemh("protocols/usb/usb_cpu1_tx_nrzi_op.hex", dut.cpu1_rom_op);
        $readmemh("protocols/usb/usb_cpu1_tx_nrzi_op1.hex", dut.cpu1_rom_op1);
        $readmemh("protocols/usb/usb_cpu1_tx_nrzi_op2.hex", dut.cpu1_rom_op2);
        $readmemh("protocols/usb/usb_cpu1_tx_nrzi_jmp.hex", dut.cpu1_jmp_table);

        // Turn on CPU 1, 2, 3
        ui_in[7:5] = 3'b111; 

        // Initial Idle wait
        #5000;

        // Send SYNC (0x80)
        spi_write(8'h0B, 8'h80); // CPU3 RX_FIFO

        // Send Data (0xFF) -> This should trigger bit stuffing (six 1s)
        spi_write(8'h0B, 8'hFF);

        // Wait for all bits to be transmitted (~16 bits total before EOP)
        // 16 bits * 33 cycles/bit * 20ns = ~10560 ns
        #12000;
        
        // Send EOP marker (0xFE)
        spi_write(8'h0B, 8'hFE);
        
        // Wait for EOP to finish
        #30000;
        
        $display("Simulation Complete.");
        $finish;
    end

    // Monitor USB lines (Pin 0 = D+, Pin 1 = D-)
    always @(dut.uio_out[1:0]) begin
        if (dut.uio_out[1:0] == 2'b10) $display("[%0t] USB BUS: J State (Idle)", $time);
        else if (dut.uio_out[1:0] == 2'b01) $display("[%0t] USB BUS: K State", $time);
        else if (dut.uio_out[1:0] == 2'b00) $display("[%0t] USB BUS: SE0 State", $time);
        else $display("[%0t] USB BUS: INVALID STATE %b", $time, dut.uio_out[1:0]);
    end

endmodule
