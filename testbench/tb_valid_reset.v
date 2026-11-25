`timescale 1ns/1ps

module tb_valid_reset;

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
    reg saw_miss;

    cache_top uut (
        .clk(clk), .reset(reset), .cpu_req(cpu_req), .cpu_write(cpu_write),
        .cpu_address(cpu_address), .cpu_write_data(cpu_write_data),
        .cpu_read_data(cpu_read_data), .cpu_ready(cpu_ready), .cache_miss(cache_miss)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task send_read;
        input [31:0] address;
        integer cycles;
        reg completed;
        begin
            @(negedge clk);
            cpu_req = 1; cpu_write = 0; cpu_address = address; cpu_write_data = 0;
            completed = 0; saw_miss = 0;
            for (cycles = 0; cycles < 30 && !completed; cycles = cycles + 1) begin
                @(posedge clk); #1;
                if (cache_miss) saw_miss = 1;
                if (cpu_ready) completed = 1;
            end
            @(negedge clk);
            cpu_req = 0;
            if (!completed) begin
                $display("ERROR: timeout at %h", address);
                errors = errors + 1;
            end
            repeat (2) @(negedge clk);
        end
    endtask

    task expect_miss;
        begin
            if (saw_miss) $display("PASS: miss, as expected");
            else begin $display("FAIL: expected a miss"); errors = errors + 1; end
        end
    endtask

    task expect_hit;
        begin
            if (!saw_miss) $display("PASS: hit, as expected");
            else begin $display("FAIL: expected a hit"); errors = errors + 1; end
        end
    endtask

    // Apply a reset pulse of 'n' clock cycles in the middle of the run
    task pulse_reset;
        input integer n;
        begin
            @(negedge clk);
            reset = 1;
            repeat (n) @(negedge clk);
            reset = 0;
            repeat (2) @(negedge clk);
        end
    endtask

    initial begin
        errors = 0;
        reset = 1; cpu_req = 0; cpu_write = 0; cpu_address = 0; cpu_write_data = 0;
        repeat (2) @(negedge clk);
        reset = 0;
        repeat (2) @(negedge clk);

        $display("--- Valid-bit reset test ---");

        $display("\nBefore reset: fill three lines (index 1, 20, 63)");
        send_read(32'h00000010); expect_miss;
        send_read(32'h00000140); expect_miss;
        send_read(32'h000003F0); expect_miss;

        $display("\nThey must hit now");
        send_read(32'h00000010); expect_hit;
        send_read(32'h00000140); expect_hit;
        send_read(32'h000003F0); expect_hit;

        $display("\nReset in the middle of the run (2 clock cycles)");
        pulse_reset(2);

        $display("\nAfter reset: the same addresses must MISS (valid bits cleared)");
        send_read(32'h00000010); expect_miss;
        send_read(32'h00000140); expect_miss;
        send_read(32'h000003F0); expect_miss;

        $display("\nAnd hit again after being refilled");
        send_read(32'h00000010); expect_hit;
        send_read(32'h00000140); expect_hit;
        send_read(32'h000003F0); expect_hit;

        if (errors == 0) $display("\nALL VALID-RESET TESTS PASSED");
        else $display("\n%0d VALID-RESET TESTS FAILED", errors);
        $finish;
    end

endmodule
