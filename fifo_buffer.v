module fifo_buffer #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4,
    parameter FIFO_DEPTH = 16
) (
    input clk, reset_n,
    input write_enable,
    input [DATA_WIDTH-1:0] data_in,
    input read_enable,
    output reg [DATA_WIDTH-1:0] data_out,
    output full, empty
);

reg [DATA_WIDTH-1:0] mem_arr [0:FIFO_DEPTH-1] ;
reg [ADDR_WIDTH-1:0] write_ptr, read_ptr ;
reg [ADDR_WIDTH:0] status ; // To know how many items are there in FIFO buffer
    
always @(posedge clk) begin
    if (!reset_n) begin
        write_ptr <= 0 ;
        read_ptr <= 0 ;
        status <= 0 ;
    end else begin
        if (write_enable) begin
            if (!full) begin
                mem_arr[write_ptr] <= data_in ;
                write_ptr <= write_ptr + 1'b1 ;
            end
        end
        if (read_enable) begin
            if (!empty) begin
                data_out <= mem_arr[read_ptr] ;
                read_ptr <= read_ptr + 1'b1 ;
            end else begin
                data_out <= {DATA_WIDTH{1'b1}} ;
            end
        end
        case ({(write_enable && !full), (read_enable && !empty)})
        2'b01 : status <= status - 1 ;
        2'b10 : status <= status + 1 ;
            default: status <= status ;
        endcase
    end
end

assign full  = (status == FIFO_DEPTH) ;
assign empty = (status == 0) ;

endmodule
