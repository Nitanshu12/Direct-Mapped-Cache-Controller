
`timescale 1ns/1ps

module tb_corner_cases;

    reg clk;
    reg reset;
    reg cpu_req;
    reg cpu_write;
    reg [31:0] cpu_address;
    reg [127:0] cpu_write_data;

    wire [127:0] cpu_read_data;
    wire cpu_ready;
    wire cache_miss;

    integer errors;
    integer passes;
    integer last_latency;
    reg saw_miss;
    reg [127:0] got_data;

    localparam [127:0] W1 = 128'hC0FFEE00C0FFEE00C0FFEE00C0FFEE11;
    localparam [127:0] W2 = 128'h0123456789ABCDEFFEDCBA9876543210;

    cache_top uut (
        .clk(clk),
        .reset(reset),
        .cpu_req(cpu_req),
        .cpu_write(cpu_write),
        .cpu_address(cpu_address),
        .cpu_write_data(cpu_write_data),
        .cpu_read_data(cpu_read_data),
        .cpu_ready(cpu_ready),
        .cache_miss(cache_miss)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task send_request;
        input write_operation;
        input [31:0] address;
        input [127:0] write_data;

        integer cycles;
        reg completed;

        begin
            @(negedge clk);
            cpu_req = 1;
            cpu_write = write_operation;
            cpu_address = address;
            cpu_write_data = write_data;

            completed = 0;
            saw_miss = 0;

            for (cycles = 0; cycles < 30 && !completed; cycles = cycles + 1) begin
                @(posedge clk);
                #1;
                if (cache_miss)
                    saw_miss = 1;
                if (cpu_ready)
                    completed = 1;
            end

            last_latency = cycles;

            @(negedge clk);
            got_data = cpu_read_data;
            cpu_req = 0;
            cpu_write = 0;

            if (!completed) begin
                $display("ERROR: request timed out at address %h", address);
                errors = errors + 1;
            end

            repeat (2) @(negedge clk);
        end
    endtask

    task expect_miss;
        begin
            if (saw_miss === 1'b1) begin
                $display("PASS: miss, as expected (%0d cycles)", last_latency);
                passes = passes + 1;
            end
            else begin
                $display("FAIL: expected a MISS but got a HIT");
                errors = errors + 1;
            end
        end
    endtask

    task expect_hit;
        begin
            if (saw_miss === 1'b0) begin
                $display("PASS: hit, as expected (%0d cycles)", last_latency);
                passes = passes + 1;
            end
            else begin
                $display("FAIL: expected a HIT but got a MISS");
                errors = errors + 1;
            end
        end
    endtask

    task expect_data;
        input [127:0] expected;
        begin
            if (got_data === expected) begin
                $display("PASS: data = %h", got_data);
                passes = passes + 1;
            end
            else begin
                $display("FAIL: data = %h, expected %h", got_data, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        passes = 0;
        last_latency = 0;
        saw_miss = 0;
        got_data = 0;

        reset = 1;
        cpu_req = 0;
        cpu_write = 0;
        cpu_address = 0;
        cpu_write_data = 0;

        repeat (2) @(negedge clk);
        reset = 0;

        $display("--------------------------------");
        $display("CORNER CASE TESTS START");
        $display("--------------------------------");

        // A: First line and last line
        $display("\nTEST A: first line (0x000) and last line (0x3F0)");
        send_request(0, 32'h00000000, 128'h0); expect_miss; expect_data(128'h0);
        send_request(0, 32'h00000000, 128'h0); expect_hit;
        send_request(0, 32'h000003F0, 128'h0); expect_miss;
        send_request(0, 32'h000003F0, 128'h0); expect_hit;
        send_request(0, 32'h00000000, 128'h0); expect_hit;

        // B: Same index, different tag
        $display("\nTEST B: conflict on index 20 (0x140 and 0x540): A, B, A, A");
        send_request(0, 32'h00000140, 128'h0); expect_miss;
        send_request(0, 32'h00000540, 128'h0); expect_miss;
        send_request(0, 32'h00000140, 128'h0); expect_miss;
        send_request(0, 32'h00000140, 128'h0); expect_hit;

        // B2: Conflict on the last line
        $display("\nTEST B2: conflict on the last line (0x7F0 and 0x3F0)");
        send_request(0, 32'h000007F0, 128'h0); expect_miss;
        send_request(0, 32'h000003F0, 128'h0); expect_miss;

        // C: Write-through
        $display("\nTEST C: write-through (0x0A0 and 0x4A0 share index 10)");
        send_request(0, 32'h000000A0, 128'h0); expect_miss;
        send_request(1, 32'h000000A0, W1); expect_hit;
        send_request(0, 32'h000000A0, 128'h0); expect_hit; expect_data(W1);
        send_request(0, 32'h000004A0, 128'h0); expect_miss;
        send_request(0, 32'h000000A0, 128'h0); expect_miss; expect_data(W1);

        // D: Write miss does not allocate
        $display("\nTEST D: write miss, no write allocate (0x1C0)");
        send_request(1, 32'h000001C0, W2); expect_miss;
        send_request(0, 32'h000001C0, 128'h0); expect_miss; expect_data(W2);
        send_request(0, 32'h000001C0, 128'h0); expect_hit; expect_data(W2);

        // E: Largest tag
        $display("\nTEST E: all-ones tag (0xFFFFFFF0)");
        send_request(0, 32'hFFFFFFF0, 128'h0); expect_miss;
        send_request(0, 32'hFFFFFFF0, 128'h0); expect_hit;
        send_request(0, 32'h000003F0, 128'h0); expect_miss;
        send_request(0, 32'hFFFFFFF0, 128'h0); expect_miss;

        // G: Offsets inside one block
        $display("\nTEST G: offsets inside a block (0x2A0, 0x2AF, then next block 0x2B0)");
        send_request(0, 32'h000002A0, 128'h0); expect_miss;
        send_request(0, 32'h000002AF, 128'h0); expect_hit;
        send_request(0, 32'h000002B0, 128'h0); expect_miss;

        $display("\n--------------------------------");
        $display("CORNER CASE SUMMARY");
        $display("Checks passed = %0d, failed = %0d", passes, errors);

        if (errors == 0)
            $display("ALL CORNER CASE TESTS PASSED");
        else
            $display("SOME CORNER CASE TESTS FAILED");

        $display("--------------------------------");
        $finish;
    end

endmodule
