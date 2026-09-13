`timescale 1ns/1ns

`ifndef CLK_FREQ
`define CLK_FREQ    50_000_000
`endif 

`ifndef MEM_DELAY
`define MEM_DELAY 0
`endif 

`ifndef SIZE_IN_BYTES
`define SIZE_IN_BYTES 1024
`endif 

module ahb_lite_tb;
    localparam  SIZE_IN_BYTES = `SIZE_IN_BYTES;
    localparam  DELAY = `MEM_DELAY;
    localparam  CLK_FREQ = `CLK_FREQ;
    localparam  CLK_PERIOD_HALF = 100_000_000 / (CLK_FREQ * 2);

    // Global Signals
    logic HRESETn = 1'b0;
    logic HCLK    = 1'b0;

    // Master Signals
    logic [31:0]  M_HADDR;
    logic [3:0]   M_HPROT;
    logic [1:0]   M_HTRANS;
    logic         M_HWRITE;
    logic [2:0]   M_HSIZE;
    logic [2:0]   M_HBURST;
    logic [31:0]  M_HWDATA;
    logic         M_HREADY;
    logic [31:0]  M_HRDATA;
    logic [1:0]   M_HRESP;

    // Slave Signals
    logic [31:0]  S_HADDR;
    logic [3:0]   S_HPROT;
    logic [1:0]   S_HTRANS;
    logic         S_HWRITE;
    logic [2:0]   S_HSIZE; 
    logic [2:0]   S_HBURST;
    logic [31:0]  S_HWDATA;
    logic         S_HREADY;
    logic [31:0]  S_HRDATA    [0:2]; 
    logic [1:0]   S_HRESP     [0:2]; 
    logic         S_HREADYout [0:2];
    logic         S_HSEL      [0:2];

    // AHB-Lite Fabric Interconnect
    ahb_lite_s3 #(  
        .P_HSEL0_START(16'h0000), .P_HSEL0_SIZE(16'h0100),
        .P_HSEL1_START(16'h1000), .P_HSEL1_SIZE(16'h0100),
        .P_HSEL2_START(16'h2000), .P_HSEL2_SIZE(16'h0100)
    ) u_ahb_lite (
        .HRESETn(HRESETn), .HCLK(HCLK),
        //--------------------------------------------------------//
        .M_HADDR    (M_HADDR), 
        .M_HTRANS   (M_HTRANS), 
        .M_HWRITE   (M_HWRITE),
        .M_HSIZE    (M_HSIZE), 
        .M_HBURST   (M_HBURST), 
        .M_HPROT    (M_HPROT),
        .M_HWDATA   (M_HWDATA), 
        .M_HRDATA   (M_HRDATA), 
        .M_HRESP     (M_HRESP), 
        .M_HREADY   (M_HREADY),
        //--------------------------------------------------------//
        .HWRITE (S_HWRITE), 
        .HADDR  (S_HADDR), 
        .HTRANS (S_HTRANS), 
        .HSIZE  (S_HSIZE), 
        .HBURST (S_HBURST), 
        .HPROT  (S_HPROT), 
        .HWDATA (S_HWDATA), 
        .HREADY (S_HREADY),
        //--------------------------------------------------------//
        .HSEL0(S_HSEL[0]), .HRESP0(S_HRESP[0]), .HRDATA0(S_HRDATA[0]), .HREADY0(S_HREADYout[0]),
        .HSEL1(S_HSEL[1]), .HRESP1(S_HRESP[1]), .HRDATA1(S_HRDATA[1]), .HREADY1(S_HREADYout[1]),
        .HSEL2(S_HSEL[2]), .HRESP2(S_HRESP[2]), .HRDATA2(S_HRDATA[2]), .HREADY2(S_HREADYout[2]),
        .REMAP(1'b0)
    );

    // Instantiate 3 Memory Slaves
    generate
        genvar GM;
        for (GM = 0; GM < 3; GM = GM + 1) begin : BM_BLK
            mem_ahb #(
                .SIZE_IN_BYTES(SIZE_IN_BYTES),
                .DELAY(DELAY)
            ) u_mem_ahb (
                .HRESETn(HRESETn), .HCLK(HCLK),
                //--------------------------------------------------------//
                .HADDR      (S_HADDR), 
                .HTRANS     (S_HTRANS), 
                .HWRITE     (S_HWRITE),
                .HSIZE      (S_HSIZE), 
                .HBURST     (S_HBURST), 
                .HWDATA     (S_HWDATA),
                .HREADYin   (S_HREADY), 
                .HSEL       (S_HSEL[GM]),
                .HRDATA     (S_HRDATA[GM]), 
                .HRESP      (S_HRESP[GM]), 
                .HREADYout  (S_HREADYout[GM])
            );
        end
    endgenerate

    // Clock Generation
    always #CLK_PERIOD_HALF HCLK <= ~HCLK;

    // --- AHB Master Tasks ---
    task ahb_write(input logic [31:0] addr, input logic [31:0] data);
        begin
            // Address Phase
            @(posedge HCLK);
            while (!M_HREADY) @(posedge HCLK); 
            M_HADDR  <= addr;
            M_HTRANS <= 2'b10; // NONSEQ
            M_HWRITE <= 1'b1;
            M_HSIZE  <= 3'b010; // WORD
            
            // Data Phase
            @(posedge HCLK);
            while (!M_HREADY) @(posedge HCLK);
            M_HTRANS <= 2'b00; // IDLE
            M_HWDATA <= data;
            
            // Wait for transfer completion
            @(posedge HCLK);
            while (!M_HREADY) @(posedge HCLK);
        end
    endtask

    task ahb_read(input logic [31:0] addr, output logic [31:0] data);
        begin
            // Address Phase
            @(posedge HCLK);
            while (!M_HREADY) @(posedge HCLK);
            M_HADDR  <= addr;
            M_HTRANS <= 2'b10; // NONSEQ
            M_HWRITE <= 1'b0;
            M_HSIZE  <= 3'b010; // WORD
            
            // Data Phase
            @(posedge HCLK);
            while (!M_HREADY) @(posedge HCLK);
            M_HTRANS <= 2'b00; // IDLE
            
            // FIXED: Wait for transfer completion before sampling data
            @(posedge HCLK); 
            while (!M_HREADY) @(posedge HCLK);
            data = M_HRDATA;
        end
    endtask

    // --- Main Stimulus ---
    logic [31:0] read_data;

    initial begin
        // Initialize Master Defaults
        M_HADDR  <= 32'h0;
        M_HTRANS <= 2'b00; // IDLE
        M_HWRITE <= 1'b0;
        M_HSIZE  <= 3'b000;
        M_HBURST <= 3'b000;
        M_HPROT  <= 4'h0;
        M_HWDATA <= 32'h0;

        // Reset Sequence
        HRESETn <= 1'b0;
        repeat (10) @(posedge HCLK);
        HRESETn <= 1'b1;
        repeat (2) @(posedge HCLK);

        $display("\n--- Starting AHB Transactions ---");

        // 1. Test Slave 0 (Memory maps HADDR[31:16] = 16'h0000)
        $display("Writing to Slave 0...");
        ahb_write(32'h0000_0004, 32'hAAAA_BBBB);
        ahb_read(32'h0000_0004, read_data);
        $display("Read from Slave 0: 0x%08X (Expected: 0xAAAABBBB)", read_data);

        // 2. Test Slave 1 (Memory maps HADDR[31:16] = 16'h1000)
        $display("\nWriting to Slave 1...");
        ahb_write(32'h1000_0008, 32'h1111_2222);
        ahb_read(32'h1000_0008, read_data);
        $display("Read from Slave 1: 0x%08X (Expected: 0x11112222)", read_data);

        // 3. Test Slave 2 (Memory maps HADDR[31:16] = 16'h2000)
        $display("\nWriting to Slave 2...");
        ahb_write(32'h2000_000C, 32'hDEAD_BEEF);
        ahb_read(32'h2000_000C, read_data);
        $display("Read from Slave 2: 0x%08X (Expected: 0xDEADBEEF)", read_data);

        // 4. Test Default Slave (Unmapped address, e.g. 16'h3000)
        $display("\nReading from Unmapped Address (Testing Default Slave)...");
        ahb_read(32'h3000_0000, read_data);
        $display("HRESP from Default Slave: 2'b%02b (Expected: 2'b01 ERROR)", M_HRESP);
        
        $display("--- Simulation Complete ---\n");
        $finish;
    end
endmodule