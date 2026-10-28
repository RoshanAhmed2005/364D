`timescale 1ns/1ps
module tb_datapath;
    reg src_clk=0, rst_n=0, start=0, sink_ready=0;
    reg [15:0] voltage_mv=1000;
    reg stretch_en=1;
    wire proc_clk;
    wire [1:0] v_sense, selected_mode;
    wire out_of_range;
    wire sink_valid, sop_out, eop_out, source_valid, source_ready, source_done;
    wire [31:0] data_out, source_data;
    wire ingress_full, egress_full;
    integer cycle=0, sent=0, received=0, packets=0, stalled=0;
    integer peak_outstanding=0, outstanding, max_latency=0;
    integer accepted_at [0:255];
    integer adaptive, no_sink_stalls, completion_cycle;
    reg [31:0] expected, raw;
    reg source_held=0, sink_held=0;
    reg [31:0] previous_source;
    reg [33:0] previous_sink;
    always #5 src_clk=~src_clk;
    voltage_status mon(.*);
    stretch_clock_model clock_model(.v_sense(v_sense),.stretch_en(stretch_en),
        .clk(proc_clk),.selected_mode(selected_mode));
    demo_datapath dut(.*);

    // Drive before sampling edges to avoid testbench/design races.
    always @(negedge src_clk) begin
        if (rst_n) begin
            cycle=cycle+1;
            if(cycle<20) voltage_mv=1000;
            else if(cycle<40) voltage_mv=970;
            else if(cycle<60) voltage_mv=940;
            else if(cycle<100) voltage_mv=910;
            else voltage_mv=1000;
            sink_ready = no_sink_stalls ||
                (!((cycle>=35)&&(cycle<110)) && (cycle%7!=0));
        end
    end
    always @(posedge src_clk) begin
        if(rst_n) begin
            if(source_held && (!source_valid || source_data !== previous_source))
                $fatal(1,"Source changed while stalled");
            if(sink_held && (!sink_valid || {sop_out,eop_out,data_out} !== previous_sink))
                $fatal(1,"Sink changed while stalled");
            source_held=source_valid&&!source_ready;
            previous_source=source_data;
            sink_held=sink_valid&&!sink_ready;
            previous_sink={sop_out,eop_out,data_out};
            if(source_valid&&!source_ready) stalled=stalled+1;
            if(source_valid&&source_ready) begin
                if(sent>=256) $fatal(1,"Too many input words");
                raw=((sent/8)<<16)|(sent%8);
                if(source_data !== raw) $fatal(1,"Source pattern mismatch");
                accepted_at[sent]=cycle; sent=sent+1;
            end
            if(sink_valid&&sink_ready) begin
                if(received>=sent || received>=256) $fatal(1,"Extra output");
                raw=((received/8)<<16)|(received%8);
                expected=raw^32'hA5A5_5A5A;
                if(data_out !== expected) $fatal(1,"Mismatch at word %0d",received);
                if(sop_out !== (received%8==0) || eop_out !== (received%8==7))
                    $fatal(1,"Packet marker mismatch");
                if(cycle-accepted_at[received]>max_latency)
                    max_latency=cycle-accepted_at[received];
                if(eop_out) packets=packets+1;
                received=received+1;
                if(received==256) completion_cycle=cycle;
            end
            outstanding=sent-received;
            if(outstanding>peak_outstanding) peak_outstanding=outstanding;
        end
    end
    initial begin
        adaptive = !$test$plusargs("baseline"); stretch_en=adaptive;
        no_sink_stalls = $test$plusargs("nostalls");
        if($test$plusargs("waves")) begin
            $dumpfile("build/datapath.vcd"); $dumpvars(0,tb_datapath);
        end
        #22; rst_n=1;
        repeat(5) @(negedge src_clk);
        start=1; @(negedge src_clk); start=0;
        wait(received==256);
        repeat(12) @(negedge src_clk);
        if(received!=256 || sent!=256 || packets!=32 ||
            (!no_sink_stalls && stalled==0))
            $fatal(1,"Bad completion counts or missing backpressure");
        if(completion_cycle>512) $fatal(1,"Missed 512-cycle DEMO deadline");
        $display("PASS datapath adaptive=%0d sink_stalls_enabled=%0d words=%0d packets=%0d stalls=%0d max_latency_cycles=%0d peak_outstanding=%0d completion_cycles=%0d",
            adaptive,!no_sink_stalls,received,packets,stalled,max_latency,peak_outstanding,completion_cycle);
        $finish;
    end
    initial begin #100000; $fatal(1,"Timeout / data failed to drain"); end
endmodule
