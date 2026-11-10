`timescale 1ns/1ns

module axi_arbiter_mtos_m2

     #(parameter WIDTH_CID=4  // Channel ID width in bits
                 , WIDTH_ID =4 // Transaction ID
                 , WIDTH_SID=(WIDTH_CID+WIDTH_ID)
                 , NUM = 2
                 )
(
       input  logic                  ARESETn
     , input  logic                  ACLK
     //-----------------------------------------------------------
     , input  logic  [NUM-1:0]       AWSELECT  // selected by address decoder
     , input  logic  [NUM-1:0]       AWVALID
     , input  logic  [NUM-1:0]       AWREADY
     , input  logic  [NUM-1:0]       AWLOCK    // lock-bit only not exclusive-bit
     , output logic  [NUM-1:0]       AWGRANT
     , input  logic  [WIDTH_SID-1:0] AWSID0    // {master_id,trans_id}
     , input  logic  [WIDTH_SID-1:0] AWSID1    // {master_id,trans_id}
     //-----------------------------------------------------------
     , input  logic  [NUM-1:0]       WVALID
     , input  logic  [NUM-1:0]       WLAST
     , input  logic  [NUM-1:0]       WREADY
     , output logic   [NUM-1:0]       WGRANT
     , input  logic  [WIDTH_SID-1:0] WSID0   // {master_id,trans_id}
     , input  logic  [WIDTH_SID-1:0] WSID1   // {master_id,trans_id}
     //-----------------------------------------------------------
     , input  logic  [NUM-1:0]       ARSELECT  // selected by address decoder
     , input  logic  [NUM-1:0]       ARVALID
     , input  logic  [NUM-1:0]       ARLOCK    // lock-bit only not exclusive-bit
     , input  logic  [NUM-1:0]       ARREADY
     , output logic  [NUM-1:0]       ARGRANT
     , input  logic  [WIDTH_SID-1:0] ARSID0    // {master_id,trans_id}
     , input  logic  [WIDTH_SID-1:0] ARSID1    // {master_id,trans_id}
     //-----------------------------------------------------------
     , input  logic  [WIDTH_CID-1:0] MID0  // master0 id
     , input  logic  [WIDTH_CID-1:0] MID1  // master0 id
);

    logic                  locked, unlock;
    logic  [WIDTH_SID-1:0] locksid; // {master_id,trans_id}

    logic [WIDTH_SID-1:0] granted_arsid = ({WIDTH_SID{ARGRANT[0]}}&ARSID0)
                                        | ({WIDTH_SID{ARGRANT[1]}}&ARSID1);
    logic  [NUM-1:0] argrant_reg;
    // The atomic access should consist of a read followed by a write.
    // The atomic access should be a single burst transfer.

    typedef enum logic [1:0] {
        STAR_RUN    = 2'b00,
        STAR_WAIT   = 2'b01,
        STAR_LOCK   = 2'b10
    } AR_state_t;

    AR_state_t stateAR;

    always @ (posedge ACLK or negedge ARESETn) begin
            if (ARESETn==1'b0) begin
                locked      <= 1'b0;
                locksid     <=  'h0;
                argrant_reg <= 'h0;
                stateAR <= STAR_RUN;
            end else begin
                case (stateAR)

                STAR_RUN: begin
                    if (|(ARGRANT&ARLOCK)) begin // note that ARLOCK={M1_ARLOCK[1],M1_ALOCK[1]}
                        locked      <= 1'b1;
                        locksid     <= granted_arsid;
                        argrant_reg <= ARGRANT;
                        stateAR     <= STAR_LOCK;
                    end else begin
                        if (|ARGRANT) begin
                           // prevent the case that
                           // the granted-one is not completed dueo to ~ARREADY
                           // and new higher-priority-one joined,
                           // then things can go wrong.
                           if (~|(ARGRANT&ARREADY)) begin
                               argrant_reg <= ARGRANT;
                               stateAR     <= STAR_WAIT;
                           end
                        end
                    end
                end // STAR_RUN

                STAR_WAIT: begin
                    if (|(ARGRANT&ARVALID&ARREADY)) begin
                        stateAR <= STAR_RUN;
                    end 
                end // STAR_WAIT

                STAR_LOCK: begin
                    if (unlock) begin
                        locked      <= 1'b0;
                        locksid     <=  'h0;
                        argrant_reg <=  'h0;
                        stateAR     <= STAR_RUN;
                    end  
                end // STAR_LOCK
                    
                    default: begin
                        stateAR <= STAR_RUN;
                    end
                endcase
            end
    end

        //-----------------------------------------------------------
        assign ARGRANT = (stateAR==STAR_RUN) ? priority_sel(ARSELECT&ARVALID)
                                            : argrant_reg;
        //-----------------------------------------------------------
        // write-address arbiter
        //-----------------------------------------------------------
        logic [WIDTH_SID-1:0] fifo_push_din   = (AWGRANT[0]==1'b1) ? AWSID0
                                            : (AWGRANT[1]==1'b1) ? AWSID1
                                            : 'h0;
        logic                 fifo_push_valid = |(AWGRANT&AWREADY);
        logic                 fifo_pop_ready;
        logic                 fifo_pop_valid;
        logic [WIDTH_SID-1:0] fifo_pop_dout ;
        //-----------------------------------------------------------
        logic [NUM-1:0] awgrant_reg;
        //-----------------------------------------------------------

        typedef enum logic [1:0] {
            STAW_RUN    = 2'b00,
            STAW_WAIT   = 2'b01,
            STAW_LOCK   = 2'b10
        } AW_state_t;

        AW_state_t stateAW;

        always_ff @ (posedge ACLK or negedge ARESETn) begin
            if (ARESETn==1'b0) begin
                awgrant_reg <=  'h0;
                unlock      <= 1'b0;
                stateAW     <= STAW_RUN;
            end else begin
                case (stateAW)
                    
                    STAW_RUN: begin
                        if (|AWGRANT) begin
                            if (~|(AWGRANT&AWREADY)) begin
                               awgrant_reg <= AWGRANT;
                               stateAW     <= STAW_WAIT;
                            end
                        end else begin
                            if (locksid[WIDTH_SID-1:WIDTH_ID]==MID0) begin
                                if (AWSELECT[0]&AWVALID[0]) begin
                                    if (locksid[WIDTH_SID-1:WIDTH_ID]==AWSID0[WIDTH_SID-1:WIDTH_ID]) begin
                                        awgrant_reg <= 2'b01;
                                        if (~AWLOCK[0]) unlock <= 1'b1;
                                        else            unlock <= 1'b0;
                                        stateAW <= STAW_LOCK;
                                    end else begin
                                        // synopsys translate_off
                                        `ifdef RIGOR
                                        $display($time,,"%m ERROR un-expected write-request during lock 0x%x",
                                                            AWSID0);
                                        `endif
                                        // synopsys translate_on
                                    end
                                end
                            end else if (locksid[WIDTH_SID-1:WIDTH_ID]==MID1) begin
                                if (AWSELECT[1]&AWVALID[1]) begin
                                    if (locksid[WIDTH_SID-1:WIDTH_ID]==AWSID1[WIDTH_SID-1:WIDTH_ID]) begin
                                        awgrant_reg <= 2'b10;
                                        if (~AWLOCK[1]) unlock <= 1'b1;
                                        else            unlock <= 1'b0;
                                        stateAW <= STAW_LOCK;
                                    end else begin
                                        // synopsys translate_off
                                        `ifdef RIGOR
                                        $display($time,,"%m ERROR un-expected write-request during lock 0x%x",
                                                            AWSID1);
                                        `endif
                                        // synopsys translate_on
                                    end
                                end
                            end
                                // synopsys translate_off
                                `ifdef RIGOR
                                else begin
                                    $display($time,,"%m ERROR un-expected MID for lock 0x%x",
                                                    locksid[WIDTH_SID-1:WIDTH_ID]);
                                end
                                `endif
                                // synopsys translate_on
                        end  
                    end

                    STAW_WAIT: begin
                        if (|(AWGRANT&AWVALID&AWREADY)) begin
                        awgrant_reg <= 'h0;
                        stateAW     <= STAW_RUN;
                        end
                    end // STAW_WAIT

                    STAW_LOCK: begin
                        if (|(AWGRANT&AWVALID&AWREADY)) begin
                        awgrant_reg <=  'h0;
                        unlock      <= 1'b0;
                        stateAW     <= STAW_RUN;
                        end
                    end // STAW_LOCK

                    default: begin
                        stateAW <= STAW_RUN;
                    end
                endcase
            end
        end


        assign AWGRANT = ((stateAW==STAW_RUN)&~locked)  ? priority_sel(AWSELECT&AWVALID)
                                                        : awgrant_reg;

    axi_arbiter_fifo_sync #(.FDW(WIDTH_SID), .FAW(4))
    Uaxi_arbiter_fifo_sync
        (
            .rstn     (ARESETn)
            , .clr      (1'b0   )
            , .clk      (ACLK   )
            , .wr_rdy   (               )
            , .wr_vld   (fifo_push_valid)
            , .wr_din   (fifo_push_din  )
            , .rd_rdy   (fifo_pop_ready )
            , .rd_vld   (fifo_pop_valid )
            , .rd_dout  (fifo_pop_dout  )
            , .full     (               )
            , .empty    ()
            , .fullN    ()
            , .emptyN   ()
            , .item_cnt ()
            , .room_cnt ()
        );

    logic active_wvalid = |(WGRANT&WVALID);
    logic active_wready = |WREADY;
    logic active_wlast  = |(WGRANT&WLAST);

    assign fifo_pop_ready = fifo_pop_valid
                           & active_wvalid
                           & active_wready
                           & active_wlast;
    always @ ( * ) begin
            if (~fifo_pop_valid) begin
                WGRANT = 2'b00;
            end else begin
                if (fifo_pop_dout[WIDTH_SID-1:WIDTH_ID]==MID0) begin
                    WGRANT = 2'b01;
                end else if (fifo_pop_dout[WIDTH_SID-1:WIDTH_ID]==MID1) begin
                    WGRANT = 2'b10;
                end else begin
                    WGRANT = 2'b00;
                end
            end
    end

    // synopsys translate_off
     `ifdef RIGOR
     always @ (negedge ACLK or negedge ARESETn) begin
          if (ARESETn==1'b1) begin
              if (fifo_pop_valid&~|WGRANT) begin
                  $display($time,,"%m ERROR FIFO valid, but none granted WGRANT");
              end
          end
     end
     `endif
    // synopsys translate_on


    function automatic logic [NUM-1:0] priority_sel(
        input [NUM-1:0] request
    );
        begin
          casex (request)
          2'b00: priority_sel = 2'b00;
          2'bx1: priority_sel = 2'b01;
          2'b10: priority_sel = 2'b10;
          endcase
        end
        
    endfunction

endmodule