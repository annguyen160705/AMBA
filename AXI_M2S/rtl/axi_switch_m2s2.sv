module axi_switch_m2s2
        #(parameter WIDTH_CID   = 4 // Channel ID width in bits
                    , WIDTH_ID    = 4 // ID width in bits
                    , WIDTH_AD    =32 // address width
                    , WIDTH_DA    =32 // data width
                    , WIDTH_DS    =(WIDTH_DA/8)  // data strobe width
                    , WIDTH_SID   =(WIDTH_CID+WIDTH_ID)// ID for slave
                    , WIDTH_AWUSER=1 // Write-address user path
                    , WIDTH_WUSER =1 // Write-data user path
                    , WIDTH_BUSER =1 // Write-response user path
                    , WIDTH_ARUSER=1 // read-address user path
                    , WIDTH_RUSER =1 // read-data user path
                    , SLAVE_EN0   =1
                    , ADDR_BASE0  =32'h0000_0000
                    , ADDR_LENGTH0=12 // effective addre bits
                    , SLAVE_EN1   =1
                    , ADDR_BASE1  =32'h0000_2000
                    , ADDR_LENGTH1=12 // effective addre bits
                    , NUM_MASTER  =2  // should not be changed
                    , NUM_SLAVE   =2  // should not be changed
            )
    (
        input   logic                      ARESETn
        , input   logic                      ACLK
        //--------------------------------------------------------------
        , input   logic  [WIDTH_CID-1:0]     M0_MID   // if not sure use 'h0
        , input   logic  [WIDTH_ID-1:0]      M0_AWID
        , input   logic  [WIDTH_AD-1:0]      M0_AWADDR
        `ifdef AMBA_AXI4
        , input   logic  [ 7:0]              M0_AWLEN
        , input   logic                      M0_AWLOCK
        `else
        , input   logic  [ 3:0]              M0_AWLEN
        , input   logic  [ 1:0]              M0_AWLOCK
        `endif
        , input   logic  [ 2:0]              M0_AWSIZE
        , input   logic  [ 1:0]              M0_AWBURST
        `ifdef AMBA_AXI_CACHE
        , input   logic  [ 3:0]              M0_AWCACHE
        `endif
        `ifdef AMBA_AXI_PROT
        , input   logic  [ 2:0]              M0_AWPROT
        `endif
        , input   logic                      M0_AWVALID
        , output  logic                      M0_AWREADY
        `ifdef AMBA_AXI4
        , input   logic  [ 3:0]              M0_AWQOS
        , input   logic  [ 3:0]              M0_AWREGION
        `endif
        `ifdef AMBA_AXI_AWUSER
        , input   logic  [WIDTH_AWUSER-1:0]  M0_AWUSER
        `endif
        , input   logic  [WIDTH_ID-1:0]      M0_WID
        , input   logic  [WIDTH_DA-1:0]      M0_WDATA
        , input   logic  [WIDTH_DS-1:0]      M0_WSTRB
        , input   logic                      M0_WLAST
        , input   logic                      M0_WVALID
        , output  logic                      M0_WREADY
        `ifdef AMBA_AXI_WUSER
        , input   logic  [WIDTH_WUSER-1:0]   M0_WUSER
        `endif
        , output  logic  [WIDTH_ID-1:0]      M0_BID
        , output  logic  [ 1:0]              M0_BRESP
        , output  logic                      M0_BVALID
        , input   logic                      M0_BREADY
        `ifdef AMBA_AXI_BUSER
        , output  logic  [WIDTH_BUSER-1:0]   M0_BUSER
        `endif
        , input   logic  [WIDTH_ID-1:0]      M0_ARID
        , input   logic  [WIDTH_AD-1:0]      M0_ARADDR
        `ifdef AMBA_AXI4
        , input   logic  [ 7:0]              M0_ARLEN
        , input   logic                      M0_ARLOCK
        `else
        , input   logic  [ 3:0]              M0_ARLEN
        , input   logic  [ 1:0]              M0_ARLOCK
        `endif
        , input   logic  [ 2:0]              M0_ARSIZE
        , input   logic  [ 1:0]              M0_ARBURST
        `ifdef AMBA_AXI_CACHE
        , input   logic  [ 3:0]              M0_ARCACHE
        `endif
        `ifdef AMBA_AXI_PROT
        , input   logic  [ 2:0]              M0_ARPROT
        `endif
        , input   logic                      M0_ARVALID
        , output  logic                      M0_ARREADY
        `ifdef AMBA_AXI4
        , input   logic  [ 3:0]              M0_ARQOS
        , input   logic  [ 3:0]              M0_ARREGION
        `endif
        `ifdef AMBA_AXI_ARUSER
        , input   logic  [WIDTH_ARUSER-1:0]  M0_ARUSER
        `endif
        , output  logic  [WIDTH_ID-1:0]      M0_RID
        , output  logic  [WIDTH_DA-1:0]      M0_RDATA
        , output  logic  [ 1:0]              M0_RRESP
        , output  logic                      M0_RLAST
        , output  logic                      M0_RVALID
        , input   logic                      M0_RREADY
        `ifdef AMBA_AXI_RUSER
        , output  logic  [WIDTH_RUSER-1:0]   M0_RUSER
        `endif
        //--------------------------------------------------------------
        , input   logic  [WIDTH_CID-1:0]     M1_MID   // if not sure use 'h1
        , input   logic  [WIDTH_ID-1:0]      M1_AWID
        , input   logic  [WIDTH_AD-1:0]      M1_AWADDR
        `ifdef AMBA_AXI4
        , input   logic  [ 7:0]              M1_AWLEN
        , input   logic                      M1_AWLOCK
        `else
        , input   logic  [ 3:0]              M1_AWLEN
        , input   logic  [ 1:0]              M1_AWLOCK
        `endif
        , input   logic  [ 2:0]              M1_AWSIZE
        , input   logic  [ 1:0]              M1_AWBURST
        `ifdef AMBA_AXI_CACHE
        , input   logic  [ 3:0]              M1_AWCACHE
        `endif
        `ifdef AMBA_AXI_PROT
        , input   logic  [ 2:0]              M1_AWPROT
        `endif
        , input   logic                      M1_AWVALID
        , output  logic                      M1_AWREADY
        `ifdef AMBA_AXI4
        , input   logic  [ 3:0]              M1_AWQOS
        , input   logic  [ 3:0]              M1_AWREGION
        `endif
        `ifdef AMBA_AXI_AWUSER
        , input   logic  [WIDTH_AWUSER-1:0]  M1_AWUSER
        `endif
        , input   logic  [WIDTH_ID-1:0]      M1_WID
        , input   logic  [WIDTH_DA-1:0]      M1_WDATA
        , input   logic  [WIDTH_DS-1:0]      M1_WSTRB
        , input   logic                      M1_WLAST
        , input   logic                      M1_WVALID
        , output  logic                      M1_WREADY
        `ifdef AMBA_AXI_WUSER
        , input   logic  [WIDTH_WUSER-1:0]   M1_WUSER
        `endif
        , output  logic  [WIDTH_ID-1:0]      M1_BID
        , output  logic  [ 1:0]              M1_BRESP
        , output  logic                      M1_BVALID
        , input   logic                      M1_BREADY
        `ifdef AMBA_AXI_BUSER
        , output  logic  [WIDTH_BUSER-1:0]   M1_BUSER
        `endif
        , input   logic  [WIDTH_ID-1:0]      M1_ARID
        , input   logic  [WIDTH_AD-1:0]      M1_ARADDR
        `ifdef AMBA_AXI4
        , input   logic  [ 7:0]              M1_ARLEN
        , input   logic                      M1_ARLOCK
        `else
        , input   logic  [ 3:0]              M1_ARLEN
        , input   logic  [ 1:0]              M1_ARLOCK
        `endif
        , input   logic  [ 2:0]              M1_ARSIZE
        , input   logic  [ 1:0]              M1_ARBURST
        `ifdef AMBA_AXI_CACHE
        , input   logic  [ 3:0]              M1_ARCACHE
        `endif
        `ifdef AMBA_AXI_PROT
        , input   logic  [ 2:0]              M1_ARPROT
        `endif
        , input   logic                      M1_ARVALID
        , output  logic                      M1_ARREADY
        `ifdef AMBA_AXI4
        , input   logic  [ 3:0]              M1_ARQOS
        , input   logic  [ 3:0]              M1_ARREGION
        `endif
        `ifdef AMBA_AXI_ARUSER
        , input   logic  [WIDTH_ARUSER-1:0]  M1_ARUSER
        `endif
        , output  logic  [WIDTH_ID-1:0]      M1_RID
        , output  logic  [WIDTH_DA-1:0]      M1_RDATA
        , output  logic  [ 1:0]              M1_RRESP
        , output  logic                      M1_RLAST
        , output  logic                      M1_RVALID
        , input   logic                      M1_RREADY
        `ifdef AMBA_AXI_RUSER
        , output  logic  [WIDTH_RUSER-1:0]   M1_RUSER
        `endif
        //--------------------------------------------------------------
        , output  logic  [WIDTH_SID-1:0]     S0_AWID
        , output  logic  [WIDTH_AD-1:0]      S0_AWADDR
        `ifdef AMBA_AXI4
        , output  logic  [ 7:0]              S0_AWLEN
        , output  logic                      S0_AWLOCK
        `else
        , output  logic  [ 3:0]              S0_AWLEN
        , output  logic  [ 1:0]              S0_AWLOCK
        `endif
        , output  logic  [ 2:0]              S0_AWSIZE
        , output  logic  [ 1:0]              S0_AWBURST
        `ifdef AMBA_AXI_CACHE
        , output  logic  [ 3:0]              S0_AWCACHE
        `endif
        `ifdef AMBA_AXI_PROT
        , output  logic  [ 2:0]              S0_AWPROT
        `endif
        , output  logic                      S0_AWVALID
        , input   logic                      S0_AWREADY
        `ifdef AMBA_AXI4
        , output  logic  [ 3:0]              S0_AWQOS
        , output  logic  [ 3:0]              S0_AWREGION
        `endif
        `ifdef AMBA_AXI_AWUSER
        , output  logic  [WIDTH_AWUSER-1:0]  S0_AWUSER
        `endif
        , output  logic  [WIDTH_SID-1:0]     S0_WID
        , output  logic  [WIDTH_DA-1:0]      S0_WDATA
        , output  logic  [WIDTH_DS-1:0]      S0_WSTRB
        , output  logic                      S0_WLAST
        , output  logic                      S0_WVALID
        , input   logic                      S0_WREADY
        `ifdef AMBA_AXI_WUSER
        , output  logic  [WIDTH_WUSER-1:0]   S0_WUSER
        `endif
        , input   logic  [WIDTH_SID-1:0]     S0_BID
        , input   logic  [ 1:0]              S0_BRESP
        , input   logic                      S0_BVALID
        , output  logic                      S0_BREADY
        `ifdef AMBA_AXI_BUSER
        , input   logic  [WIDTH_BUSER-1:0]   S0_BUSER
        `endif
        , output  logic  [WIDTH_SID-1:0]     S0_ARID
        , output  logic  [WIDTH_AD-1:0]      S0_ARADDR
        `ifdef AMBA_AXI4
        , output  logic  [ 7:0]              S0_ARLEN
        , output  logic                      S0_ARLOCK
        `else
        , output  logic  [ 3:0]              S0_ARLEN
        , output  logic  [ 1:0]              S0_ARLOCK
        `endif
        , output  logic  [ 2:0]              S0_ARSIZE
        , output  logic  [ 1:0]              S0_ARBURST
        `ifdef AMBA_AXI_CACHE
        , output  logic  [ 3:0]              S0_ARCACHE
        `endif
        `ifdef AMBA_AXI_PROT
        , output  logic  [ 2:0]              S0_ARPROT
        `endif
        , output  logic                      S0_ARVALID
        , input   logic                      S0_ARREADY
        `ifdef AMBA_AXI4
        , output  logic  [ 3:0]              S0_ARQOS
        , output  logic  [ 3:0]              S0_ARREGION
        `endif
        `ifdef AMBA_AXI_ARUSER
        , output  logic  [WIDTH_ARUSER-1:0]  S0_ARUSER
        `endif
        , input   logic  [WIDTH_SID-1:0]     S0_RID
        , input   logic  [WIDTH_DA-1:0]      S0_RDATA
        , input   logic  [ 1:0]              S0_RRESP
        , input   logic                      S0_RLAST
        , input   logic                      S0_RVALID
        , output  logic                      S0_RREADY
        `ifdef AMBA_AXI_RUSER
        , input   logic  [WIDTH_RUSER-1:0]   S0_RUSER
        `endif
        //--------------------------------------------------------------
        , output  logic  [WIDTH_SID-1:0]     S1_AWID
        , output  logic  [WIDTH_AD-1:0]      S1_AWADDR
        `ifdef AMBA_AXI4
        , output  logic  [ 7:0]              S1_AWLEN
        , output  logic                      S1_AWLOCK
        `else
        , output  logic  [ 3:0]              S1_AWLEN
        , output  logic  [ 1:0]              S1_AWLOCK
        `endif
        , output  logic  [ 2:0]              S1_AWSIZE
        , output  logic  [ 1:0]              S1_AWBURST
        `ifdef AMBA_AXI_CACHE
        , output  logic  [ 3:0]              S1_AWCACHE
        `endif
        `ifdef AMBA_AXI_PROT
        , output  logic  [ 2:0]              S1_AWPROT
        `endif
        , output  logic                      S1_AWVALID
        , input   logic                      S1_AWREADY
        `ifdef AMBA_AXI4
        , output  logic  [ 3:0]              S1_AWQOS
        , output  logic  [ 3:0]              S1_AWREGION
        `endif
        `ifdef AMBA_AXI_AWUSER
        , output  logic  [WIDTH_AWUSER-1:0]  S1_AWUSER
        `endif
        , output  logic  [WIDTH_SID-1:0]     S1_WID
        , output  logic  [WIDTH_DA-1:0]      S1_WDATA
        , output  logic  [WIDTH_DS-1:0]      S1_WSTRB
        , output  logic                      S1_WLAST
        , output  logic                      S1_WVALID
        , input   logic                      S1_WREADY
        `ifdef AMBA_AXI_WUSER
        , output  logic  [WIDTH_WUSER-1:0]   S1_WUSER
        `endif
        , input   logic  [WIDTH_SID-1:0]     S1_BID
        , input   logic  [ 1:0]              S1_BRESP
        , input   logic                      S1_BVALID
        , output  logic                      S1_BREADY
        `ifdef AMBA_AXI_BUSER
        , input   logic  [WIDTH_BUSER-1:0]   S1_BUSER
        `endif
        , output  logic  [WIDTH_SID-1:0]     S1_ARID
        , output  logic  [WIDTH_AD-1:0]      S1_ARADDR
        `ifdef AMBA_AXI4
        , output  logic  [ 7:0]              S1_ARLEN
        , output  logic                      S1_ARLOCK
        `else
        , output  logic  [ 3:0]              S1_ARLEN
        , output  logic  [ 1:0]              S1_ARLOCK
        `endif
        , output  logic  [ 2:0]              S1_ARSIZE
        , output  logic  [ 1:0]              S1_ARBURST
        `ifdef AMBA_AXI_CACHE
        , output  logic  [ 3:0]              S1_ARCACHE
        `endif
        `ifdef AMBA_AXI_PROT
        , output  logic  [ 2:0]              S1_ARPROT
        `endif
        , output  logic                      S1_ARVALID
        , input   logic                      S1_ARREADY
        `ifdef AMBA_AXI4
        , output  logic  [ 3:0]              S1_ARQOS
        , output  logic  [ 3:0]              S1_ARREGION
        `endif
        `ifdef AMBA_AXI_ARUSER
        , output  logic  [WIDTH_ARUSER-1:0]  S1_ARUSER
        `endif
        , input   logic  [WIDTH_SID-1:0]     S1_RID
        , input   logic  [WIDTH_DA-1:0]      S1_RDATA
        , input   logic  [ 1:0]              S1_RRESP
        , input   logic                      S1_RLAST
        , input   logic                      S1_RVALID
        , output  logic                      S1_RREADY
        `ifdef AMBA_AXI_RUSER
        , input   logic  [WIDTH_RUSER-1:0]   S1_RUSER
        `endif
    );

    logic  [WIDTH_SID-1:0]     SD_AWID     ;
    logic  [WIDTH_AD-1:0]      SD_AWADDR   ;
    `ifdef AMBA_AXI4
    logic  [ 7:0]              SD_AWLEN    ;
    logic                      SD_AWLOCK   ;
    `else
    logic  [ 3:0]              SD_AWLEN    ;
    logic  [ 1:0]              SD_AWLOCK   ;
    `endif
    logic  [ 2:0]              SD_AWSIZE   ;
    logic  [ 1:0]              SD_AWBURST  ;
    `ifdef AMBA_AXI_CACHE
    logic  [ 3:0]              SD_AWCACHE  ;
    `endif
    `ifdef AMBA_AXI_PROT
    logic  [ 2:0]              SD_AWPROT   ;
    `endif
    logic                      SD_AWVALID  ;
    logic                      SD_AWREADY  ;
    `ifdef AMBA_AXI4
    logic  [ 3:0]              SD_AWQOS    ;
    logic  [ 3:0]              SD_AWREGION ;
    `endif
    logic  [WIDTH_SID-1:0]     SD_WID      ;
    logic  [WIDTH_DA-1:0]      SD_WDATA    ;
    logic  [WIDTH_DS-1:0]      SD_WSTRB    ;
    logic                      SD_WLAST    ;
    logic                      SD_WVALID   ;
    logic                      SD_WREADY   ;
    logic  [WIDTH_SID-1:0]     SD_BID      ;
    logic  [ 1:0]              SD_BRESP    ;
    logic                      SD_BVALID   ;
    logic                      SD_BREADY   ;
    logic  [WIDTH_SID-1:0]     SD_ARID     ;
    logic  [WIDTH_AD-1:0]      SD_ARADDR   ;
    `ifdef AMBA_AXI4
    logic  [ 7:0]              SD_ARLEN    ;
    logic                      SD_ARLOCK   ;
    `else
    logic  [ 3:0]              SD_ARLEN    ;
    logic  [ 1:0]              SD_ARLOCK   ;
    `endif
    logic  [ 2:0]              SD_ARSIZE   ;
    logic  [ 1:0]              SD_ARBURST  ;
    `ifdef AMBA_AXI_CACHE
    logic  [ 3:0]              SD_ARCACHE  ;
    `endif
    `ifdef AMBA_AXI_PROT
    logic  [ 2:0]              SD_ARPROT   ;
    `endif
    logic                      SD_ARVALID  ;
    logic                      SD_ARREADY  ;
    `ifdef AMBA_AXI4
    logic  [ 3:0]              SD_ARQOS    ;
    logic  [ 3:0]              SD_ARREGION ;
    `endif
    logic  [WIDTH_SID-1:0]     SD_RID      ;
    logic  [WIDTH_DA-1:0]      SD_RDATA    ;
    logic  [ 1:0]              SD_RRESP    ;
    logic                      SD_RLAST    ;
    logic                      SD_RVALID   ;
    logic                      SD_RREADY   ;


        // It is driven by axi_mtos_s?
    logic M0_AWREADY_S0, M0_AWREADY_S1, M0_AWREADY_SD;
    logic M0_WREADY_S0 , M0_WREADY_S1 , M0_WREADY_SD ;
    logic M0_ARREADY_S0, M0_ARREADY_S1, M0_ARREADY_SD;
    logic M1_AWREADY_S0, M1_AWREADY_S1, M1_AWREADY_SD;
    logic M1_WREADY_S0 , M1_WREADY_S1 , M1_WREADY_SD ;
    logic M1_ARREADY_S0, M1_ARREADY_S1, M1_ARREADY_SD;

    assign M0_AWREADY = M0_AWREADY_S0|M0_AWREADY_S1|M0_AWREADY_SD;
    assign M0_WREADY  = M0_WREADY_S0 |M0_WREADY_S1 |M0_WREADY_SD ;
    assign M0_ARREADY = M0_ARREADY_S0|M0_ARREADY_S1|M0_ARREADY_SD;
    assign M1_AWREADY = M1_AWREADY_S0|M1_AWREADY_S1|M1_AWREADY_SD;
    assign M1_WREADY  = M1_WREADY_S0 |M1_WREADY_S1 |M1_WREADY_SD ;
    assign M1_ARREADY = M1_ARREADY_S0|M1_ARREADY_S1|M1_ARREADY_SD;  

        // It is driven by axi_stom_m?
    logic S0_BREADY_M0, S0_BREADY_M1;
    logic S0_RREADY_M0, S0_RREADY_M1;
    logic S1_BREADY_M0, S1_BREADY_M1;
    logic S1_RREADY_M0, S1_RREADY_M1;
    logic SD_BREADY_M0, SD_BREADY_M1;
    logic SD_RREADY_M0, SD_RREADY_M1;

    assign S0_BREADY = S0_BREADY_M0|S0_BREADY_M1;
    assign S0_RREADY = S0_RREADY_M0|S0_RREADY_M1;
    assign S1_BREADY = S1_BREADY_M0|S1_BREADY_M1;
    assign S1_RREADY = S1_RREADY_M0|S1_RREADY_M1;
    assign SD_BREADY = SD_BREADY_M0|SD_BREADY_M1;
    assign SD_RREADY = SD_RREADY_M0|SD_RREADY_M1;


    //-----------------------------------------------------------
    // drivne by axi_mtos_m2
    logic [NUM_MASTER-1:0] AWSELECT_OUT[0:NUM_SLAVE-1];
    logic [NUM_MASTER-1:0] ARSELECT_OUT[0:NUM_SLAVE-1];
    //-----------------------------------------------------------
    logic [NUM_MASTER-1:0] AWSELECT; // goes to default slave
    logic [NUM_MASTER-1:0] ARSELECT; // goes to default slave
    //-----------------------------------------------------------
    assign AWSELECT[0] = AWSELECT_OUT[0][0]|AWSELECT_OUT[1][0];
    assign AWSELECT[1] = AWSELECT_OUT[0][1]|AWSELECT_OUT[1][1];
    assign ARSELECT[0] = ARSELECT_OUT[0][0]|ARSELECT_OUT[1][0];
    assign ARSELECT[1] = ARSELECT_OUT[0][1]|ARSELECT_OUT[1][1];
    //-----------------------------------------------------------

    // masters to slave for the first slave
    axi_mtos_m2 #(.SLAVE_ID    (0           )
                ,.SLAVE_EN    (SLAVE_EN0   )
                ,.ADDR_BASE   (ADDR_BASE0  )
                ,.ADDR_LENGTH (ADDR_LENGTH0)
                ,.WIDTH_CID   (WIDTH_CID   )
                ,.WIDTH_ID    (WIDTH_ID    )
                ,.WIDTH_AD    (WIDTH_AD    )
                ,.WIDTH_DA    (WIDTH_DA    )
                ,.WIDTH_DS    (WIDTH_DS    )
                ,.WIDTH_SID   (WIDTH_SID   )
                ,.WIDTH_AWUSER(WIDTH_AWUSER)
                ,.WIDTH_WUSER (WIDTH_WUSER )
                ,.WIDTH_ARUSER(WIDTH_ARUSER)
                ,.SLAVE_DEFAULT(1'b0)
                )
    Uaxi_mtos_s0 (
        .ARESETn              (ARESETn      )
        , .ACLK                 (ACLK         )
        , .M0_MID               (M0_MID       )
        , .M0_AWID              (M0_AWID      )
        , .M0_AWADDR            (M0_AWADDR    )
        , .M0_AWLEN             (M0_AWLEN     )
        , .M0_AWLOCK            (M0_AWLOCK    )
        , .M0_AWSIZE            (M0_AWSIZE    )
        , .M0_AWBURST           (M0_AWBURST   )
        `ifdef AMBA_AXI_CACHE
        , .M0_AWCACHE           (M0_AWCACHE   )
        `endif
        `ifdef AMBA_AXI_PROT
        , .M0_AWPROT            (M0_AWPROT    )
        `endif
        , .M0_AWVALID           (M0_AWVALID   )
        , .M0_AWREADY           (M0_AWREADY_S0)
        `ifdef AMBA_AXI4
        , .M0_AWQOS             (M0_AWQOS     )
        , .M0_AWREGION          (M0_AWREGION  )
        `endif
        `ifdef AMBA_AXI_AWUSER
        , .M0_AWUSER            (M0_AWUSER    )
        `endif
        , .M0_WID               (M0_WID       )
        , .M0_WDATA             (M0_WDATA     )
        , .M0_WSTRB             (M0_WSTRB     )
        , .M0_WLAST             (M0_WLAST     )
        , .M0_WVALID            (M0_WVALID    )
        , .M0_WREADY            (M0_WREADY_S0 )
        `ifdef AMBA_AXI_WUSER
        , .M0_WUSER             (M0_WUSER     )
        `endif
        , .M0_ARID              (M0_ARID      )
        , .M0_ARADDR            (M0_ARADDR    )
        , .M0_ARLEN             (M0_ARLEN     )
        , .M0_ARLOCK            (M0_ARLOCK    )
        , .M0_ARSIZE            (M0_ARSIZE    )
        , .M0_ARBURST           (M0_ARBURST   )
        `ifdef AMBA_AXI_CACHE
        , .M0_ARCACHE           (M0_ARCACHE   )
        `endif
        `ifdef AMBA_AXI_PROT
        , .M0_ARPROT            (M0_ARPROT    )
        `endif
        , .M0_ARVALID           (M0_ARVALID   )
        , .M0_ARREADY           (M0_ARREADY_S0)
        `ifdef AMBA_AXI4
        , .M0_ARQOS             (M0_ARQOS     )
        , .M0_ARREGION          (M0_ARREGION  )
        `endif
        `ifdef AMBA_AXI_ARUSER
        , .M0_ARUSER            (M0_ARUSER    )
        `endif
        , .M1_MID               (M1_MID       )
        , .M1_AWID              (M1_AWID      )
        , .M1_AWADDR            (M1_AWADDR    )
        , .M1_AWLEN             (M1_AWLEN     )
        , .M1_AWLOCK            (M1_AWLOCK    )
        , .M1_AWSIZE            (M1_AWSIZE    )
        , .M1_AWBURST           (M1_AWBURST   )
        `ifdef AMBA_AXI_CACHE
        , .M1_AWCACHE           (M1_AWCACHE   )
        `endif
        `ifdef AMBA_AXI_PROT
        , .M1_AWPROT            (M1_AWPROT    )
        `endif
        , .M1_AWVALID           (M1_AWVALID   )
        , .M1_AWREADY           (M1_AWREADY_S0)
        `ifdef AMBA_AXI4
        , .M1_AWQOS             (M1_AWQOS     )
        , .M1_AWREGION          (M1_AWREGION  )
        `endif
        `ifdef AMBA_AXI_AWUSER
        , .M1_AWUSER            (M1_AWUSER    )
        `endif
        , .M1_WID               (M1_WID       )
        , .M1_WDATA             (M1_WDATA     )
        , .M1_WSTRB             (M1_WSTRB     )
        , .M1_WLAST             (M1_WLAST     )
        , .M1_WVALID            (M1_WVALID    )
        , .M1_WREADY            (M1_WREADY_S0 )
        `ifdef AMBA_AXI_WUSER
        , .M1_WUSER             (M1_WUSER     )
        `endif
        , .M1_ARID              (M1_ARID      )
        , .M1_ARADDR            (M1_ARADDR    )
        , .M1_ARLEN             (M1_ARLEN     )
        , .M1_ARLOCK            (M1_ARLOCK    )
        , .M1_ARSIZE            (M1_ARSIZE    )
        , .M1_ARBURST           (M1_ARBURST   )
        `ifdef AMBA_AXI_CACHE
        , .M1_ARCACHE           (M1_ARCACHE   )
        `endif
        `ifdef AMBA_AXI_PROT
        , .M1_ARPROT            (M1_ARPROT    )
        `endif
        , .M1_ARVALID           (M1_ARVALID   )
        , .M1_ARREADY           (M1_ARREADY_S0)
        `ifdef AMBA_AXI4
        , .M1_ARQOS             (M1_ARQOS     )
        , .M1_ARREGION          (M1_ARREGION  )
        `endif
        `ifdef AMBA_AXI_ARUSER
        , .M1_ARUSER            (M1_ARUSER    )
        `endif
        , .S_AWID               (S0_AWID      )
        , .S_AWADDR             (S0_AWADDR    )
        , .S_AWLEN              (S0_AWLEN     )
        , .S_AWLOCK             (S0_AWLOCK    )
        , .S_AWSIZE             (S0_AWSIZE    )
        , .S_AWBURST            (S0_AWBURST   )
        `ifdef AMBA_AXI_CACHE
        , .S_AWCACHE            (S0_AWCACHE   )
        `endif
        `ifdef AMBA_AXI_PROT
        , .S_AWPROT             (S0_AWPROT    )
        `endif
        , .S_AWVALID            (S0_AWVALID   )
        , .S_AWREADY            (S0_AWREADY   )
        `ifdef AMBA_AXI4
        , .S_AWQOS              (S0_AWQOS     )
        , .S_AWREGION           (S0_AWREGION  )
        `endif
        `ifdef AMBA_AXI_AWUSER
        , .S_AWUSER             (S0_AWUSER    )
        `endif
        , .S_WID                (S0_WID       )
        , .S_WDATA              (S0_WDATA     )
        , .S_WSTRB              (S0_WSTRB     )
        , .S_WLAST              (S0_WLAST     )
        , .S_WVALID             (S0_WVALID    )
        , .S_WREADY             (S0_WREADY    )
        `ifdef AMBA_AXI_WUSER
        , .S_WUSER              (S0_WUSER     )
        `endif
        , .S_ARID               (S0_ARID      )
        , .S_ARADDR             (S0_ARADDR    )
        , .S_ARLEN              (S0_ARLEN     )
        , .S_ARLOCK             (S0_ARLOCK    )
        , .S_ARSIZE             (S0_ARSIZE    )
        , .S_ARBURST            (S0_ARBURST   )
        `ifdef AMBA_AXI_CACHE
        , .S_ARCACHE            (S0_ARCACHE   )
        `endif
        `ifdef AMBA_AXI_PROT
        , .S_ARPROT             (S0_ARPROT    )
        `endif
        , .S_ARVALID            (S0_ARVALID   )
        , .S_ARREADY            (S0_ARREADY   )
        `ifdef AMBA_AXI4
        , .S_ARQOS              (S0_ARQOS     )
        , .S_ARREGION           (S0_ARREGION  )
        `endif
        `ifdef AMBA_AXI_ARUSER
        , .S_ARUSER             (S0_ARUSER    )
        `endif
        , .AWSELECT_OUT         (AWSELECT_OUT[0])
        , .ARSELECT_OUT         (ARSELECT_OUT[0])
        , .AWSELECT_IN          (AWSELECT_OUT[0])// not used since non-default-slave
        , .ARSELECT_IN          (ARSELECT_OUT[0])// not used since non-default-slave
    );

    // masters to slave for the second slave
    axi_mtos_m2 #(.SLAVE_ID    (1           )
                ,.SLAVE_EN    (SLAVE_EN1   )
                ,.ADDR_BASE   (ADDR_BASE1  )
                ,.ADDR_LENGTH (ADDR_LENGTH1)
                ,.WIDTH_CID   (WIDTH_CID   )
                ,.WIDTH_ID    (WIDTH_ID    )
                ,.WIDTH_AD    (WIDTH_AD    )
                ,.WIDTH_DA    (WIDTH_DA    )
                ,.WIDTH_DS    (WIDTH_DS    )
                ,.WIDTH_SID   (WIDTH_SID   )
                ,.WIDTH_AWUSER(WIDTH_AWUSER)
                ,.WIDTH_WUSER (WIDTH_WUSER )
                ,.WIDTH_ARUSER(WIDTH_ARUSER)
                ,.SLAVE_DEFAULT(1'b0)
                )
    Uaxi_mtos_s1 (
        .ARESETn              (ARESETn      )
        , .ACLK                 (ACLK         )
        , .M0_MID               (M0_MID       )
        , .M0_AWID              (M0_AWID      )
        , .M0_AWADDR            (M0_AWADDR    )
        , .M0_AWLEN             (M0_AWLEN     )
        , .M0_AWLOCK            (M0_AWLOCK    )
        , .M0_AWSIZE            (M0_AWSIZE    )
        , .M0_AWBURST           (M0_AWBURST   )
        `ifdef AMBA_AXI_CACHE
        , .M0_AWCACHE           (M0_AWCACHE   )
        `endif
        `ifdef AMBA_AXI_PROT
        , .M0_AWPROT            (M0_AWPROT    )
        `endif
        , .M0_AWVALID           (M0_AWVALID   )
        , .M0_AWREADY           (M0_AWREADY_S1)
        `ifdef AMBA_AXI4
        , .M0_AWQOS             (M0_AWQOS     )
        , .M0_AWREGION          (M0_AWREGION  )
        `endif
        `ifdef AMBA_AXI_AWUSER
        , .M0_AWUSER            (M0_AWUSER    )
        `endif
        , .M0_WID               (M0_WID       )
        , .M0_WDATA             (M0_WDATA     )
        , .M0_WSTRB             (M0_WSTRB     )
        , .M0_WLAST             (M0_WLAST     )
        , .M0_WVALID            (M0_WVALID    )
        , .M0_WREADY            (M0_WREADY_S1 )
        `ifdef AMBA_AXI_WUSER
        , .M0_WUSER             (M0_WUSER     )
        `endif
        , .M0_ARID              (M0_ARID      )
        , .M0_ARADDR            (M0_ARADDR    )
        , .M0_ARLEN             (M0_ARLEN     )
        , .M0_ARLOCK            (M0_ARLOCK    )
        , .M0_ARSIZE            (M0_ARSIZE    )
        , .M0_ARBURST           (M0_ARBURST   )
        `ifdef AMBA_AXI_CACHE
        , .M0_ARCACHE           (M0_ARCACHE   )
        `endif
        `ifdef AMBA_AXI_PROT
        , .M0_ARPROT            (M0_ARPROT    )
        `endif
        , .M0_ARVALID           (M0_ARVALID   )
        , .M0_ARREADY           (M0_ARREADY_S1)
        `ifdef AMBA_AXI4
        , .M0_ARQOS             (M0_ARQOS     )
        , .M0_ARREGION          (M0_ARREGION  )
        `endif
        `ifdef AMBA_AXI_ARUSER
        , .M0_ARUSER            (M0_ARUSER    )
        `endif
        , .M1_MID               (M1_MID       )
        , .M1_AWID              (M1_AWID      )
        , .M1_AWADDR            (M1_AWADDR    )
        , .M1_AWLEN             (M1_AWLEN     )
        , .M1_AWLOCK            (M1_AWLOCK    )
        , .M1_AWSIZE            (M1_AWSIZE    )
        , .M1_AWBURST           (M1_AWBURST   )
        `ifdef AMBA_AXI_CACHE
        , .M1_AWCACHE           (M1_AWCACHE   )
        `endif
        `ifdef AMBA_AXI_PROT
        , .M1_AWPROT            (M1_AWPROT    )
        `endif
        , .M1_AWVALID           (M1_AWVALID   )
        , .M1_AWREADY           (M1_AWREADY_S1)
        `ifdef AMBA_AXI4
        , .M1_AWQOS             (M1_AWQOS     )
        , .M1_AWREGION          (M1_AWREGION  )
        `endif
        `ifdef AMBA_AXI_AWUSER
        , .M1_AWUSER            (M1_AWUSER    )
        `endif
        , .M1_WID               (M1_WID       )
        , .M1_WDATA             (M1_WDATA     )
        , .M1_WSTRB             (M1_WSTRB     )
        , .M1_WLAST             (M1_WLAST     )
        , .M1_WVALID            (M1_WVALID    )
        , .M1_WREADY            (M1_WREADY_S1 )
        `ifdef AMBA_AXI_WUSER
        , .M1_WUSER             (M1_WUSER     )
        `endif
        , .M1_ARID              (M1_ARID      )
        , .M1_ARADDR            (M1_ARADDR    )
        , .M1_ARLEN             (M1_ARLEN     )
        , .M1_ARLOCK            (M1_ARLOCK    )
        , .M1_ARSIZE            (M1_ARSIZE    )
        , .M1_ARBURST           (M1_ARBURST   )
        `ifdef AMBA_AXI_CACHE
        , .M1_ARCACHE           (M1_ARCACHE   )
        `endif
        `ifdef AMBA_AXI_PROT
        , .M1_ARPROT            (M1_ARPROT    )
        `endif
        , .M1_ARVALID           (M1_ARVALID   )
        , .M1_ARREADY           (M1_ARREADY_S1)
        `ifdef AMBA_AXI4
        , .M1_ARQOS             (M1_ARQOS     )
        , .M1_ARREGION          (M1_ARREGION  )
        `endif
        `ifdef AMBA_AXI_ARUSER
        , .M1_ARUSER            (M1_ARUSER    )
        `endif
        , .S_AWID               (S1_AWID      )
        , .S_AWADDR             (S1_AWADDR    )
        , .S_AWLEN              (S1_AWLEN     )
        , .S_AWLOCK             (S1_AWLOCK    )
        , .S_AWSIZE             (S1_AWSIZE    )
        , .S_AWBURST            (S1_AWBURST   )
        `ifdef AMBA_AXI_CACHE
        , .S_AWCACHE            (S1_AWCACHE   )
        `endif
        `ifdef AMBA_AXI_PROT
        , .S_AWPROT             (S1_AWPROT    )
        `endif
        , .S_AWVALID            (S1_AWVALID   )
        , .S_AWREADY            (S1_AWREADY   )
        `ifdef AMBA_AXI4
        , .S_AWQOS              (S1_AWQOS     )
        , .S_AWREGION           (S1_AWREGION  )
        `endif
        `ifdef AMBA_AXI_AWUSER
        , .S_AWUSER             (S1_AWUSER    )
        `endif
        , .S_WID                (S1_WID       )
        , .S_WDATA              (S1_WDATA     )
        , .S_WSTRB              (S1_WSTRB     )
        , .S_WLAST              (S1_WLAST     )
        , .S_WVALID             (S1_WVALID    )
        , .S_WREADY             (S1_WREADY    )
        `ifdef AMBA_AXI_WUSER
        , .S_WUSER              (S1_WUSER     )
        `endif
        , .S_ARID               (S1_ARID      )
        , .S_ARADDR             (S1_ARADDR    )
        , .S_ARLEN              (S1_ARLEN     )
        , .S_ARLOCK             (S1_ARLOCK    )
        , .S_ARSIZE             (S1_ARSIZE    )
        , .S_ARBURST            (S1_ARBURST   )
        `ifdef AMBA_AXI_CACHE
        , .S_ARCACHE            (S1_ARCACHE   )
        `endif
        `ifdef AMBA_AXI_PROT
        , .S_ARPROT             (S1_ARPROT    )
        `endif
        , .S_ARVALID            (S1_ARVALID   )
        , .S_ARREADY            (S1_ARREADY   )
        `ifdef AMBA_AXI4
        , .S_ARQOS              (S1_ARQOS     )
        , .S_ARREGION           (S1_ARREGION  )
        `endif
        `ifdef AMBA_AXI_ARUSER
        , .S_ARUSER             (S1_ARUSER    )
        `endif
        , .AWSELECT_OUT         (AWSELECT_OUT[1])
        , .ARSELECT_OUT         (ARSELECT_OUT[1])
        , .AWSELECT_IN          (AWSELECT_OUT[1])// not used since non-default-slave
        , .ARSELECT_IN          (ARSELECT_OUT[1])// not used since non-default-slave
    );

    // masters to slave for default slave
    axi_mtos_m2 #(.SLAVE_ID    (1           )
                ,.SLAVE_EN    (1'b1        ) // always enabled
                ,.ADDR_BASE   (ADDR_BASE1  )
                ,.ADDR_LENGTH (ADDR_LENGTH1)
                ,.WIDTH_CID   (WIDTH_CID   )
                ,.WIDTH_ID    (WIDTH_ID    )
                ,.WIDTH_AD    (WIDTH_AD    )
                ,.WIDTH_DA    (WIDTH_DA    )
                ,.WIDTH_DS    (WIDTH_DS    )
                ,.WIDTH_SID   (WIDTH_SID   )
                ,.WIDTH_AWUSER(WIDTH_AWUSER)
                ,.WIDTH_WUSER (WIDTH_WUSER )
                ,.WIDTH_ARUSER(WIDTH_ARUSER)
                ,.SLAVE_DEFAULT(1'b1)
                )
    Uaxi_mtos_sd (
        .ARESETn              (ARESETn      )
        , .ACLK                 (ACLK         )
        , .M0_MID               (M0_MID       )
        , .M0_AWID              (M0_AWID      )
        , .M0_AWADDR            (M0_AWADDR    )
        , .M0_AWLEN             (M0_AWLEN     )
        , .M0_AWLOCK            (M0_AWLOCK    )
        , .M0_AWSIZE            (M0_AWSIZE    )
        , .M0_AWBURST           (M0_AWBURST   )
        `ifdef AMBA_AXI_CACHE
        , .M0_AWCACHE           (M0_AWCACHE   )
        `endif
        `ifdef AMBA_AXI_PROT
        , .M0_AWPROT            (M0_AWPROT    )
        `endif
        , .M0_AWVALID           (M0_AWVALID   )
        , .M0_AWREADY           (M0_AWREADY_SD)
        `ifdef AMBA_AXI4
        , .M0_AWQOS             (M0_AWQOS     )
        , .M0_AWREGION          (M0_AWREGION  )
        `endif
        `ifdef AMBA_AXI_AWUSER
        , .M0_AWUSER            (M0_AWUSER    )
        `endif
        , .M0_WID               (M0_WID       )
        , .M0_WDATA             (M0_WDATA     )
        , .M0_WSTRB             (M0_WSTRB     )
        , .M0_WLAST             (M0_WLAST     )
        , .M0_WVALID            (M0_WVALID    )
        , .M0_WREADY            (M0_WREADY_SD )
        `ifdef AMBA_AXI_WUSER
        , .M0_WUSER             (M0_WUSER     )
        `endif
        , .M0_ARID              (M0_ARID      )
        , .M0_ARADDR            (M0_ARADDR    )
        , .M0_ARLEN             (M0_ARLEN     )
        , .M0_ARLOCK            (M0_ARLOCK    )
        , .M0_ARSIZE            (M0_ARSIZE    )
        , .M0_ARBURST           (M0_ARBURST   )
        `ifdef AMBA_AXI_CACHE
        , .M0_ARCACHE           (M0_ARCACHE   )
        `endif
        `ifdef AMBA_AXI_PROT
        , .M0_ARPROT            (M0_ARPROT    )
        `endif
        , .M0_ARVALID           (M0_ARVALID   )
        , .M0_ARREADY           (M0_ARREADY_SD)
        `ifdef AMBA_AXI4
        , .M0_ARQOS             (M0_ARQOS     )
        , .M0_ARREGION          (M0_ARREGION  )
        `endif
        `ifdef AMBA_AXI_ARUSER
        , .M0_ARUSER            (M0_ARUSER    )
        `endif
        , .M1_MID               (M1_MID       )
        , .M1_AWID              (M1_AWID      )
        , .M1_AWADDR            (M1_AWADDR    )
        , .M1_AWLEN             (M1_AWLEN     )
        , .M1_AWLOCK            (M1_AWLOCK    )
        , .M1_AWSIZE            (M1_AWSIZE    )
        , .M1_AWBURST           (M1_AWBURST   )
        `ifdef AMBA_AXI_CACHE
        , .M1_AWCACHE           (M1_AWCACHE   )
        `endif
        `ifdef AMBA_AXI_PROT
        , .M1_AWPROT            (M1_AWPROT    )
        `endif
        , .M1_AWVALID           (M1_AWVALID   )
        , .M1_AWREADY           (M1_AWREADY_SD)
        `ifdef AMBA_AXI4
        , .M1_AWQOS             (M1_AWQOS     )
        , .M1_AWREGION          (M1_AWREGION  )
        `endif
        `ifdef AMBA_AXI_AWUSER
        , .M1_AWUSER            (M1_AWUSER    )
        `endif
        , .M1_WID               (M1_WID       )
        , .M1_WDATA             (M1_WDATA     )
        , .M1_WSTRB             (M1_WSTRB     )
        , .M1_WLAST             (M1_WLAST     )
        , .M1_WVALID            (M1_WVALID    )
        , .M1_WREADY            (M1_WREADY_SD )
        `ifdef AMBA_AXI_WUSER
        , .M1_WUSER             (M1_WUSER     )
        `endif
        , .M1_ARID              (M1_ARID      )
        , .M1_ARADDR            (M1_ARADDR    )
        , .M1_ARLEN             (M1_ARLEN     )
        , .M1_ARLOCK            (M1_ARLOCK    )
        , .M1_ARSIZE            (M1_ARSIZE    )
        , .M1_ARBURST           (M1_ARBURST   )
        `ifdef AMBA_AXI_CACHE
        , .M1_ARCACHE           (M1_ARCACHE   )
        `endif
        `ifdef AMBA_AXI_PROT
        , .M1_ARPROT            (M1_ARPROT    )
        `endif
        , .M1_ARVALID           (M1_ARVALID   )
        , .M1_ARREADY           (M1_ARREADY_SD)
        `ifdef AMBA_AXI4
        , .M1_ARQOS             (M1_ARQOS     )
        , .M1_ARREGION          (M1_ARREGION  )
        `endif
        `ifdef AMBA_AXI_ARUSER
        , .M1_ARUSER            (M1_ARUSER    )
        `endif
        , .S_AWID               (SD_AWID      )
        , .S_AWADDR             (SD_AWADDR    )
        , .S_AWLEN              (SD_AWLEN     )
        , .S_AWLOCK             (SD_AWLOCK    )
        , .S_AWSIZE             (SD_AWSIZE    )
        , .S_AWBURST            (SD_AWBURST   )
        `ifdef AMBA_AXI_CACHE
        , .S_AWCACHE            (SD_AWCACHE   )
        `endif
        `ifdef AMBA_AXI_PROT
        , .S_AWPROT             (SD_AWPROT    )
        `endif
        , .S_AWVALID            (SD_AWVALID   )
        , .S_AWREADY            (SD_AWREADY   )
        `ifdef AMBA_AXI4
        , .S_AWQOS              (SD_AWQOS     )
        , .S_AWREGION           (SD_AWREGION  )
        `endif
        `ifdef AMBA_AXI_AWUSER
        , .S_AWUSER             (SD_AWUSER    )
        `endif
        , .S_WID                (SD_WID       )
        , .S_WDATA              (SD_WDATA     )
        , .S_WSTRB              (SD_WSTRB     )
        , .S_WLAST              (SD_WLAST     )
        , .S_WVALID             (SD_WVALID    )
        , .S_WREADY             (SD_WREADY    )
        `ifdef AMBA_AXI_WUSER
        , .S_WUSER              (SD_WUSER     )
        `endif
        , .S_ARID               (SD_ARID      )
        , .S_ARADDR             (SD_ARADDR    )
        , .S_ARLEN              (SD_ARLEN     )
        , .S_ARLOCK             (SD_ARLOCK    )
        , .S_ARSIZE             (SD_ARSIZE    )
        , .S_ARBURST            (SD_ARBURST   )
        `ifdef AMBA_AXI_CACHE
        , .S_ARCACHE            (SD_ARCACHE   )
        `endif
        `ifdef AMBA_AXI_PROT
        , .S_ARPROT             (SD_ARPROT    )
        `endif
        , .S_ARVALID            (SD_ARVALID   )
        , .S_ARREADY            (SD_ARREADY   )
        `ifdef AMBA_AXI4
        , .S_ARQOS              (SD_ARQOS     )
        , .S_ARREGION           (SD_ARREGION  )
        `endif
        `ifdef AMBA_AXI_ARUSER
        , .S_ARUSER             (SD_ARUSER    )
        `endif
        , .AWSELECT_OUT         (             )// not used since default-slave
        , .ARSELECT_OUT         (             )// not used since default-slave
        , .AWSELECT_IN          (AWSELECT     )
        , .ARSELECT_IN          (ARSELECT     )
    );

    // slaves to master for the first master
    axi_stom_s2 #(.WIDTH_CID   (WIDTH_CID   )
                ,.WIDTH_ID    (WIDTH_ID    )
                ,.WIDTH_AD    (WIDTH_AD    )
                ,.WIDTH_DA    (WIDTH_DA    )
                ,.WIDTH_DS    (WIDTH_DS    )
                ,.WIDTH_SID   (WIDTH_SID   )
                ,.WIDTH_BUSER (WIDTH_BUSER)
                ,.WIDTH_RUSER (WIDTH_RUSER )
                )
    Uaxi_stom_m0 (
        .ARESETn              (ARESETn     )
        , .ACLK                 (ACLK        )
        , .M_MID                (M0_MID      )
        , .M_BID                (M0_BID      )
        , .M_BRESP              (M0_BRESP    )
        , .M_BVALID             (M0_BVALID   )
        , .M_BREADY             (M0_BREADY   )
        `ifdef AMBA_AXI_BUSER
        , .M_BUSER              (M0_BUSER    )
        `endif
        , .M_RID                (M0_RID      )
        , .M_RDATA              (M0_RDATA    )
        , .M_RRESP              (M0_RRESP    )
        , .M_RLAST              (M0_RLAST    )
        , .M_RVALID             (M0_RVALID   )
        , .M_RREADY             (M0_RREADY   )
        `ifdef AMBA_AXI_RUSER
        , .M_RUSER              (M0_RUSER    )
        `endif
        , .S0_BID               (S0_BID      )
        , .S0_BRESP             (S0_BRESP    )
        , .S0_BVALID            (S0_BVALID   )
        , .S0_BREADY            (S0_BREADY_M0)
        `ifdef AMBA_AXI_BUSER
        , .S0_BUSER             (S0_BUSER    )
        `endif
        , .S0_RID               (S0_RID      )
        , .S0_RDATA             (S0_RDATA    )
        , .S0_RRESP             (S0_RRESP    )
        , .S0_RLAST             (S0_RLAST    )
        , .S0_RVALID            (S0_RVALID   )
        , .S0_RREADY            (S0_RREADY_M0)
        `ifdef AMBA_AXI_RUSER
        , .S0_RUSER             (S0_RUSER    )
        `endif
        , .S1_BID               (S1_BID      )
        , .S1_BRESP             (S1_BRESP    )
        , .S1_BVALID            (S1_BVALID   )
        , .S1_BREADY            (S1_BREADY_M0)
        `ifdef AMBA_AXI_BUSER
        , .S1_BUSER             (S1_BUSER    )
        `endif
        , .S1_RID               (S1_RID      )
        , .S1_RDATA             (S1_RDATA    )
        , .S1_RRESP             (S1_RRESP    )
        , .S1_RLAST             (S1_RLAST    )
        , .S1_RVALID            (S1_RVALID   )
        , .S1_RREADY            (S1_RREADY_M0)
        `ifdef AMBA_AXI_RUSER
        , .S1_RUSER             (S1_RUSER    )
        `endif
        , .SD_BID               (SD_BID      )
        , .SD_BRESP             (SD_BRESP    )
        , .SD_BVALID            (SD_BVALID   )
        , .SD_BREADY            (SD_BREADY_M0)
        `ifdef AMBA_AXI_BUSER
        , .SD_BUSER             (SD_BUSER    )
        `endif
        , .SD_RID               (SD_RID      )
        , .SD_RDATA             (SD_RDATA    )
        , .SD_RRESP             (SD_RRESP    )
        , .SD_RLAST             (SD_RLAST    )
        , .SD_RVALID            (SD_RVALID   )
        , .SD_RREADY            (SD_RREADY_M0)
        `ifdef AMBA_AXI_RUSER
        , .SD_RUSER             (SD_RUSER    )
        `endif
    );

// slaves to master for the second master
    axi_stom_s2 #(.WIDTH_CID   (WIDTH_CID   )
                ,.WIDTH_ID    (WIDTH_ID    )
                ,.WIDTH_AD    (WIDTH_AD    )
                ,.WIDTH_DA    (WIDTH_DA    )
                ,.WIDTH_DS    (WIDTH_DS    )
                ,.WIDTH_SID   (WIDTH_SID   )
                ,.WIDTH_BUSER (WIDTH_BUSER)
                ,.WIDTH_RUSER (WIDTH_RUSER )
                )
    Uaxi_stom_m1 (
        .ARESETn              (ARESETn     )
        , .ACLK                 (ACLK        )
        , .M_MID                (M1_MID      )
        , .M_BID                (M1_BID      )
        , .M_BRESP              (M1_BRESP    )
        , .M_BVALID             (M1_BVALID   )
        , .M_BREADY             (M1_BREADY   )
        `ifdef AMBA_AXI_BUSER
        , .M_BUSER              (M1_BUSER    )
        `endif
        , .M_RID                (M1_RID      )
        , .M_RDATA              (M1_RDATA    )
        , .M_RRESP              (M1_RRESP    )
        , .M_RLAST              (M1_RLAST    )
        , .M_RVALID             (M1_RVALID   )
        , .M_RREADY             (M1_RREADY   )
        `ifdef AMBA_AXI_RUSER
        , .M_RUSER              (M1_RUSER    )
        `endif
        , .S0_BID               (S0_BID      )
        , .S0_BRESP             (S0_BRESP    )
        , .S0_BVALID            (S0_BVALID   )
        , .S0_BREADY            (S0_BREADY_M1)
        `ifdef AMBA_AXI_BUSER
        , .S0_BUSER             (S0_BUSER    )
        `endif
        , .S0_RID               (S0_RID      )
        , .S0_RDATA             (S0_RDATA    )
        , .S0_RRESP             (S0_RRESP    )
        , .S0_RLAST             (S0_RLAST    )
        , .S0_RVALID            (S0_RVALID   )
        , .S0_RREADY            (S0_RREADY_M1)
        `ifdef AMBA_AXI_RUSER
        , .S0_RUSER             (S0_RUSER    )
        `endif
        , .S1_BID               (S1_BID      )
        , .S1_BRESP             (S1_BRESP    )
        , .S1_BVALID            (S1_BVALID   )
        , .S1_BREADY            (S1_BREADY_M1)
        `ifdef AMBA_AXI_BUSER
        , .S1_BUSER             (S1_BUSER    )
        `endif
        , .S1_RID               (S1_RID      )
        , .S1_RDATA             (S1_RDATA    )
        , .S1_RRESP             (S1_RRESP    )
        , .S1_RLAST             (S1_RLAST    )
        , .S1_RVALID            (S1_RVALID   )
        , .S1_RREADY            (S1_RREADY_M1)
        `ifdef AMBA_AXI_RUSER
        , .S1_RUSER             (S1_RUSER    )
        `endif
        , .SD_BID               (SD_BID      )
        , .SD_BRESP             (SD_BRESP    )
        , .SD_BVALID            (SD_BVALID   )
        , .SD_BREADY            (SD_BREADY_M1)
        `ifdef AMBA_AXI_BUSER
        , .SD_BUSER             (SD_BUSER    )
        `endif
        , .SD_RID               (SD_RID      )
        , .SD_RDATA             (SD_RDATA    )
        , .SD_RRESP             (SD_RRESP    )
        , .SD_RLAST             (SD_RLAST    )
        , .SD_RVALID            (SD_RVALID   )
        , .SD_RREADY            (SD_RREADY_M1)
        `ifdef AMBA_AXI_RUSER
        , .SD_RUSER             (SD_RUSER    )
        `endif
    );

    axi_slave_default #(.WIDTH_CID(WIDTH_CID)// Channel ID width in bits
                        ,.WIDTH_ID (WIDTH_ID )// ID width in bits
                        ,.WIDTH_AD (WIDTH_AD )// address width
                        ,.WIDTH_DA (WIDTH_DA )// data width
                        )
    Uaxi_slave_default (
        .ARESETn  (ARESETn )
        , .ACLK     (ACLK    )
        , .AWID     (SD_AWID    )
        , .AWADDR   (SD_AWADDR  )
    `ifdef AMBA_AXI4
        , .AWLEN    (SD_AWLEN   )
        , .AWLOCK   (SD_AWLOCK  )
    `else
        , .AWLEN    (SD_AWLEN   )
        , .AWLOCK   (SD_AWLOCK  )
    `endif
        , .AWSIZE   (SD_AWSIZE  )
        , .AWBURST  (SD_AWBURST )
    `ifdef AMBA_AXI_CACHE
        , .AWCACHE  (SD_AWCACHE )
    `endif
    `ifdef AMBA_AXI_PROT
        , .AWPROT   (SD_AWPROT  )
    `endif
        , .AWVALID  (SD_AWVALID )
        , .AWREADY  (SD_AWREADY )
    `ifdef AMBA_AXI4
        , .AWQOS    (SD_AWQOS   )
        , .AWREGION (SD_AWREGION)
    `endif
        , .WID      (SD_WID     )
        , .WDATA    (SD_WDATA   )
        , .WSTRB    (SD_WSTRB   )
        , .WLAST    (SD_WLAST   )
        , .WVALID   (SD_WVALID  )
        , .WREADY   (SD_WREADY  )
        , .BID      (SD_BID     )
        , .BRESP    (SD_BRESP   )
        , .BVALID   (SD_BVALID  )
        , .BREADY   (SD_BREADY  )
        , .ARID     (SD_ARID    )
        , .ARADDR   (SD_ARADDR  )
    `ifdef AMBA_AXI4
        , .ARLEN    (SD_ARLEN   )
        , .ARLOCK   (SD_ARLOCK  )
    `else
        , .ARLEN    (SD_ARLEN   )
        , .ARLOCK   (SD_ARLOCK  )
    `endif
        , .ARSIZE   (SD_ARSIZE  )
        , .ARBURST  (SD_ARBURST )
    `ifdef AMBA_AXI_CACHE
        , .ARCACHE  (SD_ARCACHE )
    `endif
    `ifdef AMBA_AXI_PROT
        , .ARPROT   (SD_ARPROT  )
    `endif
        , .ARVALID  (SD_ARVALID )
        , .ARREADY  (SD_ARREADY )
    `ifdef AMBA_AXI4
        , .ARQOS    (SD_ARQOS   )
        , .ARREGION (SD_ARREGION)
    `endif
        , .RID      (SD_RID     )
        , .RDATA    (SD_RDATA   )
        , .RRESP    (SD_RRESP   )
        , .RLAST    (SD_RLAST   )
        , .RVALID   (SD_RVALID  )
        , .RREADY   (SD_RREADY  )
    );



endmodule