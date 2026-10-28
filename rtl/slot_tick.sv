`timescale 1ns/1ps
// 0.5 ms at 491.52 MHz is 245760 cycles. Override for faster demos.
module slot_tick #(
    parameter integer SLOT_CYCLES = 245760
) (
    input wire clk, rst_n,
    output reg slot_sync
);
    localparam integer BITS = (SLOT_CYCLES < 2) ? 1 : $clog2(SLOT_CYCLES);
    reg [BITS-1:0] count;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin count <= 0; slot_sync <= 0; end
        else begin
            slot_sync <= (count == SLOT_CYCLES-1);
            if(count == SLOT_CYCLES-1) count <= 0;
            else count <= count + 1'b1;
        end
    end
endmodule
