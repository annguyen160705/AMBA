module ahb_to_apb_s3 #(
    parameter P_PSEL0_START = 16'hC000, P_PSEL0_SIZE  = 16'h0010,
    parameter P_PSEL1_START = 16'hC010, P_PSEL1_SIZE  = 16'h0010,
    parameter P_PSEL2_START = 16'hC020, P_PSEL2_SIZE  = 16'h0010
) (
    //--------------------------------------------------------//
    // 1.Global signals
      input logic HRESETn
    , input logic HCLK

    , input logic PRESETn
    , input logic PCLK

    //--------------------------------------------------------//
    // 2. AHB signals
    , input logic           HSEL
    , input logic [1:0]     HTRANS
    , input logic [3:0]     HPROT
    , input logic           HWRITE
    , input logic [2:0]     HSIZE 
    , input logic [2:0]     HBURST

    , input logic [31:0]    HADDR

    , input logic [31:0]    HWDATA
    , output logic [31:0]   HRDATA

    , input logic           HREADYin
    , input logic [1:0]     HRESP
    , output logic          HREADYout

    //--------------------------------------------------------//
    // 3. APB signals
    , output logic PENABLE
    , output logic PWRITE
    , output logic PSEL0
    , output logic PSEL1
    , output logic PSEL2

    , output logic [31:0] PADDR

    ,output logic [31:0] PWDATA
    , input logic [31:0] PRDATA0
    , input logic [31:0] PRDATA1
    , input logic [31:0] PRDATA2
    
    `ifdef AMBA_APB3
    , input logic PREADY0
    , input logic PSLVERR0
    `endif // AMBA_APB3
    
    `ifdef AMBA_APB3
    , input logic PREADY1
    , input logic PSLVERR1
    `endif // AMBA_APB3

    `ifdef AMBA_APB3
    , input logic PREADY2
    , input logic PSLVERR2
    `endif // AMBA_APB3

    `ifdef AMBA_APB4
    , output logic [2:0] PPROT
    , output logic [3:0] PSTRB 
    `endif // AMBA_APB4

    , input logic [1:0] CLOCK_RATIO // 0=1:1, 3=async
);

    logic PSEL;
    logic [31:0] PRDATA;
    `ifdef AMBA_APB3
    logic PREADY;
    logic PSLVERR;
    `endif // AMBA_APB3

    logic [2:0] _psel; 
    assign _psel = {PSEL2,PSEL1,PSEL0};

     ahb_to_apb_controller Uahb_to_apb_controller (
          .HRESETn(HRESETn)
        , .HCLK (HCLK)
        , .PRESETn  (PRESETn)
        , .PCLK     (PCLK)

        , .HSEL     (HSEL)
        , .HTRANS   (HTRANS)
        , .HPROT    (HPROT)
        , .HWRITE   (HWRITE)
        , .HSIZE    (HSIZE)
        , .HBURST   (HBURST)

        , .PSEL     (PSEL)
        , .PENABLE  (PENABLE)
        , .PWRITE   (PWRITE)

        , .HADDR    (HADDR)
        , .PADDR    (PADDR)

        , .HWDATA   (HWDATA)
        , .HRDATA   (HRDATA)
        , .PWDATA   (PWDATA)
        , .PRDATA   (PRDATA)

        , .HREADYin (HREADYin)
        , .HRESP    (HRESP)
        , .HREADYout(HREADYout)   

        `ifdef AMBA_APB3
        , .PREADY    (PREADY )
        , .PSLVERR   (PSLVERR)
        `endif
        `ifdef AMBA_APB4
        , .PPROT     (PPROT)
        , .PSTRB     (PSTRB)
        `endif
        , .CLOCK_RATIO(CLOCK_RATIO)
     );

     apb_decoder_s3 #(3, P_PSEL0_START, P_PSEL0_SIZE,
                         P_PSEL1_START, P_PSEL1_SIZE,
                         P_PSEL2_START, P_PSEL2_SIZE)
        Uapb_decoder (    .PSELin   (PSEL)
                        , .PADDR    (PADDR)
                        , .PSELout1 (PSEL0)
                        , .PSELout2 (PSEL1)
                        , .PSELout3 (PSEL2)
    );

    always @(_psel or PRDATA0 or PRDATA1 or PRDATA2) begin
        case (_psel)
            3'b001: PRDATA  = PRDATA0;
            3'b010: PRDATA  = PRDATA1;
            3'b100: PRDATA  = PRDATA2;
            default: begin
                PRDATA  = 32'b0;
            end
        endcase
    end

    `ifdef AMBA_APB3
    always @(_psel or PREADY0 or PREADY1 or PREADY2) begin
        case (_psel)
            3'b001: PREADY  = PREADY0;
            3'b010: PREADY  = PREADY1;
            3'b100: PREADY  = PREADY2;
            default: begin
                PREADY  = 1'b1;
            end
        endcase
    end
    always @(_psel or PSLVERR0 or PSLVERR1 or PSLVERR2) begin
        case (_psel)
            3'b001: PSLVERR  = PSLVERR0;
            3'b010: PSLVERR  = PSLVERR1;
            3'b100: PSLVERR  = PSLVERR2;
            default: begin
                PSLVERR  = 1'b0;
            end
        endcase
    end
    `endif // AMBA_APB3

    
    
endmodule