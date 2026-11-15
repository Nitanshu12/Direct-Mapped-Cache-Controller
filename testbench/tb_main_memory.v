`timescale 1ns/1ps

`ifndef MEM_READ_LATENCY
`define MEM_READ_LATENCY 1
`endif

module tb_main_memory;

    reg clk;
    reg [27:0] block_address;
    reg read_enable;
    reg write_enable;
    reg [127:0] write_data;
    wire [127:0] read_data;
    wire mem_ready;

    integer errors;
    integer cycles;

    localparam [127:0] V1 = 128'h0123456789ABCDEF0123456789ABCDEF;
    localparam [127:0] V2 = 128'hFEDCBA9876543210FEDCBA9876543210;

    main_memory memory (
        .clk(clk),
        .block_address(block_address),
        .read_enable(read_enable),
        .write_enable(write_enable),
        .write_data(write_data),
        .read_data(read_data),
        .mem_ready(mem_ready)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // Read one block (one-cycle read_enable pulse) and count the clock
    // cycles until mem_ready goes high
    task do_read;
        input [27:0] addr;
        begin
            @(negedge clk);
            block_address = addr;
            read_enable = 1;
            @(posedge clk);
            #1;
            read_enable = 0;
            cycles = 1;
            while (!mem_ready && cycles < 50) begin
                @(posedge clk);
                #1;
                cycles = cycles + 1;
            end
        end
    endtask

    task check_read;
        input [27:0] addr;
        input [127:0] expected;
        begin
            do_read(addr);
            if (read_data === expected)
                $display("PASS: block %h = %h (mem_ready after %0d cycle(s))",
                         addr, read_data, cycles);
            else begin
                $display("FAIL: block %h = %h, expected %h", addr, read_data, expected);
                errors = errors + 1;
            end
        end
    endtask

    task do_write;
        input [27:0] addr;
        input [127:0] data;
        begin
            @(negedge clk);
            block_address = addr;
            write_data = data;
            write_enable = 1;
            @(posedge clk);
            #1;
            write_enable = 0;
            if (mem_ready === 1'b1)
                $display("PASS: write to block %h, mem_ready high in the next cycle", addr);
            else begin
                $display("FAIL: mem_ready not high after write to block %h", addr);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        block_address = 0;
        read_enable = 0;
        write_enable = 0;
        write_data = 0;
        repeat (2) @(negedge clk);

        $display("--- Main memory tests (READ_LATENCY = %0d) ---", `MEM_READ_LATENCY);

        // 1. Memory starts with zeros
        check_read(28'h0000000, 128'h0);
        check_read(28'h0000005, 128'h0);

        // 2. Write and read back
        do_write(28'h0000005, V1);
        check_read(28'h0000005, V1);

        // 3. Another block must not disturb block 5
        do_write(28'h000000A, V2);
        check_read(28'h0000005, V1);
        check_read(28'h000000A, V2);

        // 4. Only block_address[7:0] is used: block 0x105 is the same as 0x005
        check_read(28'h0000105, V1);

        // 5. Read latency must be equal to READ_LATENCY
        do_read(28'h0000005);
        if (cycles == `MEM_READ_LATENCY)
            $display("PASS: measured read latency = %0d cycles", cycles);
        else begin
            $display("FAIL: measured read latency = %0d, expected %0d", cycles, `MEM_READ_LATENCY);
            errors = errors + 1;
        end

        if (errors == 0)
            $display("ALL MAIN MEMORY TESTS PASSED");
        else
            $display("%0d MAIN MEMORY TESTS FAILED", errors);
        $finish;
    end

endmodule