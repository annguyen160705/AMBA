`timescale 1ns/1ps

module mem_ahb_tb;

    // --------------------------------------------------
    // Parameters
    // --------------------------------------------------
    localparam SIZE_IN_BYTES = 1024;
    localparam DELAY         = 0;
    localparam INIT          = 1;

    // --------------------------------------------------
    // AHB signals
    // --------------------------------------------------
    logic        HRESETn;
    logic        HCLK;
    logic        HSEL;
    logic [31:0] HADDR;
    logic [1:0]  HTRANS;
    logic        HWRITE;
    logic [2:0]  HSIZE;
    logic [2:0]  HBURST;
    logic [31:0] HWDATA;

    logic [31:0] HRDATA;
    logic [1:0]  HRESP;
    
    // HREADY loopback: Slave's output drives the input for the next cycle
    logic        HREADYout;
    wire         HREADYin = HREADYout; 

    // --------------------------------------------------
    // DUT
    // --------------------------------------------------
    mem_ahb #(
        .SIZE_IN_BYTES(SIZE_IN_BYTES),
        .DELAY(DELAY),
        .INIT(INIT)
    ) dut (
        .HRESETn   (HRESETn),
        .HCLK      (HCLK),
        .HSEL      (HSEL),
        .HADDR     (HADDR),
        .HTRANS    (HTRANS),
        .HWRITE    (HWRITE),
        .HSIZE     (HSIZE),
        .HBURST    (HBURST),
        .HWDATA    (HWDATA),
        .HRDATA    (HRDATA),
        .HRESP     (HRESP),
        .HREADYin  (HREADYin),
        .HREADYout (HREADYout)
    );

    // --------------------------------------------------
    // Clock Generation
    // --------------------------------------------------
    initial begin
        HCLK = 1'b0;
        forever #5 HCLK = ~HCLK;
    end

    // --------------------------------------------------
    // Monitor
    // --------------------------------------------------
    initial begin
        // Fixed: Single-line string for compatibility
        $monitor("T=%0t | HSEL=%b HREADY=%b HTRANS=%b HWRITE=%b HADDR=%h HWDATA=%h HRDATA=%h | MEM[9]=%h",
                 $time, HSEL, HREADYout, HTRANS, HWRITE, HADDR, HWDATA, HRDATA, dut.mem[9]);
    end

    // --------------------------------------------------
    // Test Sequence
    // --------------------------------------------------
    initial begin
        // --- 1. Initial values & Reset ---
        HRESETn  = 1'b0;
        HSEL     = 1'b0;
        HADDR    = 32'h0;
        HTRANS   = 2'b00;       // IDLE
        HWRITE   = 1'b0;
        HSIZE    = 3'b010;      // WORD
        HBURST   = 3'b000;      // SINGLE
        HWDATA   = 32'h0;

        #12;
        HRESETn = 1'b1;

        // --------------------------------------------------
        // 2. WRITE 0x12345678 -> address 0x24
        // --------------------------------------------------
        @(negedge HCLK);
        
        // WRITE: Address Phase
        HSEL   = 1'b1;
        HADDR  = 32'h0000_0024;
        HTRANS = 2'b10;         // NONSEQ
        HWRITE = 1'b1;
        HSIZE  = 3'b010;        // WORD

        @(negedge HCLK);
        
        // WRITE: Data Phase (Master drives HWDATA now)
        HSEL   = 1'b0;          // Deselect (next address phase is IDLE)
        HTRANS = 2'b00;         // IDLE
        HWRITE = 1'b0;
        HADDR  = 32'h0;
        
        HWDATA = 32'h1234_5678; // <-- HWDATA is driven exactly 1 cycle after Address

        @(negedge HCLK);
        
        // End of Write Data Phase
        HWDATA = 32'h0;
        
        // Idle cycle
        @(negedge HCLK);

        // --------------------------------------------------
        // 3. READ address 0x24
        // --------------------------------------------------
        @(negedge HCLK);
        
        // READ: Address Phase
        HSEL   = 1'b1;
        HADDR  = 32'h0000_0024;
        HTRANS = 2'b10;         // NONSEQ
        HWRITE = 1'b0;          // READ
        HSIZE  = 3'b010;        // WORD

        @(negedge HCLK);
        
        // READ: Data Phase (Slave will drive HRDATA)
        HSEL   = 1'b0;          // Deselect
        HTRANS = 2'b00;         // IDLE
        HADDR  = 32'h0;

        @(negedge HCLK);
        
        // --------------------------------------------------
        // 4. Self-Checking
        // --------------------------------------------------
        if (HRDATA !== 32'h1234_5678) begin
            $display("\n[FAILED] Expected HRDATA = 0x12345678, but got 0x%08h\n", HRDATA);
        end else begin
            $display("\n[PASSED] Read matched written data successfully!\n");
        end

        #10;
        $finish;
    end

endmodule