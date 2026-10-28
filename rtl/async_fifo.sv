`timescale 1ns/1ps
// Teaching FIFO: power-of-two depth >= 4, common reset, show-ahead read.
// Gray pointers cross via two registers. Actual hardware still needs CDC,
// Gray-bus routing/skew constraints, reset review, and memory inference review.
module async_fifo #(
    parameter integer WIDTH = 34,
    parameter integer ADDR_BITS = 3
) (
    input wire rst_n,
    input wire wr_clk, wr_valid,
    output wire wr_ready,
    input wire [WIDTH-1:0] wr_data,
    input wire rd_clk,
    output wire rd_valid,
    input wire rd_ready,
    output wire [WIDTH-1:0] rd_data,
    output reg full, empty
);
    localparam integer DEPTH = 1 << ADDR_BITS;
    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [ADDR_BITS:0] wbin, wgray, rbin, rgray;
    (* ASYNC_REG = "TRUE" *) reg [ADDR_BITS:0] rq1_wgray, rq2_wgray;
    (* ASYNC_REG = "TRUE" *) reg [ADDR_BITS:0] wq1_rgray, wq2_rgray;
    (* ASYNC_REG = "TRUE" *) reg [1:0] wr_reset_pipe, rd_reset_pipe;
    wire wr_run = wr_reset_pipe[1];
    wire rd_run = rd_reset_pipe[1];
    wire [ADDR_BITS:0] wnext = wbin + (wr_valid && wr_ready);
    wire [ADDR_BITS:0] rnext = rbin + (rd_valid && rd_ready);
    wire [ADDR_BITS:0] wgray_next = (wnext >> 1) ^ wnext;
    wire [ADDR_BITS:0] rgray_next = (rnext >> 1) ^ rnext;
    wire [ADDR_BITS:0] full_compare =
        {~wq2_rgray[ADDR_BITS:ADDR_BITS-1], wq2_rgray[ADDR_BITS-2:0]};
    assign wr_ready = wr_run && !full;
    assign rd_valid = rd_run && !empty;
    assign rd_data = mem[rbin[ADDR_BITS-1:0]];

    always @(posedge wr_clk or negedge rst_n)
        if (!rst_n) wr_reset_pipe <= 0;
        else wr_reset_pipe <= {wr_reset_pipe[0], 1'b1};
    always @(posedge rd_clk or negedge rst_n)
        if (!rst_n) rd_reset_pipe <= 0;
        else rd_reset_pipe <= {rd_reset_pipe[0], 1'b1};

    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin wq1_rgray <= 0; wq2_rgray <= 0; end
        else if (!wr_run) begin wq1_rgray <= 0; wq2_rgray <= 0; end
        else begin wq1_rgray <= rgray; wq2_rgray <= wq1_rgray; end
    end
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin rq1_wgray <= 0; rq2_wgray <= 0; end
        else if (!rd_run) begin rq1_wgray <= 0; rq2_wgray <= 0; end
        else begin rq1_wgray <= wgray; rq2_wgray <= rq1_wgray; end
    end
    always @(posedge wr_clk or negedge rst_n) begin
        if (!rst_n) begin wbin <= 0; wgray <= 0; full <= 0; end
        else if (!wr_run) begin wbin <= 0; wgray <= 0; full <= 0; end
        else begin
            if (wr_valid && wr_ready) mem[wbin[ADDR_BITS-1:0]] <= wr_data;
            wbin <= wnext; wgray <= wgray_next;
            full <= (wgray_next == full_compare);
        end
    end
    always @(posedge rd_clk or negedge rst_n) begin
        if (!rst_n) begin rbin <= 0; rgray <= 0; empty <= 1; end
        else if (!rd_run) begin rbin <= 0; rgray <= 0; empty <= 1; end
        else begin
            rbin <= rnext; rgray <= rgray_next;
            empty <= (rgray_next == rq2_wgray);
        end
    end
endmodule
