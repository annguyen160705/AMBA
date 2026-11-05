`timescale 1ns/1ps

module tb_mem_axi;

    logic ACLK;
    logic ARESETn;

    logic [7:0]  AWID;
    logic [31:0] AWADDR;
    logic [3:0]  AWLEN;
    logic [1:0]  AWLOCK;
    logic [2:0]  AWSIZE;
    logic [1:0]  AWBURST;
    logic        AWVALID;
    logic        AWREADY;

    logic [7:0]  WID;
    logic [31:0] WDATA;
    logic [3:0]  WSTRB;
    logic        WLAST;
    logic        WVALID;
    logic        WREADY;

    logic [7:0]  BID;
    logic [1:0]  BRESP;
    logic        BVALID;
    logic        BREADY;

    logic [7:0]  ARID;
    logic [31:0] ARADDR;
    logic [3:0]  ARLEN;
    logic [1:0]  ARLOCK;
    logic [2:0]  ARSIZE;
    logic [1:0]  ARBURST;
    logic        ARVALID;
    logic        ARREADY;

    logic [7:0]  RID;
    logic [31:0] RDATA;
    logic [1:0]  RRESP;
    logic        RVALID;
    logic        RLAST;
    logic        RREADY;

    logic CSYSREQ;
    logic CSYSACK;
    logic CACTIVE;


    mem_axi dut (
        .ARESETn(ARESETn),
        .ACLK(ACLK),

        .AWID(AWID),
        .AWADDR(AWADDR),
        .AWLEN(AWLEN),
        .AWLOCK(AWLOCK),
        .AWSIZE(AWSIZE),
        .AWBURST(AWBURST),
        .AWVALID(AWVALID),
        .AWREADY(AWREADY),

        .WID(WID),
        .WDATA(WDATA),
        .WSTRB(WSTRB),
        .WLAST(WLAST),
        .WVALID(WVALID),
        .WREADY(WREADY),

        .BID(BID),
        .BRESP(BRESP),
        .BVALID(BVALID),
        .BREADY(BREADY),

        .ARID(ARID),
        .ARADDR(ARADDR),
        .ARLEN(ARLEN),
        .ARLOCK(ARLOCK),
        .ARSIZE(ARSIZE),
        .ARBURST(ARBURST),
        .ARVALID(ARVALID),
        .ARREADY(ARREADY),

        .RID(RID),
        .RDATA(RDATA),
        .RRESP(RRESP),
        .RVALID(RVALID),
        .RLAST(RLAST),
        .RREADY(RREADY),

        .CSYSREQ(CSYSREQ),
        .CSYSACK(CSYSACK),
        .CACTIVE(CACTIVE)
    );


    // Clock
    always #5 ACLK = ~ACLK;

    //============================================================
    // Send Write Address
    //============================================================
    task send_aw(
        input logic [7:0]  id,
        input logic [31:0] addr,
        input logic [3:0]  len,
        input logic [2:0]  size,
        input logic [1:0]  burst
    );
    begin

        @(negedge ACLK);

        AWID    = id;
        AWADDR  = addr;
        AWLEN   = len;
        AWSIZE  = size;
        AWBURST = burst;
        AWLOCK  = 2'b00;
        AWVALID = 1'b1;

        // Wait for AWREADY
        wait(AWREADY == 1'b1);

        // AW handshake
        @(posedge ACLK);

        @(negedge ACLK);
        AWVALID = 1'b0;

        $display("AW : ID=%h ADDR=%h LEN=%d SIZE=%b BURST=%b",
                id, addr, len, size, burst);

    end
    endtask


    //============================================================
    // Send Write Data
    //============================================================
    task send_w(
        input logic [7:0]  id,
        input logic [31:0] data,
        input logic        last
    );
    begin

        @(negedge ACLK);

        WID    = id;
        WDATA  = data;
        WSTRB  = 4'b1111;
        WLAST  = last;
        WVALID = 1'b1;

        // Wait for WREADY
        wait(WREADY == 1'b1);

        // W handshake
        @(posedge ACLK);

        @(negedge ACLK);

        WVALID = 1'b0;
        WLAST  = 1'b0;

        $display("W  : ADDR=%h DATA=%h LAST=%b beatW=%d",
                dut.Twaddr, dut.Twdata, last, dut.beatW);

    end
    endtask


    //============================================================
    // Receive Write Response
    //============================================================
    task receive_b;
    begin

        wait(BVALID == 1'b1);

        @(negedge ACLK);
        BREADY = 1'b1;

        $display("B  : BID=%h BRESP=%b", BID, BRESP);

        @(posedge ACLK);

        @(negedge ACLK);
        BREADY = 1'b0;

    end
    endtask

    //============================================================
    // Send Read Address
    //============================================================
    task send_ar(
        input logic [7:0]  id,
        input logic [31:0] addr,
        input logic [3:0]  len,
        input logic [2:0]  size,
        input logic [1:0]  burst
    );
    begin

        @(negedge ACLK);

        ARID    = id;
        ARADDR  = addr;
        ARLEN   = len;
        ARSIZE  = size;
        ARBURST = burst;
        ARLOCK  = 2'b00;
        ARVALID = 1'b1;

        // Wait until DUT is ready
        wait(ARREADY == 1'b1);

        // AR handshake
        @(posedge ACLK);

        @(negedge ACLK);
        ARVALID = 1'b0;

        $display("AR : ID=%h ADDR=%h LEN=%d SIZE=%b BURST=%b",
                id, addr, len, size, burst);

    end
    endtask


    //============================================================
    // Receive Read Data
    //============================================================
    task receive_r(
        input integer number_of_beats
    );

        integer i;

    begin

        i = 0;

        @(negedge ACLK);
        RREADY = 1'b1;

        while(i < number_of_beats) begin

            @(negedge ACLK);

            if(RVALID && RREADY) begin

                $display(
                    "R  : RID=%h DATA=%h RESP=%b LAST=%b",
                    RID,
                    RDATA,
                    RRESP,
                    RLAST
                );

                i = i + 1;

            end

        end

        // Allow the final R handshake
        @(posedge ACLK);

        @(negedge ACLK);
        RREADY = 1'b0;

    end
    endtask


    initial begin

    //--------------------------------------------------------
    // Initial values
    //--------------------------------------------------------
    ACLK    = 0;
    ARESETn = 0;

    AWID    = 0;
    AWADDR  = 0;
    AWLEN   = 0;
    AWLOCK  = 0;
    AWSIZE  = 0;
    AWBURST = 0;
    AWVALID = 0;

    WID     = 0;
    WDATA   = 0;
    WSTRB   = 0;
    WLAST   = 0;
    WVALID  = 0;

    BREADY  = 0;

    ARID    = 0;
    ARADDR  = 0;
    ARLEN   = 0;
    ARLOCK  = 0;
    ARSIZE  = 0;
    ARBURST = 0;
    ARVALID = 0;
    RREADY  = 0;

    CSYSREQ = 0;


    //--------------------------------------------------------
    // RESET
    //--------------------------------------------------------
    #20;
    ARESETn = 1;

    #20; //40


    //========================================================
    // TEST 1: SINGLE DATA WRITE
    //========================================================
    $display("");
    $display("====================================");
    $display(" TEST 1: SINGLE WRITE");
    $display("====================================");

    // One transfer:
    // AWLEN = 0 -> 1 beat
    //
    // Address = 0x10
    // Size    = 010 -> 4 bytes
    // Burst   = 01  -> INCR

    send_aw(
        8'h01,
        32'h0000_0010,
        4'd0,
        3'b010,
        2'b01
    );

    // Only one data beat -> WLAST = 1
    send_w(
        8'h01,
        32'h1111_2222,
        1'b1
    );

    receive_b(); 


    //--------------------------------------------------------
    // Wait before next transaction
    //--------------------------------------------------------
    #20;


    //========================================================
    // TEST 2: MULTIPLE DATA WRITE
    //========================================================
    $display("");
    $display("====================================");
    $display(" TEST 2: MULTIPLE WRITE");
    $display("====================================");

    // Three transfers:
    // AWLEN = 2 -> 3 beats
    //
    // AWSIZE  = 010 -> 4 bytes/beat
    // AWBURST = 01  -> INCR
    //
    // Expected addresses:
    // Beat 0 -> 0x20
    // Beat 1 -> 0x24
    // Beat 2 -> 0x28

    send_aw(
        8'h02,
        32'h0000_0020,
        4'd2, //3 beats
        3'b010,
        2'b01
    );


    // Beat 0
    send_w(
        8'h02,
        32'hAAAA_1111,
        1'b0
    );


    // Beat 1
    send_w(
        8'h02,
        32'hBBBB_2222,
        1'b0
    );


    // Beat 2 - LAST DATA
    send_w(
        8'h02,
        32'hCCCC_3333,
        1'b1 //WLAST
    );


    // Only one B response for the whole burst
    receive_b();

    //========================================================
    // TEST 3: SINGLE READ
    //========================================================
    #20;
    $display("");
    $display("====================================");
    $display(" TEST 3: SINGLE READ");
    $display("====================================");

    // Earlier:
    // address 0x10 <- 32'h1111_2222

    send_ar(
        8'h01,             // ID
        32'h0000_0010,     // address
        4'd0,              // ARLEN = 0 -> 1 beat
        3'b010,            // 4 bytes
        2'b01              // INCR
    );

    receive_r(1);


    #20;


    //========================================================
    // TEST 4: MULTIPLE READ
    //========================================================
    $display("");
    $display("====================================");
    $display(" TEST 4: MULTIPLE READ");
    $display("====================================");

    // Earlier:
    // 0x20 <- AAAA1111
    // 0x24 <- BBBB2222
    // 0x28 <- CCCC3333

    send_ar(
        8'h02,             // ID
        32'h0000_0020,     // start address
        4'd2,              // ARLEN = 2 -> 3 beats
        3'b010,            // 4 bytes / beat
        2'b01              // INCR
    );

    receive_r(3);


    //--------------------------------------------------------
    // Finish
    //--------------------------------------------------------
    #20;

    $display("");
    $display("====================================");
    $display(" TEST FINISHED");
    $display("====================================");

    $finish;

end 

endmodule