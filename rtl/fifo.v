`default_nettype none

module fifo #(
    parameter DEPTH = 8
)(
    input  wire       clk,
    input  wire       rst_n,
    
    input  wire [7:0] wdata,
    input  wire       we,
    
    output wire [7:0] rdata,
    input  wire       re,
    
    output wire       empty,
    output wire       full
);

    reg [7:0] mem [0:DEPTH-1];
    reg [3:0] wptr;
    reg [3:0] rptr;
    reg [4:0] count;
    
    assign empty = (count == 0);
    assign full  = (count == DEPTH);
    
    assign rdata = mem[rptr[2:0]];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wptr <= 0;
            rptr <= 0;
            count <= 0;
        end else begin
            case ({we && !full, re && !empty})
                2'b10: begin // Write only
                    mem[wptr[2:0]] <= wdata;
                    wptr <= wptr + 1;
                    count <= count + 1;
                end
                2'b01: begin // Read only
                    rptr <= rptr + 1;
                    count <= count - 1;
                end
                2'b11: begin // Both (passthrough counter)
                    mem[wptr[2:0]] <= wdata;
                    wptr <= wptr + 1;
                    rptr <= rptr + 1;
                end
            endcase
        end
    end
endmodule
