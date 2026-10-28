`timescale 1ns/1ps
// Basic combinational request encoder; it does not generate a physical clock.
module stretch_request (
    input wire [1:0] v_sense,
    input wire stretch_en,
    output reg [3:0] period_quarters
);
    always_comb begin
        if(!stretch_en) period_quarters=4;
        else case(v_sense)
            2'b00: period_quarters=4;
            2'b01: period_quarters=5;
            2'b10: period_quarters=6;
            2'b11: period_quarters=8;
            default: period_quarters=8;
        endcase
    end
endmodule
