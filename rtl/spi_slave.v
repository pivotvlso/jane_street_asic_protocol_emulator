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
    output reg [6:0]  cpu0_ram_op_addr,
    output reg [3:0]  cpu0_ram_op_wdata,
    output reg        cpu0_ram_op_we,
    output reg [5:0]  cpu0_ram_op1_addr,
    output reg [3:0]  cpu0_ram_op1_wdata,
    output reg        cpu0_ram_op1_we,
    output reg [2:0]  cpu0_ram_op2_addr,
    output reg [3:0]  cpu0_ram_op2_wdata,
    output reg        cpu0_ram_op2_we,
    output reg [3:0]  cpu0_jmp_addr,
    output reg [15:0] cpu0_jmp_wdata,
    output reg        cpu0_jmp_we,
    output reg [7:0]  cpu0_rx_fifo_wdata,
    output reg        cpu0_rx_fifo_we,
    input  wire [7:0] cpu0_tx_fifo_rdata,
    output reg        cpu0_tx_fifo_re,
    input  wire       cpu0_tx_fifo_empty,
    // Interfaces to CPU 1
    output reg [6:0]  cpu1_ram_op_addr,
    output reg [3:0]  cpu1_ram_op_wdata,
    output reg        cpu1_ram_op_we,
    output reg [5:0]  cpu1_ram_op1_addr,
    output reg [3:0]  cpu1_ram_op1_wdata,
    output reg        cpu1_ram_op1_we,
    output reg [2:0]  cpu1_ram_op2_addr,
    output reg [3:0]  cpu1_ram_op2_wdata,
    output reg        cpu1_ram_op2_we,
    output reg [3:0]  cpu1_jmp_addr,
    output reg [15:0] cpu1_jmp_wdata,
    output reg        cpu1_jmp_we,
    output reg [7:0]  cpu1_rx_fifo_wdata,
    output reg        cpu1_rx_fifo_we,
    input  wire [7:0] cpu1_tx_fifo_rdata,
    output reg        cpu1_tx_fifo_re,
    input  wire       cpu1_tx_fifo_empty,
    // Interfaces to CPU 2
    output reg [6:0]  cpu2_ram_op_addr,
    output reg [3:0]  cpu2_ram_op_wdata,
    output reg        cpu2_ram_op_we,
    output reg [5:0]  cpu2_ram_op1_addr,
    output reg [3:0]  cpu2_ram_op1_wdata,
    output reg        cpu2_ram_op1_we,
    output reg [2:0]  cpu2_ram_op2_addr,
    output reg [3:0]  cpu2_ram_op2_wdata,
    output reg        cpu2_ram_op2_we,
    output reg [3:0]  cpu2_jmp_addr,
    output reg [15:0] cpu2_jmp_wdata,
    output reg        cpu2_jmp_we,
    output reg [7:0]  cpu2_rx_fifo_wdata,
    output reg        cpu2_rx_fifo_we,
    input  wire [7:0] cpu2_tx_fifo_rdata,
    output reg        cpu2_tx_fifo_re,
    input  wire       cpu2_tx_fifo_empty,
    // Interfaces to CPU 3
    output reg [6:0]  cpu3_ram_op_addr,
    output reg [3:0]  cpu3_ram_op_wdata,
    output reg        cpu3_ram_op_we,
    output reg [5:0]  cpu3_ram_op1_addr,
    output reg [3:0]  cpu3_ram_op1_wdata,
    output reg        cpu3_ram_op1_we,
    output reg [2:0]  cpu3_ram_op2_addr,
    output reg [3:0]  cpu3_ram_op2_wdata,
    output reg        cpu3_ram_op2_we,
    output reg [3:0]  cpu3_jmp_addr,
    output reg [15:0] cpu3_jmp_wdata,
    output reg        cpu3_jmp_we,
    output reg [7:0]  cpu3_rx_fifo_wdata,
    output reg        cpu3_rx_fifo_we,
    input  wire [7:0] cpu3_tx_fifo_rdata,
    output reg        cpu3_tx_fifo_re,
    input  wire       cpu3_tx_fifo_empty,
    // Dummy wire to fix trailing comma
    output wire dummy
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
    reg [2:0] bit_cnt; // Naturally wraps to 0 after 7
    reg [7:0] cmd_byte;
    reg       is_cmd_phase;
    reg [7:0] jmp_high_byte;
    reg       is_jmp_low;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg <= 0;
            bit_cnt <= 0;
            cmd_byte <= 0;
            is_cmd_phase <= 1;
            is_jmp_low <= 0;
            jmp_high_byte <= 0;
            spi_miso <= 0;

            cpu0_ram_op_addr <= 0; cpu0_ram_op_we <= 0;
            cpu0_ram_op1_addr <= 0; cpu0_ram_op1_we <= 0;
            cpu0_ram_op2_addr <= 0; cpu0_ram_op2_we <= 0;
            cpu0_jmp_addr <= 0; cpu0_jmp_we <= 0;
            cpu0_rx_fifo_we <= 0; cpu0_tx_fifo_re <= 0;
            cpu1_ram_op_addr <= 0; cpu1_ram_op_we <= 0;
            cpu1_ram_op1_addr <= 0; cpu1_ram_op1_we <= 0;
            cpu1_ram_op2_addr <= 0; cpu1_ram_op2_we <= 0;
            cpu1_jmp_addr <= 0; cpu1_jmp_we <= 0;
            cpu1_rx_fifo_we <= 0; cpu1_tx_fifo_re <= 0;
            cpu2_ram_op_addr <= 0; cpu2_ram_op_we <= 0;
            cpu2_ram_op1_addr <= 0; cpu2_ram_op1_we <= 0;
            cpu2_ram_op2_addr <= 0; cpu2_ram_op2_we <= 0;
            cpu2_jmp_addr <= 0; cpu2_jmp_we <= 0;
            cpu2_rx_fifo_we <= 0; cpu2_tx_fifo_re <= 0;
            cpu3_ram_op_addr <= 0; cpu3_ram_op_we <= 0;
            cpu3_ram_op1_addr <= 0; cpu3_ram_op1_we <= 0;
            cpu3_ram_op2_addr <= 0; cpu3_ram_op2_we <= 0;
            cpu3_jmp_addr <= 0; cpu3_jmp_we <= 0;
            cpu3_rx_fifo_we <= 0; cpu3_tx_fifo_re <= 0;
        end else begin
            // Clear single-cycle strobes

            cpu0_ram_op_we <= 0;
            cpu0_ram_op1_we <= 0;
            cpu0_ram_op2_we <= 0;
            cpu0_jmp_we <= 0;
            cpu0_rx_fifo_we <= 0;
            cpu0_tx_fifo_re <= 0;
            cpu1_ram_op_we <= 0;
            cpu1_ram_op1_we <= 0;
            cpu1_ram_op2_we <= 0;
            cpu1_jmp_we <= 0;
            cpu1_rx_fifo_we <= 0;
            cpu1_tx_fifo_re <= 0;
            cpu2_ram_op_we <= 0;
            cpu2_ram_op1_we <= 0;
            cpu2_ram_op2_we <= 0;
            cpu2_jmp_we <= 0;
            cpu2_rx_fifo_we <= 0;
            cpu2_tx_fifo_re <= 0;
            cpu3_ram_op_we <= 0;
            cpu3_ram_op1_we <= 0;
            cpu3_ram_op2_we <= 0;
            cpu3_jmp_we <= 0;
            cpu3_rx_fifo_we <= 0;
            cpu3_tx_fifo_re <= 0;
            
            if (spi_cs) begin
                if (!is_cmd_phase) $display("[%0t] spi_cs went HIGH! Resetting state.", $time);
                is_cmd_phase <= 1;
                bit_cnt <= 0;
                is_jmp_low <= 0;
            end else begin
                // SHIFT IN ON RISING EDGE
                if (sclk_rise) begin
                    shift_reg <= {shift_reg[6:0], spi_mosi};
                    bit_cnt <= bit_cnt + 1;
                    $display("[%0t] sclk_rise! bit_cnt=%d, mosi=%b", $time, bit_cnt, spi_mosi);
                    
                    if (bit_cnt == 7) begin
                        if (is_cmd_phase) begin
                            cmd_byte <= {shift_reg[6:0], spi_mosi};
                            $display("[%0t] SPI CMD RECEIVED: %h", $time, {shift_reg[6:0], spi_mosi});
                            is_cmd_phase <= 0;
                            is_jmp_low <= 0;
                            // Reset pointers

                            cpu0_ram_op_addr <= 7'h7F;
                            cpu0_ram_op1_addr <= 6'h3F;
                            cpu0_ram_op2_addr <= 3'h7;
                            cpu0_jmp_addr <= 4'hF;
                            cpu1_ram_op_addr <= 7'h7F;
                            cpu1_ram_op1_addr <= 6'h3F;
                            cpu1_ram_op2_addr <= 3'h7;
                            cpu1_jmp_addr <= 4'hF;
                            cpu2_ram_op_addr <= 7'h7F;
                            cpu2_ram_op1_addr <= 6'h3F;
                            cpu2_ram_op2_addr <= 3'h7;
                            cpu2_jmp_addr <= 4'hF;
                            cpu3_ram_op_addr <= 7'h7F;
                            cpu3_ram_op1_addr <= 6'h3F;
                            cpu3_ram_op2_addr <= 3'h7;
                            cpu3_jmp_addr <= 4'hF;
                        end else begin
                            case (cmd_byte)

                                8'h00: begin // OP CPU0
                                    cpu0_ram_op_wdata <= {shift_reg[2:0], spi_mosi};
                                    cpu0_ram_op_we <= 1;
                                    cpu0_ram_op_addr <= cpu0_ram_op_addr + 1;
                                end
                                8'h10: begin // OP1 CPU0
                                    cpu0_ram_op1_wdata <= {shift_reg[2:0], spi_mosi};
                                    cpu0_ram_op1_we <= 1;
                                    cpu0_ram_op1_addr <= cpu0_ram_op1_addr + 1;
                                end
                                8'h20: begin // OP2 CPU0
                                    cpu0_ram_op2_wdata <= {shift_reg[2:0], spi_mosi};
                                    cpu0_ram_op2_we <= 1;
                                    cpu0_ram_op2_addr <= cpu0_ram_op2_addr + 1;
                                end
                                8'h30: begin // JMP CPU0
                                    if (!is_jmp_low) begin
                                        jmp_high_byte <= {shift_reg[6:0], spi_mosi};
                                        is_jmp_low <= 1;
                                    end else begin
                                        cpu0_jmp_wdata <= {jmp_high_byte, shift_reg[6:0], spi_mosi};
                                        cpu0_jmp_we <= 1;
                                        cpu0_jmp_addr <= cpu0_jmp_addr + 1;
                                        is_jmp_low <= 0;
                                    end
                                end
                                8'h02: begin // RX FIFO CPU0
                                    $display("[%0t] SPI WRITING TO CPU0 RX FIFO: %h", $time, {shift_reg[6:0], spi_mosi});
                                    cpu0_rx_fifo_wdata <= {shift_reg[6:0], spi_mosi};
                                    cpu0_rx_fifo_we <= 1;
                                end
                                8'h01: begin // OP CPU1
                                    cpu1_ram_op_wdata <= {shift_reg[2:0], spi_mosi};
                                    cpu1_ram_op_we <= 1;
                                    cpu1_ram_op_addr <= cpu1_ram_op_addr + 1;
                                end
                                8'h11: begin // OP1 CPU1
                                    cpu1_ram_op1_wdata <= {shift_reg[2:0], spi_mosi};
                                    cpu1_ram_op1_we <= 1;
                                    cpu1_ram_op1_addr <= cpu1_ram_op1_addr + 1;
                                end
                                8'h21: begin // OP2 CPU1
                                    cpu1_ram_op2_wdata <= {shift_reg[2:0], spi_mosi};
                                    cpu1_ram_op2_we <= 1;
                                    cpu1_ram_op2_addr <= cpu1_ram_op2_addr + 1;
                                end
                                8'h31: begin // JMP CPU1
                                    if (!is_jmp_low) begin
                                        jmp_high_byte <= {shift_reg[6:0], spi_mosi};
                                        is_jmp_low <= 1;
                                    end else begin
                                        cpu1_jmp_wdata <= {jmp_high_byte, shift_reg[6:0], spi_mosi};
                                        cpu1_jmp_we <= 1;
                                        cpu1_jmp_addr <= cpu1_jmp_addr + 1;
                                        is_jmp_low <= 0;
                                    end
                                end
                                8'h03: begin // RX FIFO CPU1
                                    cpu1_rx_fifo_wdata <= {shift_reg[6:0], spi_mosi};
                                    cpu1_rx_fifo_we <= 1;
                                end
                                8'h08: begin // OP CPU2
                                    cpu2_ram_op_wdata <= {shift_reg[2:0], spi_mosi};
                                    cpu2_ram_op_we <= 1;
                                    cpu2_ram_op_addr <= cpu2_ram_op_addr + 1;
                                end
                                8'h18: begin // OP1 CPU2
                                    cpu2_ram_op1_wdata <= {shift_reg[2:0], spi_mosi};
                                    cpu2_ram_op1_we <= 1;
                                    cpu2_ram_op1_addr <= cpu2_ram_op1_addr + 1;
                                end
                                8'h28: begin // OP2 CPU2
                                    cpu2_ram_op2_wdata <= {shift_reg[2:0], spi_mosi};
                                    cpu2_ram_op2_we <= 1;
                                    cpu2_ram_op2_addr <= cpu2_ram_op2_addr + 1;
                                end
                                8'h38: begin // JMP CPU2
                                    if (!is_jmp_low) begin
                                        jmp_high_byte <= {shift_reg[6:0], spi_mosi};
                                        is_jmp_low <= 1;
                                    end else begin
                                        cpu2_jmp_wdata <= {jmp_high_byte, shift_reg[6:0], spi_mosi};
                                        cpu2_jmp_we <= 1;
                                        cpu2_jmp_addr <= cpu2_jmp_addr + 1;
                                        is_jmp_low <= 0;
                                    end
                                end
                                8'h0A: begin // RX FIFO CPU2
                                    cpu2_rx_fifo_wdata <= {shift_reg[6:0], spi_mosi};
                                    cpu2_rx_fifo_we <= 1;
                                end
                                8'h09: begin // OP CPU3
                                    cpu3_ram_op_wdata <= {shift_reg[2:0], spi_mosi};
                                    cpu3_ram_op_we <= 1;
                                    cpu3_ram_op_addr <= cpu3_ram_op_addr + 1;
                                end
                                8'h19: begin // OP1 CPU3
                                    cpu3_ram_op1_wdata <= {shift_reg[2:0], spi_mosi};
                                    cpu3_ram_op1_we <= 1;
                                    cpu3_ram_op1_addr <= cpu3_ram_op1_addr + 1;
                                end
                                8'h29: begin // OP2 CPU3
                                    cpu3_ram_op2_wdata <= {shift_reg[2:0], spi_mosi};
                                    cpu3_ram_op2_we <= 1;
                                    cpu3_ram_op2_addr <= cpu3_ram_op2_addr + 1;
                                end
                                8'h39: begin // JMP CPU3
                                    if (!is_jmp_low) begin
                                        jmp_high_byte <= {shift_reg[6:0], spi_mosi};
                                        is_jmp_low <= 1;
                                    end else begin
                                        cpu3_jmp_wdata <= {jmp_high_byte, shift_reg[6:0], spi_mosi};
                                        cpu3_jmp_we <= 1;
                                        cpu3_jmp_addr <= cpu3_jmp_addr + 1;
                                        is_jmp_low <= 0;
                                    end
                                end
                                8'h0B: begin // RX FIFO CPU3
                                    cpu3_rx_fifo_wdata <= {shift_reg[6:0], spi_mosi};
                                    cpu3_rx_fifo_we <= 1;
                                end
                                default: begin
                                    if (cmd_byte != 8'h04 && cmd_byte != 8'h05 && cmd_byte != 8'h0C && cmd_byte != 8'h0D)
                                        $display("[%0t] SPI UNKNOWN DATA! cmd_byte=%h data=%h", $time, cmd_byte, {shift_reg[6:0], spi_mosi});
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
