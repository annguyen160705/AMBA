module ahb2ahb_slave_core #(
    parameter FIFO_AW=5
) (
    //--------------------------------------------------------//
    // AHB slave port
      input logic   HRESETn
    , input logic   HCLK

    , input logic   HSEL
    , input logic [31:0]    HADDR
    , input logic [1:0]     HTRANS
    , input logic           HWRITE
    , input logic [2:0]     HSIZE
    , input logic [2:0]     HBURST
    , input logic [31:0]    HWDATA
    , output logic [31:0]   HRDATA
    , output logic [1:0]    HRESP
    , input logic           HREADYin
    , output logic          HREADYout

    //--------------------------------------------------------//
    // FIFO forward: address related
    , output logic          fwr_clk
    , input logic           fwr_rdy
    , output logic          fwr_vld
    , output logic [31:0]         fwr_dat
    , input logic           fwr_full
    , input logic [FIFO_AW:0] fwr_cnt // how many rooms available
    //--------------------------------------------------------//
    // FIFO backward: data related
    , output logic          brd_clk
    , output logic          brd_rdy
    , input logic           brd_vld
    , input logic [31:0]    brd_dat
    , input logic           brd_empty
    , input logic [FIFO_AW:0] brd_cnt // how many items available
);

    //--------------------------------------------------------//
    assign fwr_clk  = HCLK;
    assign brd_clk  = HCLK;
    //--------------------------------------------------------//
    logic [31:0]    T_ADDR;
    logic           T_WRITE;
    logic [1:0]     T_TRANS;
    logic [2:0]     T_BURST;
    logic [2:0]     T_SIZE;
    logic [4:0]     T_LENG;
    logic [4:0]     counter;
    //--------------------------------------------------------//

    typedef enum logic [2:0] {
        STH_IDLE    = 3'b000,
        STH_WAIT    = 3'b001,
        STH_ADDR    = 3'b010,
        STH_READ0   = 3'b011,
        STH_READ1   = 3'b100,
        STH_READ2   = 3'b101,
        STH_WRITE0  = 3'b110,
        STH_WRITE1  = 3'b111
    } state_t;

    state_t state;

    always_ff @(posedge HCLK or negedge HRESETn) begin
        if (!HRESETn) begin
            // AHB Bus Outputs:
            HRDATA     <= 32'h0; // Clears stale data; prevents X-propagation (unknown states) on the bus.
            HREADYout  <= 1'b1;  // MUST be 1 on reset. If 0, the AHB master gets permanently stalled waiting for a ready signal that never comes.
            HRESP      <= 2'b00; // Defaults to OKAY (00). Prevents sending false ERROR or RETRY signals to the master on power-up.

            // Forward FIFO (Push interface):
            fwr_vld    <= 1'b0;  // MUST be 0. If 1, the slave would accidentally push garbage data into the FIFO during reset.
            fwr_dat    <= 32'h0; // Clears data payload; prevents pushing X-states into the FIFO.

            // Backward FIFO (Pop interface):
            brd_rdy    <= 1'b0;  // MUST be 0. If 1, the slave might accidentally pop and delete unread data from the FIFO before the FSM is ready.

            // Internal Transaction Registers:
            T_ADDR     <= 32'h0; // Wipes the last accessed address.
            T_WRITE    <= 1'b0;  // Defaults to read (safe mode); prevents accidental phantom writes.
            T_TRANS    <= 2'h0;  // Defaults to IDLE; clears any pending sequential/non-sequential transfer states.
            T_BURST    <= 3'h0;  // Clears the burst type history.
            T_SIZE     <= 3'h0;  // Clears the transfer size history.
            T_LENG     <= 'h0;   // Clears the calculated burst length.

            // FSM Tracking Logic:
            counter    <= 5'h0;  // Resets the beat counter so the next burst correctly starts at beat 1.
            state   <= STH_IDLE;
        end else begin
            case (state)
                STH_IDLE: begin
                    fwr_vld <= 1'b0;
                    if(HSEL && HREADYin) begin
                        case (HTRANS)
                            2'b00, 2'b01: begin //`HTRANS_IDLE,`HTRANS_BUSY
                                HREADYout   <= 1'b1;
                                state       <= STH_IDLE;
                            end
                            2'b10, 2'b11: begin //`HTRANS_NONSEQ,`HTRANS_SEQ
                                T_ADDR  <= HADDR;
                                T_WRITE <= HWRITE;
                                T_TRANS <= HTRANS;
                                T_BURST <= HBURST;
                                T_SIZE  <= HSIZE;
                                T_LENG  <= burst_leng(HBURST);
                                HREADYout   <= 1'b0;
                                if(fwr_rdy&&(fwr_cnt>(burst_leng(HBURST)+2)))begin
                                    fwr_dat <= {HSIZE,HBURST,HTRANS,HWRITE};
                                    fwr_vld <= 1'b1;
                                    state   <= STH_ADDR;
                                end else begin
                                    state   <= STH_WAIT;
                                end
                            end
                        endcase
                    end else begin //if (HSEL && HREADYin)
                        HREADYout   <= 1'b1;
                    end
                end   
                STH_WAIT: begin
                    if(fwr_rdy && (fwr_cnt>(T_LENG+2))) begin
                        fwr_dat <= {T_SIZE,T_BURST,T_TRANS,T_WRITE};
                        fwr_vld <= 1'b1;
                        state   <= STH_ADDR;
                    end else begin
                        fwr_vld <= 1'b0;
                    end
                end  
                STH_ADDR: begin
                    if(fwr_rdy) begin
                        fwr_dat <= T_ADDR;
                        fwr_vld <= 1'b1;
                        if(T_WRITE) begin
                            counter     <= 1;
                            state        <= STH_WRITE0;
                        end else begin
                            HREADYout   <= 1'b0;
                            state       <= STH_READ0;   
                        end
                    end
                end  
                //--------------------------------------------------------//
                // READ
                STH_READ0: begin
                    if (fwr_rdy) begin
                        fwr_vld <= 1'b0;
                        state   <= STH_READ1;
                    end
                end 
                STH_READ1: begin
                    if(brd_vld && (brd_cnt >= T_LENG)) begin
                        brd_rdy <= 1'b1;
                        counter <= 1;
                        state   <= STH_READ2;
                    end
                end 
                STH_READ2: begin
                    HRDATA      <= brd_dat;
                    HREADYout   <= 1'b1;
                    counter     <= counter + 1;
                    if(counter >= T_LENG) begin
                        brd_rdy <= 1'b0;
                        state   <= STH_IDLE;
                    end
                end
                //--------------------------------------------------------//
                // WRITE
                STH_WRITE0: begin
                    HREADYout   <= 1'b1;
                    fwr_vld     <= 1'b0;
                    counter     <= 1;
                    state       <= STH_WRITE1;
                end
                STH_WRITE1: begin
                    fwr_dat <= HWDATA;
                    fwr_vld <= 1'b1;
                    counter <= counter + 1;
                    if(counter >= T_LENG) begin
                        fwr_vld <= 1'b1;
                        if(HSEL && HREADYin) begin
                            case (HTRANS)
                                2'b00, 2'b01: begin //`HTRANS_IDLE,`HTRANS_BUSY
                                    HREADYout   <= 1'b1;
                                    state       <= STH_IDLE;
                                end
                                2'b10, 2'b11: begin //`HTRANS_NONSEQ,`HTRANS_SEQ
                                    T_ADDR  <= HADDR;
                                    T_WRITE <= HWRITE;
                                    T_TRANS <= HTRANS;
                                    T_BURST <= HBURST;
                                    T_SIZE  <= HSIZE;
                                    T_LENG  <= burst_leng(HBURST);
                                    HREADYout   <= 1'b0;
                                    state   <= STH_WAIT;
                                end
                            endcase
                        end else begin
                            state   <= STH_IDLE;
                        end
                    end
                end
            endcase
        end
    end


    function automatic logic [4:0] burst_leng(
        input logic [2:0] burst
    );

        begin
            case (burst)
                3'b010, 3'b011: burst_leng  = 5'h04; // increment & wrap 4
                3'b100, 3'b101: burst_leng  = 5'h08; // increment & wrap8
                3'b110, 3'b111: burst_leng  = 5'h10; // increment & wrap16
                default: burst_leng = 5'h01;         // all other
            endcase    
        end
        
    endfunction
    
endmodule