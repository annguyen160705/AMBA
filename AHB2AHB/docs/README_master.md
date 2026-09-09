# WRITE-EXAMPLE
```systemverilog
case (state)
                
                STH_IDLE        :begin
                    if(frd_vld&(frd_cnt >= 2))  begin // frd_vld = 1, frd_cnt = 6 (6 >= 2 is true. We have 1 control + 1 address + 4 data words)
                        {T_SIZE,T_BURST,T_TRANS,T_WRITE} <= frd_dat; // Word 1 (Control): 32'h0000_009D. T_SIZE = 3'b010, T_BURST = 3'b011 (INCR4), T_TRANS = 2'b10, T_WRITE = 1'b1
                        frd_rdy_loc <= 1'b1; // Pop control; address replaces it next.
                        state <= STH_GET_ADDR0; // state = STH_GET_ADDR0 (Moves to the next step)
                    end

                    if (HREADY && check_resp)   begin // HREADY = 1, check_resp = 0 (0 means false, so this block is skipped for this example)
                        check_resp <= 1'b0;
                        if (HRESP! = 2'b00) $display($time,"%m ERROR non-OK response");

                    end
                end      
                STH_GET_ADDR0   : begin
                    T_LENG  <= burst_leng(T_BURST); // T_BURST = 3'b011, so burst_leng() returns 4. T_LENG = 4
                    state   <= STH_GET_ADDR1; // state = STH_GET_ADDR1
                end
                STH_GET_ADDR1   : begin
                     T_ADDR <= frd_dat; // Word 2 (Address): 32'h4000_1000. T_ADDR = 32'h4000_1000.
                     HBUSREQ    <= 1'b1; // HBUSREQ = 1 (Master asks for AHB bus access)
                     if (T_WRITE) begin // T_WRITE = 1 (True. This is a write transaction, so we enter this block)
                        if(frd_cnt > T_LENG) begin // frd_cnt = 6, T_LENG = 4. (6 > 4 is true. We have enough data to complete the burst)
                            frd_rdy_loc <= 1'b0; // frd_rdy_loc = 0 (Stop popping from the FIFO temporarily)
                            state   <= STH_WRITE_ARB; // state = STH_WRITE_ARB (Move to wait for bus arbitration)
                        end else begin // Skipped (Would trigger if frd_cnt was 3, meaning we'd have to wait for more data)
                            frd_rdy_loc <= 1'b0;
                            state   <= STH_WRITE_WAIT;
                        end
                     end else begin // Skipped (Would trigger if T_WRITE = 0, meaning it's a read transaction)
                        frd_rdy_loc <= 1'b0;
                        if(bwr_rdy&(bwr_cnt >= T_LENG)) begin 
                            state   <= STH_READ_ARB;
                        end else begin
                            state   <= STH_READ_WAIT;
                        end
                     end
                end
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
                        frd_rdy_gate    <= 1'b1; // Links the FIFO pop mechanism directly to HREADY so data flows automatically.
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
                        HWDATA  <= frd_dat; // Word 3 (Data 1): frd_dat is now 32'h1111_1111.
                        if(T_LENG>1) begin // 4 > 1 is true.
                            HADDR   <= get_next_haddr(HADDR,T_BURST); // Calculates next address: 32'h4000_1004.
                            HTRANS  <= 2'b11; // NON-SEQ -> SEQ
                            counter <= counter +1; // counter becomes 2.
                            state   <= STH_WRITE1; // Moves to the looping state.
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
                        HWDATA  <= frd_dat; // Loop 1: Word 4 (32'h2222_2222). Loop 2: Word 5 (32'h3333_3333). Loop 3: Word 6 (32'h4444_4444).
                        if (counter >= T_LENG) begin // On Loop 3, counter == 4. Burst is done.
                            HBUSREQ <= 1'b0; // Drop bus request.
                            HTRANS  <= 2'b00; // IDLE
                            frd_rdy_gate    <= 1'b0; // Disconnect FIFO from HREADY.
                            state   <= STH_WRITE2; // Move to cleanup.
                        end else begin
                            HADDR   <= get_next_haddr(HADDR,T_BURST); // Loop 1: 0x4000_1008. Loop 2: 0x4000_100C.
                            HTRANS  <= 2'b11; // Stays SEQ.
                            counter <= counter + 1; // Increments to 3, then 4.
                        end
                        if(HRESP!=2'b00) $display($time,"%m ERROR non-OK response ");

                    end
                end 
                STH_WRITE2      : begin
                    state   <= STH_IDLE; // Transaction complete, back to idle.
                    check_resp  <= 1'b1;
                end
```

# READ-EXAMPLE
```systemverilog
              case (state)              
                STH_IDLE        :begin
                    if(frd_vld&(frd_cnt >= 2))  begin // frd_vld = 1, frd_cnt = 2 (We have 1 control word + 1 address word waiting)
                        {T_SIZE,T_BURST,T_TRANS,T_WRITE} <= frd_dat; // Word 1 (Control): 32'h0000_009C. T_SIZE = 3'b010, T_BURST = 3'b011 (INCR4), T_TRANS = 2'b10, T_WRITE = 1'b0 (Read)
                        frd_rdy_loc <= 1'b1; // Pop control; address replaces it next.
                        state <= STH_GET_ADDR0; // Moves to the next step to process the address
                    end

                    if (HREADY && check_resp)   begin // HREADY = 1, check_resp = 0 (Skipped for this setup)
                        check_resp <= 1'b0;
                        if (HRESP! = 2'b00) $display($time,"%m ERROR non-OK response");

                    end
                end
                
                STH_GET_ADDR0   : begin
                    T_LENG  <= burst_leng(T_BURST); // T_BURST = 3'b011, so burst_leng() returns 4. T_LENG = 4.
                    state   <= STH_GET_ADDR1;
                end
                STH_GET_ADDR1   : begin
                     T_ADDR <= frd_dat; // Word 2 (Address): 32'h8000_2000.
                     HBUSREQ    <= 1'b1; // Master asks for AHB bus access.
                     if (T_WRITE) begin // T_WRITE = 0 (False. This is a read transaction, so we skip this write block)
                        if(frd_cnt > T_LENG) begin
                            frd_rdy_loc <= 1'b0;
                            state   <= STH_WRITE_ARB;
                        end else begin
                            frd_rdy_loc <= 1'b0;
                            state   <= STH_WRITE_WAIT;
                        end
                     end else begin // READ PATH enters here
                        frd_rdy_loc <= 1'b0; // Stop popping from forward FIFO
                        if(bwr_rdy&(bwr_cnt >= T_LENG)) begin // bwr_cnt >= 4. Verifies backward FIFO has room.
                            state   <= STH_READ_ARB; // Enough room exists, move to request bus.
                        end else begin
                            state   <= STH_READ_WAIT; // Stall if not enough room.
                        end
                     end
                end

                STH_READ_WAIT   : begin
                    if  (bwr_rdy & (bwr_cnt >= T_LENG)) begin // Waits here until backward FIFO has at least 4 empty slots.
                        state   <= STH_READ_ARB; 
                    end
                end
                STH_READ_ARB    : begin
                    if(HGRANT && HREADY) begin // Master is granted the AHB bus.
                        HADDR   <= T_ADDR; // Drives Word 2 (Address): 32'h8000_2000 onto the bus.
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
                    if (HREADY) begin // The bus accepted the first address (0x8000_2000).
                        if(T_LENG>1) begin // 4 > 1 is true.
                            HADDR   <= get_next_haddr(HADDR, T_BURST); // Fixed typo: Calculates and issues 2nd address: 32'h8000_2004.
                            HTRANS  <= 2'b11; //SEQ
                            state   <= STH_READ1; // Moves to pipelined loop to start catching data.
                        end else begin
                            HBUSREQ <= 1'b0;
                            HTRANS  <= 2'b00;
                            state   <= STH_READ2;
                        end
                    end
                end       
                STH_READ1       : begin
                    if(HREADY) begin
                        bwr_vld <= 1'b1; // Enables writing to the backward FIFO.
                        bwr_dat <= HRDATA; // Loop 1: Catches Word 3 (32'h1111_1111). Loop 2: Catches Word 4 (32'h2222_2222). Loop 3: Catches Word 5 (32'h3333_3333).
                        
                        if(counter >= T_LENG) begin // On Loop 3, counter == 4. All addresses have been issued.
                            HBUSREQ <= 1'b0; // Drops bus request.
                            HTRANS  <= 2'b00; // IDLE
                            state   <= STH_READ2; // Break loop, move to catch the final piece of data.
                        end else begin
                            HADDR   <= get_next_haddr(HADDR, T_BURST); // Loop 1: Issues 0x8000_2008. Loop 2: Issues 0x8000_200C.
                            HTRANS  <= 2'b11;
                            counter <= counter + 1; // Increments to 3, then 4.
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
                        bwr_dat <= HRDATA; // Catches Word 6 (32'h4444_4444). The 4th and final data beat from the final address issued in STH_READ1.
                        state   <= STH_READ3; // Move to cleanup.
                        // synthesis translate_off
                        if (HRESP!=2'b00) $display($time,,"%m ERROR non-OK response");
                        // synthesis translate_on
                    end else begin
                        bwr_vld <= 1'b0;
                    end

                end 
                STH_READ3       : begin
                    bwr_vld <= 1'b0; // Stop writing to the backward FIFO.
                    state   <= STH_IDLE; // Transaction complete, back to idle.
                    check_resp  <= 1'b0; // Resets check_resp
                end
```

# burst_leng EXAMPLE
```systemverilog
function [4:0] burst_leng;
        input [2:0] burst; // burst = 3'b011 (Passed from T_BURST extracted from Word 1 Control: 32'h0000_009C/9D)
   begin
        case (burst) // Evaluates burst = 3'b011
        3'b010, 3'b011:  burst_leng = 5'h04;  // Matches! Returns 4 beats, so T_LENG = 4 for our INCR4 burst
        3'b100, 3'b101:  burst_leng = 5'h08;  // increment & wrap8
        3'b110, 3'b111:  burst_leng = 5'h10;  // increment & wrap16
        default: burst_leng = 5'h01;  // all other
        endcase
   end
   endfunction
```

# get_next_haddr EXAMPLE
```systemverilog
function automatic logic [31:0] get_next_haddr(
        input logic [31:0] haddr, // haddr = 32'h8000_2000 (Current address passed from STH_READ0/WRITE0)
        input logic [2:0] burst   // burst = 3'b011 (T_BURST for INCR4 from Word 1 Control: 32'h0000_009C)
    );

        logic [3:0] wrap;
        begin
            wrap = haddr[5:2]+1; // wrap = 4'h0 + 1 = 4'h1 (Calculated for potential WRAP bursts)
            case (burst) // Evaluates burst = 3'b011
                3'b010: get_next_haddr = {haddr[31:4],wrap[1:0],2'b0}; // WRAP4 (Skipped for INCR4)
                3'b100: get_next_haddr = {haddr[31:5],wrap[2:0],2'b0}; // WRAP8 (Skipped)
                3'b110: get_next_haddr = {haddr[31:6],wrap[3:0],2'b0}; // WRAP16 (Skipped)
                default: begin
                    get_next_haddr = haddr + 4; // Matches INCR4! 32'h8000_2000 + 4 = 32'h8000_2004 (Next sequential address)
                end
            endcase
        end
        
    endfunction
```

```systemverilog
function automatic logic [31:0] get_next_haddr(
        input logic [31:0] haddr, // haddr = 32'h8000_200C (Current address nearing boundary)
        input logic [2:0] burst   // burst = 3'b010 (WRAP4)
    );

        logic [3:0] wrap;
        begin
            wrap = haddr[5:2]+1; // wrap = 3 + 1 = 4 (4'b0100)
            case (burst) // Evaluates burst = 3'b010
                3'b010: get_next_haddr = {haddr[31:4], wrap[1:0], 2'b0}; // Matches WRAP4! Lower bits wrap: {8000_200, 2'b00, 2'b0} = 32'h8000_2000
                3'b100: get_next_haddr = {haddr[31:5], wrap[2:0], 2'b0}; // WRAP8 (Skipped)
                3'b110: get_next_haddr = {haddr[31:6], wrap[3:0], 2'b0}; // WRAP16 (Skipped)
                default: begin
                    get_next_haddr = haddr + 4; // Skipped for WRAP
                end
            endcase
        end
        
    endfunction
```