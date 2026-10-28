`timescale 1ns/1ps
// SIMULATION ONLY. No synthesizable generated-clock implementation is supplied.
// Sample mode on each rising edge; hold high for T/2 and extend the low time.
// The selected mode describes the interval from this rising edge to the next.
module stretch_clock_model #(
    parameter real NOMINAL_NS = 10.0
) (
    input wire [1:0] v_sense,
    input wire stretch_en,
    output reg clk = 0,
    output reg [1:0] selected_mode = 0
);
    real factor;
    wire [3:0] period_quarters;
    stretch_request request_encoder(.*);
    initial begin
        #1;
        forever begin
            clk = 1;
            selected_mode = stretch_en ? v_sense : 2'b00;
            factor = period_quarters/4.0;
            #(NOMINAL_NS/2.0) clk = 0;
            #(NOMINAL_NS*factor - NOMINAL_NS/2.0);
        end
    end
endmodule
