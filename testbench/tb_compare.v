`timescale 1ns/1ps

// Compares the cache design (cache_top) with the baseline without cache
// (nocache_top) on exactly the same 72 read requests:
//   16 sequential + 6 conflict + 50 random reads inside 1 KB.
// The main-memory read latency is set at compile time with -DMEM_READ_LATENCY=N.

`ifndef MEM_READ_LATENCY
`define MEM_READ_LATENCY 1
`endif

module tb_compare;

    reg clk;
    reg reset;

    // cache design
    reg c_req;
    reg [31:0] c_addr;
    wire [127:0] c_rdata;
    wire c_ready;
    wire c_miss;

    // baseline design (no cache)
    reg n_req;
    reg [31:0] n_addr;
    wire [127:0] n_rdata;
    wire n_ready;

    integer i;
    integer cycles;
    integer cache_total;
    integer nocache_total;
    integer cache_misses;
    reg [31:0] addr_list [0:71];
    reg [31:0] r;
    reg saw_miss;
    reg done;

    cache_top cache_dut (
        .clk(clk), .reset(reset), .cpu_req(c_req), .cpu_write(1'b0),
        .cpu_address(c_addr), .cpu_write_data(128'h0),
        .cpu_read_data(c_rdata), .cpu_ready(c_ready), .cache_miss(c_miss)
    );

    nocache_top base_dut (
        .clk(clk), .reset(reset), .cpu_req(n_req), .cpu_write(1'b0),
        .cpu_address(n_addr), .cpu_write_data(128'h0),
        .cpu_read_data(n_rdata), .cpu_ready(n_ready)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // one read through the cache design; adds its cycles to cache_total
    task cache_read;
        input [31:0] address;
        begin
            @(negedge clk);
            c_req = 1; c_addr = address;
            done = 0; saw_miss = 0;
            for (cycles = 0; cycles < 200 && !done; cycles = cycles + 1) begin
                @(posedge clk); #1;
                if (c_miss) saw_miss = 1;
                if (c_ready) done = 1;
            end
            cache_total = cache_total + cycles;
            if (saw_miss) cache_misses = cache_misses + 1;
            @(negedge clk);
            c_req = 0;
            repeat (2) @(negedge clk);
        end
    endtask

    // one read through the baseline; adds its cycles to nocache_total
    task nocache_read;
        input [31:0] address;
        begin
            @(negedge clk);
            n_req = 1; n_addr = address;
            done = 0;
            for (cycles = 0; cycles < 200 && !done; cycles = cycles + 1) begin
                @(posedge clk); #1;
                if (n_ready) done = 1;
            end
            nocache_total = nocache_total + cycles;
            @(negedge clk);
            n_req = 0;
            repeat (2) @(negedge clk);
        end
    endtask

    initial begin
        reset = 1; c_req = 0; n_req = 0; c_addr = 0; n_addr = 0;
        cache_total = 0; nocache_total = 0; cache_misses = 0;

        // build the request list
        for (i = 0; i < 16; i = i + 1)
            addr_list[i] = 32'h00000100 + (i * 4);
        for (i = 0; i < 6; i = i + 1)
            addr_list[16 + i] = (i % 2 == 0) ? 32'h00000030 : 32'h00000430;
        for (i = 0; i < 50; i = i + 1) begin
            r = $random;
            addr_list[22 + i] = r & 32'h000003F0;
        end

        repeat (2) @(negedge clk);
        reset = 0;
        repeat (2) @(negedge clk);

        for (i = 0; i < 72; i = i + 1) cache_read(addr_list[i]);
        for (i = 0; i < 72; i = i + 1) nocache_read(addr_list[i]);

        $display("MEM_READ_LATENCY = %0d", `MEM_READ_LATENCY);
        $display("Requests                  = 72 reads");
        $display("Cache design:   misses = %0d, total cycles = %0d, average = %f", cache_misses, cache_total, cache_total / 72.0);
        $display("No-cache design:            total cycles = %0d, average = %f", nocache_total, nocache_total / 72.0);
        $display("Speed-up (no-cache / cache) = %f", (nocache_total * 1.0) / cache_total);
        if (cache_total < nocache_total) $display("RESULT: cache is faster");
        else $display("RESULT: no-cache is faster");
        $finish;
    end

endmodule
