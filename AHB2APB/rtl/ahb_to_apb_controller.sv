module ahb_to_apb_controller(
    //--------------------------------------------------------//
    // Global signals
    input logic         HRESETn,
    input logic         HCLK,

    input logic         PRESETn,
    input logic         PCLK,

    //--------------------------------------------------------//
    // AHB Control signals
    input logic         HSEL,
    input logic [1:0]   HTRANS,
    input logic [3:0]   HPROT,
    input logic         HWRITE,
    input logic [2:0]   HSIZE,
    input logic [2:0]   HBURST, 

    // APB Control signals
    output logic        PSEL,
    output logic        PENABLE,
    output logic        PWRITE,

    //--------------------------------------------------------//
    // AHB Address bus
    input logic [31:0]  HADDR,

    // APB Address bus
    output logic [31:0] PADDR,

    //--------------------------------------------------------//
    // AHB Data bus
    input logic [31:0]  HWDATA,
    output logic [31:0] HRDATA,

    // APB Data bus
    output logic [31:0] PWDATA,
    input logic [31:0]  PRDATA,

    //--------------------------------------------------------//
    // AHB Response / Handshake
    input logic         HREADYin,
    output logic [1:0]  HRESP,
    output logic        HREADYout,

    // APB Response / Handshake
    `ifdef AMBA_APB3,
    input logic         PREADY,
    input logic         PSLVERR
    `endif

    // APB4 Protection / Strobe
    `ifdef AMBA_APB4,
    output logic [2:0]  PPROT,
    output logic [3:0]  PSTRB 
    `endif // AMBA_APB4

    //--------------------------------------------------------//
    // Clock configuration
    // 0 = 1:1
    // 3 = asynchronous
    input logic [1:0]   CLOCK_RATIO
);

    //--------------------------------------------------------//
    `ifndef AMBA_APB3
    logic       PREADY  = 1'b1;
    logic       PSLVERR = 1'b0;
    `endif // AMBA_APB3

    `ifndef AMBA_APB4
    logic [2:0] PPROT; 
    logic [3:0] PSTRB;
    `endif// AMBA_APB4
    //--------------------------------------------------------//

    logic [31:0]    tADDR;
    logic           tWRITE;
    logic [31:0]    tWDATA;
    logic [31:0]    tRDATA;
    logic           tREQ;
    logic           tACK;
    logic           tERROR;
    logic [1:0]     tPROT;
    logic [3:0]     tSTRB;

    //--------------------------------------------------------//

    assign  PADDR   = tADDR;
    assign  PWRITE  = tWRITE;
    assign  PWDATA  = tWDATA;
    assign  PPROT   = tPROT;
    assign  PSTRB   = tSTRB;

    //--------------------------------------------------------//

    logic tACKsync, tACKsync0, tACKsync1;
    always_ff @(posedge HCLK or negedge HRESETn) begin
        if(!HRESETn)begin
            tACKsync0   <= 1'b0;
            tACKsync1   <= 1'b0;
        end else begin
            tACKsync0   <= tACK;
            tACKsync1   <= tACKsync0;
        end
    end

    always_comb begin
        case (CLOCK_RATIO)
            2'b00:  tACKsync = tACK;
            2'b01:  tACKsync = tACKsync1;
            2'b10:  tACKsync = tACKsync1;
            2'b11:  tACKsync = tACKsync1;
        endcase
    end

    //--------------------------------------------------------//
    // AHB bus wrapper

    typedef enum logic [2:0] {
        STH_IDLE    = 3'b000,
        STH_WRITE0  = 3'b001,
        STH_WRITE1  = 3'b010,
        STH_READ0   = 3'b011,
        STH_WAIT    = 3'b100
    } H_state_t;

    H_state_t state;

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if(!HRESETn) begin
            state   <= STH_IDLE;
            HRDATA  <= 32'b0;
            HRESP   <= 2'b00;
            HREADYout   <= 1'b1;    // Why ?
            tADDR       <= 32'h0;
            tWDATA      <= 32'h0;
            tWRITE      <= 1'h0;
            tPROT       <= 3'h0;
            tSTRB       <= 4'hF; // Why ?
            tREQ        <= 1'b0;
        end else begin
            case(state)

                STH_IDLE: begin
                    if(HSEL && HREADYin)begin
                        case(HTRANS)
                            //`HTRANS_IDLE, `HTRANS_BUSY
                            2'b00, 2'b01: begin
                                HREADYout   <= 1'b1;
                                HRESP       <= 2'b00;
                                state       <= STH_IDLE;
                            end
                            //`HTRANS_NONSEQ, `HTRANS_SEQ
                            2'b10, 2'b11: begin
                                HREADYout   <= 1'b0;
                                HRESP       <= 2'b00; 
                                tADDR       <= HADDR[31:0];
                                tWRITE      <= HWRITE;
                                tPROT       <= {~HPROT[0],1'b1,HPROT[1]};
                                tSTRB       <= get_strb(HADDR[1:0], HSIZE);
                                if(HWRITE) begin
                                    state   <= STH_WRITE0;
                                end else begin
                                    tREQ    <= 1'b1;
                                    state   <= STH_READ0;
                                end
                            end
                        endcase     // HTRANS
                    end else begin  // if (HSEL && HREADYin)
                        HREADYout   <= 1'b1;
                        HRESP       <= 2'b00;
                    end
                end // STH_IDLE
                //--------------------------------------------------------//
                // WRITE
                STH_WRITE0:begin
                    tWDATA  <= HWDATA;
                    tREQ    <= 1'b1;
                    state   <= STH_WRITE1;
                end // STH_WRITE0

                STH_WRITE1:begin
                    if(tACKsync) begin
                        tREQ    <= 1'b0;
                        HRESP   <= {1'b0,tERROR};
                        tADDR   <= 32'h0;
                        tWDATA  <= 32'h0;
                        tWRITE  <= 1'b0;
                        if(CLOCK_RATIO == 2'b00) begin
                            HREADYout   <= 1'b1;
                            state       <= STH_IDLE;
                        end else begin
                            state       <= STH_WAIT;
                        end
                    end
                end // STH_WRITE1

                STH_READ0: begin
                    if(tACKsync) begin
                        tREQ    <= 1'b0;
                        HRDATA  <= tRDATA;
                        HRESP   <= {1'b0,tERROR};
                        if(CLOCK_RATIO == 2'b00) begin
                            HREADYout   <= 1'b1;
                            state       <= STH_IDLE;
                        end else begin
                            state       <= STH_WAIT;
                        end
                    end
                end // STH_READ0
                STH_WAIT: begin
                    if(tACKsync == 1'b0) begin
                        HREADYout   <= 1'b1;
                        state       <= STH_IDLE;
                    end
                end // STH_WAIT
            endcase // state
        end // else
    end // always_ff


    //--------------------------------------------------------//

    logic tREQsync, tREQsync0, tREQsync1;
    always_ff @(posedge HCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            tREQsync0   <= 1'b0;
            tREQsync1   <= 1'b0;
        end else begin
            tREQsync0   <= tREQ;
            tREQsync1   <= tREQsync0;
        end
    end

    always_comb begin
        case (CLOCK_RATIO)
        2'b00: tREQsync = tREQ;
        2'b01: tREQsync = tREQsync1;
        2'b10: tREQsync = tREQsync1;
        2'b11: tREQsync = tREQsync1;
        endcase
    end

    typedef enum logic [1:0] {
        STP_IDLE    = 2'b00,
        STP_SETUP   = 2'b01,
        STP_GO      = 2'b10,
        STP_WAIT    = 2'b11
    } P_state_t;
    
    P_state_t pstate;

    always_ff @(posedge PCLK or negedge PRESETn) begin
        if (!PRESETn) begin
            pstate  <= STP_IDLE;
        end else begin
            case (pstate)

                STP_IDLE: begin
                    if(tREQsync) begin
                        PSEL    <= 1'b1;
                        pstate  <= STP_SETUP;
                    end
                end // STP_IDLE
                STP_SETUP: begin
                    PENABLE <= 1'b1;
                    pstate  <= STP_GO;
                end // STP_SETUP
                STP_GO: begin
                    if(PREADY) begin
                        PENABLE <= 1'b0;
                        PSEL    <= 1'b0;
                        tACK    <= 1'b1;
                        tRDATA  <= PRDATA;
                        tERROR  <= PSLVERR;
                        pstate  <= STP_WAIT;
                    end
                end // STP_GO
                STP_WAIT: begin
                    if(CLOCK_RATIO == 2'b0)begin
                        tACK    <= 1'b0;
                        pstate  <= STP_IDLE;
                    end else begin
                        if(tREQsync == 1'b0) begin
                            tACK    <= 1'b0;
                            pstate  <= STP_IDLE;
                        end
                    end
                end // STP_WAIT
            endcase // pstate
        end // if else
    end // always


    //--------------------------------------------------------//
    function automatic logic [3:0] get_strb(
        input logic [1:0] add,
        input logic [2:0] size 
    );

    logic [3:0] be;
    begin
        case ({size,add})
            
            `ifdef ENDIAN_BIG
                5'b010_00: be   = 4'b1111; // word
                5'b001_00: be   = 4'b1100; // halfword
                5'b001_10: be   = 4'b0011;
                5'b000_00: be   = 4'b1000; // byte
                5'b000_01: be   = 4'b0100;
                5'b000_10: be   = 4'b0010;
                5'b000_11: be   = 4'b0001;
            `else // little-endian -- default
                5'b010_00: be   = 4'b1111;
                5'b001_00: be   = 4'b0011;
                5'b001_10: be   = 4'b1100;
                5'b000_00: be   = 4'b0001;
                5'b000_01: be   = 4'b0010;
                5'b000_10: be   = 4'b0100;
                5'b000_11: be   = 4'b1000;
            `endif // ENDIAN_BIG

            default: begin
                be = 4'b0;
            end
        endcase

        get_strb = be;
    end
        
    endfunction
endmodule