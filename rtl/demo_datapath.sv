`timescale 1ns/1ps
// Packet source -> ingress FIFO -> toy processing -> egress FIFO -> sink.
module demo_datapath #(
    parameter integer ADDR_BITS = 3,
    parameter integer WORDS_PER_PACKET = 8,
    parameter integer PACKET_COUNT = 32
) (
    input wire src_clk, proc_clk, rst_n, start,
    input wire sink_ready,
    output wire sink_valid,
    output wire [31:0] data_out,
    output wire sop_out, eop_out,
    output wire source_valid, source_ready, source_done,
    output wire [31:0] source_data,
    output wire ingress_full, egress_full
);
    wire sop_in, eop_in;
    wire in_valid, in_ready, work_valid, work_ready;
    wire [33:0] in_word, work_word, sink_word;
    wire unused_ingress_empty, unused_egress_empty, unused_busy;
    packet_source #(.WORDS_PER_PACKET(WORDS_PER_PACKET), .PACKET_COUNT(PACKET_COUNT)) src (
        .clk(src_clk), .rst_n(rst_n), .start(start), .valid(source_valid),
        .ready(source_ready), .data(source_data), .sop(sop_in), .eop(eop_in),
        .done(source_done), .busy(unused_busy)
    );
    async_fifo #(.ADDR_BITS(ADDR_BITS)) ingress (
        .rst_n(rst_n), .wr_clk(src_clk), .wr_valid(source_valid),
        .wr_ready(source_ready), .wr_data({sop_in,eop_in,source_data}),
        .rd_clk(proc_clk), .rd_valid(in_valid), .rd_ready(in_ready),
        .rd_data(in_word), .full(ingress_full), .empty(unused_ingress_empty)
    );
    toy_workload work_unit (
        .clk(proc_clk), .rst_n(rst_n), .in_valid(in_valid), .in_ready(in_ready),
        .in_word(in_word), .out_valid(work_valid), .out_ready(work_ready),
        .out_word(work_word)
    );
    async_fifo #(.ADDR_BITS(ADDR_BITS)) egress (
        .rst_n(rst_n), .wr_clk(proc_clk), .wr_valid(work_valid),
        .wr_ready(work_ready), .wr_data(work_word), .rd_clk(src_clk),
        .rd_valid(sink_valid), .rd_ready(sink_ready), .rd_data(sink_word),
        .full(egress_full), .empty(unused_egress_empty)
    );
    assign {sop_out,eop_out,data_out} = sink_word;
endmodule
