`timescale 1ns/1ps
// Synthetic packets: {16-bit packet number, 16-bit word number}.
// Advance only on valid && ready; keep data and markers stable when stalled.
module packet_source #(
    parameter integer WORDS_PER_PACKET = 8,
    parameter integer PACKET_COUNT = 32
) (
    input wire clk, rst_n, start,
    output reg valid,
    input wire ready,
    output wire [31:0] data,
    output wire sop, eop,
    output reg done,
    output wire busy
);
    reg [15:0] packet_id, word_id;
    assign data = {packet_id, word_id};
    assign sop = (word_id == 0);
    assign eop = (word_id == WORDS_PER_PACKET-1);
    assign busy = valid;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            packet_id <= 0; word_id <= 0; valid <= 0; done <= 0;
        end else begin
            done <= 0;
            if (!valid && start) begin
                packet_id <= 0; word_id <= 0; valid <= 1;
            end else if (valid && ready) begin
                if (eop) begin
                    word_id <= 0;
                    if (packet_id == PACKET_COUNT-1) begin
                        valid <= 0; done <= 1;
                    end else packet_id <= packet_id + 1'b1;
                end else word_id <= word_id + 1'b1;
            end
        end
    end
endmodule
