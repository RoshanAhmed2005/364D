`timescale 1ns/1ps
module tb_voltage_clock;
    reg [15:0] voltage_mv = 1000;
    reg stretch_en = 1;
    wire [1:0] v_sense, selected_mode;
    wire out_of_range, clk;
    integer seen [0:3];
    integer i;
    realtime previous_edge, measured, expected;
    reg [1:0] previous_mode;
    reg have_edge = 0;
    voltage_status mon(.*);
    stretch_clock_model clock_model(.*);
    always @(posedge clk) begin
        if (have_edge) begin
            measured = $realtime-previous_edge;
            case (previous_mode)
                0: expected=10.0; 1: expected=12.5;
                2: expected=15.0; 3: expected=20.0;
            endcase
            if (measured < expected-0.002 || measured > expected+0.002)
                $fatal(1,"Wrong period: got %f expected %f",measured,expected);
            seen[previous_mode] = seen[previous_mode]+1;
        end
        // Clock model and checker wake together; sample mode after it settles.
        #0.001;
        previous_edge = $realtime-0.001;
        previous_mode = selected_mode;
        have_edge = 1;
    end
    task check_voltage(input integer mv, input [1:0] code, input bit bad);
        begin
            @(negedge clk); voltage_mv=mv; #0.01;
            if (v_sense !== code || out_of_range !== bad)
                $fatal(1,"Voltage map mismatch at %0d mV",mv);
            repeat(4) @(negedge clk);
        end
    endtask
    initial begin
        for(i=0;i<4;i=i+1) seen[i]=0;
        check_voltage(1000,0,0); check_voltage(980,0,0);
        check_voltage(979,1,0); check_voltage(950,1,0);
        check_voltage(949,2,0); check_voltage(920,2,0);
        check_voltage(919,3,0); check_voltage(900,3,0);
        check_voltage(899,3,1); check_voltage(1101,0,1);
        @(negedge clk); stretch_en=0; voltage_mv=910;
        repeat(5) @(negedge clk);
        if (selected_mode !== 0) $fatal(1,"Bypass failed");
        for(i=0;i<4;i=i+1)
            if(seen[i]==0) $fatal(1,"Missing clock mode %0d",i);
        $display("PASS voltage thresholds, range flag, four clock periods, bypass");
        $finish;
    end
    initial begin #10000; $fatal(1,"Timeout"); end
endmodule
