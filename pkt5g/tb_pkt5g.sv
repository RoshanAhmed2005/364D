`timescale 1ns/1ps
// Sends one random 5G packet per clock cycle. Open the waveform and watch
// pkt_type, plane, header and payload.
module tb_pkt5g;
    import pkt5g_pkg::*;

    logic        clk = 0;
    plane_e      plane;
    pkt_type_e   pkt_type;
    logic [63:0] header;
    logic [63:0] payload;

    always #5 clk = ~clk;

    initial begin
        pkt_base pkt;
        gtpu_pkt gtpu;
        pdcp_pkt pdcp;
        rrc_pkt  rrc;
        nas_pkt  nas;
        ngap_pkt ngap;
        repeat (50) begin
            @(posedge clk);
            case ($urandom_range(0, 4))
                0: begin gtpu = new(); pkt = gtpu; end
                1: begin pdcp = new(); pkt = pdcp; end
                2: begin rrc  = new(); pkt = rrc;  end
                3: begin nas  = new(); pkt = nas;  end
                4: begin ngap = new(); pkt = ngap; end
            endcase
            pkt.fill();
            plane    = pkt.plane;
            pkt_type = pkt.pkt_type;
            header   = pkt.header();
            payload  = pkt.payload;
        end
        $finish;
    end
endmodule
