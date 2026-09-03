`timescale 1ns/1ns
`define AMBA3
`define AMBA4

module mem_apb_tb;

    // --------------------------------------------------------
    // 1. Signals & Clock
    // --------------------------------------------------------
    logic PCLK = 0;
    logic PRESETn = 0;

    logic        PSEL;
    logic [31:0] PADDR;
    logic        PENABLE;
    logic        PWRITE;
    logic [31:0] PWDATA;
    logic [31:0] PRDATA;
    logic        PREADY;
    /* verilator lint_off UNUSEDSIGNAL */
    logic        PSLVERR;
    /* verilator lint_on UNUSEDSIGNAL */
    logic [2:0]  PPROT;
    logic [3:0]  PSTRB;

    initial begin
        forever #5 PCLK = ~PCLK; // 100MHz clock
    end

    // --------------------------------------------------------
    // 2. DUT Instantiation (Delay = 1 to test wait states)
    // --------------------------------------------------------
    mem_apb #(.SIZE_IN_BYTES(1024), .DELAY(5)) u_slave (
        .PRESETn(PRESETn), .PCLK(PCLK), .PSEL(PSEL), .PADDR(PADDR), 
        .PENABLE(PENABLE), .PWRITE(PWRITE), .PWDATA(PWDATA), .PRDATA(PRDATA),
        .PREADY(PREADY), .PSLVERR(PSLVERR), .PPROT(PPROT), .PSTRB(PSTRB)
    );

    // --------------------------------------------------------
    // 3. Reusable APB Bus Tasks
    // --------------------------------------------------------
    task apb_write(input [31:0] a, input [31:0] d, input [3:0] s);
        // Setup Phase
        @(posedge PCLK); #1; 
        PSEL = 1; PADDR = a; PWRITE = 1; PWDATA = d; PSTRB = s; PENABLE = 0;
        
        // Access Phase
        @(posedge PCLK); #1;
        PENABLE = 1;
        
        // Wait for Slave to assert PREADY
        while (!PREADY) @(posedge PCLK); #1;
        PSEL = 0; PENABLE = 0;
    endtask

    task apb_read(input [31:0] a, output [31:0] d);
        // Setup Phase
        @(posedge PCLK); #1;
        PSEL = 1; PADDR = a; PWRITE = 0; PSTRB = 4'h0; PENABLE = 0;
        
        // Access Phase
        @(posedge PCLK); #1;
        PENABLE = 1;
        
        // Wait for Slave and sample data
        while (!PREADY) @(posedge PCLK); #1;
        d = PRDATA;
        PSEL = 0; PENABLE = 0;
    endtask

    // --------------------------------------------------------
    // 4. Main Test Sequence
    // --------------------------------------------------------
    logic [31:0] read_val;

    initial begin
        // Initialize Signals
        PSEL = 0; PADDR = 0; PENABLE = 0; PWRITE = 0; PWDATA = 0;
        PPROT = 0; PSTRB = 0;
        
        // Release Reset
        #23 PRESETn = 1;
        @(posedge PCLK);

        $display("\n=======================================");
        $display(" TEST 1: Full Word Write & Read");
        $display("=======================================");
        apb_write(32'h0000_0004, 32'hAAAA5678, 4'b1111);
        apb_read (32'h0000_0004, read_val);
        if (read_val == 32'hAAAA5678) $display(" [PASS] Read Data: 0x%0h", read_val);
        else $display(" [FAIL] Expected 0xAAAAAAAA, got 0x%0h", read_val);

        $display("\n=======================================");
        $display(" TEST 2: Byte-Strobe Write (Masking)");
        $display("=======================================");
        // Overwrite ONLY the bottom two bytes with 16-bit BBBBs
        apb_write(32'h0000_0004, 32'hBBBBBBBB, 4'b0011);
        apb_read (32'h0000_0004, read_val);
        if (read_val == 32'hAAAABBBB) $display(" [PASS] Read Data: 0x%0h (Upper bytes protected)", read_val);
        else $display(" [FAIL] Expected 0xAAAABBBB, got 0x%0h", read_val);

        $display("\n=======================================");
        $display(" TEST 3: Back-to-Back Burst");
        $display("=======================================");
        
        // Burst Write 1
        @(posedge PCLK); #1;
        PSEL = 1; PADDR = 32'h0000_0008; PWRITE = 1; PWDATA = 32'h12345678; PSTRB = 4'hF; PENABLE = 0;
        
        @(posedge PCLK); #1; 
        PENABLE = 1;
        while (!PREADY) @(posedge PCLK); #1;
        
        // Burst Write 2 (Zero-idle setup phase starts EXACTLY when previous PREADY goes high)
        PSEL = 1; PADDR = 32'h0000_000C; PWRITE = 1; PWDATA = 32'h87654321; PSTRB = 4'hF; PENABLE = 0;
        
        @(posedge PCLK); #1; 
        PENABLE = 1;
        while (!PREADY) @(posedge PCLK); #1;
        PSEL = 0; PENABLE = 0;
        
        $display(" [INFO] Burst Writes Completed.\n");

        // Let simulation run a bit longer to show the final waveform states cleanly
        #40 $finish;
    end

    // --------------------------------------------------------
    // 5. Console Monitoring ($monitor)
    // --------------------------------------------------------
    initial begin
        // Prints a line automatically anytime one of these specific signals changes state
        $monitor("Time=[%0t] | SEL=%b EN=%b WR=%b RDY=%b | ADDR=0x%0h | WDAT=0x%0h STRB=%b | RDAT=0x%0h",
                 $time, PSEL, PENABLE, PWRITE, PREADY, PADDR, PWDATA, PSTRB, PRDATA);
    end

    // --------------------------------------------------------
    // 6. Waveform Dump
    // --------------------------------------------------------
    initial begin
        $dumpfile("full_wave.vcd");
        $dumpvars(0, mem_apb_tb);
    end

endmodule