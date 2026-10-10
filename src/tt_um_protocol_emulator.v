`default_nettype none
`timescale 1ns/1ps

module tt_um_protocol_emulator (
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
    wire spi_miso = 1'b0;
    assign uo_out[0] = spi_miso;

    // ========================================================
    // SPI SLAVE 
    // ========================================================

    wire [7:0] cpu0_rx_fifo_wdata = 8'h00; wire cpu0_rx_fifo_we = 1'b0;
    wire [7:0] cpu0_tx_fifo_rdata; wire cpu0_tx_fifo_re = 1'b0; wire cpu0_tx_fifo_empty;
    wire cpu0_run = ui_in[4];
    wire [7:0] cpu1_rx_fifo_wdata = 8'h00; wire cpu1_rx_fifo_we = 1'b0;
    wire [7:0] cpu1_tx_fifo_rdata; wire cpu1_tx_fifo_re = 1'b0; wire cpu1_tx_fifo_empty;
    wire cpu1_run = ui_in[5];
    wire [7:0] cpu2_rx_fifo_wdata = 8'h00; wire cpu2_rx_fifo_we = 1'b0;
    wire [7:0] cpu2_tx_fifo_rdata; wire cpu2_tx_fifo_re = 1'b0; wire cpu2_tx_fifo_empty;
    wire cpu2_run = ui_in[6];
    wire [7:0] cpu3_rx_fifo_wdata = 8'h00; wire cpu3_rx_fifo_we = 1'b0;
    wire [7:0] cpu3_tx_fifo_rdata; wire cpu3_tx_fifo_re = 1'b0; wire cpu3_tx_fifo_empty;
    wire cpu3_run = ui_in[7];



    // ========================================================
    // SHARED REGISTERS (0x9 and 0xA)
    // ========================================================
    reg [7:0] shared_reg_0; reg shared_reg_0_valid;
    reg [7:0] shared_reg_1; reg shared_reg_1_valid;
    reg [7:0] shared_reg_2; reg shared_reg_2_valid;
    reg [7:0] shared_reg_3; reg shared_reg_3_valid;

    always @(posedge clk) begin
        if (!rst_n) begin
            shared_reg_0 <= 0; shared_reg_0_valid <= 0;
            shared_reg_1 <= 0; shared_reg_1_valid <= 0;
            shared_reg_2 <= 0; shared_reg_2_valid <= 0;
            shared_reg_3 <= 0; shared_reg_3_valid <= 0;
        end else begin
            // Reads (Clears valid flag when read happens successfully)
            if (cpu0_mem_re && cpu0_mem_addr == 4'h9 && shared_reg_0_valid) shared_reg_0_valid <= 1'b0;
            if (cpu1_mem_re && cpu1_mem_addr == 4'h9 && shared_reg_0_valid) shared_reg_0_valid <= 1'b0;
            if (cpu2_mem_re && cpu2_mem_addr == 4'h9 && shared_reg_0_valid) shared_reg_0_valid <= 1'b0;
            if (cpu3_mem_re && cpu3_mem_addr == 4'h9 && shared_reg_0_valid) shared_reg_0_valid <= 1'b0;

            if (cpu0_mem_re && cpu0_mem_addr == 4'hA && shared_reg_1_valid) shared_reg_1_valid <= 1'b0;
            if (cpu1_mem_re && cpu1_mem_addr == 4'hA && shared_reg_1_valid) shared_reg_1_valid <= 1'b0;
            if (cpu2_mem_re && cpu2_mem_addr == 4'hA && shared_reg_1_valid) shared_reg_1_valid <= 1'b0;
            if (cpu3_mem_re && cpu3_mem_addr == 4'hA && shared_reg_1_valid) shared_reg_1_valid <= 1'b0;

            if (cpu0_mem_re && cpu0_mem_addr == 4'hB && shared_reg_2_valid) shared_reg_2_valid <= 1'b0;
            if (cpu1_mem_re && cpu1_mem_addr == 4'hB && shared_reg_2_valid) shared_reg_2_valid <= 1'b0;
            if (cpu2_mem_re && cpu2_mem_addr == 4'hB && shared_reg_2_valid) shared_reg_2_valid <= 1'b0;
            if (cpu3_mem_re && cpu3_mem_addr == 4'hB && shared_reg_2_valid) shared_reg_2_valid <= 1'b0;

            if (cpu0_mem_re && cpu0_mem_addr == 4'hC && shared_reg_3_valid) shared_reg_3_valid <= 1'b0;
            if (cpu1_mem_re && cpu1_mem_addr == 4'hC && shared_reg_3_valid) shared_reg_3_valid <= 1'b0;
            if (cpu2_mem_re && cpu2_mem_addr == 4'hC && shared_reg_3_valid) shared_reg_3_valid <= 1'b0;
            if (cpu3_mem_re && cpu3_mem_addr == 4'hC && shared_reg_3_valid) shared_reg_3_valid <= 1'b0;

            // Writes (Sets valid flag)
            if (cpu0_mem_we && cpu0_mem_addr == 4'h9) begin shared_reg_0 <= cpu0_mem_wdata; shared_reg_0_valid <= 1'b1; end
            if (cpu1_mem_we && cpu1_mem_addr == 4'h9) begin shared_reg_0 <= cpu1_mem_wdata; shared_reg_0_valid <= 1'b1; end
            if (cpu2_mem_we && cpu2_mem_addr == 4'h9) begin shared_reg_0 <= cpu2_mem_wdata; shared_reg_0_valid <= 1'b1; end
            if (cpu3_mem_we && cpu3_mem_addr == 4'h9) begin shared_reg_0 <= cpu3_mem_wdata; shared_reg_0_valid <= 1'b1; end

            if (cpu0_mem_we && cpu0_mem_addr == 4'hA) begin shared_reg_1 <= cpu0_mem_wdata; shared_reg_1_valid <= 1'b1; end
            if (cpu1_mem_we && cpu1_mem_addr == 4'hA) begin shared_reg_1 <= cpu1_mem_wdata; shared_reg_1_valid <= 1'b1; end
            if (cpu2_mem_we && cpu2_mem_addr == 4'hA) begin shared_reg_1 <= cpu2_mem_wdata; shared_reg_1_valid <= 1'b1; end
            if (cpu3_mem_we && cpu3_mem_addr == 4'hA) begin shared_reg_1 <= cpu3_mem_wdata; shared_reg_1_valid <= 1'b1; end

            if (cpu0_mem_we && cpu0_mem_addr == 4'hB) begin shared_reg_2 <= cpu0_mem_wdata; shared_reg_2_valid <= 1'b1; end
            if (cpu1_mem_we && cpu1_mem_addr == 4'hB) begin shared_reg_2 <= cpu1_mem_wdata; shared_reg_2_valid <= 1'b1; end
            if (cpu2_mem_we && cpu2_mem_addr == 4'hB) begin shared_reg_2 <= cpu2_mem_wdata; shared_reg_2_valid <= 1'b1; end
            if (cpu3_mem_we && cpu3_mem_addr == 4'hB) begin shared_reg_2 <= cpu3_mem_wdata; shared_reg_2_valid <= 1'b1; end

            if (cpu0_mem_we && cpu0_mem_addr == 4'hC) begin shared_reg_3 <= cpu0_mem_wdata; shared_reg_3_valid <= 1'b1; end
            if (cpu1_mem_we && cpu1_mem_addr == 4'hC) begin shared_reg_3 <= cpu1_mem_wdata; shared_reg_3_valid <= 1'b1; end
            if (cpu2_mem_we && cpu2_mem_addr == 4'hC) begin shared_reg_3 <= cpu2_mem_wdata; shared_reg_3_valid <= 1'b1; end
            if (cpu3_mem_we && cpu3_mem_addr == 4'hC) begin shared_reg_3 <= cpu3_mem_wdata; shared_reg_3_valid <= 1'b1; end
        end
    end

    // ========================================================
    // CPU 0 SUBSYSTEM
    // ========================================================
    // ROM Instantiation
    wire [3:0] cpu0_rom_op_data;
    wire [3:0] cpu0_rom_op1_data;
    wire [3:0] cpu0_rom_op2_data;
    wire [16:0] cpu0_jmp_data;
    
    rom_cpu0 rom0 (
        .pc_op(cpu0_pc_op), .op_data(cpu0_rom_op_data),
        .pc_op1(cpu0_pc_op1), .op1_data(cpu0_rom_op1_data),
        .pc_op2(cpu0_pc_op2), .op2_data(cpu0_rom_op2_data),
        .jmp_addr(cpu0_jmp_addr), .jmp_data(cpu0_jmp_data)
    );
    wire [6:0] cpu0_pc_op;
    wire [5:0] cpu0_pc_op1;
    wire [3:0] cpu0_pc_op2;
    wire [3:0] cpu0_jmp_addr;
    

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
        if (cpu0_mem_addr == 4'h5) cpu0_mem_rdata = cpu0_rx_empty ? 8'h00 : cpu0_rx_rdata;
        else if (cpu0_mem_addr == 4'h6) cpu0_mem_rdata = {4'b0, uio_in[3:0]};
        else if (cpu0_mem_addr == 4'h7) cpu0_mem_rdata = cpu0_timer_rdata;
        else if (cpu0_mem_addr == 4'h9) cpu0_mem_rdata = shared_reg_0;
        else if (cpu0_mem_addr == 4'hA) cpu0_mem_rdata = shared_reg_1;
        else if (cpu0_mem_addr == 4'hB) cpu0_mem_rdata = shared_reg_2;
        else if (cpu0_mem_addr == 4'hC) cpu0_mem_rdata = shared_reg_3;
    end
    
    assign cpu0_mem_stall = 
        (cpu0_mem_re && cpu0_mem_addr == 4'h5 && cpu0_rx_empty) || 
        (cpu0_mem_re && cpu0_mem_addr == 4'h7 && !cpu0_timer_zero) ||
        (cpu0_mem_re && cpu0_mem_addr == 4'h9 && !shared_reg_0_valid) ||
        (cpu0_mem_re && cpu0_mem_addr == 4'hA && !shared_reg_1_valid) ||
        (cpu0_mem_re && cpu0_mem_addr == 4'hB && !shared_reg_2_valid) ||
        (cpu0_mem_re && cpu0_mem_addr == 4'hC && !shared_reg_3_valid) ||
        (cpu0_mem_we && cpu0_mem_addr == 4'h4 && cpu0_tx_full);

    cpu_core core0 (
        .clk(clk), .rst_n(rst_n), .run(cpu0_run),
        .pin_state(uio_in[3:0]), .pin_out(cpu0_pin_out), .pin_dir(cpu0_pin_dir),
        .pc_op(cpu0_pc_op), .rom_op_data(cpu0_rom_op_data),
        .pc_op1(cpu0_pc_op1), .rom_op1_data(cpu0_rom_op1_data),
        .pc_op2(cpu0_pc_op2), .rom_op2_data(cpu0_rom_op2_data),
        .jmp_table_addr(cpu0_jmp_addr), .jmp_table_data(cpu0_jmp_data),
        .mem_addr(cpu0_mem_addr), .mem_wdata(cpu0_mem_wdata), .mem_we(cpu0_mem_we), .mem_re(cpu0_mem_re),
        .mem_rdata(cpu0_mem_rdata), .mem_stall(cpu0_mem_stall),
        .shared_valid({shared_reg_3_valid, shared_reg_2_valid, shared_reg_1_valid, shared_reg_0_valid})
    );
    


    // ========================================================
    // CPU 1 SUBSYSTEM
    // ========================================================
    // ROM Instantiation
    wire [3:0] cpu1_rom_op_data;
    wire [3:0] cpu1_rom_op1_data;
    wire [3:0] cpu1_rom_op2_data;
    wire [16:0] cpu1_jmp_data;
    
    rom_cpu1 rom1 (
        .pc_op(cpu1_pc_op), .op_data(cpu1_rom_op_data),
        .pc_op1(cpu1_pc_op1), .op1_data(cpu1_rom_op1_data),
        .pc_op2(cpu1_pc_op2), .op2_data(cpu1_rom_op2_data),
        .jmp_addr(cpu1_jmp_addr), .jmp_data(cpu1_jmp_data)
    );
    wire [6:0] cpu1_pc_op;
    wire [5:0] cpu1_pc_op1;
    wire [3:0] cpu1_pc_op2;
    wire [3:0] cpu1_jmp_addr;
    

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



    wire [7:0] cpu1_timer_rdata; wire cpu1_timer_zero;
    wire cpu1_timer_we_l = (cpu1_mem_addr == 4'h7) && cpu1_mem_we;
    wire cpu1_timer_we_h = (cpu1_mem_addr == 4'h8) && cpu1_mem_we;
    timer tmr1 (.clk(clk), .rst_n(rst_n), .wdata(cpu1_mem_wdata), .we_l(cpu1_timer_we_l), .we_h(cpu1_timer_we_h),
                .rdata_l(cpu1_timer_rdata), .is_zero(cpu1_timer_zero));

    always @(*) begin
        cpu1_mem_rdata = 8'h00;
        if (cpu1_mem_addr == 4'h5) cpu1_mem_rdata = cpu1_rx_empty ? 8'h00 : cpu1_rx_rdata;
        else if (cpu1_mem_addr == 4'h6) cpu1_mem_rdata = {4'b0, uio_in[3:0]};
        else if (cpu1_mem_addr == 4'h7) cpu1_mem_rdata = cpu1_timer_rdata;
        else if (cpu1_mem_addr == 4'h9) cpu1_mem_rdata = shared_reg_0;
        else if (cpu1_mem_addr == 4'hA) cpu1_mem_rdata = shared_reg_1;
        else if (cpu1_mem_addr == 4'hB) cpu1_mem_rdata = shared_reg_2;
        else if (cpu1_mem_addr == 4'hC) cpu1_mem_rdata = shared_reg_3;
    end
    
    assign cpu1_mem_stall = 
        (cpu1_mem_re && cpu1_mem_addr == 4'h5 && cpu1_rx_empty) || 
        (cpu1_mem_re && cpu1_mem_addr == 4'h7 && !cpu1_timer_zero) ||
        (cpu1_mem_re && cpu1_mem_addr == 4'h9 && !shared_reg_0_valid) ||
        (cpu1_mem_re && cpu1_mem_addr == 4'hA && !shared_reg_1_valid) ||
        (cpu1_mem_re && cpu1_mem_addr == 4'hB && !shared_reg_2_valid) ||
        (cpu1_mem_re && cpu1_mem_addr == 4'hC && !shared_reg_3_valid) ||
        (cpu1_mem_we && cpu1_mem_addr == 4'h4 && cpu1_tx_full);

    cpu_core core1 (
        .clk(clk), .rst_n(rst_n), .run(cpu1_run),
        .pin_state(uio_in[3:0]), .pin_out(cpu1_pin_out), .pin_dir(cpu1_pin_dir),
        .pc_op(cpu1_pc_op), .rom_op_data(cpu1_rom_op_data),
        .pc_op1(cpu1_pc_op1), .rom_op1_data(cpu1_rom_op1_data),
        .pc_op2(cpu1_pc_op2), .rom_op2_data(cpu1_rom_op2_data),
        .jmp_table_addr(cpu1_jmp_addr), .jmp_table_data(cpu1_jmp_data),
        .mem_addr(cpu1_mem_addr), .mem_wdata(cpu1_mem_wdata), .mem_we(cpu1_mem_we), .mem_re(cpu1_mem_re),
        .mem_rdata(cpu1_mem_rdata), .mem_stall(cpu1_mem_stall),
        .shared_valid({shared_reg_3_valid, shared_reg_2_valid, shared_reg_1_valid, shared_reg_0_valid})
    );



    // ========================================================
    // CPU 2 SUBSYSTEM
    // ========================================================
    // ROM Instantiation
    wire [3:0] cpu2_rom_op_data;
    wire [3:0] cpu2_rom_op1_data;
    wire [3:0] cpu2_rom_op2_data;
    wire [16:0] cpu2_jmp_data;
    
    rom_cpu2 rom2 (
        .pc_op(cpu2_pc_op), .op_data(cpu2_rom_op_data),
        .pc_op1(cpu2_pc_op1), .op1_data(cpu2_rom_op1_data),
        .pc_op2(cpu2_pc_op2), .op2_data(cpu2_rom_op2_data),
        .jmp_addr(cpu2_jmp_addr), .jmp_data(cpu2_jmp_data)
    );
    wire [6:0] cpu2_pc_op;
    wire [5:0] cpu2_pc_op1;
    wire [3:0] cpu2_pc_op2;
    wire [3:0] cpu2_jmp_addr;
    

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
        if (cpu2_mem_addr == 4'h5) cpu2_mem_rdata = cpu2_rx_empty ? 8'h00 : cpu2_rx_rdata;
        else if (cpu2_mem_addr == 4'h6) cpu2_mem_rdata = {4'b0, uio_in[3:0]};
        else if (cpu2_mem_addr == 4'h7) cpu2_mem_rdata = cpu2_timer_rdata;
        else if (cpu2_mem_addr == 4'h9) cpu2_mem_rdata = shared_reg_0;
        else if (cpu2_mem_addr == 4'hA) cpu2_mem_rdata = shared_reg_1;
        else if (cpu2_mem_addr == 4'hB) cpu2_mem_rdata = shared_reg_2;
        else if (cpu2_mem_addr == 4'hC) cpu2_mem_rdata = shared_reg_3;
    end
    
    assign cpu2_mem_stall = 
        (cpu2_mem_re && cpu2_mem_addr == 4'h5 && cpu2_rx_empty) || 
        (cpu2_mem_re && cpu2_mem_addr == 4'h7 && !cpu2_timer_zero) ||
        (cpu2_mem_re && cpu2_mem_addr == 4'h9 && !shared_reg_0_valid) ||
        (cpu2_mem_re && cpu2_mem_addr == 4'hA && !shared_reg_1_valid) ||
        (cpu2_mem_re && cpu2_mem_addr == 4'hB && !shared_reg_2_valid) ||
        (cpu2_mem_re && cpu2_mem_addr == 4'hC && !shared_reg_3_valid) ||
        (cpu2_mem_we && cpu2_mem_addr == 4'h4 && cpu2_tx_full);

    cpu_core core2 (
        .clk(clk), .rst_n(rst_n), .run(cpu2_run),
        .pin_state(ui_in[3:0]), .pin_out(cpu2_pin_out), .pin_dir(cpu2_pin_dir),
        .pc_op(cpu2_pc_op), .rom_op_data(cpu2_rom_op_data),
        .pc_op1(cpu2_pc_op1), .rom_op1_data(cpu2_rom_op1_data),
        .pc_op2(cpu2_pc_op2), .rom_op2_data(cpu2_rom_op2_data),
        .jmp_table_addr(cpu2_jmp_addr), .jmp_table_data(cpu2_jmp_data),
        .mem_addr(cpu2_mem_addr), .mem_wdata(cpu2_mem_wdata), .mem_we(cpu2_mem_we), .mem_re(cpu2_mem_re),
        .mem_rdata(cpu2_mem_rdata), .mem_stall(cpu2_mem_stall),
        .shared_valid({shared_reg_3_valid, shared_reg_2_valid, shared_reg_1_valid, shared_reg_0_valid})
    );



    // ========================================================
    // CPU 3 SUBSYSTEM
    // ========================================================
    // ROM Instantiation
    wire [3:0] cpu3_rom_op_data;
    wire [3:0] cpu3_rom_op1_data;
    wire [3:0] cpu3_rom_op2_data;
    wire [16:0] cpu3_jmp_data;
    
    rom_cpu3 rom3 (
        .pc_op(cpu3_pc_op), .op_data(cpu3_rom_op_data),
        .pc_op1(cpu3_pc_op1), .op1_data(cpu3_rom_op1_data),
        .pc_op2(cpu3_pc_op2), .op2_data(cpu3_rom_op2_data),
        .jmp_addr(cpu3_jmp_addr), .jmp_data(cpu3_jmp_data)
    );
    wire [6:0] cpu3_pc_op;
    wire [5:0] cpu3_pc_op1;
    wire [3:0] cpu3_pc_op2;
    wire [3:0] cpu3_jmp_addr;
    

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
        if (cpu3_mem_addr == 4'h5) cpu3_mem_rdata = cpu3_rx_empty ? 8'h00 : cpu3_rx_rdata;
        else if (cpu3_mem_addr == 4'h6) cpu3_mem_rdata = {4'b0, uio_in[3:0]};
        else if (cpu3_mem_addr == 4'h7) cpu3_mem_rdata = cpu3_timer_rdata;
        else if (cpu3_mem_addr == 4'h9) cpu3_mem_rdata = shared_reg_0;
        else if (cpu3_mem_addr == 4'hA) cpu3_mem_rdata = shared_reg_1;
        else if (cpu3_mem_addr == 4'hB) cpu3_mem_rdata = shared_reg_2;
        else if (cpu3_mem_addr == 4'hC) cpu3_mem_rdata = shared_reg_3;
    end
    
    assign cpu3_mem_stall = 
        (cpu3_mem_re && cpu3_mem_addr == 4'h5 && cpu3_rx_empty) || 
        (cpu3_mem_re && cpu3_mem_addr == 4'h7 && !cpu3_timer_zero) ||
        (cpu3_mem_re && cpu3_mem_addr == 4'h9 && !shared_reg_0_valid) ||
        (cpu3_mem_re && cpu3_mem_addr == 4'hA && !shared_reg_1_valid) ||
        (cpu3_mem_re && cpu3_mem_addr == 4'hB && !shared_reg_2_valid) ||
        (cpu3_mem_re && cpu3_mem_addr == 4'hC && !shared_reg_3_valid) ||
        (cpu3_mem_we && cpu3_mem_addr == 4'h4 && cpu3_tx_full);

    cpu_core core3 (
        .clk(clk), .rst_n(rst_n), .run(cpu3_run),
        .pin_state(ui_in[7:4]), .pin_out(cpu3_pin_out), .pin_dir(cpu3_pin_dir),
        .pc_op(cpu3_pc_op), .rom_op_data(cpu3_rom_op_data),
        .pc_op1(cpu3_pc_op1), .rom_op1_data(cpu3_rom_op1_data),
        .pc_op2(cpu3_pc_op2), .rom_op2_data(cpu3_rom_op2_data),
        .jmp_table_addr(cpu3_jmp_addr), .jmp_table_data(cpu3_jmp_data),
        .mem_addr(cpu3_mem_addr), .mem_wdata(cpu3_mem_wdata), .mem_we(cpu3_mem_we), .mem_re(cpu3_mem_re),
        .mem_rdata(cpu3_mem_rdata), .mem_stall(cpu3_mem_stall),
        .shared_valid({shared_reg_3_valid, shared_reg_2_valid, shared_reg_1_valid, shared_reg_0_valid})
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
