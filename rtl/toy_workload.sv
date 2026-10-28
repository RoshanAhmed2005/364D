`timescale 1ns/1ps
// One elastic processing register. XOR is a visible, reversible test operation.
// This is not actual 5G baseband processing or packet protocol IP.
module toy_workload #(
    parameter [31:0] XOR_MASK = 32'hA5A5_5A5A
) (
    input wire clk, rst_n,
    input wire in_valid,
    output wire in_ready,
    input wire [33:0] in_word,
    output reg out_valid,
    input wire out_ready,
    output reg [33:0] out_word
);
    assign in_ready = !out_valid || out_ready;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin out_valid <= 0; out_word <= 0; end
        else if (in_ready) begin
            out_valid <= in_valid;
            if (in_valid)
                out_word <= {in_word[33:32], in_word[31:0] ^ XOR_MASK};
        end
    end
endmodule
