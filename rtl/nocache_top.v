// nocache_top.v
// BASELINE design for the comparison: the CPU talks directly to main memory,
// there is no cache. Every request goes to memory.
// FSM: IDLE -> ACCESS (start read/write) -> WAIT (wait for mem_ready) -> DONE (cpu_ready)
module nocache_top (
    input wire clk,
    input wire reset,
    input wire cpu_req,
    input wire cpu_write,
    input wire [31:0] cpu_address,
    input wire [127:0] cpu_write_data,
    output wire [127:0] cpu_read_data,
    output wire cpu_ready
);

    localparam IDLE = 2'd0, ACCESS = 2'd1, WAIT = 2'd2, DONE = 2'd3;

    reg [1:0] state, next_state;
    wire mem_ready;
    wire mem_read_en  = (state == ACCESS) && !cpu_write;
    wire mem_write_en = (state == ACCESS) &&  cpu_write;

    assign cpu_ready = (state == DONE);

    always @(posedge clk or posedge reset) begin
        if (reset) state <= IDLE;
        else state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE:   if (cpu_req) next_state = ACCESS;
            ACCESS: next_state = WAIT;
            WAIT:   if (mem_ready) next_state = DONE;
            DONE:   next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    main_memory memory (
        .clk(clk),
        .block_address(cpu_address[31:4]),
        .read_enable(mem_read_en),
        .write_enable(mem_write_en),
        .write_data(cpu_write_data),
        .read_data(cpu_read_data),
        .mem_ready(mem_ready)
    );

endmodule
