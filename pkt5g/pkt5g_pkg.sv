// Simulated 5G packets (behavioral only, not synthesizable).
// Hierarchy:
//   pkt_base
//   |-- up_pkt  (user plane)    : gtpu_pkt, pdcp_pkt
//   `-- cp_pkt  (control plane) : rrc_pkt, nas_pkt, ngap_pkt
// Each packet is reduced to a 64-bit header plus a 64-bit payload so it can
// be shown on a waveform. Fields use $urandom instead of randomize() so the
// code also runs on ModelSim editions without constrained-random support.
package pkt5g_pkg;

    typedef enum logic [0:0] {USER_PLANE, CONTROL_PLANE} plane_e;
    typedef enum logic [2:0] {GTPU, PDCP, RRC, NAS, NGAP} pkt_type_e;

    virtual class pkt_base;
        plane_e      plane;
        pkt_type_e   pkt_type;
        logic [63:0] payload;

        function void fill();
            payload = {$urandom, $urandom};
            fill_header();
        endfunction

        pure virtual function void fill_header();
        pure virtual function logic [63:0] header();
    endclass

    virtual class up_pkt extends pkt_base;
        function new();
            plane = USER_PLANE;
        endfunction
    endclass

    virtual class cp_pkt extends pkt_base;
        function new();
            plane = CONTROL_PLANE;
        endfunction
    endclass

    // ---------------- User plane ----------------

    // GTP-U (N3/N9 tunnel between gNB and UPF), G-PDU carrying user data.
    class gtpu_pkt extends up_pkt;
        logic [7:0]  flags;     // version 1, PT=1
        logic [7:0]  msg_type;  // 0xFF = G-PDU
        logic [15:0] length;
        logic [31:0] teid;

        function new();
            pkt_type = GTPU;
        endfunction

        virtual function void fill_header();
            flags    = 8'h30;
            msg_type = 8'hFF;
            length   = 16'd8;
            teid     = $urandom;
        endfunction

        virtual function logic [63:0] header();
            return {flags, msg_type, length, teid};
        endfunction
    endclass

    // PDCP data PDU (12-bit SN) carrying a user-plane SDU over the air.
    class pdcp_pkt extends up_pkt;
        logic        dc;  // 1 = data PDU
        logic [11:0] sn;

        function new();
            pkt_type = PDCP;
        endfunction

        virtual function void fill_header();
            dc = 1'b1;
            sn = $urandom;
        endfunction

        virtual function logic [63:0] header();
            return {48'h0, dc, 3'b000, sn};
        endfunction
    endclass

    // ---------------- Control plane ----------------

    // RRC message between UE and gNB.
    class rrc_pkt extends cp_pkt;
        typedef enum logic [7:0] {
            SETUP_REQUEST, SETUP, SETUP_COMPLETE, RECONFIGURATION, RELEASE
        } rrc_msg_e;
        rrc_msg_e    msg;
        logic [31:0] ue_id;

        function new();
            pkt_type = RRC;
        endfunction

        virtual function void fill_header();
            msg   = rrc_msg_e'($urandom_range(0, 4));
            ue_id = $urandom;
        endfunction

        virtual function logic [63:0] header();
            return {24'h0, msg, ue_id};
        endfunction
    endclass

    // NAS 5GMM message between UE and AMF.
    class nas_pkt extends cp_pkt;
        logic [7:0] epd;       // 0x7E = 5GS mobility management
        logic [3:0] sec_hdr;   // 0 = plain
        logic [7:0] msg_type;

        function new();
            pkt_type = NAS;
        endfunction

        virtual function void fill_header();
            logic [7:0] types [4] = '{8'h41, 8'h42, 8'h43, 8'h45}; // reg req/acc/cmp, dereg
            epd      = 8'h7E;
            sec_hdr  = 4'h0;
            msg_type = types[$urandom_range(0, 3)];
        endfunction

        virtual function logic [63:0] header();
            return {40'h0, epd, 4'h0, sec_hdr, msg_type};
        endfunction
    endclass

    // NGAP message between gNB and AMF (N2).
    class ngap_pkt extends cp_pkt;
        logic [7:0]  proc_code; // 15 = InitialUEMessage, 46 = UplinkNASTransport, ...
        logic [31:0] ran_ue_id;

        function new();
            pkt_type = NGAP;
        endfunction

        virtual function void fill_header();
            logic [7:0] codes [3] = '{8'd15, 8'd4, 8'd46};
            proc_code = codes[$urandom_range(0, 2)];
            ran_ue_id = $urandom;
        endfunction

        virtual function logic [63:0] header();
            return {24'h0, proc_code, ran_ue_id};
        endfunction
    endclass

endpackage
