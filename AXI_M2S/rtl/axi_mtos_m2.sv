
`timescale 1ns/1ns

module axi_mtos_m2
   // synopsys translate_off
   `protect
   // synopsys translate_on
       #(parameter SLAVE_ID    =0
                 , SLAVE_EN    =1'b1 // the slave is available when 1
                 , ADDR_BASE   =32'h0000_0000
                 , ADDR_LENGTH =12 // effective addre bits
                 , WIDTH_CID   =4  // Channel ID width in bits
                 , WIDTH_ID    =4  // ID width in bits
                 , WIDTH_AD    =32 // address width
                 , WIDTH_DA    =32 // data width
                 , WIDTH_DS    =(WIDTH_DA/8)  // data strobe width
                 , WIDTH_SID   =WIDTH_CID+WIDTH_ID // ID for slave
                 , WIDTH_AWUSER=1 // Write-address user path
                 , WIDTH_WUSER =1 // Write-data user path
                 , WIDTH_ARUSER=1 // read-address user path
                 , NUM_MASTER  =2    // number of master
                 , SLAVE_DEFAULT=1'b0  // default-salve when 1
        )
(
       input   logic                      ARESETn
     , input   logic                      ACLK
     //--------------------------------------------------------------
     , input   logic  [WIDTH_CID-1:0]     M0_MID
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
     `ifdef  AMBA_AXI_CACHE
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
     `ifdef  AMBA_AXI_CACHE
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
     //--------------------------------------------------------------
     , input   logic  [WIDTH_CID-1:0]     M1_MID
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
     `ifdef  AMBA_AXI_CACHE
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
     , input   logic                      M1_WVALID
     , output  logic                      M1_WREADY
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
     `ifdef  AMBA_AXI_CACHE
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
     //--------------------------------------------------------------
     , output  logic   [WIDTH_SID-1:0]     S_AWID
     , output  logic   [WIDTH_AD-1:0]      S_AWADDR
     `ifdef AMBA_AXI4
     , output  logic   [ 7:0]              S_AWLEN
     , output  logic                       S_AWLOCK
     `else
     , output  logic   [ 3:0]              S_AWLEN
     , output  logic   [ 1:0]              S_AWLOCK
     `endif
     , output  logic   [ 2:0]              S_AWSIZE
     , output  logic   [ 1:0]              S_AWBURST
     `ifdef  AMBA_AXI_CACHE
     , output  logic   [ 3:0]              S_AWCACHE
     `endif
     `ifdef AMBA_AXI_PROT
     , output  logic   [ 2:0]              S_AWPROT
     `endif
     , output  logic                       S_AWVALID
     , input   logic                      S_AWREADY
     `ifdef AMBA_AXI4
     , output  logic   [ 3:0]              S_AWQOS
     , output  logic   [ 3:0]              S_AWREGION
     `endif
     `ifdef AMBA_AXI_AWUSER
     , output  logic   [WIDTH_AWUSER-1:0]  S_AWUSER
     `endif
     , output  logic   [WIDTH_SID-1:0]     S_WID
     , output  logic   [WIDTH_DA-1:0]      S_WDATA
     , output  logic   [WIDTH_DS-1:0]      S_WSTRB
     , output  logic                       S_WLAST
     , output  logic                       S_WVALID
     , input   logic                      S_WREADY
     `ifdef AMBA_AXI_WUSER
     , output  logic   [WIDTH_WUSER-1:0]   S_WUSER
     `endif
     , output  logic   [WIDTH_SID-1:0]     S_ARID
     , output  logic   [WIDTH_AD-1:0]      S_ARADDR
     `ifdef AMBA_AXI4
     , output  logic   [ 7:0]              S_ARLEN
     , output  logic                       S_ARLOCK
     `else
     , output  logic   [ 3:0]              S_ARLEN
     , output  logic   [ 1:0]              S_ARLOCK
     `endif
     , output  logic   [ 2:0]              S_ARSIZE
     , output  logic   [ 1:0]              S_ARBURST
     `ifdef  AMBA_AXI_CACHE
     , output  logic   [ 3:0]              S_ARCACHE
     `endif
     `ifdef AMBA_AXI_PROT
     , output  logic   [ 2:0]              S_ARPROT
     `endif
     , output  logic                       S_ARVALID
     , input   logic                      S_ARREADY
     `ifdef AMBA_AXI4
     , output  logic   [ 3:0]              S_ARQOS
     , output  logic   [ 3:0]              S_ARREGION
     `endif
     `ifdef AMBA_AXI_ARUSER
     , output  logic   [WIDTH_ARUSER-1:0]  S_ARUSER
     `endif
     //-----------------------------------------------------------
     , output  logic  [NUM_MASTER-1:0]    AWSELECT_OUT
     , output  logic  [NUM_MASTER-1:0]    ARSELECT_OUT
     , input   logic  [NUM_MASTER-1:0]    AWSELECT_IN
     , input   logic  [NUM_MASTER-1:0]    ARSELECT_IN
);

    logic  [NUM_MASTER-1:0] AWSELECT;
    logic  [NUM_MASTER-1:0] ARSELECT;
    logic [1:0] AWGRANT, WGRANT, ARGRANT;

    assign  AWSELECT_OUT = AWSELECT;
    assign  ARSELECT_OUT = ARSELECT;

    always_comb begin
        if (SLAVE_DEFAULT=='h0) begin
            AWSELECT[0] = SLAVE_EN    &
                          (  M0_AWADDR[WIDTH_AD-1:ADDR_LENGTH]
                           ==ADDR_BASE[WIDTH_AD-1:ADDR_LENGTH]);
            AWSELECT[1] = SLAVE_EN    &
                          (  M1_AWADDR[WIDTH_AD-1:ADDR_LENGTH]
                           ==ADDR_BASE[WIDTH_AD-1:ADDR_LENGTH]);
            ARSELECT[0] = SLAVE_EN    &
                          (  M0_ARADDR[WIDTH_AD-1:ADDR_LENGTH]
                           ==ADDR_BASE[WIDTH_AD-1:ADDR_LENGTH]);
            ARSELECT[1] = SLAVE_EN    &
                          (  M1_ARADDR[WIDTH_AD-1:ADDR_LENGTH]
                           ==ADDR_BASE[WIDTH_AD-1:ADDR_LENGTH]);
        end else begin
            AWSELECT = ~AWSELECT_IN & {M1_AWVALID,M0_AWVALID};
            ARSELECT = ~ARSELECT_IN & {M1_ARVALID,M0_ARVALID};
        end
    end


        axi_arbiter_mtos_m2 #(.WIDTH_CID(WIDTH_CID) // Channel ID width in bits
                          ,.WIDTH_ID (WIDTH_ID ) // Transaction ID
                          )
        Uaxi_arbiter (
            .ARESETn  (ARESETn )
            , .ACLK     (ACLK    )
            , .AWSELECT (AWSELECT)
            , .AWVALID  ({M1_AWVALID,M0_AWVALID})
            , .AWREADY  ({M1_AWREADY,M0_AWREADY})
            `ifdef AMBA_AXI4
            , .AWLOCK   ({M1_AWLOCK ,M0_AWLOCK })
            `else
            , .AWLOCK   ({M1_AWLOCK[1],M0_AWLOCK[1]})
            `endif
            , .AWGRANT  (AWGRANT          )
            , .AWSID0   ({M0_MID,M0_AWID})
            , .AWSID1   ({M1_MID,M1_AWID})
            , .WVALID   ({M1_WVALID,M0_WVALID})
            , .WLAST    ({M1_WLAST ,M0_WLAST })
            , .WREADY   ({M1_WREADY,M0_WREADY})
            , .WGRANT   (WGRANT             )
            , .WSID0    ({M0_MID,M0_WID}   )
            , .WSID1    ({M1_MID,M1_WID}   )
            , .ARSELECT (ARSELECT)
            , .ARVALID  ({M1_ARVALID,M0_ARVALID})
            `ifdef AMBA_AXI4
            , .ARLOCK   ({M1_ARLOCK ,M0_ARLOCK })
            `else
            , .ARLOCK   ({M1_ARLOCK[1],M0_ARLOCK[1]})
            `endif
            , .ARREADY  ({M1_ARREADY,M0_ARREADY})
            , .ARGRANT  (ARGRANT            )
            , .ARSID0   ({M0_MID,M0_ARID}  )
            , .ARSID1   ({M1_MID,M1_ARID}  )
            , .MID0     (M0_MID    )
            , .MID1     (M1_MID    )
        );

        localparam NUM_AW_WIDTH = 0
                    + WIDTH_SID          //S_AWID
                    + WIDTH_AD           //S_AWADDR
                      `ifdef AMBA_AXI4
                    +  8                 //S_AWLEN
                    +  1                 //S_AWLOCK
                      `else
                    +  4                 //S_AWLEN
                    +  2                 //S_AWLOCK
                      `endif
                    +  3                 //S_AWSIZE
                    +  2                 //S_AWBURST
                       `ifdef  AMBA_AXI_CACHE
                    +  4                 //S_AWCACHE
                       `endif
                       `ifdef AMBA_AXI_PROT
                    +  3                 //S_AWPROT
                       `endif
                    +  1                 //S_AWVALID
                      `ifdef AMBA_AXI4
                    +  4                 //S_AWQOS
                    +  4                 //S_AWREGION
                      `endif
                      `ifdef AMBA_AXI_AWUSER
                    + WIDTH_AWUSER       //S_AWUSER
                      `endif
                    ;

        localparam NUM_W_WIDTH = 0
                    + WIDTH_SID          //S_WID
                    + WIDTH_DA           //S_WDATA
                    + WIDTH_DS           //S_WSTRB
                    + 1                  //S_WLAST
                    + 1                  //S_WVALID
                      `ifdef AMBA_AXI_WUSER
                    + WIDTH_WUSER        //S_WUSER
                      `endif
                    ;
        
        localparam NUM_AR_WIDTH = 0
                    + WIDTH_SID          //S_ARID
                    + WIDTH_AD           //S_ARADDR
                      `ifdef AMBA_AXI4
                    +  8                 //S_ARLEN
                    +  1                 //S_ARLOCK
                      `else
                    +  4                 //S_ARLEN
                    +  2                 //S_ARLOCK
                      `endif
                    +  3                 //S_ARSIZE
                    +  2                 //S_ARBURST
                       `ifdef  AMBA_AXI_CACHE
                    +  4                 //S_ARCACHE
                       `endif
                       `ifdef AMBA_AXI_PROT
                    +  3                 //S_ARPROT
                       `endif
                    +  1                 //S_ARVALID
                      `ifdef AMBA_AXI4
                    +  4                 //S_ARQOS
                    +  4                 //S_ARREGION
                      `endif
                      `ifdef AMBA_AXI_ARUSER
                    + WIDTH_ARUSER       //S_ARUSER
                      `endif
                    ;

        wire [NUM_AW_WIDTH-1:0] bus_aw[0:1];
        wire [NUM_W_WIDTH-1 :0] bus_w [0:1];
        wire [NUM_AR_WIDTH-1:0] bus_ar[0:1];

        assign M0_AWREADY = AWGRANT[0]&S_AWREADY;
        assign M1_AWREADY = AWGRANT[1]&S_AWREADY;
        assign M0_WREADY  = WGRANT [0]&S_WREADY;
        assign M1_WREADY  = WGRANT [1]&S_WREADY;
        assign M0_ARREADY = ARGRANT[0]&S_ARREADY;
        assign M1_ARREADY = ARGRANT[1]&S_ARREADY;

        assign bus_aw[0] = {M0_MID     // master 0 master channel id
                            ,M0_AWID
                            ,M0_AWADDR
                            ,M0_AWLEN
                            ,M0_AWLOCK
                            ,M0_AWSIZE
                            ,M0_AWBURST
                            `ifdef AMBA_AXI_CACHE
                            ,M0_AWCACHE
                            `endif
                            `ifdef AMBA_AXI_PROT
                            ,M0_AWPROT
                            `endif
                            ,M0_AWVALID
                            `ifdef AMBA_AXI4
                            ,M0_AWQOS
                            ,M0_AWREGION
                            `endif
                            `ifdef AMBA_AXI_AWUSER
                            ,M0_AWUSER
                            `endif
                            };
        assign bus_aw[1] = {M1_MID
                            ,M1_AWID
                            ,M1_AWADDR
                            ,M1_AWLEN
                            ,M1_AWLOCK
                            ,M1_AWSIZE
                            ,M1_AWBURST
                            `ifdef AMBA_AXI_CACHE
                            ,M1_AWCACHE
                            `endif
                            `ifdef AMBA_AXI_PROT
                            ,M1_AWPROT
                            `endif
                            ,M1_AWVALID
                            `ifdef AMBA_AXI4
                            ,M1_AWQOS
                            ,M1_AWREGION
                            `endif
                            `ifdef AMBA_AXI_AWUSER
                            ,M1_AWUSER
                            `endif
                            };
        assign bus_w[0]  = {M0_MID
                            ,M0_WID
                            ,M0_WDATA
                            ,M0_WSTRB
                            ,M0_WLAST
                            ,M0_WVALID
                            `ifdef AMBA_AXI_WUSER
                            ,M0_WUSER
                            `endif
                            };
        assign bus_w[1]  = {M1_MID
                            ,M1_WID
                            ,M1_WDATA
                            ,M1_WSTRB
                            ,M1_WLAST
                            ,M1_WVALID
                            `ifdef AMBA_AXI_WUSER
                            ,M1_WUSER
                            `endif
                            };
        assign bus_ar[0] = {M0_MID
                            ,M0_ARID
                            ,M0_ARADDR
                            `ifdef AMBA_AXI4
                            ,M0_ARLEN
                            ,M0_ARLOCK
                            `else
                            ,M0_ARLEN
                            ,M0_ARLOCK
                            `endif
                            ,M0_ARSIZE
                            ,M0_ARBURST
                            `ifdef AMBA_AXI_CACHE
                            ,M0_ARCACHE
                            `endif
                            `ifdef AMBA_AXI_PROT
                            ,M0_ARPROT
                            `endif
                            ,M0_ARVALID
                            `ifdef AMBA_AXI4
                            ,M0_ARQOS
                            ,M0_ARREGION
                            `endif
                            `ifdef AMBA_AXI_ARUSER
                            ,M0_ARUSER
                            `endif
                            };
        assign bus_ar[1] = {M1_MID
                            ,M1_ARID
                            ,M1_ARADDR
                            `ifdef AMBA_AXI4
                            ,M1_ARLEN
                            ,M1_ARLOCK
                            `else
                            ,M1_ARLEN
                            ,M1_ARLOCK
                            `endif
                            ,M1_ARSIZE
                            ,M1_ARBURST
                            `ifdef AMBA_AXI_CACHE
                            ,M1_ARCACHE
                            `endif
                            `ifdef AMBA_AXI_PROT
                            ,M1_ARPROT
                            `endif
                            ,M1_ARVALID
                            `ifdef AMBA_AXI4
                            ,M1_ARQOS
                            ,M1_ARREGION
                            `endif
                            `ifdef AMBA_AXI_ARUSER
                            ,M1_ARUSER
                            `endif
                            };
        `define S_AWBUS {S_AWID\
                        ,S_AWADDR\
                        ,S_AWLEN\
                        ,S_AWLOCK\
                        ,S_AWSIZE\
                        ,S_AWBURST\
                        `ifdef AMBA_AXI_CACHE\
                        ,S_AWCACHE\
                        `endif\
                        `ifdef AMBA_AXI_PROT\
                        ,S_AWPROT\
                        `endif\
                        ,S_AWVALID\
                        `ifdef AMBA_AXI4\
                        ,S_AWQOS\
                        ,S_AWREGION\
                        `endif\
                        `ifdef AMBA_AXI_AWUSER\
                        ,S_AWUSER\
                        `endif\
                        }

        always @ ( AWGRANT, bus_aw[0], bus_aw[1] ) begin
                `ifdef AMBA_AXI_MUX
                case (AWGRANT)
                2'b01:   `S_AWBUS = bus_aw[0];
                2'b10:   `S_AWBUS = bus_aw[1];
                default: `S_AWBUS = 'h0;
                endcase
                `else
                `S_AWBUS =
                ({NUM_AW_WIDTH{AWGRANT[0]}}&bus_aw[0])|({NUM_AW_WIDTH{AWGRANT[1]}}&bus_aw[1]);
                `endif
        end

            `define S_WBUS {S_WID\
                            ,S_WDATA\
                            ,S_WSTRB\
                            ,S_WLAST\
                            ,S_WVALID\
                            `ifdef AMBA_AXI_WUSER\
                            ,S_WUSER\
                            `endif\
                            }

            `define S_ARBUS {S_ARID\
                            ,S_ARADDR\
                            `ifdef AMBA_AXI4\
                            ,S_ARLEN\
                            ,S_ARLOCK\
                            `else\
                            ,S_ARLEN\
                            ,S_ARLOCK\
                            `endif\
                            ,S_ARSIZE\
                            ,S_ARBURST\
                            `ifdef AMBA_AXI_CACHE\
                            ,S_ARCACHE\
                            `endif\
                            `ifdef AMBA_AXI_PROT\
                            ,S_ARPROT\
                            `endif\
                            ,S_ARVALID\
                            `ifdef AMBA_AXI4\
                            ,S_ARQOS\
                            ,S_ARREGION\
                            `endif\
                            `ifdef AMBA_AXI_ARUSER\
                            ,S_ARUSER\
                            `endif\
                            }

            always @ ( ARGRANT, bus_ar[0], bus_ar[1] ) begin
                `ifdef AMBA_AXI_MUX
                case (ARGRANT)
                2'b01:   `S_ARBUS = bus_ar[0];
                2'b10:   `S_ARBUS = bus_ar[1];
                default: `S_ARBUS = 'h0;
                endcase
                `else
                `S_ARBUS =
                ({NUM_AR_WIDTH{ARGRANT[0]}}&bus_ar[0])|({NUM_AR_WIDTH{ARGRANT[1]}}&bus_ar[1]);
                `endif
            end

endmodule