`timescale 1ns/1ns

`ifndef CLK_FREQ
`define CLK_FREQ    50_000_000
`endif

`ifndef MEM_DELAY
`define MEM_DELAY 0
`endif

module top;

    localparam P_NUM    = 3;
    localparam SIZE_IN_BYTES    = 1024;
    localparam DELAY    = `MEM_DELAY;

    logic               PRESETn = 1'b0;
    logic               PCLK    = 1'b0;

    logic [P_NUM-1:0]   PSEL;
    logic [31:0]        PADDR;
    logic               PENABLE;
    logic               PWRITE;
    logic [31:0]        PWDATA;
    logic [31:0]        PRDATA0;
    logic [31:0]        PRDATA1;
    logic [31:0]        PRDATA2;

    `ifdef AMBA3
    logic [P_NUM-1:0]   PREADY;
    logic [P_NUM-1:0]   PSLVERR;
    `endif

    `ifdef AMBA4
    logic [2:0]         PPROT;
    logic [3:0]         PSTRB;
    `endif

    logic [32*P_NUM-1:0] PRDATA;

    assign PRDATA0 = PRDATA[31:0];
    assign PRDATA1 = PRDATA[63:32];
    assign PRDATA2 = PRDATA[95:64];

    bfm_apb_s3  #(.P_NUM(P_NUM))
    u_bfm_apb_s3    (
        .PRESETn    (PRESETn)
        ,.PCLK      (PCLK)
        ,.PSEL      (PSEL)
        ,.PADDR     (PADDR)
        ,.PENABLE   (PENABLE)
        ,.PWRITE    (PWRITE)
        ,.PWDATA    (PWDATA)
        ,.PRDATA0   (PRDATA0)
        ,.PRDATA1   (PRDATA1)
        ,.PRDATA2   (PRDATA2)

        `ifdef AMBA3
        ,.PREADY    (PREADY)
        ,.PSLVERR   (PSLVERR)
        `endif // AMBA3

        `ifdef AMBA4
        ,.PPROT     (PPROT)
        ,.PSTRB     (PSTRB)
        `endif // AMBA4
    );

    generate
    genvar pn;
        for ( pn = 0; pn < P_NUM; pn = pn + 1) begin : P_BLOCK
            mem_apb #(.SIZE_IN_BYTES(1024)
                    ,.DELAY (DELAY))
            u_mem_apb(
                    .PRESETn    (PRESETn)
                    ,.PCLK      (PCLK)
                    ,.PSEL      (PSEL[pn])
                    ,.PADDR     (PADDR)
                    ,.PENABLE   (PENABLE)
                    ,.PWRITE    (PWRITE)
                    ,.PWDATA    (PWDATA)
                    ,.PRDATA    (PRDATA[32*(pn+1)-1:32*pn])
                    `ifdef AMBA3
                    ,.PREADY    (PREADY[pn])
                    ,.PSLVERR   (PSLVERR[pn])
                    `endif // AMBA3
                    `ifdef AMBA4
                    ,.PPROT     (PPROT)
                    ,.PSTRB     (PSTRB)
                    `endif // AMBA4
            );
            // Instantiate module
        end
    endgenerate

    localparam  CLK_FREQ=`CLK_FREQ;
    localparam  CLK_PERIOD_HALF = 1_000_000_000/(CLK_FREQ*2);

    always  #CLK_PERIOD_HALF    PCLK <= ~PCLK;

    initial begin
        PRESETn <= 1'b0;
        repeat  (5) @(posedge PCLK);
        repeat  (5) @(posedge PCLK);
        PRESETn <= 1'b1;
    end
    
    
endmodule