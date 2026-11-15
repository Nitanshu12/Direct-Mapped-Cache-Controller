`timescale 1ns/1ps

module tb_data_ram;

    reg clk;
    reg [5:0] index;
    reg [127:0] write_data;
    reg write_enable;
    wire [127:0] read_data;

    integer errors;

    localparam [127:0] A = 128'h0123456789ABCDEF0123456789ABCDEF;
    localparam [127:0] B = 128'hFEDCBA9876543210FEDCBA9876543210;
    localparam [127:0] C = 128'hAAAAAAAA11111111BBBBBBBB22222222;
    localparam [127:0] D = 128'h11111111222222223333333344444444;
    localparam [127:0] E = 128'hDEADBEEFDEADBEEFDEADBEEFDEADBEEF;
    localparam [127:0] F = 128'hCAFEBABECAFEBABECAFEBABECAFEBABE;
    localparam [127:0] G = 128'h55555555AAAAAAAA5555555500000000;

    cache_data_ram data_ram (
        .clk(clk),
        .index(index),
        .write_data(write_data),
        .write_enable(write_enable),
        .read_data(read_data)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    // Write one block (en = 0 means the write must be ignored)
    task write_block;
        input [5:0] idx;
        input [127:0] data;
        input en;
        begin
            @(negedge clk);
            index = idx;
            write_data = data;
            write_enable = en;
            @(negedge clk);
            write_enable = 0;
        end
    endtask

    // Read one block: the data appears one clock edge after the index
    task read_check;
        input [5:0] idx;
        input [127:0] expected;
        begin
            @(negedge clk);
            index = idx;
            write_enable = 0;
            @(posedge clk);
            #1;
            if (read_data === expected)
                $display("PASS: line %0d = %h", idx, read_data);
            else begin
                $display("FAIL: line %0d = %h, expected %h", idx, read_data, expected);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        index = 0;
        write_data = 0;
        write_enable = 0;
        repeat (2) @(negedge clk);

        $display("--- Data RAM tests ---");

        // 1. Write and read back
        write_block(6'd3, A, 1'b1);
        read_check(6'd3, A);

        // 2. A second line must not disturb the first one
        write_block(6'd4, B, 1'b1);
        read_check(6'd4, B);
        read_check(6'd3, A);

        // 3. write_enable = 0: data must NOT change
        write_block(6'd3, C, 1'b0);
        read_check(6'd3, A);

        // 4. Overwrite an existing line
        write_block(6'd3, D, 1'b1);
        read_check(6'd3, D);

        // 5. First and last line
        write_block(6'd0, E, 1'b1);
        write_block(6'd63, F, 1'b1);
        read_check(6'd0, E);
        read_check(6'd63, F);
        read_check(6'd3, D);

        // 6. During a write the new data also appears on read_data
        @(negedge clk);
        index = 6'd10;
        write_data = G;
        write_enable = 1;
        @(posedge clk);
        #1;
        if (read_data === G)
            $display("PASS: write data visible on read_data at the same edge");
        else begin
            $display("FAIL: read_data = %h after write, expected %h", read_data, G);
            errors = errors + 1;
        end
        @(negedge clk);
        write_enable = 0;

        if (errors == 0)
            $display("ALL DATA RAM TESTS PASSED");
        else
            $display("%0d DATA RAM TESTS FAILED", errors);
        $finish;
    end

endmodule