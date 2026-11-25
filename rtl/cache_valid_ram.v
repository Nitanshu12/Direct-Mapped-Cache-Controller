// Cache Valid RAM:
// Stores one valid bit for each of the 64 cache lines.
// All valid bits are initialized to 0 at start-up. A reset clears all valid
// bits again, so the cache is empty after every reset. Read and write
// operations take place on the rising edge of the clock.
//
// Inputs:
// clk          - Clock signal.
// reset        - 1 = clear all 64 valid bits at the next clock edge.
// index [5:0]  - Selects one of the 64 cache lines.
// write_valid  - Valid bit value to be stored (0 or 1).
// write_enable - Enables writing into the selected valid entry.
//
// Output:
// read_valid   - Valid bit read from the selected cache line (it appears
//                one clock cycle after the index is applied).

module cache_valid_ram (
    input wire clk,
    input wire reset,
    input wire [5:0] index,
    input wire write_valid,
    input wire write_enable,
    output reg read_valid
);

    reg valid_mem [0:63];

    integer i;

    // start-up value (simulation and FPGA initial state)
    initial begin
        for (i = 0; i < 64; i = i + 1) begin
            valid_mem[i] = 1'b0;
        end
        read_valid = 1'b0;
    end

    always @(posedge clk) begin
        if (reset) begin
            for (i = 0; i < 64; i = i + 1) begin
                valid_mem[i] <= 1'b0;
            end
            read_valid <= 1'b0;
        end
        else begin
            if (write_enable) begin
                valid_mem[index] <= write_valid;
            end

            read_valid <= valid_mem[index];
        end
    end

endmodule
