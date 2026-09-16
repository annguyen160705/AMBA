```systemverilog
        case (state)
            ST_IDLE: begin
                // Wait for APB Setup Phase (PSEL high, PENABLE low)
                if (PSEL) begin // PSEL = 1 (True. Master is targeting this slave)
                    if (DELAY == 0) begin // DELAY = 2 (2 == 0 is False. Skip this block)
                        // ... skipped ...
                    end else begin // Enters here because DELAY > 0
                        PREADY          <= 1'b0;  // PREADY = 0 (Tell master to stall/wait)
                        dcnt            <= 'h1;   // dcnt = 1 (Initialize the counter at 1)
                        state           <= ST_DELAY; // state = ST_DELAY (Move to wait state)
                    end 
                end 
            end

            ST_DELAY: begin
                // Counting Wait States
                dcnt <= dcnt + 1; // Cycle 1: dcnt evaluates as 1, becomes 2. Cycle 2: dcnt evaluates as 2, becomes 3.
                
                if (dcnt >= DELAY) begin // Cycle 1: (1 >= 2) is False (Skips block). Cycle 2: (2 >= 2) is True! (Enters block).
                    PREADY      <= 1'b1; // PREADY = 1 (Tell master we are ready to finish the transfer)
                    state       <= ST_DONE; // state = ST_DONE
                    
                        if (!PWRITE) begin // PWRITE = 1 (!1 is False. This is a write, skip read block)
                            // ... skipped ...
                        end else begin // WRITE PATH enters here on Cycle 2
                            // addr = 2 (Calculated from PADDR 0x8)
                            // PWDATA = 32'hDEADBEEF
                            // PSTRB = 4'b1111 (All bits true, all if-statements execute)
                            if (PSTRB[0]) mem0[addr] <= PWDATA[7:0];   // mem0[2] <= 8'hEF
                            if (PSTRB[1]) mem1[addr] <= PWDATA[15:8];  // mem1[2] <= 8'hBE
                            if (PSTRB[2]) mem2[addr] <= PWDATA[23:16]; // mem2[2] <= 8'hAD
                            if (PSTRB[3]) mem3[addr] <= PWDATA[31:24]; // mem3[2] <= 8'hDE
                        end
                end
            end

            ST_DONE: begin // Enters this state on the next clock cycle (Cycle 3)
                PREADY  <= 1'b1; // Keeps PREADY high to safely complete the APB Access Phase
                state   <= ST_IDLE; // Transaction complete, return to IDLE to wait for next PSEL
            end
        endcase
```