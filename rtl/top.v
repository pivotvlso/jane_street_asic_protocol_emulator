`default_nettype none

module top (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    wire spi_cs   = ui_in[0];
    wire spi_sclk = ui_in[1];
    wire spi_mosi = ui_in[2];
    wire spi_miso;
    wire ext_irq  = ui_in[4];
    
    assign uo_out[0] = spi_miso;

    // ========================================================
    // SPI SLAVE 
    // ========================================================
    wire [6:0] cpu0_ram_waddr; wire [3:0] cpu0_ram_wdata; wire cpu0_ram_we;
    wire [7:0] cpu0_rx_fifo_wdata; wire cpu0_rx_fifo_we;
    wire [7:0] cpu0_tx_fifo_rdata; wire cpu0_tx_fifo_re; wire cpu0_tx_fifo_empty;
    wire cpu0_run;
    wire [6:0] cpu1_ram_waddr; wire [3:0] cpu1_ram_wdata; wire cpu1_ram_we;
    wire [7:0] cpu1_rx_fifo_wdata; wire cpu1_rx_fifo_we;
    wire [7:0] cpu1_tx_fifo_rdata; wire cpu1_tx_fifo_re; wire cpu1_tx_fifo_empty;
    wire cpu1_run;
    wire [6:0] cpu2_ram_waddr; wire [3:0] cpu2_ram_wdata; wire cpu2_ram_we;
    wire [7:0] cpu2_rx_fifo_wdata; wire cpu2_rx_fifo_we;
    wire [7:0] cpu2_tx_fifo_rdata; wire cpu2_tx_fifo_re; wire cpu2_tx_fifo_empty;
    wire cpu2_run;
    wire [6:0] cpu3_ram_waddr; wire [3:0] cpu3_ram_wdata; wire cpu3_ram_we;
    wire [7:0] cpu3_rx_fifo_wdata; wire cpu3_rx_fifo_we;
    wire [7:0] cpu3_tx_fifo_rdata; wire cpu3_tx_fifo_re; wire cpu3_tx_fifo_empty;
    wire cpu3_run;

    spi_slave spi_inst (
        .clk(clk), .rst_n(rst_n),
        .spi_cs(spi_cs), .spi_sclk(spi_sclk), .spi_mosi(spi_mosi), .spi_miso(spi_miso),

        .cpu0_ram_addr(cpu0_ram_waddr), .cpu0_ram_wdata(cpu0_ram_wdata), .cpu0_ram_we(cpu0_ram_we),
        .cpu0_rx_fifo_wdata(cpu0_rx_fifo_wdata), .cpu0_rx_fifo_we(cpu0_rx_fifo_we),
        .cpu0_tx_fifo_rdata(cpu0_tx_fifo_rdata), .cpu0_tx_fifo_re(cpu0_tx_fifo_re),
        .cpu0_tx_fifo_empty(cpu0_tx_fifo_empty), .cpu0_run(cpu0_run),
        .cpu1_ram_addr(cpu1_ram_waddr), .cpu1_ram_wdata(cpu1_ram_wdata), .cpu1_ram_we(cpu1_ram_we),
        .cpu1_rx_fifo_wdata(cpu1_rx_fifo_wdata), .cpu1_rx_fifo_we(cpu1_rx_fifo_we),
        .cpu1_tx_fifo_rdata(cpu1_tx_fifo_rdata), .cpu1_tx_fifo_re(cpu1_tx_fifo_re),
        .cpu1_tx_fifo_empty(cpu1_tx_fifo_empty), .cpu1_run(cpu1_run),
        .cpu2_ram_addr(cpu2_ram_waddr), .cpu2_ram_wdata(cpu2_ram_wdata), .cpu2_ram_we(cpu2_ram_we),
        .cpu2_rx_fifo_wdata(cpu2_rx_fifo_wdata), .cpu2_rx_fifo_we(cpu2_rx_fifo_we),
        .cpu2_tx_fifo_rdata(cpu2_tx_fifo_rdata), .cpu2_tx_fifo_re(cpu2_tx_fifo_re),
        .cpu2_tx_fifo_empty(cpu2_tx_fifo_empty), .cpu2_run(cpu2_run),
        .cpu3_ram_addr(cpu3_ram_waddr), .cpu3_ram_wdata(cpu3_ram_wdata), .cpu3_ram_we(cpu3_ram_we),
        .cpu3_rx_fifo_wdata(cpu3_rx_fifo_wdata), .cpu3_rx_fifo_we(cpu3_rx_fifo_we),
        .cpu3_tx_fifo_rdata(cpu3_tx_fifo_rdata), .cpu3_tx_fifo_re(cpu3_tx_fifo_re),
        .cpu3_tx_fifo_empty(cpu3_tx_fifo_empty), .cpu3_run(cpu3_run)
    );

    // ========================================================
    // CPU 0 SUBSYSTEM
    // ========================================================
    reg [3:0] cpu0_ram [0:127];
    wire [6:0] cpu0_pc_addr;
    wire [3:0] cpu0_rom_data = cpu0_ram[cpu0_pc_addr];
    always @(posedge clk) if (cpu0_ram_we) cpu0_ram[cpu0_ram_waddr] <= cpu0_ram_wdata;

    wire [3:0] cpu0_pin_out, cpu0_pin_dir;
    wire [3:0] cpu0_mem_addr;
    wire [7:0] cpu0_mem_wdata;
    wire cpu0_mem_we, cpu0_mem_re;
    reg  [7:0] cpu0_mem_rdata;
    wire       cpu0_mem_stall;

    wire [7:0] cpu0_rx_rdata; wire cpu0_rx_empty, cpu0_rx_full;
    wire cpu0_rx_re = (cpu0_mem_addr == 4'h5) && cpu0_mem_re && !cpu0_rx_empty;
    fifo rx0 (.clk(clk), .rst_n(rst_n), .wdata(cpu0_rx_fifo_wdata), .we(cpu0_rx_fifo_we),
              .rdata(cpu0_rx_rdata), .re(cpu0_rx_re), .empty(cpu0_rx_empty), .full(cpu0_rx_full));
              
    wire cpu0_tx_full;
    wire cpu0_tx_we = (cpu0_mem_addr == 4'h4) && cpu0_mem_we && !cpu0_tx_full;
    fifo tx0 (.clk(clk), .rst_n(rst_n), .wdata(cpu0_mem_wdata), .we(cpu0_tx_we),
              .rdata(cpu0_tx_fifo_rdata), .re(cpu0_tx_fifo_re), .empty(cpu0_tx_fifo_empty), .full(cpu0_tx_full));

    wire [7:0] cpu0_timer_rdata; wire cpu0_timer_zero;
    wire cpu0_timer_we_l = (cpu0_mem_addr == 4'h7) && cpu0_mem_we;
    wire cpu0_timer_we_h = (cpu0_mem_addr == 4'h8) && cpu0_mem_we;
    timer tmr0 (.clk(clk), .rst_n(rst_n), .wdata(cpu0_mem_wdata), .we_l(cpu0_timer_we_l), .we_h(cpu0_timer_we_h),
                .rdata_l(cpu0_timer_rdata), .is_zero(cpu0_timer_zero));

    always @(*) begin
        cpu0_mem_rdata = 8'h00;
        if (cpu0_mem_addr == 4'h5) cpu0_mem_rdata = cpu0_rx_rdata;
        else if (cpu0_mem_addr == 4'h6) cpu0_mem_rdata = {4'b0, uio_in[3:0]};
        else if (cpu0_mem_addr == 4'h7) cpu0_mem_rdata = cpu0_timer_rdata;
    end
    
    assign cpu0_mem_stall = ((cpu0_mem_addr == 4'h5) && cpu0_mem_re && cpu0_rx_empty) ||
                            ((cpu0_mem_addr == 4'h4) && cpu0_mem_we && cpu0_tx_full) ||
                            ((cpu0_mem_addr == 4'h7) && cpu0_mem_re && !cpu0_timer_zero);

    cpu_core core0 (
        .clk(clk), .rst_n(rst_n), .run(cpu0_run), .irq(ext_irq),
        .pin_out(cpu0_pin_out), .pin_dir(cpu0_pin_dir),
        .rom_addr(cpu0_pc_addr), .rom_data(cpu0_rom_data),
        .mem_addr(cpu0_mem_addr), .mem_wdata(cpu0_mem_wdata), .mem_we(cpu0_mem_we), .mem_re(cpu0_mem_re),
        .mem_rdata(cpu0_mem_rdata), .mem_stall(cpu0_mem_stall)
    );
    
    always @(posedge clk) begin
        if (cpu0_run && core0.state == 3'd4) begin
            $display("DBG|0|%0t|%h|%h|%h|%h|%h|%h|%h|%h|%h|%h|%h|%h|%h", $time, core0.pc, core0.curr_opcode, core0.acc, core0.b_reg, core0.r_regs[2], core0.r_regs[3], core0.r_regs[4], core0.r_regs[8], core0.flag_carry, core0.flag_zero, core0.pin_dir, core0.pin_out);
        end
    end

    // ========================================================
    // CPU 1 SUBSYSTEM
    // ========================================================
    reg [3:0] cpu1_ram [0:127];
    wire [6:0] cpu1_pc_addr;
    wire [3:0] cpu1_rom_data = cpu1_ram[cpu1_pc_addr];
    always @(posedge clk) if (cpu1_ram_we) cpu1_ram[cpu1_ram_waddr] <= cpu1_ram_wdata;

    wire [3:0] cpu1_pin_out, cpu1_pin_dir;
    wire [3:0] cpu1_pin_in = uio_in[3:0];
    wire [3:0] cpu1_mem_addr;
    wire [7:0] cpu1_mem_wdata;
    wire cpu1_mem_we, cpu1_mem_re;
    reg  [7:0] cpu1_mem_rdata;
    wire       cpu1_mem_stall;

    wire [7:0] cpu1_rx_rdata; wire cpu1_rx_empty, cpu1_rx_full;
    wire cpu1_rx_re = (cpu1_mem_addr == 4'h5) && cpu1_mem_re && !cpu1_rx_empty;
    fifo rx1 (.clk(clk), .rst_n(rst_n), .wdata(cpu1_rx_fifo_wdata), .we(cpu1_rx_fifo_we),
              .rdata(cpu1_rx_rdata), .re(cpu1_rx_re), .empty(cpu1_rx_empty), .full(cpu1_rx_full));
              
    wire cpu1_tx_full;
    wire cpu1_tx_we = (cpu1_mem_addr == 4'h4) && cpu1_mem_we && !cpu1_tx_full;
    fifo tx1 (.clk(clk), .rst_n(rst_n), .wdata(cpu1_mem_wdata), .we(cpu1_tx_we),
              .rdata(cpu1_tx_fifo_rdata), .re(cpu1_tx_fifo_re), .empty(cpu1_tx_fifo_empty), .full(cpu1_tx_full));

    always @(posedge clk) begin
        if (cpu1_tx_we) $display("[%0t] CPU 1 WROTE TO TX FIFO: 0x%h", $time, cpu1_mem_wdata);
    end

    wire [7:0] cpu1_timer_rdata; wire cpu1_timer_zero;
    wire cpu1_timer_we_l = (cpu1_mem_addr == 4'h7) && cpu1_mem_we;
    wire cpu1_timer_we_h = (cpu1_mem_addr == 4'h8) && cpu1_mem_we;
    timer tmr1 (.clk(clk), .rst_n(rst_n), .wdata(cpu1_mem_wdata), .we_l(cpu1_timer_we_l), .we_h(cpu1_timer_we_h),
                .rdata_l(cpu1_timer_rdata), .is_zero(cpu1_timer_zero));

    always @(*) begin
        cpu1_mem_rdata = 8'h00;
        if (cpu1_mem_addr == 4'h5) cpu1_mem_rdata = cpu1_rx_rdata;
        else if (cpu1_mem_addr == 4'h6) cpu1_mem_rdata = {4'b0, uio_in[3:0]};
        else if (cpu1_mem_addr == 4'h7) cpu1_mem_rdata = cpu1_timer_rdata;
    end
    
    assign cpu1_mem_stall = ((cpu1_mem_addr == 4'h5) && cpu1_mem_re && cpu1_rx_empty) ||
                            ((cpu1_mem_addr == 4'h4) && cpu1_mem_we && cpu1_tx_full) ||
                            ((cpu1_mem_addr == 4'h7) && cpu1_mem_re && !cpu1_timer_zero);

    cpu_core core1 (
        .clk(clk), .rst_n(rst_n), .run(cpu1_run), .irq(ext_irq),
        .pin_out(cpu1_pin_out), .pin_dir(cpu1_pin_dir),
        .rom_addr(cpu1_pc_addr), .rom_data(cpu1_rom_data),
        .mem_addr(cpu1_mem_addr), .mem_wdata(cpu1_mem_wdata), .mem_we(cpu1_mem_we), .mem_re(cpu1_mem_re),
        .mem_rdata(cpu1_mem_rdata), .mem_stall(cpu1_mem_stall)
    );

    always @(posedge clk) begin
        if (cpu1_run && core1.state == 3'd4) begin
            $display("DBG|1|%0t|%h|%h|%h|%h|%h|%h|%h|%h|%h|%h|%h|%h|%h", $time, core1.pc, core1.curr_opcode, core1.acc, core1.b_reg, core1.r_regs[2], core1.r_regs[3], core1.r_regs[4], core1.r_regs[8], core1.flag_carry, core1.flag_zero, core1.pin_dir, core1.pin_out);
        end
    end

    // ========================================================
    // CPU 2 SUBSYSTEM
    // ========================================================
    reg [3:0] cpu2_ram [0:127];
    wire [6:0] cpu2_pc_addr;
    wire [3:0] cpu2_rom_data = cpu2_ram[cpu2_pc_addr];
    always @(posedge clk) if (cpu2_ram_we) cpu2_ram[cpu2_ram_waddr] <= cpu2_ram_wdata;

    wire [3:0] cpu2_pin_out, cpu2_pin_dir;
    wire [3:0] cpu2_pin_in = uio_in[3:0];
    wire [3:0] cpu2_mem_addr;
    wire [7:0] cpu2_mem_wdata;
    wire cpu2_mem_we, cpu2_mem_re;
    reg  [7:0] cpu2_mem_rdata;
    wire       cpu2_mem_stall;

    wire [7:0] cpu2_rx_rdata; wire cpu2_rx_empty, cpu2_rx_full;
    wire cpu2_rx_re = (cpu2_mem_addr == 4'h5) && cpu2_mem_re && !cpu2_rx_empty;
    fifo rx2 (.clk(clk), .rst_n(rst_n), .wdata(cpu2_rx_fifo_wdata), .we(cpu2_rx_fifo_we),
              .rdata(cpu2_rx_rdata), .re(cpu2_rx_re), .empty(cpu2_rx_empty), .full(cpu2_rx_full));
              
    wire cpu2_tx_full;
    wire cpu2_tx_we = (cpu2_mem_addr == 4'h4) && cpu2_mem_we && !cpu2_tx_full;
    fifo tx2 (.clk(clk), .rst_n(rst_n), .wdata(cpu2_mem_wdata), .we(cpu2_tx_we),
              .rdata(cpu2_tx_fifo_rdata), .re(cpu2_tx_fifo_re), .empty(cpu2_tx_fifo_empty), .full(cpu2_tx_full));

    wire [7:0] cpu2_timer_rdata; wire cpu2_timer_zero;
    wire cpu2_timer_we_l = (cpu2_mem_addr == 4'h7) && cpu2_mem_we;
    wire cpu2_timer_we_h = (cpu2_mem_addr == 4'h8) && cpu2_mem_we;
    timer tmr2 (.clk(clk), .rst_n(rst_n), .wdata(cpu2_mem_wdata), .we_l(cpu2_timer_we_l), .we_h(cpu2_timer_we_h),
                .rdata_l(cpu2_timer_rdata), .is_zero(cpu2_timer_zero));

    always @(*) begin
        cpu2_mem_rdata = 8'h00;
        if (cpu2_mem_addr == 4'h5) cpu2_mem_rdata = cpu2_rx_rdata;
        else if (cpu2_mem_addr == 4'h6) cpu2_mem_rdata = {4'b0, uio_in[3:0]};
        else if (cpu2_mem_addr == 4'h7) cpu2_mem_rdata = cpu2_timer_rdata;
    end
    
    assign cpu2_mem_stall = ((cpu2_mem_addr == 4'h5) && cpu2_mem_re && cpu2_rx_empty) ||
                            ((cpu2_mem_addr == 4'h4) && cpu2_mem_we && cpu2_tx_full) ||
                            ((cpu2_mem_addr == 4'h7) && cpu2_mem_re && !cpu2_timer_zero);

    cpu_core core2 (
        .clk(clk), .rst_n(rst_n), .run(cpu2_run), .irq(ext_irq),
        .pin_out(cpu2_pin_out), .pin_dir(cpu2_pin_dir),
        .rom_addr(cpu2_pc_addr), .rom_data(cpu2_rom_data),
        .mem_addr(cpu2_mem_addr), .mem_wdata(cpu2_mem_wdata), .mem_we(cpu2_mem_we), .mem_re(cpu2_mem_re),
        .mem_rdata(cpu2_mem_rdata), .mem_stall(cpu2_mem_stall)
    );

    // ========================================================
    // CPU 3 SUBSYSTEM
    // ========================================================
    reg [3:0] cpu3_ram [0:127];
    wire [6:0] cpu3_pc_addr;
    wire [3:0] cpu3_rom_data = cpu3_ram[cpu3_pc_addr];
    always @(posedge clk) if (cpu3_ram_we) cpu3_ram[cpu3_ram_waddr] <= cpu3_ram_wdata;

    wire [3:0] cpu3_pin_out, cpu3_pin_dir;
    wire [3:0] cpu3_pin_in = uio_in[3:0];
    wire [3:0] cpu3_mem_addr;
    wire [7:0] cpu3_mem_wdata;
    wire cpu3_mem_we, cpu3_mem_re;
    reg  [7:0] cpu3_mem_rdata;
    wire       cpu3_mem_stall;

    wire [7:0] cpu3_rx_rdata; wire cpu3_rx_empty, cpu3_rx_full;
    wire cpu3_rx_re = (cpu3_mem_addr == 4'h5) && cpu3_mem_re && !cpu3_rx_empty;
    fifo rx3 (.clk(clk), .rst_n(rst_n), .wdata(cpu3_rx_fifo_wdata), .we(cpu3_rx_fifo_we),
              .rdata(cpu3_rx_rdata), .re(cpu3_rx_re), .empty(cpu3_rx_empty), .full(cpu3_rx_full));
              
    wire cpu3_tx_full;
    wire cpu3_tx_we = (cpu3_mem_addr == 4'h4) && cpu3_mem_we && !cpu3_tx_full;
    fifo tx3 (.clk(clk), .rst_n(rst_n), .wdata(cpu3_mem_wdata), .we(cpu3_tx_we),
              .rdata(cpu3_tx_fifo_rdata), .re(cpu3_tx_fifo_re), .empty(cpu3_tx_fifo_empty), .full(cpu3_tx_full));

    wire [7:0] cpu3_timer_rdata; wire cpu3_timer_zero;
    wire cpu3_timer_we_l = (cpu3_mem_addr == 4'h7) && cpu3_mem_we;
    wire cpu3_timer_we_h = (cpu3_mem_addr == 4'h8) && cpu3_mem_we;
    timer tmr3 (.clk(clk), .rst_n(rst_n), .wdata(cpu3_mem_wdata), .we_l(cpu3_timer_we_l), .we_h(cpu3_timer_we_h),
                .rdata_l(cpu3_timer_rdata), .is_zero(cpu3_timer_zero));

    always @(*) begin
        cpu3_mem_rdata = 8'h00;
        if (cpu3_mem_addr == 4'h5) cpu3_mem_rdata = cpu3_rx_rdata;
        else if (cpu3_mem_addr == 4'h6) cpu3_mem_rdata = {4'b0, uio_in[3:0]};
        else if (cpu3_mem_addr == 4'h7) cpu3_mem_rdata = cpu3_timer_rdata;
    end
    
    assign cpu3_mem_stall = ((cpu3_mem_addr == 4'h5) && cpu3_mem_re && cpu3_rx_empty) ||
                            ((cpu3_mem_addr == 4'h4) && cpu3_mem_we && cpu3_tx_full) ||
                            ((cpu3_mem_addr == 4'h7) && cpu3_mem_re && !cpu3_timer_zero);

    cpu_core core3 (
        .clk(clk), .rst_n(rst_n), .run(cpu3_run), .irq(ext_irq),
        .pin_out(cpu3_pin_out), .pin_dir(cpu3_pin_dir),
        .rom_addr(cpu3_pc_addr), .rom_data(cpu3_rom_data),
        .mem_addr(cpu3_mem_addr), .mem_wdata(cpu3_mem_wdata), .mem_we(cpu3_mem_we), .mem_re(cpu3_mem_re),
        .mem_rdata(cpu3_mem_rdata), .mem_stall(cpu3_mem_stall)
    );


    // ========================================================
    // PINS & STATUS
    // ========================================================
    assign uio_oe[3:0] = cpu0_pin_dir | cpu1_pin_dir | cpu2_pin_dir | cpu3_pin_dir;
    
    wire [3:0] cpu0_safe_out = cpu0_pin_dir & cpu0_pin_out;
    wire [3:0] cpu1_safe_out = cpu1_pin_dir & cpu1_pin_out;
    wire [3:0] cpu2_safe_out = cpu2_pin_dir & cpu2_pin_out;
    wire [3:0] cpu3_safe_out = cpu3_pin_dir & cpu3_pin_out;
    
    assign uio_out[3:0] = cpu0_safe_out | cpu1_safe_out | cpu2_safe_out | cpu3_safe_out;
    assign uio_oe[7:4] = 4'b0000;
    assign uio_out[7:4] = 4'b0000;

    // Map FIFO status flags to output pins for the RP2040 Host
    assign uo_out[1] = cpu0_rx_empty;
    assign uo_out[2] = cpu1_rx_empty;
    assign uo_out[3] = cpu2_rx_empty;
    assign uo_out[4] = cpu3_rx_empty;
    assign uo_out[5] = cpu0_tx_fifo_empty;
    assign uo_out[6] = cpu1_tx_fifo_empty;
    assign uo_out[7] = cpu2_tx_fifo_empty; // cpu3_tx_empty omitted from physical pins

endmodule
