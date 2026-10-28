`timescale 1ns/1ps
module tb_slot_tick;
    reg clk=0, rst_n=0;
    wire slot_sync;
    integer i, pulses=0;
    always #5 clk=~clk;
    slot_tick #(.SLOT_CYCLES(8)) dut(.*);
    initial begin
        #12; rst_n=1;
        for(i=1;i<=40;i=i+1) begin
            @(posedge clk); #1;
            if(slot_sync !== (i%8==0)) $fatal(1,"Incorrect slot pulse");
            if(slot_sync) pulses=pulses+1;
        end
        if(pulses!=5) $fatal(1,"Missing slot pulses");
        $display("PASS slot trigger interval and single-cycle pulse");
        $finish;
    end
endmodule
