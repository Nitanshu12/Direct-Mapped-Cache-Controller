`timescale 1ns/1ps

// Trace-driven testbench: reads a trace file and sends every request to the cache.
// Usage:  vvp sim +trace=traces/sequential.hex +n=64 +name=sequential
//   +trace  trace file (see scripts/gen_traces.py)
//   +n      number of requests in the file
//   +name   name printed in the result line
module tb_trace;

    reg clk;
    reg reset;
    reg cpu_req;
    reg cpu_write;
    reg [31:0] cpu_address;
    reg [127:0] cpu_write_data;

    wire [127:0] cpu_read_data;
    wire cpu_ready;
    wire cache_miss;

    reg [35:0] trace [0:4095];
    reg [8*100-1:0] trace_file;
    reg [8*40-1:0] trace_name;
    integer n;
    integer i;
    integer cycles;
    integer reads, read_hits, read_misses;
    integer writes;
    integer total_cycles;
    reg completed;
    reg saw_miss;
    reg is_write;
    reg [31:0] addr;
    real hit_rate, amat;
    integer hit_cycles, miss_cycles;

    cache_top uut (
        .clk(clk), .reset(reset), .cpu_req(cpu_req), .cpu_write(cpu_write),
        .cpu_address(cpu_address), .cpu_write_data(cpu_write_data),
        .cpu_read_data(cpu_read_data), .cpu_ready(cpu_ready), .cache_miss(cache_miss)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        if (!$value$plusargs("trace=%s", trace_file)) begin
            $display("ERROR: use +trace=<file> +n=<requests> +name=<name>");
            $finish;
        end
        if (!$value$plusargs("n=%d", n)) n = 0;
        if (!$value$plusargs("name=%s", trace_name)) trace_name = "trace";

        $readmemh(trace_file, trace);

        reads = 0; read_hits = 0; read_misses = 0; writes = 0; total_cycles = 0;
        hit_cycles = 4; miss_cycles = 7;

        reset = 1; cpu_req = 0; cpu_write = 0; cpu_address = 0; cpu_write_data = 0;
        repeat (2) @(negedge clk);
        reset = 0;
        repeat (2) @(negedge clk);

        for (i = 0; i < n; i = i + 1) begin
            is_write = trace[i][32];
            addr = trace[i][31:0];

            @(negedge clk);
            cpu_req = 1;
            cpu_write = is_write;
            cpu_address = addr;
            cpu_write_data = {addr, addr, addr, addr};

            completed = 0;
            saw_miss = 0;
            for (cycles = 0; cycles < 100 && !completed; cycles = cycles + 1) begin
                @(posedge clk);
                #1;
                if (cache_miss) saw_miss = 1;
                if (cpu_ready) completed = 1;
            end
            total_cycles = total_cycles + cycles;

            @(negedge clk);
            cpu_req = 0;
            cpu_write = 0;

            if (is_write) writes = writes + 1;
            else begin
                reads = reads + 1;
                if (saw_miss) begin read_misses = read_misses + 1; miss_cycles = cycles; end
                else begin read_hits = read_hits + 1; hit_cycles = cycles; end
            end
            repeat (2) @(negedge clk);
        end

        hit_rate = (reads == 0) ? 0.0 : (read_hits * 100.0) / reads;
        amat = (reads == 0) ? 0.0 : (hit_cycles + ((read_misses * 1.0) / reads) * (miss_cycles - hit_cycles));

        $display("RESULT,%0s,%0d,%0d,%0d,%0d,%f,%f", trace_name, n, reads, writes, read_hits, hit_rate, amat);
        $finish;
    end

endmodule
