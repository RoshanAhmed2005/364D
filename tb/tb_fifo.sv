`timescale 1ns/1ps
module tb_fifo;
    reg rst_n=0, wr_clk=0, rd_clk=0, wr_valid=0, rd_ready=0;
    reg [15:0] wr_data=0;
    wire wr_ready, rd_valid, full, empty;
    wire [15:0] rd_data;
    integer batch,j;
    always #5 wr_clk=~wr_clk;
    always #7 rd_clk=~rd_clk;
    async_fifo #(.WIDTH(16),.ADDR_BITS(2)) dut(.*);
    task put(input integer value);
        begin
            @(negedge wr_clk); wr_data=value; wr_valid=1;
            do @(posedge wr_clk); while(!wr_ready);
            @(negedge wr_clk); wr_valid=0;
        end
    endtask
    task get_word(input integer value);
        begin
            @(negedge rd_clk); rd_ready=1;
            do @(posedge rd_clk); while(!rd_valid);
            if(rd_data !== value[15:0]) $fatal(1,"FIFO order mismatch");
            @(negedge rd_clk); rd_ready=0;
        end
    endtask
    initial begin
        #23; rst_n=1;
        repeat(5) @(posedge wr_clk);
        for(batch=0;batch<6;batch=batch+1) begin
            for(j=0;j<4;j=j+1) put(batch*4+j);
            #1; if(!full || wr_ready) $fatal(1,"FIFO did not become full");
            // A fifth offered word must not overwrite accepted data.
            @(negedge wr_clk); wr_valid=1; wr_data=16'hFFFF;
            repeat(3) begin @(posedge wr_clk); if(wr_ready) $fatal(1,"Accepted full write"); end
            @(negedge wr_clk); wr_valid=0;
            for(j=0;j<4;j=j+1) get_word(batch*4+j);
            #1; if(!empty || rd_valid) $fatal(1,"FIFO did not become empty");
            @(negedge rd_clk); rd_ready=1;
            repeat(3) begin @(posedge rd_clk); if(rd_valid) $fatal(1,"Accepted empty read"); end
            @(negedge rd_clk); rd_ready=0;
        end
        // Reset discards pending words in both clock domains.
        put(123); @(negedge wr_clk); rst_n=0;
        #20; rst_n=1; repeat(6) @(posedge rd_clk);
        if(rd_valid || !empty) $fatal(1,"Reset did not flush FIFO");
        put(456); get_word(456);
        $display("PASS FIFO full/empty blocking, wraparound, order, common reset");
        $finish;
    end
    initial begin #20000; $fatal(1,"Timeout"); end
endmodule
