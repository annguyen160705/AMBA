Scenario: The AHB Master initiates a Read from an APB peripheral.

CLOCK_RATIO = 2'b00 (1:1 synchronous, so tREQsync = tREQ and tACKsync = tACK).

HSEL = 1, HREADYin = 1

HTRANS = 2'b10 (NONSEQ)

HWRITE = 0 (READ)

HADDR = 32'h8000_2000

The APB Slave will return 32'h11223344 on PRDATA.


```systemverilog
// ==============================================================================
// CYCLE 1: AHB Address Phase & Immediate APB Request
// ==============================================================================
// Inside AHB FSM
    STH_IDLE: begin
        if (HSEL && HREADYin) begin // True! Master initiates a transfer.
            case(HTRANS)
                2'b10, 2'b11: begin // NONSEQ
                    HREADYout   <= 1'b0;          // STALL the AHB bus to wait for APB
                    tADDR       <= HADDR[31:0];   // 32'h8000_2000
                    tWRITE      <= HWRITE;        // 0 (Read)
                    
                    if (HWRITE) begin
                        // Skipped...
                    end else begin // READ PATH
                        tREQ    <= 1'b1;          // IMMEDIATELY request APB access!
                        state   <= STH_READ0;     // Move to wait for APB data
                    end
                end
            endcase
        end
    end

// Inside APB FSM (Concurrently)
    STP_IDLE: begin 
        // tREQsync is 0 at this exact clock edge (it gets updated next cycle)
        // Stays in STP_IDLE
    end


// ==============================================================================
// CYCLE 2: AHB Stalled / APB Setup Phase
// ==============================================================================
// Inside AHB FSM
    STH_READ0: begin
        if(tACKsync) begin // tACKsync is 0. Stays waiting.
            // ...
        end
    end

// Inside APB FSM
    STP_IDLE: begin
        if(tREQsync) begin   // tREQsync is now 1 (propagated from AHB FSM)
            PSEL    <= 1'b1; // Drive APB Select High
            pstate  <= STP_SETUP;
        end
    end


// ==============================================================================
// CYCLE 3: AHB Stalled / APB Access Phase
// ==============================================================================
// Inside AHB FSM
    STH_READ0: begin
        // Still waiting for tACKsync...
    end

// Inside APB FSM
    STP_SETUP: begin
        PENABLE <= 1'b1; // Assert PENABLE to execute the APB read
        pstate  <= STP_GO;
    end


// ==============================================================================
// CYCLE 4: APB Slave Responds (Data arrives)
// ==============================================================================
// Inside AHB FSM
    STH_READ0: begin
        // Still waiting...
    end

// Inside APB FSM
    STP_GO: begin
        if(PREADY) begin         // APB Slave signals it has the data ready
            PENABLE <= 1'b0;     // Drop Enable
            PSEL    <= 1'b0;     // Drop Select
            tACK    <= 1'b1;     // Tell AHB FSM the transaction is done!
            tRDATA  <= PRDATA;   // Capture the read data: 32'h11223344
            tERROR  <= PSLVERR;  // Capture error status
            pstate  <= STP_WAIT; // Move to cleanup
        end
    end


// ==============================================================================
// CYCLE 5: Resolution & AHB Data Phase Completion
// ==============================================================================
// Inside AHB FSM
    STH_READ0: begin
        if(tACKsync) begin       // tACKsync is now 1!
            tREQ      <= 1'b0;   // Deassert request
            HRDATA    <= tRDATA; // Pass 32'h11223344 onto the AHB read data bus
            HRESP     <= {1'b0, tERROR}; 
            
            if(CLOCK_RATIO == 2'b00) begin
                HREADYout <= 1'b1;       // UNSTALL the AHB bus! Data is now valid.
                state     <= STH_IDLE;   // AHB transfer complete.
            end 
        end
    end

// Inside APB FSM
    STP_WAIT: begin
        if(CLOCK_RATIO == 2'b0) begin
            tACK   <= 1'b0;      // Drop ACK
            pstate <= STP_IDLE;  // APB side complete.
        end 
    end
```

