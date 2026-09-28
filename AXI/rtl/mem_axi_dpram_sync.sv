module mem_axi_dpram_sync #(
      parameter WIDTH_AD = 10 // size of memory in byte
    , parameter WIDTH_DA = 32 // width of a line in bytes
    , parameter WIDTH_DS = (WIDTH_DA/8) // width of a line in bytes
    , parameter WIDTH_DSB = $clog2(WIDTH_DS)
) (
      input logic                 RESETn
    , input logic                 CLK
    //--------------------------------------------------------//
    // write signals
    , input logic [WIDTH_AD-1:0]  WADDR
    , input logic [WIDTH_DA-1:0]  WDATA
    , input logic [WIDTH_DS-1:0]  WSTRB
    , input logic                 WEN
    //--------------------------------------------------------//
    // read signals
    , input logic [WIDTH_AD-1:0]  RADDR
    , output logic [WIDTH_DA-1:0] RDATA
    , input logic [WIDTH_DS-1:0]  RSTRB
    , input logic                 REN
    
);

  localparam DEPTH_BIT  = (WIDTH_AD-WIDTH_DSB);
  localparam DEPTH      = (1 << DEPTH_BIT);
    
  generate
  genvar bs;
    for ( bs = 0; bs < WIDTH_DS; bs = bs + 1) begin : mem_core
      mem_axi_dpram_sync_core #(.WIDTH_AD(WIDTH_AD-WIDTH_DSB))
      Udpram_sync_core  (
                           .RESETn(RESETn)
                          ,.CLK   (CLK)

                          ,.WADDR (WADDR[WIDTH_AD-1:WIDTH_DSB])
                          ,.WDATA (WDATA[8*bs+7:8*bs])
                          ,.WEN   (WEN & WSTRB[bs])

                          ,.RADDR (RADDR[WIDTH_AD-1:WIDTH_DSB])
                          ,.RDATA (RDATA[8*bs+7:8*bs])
                          ,.REN   (REN&RSTRB[bs])
      );
    end
  endgenerate  
endmodule