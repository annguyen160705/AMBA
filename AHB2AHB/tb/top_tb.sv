`timescale 1ns/1ps

module top_tb;

    // =========================================================================
    // Constants
    // =========================================================================
    localparam time CLK_PERIOD = 10ns;
    localparam int  TIMEOUT_CYCLES = 200;

    localparam logic [1:0] HTRANS_IDLE   = 2'b00;
    localparam logic [1:0] HTRANS_NONSEQ = 2'b10;
    localparam logic [2:0] HSIZE_WORD    = 3'b010;
    localparam logic [2:0] HBURST_SINGLE = 3'b000;

    // =========================================================================
    // DUT interface
    // =========================================================================
    logic        HCLK;
    logic        HRESETn;

    logic        sHSEL;
    logic [31:0] sHADDR;
    logic [1:0]  sHTRANS;
    logic        sHWRITE;
    logic [2:0]  sHSIZE;
    logic [2:0]  sHBURST;
    logic [31:0] sHWDATA;

    logic [31:0] sHRDATA;
    logic [1:0]  sHRESP;
    logic        sHREADYout;

    int pass_count = 0;
    int fail_count = 0;

    // =========================================================================
    // DUT
    // =========================================================================
    top dut (
        .HCLK       (HCLK),
        .HRESETn    (HRESETn),

        .sHSEL      (sHSEL),
        .sHADDR     (sHADDR),
        .sHTRANS    (sHTRANS),
        .sHWRITE    (sHWRITE),
        .sHSIZE     (sHSIZE),
        .sHBURST    (sHBURST),
        .sHWDATA    (sHWDATA),

        .sHRDATA    (sHRDATA),
        .sHRESP     (sHRESP),
        .sHREADYout (sHREADYout)
    );

    // =========================================================================
    // Clock: 100 MHz
    // =========================================================================
    initial begin
        HCLK = 1'b0;
        forever #(CLK_PERIOD/2) HCLK = ~HCLK;
    end

    // =========================================================================
    // Put upstream AHB bus in IDLE
    // =========================================================================
    task automatic drive_idle;
        begin
            sHSEL   = 1'b0;
            sHADDR  = 32'h0000_0000;
            sHTRANS = HTRANS_IDLE;
            sHWRITE = 1'b0;
            sHSIZE  = HSIZE_WORD;
            sHBURST = HBURST_SINGLE;
            sHWDATA = 32'h0000_0000;
        end
    endtask

    // =========================================================================
    // Wait until the upstream bridge is ready before starting a transaction
    // =========================================================================
    task automatic wait_upstream_ready;
        int n;
        begin
            n = 0;
            while ((sHREADYout !== 1'b1) && (n < TIMEOUT_CYCLES)) begin
                @(negedge HCLK);
                n++;
            end

            if (n >= TIMEOUT_CYCLES) begin
                $fatal(1, "TIMEOUT waiting for sHREADYout=1");
            end
        end
    endtask

    // =========================================================================
    // Single 32-bit AHB write
    //
    // Important for this bridge implementation:
    //   1. Present address/control while upstream READY is high.
    //   2. Keep HWDATA stable while the bridge stalls the bus.
    //   3. When READY returns high, move address/control to IDLE but keep
    //      HWDATA for one additional cycle. ahb2ahb_slave_core consumes the
    //      write data in STH_WRITE1 on that following rising edge.
    // =========================================================================
    task automatic ahb_write_word(
        input logic [31:0] addr,
        input logic [31:0] data
    );
        int n;
        bit saw_wait;
        begin
            wait_upstream_ready();

            // Drive before rising edge to avoid testbench/DUT race.
            @(negedge HCLK);
            sHSEL   = 1'b1;
            sHADDR  = addr;
            sHTRANS = HTRANS_NONSEQ;
            sHWRITE = 1'b1;
            sHSIZE  = HSIZE_WORD;
            sHBURST = HBURST_SINGLE;
            sHWDATA = data;

            // This bridge should pull HREADYout low after accepting address.
            n        = 0;
            saw_wait = 1'b0;
            while ((!saw_wait) && (n < TIMEOUT_CYCLES)) begin
                @(negedge HCLK);
                if (sHREADYout === 1'b0)
                    saw_wait = 1'b1;
                n++;
            end

            if (!saw_wait)
                $fatal(1, "WRITE timeout: bridge never entered wait state. ADDR=%08h", addr);

            // Wait for completion of the upstream address phase.
            n = 0;
            while ((sHREADYout !== 1'b1) && (n < TIMEOUT_CYCLES)) begin
                @(negedge HCLK);
                n++;
            end

            if (n >= TIMEOUT_CYCLES)
                $fatal(1, "WRITE timeout waiting for READY. ADDR=%08h", addr);

            // Address/control may now advance to IDLE. Keep write data stable.
            sHSEL   = 1'b0;
            sHADDR  = 32'h0000_0000;
            sHTRANS = HTRANS_IDLE;
            sHWRITE = 1'b0;
            sHSIZE  = HSIZE_WORD;
            sHBURST = HBURST_SINGLE;
            sHWDATA = data;

            // Allow slave_core STH_WRITE1 to capture HWDATA.
            @(negedge HCLK);
            sHWDATA = 32'h0000_0000;
        end
    endtask

    // =========================================================================
    // Wait for a write to travel through FIFO -> master core -> AHB slave.
    // =========================================================================
    task automatic wait_downstream_write_complete;
        int n;
        bit saw_request;
        begin
            n           = 0;
            saw_request = 1'b0;

            // First prove that the bridge actually generated a downstream req.
            while ((!saw_request) && (n < TIMEOUT_CYCLES)) begin
                @(negedge HCLK);
                if (dut.mHBUSREQ === 1'b1)
                    saw_request = 1'b1;
                n++;
            end

            if (!saw_request)
                $fatal(1, "Downstream write never generated mHBUSREQ");

            // Then wait for the master transaction to finish.
            n = 0;
            while ((dut.mHBUSREQ !== 1'b0) && (n < TIMEOUT_CYCLES)) begin
                @(negedge HCLK);
                n++;
            end

            if (n >= TIMEOUT_CYCLES)
                $fatal(1, "TIMEOUT waiting for downstream write completion");

            // mem_ahb has internal write pipelining; give it a few clocks to
            // commit T_DATA into the memory array.
            repeat (4) @(posedge HCLK);
        end
    endtask

    // =========================================================================
    // Single 32-bit AHB read
    // =========================================================================
    task automatic ahb_read_word(
        input  logic [31:0] addr,
        output logic [31:0] data,
        output logic [1:0]  resp
    );
        int n;
        bit saw_wait;
        begin
            wait_upstream_ready();

            @(negedge HCLK);
            sHSEL   = 1'b1;
            sHADDR  = addr;
            sHTRANS = HTRANS_NONSEQ;
            sHWRITE = 1'b0;
            sHSIZE  = HSIZE_WORD;
            sHBURST = HBURST_SINGLE;
            sHWDATA = 32'h0000_0000;

            // Wait until bridge accepts the read and stalls upstream.
            n        = 0;
            saw_wait = 1'b0;
            while ((!saw_wait) && (n < TIMEOUT_CYCLES)) begin
                @(negedge HCLK);
                if (sHREADYout === 1'b0)
                    saw_wait = 1'b1;
                n++;
            end

            if (!saw_wait)
                $fatal(1, "READ timeout: bridge never entered wait state. ADDR=%08h", addr);

            // Read completes when HREADYout returns high. At the negedge after
            // that rising edge, HRDATA is already stable.
            n = 0;
            while ((sHREADYout !== 1'b1) && (n < TIMEOUT_CYCLES)) begin
                @(negedge HCLK);
                n++;
            end

            if (n >= TIMEOUT_CYCLES)
                $fatal(1, "READ timeout waiting for READY. ADDR=%08h", addr);

            data = sHRDATA;
            resp = sHRESP;

            // Complete transaction and return upstream bus to IDLE.
            sHSEL   = 1'b0;
            sHADDR  = 32'h0000_0000;
            sHTRANS = HTRANS_IDLE;
            sHWRITE = 1'b0;
            sHSIZE  = HSIZE_WORD;
            sHBURST = HBURST_SINGLE;
            sHWDATA = 32'h0000_0000;

            @(negedge HCLK);
        end
    endtask

    // =========================================================================
    // Test sequence
    // =========================================================================
    logic [31:0] read_data;
    logic [1:0]  read_resp;

    initial begin
        // ---------------------------------------------------------------------
        // Initial values
        // ---------------------------------------------------------------------
        HRESETn = 1'b0;
        drive_idle();

        // =====================================================================
        // TC1: RESET
        // =====================================================================
        $display("====================================");
        $display("TC1: RESET TEST");
        $display("====================================");
        $display("[%0t] Reset asserted", $time);

        repeat (5) @(posedge HCLK);
        @(negedge HCLK);
        HRESETn = 1'b1;
        $display("[%0t] Reset released", $time);

        repeat (2) @(posedge HCLK);
        #1;

        if ((^sHRESP === 1'bx) || (^sHREADYout === 1'bx)) begin
            $display("TC1 FAIL: X detected on response/ready signals");
            fail_count++;
        end else if (sHREADYout !== 1'b1) begin
            $display("TC1 FAIL: bridge is not READY after reset");
            fail_count++;
        end else begin
            $display("TC1 PASS: reset outputs are valid and bridge is READY");
            pass_count++;
        end

        $display("====================================");
        $display("TC1 COMPLETE");
        $display("====================================");

        // =====================================================================
        // TC2: WRITE 0x12345678 TO SLAVE 0 @ 0x00000010
        // =====================================================================
        $display("====================================");
        $display("TC2: WRITE TO SLAVE 0");
        $display("====================================");

        ahb_write_word(32'h0000_0010, 32'h1234_5678);
        wait_downstream_write_complete();

        // 0x10 / 4 = word index 4 in the 1-KB mem0.
        // This white-box check prevents a false PASS based only on HRESP.
        if (dut.MEM_BLK[0].u_mem_ahb.mem[4] === 32'h1234_5678) begin
            $display("TC2 PASS: mem0[4] = 0x%08h",
                     dut.MEM_BLK[0].u_mem_ahb.mem[4]);
            pass_count++;
        end else begin
            $display("TC2 FAIL: mem0[4] expected 0x12345678, got 0x%08h",
                     dut.MEM_BLK[0].u_mem_ahb.mem[4]);
            fail_count++;
        end

        $display("====================================");
        $display("TC2 COMPLETE");
        $display("====================================");

        // =====================================================================
        // TC3: READ BACK FROM SLAVE 0
        // =====================================================================
        $display("====================================");
        $display("TC3: READ FROM SLAVE 0");
        $display("====================================");

        ahb_read_word(32'h0000_0010, read_data, read_resp);

        if (read_resp !== 2'b00) begin
            $display("TC3 FAIL: unexpected HRESP = %b", read_resp);
            fail_count++;
        end else if (read_data !== 32'h1234_5678) begin
            $display("TC3 FAIL: expected DATA=0x12345678, got DATA=0x%08h",
                     read_data);
            fail_count++;
        end else begin
            $display("TC3 PASS: READ ADDR=0x00000010 DATA=0x%08h", read_data);
            pass_count++;
        end

        $display("====================================");
        $display("TC3 COMPLETE");
        $display("====================================");

                // =====================================================================
        // TC4: WRITE + READ SLAVE 1
        // =====================================================================
        $display("====================================");
        $display("TC4: WRITE/READ SLAVE 1");
        $display("====================================");

        // ---------------------------------------------------------------------
        // WRITE to Slave 1
        // ---------------------------------------------------------------------
        ahb_write_word(
            32'h1000_0020,
            32'hAABB_CCDD
        );

        wait_downstream_write_complete();


        // 0x20 / 4 = word index 8
        if (dut.MEM_BLK[1].u_mem_ahb.mem[8] === 32'hAABB_CCDD) begin

            $display(
                "TC4 WRITE PASS: mem1[8] = 0x%08h",
                dut.MEM_BLK[1].u_mem_ahb.mem[8]
            );

        end
        else begin

            $display(
                "TC4 WRITE FAIL: expected 0xAABBCCDD, got 0x%08h",
                dut.MEM_BLK[1].u_mem_ahb.mem[8]
            );

            fail_count++;

        end


        // ---------------------------------------------------------------------
        // READ back from Slave 1
        // ---------------------------------------------------------------------
        ahb_read_word(
            32'h1000_0020,
            read_data,
            read_resp
        );


        // ---------------------------------------------------------------------
        // Check read response
        // ---------------------------------------------------------------------
        if (read_resp !== 2'b00) begin

            $display(
                "TC4 FAIL: unexpected HRESP = %b",
                read_resp
            );

            fail_count++;

        end
        else if (read_data !== 32'hAABB_CCDD) begin

            $display(
                "TC4 FAIL: expected DATA=0xAABBCCDD, got DATA=0x%08h",
                read_data
            );

            fail_count++;

        end
        else begin

            $display(
                "TC4 PASS: READ ADDR=0x10000020 DATA=0x%08h",
                read_data
            );

            pass_count++;

        end


        $display("====================================");
        $display("TC4 COMPLETE");
        $display("====================================");

        // =====================================================================
        // TC5: WRITE + READ SLAVE 2
        // =====================================================================
        $display("====================================");
        $display("TC5: WRITE/READ SLAVE 2");
        $display("====================================");

        // ---------------------------------------------------------------------
        // WRITE to Slave 2
        // ---------------------------------------------------------------------
        ahb_write_word(
            32'h2000_0030,
            32'hDEAD_BEEF
        );

        wait_downstream_write_complete();


        // Check internal memory
        if (dut.MEM_BLK[2].u_mem_ahb.mem[12] === 32'hDEAD_BEEF) begin

            $display(
                "TC5 WRITE PASS: mem2[12] = 0x%08h",
                dut.MEM_BLK[2].u_mem_ahb.mem[12]
            );

        end
        else begin

            $display(
                "TC5 WRITE FAIL: expected 0xDEADBEEF, got 0x%08h",
                dut.MEM_BLK[2].u_mem_ahb.mem[12]
            );

            fail_count++;

        end


        // ---------------------------------------------------------------------
        // READ back from Slave 2
        // ---------------------------------------------------------------------
        ahb_read_word(
            32'h2000_0030,
            read_data,
            read_resp
        );


        // ---------------------------------------------------------------------
        // Check read result
        // ---------------------------------------------------------------------
        if (read_resp !== 2'b00) begin

            $display(
                "TC5 FAIL: unexpected HRESP = %b",
                read_resp
            );

            fail_count++;

        end
        else if (read_data !== 32'hDEAD_BEEF) begin

            $display(
                "TC5 FAIL: expected DATA=0xDEADBEEF, got DATA=0x%08h",
                read_data
            );

            fail_count++;

        end
        else begin

            $display(
                "TC5 PASS: READ ADDR=0x20000030 DATA=0x%08h",
                read_data
            );

            pass_count++;

        end


        $display("====================================");
        $display("TC5 COMPLETE");
        $display("====================================");

        // =====================================================================
        // Regression summary
        // =====================================================================
        $display("");
        $display("====================================");
        $display("REGRESSION SUMMARY");
        $display("====================================");
        $display("PASS = %0d", pass_count);
        $display("FAIL = %0d", fail_count);
        $display("====================================");

        if (fail_count == 0)
            $display("ALL TESTS PASSED");
        else
            $display("REGRESSION FAILED");

        repeat (2) @(posedge HCLK);

        $finish;
    end

    // =========================================================================
    // Global watchdog
    // =========================================================================
    initial begin
        #(CLK_PERIOD * 2000);
        $fatal(1, "GLOBAL TESTBENCH TIMEOUT");
    end

endmodule
