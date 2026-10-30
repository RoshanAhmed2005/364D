// Clocked monitor for an already-digitized voltage sample, in millivolts.
module voltage_status #(
    parameter int MINOR_MV = 980,
    parameter int MODERATE_MV = 950,
    parameter int SEVERE_MV = 920,
    parameter int HYSTERESIS_MV = 10,
    parameter int MIN_VALID_MV = 900,
    parameter int MAX_VALID_MV = 1100
) (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        sample_valid,
    input  logic [15:0] voltage_mv,
    output logic [1:0]  v_sense,
    output logic        status_valid,
    output logic        droop_active,
    output logic        voltage_fault
);
    logic [1:0] next_status;

    // Worsening voltage is detected on the next accepted sample.
    // Recovery needs extra margin to avoid toggling near a threshold.
    always_comb begin
        if ((voltage_mv < SEVERE_MV) ||
            ((v_sense == 3) && (voltage_mv < SEVERE_MV + HYSTERESIS_MV)))
            next_status = 2'b11;
        else if ((voltage_mv < MODERATE_MV) ||
            ((v_sense >= 2) && (voltage_mv < MODERATE_MV + HYSTERESIS_MV)))
            next_status = 2'b10;
        else if ((voltage_mv < MINOR_MV) ||
            ((v_sense >= 1) && (voltage_mv < MINOR_MV + HYSTERESIS_MV)))
            next_status = 2'b01;
        else
            next_status = 2'b00;
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            v_sense <= 0;
            status_valid <= 0;
            voltage_fault <= 0;
        end else if (sample_valid) begin
            v_sense <= next_status;
            status_valid <= 1;
            voltage_fault <= (voltage_mv < MIN_VALID_MV) ||
                             (voltage_mv > MAX_VALID_MV);
        end
    end
    assign droop_active = status_valid && (v_sense != 0);
endmodule
