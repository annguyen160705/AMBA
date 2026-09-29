module mem_axi #(
      parameter AXI_WIDTH_CID   = 4
    , parameter AXI_WIDTH_ID    = 4
    , parameter AXI_WIDTH_AD    = 32
    , parameter AXI_WIDTH_DA    = 32
    , parameter AXI_WIDTH_DS    = (AXI_WIDTH_DA/8)
    , parameter AXI_WIDTH_DSB   = $clog2(AXI_WIDTH_DS/8)
    , parameter AXI_WIDTH_SID   = (AXI_WIDTH_CID + AXI_WIDTH_ID)
    , parameter ADDR_LENGTH     = 12
) (
    //--------------------------------------------------------//
    // Global signals
    input logic         ARESETn
    , input logic       ACLK

    //--------------------------------------------------------//
    // Write Address Channel (AW)
    , input logic [AXI_WIDTH_SID-1:0]   AWID
    , input logic [AXI_WIDTH_AD-1:0]    AWADDR

    `ifdef AMBA_AXI4
    , input logic [7:0] AWLEN
    , input logic       AWLOCK
    `else
    , input logic [3:0] AWLEN 
    , input logic [1:0] AWLOCK 
    `endif // AMBA_AXI4

    , input logic [2:0] AWSIZE
    , input logic [1:0] AWBURST

    `ifdef AMBA_AXI_CACHE
    , input logic [3:0] AWCACHE
    `endif // AMBA_AXI_CACHE

    `ifdef AMBA_AXI_PROT
    , input logic [2:0] AWPROT
    `endif // AMBA_AXI_PROT

    , input logic       AWVALID
    , output logic      AWREADY

    `ifdef AMBA_AXI4
    , input logic [3:0] AWQOS
    , input logic [3:0] AWREGION
    `endif // AMBA_AXI4

    //--------------------------------------------------------//
    // Write Data Channel (W)
    , input logic [AXI_WIDTH_SID-1:0]   WID
    , input logic [AXI_WIDTH_DA-1:0]    WDATA
    , input logic [AXI_WIDTH_DS-1:0]    WSTRB
    , input logic                       WLAST
    , input logic                       WVALID
    , output logic                      WREADY

    //--------------------------------------------------------//
    // Write response channel (B)

    , output logic [AXI_WIDTH_SID-1:0]  BID
    , output logic [1:0]                BRESP
    , output logic                      BVALID
    , input logic                       BREADY

    //--------------------------------------------------------//
    // Read Address channel (AR)
    , input logic [AXI_WIDTH_SID-1:0]   ARID
    , input logic [AXI_WIDTH_AD-1:0]    ARADDR

    `ifdef AMBA_AXI4
    , input logic [7:0]                 ARLEN
    , input logic                       ARLOCK
    `else
    , input logic [3:0]                 ARLEN 
    , input logic [1:0]                 ARLOCK 
    `endif // AMBA_AXI4

    , input logic [2:0]                 ARSIZE
    , input logic [1:0]                 ARBURST

    `ifdef AMBA_AXI_CACHE
    , input logic [3:0] 
        
    `endif // AMBA_AXI_CACHE

    `ifdef AMBA_AXI_PROT
    , input logic [2:0]                 ARPROT
    `endif // AMBA_AXI_PROT

    , input logic                       ARVALID
    , output logic                      ARREADY

    `ifdef AMBA_AXI4
    , input logic [3:0]                 ARQOS
    , input logic [3:0]                 ARREGION
    `endif // AMBA_AXI4

    //--------------------------------------------------------//
    // Read data channel (R)
    , output logic [AXI_WIDTH_SID-1:0]  RID
    , output logic [AXI_WIDTH_DA-1:0]   RDATA
    , output logic [1:0]                RRESP
    , output logic                      RVALID
    , output logic                      RLAST
    , input logic                       RREADY

    //--------------------------------------------------------//
    // Low-power/ System control signals
    , input logic                       CSYSREQ
    , output logic                      CSYSACK
    , output logic                      CACTIVE
    
);

    assign CSYSACK  = CSYSREQ;
    assign CACTIVE  = 1'b1;

    //--------------------------------------------------------//

    logic   [ADDR_LENGTH-1:0]   Twaddr;
    logic   [AXI_WIDTH_DA-1:0]  Twdata;
    logic   [AXI_WIDTH_DS-1:0]  Twstrb;
    logic                       Twen;

    logic   [ADDR_LENGTH-1:0]   Traddr;
    logic   [AXI_WIDTH_DA-1:0]  Trdata;
    logic   [AXI_WIDTH_DS-1:0]  Trstrb;

    logic                       Tren;   // driven by stateR
    logic                       TrenX;  // actual Tren

    //--------------------------------------------------------//
    // write case

    logic [AXI_WIDTH_SID-1:0]   AWID_reg;
    logic [AXI_WIDTH_AD-1:0]    AWADDR_reg;
    `ifdef AMBA_AXI4
    logic [7:0]                 AWLEn_reg;
    logic                       AWLOCK_reg;
    `else
    logic [3:0]                 AWLEN_reg;
    logic [1:0]                 AWLOCK_reg;
    `endif // AMBA_AXI4

    logic [2:0]                 AWSIZE_reg;
    logic [1:0]                 AWBURST_reg;
    logic [3:0]                 AWCACHE_reg;
    logic [2:0]                 AWPROT_reg;

    //--------------------------------------------------------//
    logic   [ADDR_LENGTH-1:0]   addrW;
    `ifdef AMBA_AXI4
    logic [7:0]                 beatW;
    `else
    logic [3:0]                 beatW;
    `endif // AMBA_AXI4

    typedef enum logic [1:0] {
        STW_IDLE    = 2'b00,
        STW_WRITE0  = 2'b01,
        STW_WRITE   = 2'b10,
        STW_RSP     = 2'b11
    } W_state_t;

    W_state_t stateW;

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if(!ARESETn) begin
            stateW  <= STW_IDLE;
            AWID_reg    <= 'h0;
            AWADDR_reg  <= 'h0;
            AWLEN_reg   <= 'h0;
            AWSIZE_reg  <= 'b0;
            AWBURST_reg <= 'b0;
            AWLOCK_reg  <= 'b0;
            AWCACHE_reg <= 'h0;
            AWPROT_reg  <= 'b0;
            AWREADY     <= 1'b0;
            WREADY      <= 1'b0;
            BID         <= 'h0;
            BRESP       <= 2'b10;
            BVALID      <= 1'b0;
            addrW       <= 'h0;
            beatW       <= 'h0;
            Twaddr      <= 'h0;
            Twdata      <= 'h0;
            Twstrb      <= 'h0;
            Twen        <= 1'b0;
        end else begin
            case (stateW)
                STW_IDLE: begin
                    if((AWVALID == 1'b1) && (AWREADY == 1'b1)) begin
                        AWID_reg    <= AWID;
                        AWADDR_reg  <= AWADDR;
                        AWLEN_reg   <= AWLEN;
                        AWSIZE_reg  <= AWSIZE;
                        AWBURST_reg <= AWBURST;
                        AWLOCK_reg  <= AWLOCK;
                        `ifdef AMBA_AXI_CACHE
                        AWCACHE_reg <= AWCACHE;
                        `else
                        AWCACHE_reg <= 'h0;
                        `endif // AMBA_AXI_CACHE

                        `ifdef AMBA_AXI_PROT
                        AWPROT_reg  <= AWPROT;
                        `else
                        AWPROT_reg  <= 'h0;
                        `endif // AMBA_AXI_PROT
                        AWREADY     <= 1'b0;
                        WREADY      <= 1'b1;
                        BRESP       <= 2'b00;
                        addrW       <= AWADDR[ADDR_LENGTH-1:0];
                        beatW       <= 'h0;
                        stateW      <= STW_WRITE0;
                    end else begin
                        AWREADY     <= 1'b1;
                    end
                end    
                STW_WRITE0: begin
                    if(WVALID == 1'b1) begin
                        Twaddr  <= addrW;
                        Twdata  <= WDATA;
                        Twstrb  <= WSTRB;
                        Twen    <= 1'b1;
                        beatW   <= beatW + 1;
                        addrW   <= get_next_addr_wr(addrW,AWSIZE_reg,AWBURST_reg,AWLEN_reg);
                        if(beatW >= AWLEN_reg) begin
                            WREADY  <= 1'b0;
                            BVALID  <= 1'b1;
                            BID     <= AWID_reg;
                            if(WLAST == 1'b0) BRESP <= 2'b10;
                            stateW  <= STW_RSP;
                        end else begin
                            stateW  <= STW_WRITE;
                        end
                        if (WID != AWID_reg) BRESP  <= 2'b10;
                    end else begin
                        Twen    <= 1'b0;
                    end
                end
                STW_WRITE: begin
                    if(WVALID == 1'b1) begin
                        Twaddr  <= addrW;
                        Twdata  <= WDATA;
                        Twstrb  <= WSTRB;
                        Twen    <= 1'b1;
                        beatW   <= beatW + 1;
                        addrW   <= get_next_addr_wr(addrW, AWSIZE_reg, AWBURST_reg, AWLEN_reg);
                        if(beatW >= AWLEN_reg) begin
                            WREADY  <= 1'b0;
                            BVALID  <= 1'b1;
                            BID     <= AWID_reg;
                            if(WLAST == 1'b0) BRESP <= 2'b10;
                            stateW  <= STW_RSP;
                        end
                        if(WID!=AWID_reg)   BRESP   <= 2'b10;
                    end else begin
                        Twen    <= 1'b0;
                    end
                end  
                STW_RSP: begin
                    Twen    <= 1'b0;
                    if(BREADY == 1'b1) begin
                        BVALID  <= 1'b0;
                        AWREADY <= 1'b1;
                        stateW  <= STW_IDLE;
                    end
                end   
            endcase
        end
    end
    

    //--------------------------------------------------------//
    // read case
    logic [AXI_WIDTH_AD-1:0] ARADDR_reg;
    `ifdef AMBA_AXI4
    logic [7:0]             ARLEN_reg;
    logic                   ARLOCK_reg;
    `else
    logic [3:0]             ARLEN_reg;
    logic [1:0]             ARLOCK_reg;
    `endif // AMBA_AXI4
    logic [2:0]             ARSIZE_reg;
    logic [1:0]             ARBURST_reg;
    logic [3:0]             ARCACHE_reg;
    logic [2:0]             ARPROT_reg;

    //--------------------------------------------------------//
    logic   [AXI_WIDTH_DA-1:0]  dataR;
    logic   [ADDR_LENGTH-1:0]   addrR;
    logic   [AXI_WIDTH_DS-1:0]  strbR;

    `ifdef AMBA_AXI4
    logic [7:0]                 beatR;
    `else
    logic [3:0]                 beatR;
    `endif // AMBA_AXI4

    typedef enum logic [3:0] {
        STR_IDLE        = 'h0,
        STR_READ0       = 'h1,
        STR_READ1       = 'h2,
        STR_READ2       = 'h3,
        STR_READ21      = 'h4,
        STR_READ22      = 'h5,
        STR_READ3       = 'h6,
        STR_READ31      = 'h7,
        STR_READ32      = 'h8,
        STR_READ33      = 'h9,
        STR_READ34      = 'hA,
        STR_END         = 'hB
    } R_state_t;

    R_state_t stateR;

    always_ff @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            stateR  <= STR_IDLE;
        end else begin
            case (stateR)
                STR_IDLE: begin
                    if((ARVALID == 1'b1) && (ARREADY == 1'b1)) begin
                        ARADDR_reg  <= ARADDR;
                        ARLEN_reg   <= ARLEN;
                        ARSIZE_reg  <= ARSIZE;
                        ARBURST_reg <= ARBURST;
                        ARLOCK_reg  <= ARLOCK;
                        `ifdef AMBA_AXI_CACHE
                        ARCACHE_reg <= ARCACHE;
                        `else
                        ARCACHE_reg <= 'h0;
                        `endif // AMBA_AXI_CACHE

                        `ifdef AMBA_AXI_PROT
                        ARPROT_reg  <= ARPROT;    
                        `else
                        ARPROT_reg  <= 'h0;
                        `endif // AMBA_AXI_PROT

                        ARREADY <= 1'b0;
                        RID     <= ARID;
                        addrR   <= get_next_addr_rd(ARADDR[ADDR_LENGTH-1:0],ARSIZE,ARBURST,ARLEN);
                        beatR   <= 'h0;
                        Traddr  <= ARADDR[ADDR_LENGTH-1:0];
                        Trstrb  <= get_strb(ARADDR[ADDR_LENGTH-1:0],ARSIZE);
                        Tren    <= 1'b1;
                        stateR  <= STR_READ0;
                    end else begin
                        ARREADY <= 1'b1;
                    end
                end        
                STR_READ0: begin
                    if(ARLEN_reg == 'h0) begin //single beat burst
                        Tren    <= 1'b0;
                        stateR  <= STR_READ1;
                    end else if (ARLEN_reg == 'h1) begin // two-beat burst
                        Tren    <= 1'b1;
                        Traddr  <= addrR;
                        Trstrb  <= get_strb(addrR,ARSIZE_reg);
                        stateR  <= STR_READ2;
                    end else begin //three or more beat burst
                        Tren    <= 1'b1;
                        Traddr  <= addrR;
                        Trstrb  <= get_strb(addrR,ARSIZE_reg);
                        addrR   <= get_next_addr_rd(addrR,ARSIZE_reg,ARBURST_reg,ARLEN_reg);
                        beatR   <= 1;
                        stateR  <= STR_READ3;
                    end
                end
                STR_READ1: begin
                    RLAST   <= 1'b1;
                    RDATA   <= Trdata;
                    RRESP   <= 2'b00;
                    RVALID  <= 1'b1;
                    stateR  <= STR_END;
                end  
                STR_READ2: begin
                    Tren    <= 1'b0;
                    RLAST   <= 1'b0;
                    RDATA   <= Trdata;
                    RRESP   <= 2'b00;
                    RVALID  <= 1'b1;
                    stateR  <= STR_READ21;
                end
                STR_READ21: begin
                    if(RREADY == 1'b1) begin
                        RLAST   <= 1'b1;
                        RDATA   <= Trdata;
                        RRESP   <= 2'b00;
                        RVALID  <= 1'b1;
                        stateR  <= STR_END;
                    end else begin
                        dataR   <= Trdata;
                        stateR  <= STR_READ22;
                    end
                end
                STR_READ22: begin
                    if(RREADY == 1'b1) begin
                        RLAST   <= 1'b1;
                        RDATA   <= dataR;
                        RRESP   <= 2'b00;
                        RVALID  <= 1'b1;
                        stateR  <= STR_END;
                    end
                end
                STR_READ3: begin
                    RLAST   <= 1'b0;
                    RDATA   <= Trdata;
                    RRESP   <= 2'b00;
                    RVALID  <= 1'b1;
                    Tren    <= 1'b1;
                    Traddr  <= addrR;
                    Trstrb  <= get_strb(addrR,ARSIZE_reg);
                    addrR   <= get_next_addr_rd(addrR,ARSIZE_reg,ARBURST_reg,ARLEN_reg);
                    beatR   <= beatR + 1;
                    stateR  <= STR_READ31;
                end 
                STR_READ31: begin
                    if(RREADY == 1'b1) begin
                        RLAST   <= 1'b0;
                        RDATA   <= Trdata;
                        RRESP   <= 2'b00;
                        RVALID  <= 1'b1;
                        if(beatR >= ARLEN_reg) begin
                            Tren    <= 1'b1;
                            Traddr  <= addrR;
                            stateR  <= STR_READ33;
                        end else begin
                            Tren    <= 1'b1;
                            Traddr  <= addrR;
                            Trstrb  <= get_strb(addrR,ARSIZE_reg);
                            addrR  <= get_next_addr_rd(addrR,ARSIZE_reg<ARBURST_reg,ARLEN_reg);
                        end
                        beatR   <= beatR + 1;
                    end else begin
                    Tren    <= 1'b1;
                    dataR   <= Trdata;
                    stateR  <= STR_READ32;
                end 
                end   
                STR_READ32: begin
                    if(RREADY == 1'b1) begin
                        RLAST   <= 1'b0;
                        RDATA   <= dataR;
                        RRESP   <= 2'b00;
                        RVALID  <= 1'b1;
                        dataR   <= Trdata;
                        if(beatR >= ARLEN_reg) begin
                            Tren    <= 1'b0;
                            stateR  <= STR_READ33;
                        end else begin
                            Tren    <= 1'b1;
                            Traddr  <= addrR;
                            Trstrb  <= get_strb(addrR,ARSIZE_reg);
                            addrR   <= get_next_addr_rd(addrR,ARSIZE_reg,ARBURST_reg,ARLEN_reg);
                            stateR  <= STR_READ31;
                        end
                        beatR   <= beatR + 1;
                    end
                end
                STR_READ33: begin
                    if(RREADY == 1'b1) begin
                        RLAST   <= 1'b1;
                        RDATA   <= Trdata;
                        RRESP   <= 2'b00;
                        RVALID  <= 1'b1;
                        stateR  <= STR_END;
                    end else begin
                        Tren    <= 1'b0;
                        dataR   <= Trdata;
                        stateR  <= STR_READ34;
                    end
                end    
                STR_READ34: begin
                    if(RREADY == 1'b1) begin
                        RLAST   <= 1'b1;
                        RDATA   <= dataR;
                        RRESP   <= 2'b00;
                        RVALID  <= 1'b1;
                        stateR  <= STR_END;
                    end
                end    
                STR_END: begin
                    if(RREADY == 1'b1) begin
                        RDATA   <= 'h0;
                        RRESP   <= 2'b10;
                        RLAST   <= 1'b0;
                        RVALID  <= 1'b0;
                        ARREADY <= 1'b1;
                        stateR  <= STR_IDLE;
                    end
                end                  
            endcase
        end
    end

     

assign TrenX = ((stateR == STR_READ31) || (stateR == STR_READ32)) ? RREADY : Tren;

mem_axi_dpram_sync #(.WIDTH_AD  (ADDR_LENGTH)
                    ,.WIDTH_DA  (AXI_WIDTH_DA))
Udpram(
     .RESETn    (ARESETn)
    ,.CLK       (ACLK)
    ,.WADDR     (Twaddr)
    ,.WDATA     (Twdata)
    ,.WSTRB     (Twstrb)
    ,.WEN       (Twen)
    ,.RADDR     (Traddr)
    ,.RDATA     (Trdata)
    ,.RSTRB     (Trstrb)
    ,.REN       (TrenX)
);



endmodule