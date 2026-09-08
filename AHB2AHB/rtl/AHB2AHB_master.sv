
// Signal naming convention:
//    * forward: address and control information comes in
//    * backward: data information goes out
//    * frd_ : forward and fifo-read
//    * bwr_ : backward and fifo-write

module AHB2AHB_master#(
    parameter FIFO_AW = 5
)(
    //--------------------------------------------------------//
    //AHB master port
    input   logic           HRESETn,
    input   logic           HCLK,
    input   logic           HGRANT,
    input   logic [31:0]    HRDATA,
    input   logic [1:0]     HRESP,
    input   logic           HREADY,
    output  logic           HBUSREQ,
    output  logic [31:0]    HADDR,
    output  logic [1:0]     HTRANS,
    output  logic           HWRITE,
    output  logic [2:0]     HSIZE, 
    output  logic [2:0]     HBURST,
    output  logic [31:0]    HWDATA,

    //--------------------------------------------------------//
    // FIFO forward port: address related
    output  logic               frd_clk,
    output  logic               frd_rdy,
    input   logic               frd_vld,
    input   logic [31:0]        frd_dat,
    input   logic               frd_empty,
    input   logic [FIFO_AW:0]   frd_cnt,  

    //--------------------------------------------------------//
    // FIFO backward port: data related
    output  logic               bwr_clk,
    input   logic               bwr_rdy,
    output  logic               bwr_vld,
    output  logic [31:0]        bwr_dat,
    input   logic               bwr_full,
    input   logic [FIFO_AW:0]   bwr_cnt 
);
    
    //--------------------------------------------------------//
    assign frd_clk  = HCLK;
    assign bwr_clk  = HCLK;
    //--------------------------------------------------------//

    logic [31:0] T_ADDR;
    logic T_WRITE;
    logic [1:0]     T_TRANS;
    logic [2:0]     T_SIZE; 
    logic [2:0]     T_BURST; 
    logic [4:0]     T_LENG; 
    logic [4:0]     counter;
    logic frd_rdy_gate; 
    logic frd_rdy_loc;

    // synthesis translate_off
    logic check_resp = 1'b0;
    // synthesis translate_on;
    //--------------------------------------------------------//
    assign frd_rdy = (frd_rdy_gate) ? HREADY : frd_rdy_loc;

    typedef enum logic [3:0] {
        STH_IDLE        = 'h0,
        STH_GET_ADDR0   = 'h1,
        STH_GET_ADDR1   = 'h2,
        STH_READ_WAIT   = 'h3,
        STH_READ_ARB    = 'h4,
        STH_READ0       = 'h5,
        STH_READ1       = 'h6,
        STH_READ2       = 'h7,
        STH_READ3       = 'h8,
        STH_WRITE_WAIT  = 'h9,
        STH_WRITE_ARB   = 'hA,
        STH_WRITE0      = 'hB,
        STH_WRITE1      = 'hC,
        STH_WRITE2      = 'hD
    } state_t;

    state_t state;

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if(!HRESETn) begin
            HBUSREQ  <= 1'b0;
           HADDR    <= ~32'h0;
           HTRANS   <= 2'h0;
           HWRITE   <= 1'b0;
           HSIZE    <= 3'h0;
           HBURST   <= 3'h0;
           HWDATA   <= 32'h0;
           frd_rdy_gate <= 1'b0;
           frd_rdy_loc  <= 1'b0;
           bwr_vld  <= 1'b0;
           bwr_dat  <= 32'h0;
           counter  <= 'h0;
           T_ADDR   <= 23'h0;
           T_WRITE  <= 1'b0;
           T_TRANS  <= 2'b0;
           T_SIZE   <= 3'b0;
           T_BURST  <= 3'b0;
           T_LENG   <= 5'h0;
           // synthesis translate_off
           check_resp <=1'b0;
           // synthesis translate_on
            state <= STH_IDLE;

        end else    begin
            case (state)
                
                STH_IDLE        :begin
                    if(frd_vld&(frd_cnt >= 2))  begin
                        {T_SIZE,T_BURST,T_TRANS,T_WRITE} <= frd_dat;
                        frd_rdy_loc <= 1'b1;
                        state <= STH_GET_ADDR0;
                    end

                    if (HREADY && check_resp)   begin
                        check_resp <= 1'b0;
                        if (HRESP != 2'b00) $display($time,"%m ERROR non-OK response");

                    end
                end
//-----------------------ADDRESS-STATE-----------------------------//      
                STH_GET_ADDR0   : begin
                    T_LENG  <= burst_leng(T_BURST);
                    state   <= STH_GET_ADDR1;
                end
                STH_GET_ADDR1   : begin
                     T_ADDR <= frd_dat;
                     HBUSREQ    <= 1'b1;
                     if (T_WRITE) begin
                        if(frd_cnt > T_LENG) begin
                            frd_rdy_loc <= 1'b0;
                            state   <= STH_WRITE_ARB;
                        end else begin
                            frd_rdy_loc <= 1'b0;
                            state   <= STH_WRITE_WAIT;
                        end
                     end else begin
                        frd_rdy_loc <= 1'b0;
                        if(bwr_rdy&(bwr_cnt >= T_LENG)) begin
                            state   <= STH_READ_ARB;
                        end else begin
                            state   <= STH_READ_WAIT;
                        end
                     end
                end
//------------------------DATA-WRITE-STATE-----------------------------//
                STH_WRITE_WAIT  : begin
                    if(frd_cnt >= T_LENG) begin
                        frd_rdy_loc <= 1'b0;
                        state   <= STH_WRITE_ARB;
                    end
                end
                STH_WRITE_ARB   : begin
                    frd_rdy_loc <= 1'b0;
                    if(HGRANT && HREADY) begin
                        HADDR   <=  T_ADDR;
                        HWRITE  <=  T_WRITE;
                        HTRANS  <=  T_TRANS;
                        HBURST  <=  T_BURST;
                        HSIZE   <=  T_SIZE;
                        counter <= 1;
                        frd_rdy_gate    <= 1'b1;
                        state   <= STH_WRITE0;
                        // synopsys translate_off
                        `ifdef RIGOR
                        if (T_TRANS!=2'b10) $display($time,,"%m: ERROR HTRANS is not NON_SEQ");
                        `endif
                        // synopsys translate_on

                    end
                end
                STH_WRITE0      : begin
                    if(HREADY) begin
                        HWDATA  <= frd_dat;
                        if(T_LENG>1) begin
                            HADDR   <= get_next_haddr(HADDR,T_BURST);
                            HTRANS  <= 2'b11; // NON-SEQ
                            counter <= counter +1;
                            state   <= STH_WRITE1;
                        end else begin
                            HBUSREQ <= 1'b0;
                            HTRANS  <= 2'b00;
                            frd_rdy_gate    <= 1'b0;
                            state   <= STH_WRITE2;
                        end
                    end
                end      
                STH_WRITE1      : begin
                    if(HREADY) begin
                        HWDATA  <= frd_dat;
                        if (counter >= T_LENG) begin
                            HBUSREQ <= 1'b0;
                            HTRANS  <= 2'b00;
                            frd_rdy_gate    <= 1'b0;
                            state   <= STH_WRITE2;
                        end else begin
                            HADDR   <= get_next_haddr(HADDR,T_BURST);
                            HTRANS  <= 2'b11;
                            counter <= counter + 1;
                        end
                        if(HRESP!=2'b00) $display($time,"%m ERROR non-OK response ");

                    end
                end 
                STH_WRITE2      : begin
                    state   <= STH_IDLE;
                    check_resp  <= 1'b1;
                end
//------------------------DATA-READ-STATE--------------------------//

                STH_READ_WAIT   : begin
                    if  (bwr_rdy & (bwr_cnt >= T_LENG)) begin
                        state   <= STH_READ_ARB;
                    end
                end
                STH_READ_ARB    : begin
                    if(HGRANT && HREADY) begin
                        HADDR   <= T_ADDR;
                        HWRITE  <= T_WRITE;
                        HTRANS  <= T_TRANS;
                        HBURST  <= T_BURST;
                        HSIZE   <= T_SIZE;
                        counter <= 2;
                        state   <= STH_READ0;
                    // synopsys translate_off
                      `ifdef RIGOR
                      if (T_TRANS!=2'b10) $display($time,,"%m: ERROR HTRANS is not NON_SEQ");
                      `endif
                    // synopsys translate_on
                    end
                end
                STH_READ0       : begin
                    if (HREADY) begin
                        if(T_LENG>1) begin
                            HADDR   <= get_next_haddr(HADDR,T_BURST);
                            HTRANS  <= 2'b11; //SEQ
                            state   <= STH_READ1;
                        end else begin
                            HBUSREQ <= 1'b0;
                            HTRANS  <= 2'b00;
                            state   <= STH_READ2;
                        end
                    end
                end       
                STH_READ1       : begin
                    if(HREADY) begin
                        bwr_vld <= 1'b1;
                        bwr_dat <= HRDATA;
                        if(counter >= T_LENG) begin
                            HBUSREQ <= 1'b0;
                            HTRANS  <= 2'b00;
                            state   <= STH_READ2;
                        end else begin
                            HADDR   <= get_next_haddr(HADDR,T_BURST);
                            HTRANS  <= 2'b11;
                            counter <= counter + 1;
                        end
                    // synthesis translate_off
                    if (HRESP!=2'b00) $display($time,,"%m ERROR non-OK response");
                    // synthesis translate_on
                    end else begin
                        bwr_vld <= 1'b0;
                    end
                end  
                STH_READ2       : begin
                    if(HREADY) begin
                        bwr_vld <= 1'b1;
                        bwr_dat <= HRDATA;
                        state   <= STH_READ3;
                        // synthesis translate_off
                        if (HRESP!=2'b00) $display($time,,"%m ERROR non-OK response");
                        // synthesis translate_on
                    end else begin
                        bwr_vld <= 1'b0;
                    end

                end 
                STH_READ3       : begin
                    bwr_vld <= 1'b0;
                    state   <= STH_IDLE;
                    check_resp  <= 1'b0;
                end  
  
            endcase
        end
    end

    function automatic logic [4:0] burst_leng(
        input logic [3:0] burst
    );

    case (burst)
        
        3'b010, 3'b011: burst_leng = 5'h04; //00100 increment & wrap 4
        3'b100, 3'b101: burst_leng = 5'h08; //01000 increment & wrap 8
        3'b110, 3'b111: burst_leng = 5'h10; //10000 increment & wrap 16

        default: begin
            burst_leng = 5'h01; //00001
        end
    endcase
        
    endfunction

    function automatic logic [31:0] get_next_haddr(
        input logic [31:0] haddr, //32'h0000_0000
        input logic [2:0] burst   //  
    );

        logic [3:0] wrap;
        begin
            wrap = haddr[5:2]+1;
            case (burst)
                3'b010: get_next_haddr = {haddr[31:4],wrap[1:0],2'b0};
                3'b100: get_next_haddr = {haddr[31:5],wrap[2:0],2'b0};
                3'b110: get_next_haddr = {haddr[31:6],wrap[3:0],2'b0};
                default: begin
                    get_next_haddr = haddr + 4;
                end
            endcase
        end
        
    endfunction

endmodule