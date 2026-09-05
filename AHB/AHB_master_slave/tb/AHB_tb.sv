`timescale 1ns/1ps

module AHB_tb;

    parameter DATA_WIDTH = 32;
    parameter ADDR_WIDTH = 32;

    //========================================================
    // Clock / Reset
    //========================================================
    logic HCLK;
    logic HRESETn;

    //========================================================
    // AHB signals
    //========================================================
    logic [ADDR_WIDTH-1:0] HADDR;
    logic HWRITE;

    logic [DATA_WIDTH-1:0] HWDATA;
    logic [DATA_WIDTH-1:0] HRDATA;

    logic HREADY;
    logic HREADYOUT;

    logic HRESP;

    //========================================================
    // Clock generation
    //========================================================
    initial begin
        HCLK = 1'b0;
        forever #5 HCLK = ~HCLK;
    end

    //========================================================
    // Master
    //========================================================
    AHB_master #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
        
    ) u_master (
        .HRESETn(HRESETn),
        .HCLK(HCLK),

        .HREADY(HREADY),
        .HRESP(HRESP),

        .HRDATA(HRDATA),

        .HADDR(HADDR),
        .HWRITE(HWRITE),

        .HWDATA(HWDATA)
    );

    //========================================================
    // Slave
    //========================================================
    AHB_slave #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) u_slave (
        .HRESETn(HRESETn),
        .HCLK(HCLK),

        .HREADYOUT(HREADYOUT),
        .HRESP(HRESP),

        .HRDATA(HRDATA),

        .HADDR(HADDR),
        .HWRITE(HWRITE),

        .HWDATA(HWDATA)
    );

    //========================================================
    // Connect HREADY
    //========================================================
    assign HREADY = HREADYOUT;

    //========================================================
    // Test sequence
    //========================================================
    initial begin

        // Initialize
        HRESETn = 1'b0;

        #20;

        // Release reset
        HRESETn = 1'b1;

        //====================================================
        // WRITE
        // Address = 4
        // Data    = 0x12345678
        //====================================================
        HADDR  = 32'd4;
        HWRITE = 1'b1;
        HWDATA = 32'h12345678;

        #50;

        //====================================================
        // READ
        // Address = 4
        //====================================================
        HADDR  = 32'd4;
        HWRITE = 1'b0;

        #50;

        //====================================================
        // Finish
        //====================================================
        $finish;

    end

endmodule