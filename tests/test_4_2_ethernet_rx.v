`timescale 1ns/1ps

module test_4_2_ethernet_rx;
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

    always #10 clk = ~clk; // 50 MHz clock (20ns period)

    task spi_write(input [6:0] addr, input [7:0] data);
        integer i;
        begin
            $display("[%0t] spi_write(addr=%h, data=%h)", $time, addr, data);
            @(posedge clk);
            ui_in[0] = 0; // CS low
            for (i=15; i>=0; i=i-1) begin
                @(posedge clk);
                ui_in[1] = 0; // SCLK low
                if (i >= 8) ui_in[2] = (addr >> (i-8)) & 1;
                else ui_in[2] = (data >> i) & 1;
                @(posedge clk);
                @(posedge clk);
                ui_in[1] = 1; // SCLK high
                @(posedge clk);
                @(posedge clk);
            end
            @(posedge clk);
            ui_in[0] = 1; // CS high
            @(posedge clk);
        end
    endtask

    task spi_send_cmd(input [7:0] cmd);
        integer i;
        begin
            $display("[%0t] spi_send_cmd(cmd=%h)", $time, cmd);
            @(posedge clk);
            ui_in[0] = 0; // CS low
            for (i=7; i>=0; i=i-1) begin
                @(posedge clk);
                ui_in[1] = 0; // SCLK low
                ui_in[2] = (cmd >> i) & 1;
                @(posedge clk);
                @(posedge clk);
                ui_in[1] = 1; // SCLK high
                @(posedge clk);
                @(posedge clk);
            end
            @(posedge clk);
            ui_in[0] = 1; // CS high
            @(posedge clk);
        end
    endtask

    task spi_read(input [7:0] cmd, output [7:0] data);
        integer i;
        begin
            $display("[%0t] spi_read(cmd=%h)", $time, cmd);
            @(posedge clk);
            ui_in[0] = 0; // CS low
            for (i=15; i>=0; i=i-1) begin
                @(posedge clk);
                ui_in[1] = 0; // SCLK low
                if (i >= 8) ui_in[2] = (cmd >> (i-8)) & 1;
                else ui_in[2] = 0;
                @(posedge clk);
                @(posedge clk);
                ui_in[1] = 1; // SCLK high
                @(posedge clk);
                if (i < 8) data[i] = uo_out[0]; // MISO
                @(posedge clk);
            end
            @(posedge clk);
            ui_in[0] = 1; // CS high
            @(posedge clk);
        end
    endtask

    // 1 Bit = 200 cycles = 4000ns
    // Half Bit = 100 cycles = 2000ns
    task send_manchester_bit(input val);
        begin
            if (val == 0) begin
                uio_in[0] = 1; // First half HIGH
                #2000;
                uio_in[0] = 0; // Second half LOW (Data Edge)
                #2000;
            end else begin
                uio_in[0] = 0; // First half LOW
                #2000;
                uio_in[0] = 1; // Second half HIGH (Data Edge)
                #2000;
            end
        end
    endtask

    reg [7:0] recv_byte;

    initial begin
        $dumpfile("test_4_2_ethernet_rx.vcd");
        $dumpvars(0, test_4_2_ethernet_rx);

        clk = 0;
        rst_n = 0;
        ui_in = 8'h01; // CS high
        uio_in = 8'h01; // Idle HIGH for Pin 0
        #100 rst_n = 1;
        #100;

        // Load firmware
        $readmemh("protocols/ethernet/eth_cpu0_rx_edge_op.hex", dut.cpu0_rom_op);
        $readmemh("protocols/ethernet/eth_cpu0_rx_edge_op1.hex", dut.cpu0_rom_op1);
        $readmemh("protocols/ethernet/eth_cpu0_rx_edge_op2.hex", dut.cpu0_rom_op2);
        $readmemh("protocols/ethernet/eth_cpu0_rx_edge_jmp.hex", dut.cpu0_jmp_table);

        $readmemh("protocols/ethernet/eth_cpu1_rx_deserializer_op.hex", dut.cpu1_rom_op);
        $readmemh("protocols/ethernet/eth_cpu1_rx_deserializer_op1.hex", dut.cpu1_rom_op1);
        $readmemh("protocols/ethernet/eth_cpu1_rx_deserializer_op2.hex", dut.cpu1_rom_op2);
        $readmemh("protocols/ethernet/eth_cpu1_rx_deserializer_jmp.hex", dut.cpu1_jmp_table);

        // CPU 0 RX FIFO addr: 0x02. Push 3/4 Baud Delay
        // 3/4 of 200 cycles = 150 cycles = 0x96
        spi_write(7'h02, 8'h96);

        // Start CPU 0 and CPU 1
        ui_in[4] = 1; // CPU 0
        ui_in[5] = 1; // CPU 1

        #1000;

        // Send a byte: 0x5A (0101 1010)
        // LSB first: 0, 1, 0, 1, 1, 0, 1, 0
        // Wait, Manchester decoding relies on previous state being idle, so let's send a sync bit first
        // Actually, just send the 8 bits. The first edge will synchronize it.
        $display("[%0t] Host sending 0x5A (Manchester Encoded)...", $time);
        send_manchester_bit(0);
        send_manchester_bit(1);
        send_manchester_bit(0);
        send_manchester_bit(1);
        send_manchester_bit(1);
        send_manchester_bit(0);
        send_manchester_bit(1);
        send_manchester_bit(0);

        #10000;

        // Read from CPU 1 TX FIFO (cmd 0x05)
        spi_read(8'h05, recv_byte);
        
        $display("[%0t] Host read byte from CPU 1: 0x%h", $time, recv_byte);

        if (recv_byte !== 8'h5A) begin
            $display("FAILED: Expected 0x5A, got 0x%h", recv_byte);
        end else begin
            $display("SUCCESS: Ethernet RX perfectly decoded 0x5A!");
        end

        $finish;
    end

    `include "protocols/ethernet/eth_cpu0_rx_edge_assert.vh"
    `include "protocols/ethernet/eth_cpu1_rx_deserializer_assert.vh"

    always @(posedge clk) begin
        if (dut.cpu1_tx_we) $display("[%0t] CPU 1 WROTE TO TX FIFO: 0x%h", $time, dut.cpu1_mem_wdata);
        if (dut.cpu0_mem_we && dut.cpu0_mem_addr == 4'h9) $display("[%0t] CPU 0 WROTE TO SHARED_0: %d", $time, dut.cpu0_mem_wdata);
        if (dut.cpu0_rx_fifo_we) $display("[%0t] HOST WROTE TO CPU 0 RX FIFO: 0x%h", $time, dut.cpu0_rx_fifo_wdata);
        if (dut.spi_inst.sclk_rise && dut.spi_inst.bit_cnt == 7) $display("[%0t] SPI CMD_PHASE=%b CMD_BYTE=0x%h MOSI=%b", $time, dut.spi_inst.is_cmd_phase, dut.spi_inst.cmd_byte, dut.spi_inst.spi_mosi);
    end
endmodule
