`timescale 1ns/1ps

module tb_mem_axi_dpram_sync;

    logic        RESETn;
    logic        CLK;

    logic [9:0]  WADDR;
    logic [31:0] WDATA;
    logic [3:0]  WSTRB;
    logic        WEN;

    logic [9:0]  RADDR;
    logic [31:0] RDATA;
    logic [3:0]  RSTRB;
    logic        REN;


    mem_axi_dpram_sync #(
        .WIDTH_AD(10),
        .WIDTH_DA(32)
    ) dut (
        .RESETn(RESETn),
        .CLK   (CLK),

        .WADDR (WADDR),
        .WDATA (WDATA),
        .WSTRB (WSTRB),
        .WEN   (WEN),

        .RADDR (RADDR),
        .RDATA (RDATA),
        .RSTRB (RSTRB),
        .REN   (REN)
    );


    // Clock 10 ns
    always #5 CLK = ~CLK;


    initial begin

        CLK    = 0;
        RESETn = 0;

        WADDR = 0;
        WDATA = 0;
        WSTRB = 0;
        WEN   = 0;

        RADDR = 0;
        RSTRB = 0;
        REN   = 0;


        // Reset
        #10;
        RESETn = 1;


        // WRITE
        #10;
        WADDR = 10'h010;
        WDATA = 32'h1234_5678;
        WSTRB = 4'b1111;
        WEN   = 1;

        #10;
        WEN = 0;


        // READ
        RADDR = 10'h010;
        RSTRB = 4'b1111;
        REN   = 1;

        #10;

        // WRITE
        #10;
        WADDR = 10'h011;
        WDATA = 32'hAABB_CCDD;
        WSTRB = 4'b1001;
        WEN   = 1;

        #10;
        WEN = 0;


        // READ
        RADDR = 10'h010;
        RSTRB = 4'b1100;
        REN   = 1;

        #10;


        $display("RDATA = %h", RDATA);


        #10;
        $finish;

    end

endmodule