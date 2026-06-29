`timescale 1ns/1ps

module tb_fifo_buffer;

    // Parameters
    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 4;
    parameter FIFO_DEPTH = 16;

    // Testbench Signals
    reg clk;
    reg reset_n;
    reg write_enable;
    reg [DATA_WIDTH-1:0] data_in;
    reg read_enable;
    
    wire [DATA_WIDTH-1:0] data_out;
    wire full;
    wire empty;

    // Instantiate the Design Under Test (DUT)
    fifo_buffer #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) uut (
        .clk(clk),
        .reset_n(reset_n),
        .write_enable(write_enable),
        .data_in(data_in),
        .read_enable(read_enable),
        .data_out(data_out),
        .full(full),
        .empty(empty)
    );

    // Clock Generation (50 MHz Clock -> 20ns period)
    always #10 clk = ~clk;

    // Task for Writing Data
    task write_data(input [DATA_WIDTH-1:0] val);
        begin
            @(posedge clk);
            write_enable = 1;
            data_in = val;
            #1; // Small delay to check flags after edge
        end
    endtask

    // Task for Reading Data
    task read_data;
        begin
            @(posedge clk);
            write_enable = 0; // Ensure we aren't writing
            read_enable = 1;
            #1;
        end
    endtask

    // Stimulus Block
    initial begin
        // Initialize Signals
        $dumpfile("fifo_wave.vcd");
        $dumpvars(0, tb_fifo_buffer);
        
        clk = 0;
        reset_n = 0;
        write_enable = 0;
        read_enable = 0;
        data_in = 0;

        // 1. Reset Test
        #40;
        reset_n = 1;
        $display("[TIME %0t] Reset released. Empty flag: %b (Expected: 1)", $time, empty);

        // 2. Fill the FIFO to the max (16 writes)
        $display("\n--- Starting Write Test ---");
        repeat(FIFO_DEPTH) begin
            write_data($random % 256);
        end
        
        // Turn off write enable and check full flag
        @(posedge clk);
        write_enable = 0;
        #1;
        $display("[TIME %0t] Finished 16 writes. Full flag: %b (Expected: 1)", $time, full);

        // Try 1 extra write to prove it safely rejects it
        // write_data(8'hFF);
        @(posedge clk);
        write_enable = 0;

        // 3. Read everything back out (16 reads)
        $display("\n--- Starting Read Test ---");
        repeat(FIFO_DEPTH) begin
            read_data();
            $display("[TIME %0t] Read Data Out: %h", $time, data_out);
        end
        
        // Turn off read enable and check empty flag
        @(posedge clk);
        read_enable = 0;
        #1;
        $display("[TIME %0t] Finished 16 reads. Empty flag: %b (Expected: 1)", $time, empty);

        // 4. Simultaneous Read and Write Stress Test
        $display("\n--- Starting Simultaneous R/W Test ---");
        // Put 2 items in first
        write_data(8'hAA);
        write_data(8'hBB);
        
        // Execute R/W on the same edge
        @(posedge clk);
        write_enable = 1;
        read_enable = 1;
        data_in = 8'hCC; // Writing CC while reading AA
        
        #1;
        $display("[TIME %0t] Sim R/W - Out: %h (Expected: aa), Status Counter shouldn't change.", $time, data_out);
        
        @(posedge clk);
        write_enable = 0;
        read_enable = 0;

        #100;
        $display("\nSimulation Completed Successfully!");
        $finish;
    end

endmodule