`timescale 1ns/1ns

module bfm_apb_s3 #(
    parameter P_DWIDTH  = 32,
    parameter P_STRB    = (P_DWIDTH/8),
    parameter P_NUM     = 3,
    parameter P_ADDR_START0 = 16'h0000, P_ADDR_SIZE0 = 16'h0010,
    parameter P_ADDR_START1 = 16'h1000, P_ADDR_SIZE1 = 16'h0010,
    parameter P_ADDR_START2 = 16'h2000, P_ADDR_SIZE2 = 16'h0010
) (
    input logic     PRESETn
    , input logic   PCLK
    , output logic [P_NUM-1:0] PSEL
    , output logic [31:0]   PADDR
    , output logic          PENABLE
    , output logic          PWRITE
    , output logic [P_DWIDTH-1:0] PWDATA
    , input logic [P_DWIDTH-1:0] PRDATA0
    , input logic [P_DWIDTH-1:0] PRDATA1
    , input logic [P_DWIDTH-1:0] PRDATA2
    `ifdef AMBA3
    , input logic [P_NUM-1:0] PREADY
    , input logic [P_NUM-1:0] PSLVERR
    `endif // AMBA3
    `ifdef AMBA4
    , output logic [2:0] PPROT
    , output logic [P_STRB-1:0] PSTRB
    `endif // AMBA4
);

    `ifndef AMBA3
    logic [P_NUM-1:0] PREADY    = {P_NUM{1'b1}};
    logic [P_NUM-1:0] PSLVERR   = {P_NUM{1'b0}};
    `endif
    `ifndef AMBA4
    logic [2:0]     PPROT;
    logic [P_STRB-1:0] PSTRB;
    `endif

    initial begin
        PSEL    = {P_NUM{1'b0}};
        PADDR   = ~32'h0;
        PENABLE = 1'b0;
        PWRITE  = 1'b0;
        PWDATA  = {P_DWIDTH{1'b1}};
        PPROT   = 3'h0;
        PSTRB   = {P_STRB{1'b0}};
        wait    (PRESETn == 1'b0);
        wait    (PRESETn == 1'b1);
        memory_test({P_ADDR_START0,16'h0}, {P_ADDR_START0,16'h0} + 32'h10 - 1, 4);
        memory_test({P_ADDR_START1,16'h0}, {P_ADDR_START1,16'h0} + 32'h10 - 1, 4);
        memory_test({P_ADDR_START2,16'h0}, {P_ADDR_START2,16'h0} + 32'h10 - 1, 4);
        repeat (5) @(posedge PCLK);
        $finish(2);
    end

    logic [P_DWIDTH-1:0] reposit [0:1023];
    

    task memory_test(
        input logic [31:0]  start,
        input logic [31:0]  finish,
        input logic [2:0]   size
    );

        logic [P_DWIDTH-1:0] dataW, dataR;
        integer a, b, err;
        begin
            err = 0;

            // read-after-write test
            for (a=start; a<=(finish-size); a = a + size) begin
                dataW   = $random;
                apb_write   (a, dataW, size);
                apb_read    (a, dataR, size);
                if(dataR !== dataW) begin
                    err = err + 1;
                    $display ($time, "%m RAW error at A:0x%08x D:0x%x, but 0x%x expected",
                                        a, dataR, dataW);
                end
            end
            if(err == 0) $display($time, "%m RAW 0x%x-%x test OK", start, finish);
            err = 0;

            for (a=start; a<=(finish-size); a = a + size) begin
                b = a - start;
                reposit[b] = $random;
                apb_write(a, reposit[b], size);
            end
            for (a=start; a<=(finish-size); a=a+size) begin
                b = a - start;
                apb_read(a, dataR, size);
                if(dataR !== reposit[b]) begin
                    err = err + 1;
                    $$display($time,"%m RAAWA error at A:0x%08x D:0x%x, but 0x%x expected",
                            a, dataR, reposit[b]);
                end
            end
            if(err==0) $display($time, "%m RAAWA 0x%x-%x test OK", start, finish);
        end
        
        
    endtask

    `include "bfm_apb_tasks.sv"
endmodule
