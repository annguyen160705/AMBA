`timescale 1ns/1ps

module AMBA_APB_tb;

    //============================================================
    // Parameters
    //============================================================
    parameter DATA_WIDTH   = 32;
    parameter MEMORY_DEPTH = 32;

    //============================================================
    // DUT signals
    //============================================================
    logic                  Pclk;
    logic                  Prst;
    logic [$clog2(MEMORY_DEPTH)-1:0] Paddr;
    logic                  Pselx;
    logic                  Penable;
    logic                  Pwrite;
    logic [DATA_WIDTH-1:0] Pwdata;

    logic                  Pready;
    logic                  Pslverr;
    logic [DATA_WIDTH-1:0] Prdata;
    logic [DATA_WIDTH-1:0] temp;

    //============================================================
    // DUT
    //============================================================
    AMBA_APB #(
        .DATA_WIDTH(DATA_WIDTH),
        .MEMORY_DEPTH(MEMORY_DEPTH)
    ) dut (
        .Pclk    (Pclk),
        .Prst    (Prst),
        .Paddr   (Paddr),
        .Pselx   (Pselx),
        .Penable (Penable),
        .Pwrite  (Pwrite),
        .Pwdata  (Pwdata),

        .Pready  (Pready),
        .Pslverr (Pslverr),
        .Prdata  (Prdata),
        .temp    (temp)
    );

    //============================================================
    // Clock generation
    //============================================================
    initial begin
        Pclk = 1'b0;

        forever #5 Pclk = ~Pclk;
    end

    //============================================================
    // WRITE task
    //============================================================
    task automatic apb_write(
        input logic [$clog2(MEMORY_DEPTH)-1:0] addr,
        input logic [DATA_WIDTH-1:0] data
    );
    begin

        // SETUP phase
        @(negedge Pclk);
        Paddr   = addr;
        Pwdata  = data;
        Pwrite  = 1'b1;
        Pselx   = 1'b1;
        Penable = 1'b0;

        // ACCESS phase
        @(negedge Pclk);
        Penable = 1'b1;

        // Wait for PREADY
        @(posedge Pclk);

        while (!Pready)
            @(posedge Pclk);

        // End transfer
        @(negedge Pclk);
        Pselx   = 1'b0;
        Penable = 1'b0;
        Pwrite  = 1'b0;
        Paddr   = '0;
        Pwdata  = '0;

    end
    endtask

    //============================================================
    // READ task
    //============================================================
    task automatic apb_read(
        input  logic [$clog2(MEMORY_DEPTH)-1:0] addr,
        output logic [DATA_WIDTH-1:0] data
    );
    begin

        // SETUP phase
        @(negedge Pclk);
        Paddr   = addr;
        Pwrite  = 1'b0;
        Pselx   = 1'b1;
        Penable = 1'b0;

        // ACCESS phase
        @(negedge Pclk);
        Penable = 1'b1;

        // Wait for PREADY
        @(posedge Pclk);

        while (!Pready)
            @(posedge Pclk);

        data = Prdata;

        // End transfer
        @(negedge Pclk);
        Pselx   = 1'b0;
        Penable = 1'b0;
        Paddr   = '0;

    end
    endtask

    //============================================================
    // Test
    //============================================================
    logic [DATA_WIDTH-1:0] read_data;

    initial begin

        // Initial values
        Prst    = 1'b0;
        Paddr   = '0;
        Pselx   = 1'b0;
        Penable = 1'b0;
        Pwrite  = 1'b0;
        Pwdata  = '0;

        // Reset
        #20;
        Prst = 1'b1;

        //========================================================
        // WRITE
        //========================================================
        $display("========================================");
        $display("WRITE TEST");
        $display("========================================");

        apb_write(5, 32'h1234_ABCD);

        $display("Wrote 0x%08h to address %0d",
                 32'h1234_ABCD, 5);

        //========================================================
        // READ
        //========================================================
        $display("========================================");
        $display("READ TEST");
        $display("========================================");

        apb_read(5, read_data);

        $display("Read 0x%08h from address %0d",
                 read_data, 5);

        //========================================================
        // CHECK
        //========================================================
        if (read_data == 32'h1234_ABCD) begin
            $display("PASS: Read data matches write data");
        end
        else begin
            $display("FAIL: Expected 0x1234_ABCD, got 0x%08h",
                     read_data);
        end

        $display("========================================");

        #20;
        $finish;
    end

endmodule