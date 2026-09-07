`timescale 1ns/1ps

module AHB_master_tb;

    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 32;
    parameter MASTER_MEMORY_DEPTH = 32;

    //--------------------------------------------------------//
    // Clock / Reset
    //--------------------------------------------------------//
    logic HCLK;
    logic HRESETn;

    //--------------------------------------------------------//
    // AHB response
    //--------------------------------------------------------//
    logic HREADY;
    logic HRESP;
    logic [DATA_WIDTH-1:0] HRDATA;

    //--------------------------------------------------------//
    // AHB master outputs
    //--------------------------------------------------------//
    logic [ADDR_WIDTH-1:0] HADDR;
    logic HWRITE;
    logic [DATA_WIDTH-1:0] HWDATA;

    //--------------------------------------------------------//
    // User inputs
    //--------------------------------------------------------//
    logic write_top;
    logic enable;
    logic [ADDR_WIDTH-1:0] addr_top;

    //--------------------------------------------------------//
    // DUT
    //--------------------------------------------------------//
    AHB_master #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH),
        .master_MEMORY_DEPTH(MASTER_MEMORY_DEPTH)
    ) dut (
        .HRESETn   (HRESETn),
        .HCLK      (HCLK),

        .HREADY    (HREADY),
        .HRESP     (HRESP),
        .HRDATA    (HRDATA),

        .HADDR     (HADDR),
        .HWRITE    (HWRITE),
        .HWDATA    (HWDATA),

        .write_top (write_top),
        .enable    (enable),
        .addr_top  (addr_top)
    );

    //--------------------------------------------------------//
    // Clock
    //--------------------------------------------------------//
    initial begin
        HCLK = 1'b0;
        forever #5 HCLK = ~HCLK;
    end

    //--------------------------------------------------------//
    // Test sequence
    //--------------------------------------------------------//
    initial begin

        //----------------------------------------------------//
        // Initial values
        //----------------------------------------------------//
        HRESETn   = 1'b0;
        HREADY    = 1'b1;
        HRESP     = 1'b0;
        HRDATA    = 32'h0000_0000;

        enable    = 1'b0;
        write_top = 1'b0;
        addr_top  = 32'h0000_0000;

        //----------------------------------------------------//
        // Reset
        //----------------------------------------------------//
        repeat (2) @(posedge HCLK);
        HRESETn = 1'b1;

        //----------------------------------------------------//
        // Put data into master's local memory
        //
        // Address 0x04 -> memory[1]
        //----------------------------------------------------//
        dut.master_memory[1] = 32'h1234_5678;

        //----------------------------------------------------//
        //====================================================//
        // READ TRANSFER
        // Address = 0x04
        // Slave returns 0xAABBCCDD
        //====================================================//
        //----------------------------------------------------//

        @(negedge HCLK);

        enable    = 1'b1;
        write_top = 1'b0;
        addr_top  = 32'h0000_0004;

        @(negedge HCLK);

        enable = 1'b0;

        //----------------------------------------------------//
        // Keep HRDATA stable during read data phase
        //----------------------------------------------------//
        HRDATA = 32'hAABB_CCDD;

        //----------------------------------------------------//
        // Wait for data phase
        //----------------------------------------------------//
        wait (dut.current_state == dut.DATA_PHASE);

        $display("----------------------------------------");
        $display("READ TRANSFER");
        $display("HADDR  = %08h", HADDR);
        $display("HWRITE = %b", HWRITE);
        $display("HRDATA = %08h", HRDATA);

        //----------------------------------------------------//
        // Wait until transfer finishes
        //----------------------------------------------------//
        @(posedge HCLK);

        //----------------------------------------------------//
        // Check received data
        //----------------------------------------------------//
        #1;

        $display("MEM[1]  = %08h", dut.master_memory[1]);

        if (dut.master_memory[1] == 32'hAABB_CCDD)
            $display("READ PASSED");
        else
            $display("READ FAILED");


        //----------------------------------------------------//
        //====================================================//
        // WRITE TRANSFER
        // Address = 0x04
        // Data    = 0x12345678
        //====================================================//
        //----------------------------------------------------//

        @(negedge HCLK);

        enable    = 1'b1;
        write_top = 1'b1;
        addr_top  = 32'h0000_0004;

        @(negedge HCLK);

        enable = 1'b0;

        //----------------------------------------------------//
        // Wait for DATA_PHASE
        //----------------------------------------------------//
        wait (dut.current_state == dut.DATA_PHASE);

        #1;

        $display("----------------------------------------");
        $display("WRITE TRANSFER");
        $display("HADDR  = %08h", HADDR);
        $display("HWRITE = %b", HWRITE);
        $display("HWDATA = %08h", HWDATA);

        if (HADDR == 32'h0000_0004 &&
            HWRITE == 1'b1 &&
            HWDATA == 32'h1234_5678)
            $display("WRITE PASSED");
        else
            $display("WRITE FAILED");

        //----------------------------------------------------//
        // Finish
        //----------------------------------------------------//
        @(posedge HCLK);
        #20;

        $finish;

    end

endmodule