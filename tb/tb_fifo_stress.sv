`timescale 1ns/1ps
module tb_fifo_stress #(
    parameter integer WR_HALF=5,
    parameter integer RD_HALF=7
);
    reg rst_n=0, wr_clk=0, rd_clk=0, wr_valid=0, rd_ready=0;
    reg [31:0] wr_data=0;
    wire wr_ready, rd_valid, full, empty;
    wire [31:0] rd_data;
    reg [15:0] wlfsr=16'hACE1, rlfsr=16'h1234;
    integer sent=0, received=0;
    always #(WR_HALF) wr_clk=~wr_clk;
    always #(RD_HALF) rd_clk=~rd_clk;
    async_fifo #(.WIDTH(32),.ADDR_BITS(3)) dut(.*);
    always @(negedge wr_clk) begin
        if(rst_n) begin
            wlfsr={wlfsr[14:0],wlfsr[15]^wlfsr[13]^wlfsr[12]^wlfsr[10]};
            wr_valid=(sent<1000) && wlfsr[0];
            wr_data=sent;
        end
    end
    always @(negedge rd_clk) begin
        if(rst_n) begin
            rlfsr={rlfsr[14:0],rlfsr[15]^rlfsr[13]^rlfsr[12]^rlfsr[10]};
            rd_ready=rlfsr[0] || rlfsr[1];
        end
    end
    always @(posedge wr_clk)
        if(rst_n && wr_valid && wr_ready) sent=sent+1;
    always @(posedge rd_clk) begin
        if(rst_n && rd_valid && rd_ready) begin
            if(rd_data !== received) $fatal(1,"FIFO stress mismatch at %0d",received);
            received=received+1;
        end
    end
    initial begin
        #23; rst_n=1;
        wait(received==1000);
        repeat(20) @(negedge rd_clk);
        if(received!=1000 || sent!=1000 || !empty)
            $fatal(1,"FIFO stress counts failed");
        $display("PASS FIFO stress: 1000 words, write half-period=%0d ns read half-period=%0d ns",WR_HALF,RD_HALF);
        $finish;
    end
    initial begin #200000; $fatal(1,"FIFO stress timeout"); end
endmodule
