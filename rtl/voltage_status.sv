`timescale 1ns/1ps
// Digital millivolt encoding, not an analog sensor or a voltage-delay model.
module voltage_status (
    input  wire [15:0] voltage_mv,
    output reg  [1:0]  v_sense,
    output wire        out_of_range
);
    assign out_of_range = (voltage_mv < 900) || (voltage_mv > 1100);
    always_comb begin
        if      (voltage_mv >= 980) v_sense = 2'b00;
        else if (voltage_mv >= 950) v_sense = 2'b01;
        else if (voltage_mv >= 920) v_sense = 2'b10;
        else                       v_sense = 2'b11;
    end
endmodule
