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


    initial begin

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


        // Release reset
        #20;
        ARESETn = 1;


        // Wait until STW_IDLE makes AWREADY = 1
        #10;


        // Test AW handshake
        AWID    = 8'h01;
        AWADDR  = 32'h0000_0010;
        AWLEN   = 4'h0;
        AWSIZE  = 3'b010;
        AWBURST = 2'b01;
        AWLOCK  = 2'b00;
        AWVALID = 1;


        // Handshake happens here
        #10;

        AWVALID = 0;


        // Show result
        $display("AWREADY    = %b", AWREADY);
        $display("WREADY     = %b", WREADY);
        $display("AWID_reg   = %h", dut.AWID_reg);
        $display("AWADDR_reg = %h", dut.AWADDR_reg);
        $display("addrW      = %h", dut.addrW);
        $display("beatW      = %h", dut.beatW);
        $display("stateW     = %b", dut.stateW);


        #20;
        $finish;

    end

endmodule