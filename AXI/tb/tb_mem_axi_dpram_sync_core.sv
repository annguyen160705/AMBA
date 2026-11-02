`timescale 1ns/1ns

module tb_mem_axi_dpram_sync_core;

    logic clk;
    logic [7:0] waddr, raddr;
    logic [7:0] wdata, rdata;
    logic wen, ren;

    mem_axi_dpram_sync_core #(
        .WIDTH_AD(8)
    ) dut (
        .CLK(clk),
        .WADDR(waddr),
        .WDATA(wdata),
        .WEN(wen),
        .RADDR(raddr),
        .REN(ren),
        .RDATA(rdata)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        wen = 0;
        ren = 0;

        // Write AA into address 16
        #10;
        waddr = 8'h10;
        wdata = 8'hAA;
        wen = 1;

        #10;
        wen = 0;

        // read address 16
        raddr = 8'h10;
        ren = 1;

        #10;

        $display("RDATA = %h", rdata);

        #10;
        $finish;
    end

endmodule