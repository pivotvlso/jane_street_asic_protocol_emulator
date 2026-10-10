`timescale 1ns/1ps

module test_4_1_ethernet_tx;
    reg clk;
    reg rst_n;
    reg [7:0] ui_in;
    reg [7:0] uio_in;
    wire [7:0] uo_out;
    wire [7:0] uio_out;
    wire [7:0] uio_oe;

    top dut (
        .clk(clk), .rst_n(rst_n),
        .ui_in(ui_in), .uo_out(uo_out),
        .uio_in(uio_in), .uio_out(uio_out), .uio_oe(uio_oe),
        .ena(1'b1)
    );

    always #10 clk = ~clk; // 50 MHz clock

    // Task to write to SPI
    task spi_write(input [6:0] addr, input [7:0] data);
        integer i;
        begin
            ui_in[0] = 0; // CS low
            for (i=15; i>=0; i=i-1) begin
                ui_in[1] = 0; // SCLK low
                if (i >= 8) ui_in[2] = (addr >> (i-8)) & 1;
                else ui_in[2] = (data >> i) & 1;
                #20 ui_in[1] = 1; // SCLK high
                #20;
            end
            ui_in[0] = 1; // CS high
            #40;
        end
    endtask

    initial begin
        $dumpfile("test_4_1_ethernet_tx.vcd");
        $dumpvars(0, test_4_1_ethernet_tx);

        clk = 0;
        rst_n = 0;
        ui_in = 8'h01; // CS high
        uio_in = 8'h00;
        #100 rst_n = 1;
        #100;

        // Load 4 CPU hex files via loopback in tb
        // But for simulation, we'll just $readmemh directly into the RAMs to save time!
        $readmemh("protocols/ethernet/eth_cpu0_tx_plus_op.hex", dut.cpu0_rom_op);
        $readmemh("protocols/ethernet/eth_cpu0_tx_plus_op1.hex", dut.cpu0_rom_op1);
        $readmemh("protocols/ethernet/eth_cpu0_tx_plus_op2.hex", dut.cpu0_rom_op2);
        $readmemh("protocols/ethernet/eth_cpu0_tx_plus_jmp.hex", dut.cpu0_jmp_table);

        $readmemh("protocols/ethernet/eth_cpu1_tx_minus_op.hex", dut.cpu1_rom_op);
        $readmemh("protocols/ethernet/eth_cpu1_tx_minus_op1.hex", dut.cpu1_rom_op1);
        $readmemh("protocols/ethernet/eth_cpu1_tx_minus_op2.hex", dut.cpu1_rom_op2);
        $readmemh("protocols/ethernet/eth_cpu1_tx_minus_jmp.hex", dut.cpu1_jmp_table);

        $readmemh("protocols/ethernet/eth_cpu2_encoder_op.hex", dut.cpu2_rom_op);
        $readmemh("protocols/ethernet/eth_cpu2_encoder_op1.hex", dut.cpu2_rom_op1);
        $readmemh("protocols/ethernet/eth_cpu2_encoder_op2.hex", dut.cpu2_rom_op2);
        $readmemh("protocols/ethernet/eth_cpu2_encoder_jmp.hex", dut.cpu2_jmp_table);

        $readmemh("protocols/ethernet/eth_cpu3_serializer_op.hex", dut.cpu3_rom_op);
        $readmemh("protocols/ethernet/eth_cpu3_serializer_op1.hex", dut.cpu3_rom_op1);
        $readmemh("protocols/ethernet/eth_cpu3_serializer_op2.hex", dut.cpu3_rom_op2);
        $readmemh("protocols/ethernet/eth_cpu3_serializer_jmp.hex", dut.cpu3_jmp_table);

        // Start all 4 CPUs!
        spi_write(7'h7C, 8'h01); // CPU 0
        spi_write(7'h7D, 8'h01); // CPU 1
        spi_write(7'h7E, 8'h01); // CPU 2
        spi_write(7'h7F, 8'h01); // CPU 3

        // Push a test byte to CPU 3 RX_FIFO (0x5A = 01011010)
        // Wait, CPU 3 reads RX_FIFO. RX_FIFO is at addr 0x5. SPI pushes to CPU 3 RX FIFO using addr 7'h45 ?
        // Let's look at top.v SPI map:
        // cpu3_rx_fifo_wdata: SPI Addr 7'h19 
        // Wait, what's the SPI map for CPU3 RX? 
        // CPU 0 RX = 0x01
        // CPU 1 RX = 0x09
        // CPU 2 RX = 0x11
        // CPU 3 RX = 0x19
        spi_write(7'h19, 8'h5A); // Send 0x5A to CPU 3

        #10000;
        
        $display("Simulation Complete.");
        $finish;
    end

endmodule
