`default_nettype none

module timer (
    input  wire       clk,
    input  wire       rst_n,
    
    input  wire [7:0] wdata,
    input  wire       we_l,   // Write to TIMER_L (0x7)
    input  wire       we_h,   // Write to TIMER_H (0x8)
    
    output wire [7:0] rdata_l,
    output wire       is_zero
);

    reg [15:0] count;
    reg        running;
    
    assign rdata_l = count[7:0];
    assign is_zero = (count == 0);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 0;
            running <= 0;
        end else begin
            if (we_h) begin
                count[15:8] <= wdata;
                running <= 1; // Explicit start
            end 
            else if (we_l) begin
                count[7:0] <= wdata;
                count[15:8] <= 8'h00; // Auto-clear upper bits for 8-bit delays
                running <= 1; // Auto-start for 8-bit delays
            end 
            else if (running && count > 0) begin
                count <= count - 1;
            end 
            else if (count == 0) begin
                running <= 0;
            end
        end
    end
endmodule
