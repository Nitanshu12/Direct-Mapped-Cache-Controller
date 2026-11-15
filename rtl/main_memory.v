// main_memory.v
// Simple main-memory model used with the cache.
//  - 256 blocks of 128 bits (4 KB). Only block_address[7:0] is used.
//  - Write: data is stored at the clock edge and mem_ready is asserted.
//  - Read: data is captured at the clock edge. mem_ready is asserted
//    after READ_LATENCY clock cycles.

`ifndef MEM_READ_LATENCY
`define MEM_READ_LATENCY 1
`endif

module main_memory #(
    parameter READ_LATENCY = `MEM_READ_LATENCY
) (
    input wire clk,
    input wire [27:0] block_address,
    input wire read_enable,
    input wire write_enable,
    input wire [127:0] write_data,
    output reg [127:0] read_data,
    output reg mem_ready
);

    reg [127:0] memory [0:255];
    integer i;

    reg read_pending;
    reg [7:0] wait_count;

    initial begin
        for (i = 0; i < 256; i = i + 1) begin
            memory[i] = 128'h0;
        end

        mem_ready = 0;
        read_data = 128'h0;
        read_pending = 0;
        wait_count = 0;
    end

    always @(posedge clk) begin
        mem_ready <= 0;

        if (write_enable) begin
            memory[block_address[7:0]] <= write_data;
            mem_ready <= 1;
        end

        if (read_enable) begin
            read_data <= memory[block_address[7:0]];

            if (READ_LATENCY <= 1)
                mem_ready <= 1;
            else begin
                read_pending <= 1;
                wait_count <= READ_LATENCY - 1;
            end
        end
        else if (read_pending) begin
            if (wait_count == 1) begin
                read_pending <= 0;
                mem_ready <= 1;
            end

            wait_count <= wait_count - 1;
        end
    end

endmodule