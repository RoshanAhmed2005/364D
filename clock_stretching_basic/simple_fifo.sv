// Single-clock FIFO with valid/ready transfers and a visible fill level.
module simple_fifo #(
    parameter int WIDTH = 32,
    parameter int DEPTH = 16,
    parameter int COUNT_BITS = $clog2(DEPTH+1)
) (
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic [WIDTH-1:0]      in_data,
    input  logic                  in_valid,
    output logic                  in_ready,
    output logic [WIDTH-1:0]      out_data,
    output logic                  out_valid,
    input  logic                  out_ready,
    output logic                  full,
    output logic                  empty,
    output logic [COUNT_BITS-1:0] level
);
    localparam int PTR_BITS = (DEPTH > 1) ? $clog2(DEPTH) : 1;
    logic [WIDTH-1:0] memory [0:DEPTH-1];
    logic [PTR_BITS-1:0] write_pointer, read_pointer;
    logic push, pop;

    assign full = (level == DEPTH);
    assign empty = (level == 0);
    assign out_valid = rst_n && !empty;
    // A read frees a full FIFO entry on the same clock edge.
    assign in_ready = rst_n && (!full || (out_valid && out_ready));
    assign push = in_valid && in_ready;
    assign pop = out_valid && out_ready;
    assign out_data = memory[read_pointer];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            write_pointer <= 0;
            read_pointer <= 0;
            level <= 0;
        end else begin
            if (push) begin
                memory[write_pointer] <= in_data;
                if (write_pointer == DEPTH-1) write_pointer <= 0;
                else write_pointer <= write_pointer + 1'b1;
            end
            if (pop) begin
                if (read_pointer == DEPTH-1) read_pointer <= 0;
                else read_pointer <= read_pointer + 1'b1;
            end
            case ({push, pop})
                2'b10: level <= level + 1'b1;
                2'b01: level <= level - 1'b1;
                default: level <= level;
            endcase
        end
    end
endmodule
