`timescale 1ns/1ps

module AHB_tb_improved;

    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 32;
    parameter MEM_DEPTH  = 32;

    //========================================================
    // Clock / Reset
    //========================================================
    logic HCLK;
    logic HRESETn;

    //========================================================
    // AHB Bus Signals
    //========================================================
    logic [ADDR_WIDTH-1:0] HADDR;
    logic                  HWRITE;
    logic [1:0]            HTRANS;
    logic [DATA_WIDTH-1:0] HWDATA;
    logic [DATA_WIDTH-1:0] HRDATA;
    logic                  HREADY;
    logic                  HRESP;

    //========================================================
    // User Control Signals
    //========================================================
    logic                  master_enable;
    logic                  master_write;
    logic [ADDR_WIDTH-1:0] master_addr;
    
    logic                  slave_enable;

    //========================================================
    // Clock generation
    //========================================================
    initial begin
        HCLK = 1'b0;
        forever #5 HCLK = ~HCLK;
    end

    //========================================================
    // Master Instance
    //========================================================
    AHB_master #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .master_MEMORY_DEPTH(MEM_DEPTH)
    ) u_master (
        .HRESETn(HRESETn),
        .HCLK(HCLK),
        .HREADY(HREADY),
        .HRESP(HRESP),
        .HRDATA(HRDATA),
        .HADDR(HADDR),
        .HWRITE(HWRITE),
        .HTRANS(HTRANS),
        .HWDATA(HWDATA),
        
        // Control inputs
        .write_top(master_write),
        .enable(master_enable),
        .addr_top(master_addr)
    );

    //========================================================
    // Slave Instance
    //========================================================
    AHB_slave #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .slave_MEMORY_DEPTH(MEM_DEPTH)
    ) u_slave (
        .HRESETn(HRESETn),
        .HCLK(HCLK),
        .HREADYOUT(HREADY), // Connected directly to HREADY
        .HRESP(HRESP),
        .HRDATA(HRDATA),
        .HADDR(HADDR),
        .HWRITE(HWRITE),
        .HTRANS(HTRANS),
        .HWDATA(HWDATA),
        
        // Control inputs
        .enable(slave_enable)
    );

    //========================================================
    // Test sequence
    //========================================================
    initial begin
        // Initialize control signals
        HRESETn       = 1'b0;
        master_enable = 1'b0;
        master_write  = 1'b0;
        master_addr   = 32'h0;
        slave_enable  = 1'b0;

        #20;

        // Release reset
        HRESETn = 1'b1;
        #10;
        
        // Backdoor initialize master memory at index 1 (Address 4)
        u_master.master_memory[1] = 32'hDEADBEEF;

        //====================================================
        // WRITE TRANSACTION
        // Write data from master memory to slave at Address 4
        //====================================================
        @(posedge HCLK);
        master_enable = 1'b1;
        slave_enable  = 1'b1;
        master_write  = 1'b1;
        master_addr   = 32'd4; // Word-aligned address

        // Wait for address phase to complete
        @(posedge HCLK);
        master_enable = 1'b0; // Deassert enable to prevent looping
        
        // Wait for data phase to complete
        wait(HREADY == 1'b1);
        @(posedge HCLK);

        //====================================================
        // READ TRANSACTION
        // Read data back from slave at Address 4
        //====================================================
        master_enable = 1'b1;
        master_write  = 1'b0;
        master_addr   = 32'd4;

        // Wait for address phase
        @(posedge HCLK);
        master_enable = 1'b0;
        
        // Wait for data phase
        wait(HREADY == 1'b1);
        @(posedge HCLK);
        
        if (HRDATA == 32'hDEADBEEF)
            $display("SUCCESS: Data read successfully.");
        else
            $display("ERROR: Expected 0xDEADBEEF, got 0x%08h", HRDATA);

        //====================================================
        // Finish
        //====================================================
        #50 $finish;
    end

endmodule