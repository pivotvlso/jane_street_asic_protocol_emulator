`default_nettype none

module spi_slave (
    input  wire clk,
    input  wire rst_n,
    
    // SPI Pins
    input  wire spi_cs,
    input  wire spi_sclk,
    input  wire spi_mosi,
    output reg  spi_miso,

    // Interfaces to CPU 0
    output reg [6:0]  cpu0_ram_addr,
    output reg [3:0]  cpu0_ram_wdata,
    output reg        cpu0_ram_we,
    output reg [7:0]  cpu0_rx_fifo_wdata,
    output reg        cpu0_rx_fifo_we,
    input  wire [7:0] cpu0_tx_fifo_rdata,
    output reg        cpu0_tx_fifo_re,
    input  wire       cpu0_tx_fifo_empty,
    // Interfaces to CPU 1
    output reg [6:0]  cpu1_ram_addr,
    output reg [3:0]  cpu1_ram_wdata,
    output reg        cpu1_ram_we,
    output reg [7:0]  cpu1_rx_fifo_wdata,
    output reg        cpu1_rx_fifo_we,
    input  wire [7:0] cpu1_tx_fifo_rdata,
    output reg        cpu1_tx_fifo_re,
    input  wire       cpu1_tx_fifo_empty,
    // Interfaces to CPU 2
    output reg [6:0]  cpu2_ram_addr,
    output reg [3:0]  cpu2_ram_wdata,
    output reg        cpu2_ram_we,
    output reg [7:0]  cpu2_rx_fifo_wdata,
    output reg        cpu2_rx_fifo_we,
    input  wire [7:0] cpu2_tx_fifo_rdata,
    output reg        cpu2_tx_fifo_re,
    input  wire       cpu2_tx_fifo_empty,
    // Interfaces to CPU 3
    output reg [6:0]  cpu3_ram_addr,
    output reg [3:0]  cpu3_ram_wdata,
    output reg        cpu3_ram_we,
    output reg [7:0]  cpu3_rx_fifo_wdata,
    output reg        cpu3_rx_fifo_we,
    input  wire [7:0] cpu3_tx_fifo_rdata,
    output reg        cpu3_tx_fifo_re,
    input  wire       cpu3_tx_fifo_empty
);

    // SPI SCLK Edge Detection
    reg sclk_sync1, sclk_sync2;
    always @(posedge clk) begin
        sclk_sync1 <= spi_sclk;
        sclk_sync2 <= sclk_sync1;
    end
    wire sclk_rise = (sclk_sync1 && !sclk_sync2);
    wire sclk_fall = (!sclk_sync1 && sclk_sync2);

    // State Machine
    reg [7:0] shift_reg;
    reg [7:0] out_shift_reg;
    reg [2:0] bit_cnt;
    reg [7:0] cmd_byte;
    reg       is_cmd_phase;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 0;
            bit_cnt <= 0;
            cmd_byte <= 0;
            is_cmd_phase <= 1;
            spi_miso <= 0;
            cpu0_ram_addr <= 0;
            cpu0_ram_we <= 0;
            cpu0_rx_fifo_we <= 0;
            cpu0_tx_fifo_re <= 0;
            cpu1_ram_addr <= 0;
            cpu1_ram_we <= 0;
            cpu1_rx_fifo_we <= 0;
            cpu1_tx_fifo_re <= 0;
            cpu2_ram_addr <= 0;
            cpu2_ram_we <= 0;
            cpu2_rx_fifo_we <= 0;
            cpu2_tx_fifo_re <= 0;
            cpu3_ram_addr <= 0;
            cpu3_ram_we <= 0;
            cpu3_rx_fifo_we <= 0;
            cpu3_tx_fifo_re <= 0;
        end else begin
            // Clear single-cycle strobes
            cpu0_ram_we <= 0;
            cpu0_rx_fifo_we <= 0;
            cpu0_tx_fifo_re <= 0;
            cpu1_ram_we <= 0;
            cpu1_rx_fifo_we <= 0;
            cpu1_tx_fifo_re <= 0;
            cpu2_ram_we <= 0;
            cpu2_rx_fifo_we <= 0;
            cpu2_tx_fifo_re <= 0;
            cpu3_ram_we <= 0;
            cpu3_rx_fifo_we <= 0;
            cpu3_tx_fifo_re <= 0;
            
            if (spi_cs) begin
                is_cmd_phase <= 1;
                bit_cnt <= 0;
            end else begin
                // SHIFT IN ON RISING EDGE
                if (sclk_rise) begin
                    shift_reg <= {shift_reg[6:0], spi_mosi};
                    bit_cnt <= bit_cnt + 1;
                    
                    if (bit_cnt == 7) begin
                        if (is_cmd_phase) begin
                            cmd_byte <= {shift_reg[6:0], spi_mosi};
                            is_cmd_phase <= 0;
                            // Reset pointers
                            cpu0_ram_addr <= 7'h7F;
                            cpu1_ram_addr <= 7'h7F;
                            cpu2_ram_addr <= 7'h7F;
                            cpu3_ram_addr <= 7'h7F;
                        end else begin
                            case (cmd_byte)
                                8'h00: begin // Write CPU0 RAM
                                    cpu0_ram_wdata <= {shift_reg[2:0], spi_mosi};
                                    cpu0_ram_we <= 1;
                                    cpu0_ram_addr <= cpu0_ram_addr + 1;
                                end
                                8'h02: begin // Write CPU0 RX FIFO
                                    cpu0_rx_fifo_wdata <= {shift_reg[6:0], spi_mosi};
                                    cpu0_rx_fifo_we <= 1;
                                end
                                8'h01: begin // Write CPU1 RAM
                                    cpu1_ram_wdata <= {shift_reg[2:0], spi_mosi};
                                    cpu1_ram_we <= 1;
                                    cpu1_ram_addr <= cpu1_ram_addr + 1;
                                end
                                8'h03: begin // Write CPU1 RX FIFO
                                    cpu1_rx_fifo_wdata <= {shift_reg[6:0], spi_mosi};
                                    cpu1_rx_fifo_we <= 1;
                                end
                                8'h08: begin // Write CPU2 RAM
                                    cpu2_ram_wdata <= {shift_reg[2:0], spi_mosi};
                                    cpu2_ram_we <= 1;
                                    cpu2_ram_addr <= cpu2_ram_addr + 1;
                                end
                                8'h0A: begin // Write CPU2 RX FIFO
                                    cpu2_rx_fifo_wdata <= {shift_reg[6:0], spi_mosi};
                                    cpu2_rx_fifo_we <= 1;
                                end
                                8'h09: begin // Write CPU3 RAM
                                    cpu3_ram_wdata <= {shift_reg[2:0], spi_mosi};
                                    cpu3_ram_we <= 1;
                                    cpu3_ram_addr <= cpu3_ram_addr + 1;
                                end
                                8'h0B: begin // Write CPU3 RX FIFO
                                    cpu3_rx_fifo_wdata <= {shift_reg[6:0], spi_mosi};
                                    cpu3_rx_fifo_we <= 1;
                                end
                            endcase
                        end
                    end
                end
                
                // SHIFT OUT ON FALLING EDGE
                if (sclk_fall) begin
                    if (!is_cmd_phase) begin
                        if (cmd_byte == 8'h04 || cmd_byte == 8'h05 || cmd_byte == 8'h0C || cmd_byte == 8'h0D) begin
                            if (bit_cnt == 0) begin
                                if (cmd_byte == 8'h04) begin
                                    out_shift_reg <= {cpu0_tx_fifo_rdata[6:0], 1'b0};
                                    spi_miso <= cpu0_tx_fifo_rdata[7];
                                    cpu0_tx_fifo_re <= 1;
                                end else if (cmd_byte == 8'h05) begin
                                    out_shift_reg <= {cpu1_tx_fifo_rdata[6:0], 1'b0};
                                    spi_miso <= cpu1_tx_fifo_rdata[7];
                                    cpu1_tx_fifo_re <= 1;
                                end else if (cmd_byte == 8'h0C) begin
                                    out_shift_reg <= {cpu2_tx_fifo_rdata[6:0], 1'b0};
                                    spi_miso <= cpu2_tx_fifo_rdata[7];
                                    cpu2_tx_fifo_re <= 1;
                                end else if (cmd_byte == 8'h0D) begin
                                    out_shift_reg <= {cpu3_tx_fifo_rdata[6:0], 1'b0};
                                    spi_miso <= cpu3_tx_fifo_rdata[7];
                                    cpu3_tx_fifo_re <= 1;
                                end
                            end else begin
                                out_shift_reg <= {out_shift_reg[6:0], 1'b0};
                                spi_miso <= out_shift_reg[7];
                            end
                        end
                    end
                end
            end
        end
    end
endmodule
