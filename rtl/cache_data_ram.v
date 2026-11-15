// cache_data_ram.v
// Data storage of the direct-mapped cache: 64 lines, each holding one
// 128-bit (16-byte) block. The line is selected by the 6-bit index.
//  - Write: when write_enable = 1 the block is stored at the clock edge
//    and the same data also appears on read_data.
//  - Read: read_data is registered, so the block for a new index appears
//    one clock cycle after the index is applied. The cache controller
//    waits for this in its LOOKUP state.
//  - The memory has no initial values: a line that was never written
//    returns unknown (x). This is safe because the valid bit stops the
//    cache from using such a line.
module cache_data_ram (
    input wire clk,                 // clock
    input wire [5:0] index,         // cache line number (0..63)
    input wire [127:0] write_data,  // block to store
    input wire write_enable,        // 1 = store write_data at this clock edge
    output reg [127:0] read_data    // block read from the selected line
);

    reg [127:0] data_mem [0:63];

    always @(posedge clk) begin
        if (write_enable) begin
            data_mem[index] <= write_data;
            read_data <= write_data;
        end
        else begin
            read_data <= data_mem[index];
        end
    end

endmodule