// Synthetic workload: packet ID in bits 31:16, word index in bits 15:0.
module packet_source #(
    parameter int WORDS_PER_PACKET = 16
) (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        enable,
    input  logic        ready,
    output logic [31:0] data,
    output logic        valid,
    output logic        first,
    output logic        last
);
    logic [15:0] packet_id, word_index;
    assign data = {packet_id, word_index};
    assign first = valid && (word_index == 0);
    assign last = valid && (word_index == WORDS_PER_PACKET-1);

    // Finish an active packet before stopping; never change a stalled word.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            packet_id <= 0;
            word_index <= 0;
            valid <= 0;
        end else if (!valid) begin
            if (enable) valid <= 1;
        end else if (ready) begin
            if (last) begin
                packet_id <= packet_id + 16'd1;
                word_index <= 0;
                valid <= enable;
            end else begin
                word_index <= word_index + 16'd1;
            end
        end
    end
endmodule
